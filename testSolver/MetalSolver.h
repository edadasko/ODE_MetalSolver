#import <Foundation/Foundation.h>
#import <Metal/Metal.h>

NS_ASSUME_NONNULL_BEGIN

@interface MetalSolver : NSObject
- (instancetype) initWithDevice: (id<MTLDevice>) device;
- (void) prepareData;
- (void) sendComputeCommand;
- (float) getResult;
- (void) nextIteration;
 @end

NS_ASSUME_NONNULL_END
