#import <Foundation/Foundation.h>
#import <Metal/Metal.h>

NS_ASSUME_NONNULL_BEGIN

float* parallelPicardsMethod(float, float, float, unsigned long);

@interface PicardsMetalSolver : NSObject
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
