#import <Foundation/Foundation.h>
#import "InterSystemsInstance.h"

@interface CControl : NSObject {
    
@private
    
}
extern NSString * const Started;
extern NSString * const Stopped;

+ (NSMutableArray *)getInstances;
+ (BOOL)isInterSystemsInstalled;
+ (BOOL)startStopInstance:(InterSystemsInstance *)instance;
+ (void)restartInstance:(InterSystemsInstance *)instance;
@end
