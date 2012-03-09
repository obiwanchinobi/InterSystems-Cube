#import <Foundation/Foundation.h>


@interface InterSystemsInstance : NSObject {
    
@private
    NSString* name;
    NSString* dir;
    NSString* version;
    NSString* status;
    NSString* lastUsed;
    NSString* superServerPort;
    NSString* webServerPort;
    
}

@property (copy) NSString* name;
@property (copy) NSString* dir;
@property (copy) NSString* version;
@property (copy) NSString* status;
@property (copy) NSString* lastUsed;
@property (copy) NSString* superServerPort;
@property (copy) NSString* webServerPort;

+ (BOOL)isInstanceRunning:(InterSystemsInstance *)instance;

@end
