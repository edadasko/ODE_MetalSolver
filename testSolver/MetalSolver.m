#import "MetalSolver.h"
#include <time.h>

const float x0 = 0;
const float xN = 10;
const float yInit = 1;

const unsigned long int numOfXs = 1024 * 16 * 16;
const unsigned long int numOfThreads = 128 * 16;
const unsigned long int numOfThreadsPerThreadgroup = 16;
const unsigned int bufferXsSize = numOfXs * sizeof(float);
const unsigned int bufferGroupsSize = numOfThreads * sizeof(float);
const unsigned int bufferNumOfXsSize = sizeof(long int);
const unsigned int bufferNumOfGroupsSize = sizeof(long int);
const unsigned int bufferNumOfIterationSize = sizeof(int);

@implementation MetalSolver
{
    id<MTLDevice> _mDevice;
    
    id<MTLComputePipelineState> _mSolveFunctionPSO;
    
    id<MTLCommandQueue> _mCommandQueue;
    
    id<MTLBuffer> _mBufferXs;
    id<MTLBuffer> _mBufferYs;
    id<MTLBuffer> _mBufferSums;
    id<MTLBuffer> _mBufferPrevIntegrals;
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
        if (defaultLibrary == nil)
        {
            NSLog(@"Failed to find the default library.");
            return nil;
        }

        id<MTLFunction> solveFunction = [defaultLibrary newFunctionWithName:@"solve_boundary_task"];
        if (solveFunction == nil)
        {
            NSLog(@"Failed to find the adder function.");
            return nil;
        }
        
        _mSolveFunctionPSO = [_mDevice newComputePipelineStateWithFunction: solveFunction error:&error];
        if (_mSolveFunctionPSO == nil)
        {
            NSLog(@"Failed to created pipeline state object, error %@.", error);
            return nil;
        }
        
        _mCommandQueue = [_mDevice newCommandQueue];
        if (_mCommandQueue == nil)
        {
            NSLog(@"Failed to find the command queue.");
            return nil;
        }
    }
    
    return self;
}

- (void) prepareData
{
    _mBufferXs = [_mDevice newBufferWithLength:bufferXsSize options:MTLResourceStorageModeShared];
    _mBufferYs = [_mDevice newBufferWithLength:bufferXsSize options:MTLResourceStorageModeShared];
    _mBufferPrevIntegrals = [_mDevice newBufferWithLength:bufferXsSize options:MTLResourceStorageModeShared];
    _mBufferSums = [_mDevice newBufferWithLength:bufferGroupsSize options:MTLResourceStorageModeShared];
    _mBufferNumOfXs = [_mDevice newBufferWithLength:bufferNumOfXsSize options:MTLResourceStorageModeShared];
    _mBufferNumOfThreads = [_mDevice newBufferWithLength:bufferNumOfGroupsSize options:MTLResourceStorageModeShared];
    _mBufferNumOfIteration = [_mDevice newBufferWithLength:bufferNumOfIterationSize options:MTLResourceStorageModeShared];
    
    [self generateXs:_mBufferXs];
    [self generateYs:_mBufferYs];
    [self generateNumOfXs:_mBufferNumOfXs
          generateNumOfGroups:_mBufferNumOfThreads
          generateNumOfIteration:_mBufferNumOfIteration];
}


- (void) generateXs: (id<MTLBuffer>) buffer
{
    float* dataPtr = buffer.contents;
    float h = (xN - x0) / (numOfXs - 1);
    dataPtr[0] = x0;
    dataPtr[numOfXs - 1] = xN;
    for (unsigned long index = 1; index < numOfXs - 1; index++)
    {
        dataPtr[index] = dataPtr[index - 1] + h;
    }
}

- (void) generateYs: (id<MTLBuffer>) buffer
{
    float* dataPtr = buffer.contents;
    for (unsigned long index = 0; index < numOfXs; index++)
    {
        dataPtr[index] = yInit;
    }
}

- (void) generateNumOfXs: (id<MTLBuffer>) bufferNumOfXs
         generateNumOfGroups: (id<MTLBuffer>) bufferNumOfGroups
         generateNumOfIteration: (id<MTLBuffer>) bufferNumOfIteration
{
    long int* numXs = bufferNumOfXs.contents;
    *numXs = numOfXs;
    long int* numGroups = bufferNumOfGroups.contents;
    *numGroups = numOfThreads;
    int* numIteration = bufferNumOfIteration.contents;
    *numIteration = 0;
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
    
    [self encodeAddCommand:computeEncoder];
    
    [computeEncoder endEncoding];
    [commandBuffer commit];
    [commandBuffer waitUntilCompleted];
    

}

- (void)encodeAddCommand:(id<MTLComputeCommandEncoder>)computeEncoder {
    
    [computeEncoder setComputePipelineState:_mSolveFunctionPSO];
    [computeEncoder setBuffer:_mBufferXs offset:0 atIndex:0];
    [computeEncoder setBuffer:_mBufferYs offset:0 atIndex:1];
    [computeEncoder setBuffer:_mBufferSums offset:0 atIndex:2];
    [computeEncoder setBuffer:_mBufferPrevIntegrals offset:0 atIndex:3];
    [computeEncoder setBuffer:_mBufferNumOfIteration offset:0 atIndex:4];
    [computeEncoder setBuffer:_mBufferNumOfXs offset:0 atIndex:5];
    [computeEncoder setBuffer:_mBufferNumOfThreads offset:0 atIndex:6];
    
    MTLSize threadsPerThreadgroup = MTLSizeMake(numOfThreadsPerThreadgroup, 1, 1);
    MTLSize threadsPerGrid = MTLSizeMake(numOfThreads, 1, 1);
    [computeEncoder dispatchThreads: threadsPerGrid
                     threadsPerThreadgroup: threadsPerThreadgroup];
}

-(float) getResult
{
    float* yCheck = _mBufferYs.contents;
    printf("%f\n",yCheck[numOfXs - 1]);
    return yCheck[numOfXs - 1];
}

@end
