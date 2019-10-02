#import <Foundation/Foundation.h>
#import <Metal/Metal.h>
#import "MetalSolver.h"

const float error = 0.001;
float answer = 0;

int main()
{
    @autoreleasepool
    {
        id<MTLDevice> device = MTLCreateSystemDefaultDevice();

        MetalSolver* solver = [[MetalSolver alloc] initWithDevice:device];
        
        [solver prepareData];
        
        NSDate *start = [NSDate date];
        [solver sendComputeCommand];
        float nextAnswer = [solver getResult];
        while (nextAnswer - answer > error)
        {
            [solver nextIteration];
            answer = nextAnswer;
            [solver sendComputeCommand];
            nextAnswer = [solver getResult];
        }
        
        NSTimeInterval timeInterval = [start timeIntervalSinceNow];
        printf("\n%f\n", fabs(timeInterval));
        
        NSLog(@"Execution finished");
    }
    return 0;
}
