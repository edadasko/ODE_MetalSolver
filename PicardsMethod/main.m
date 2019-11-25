#import <Foundation/Foundation.h>
#import <Metal/Metal.h>
#import "PicardsMetalSolver.h"

int main()
{
    //x0, xN, y0, numX
    parallelPicardsMethod(0, 5, 1, 1024 * 1024);
    return 0;
}
