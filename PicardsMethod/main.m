#import <Foundation/Foundation.h>
#import <Metal/Metal.h>
#import "PicardsParallelSolver.h"
#import "PicardsIterativeSolver.h"

int main()
{
    const int x0 = 1;
    const int xN = 10;
    const int y0 = -1;
    const long numX =  1024 * 1024;
    
    float* parallelAnswer = parallelPicardsMethod(x0, xN, y0, numX);
    printf("y[xN] = %f\n", parallelAnswer[numX - 1]);
    
    float* iterativeAnswer = iterativePicardsMethod(x0, xN, y0, numX);
    printf("y[xN] = %f\n", iterativeAnswer[numX - 1]);
    
    //for (int i = 0; i < numX; i++)
    //   printf("%f\n", fabs(parallelAnswer[i] - iterativeAnswer[i]));
    
    
    return 0;
}
