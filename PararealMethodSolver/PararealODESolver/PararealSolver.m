#import "PararealSolver.h"
#import "rightSide.h"
#include <time.h>

float x0;
float xN;
float yInit;
float coefficient;

unsigned long numOfXs;
unsigned long bufferXsSize;
const unsigned long numOfThreads = 1024;
const unsigned long numOfThreadsPerThreadgroup = 32;

const unsigned int bufferGroupsSize = numOfThreads * sizeof(float);
const unsigned int bufferCoarseYsSize = (numOfThreads + 1) * sizeof(float);
const unsigned int bufferNumOfXsSize = sizeof(long int);
const unsigned int bufferCoeffSize = sizeof(float);
const unsigned int bufferDTSize = sizeof(float);
const unsigned int bufferNumOfGroupsSize = sizeof(long int);
const unsigned int bufferNumOfIterationSize = sizeof(int);

@implementation PararealSolver
{
    id<MTLDevice> _mDevice;
    
    id<MTLComputePipelineState> _mSolveFunctionPSO;
    
    id<MTLCommandQueue> _mCommandQueue;
    
    id<MTLBuffer> _mBufferXs;
    id<MTLBuffer> _mBufferYs;
    id<MTLBuffer> _mBufferCoarseYs;
    id<MTLBuffer> _mBufferCoeff;
    id<MTLBuffer> _mBufferDT;
    id<MTLBuffer> _mBufferNumOfThreads;
    id<MTLBuffer> _mBufferNumOfXs;
    id<MTLBuffer> _mBufferNumOfIteration;
}

- (instancetype) initWithDevice: (id<MTLDevice>) device
{
    self = [super init];
    if (self)
    {
        _mDevice = device;
        NSError* error = nil;
        id<MTLLibrary> defaultLibrary = [_mDevice newDefaultLibrary];
        id<MTLFunction> solveFunction = [defaultLibrary newFunctionWithName:@"solveODE"];
        _mSolveFunctionPSO = [_mDevice newComputePipelineStateWithFunction: solveFunction error:&error];
        _mCommandQueue = [_mDevice newCommandQueue];
    }
    
    return self;
}

- (void) setX0: (float) initX0
         setXN: (float) initXN
         setY0: (float) initY0
     setNumOfX:(unsigned long int) initNumX
{
    x0 = initX0;
    xN = initXN;
    yInit = initY0;
    numOfXs = initNumX;
    bufferXsSize = numOfXs * sizeof(float);
    
    _mBufferXs = [_mDevice newBufferWithLength:bufferXsSize options:MTLResourceStorageModeShared];
    _mBufferYs = [_mDevice newBufferWithLength:bufferXsSize options:MTLResourceStorageModeShared];
    _mBufferNumOfXs = [_mDevice newBufferWithLength:bufferNumOfXsSize options:MTLResourceStorageModeShared];
    _mBufferCoarseYs = [_mDevice newBufferWithLength:bufferCoarseYsSize options:MTLResourceStorageModeShared];
    _mBufferDT= [_mDevice newBufferWithLength:bufferDTSize options:MTLResourceStorageModeShared];
    _mBufferCoeff= [_mDevice newBufferWithLength:bufferCoeffSize options:MTLResourceStorageModeShared];
    _mBufferNumOfThreads = [_mDevice newBufferWithLength:bufferNumOfGroupsSize options:MTLResourceStorageModeShared];
    _mBufferNumOfIteration = [_mDevice newBufferWithLength:bufferNumOfIterationSize options:MTLResourceStorageModeShared];
    
    generateXs(_mBufferXs, _mBufferDT);
    generateYs(_mBufferYs);
    generateNums(_mBufferNumOfXs, _mBufferNumOfThreads,
                 _mBufferNumOfIteration, _mBufferCoeff);
}

- (void) setCoarseValues
{
    generateCoarseValues(_mBufferCoarseYs, _mBufferXs);
}

- (void) updateCoarseValues
{
    correctCoarseGridValues(_mBufferCoarseYs, _mBufferYs);
}

void generateXs(id<MTLBuffer> bufferXs, id<MTLBuffer> bufferDT)
{
    float* dataPtr = bufferXs.contents;
    float h = (xN - x0) / (numOfXs - 1);
    
    dataPtr[0] = x0;
    dataPtr[numOfXs - 1] = xN;
    
    for (unsigned long index = 1; index < numOfXs - 1; index++)
    {
        dataPtr[index] = dataPtr[index - 1] + h;
    }
    
    float* dt = bufferDT.contents;
    *dt = h;
}

void generateYs(id<MTLBuffer> buffer)
{
    float* dataPtr = buffer.contents;
    
    for (unsigned long index = 0; index < numOfXs; index++)
    {
        dataPtr[index] = yInit;
    }
}

void generateNums(id<MTLBuffer> bufferNumOfXs, id<MTLBuffer> bufferNumOfGroups,
                  id<MTLBuffer> bufferNumOfIteration, id<MTLBuffer> bufferCoeff)
{
    long int* numXs = bufferNumOfXs.contents;
    *numXs = numOfXs;
    
    long int* numGroups = bufferNumOfGroups.contents;
    *numGroups = numOfThreads;
    
    int* numIteration = bufferNumOfIteration.contents;
    *numIteration = 0;
    
    float* coeff = bufferCoeff.contents;
    *coeff = coefficient;
}

