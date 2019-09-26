#include <metal_stdlib>
using namespace metal;

float f(float x, float y)
{
    return 2 * x * y / (1 + x * x);
}

// y = 1 + x ^ 2


float findIntegral(int i, device const float* x, device float* y)
{
    return (x[i + 1] - x[i]) * (f(x[i], y[i]) + f(x[i + 1], y[i + 1])) / 2;
}

void setSums(device const float* x,
             device float* y,
             device float* sums,
             device const int* numOfX,
             device const int* numOfGroups,
             device float* prevIntegrals,
             uint numOfCurrentGroup)
{
    float sum = 0;
    for (uint i = numOfCurrentGroup * *numOfX / *numOfGroups;
              i < (numOfCurrentGroup + 1) * *numOfX / *numOfGroups;
              i ++)
    {
        prevIntegrals[i] = findIntegral(i, x, y);
        sum += prevIntegrals[i];
    }
    
    sums[numOfCurrentGroup] = sum;
}

float getSums(device float* sums, uint numOfCurrentGroup)
{
    float sum = 0;
    for (uint i = 0; i < numOfCurrentGroup; i ++)
        sum += sums[i];
    return sum;
}

kernel void solve_boundary_task(device const float* x,
                                device float* y,
                                device float* sums,
                                device float* prevIntegrals,
                                device const int* numOfIteration,
                                device const int* numOfX,
                                device const int* numOfGroups,
                                uint numOfCurrentGroup [[thread_position_in_grid]])
{
    if(*numOfIteration != 0)
    {
        float sum = getSums(sums, numOfCurrentGroup);
        y[numOfCurrentGroup * *numOfX / *numOfGroups] = y[0] + sum;
        for (uint i = numOfCurrentGroup * *numOfX / *numOfGroups + 1;
                  i < (numOfCurrentGroup + 1) * *numOfX / *numOfGroups;
                  i ++)
        {
            y[i] = y[i - 1] + prevIntegrals[i - 1];
        }
    }
    setSums(x, y, sums, numOfX, numOfGroups,
            prevIntegrals, numOfCurrentGroup);
}
