#import <Foundation/Foundation.h>
#import "InterSystemsInstance.h"

@interface CControl : NSObject {
    
@private
    
}

+ (NSMutableArray *)getInstances;
+ (BOOL)isInterSystemsInstalled;
+ (BOOL)startStopInstance:(InterSystemsInstance *)instance;
@end
