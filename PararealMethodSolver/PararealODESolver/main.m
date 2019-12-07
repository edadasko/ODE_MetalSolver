#import <Foundation/Foundation.h>
#import <Metal/Metal.h>
#import "PararealSolver.h"

int main()
{
    const int numOfEquations = 10;
    const int x0 = 1;
    const int xN = 100;
    const int y0 = 0;
    const int numX =  1024 * 1024;
    const float coeff = 0.01;
    
    double parallelTime = 0;
    float* parallelAnswer = 0;
    for (int i = 0; i < numOfEquations; i++)
        parallelAnswer = pararealMethod(x0, xN, y0, coeff, numX, &parallelTime);
    
    printf("Parallel time: %f \n", parallelTime);
    printf("y[xN] = %f\n", parallelAnswer[numX - 1]);
    
    return 0;
}
