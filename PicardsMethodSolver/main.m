#import <Foundation/Foundation.h>
#import <Metal/Metal.h>
#import "PicardsMethod/Parallel/PicardsParallelSolver.h"
#import "PicardsMethod/Iterative/PicardsIterativeSolver.h"

int main()
{
    const int numOfEquations = 1;
    const int x0 = 0;
    const int xN = 10;
    const int y0 = 1;
    const int numX =  1024 * 1024;
    
    double parallelTime = 0;
    float* parallelAnswer = 0;
    for (int i = 0; i < numOfEquations; i ++)
        parallelAnswer = parallelPicardsMethod(x0, xN, y0, numX, &parallelTime);
    
    printf("Parallel time: %f \n", parallelTime);
    printf("y[xN] = %f\n", parallelAnswer[numX - 1]);
    
    double iterativeTime = 0;
    float* iterativeAnswer = 0;
    for (int i = 0; i < numOfEquations; i ++)
        iterativeAnswer = iterativePicardsMethod(x0, xN, y0, numX, &iterativeTime);
    
    printf("Iterative time: %f \n", iterativeTime);
    printf("y[xN] = %f\n", iterativeAnswer[numX - 1]);
    
    //for (int i = 0; i < numX; i++)
    //   printf("%f\n", fabs(parallelAnswer[i] - iterativeAnswer[i]));
    
    return 0;
}
