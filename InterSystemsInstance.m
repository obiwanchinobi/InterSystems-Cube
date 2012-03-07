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

@end
