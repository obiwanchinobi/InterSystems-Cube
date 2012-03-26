#import <Foundation/Foundation.h>
#import "InterSystemsInstance.h"

@interface CControl : NSObject {
    
@private

}

extern NSString * const Started;
extern NSString * const Stopped;

+ (BOOL)isInterSystemsInstalled;
+ (NSMutableArray *)getInstances;

@end
