#import "InterSystemsInstance.h"


@implementation InterSystemsInstance

@synthesize name;
@synthesize dir;
@synthesize version;
@synthesize status;
@synthesize lastUsed;
@synthesize superServerPort;
@synthesize webServerPort;

- (id)init
{
    self = [super init];
    if (self) {
        // 
    }
    
    return self;
}

- (void)dealloc
{
    [super dealloc];
}

+ (BOOL)isInstanceRunning:(InterSystemsInstance *)instance {
    if ([instance.status isEqualToString: @"running"]) {
        return TRUE;
    }
    return FALSE;
}

+ (BOOL)isStartupScriptInstalled:(NSString *)instanceName {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    BOOL isDir;
    
    return ([fileManager fileExistsAtPath:[NSString stringWithFormat:@"/Library/StartupItems/%@", instanceName] isDirectory:&isDir] && isDir);
}

+ (BOOL)isStartupScriptDisabled:(NSString *)instanceName {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    BOOL isDir;
    
    return ([fileManager fileExistsAtPath:[NSString stringWithFormat:@"/Library/StartupItems/%@/.disabled", instanceName] isDirectory:&isDir] && !isDir);
}

@end
