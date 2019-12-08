#include <metal_stdlib>
#import "rightSide.h"

using namespace metal;

float rungeKutta4(float prevX, float prevY, float dt)
{
    float k1 = f(prevX, prevY);
    float k2 = f(prevX + dt / 2, prevY + dt / 2 * k1);
    float k3 = f(prevX + dt / 2, prevY + dt / 2 * k2);
    float k4 = f(prevX + dt, prevY + dt * k3);
    
    return prevY + dt / 6 * (k1 + 2 * k2 + 2 * k3 + k4);
}
kernel void solveODE(device const float* x,
                     device float* y,
                     device float* coarseGridValues,
                     device const int* numOfIteration,
                     device const int* numOfX,
                     device const float* dt,
                     device const int* numOfThreads,
                     uint numOfCurrentThread [[thread_position_in_grid]])
{
    int startIndex = numOfCurrentThread * (*numOfX - 1) / *numOfThreads;
    
    y[startIndex + 1] = rungeKutta4(x[startIndex], coarseGridValues[numOfCurrentThread], *dt);
    

    for (uint i = startIndex + 2;
         i < (numOfCurrentThread + 1) * (*numOfX - 1) / *numOfThreads + 1;
         i++)
    {
        y[i] = rungeKutta4(x[i - 1], y[i - 1], *dt);
    }
}
