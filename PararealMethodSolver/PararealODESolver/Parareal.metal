#include <metal_stdlib>
#import "rightSide.h"

using namespace metal;

kernel void solveBoundaryTask(device const float* x,
                              device float* y,
                              device float* coarseGridValues,
                              device const int* numOfIteration,
                              device const int* numOfX,
                              device const float* dt,
                              device const float* coeff,
                              device const int* numOfThreads,
                              uint numOfCurrentThread [[thread_position_in_grid]])
{
    int startIndex = numOfCurrentThread * (*numOfX - 1) / *numOfThreads;
    
    y[startIndex + 1] =
        (*dt * f(x[startIndex + 1]) + coarseGridValues[numOfCurrentThread]) / (1 - *coeff * *dt);
    
    for (uint i = startIndex + 2;
         i < (numOfCurrentThread + 1) * (*numOfX - 1) / *numOfThreads + 1;
         i++)
    {
        y[i] = (*dt * f(x[i + 1]) + y[i - 1]) / (1 - *coeff * *dt);
    }
}