void generateCoarseValues(id<MTLBuffer> bufferCoarse, id<MTLBuffer> bufferXs)
{
    float* coarseGridValues = bufferCoarse.contents;
    
    coarseGridValues[0] = yInit;
    
    float dT = (xN - x0) / (numOfThreads - 1);
    float* xs = bufferXs.contents;
    
    for (int i = 1; i < numOfThreads + 1; i++)
    {
        coarseGridValues[i] = (dT * f(xs[i * (numOfXs - 1) /  numOfThreads])
                               + coarseGridValues[i - 1]) / (1 - coefficient * dT);
    }
}

void correctCoarseGridValues(id<MTLBuffer> bufferCoarse, id<MTLBuffer> bufferYs)
{
    float* coarseGridValues = bufferCoarse.contents;
    float* ys = bufferYs.contents;
    
    float dT = (xN - x0) / (numOfThreads - 1);
    
    float* defect = (float*)malloc((numOfThreads + 1) * sizeof(float));
    
    for (int i = 0; i < numOfThreads + 1; i++)
    {
        defect[i] = ys[i * (numOfXs - 1) /  numOfThreads] - coarseGridValues[i];
    }
    
    float* deltas = (float*)malloc((numOfThreads + 1) * sizeof(float));
    
    deltas[0] = 0;
    
    for (int i = 1; i < numOfThreads + 1; i++)
    {
        deltas[i] = (defect[i - 1] + deltas[i - 1]) / (1 - coefficient * dT);
    }
    
    for (int i = 0; i < numOfThreads + 1; i++)
    {
        coarseGridValues[i] = ys[i * (numOfXs - 1) /  numOfThreads] + deltas[i];
    }
    
    free (defect);
    free (deltas);
}

- (void) nextIteration
{
    int* numIteration = _mBufferNumOfIteration.contents;
    *numIteration += 1;
}

- (void) sendComputeCommand
{
    id<MTLCommandBuffer> commandBuffer = [_mCommandQueue commandBuffer];
    assert(commandBuffer != nil);
    
    id<MTLComputeCommandEncoder> computeEncoder = [commandBuffer computeCommandEncoder];
    assert(computeEncoder != nil);
    
    [self encodeSolveCommand:computeEncoder];
    
    [computeEncoder endEncoding];
    [commandBuffer commit];
    [commandBuffer waitUntilCompleted];
}

- (void)encodeSolveCommand:(id<MTLComputeCommandEncoder>)computeEncoder {
    
    [computeEncoder setComputePipelineState:_mSolveFunctionPSO];
    [computeEncoder setBuffer:_mBufferXs offset:0 atIndex:0];
    [computeEncoder setBuffer:_mBufferYs offset:0 atIndex:1];
    [computeEncoder setBuffer:_mBufferCoarseYs offset:0 atIndex:2];
    [computeEncoder setBuffer:_mBufferNumOfIteration offset:0 atIndex:3];
    [computeEncoder setBuffer:_mBufferNumOfXs offset:0 atIndex:4];
    [computeEncoder setBuffer:_mBufferDT offset:0 atIndex:5];
    [computeEncoder setBuffer:_mBufferCoeff offset:0 atIndex:6];
    [computeEncoder setBuffer:_mBufferNumOfThreads offset:0 atIndex:7];
    
    MTLSize threadsPerThreadgroup = MTLSizeMake(numOfThreadsPerThreadgroup, 1, 1);
    MTLSize threadsPerGrid = MTLSizeMake(numOfThreads, 1, 1);
    [computeEncoder dispatchThreads: threadsPerGrid
              threadsPerThreadgroup: threadsPerThreadgroup];
}

-(float*) getResult
{
    float* yCheck = _mBufferYs.contents;
    return yCheck;
}

@end


float getMaxDifference(float* answer, float* nextAnswer, unsigned long numX)
{
    float maxDifference = FLT_MIN;
    
    for (int i = 0; i < numOfThreads; i ++)
    {
        float diff = fabsf(nextAnswer[i * (numOfXs - 1) /  numOfThreads] -
                        answer[i * (numOfXs - 1) /  numOfThreads]);
        
        if (diff > maxDifference)
            maxDifference = diff;
    }
    
    return maxDifference;
}


float* pararealMethod(float x0, float xN, float y0,
                      float coeff, unsigned long numX,
                      double* time)
{
    const float error = 0.0001;
    float* answer = (float*)malloc(numX * sizeof(int));
    
    for (int i = 0; i < numX; i++)
    {
        answer[i] = FLT_MAX;
    }
    
    coefficient = coeff;
    
    id<MTLDevice> device = MTLCreateSystemDefaultDevice();
    
    PararealSolver* solver = [[PararealSolver alloc] initWithDevice:device];
    
    [solver setX0: x0
            setXN: xN
            setY0: y0
        setNumOfX: numX + 1];
    
    NSTimeInterval sumTime = 0;

    NSDate *start = [NSDate date];
    [solver setCoarseValues];
    [solver sendComputeCommand];
    float* nextAnswer = [solver getResult];
    
    sumTime += [start timeIntervalSinceNow];
    
    while (getMaxDifference(answer, nextAnswer, numX) > error)
    {
        for (int i = 0; i < numX; i ++)
            answer[i] = nextAnswer[i];
        
        NSDate *start = [NSDate date];
        
        [solver updateCoarseValues];
        [solver nextIteration];
        [solver sendComputeCommand];
        nextAnswer = [solver getResult];
        
        sumTime += [start timeIntervalSinceNow];
    }
    
    *time += (double)fabs(sumTime);
    
    return nextAnswer;
}
