#import <Foundation/Foundation.h>
#import <Metal/Metal.h>
#import "MetalSolver.h"


int main()
{
    @autoreleasepool
    {
        id<MTLDevice> device = MTLCreateSystemDefaultDevice();

        MetalSolver* solver = [[MetalSolver alloc] initWithDevice:device];
        
        [solver prepareData];
        
        for (int i = 0; i < 10; i ++)
        {
            [solver sendComputeCommand];
            //[adder getResult];
            //printf("\n");
            [solver nextIteration];
        }
        
        NSLog(@"Execution finished");
    }
    return 0;
}
