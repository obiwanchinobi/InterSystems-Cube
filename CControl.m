#import "CControl.h"


@implementation CControl

- (id)init
{
    self = [super init];
    if (self) {
        // Initialization code here.
    }
    
    return self;
}

+ (NSMutableArray *)getInstances {
    NSMutableArray *instancesList;
    
    instancesList = [[NSMutableArray alloc] init];
    InterSystemsInstance *instance;
    
    //Setup the task execution
    NSPipe *output = [NSPipe pipe];
    NSTask *task = [[[NSTask alloc] init] autorelease];
    [task setLaunchPath:@"/usr/bin/ccontrol"];
    [task setArguments:[NSArray arrayWithObjects:@"qlist", nil, nil]];
    [task setStandardOutput:output];
    
    //launch task and wait for completion
    [task launch];
    [task waitUntilExit];
    int status = [task terminationStatus];
    
    if (status == 0)
    {    
        NSData *data = [[output fileHandleForReading] readDataToEndOfFile];
        NSString *dataString = [[[NSString alloc] initWithBytes:[data bytes] 
                                                         length:[data length] 
                                                       encoding:NSUTF8StringEncoding] autorelease];
        
        NSUInteger length = [dataString length];
        NSUInteger paraStart = 0, paraEnd = 0, contentsEnd = 0;
        NSRange currentRange;
        while (paraEnd < length)
        {
            // Parse each line
            [dataString getParagraphStart:&paraStart end:&paraEnd contentsEnd:&contentsEnd
                                 forRange:NSMakeRange(paraEnd, 0)];
            currentRange = NSMakeRange(paraStart, contentsEnd - paraStart);
            
            // Extract each piece
            NSArray *stringArray = [[dataString substringWithRange:currentRange] componentsSeparatedByString: @"^"];
            
            instance = [[InterSystemsInstance alloc] init];
            instance.name = [stringArray objectAtIndex:0];
            instance.dir = [stringArray objectAtIndex:1];
            instance.version = [stringArray objectAtIndex:2];
            
            // Extract status and 'last used'
            NSUInteger paraStatusStart = 0, paraStatusEnd = 0, contentsStatusEnd = 0;
            
            [[stringArray objectAtIndex:3] getParagraphStart:&paraStatusStart end:&paraStatusEnd contentsEnd:&contentsStatusEnd
                                                    forRange:NSMakeRange(paraStatusEnd, 0)];
            NSRange currentStatusRange = NSMakeRange(paraStatusStart, contentsStatusEnd - paraStatusStart);
            NSArray *stringStatusArray = [[[stringArray objectAtIndex:3] substringWithRange:currentStatusRange] componentsSeparatedByString: @", "];
            instance.status = [stringStatusArray objectAtIndex:0];
            instance.lastUsed = [stringStatusArray objectAtIndex:1];
            
            instance.superServerPort = [stringArray objectAtIndex:5];
            instance.webServerPort = [stringArray objectAtIndex:6];
            
            // Append to array
            [instancesList addObject:instance];
            [instance release];
        }
    }
    else {
        NSLog(@"Task failed.");
    }
    
    return instancesList;
}

+ (BOOL)isInterSystemsInstalled {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    BOOL isDir;
    
    return [fileManager fileExistsAtPath:[NSString stringWithFormat:@"/usr/bin/ccontrol"] isDirectory:&isDir] && !isDir;
}

+ (BOOL)startStopInstance:(InterSystemsInstance *)instance {
    NSString *action;
    NSString *parameter = nil;
    
    if ([instance.status isEqualToString:@"running"]) {
        action = @"stop";
        parameter = @"quietly";
    }
    else if ([instance.status isEqualToString:@"down"]) {
        action = @"start";
    }
    else {
        action = @"force";
    }
    
    //Setup the task execution
    NSPipe *output = [NSPipe pipe];
    NSTask *task = [[[NSTask alloc] init] autorelease];
    [task setLaunchPath:@"/usr/bin/ccontrol"];
    [task setArguments:[NSArray arrayWithObjects:action, instance.name, parameter, nil]];
    [task setStandardOutput:output];
    
    //launch task and wait for completion
    [task launch];
    [task waitUntilExit];
    int status = [task terminationStatus];
    
    if (status == 0) {
        if ([instance.status isEqualToString:@"running"]) {
            instance.status = @"down";
        }
        else if ([instance.status isEqualToString:@"down"]) {
            instance.status = @"running";
        }
        return TRUE;
    }
    else {
        return FALSE;
    }
}

- (void)dealloc
{
    [super dealloc];
}
@end
