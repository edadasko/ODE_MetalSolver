#import <Foundation/Foundation.h>
#import <Metal/Metal.h>

NS_ASSUME_NONNULL_BEGIN

float* pararealMethod(float, float, float, float, unsigned long, double*);

@interface PararealSolver : NSObject
- (instancetype) initWithDevice: (id<MTLDevice>) device;
- (void) setX0: (float) initX0
         setXN: (float) initXN
         setY0: (float) initY0
     setNumOfX: (unsigned long) initNumX;
- (void) sendComputeCommand;
- (float*) getResult;
- (void) nextIteration;
@end

NS_ASSUME_NONNULL_END
