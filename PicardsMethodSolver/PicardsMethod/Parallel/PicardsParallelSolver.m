#import "PicardsParallelSolver.h"
#include <time.h>

float x0;
float xN;
float yInit;

unsigned long numOfXs;
unsigned long bufferXsSize;
const unsigned long numOfThreads = 512;
const unsigned long numOfThreadsPerThreadgroup = 32;
const unsigned int bufferGroupsSize = numOfThreads * sizeof(float);
const unsigned int bufferNumOfXsSize = sizeof(long int);
const unsigned int bufferNumOfGroupsSize = sizeof(long int);
const unsigned int bufferNumOfIterationSize = sizeof(int);

@implementation PicardsMetalSolver {
    id<MTLDevice> _mDevice;
    
    id<MTLComputePipelineState> _mSolveFunctionPSO;
    
    id<MTLCommandQueue> _mCommandQueue;
    
    id<MTLBuffer> _mBufferXs;
    id<MTLBuffer> _mBufferYs;
    id<MTLBuffer> _mBufferCurrentThreadSums;
    id<MTLBuffer> _mBufferTotalSums;
    id<MTLBuffer> _mBufferPrevIntegrals;
    id<MTLBuffer> _mBufferNumOfThreads;
    id<MTLBuffer> _mBufferNumOfXs;
    id<MTLBuffer> _mBufferNumOfIteration;
}

- (instancetype) initWithDevice: (id<MTLDevice>) device {
    self = [super init];
    if (self) {
        _mDevice = device;
        
        NSError* error = nil;

        id<MTLLibrary> defaultLibrary = [_mDevice newDefaultLibrary];

        id<MTLFunction> solveFunction = [defaultLibrary newFunctionWithName:@"solveODE"];
        
        _mSolveFunctionPSO = [_mDevice newComputePipelineStateWithFunction:
                              solveFunction error:&error];
        
        _mCommandQueue = [_mDevice newCommandQueue];
    }
    
    return self;
}

- (void) setX0: (float) initX0
         setXN: (float) initXN
         setY0: (float) initY0
         setNumOfX:(unsigned long int) initNumX {
    x0 = initX0;
    xN = initXN;
    yInit = initY0;
    numOfXs = initNumX;
    bufferXsSize = numOfXs * sizeof(float);
    
    _mBufferXs = [_mDevice newBufferWithLength:bufferXsSize options:MTLResourceStorageModeShared];
    _mBufferYs = [_mDevice newBufferWithLength:bufferXsSize options:MTLResourceStorageModeShared];
    _mBufferPrevIntegrals = [_mDevice newBufferWithLength:bufferXsSize options:MTLResourceStorageModeShared];
    _mBufferCurrentThreadSums = [_mDevice newBufferWithLength:bufferGroupsSize options:MTLResourceStorageModeShared];
    _mBufferTotalSums = [_mDevice newBufferWithLength:bufferGroupsSize options:MTLResourceStorageModeShared];
    _mBufferNumOfXs = [_mDevice newBufferWithLength:bufferNumOfXsSize options:MTLResourceStorageModeShared];
    _mBufferNumOfThreads = [_mDevice newBufferWithLength:bufferNumOfGroupsSize options:MTLResourceStorageModeShared];
    _mBufferNumOfIteration = [_mDevice newBufferWithLength:bufferNumOfIterationSize options:MTLResourceStorageModeShared];
    
    generateXs(_mBufferXs);
    generateYs(_mBufferYs);
    generateNums(_mBufferNumOfXs, _mBufferNumOfThreads, _mBufferNumOfIteration);
}

void generateXs(id<MTLBuffer> buffer) {
    float* dataPtr = buffer.contents;
    float h = (xN - x0) / (numOfXs - 1);
    
    dataPtr[0] = x0;
    dataPtr[numOfXs - 1] = xN;
    
    for (unsigned long index = 1; index < numOfXs - 1; index++)
        dataPtr[index] = dataPtr[index - 1] + h;
}

void generateYs(id<MTLBuffer> buffer) {
    float* dataPtr = buffer.contents;
    for (unsigned long index = 0; index < numOfXs; index++)
        dataPtr[index] = yInit;
}

void generateNums(id<MTLBuffer> bufferNumOfXs, id<MTLBuffer> bufferNumOfGroups,
                  id<MTLBuffer> bufferNumOfIteration) {
    long int* numXs = bufferNumOfXs.contents;
    *numXs = numOfXs;
    long int* numGroups = bufferNumOfGroups.contents;
    *numGroups = numOfThreads;
    int* numIteration = bufferNumOfIteration.contents;
    *numIteration = 0;
}

