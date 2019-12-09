#import <Foundation/Foundation.h>
#import <Metal/Metal.h>
#import "PararealSolver.h"

int main() {
    const int numOfEquations = 50;
    const int x0 = 0;
    const int xN = 10;
    const int y0 = 1;
    const int numX =  1024 * 1024;
    
    double parallelTime = 0;
    float* parallelAnswer = 0;
    
    for (int i = 0; i < numOfEquations; i++)
        parallelAnswer = pararealMethod(x0, xN, y0, numX, &parallelTime);
    
    printf("Parallel time: %f \n", parallelTime);
    printf("y[xN] = %f\n", parallelAnswer[numX - 1]);
    
    FILE * f = fopen("/Users/edadasko/Desktop/parareal.txt ", "w");
    for (int i = 0; i < numX; i++)
        fprintf(f, "%f, ", parallelAnswer[i]);
    fclose(f);
    
    return 0;
}
