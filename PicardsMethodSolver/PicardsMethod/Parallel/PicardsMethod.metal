#include <metal_stdlib>
#import "rightSide.h"

using namespace metal;

float findIntegral(int i, device const float* x, device float* y) {
    return (x[i + 1] - x[i]) * (f(x[i], y[i]) + f(x[i + 1], y[i + 1])) / 2;
}

void setSums(device const float* x,
             device float* y,
             device float* currentThreadSums,
             device const int* numOfX,
             device const int* numOfThreads,
             device float* prevIntegrals,
             uint numOfCurrentThread) {
    float sum = 0;
    for (uint i = numOfCurrentThread * *numOfX / *numOfThreads;
              i < (numOfCurrentThread + 1) * *numOfX / *numOfThreads;
              i++) {
        prevIntegrals[i] = findIntegral(i, x, y);
        sum += prevIntegrals[i];
    }
    
    currentThreadSums[numOfCurrentThread] = sum;
}

kernel void solveODE(device const float* x,
                     device float* y,
                     device float* currentThreadSums,
                     device float* totalSums,
                     device float* prevIntegrals,
                     device const int* numOfIteration,
                     device const int* numOfX,
                     device const int* numOfThreads,
                     uint numOfCurrentThread [[thread_position_in_grid]]) {
    
    if(*numOfIteration != 0) {
        float sum = totalSums[numOfCurrentThread];
        y[numOfCurrentThread * *numOfX / *numOfThreads] = y[0] + sum;
        
        for (uint i = numOfCurrentThread * *numOfX / *numOfThreads + 1;
                  i < (numOfCurrentThread + 1) * *numOfX / *numOfThreads; i ++)
            y[i] = y[i - 1] + prevIntegrals[i - 1];
    }
    
    setSums(x, y, currentThreadSums, numOfX, numOfThreads, prevIntegrals, numOfCurrentThread);
}