- (void) nextIteration {
    int* numIteration = _mBufferNumOfIteration.contents;
    *numIteration += 1;
}

- (void) sendComputeCommand {
    id<MTLCommandBuffer> commandBuffer = [_mCommandQueue commandBuffer];
    assert(commandBuffer != nil);
    
    id<MTLComputeCommandEncoder> computeEncoder = [commandBuffer computeCommandEncoder];
    assert(computeEncoder != nil);
    
    [self encodeSolveCommand:computeEncoder];
    
    [computeEncoder endEncoding];
    [commandBuffer commit];
    [commandBuffer waitUntilCompleted];
}

- (void) encodeSolveCommand:(id<MTLComputeCommandEncoder>)computeEncoder {
    [computeEncoder setComputePipelineState:_mSolveFunctionPSO];
    [computeEncoder setBuffer:_mBufferXs offset:0 atIndex:0];
    [computeEncoder setBuffer:_mBufferYs offset:0 atIndex:1];
    [computeEncoder setBuffer:_mBufferCurrentThreadSums offset:0 atIndex:2];
    [computeEncoder setBuffer:_mBufferTotalSums offset:0 atIndex:3];
    [computeEncoder setBuffer:_mBufferPrevIntegrals offset:0 atIndex:4];
    [computeEncoder setBuffer:_mBufferNumOfIteration offset:0 atIndex:5];
    [computeEncoder setBuffer:_mBufferNumOfXs offset:0 atIndex:6];
    [computeEncoder setBuffer:_mBufferNumOfThreads offset:0 atIndex:7];
    
    MTLSize threadsPerThreadgroup = MTLSizeMake(numOfThreadsPerThreadgroup, 1, 1);
    MTLSize threadsPerGrid = MTLSizeMake(numOfThreads, 1, 1);
    [computeEncoder dispatchThreads: threadsPerGrid
                    threadsPerThreadgroup: threadsPerThreadgroup];
}

-(float*) getResult {
    float* yCheck = _mBufferYs.contents;
    return yCheck;
}

- (void) setTotalSums {
    setTotalSums(_mBufferTotalSums, _mBufferCurrentThreadSums);
}

void setTotalSums(id<MTLBuffer> totalSums, id<MTLBuffer> currentSums) {
    float* tSums = totalSums.contents;
    float* cSums = currentSums.contents;
    
    for (uint i = 0 ; i < numOfThreads; i++) {
        tSums[i] = 0;
    }
    
    for (uint i = 0; i < numOfThreads; i++) {
        for (uint j = i + 1; j < numOfThreads; j++) {
            tSums[j] += cSums[i];
        }
    }
}

@end

float getMaxDifference(float* answer, float* nextAnswer, unsigned long numX) {
    float maxDifference = FLT_MIN;
    
    for (int i = 0; i < numX; i ++) {
        float diff = fabsf(nextAnswer[i] - answer[i]);
        if (diff > maxDifference)
            maxDifference = diff;
    }
    
    return maxDifference;
}

float* parallelPicardsMethod(float x0, float xN, float y0, unsigned long numX, double* time) {
    const float error = 0.0001;
    float* answer = (float*)malloc(numX * sizeof(int));
    
    for (int i = 0; i < numX; i++)
        answer[i] = FLT_MAX;
    
    id<MTLDevice> device = MTLCreateSystemDefaultDevice();
    
    PicardsMetalSolver* solver = [[PicardsMetalSolver alloc] initWithDevice:device];
    
    [solver setX0: x0
            setXN: xN
            setY0: y0
            setNumOfX: numX];
    
    NSDate *start = [NSDate date];
    NSTimeInterval sumTime = 0;
    [solver sendComputeCommand];
    float* nextAnswer = [solver getResult];
    
    sumTime += [start timeIntervalSinceNow];
    
    while (getMaxDifference(answer, nextAnswer, numX) > error) {
        for (int i = 0; i < numX; i ++)
            answer[i] = nextAnswer[i];
        
        NSDate *start = [NSDate date];
        
        [solver nextIteration];
        [solver setTotalSums];
        [solver sendComputeCommand];
        nextAnswer = [solver getResult];
        
        sumTime += [start timeIntervalSinceNow];
    }
    
    *time += (double)fabs(sumTime);
    
    return nextAnswer;
}
