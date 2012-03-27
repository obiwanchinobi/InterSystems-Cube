#import "cubeAppDelegate.h"

@implementation cubeAppDelegate

@synthesize window;

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    NSImage *instancesImage = [NSImage imageNamed:@"cube_status.icns"];
    instancesItem = [[[NSStatusBar systemStatusBar] statusItemWithLength:NSVariableStatusItemLength] retain];
    
    //Use SetTemplate to set image as template.
    //This image should uses only black and clear colors.
    //Click over a template image in statusBar converts black color in white and alpha channel in blue.
    [instancesImage setTemplate:YES];
    [instancesItem setImage:instancesImage];
    [instancesItem setToolTip:@"Manage InterSystems Instances"];
    [instancesItem setHighlightMode:YES];
    BOOL blessHelper = TRUE;
    NSArray *allJobs = (NSArray *)SMCopyAllJobDictionaries(kSMDomainSystemLaunchd);
    for (NSDictionary *job in allJobs) {
        NSString *label = [job objectForKey: @"Label"];
        NSString *program = [job objectForKey: @"Program"];
        if (nil == program) {
            program = [[job objectForKey: @"ProgramArguments"] objectAtIndex: 0];
        }
        if ([label isEqualToString:@"com.InterSystems.CubeHelper"]) {
            blessHelper = FALSE;
            NSLog(@"Detected helper job: %@ (%@)", label, program);
        }
    }
    [allJobs release];
    
    if (blessHelper == TRUE) {
        // Get authorization
        AuthorizationRef authRef = [self createAuthRef];
        if (authRef == NULL) {
            NSLog(@"Authorization failed");
            return;
        }
        
        // Bless Helper
        NSError *error = nil;
        if (![self blessHelperWithLabel:@"com.InterSystems.CubeHelper" withAuthRef:authRef error:&error]) {
            NSLog(@"Bless Error: %@",error);
            return;
        }
        NSLog(@"Helper job does not exist - bless helper!");
    }

    // Connect to Helper
    NSConnection *c = [NSConnection connectionWithRegisteredName:@"com.InterSystems.CubeHelper.mach" host:nil]; 
    proxy = (PrivilegedActions *)[c rootProxy];
    
    if ([CControl isInterSystemsInstalled] == TRUE) {
        instancesList = [[NSMutableArray alloc] init];
        instancesList = [CControl getInstances];
        
        // Load Instances
        if ([instancesList count] > 0) {
            [instancesItem setAction:@selector(validateInstallationFiles)];
            [instancesItem setTarget:self];
        }
        else {
            [instancesItem setMenu:instancesMenu];
            [instancesMenu insertItemWithTitle:@"No instances installed" action:nil keyEquivalent:@"" atIndex:0];
            [instancesMenu insertItem:[NSMenuItem separatorItem] atIndex:1];
            [instancesMenu insertItemWithTitle:@"Quit" action:@selector(quit:) keyEquivalent:@"" atIndex:2];
        }
    }
    else {
        [instancesItem setMenu:instancesMenu];
        [instancesMenu insertItemWithTitle:@"No InterSystems installations detected" action:nil keyEquivalent:@"" atIndex:0];
        [instancesMenu insertItem:[NSMenuItem separatorItem] atIndex:1];
        [instancesMenu insertItemWithTitle:@"Quit" action:@selector(quit:) keyEquivalent:@"" atIndex:2];
    }
}

- (void)validateInstallationFiles {
    if ([CControl isInterSystemsInstalled] == TRUE) {
        instancesList = [[NSMutableArray alloc] init];
        instancesList = [CControl getInstances];
        
        // Load Instances
        if ([instancesList count] > 0) {
            [self createMenus];
        }
        else {
            [instancesItem setMenu:instancesMenu];
            [instancesMenu insertItemWithTitle:@"No instances installed" action:nil keyEquivalent:@"" atIndex:0];
            [instancesMenu insertItem:[NSMenuItem separatorItem] atIndex:1];
            [instancesMenu insertItemWithTitle:@"Quit" action:@selector(quit:) keyEquivalent:@"" atIndex:2];
        }
    }
    else {
        [instancesItem setMenu:instancesMenu];
        [instancesMenu insertItemWithTitle:@"No InterSystems installations detected" action:nil keyEquivalent:@"" atIndex:0];
        [instancesMenu insertItem:[NSMenuItem separatorItem] atIndex:1];
        [instancesMenu insertItemWithTitle:@"Quit" action:@selector(quit:) keyEquivalent:@"" atIndex:2];
    }
}

- (NSApplicationTerminateReply)applicationShouldTerminate:(NSApplication *)sender {
    return NSTerminateNow;
}

-(void)awakeFromNib {

}

-(IBAction)quit:sender {
    [NSApp performSelector:@selector(terminate:) withObject:nil afterDelay:0.0];
}

- (IBAction)terminal:sender {
    InterSystemsInstance *instance = [sender representedObject];
    
    NSString *instanceName = instance.name;
    NSAppleScript* csession = [[NSAppleScript alloc] initWithSource:
                               [NSString stringWithFormat:
                                    @"tell application \"Terminal\"\n"
                                    @"  activate\n"
                                    @"  if it is running then\n"
                                    @"      do script \"csession %@\"\n"
                                    @"  else\n"
                                    @"      do script \"csession %@\" in front window\n"
                                    @"  end if\n"
                                    @"  tell the front window\n"
                                    @"      set title displays shell path to false\n"
                                    @"      set title displays custom title to true\n"
                                    @"      set custom title to \"InterSystems Session: %@\"\n"
                                    @"  end tell\n"
                                    @"end tell", instanceName, instanceName, instanceName]];
    
    [csession executeAndReturnError:nil];
}

- (IBAction)openDirectory:sender {
    InterSystemsInstance *instance = [sender representedObject];
    NSAppleScript* openDir = [[NSAppleScript alloc] initWithSource:
                               [NSString stringWithFormat:
                                @"tell application \"Finder\"\n"
                                @"  open (\"%@\" as POSIX file)\n"
                                @"end tell", instance.dir]];
    
    [openDir executeAndReturnError:nil];
}

- (IBAction)startStopInstance:sender {
    InterSystemsInstance *instance = [sender representedObject];
    
    if ([proxy startStopInstance:instance] == FALSE) {
        NSLog(@"Error starting/stopping '%@'", instance.name);
    }
}

- (IBAction)restartInstance:sender {
    InterSystemsInstance *instance = [sender representedObject];

    [proxy restartInstance:instance];
}

- (IBAction)launchPortal:sender {
    InterSystemsInstance *instance = [sender representedObject];
    NSString *port = instance.webServerPort;

    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:[NSString stringWithFormat:@"http://localhost:%@/csp/sys/UtilHome.csp", port]]];
}

- (IBAction)launchDocs:sender {
    InterSystemsInstance *instance = [sender representedObject];
    NSString *port = instance.webServerPort;
    
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:[NSString stringWithFormat:@"http://localhost:%@/csp/docbook/DocBook.UI.HomePageZen.cls", port]]];
}

- (IBAction)launchReferences:sender {
    InterSystemsInstance *instance = [sender representedObject];
    NSString *port = instance.webServerPort;

    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:[NSString stringWithFormat:@"http://localhost:%@/csp/documatic/%%25CSP.Documatic.cls", port]]];
}

- (IBAction)toggleInstanceAutoStart:sender {
    InterSystemsInstance *instance = [sender representedObject];
    
    if ([InterSystemsInstance isStartupScriptInstalled:instance.name] == FALSE) {
        [proxy createAutoStartFiles:instance];
    }
    else {
        if ([InterSystemsInstance isStartupScriptDisabled:instance.name] == TRUE) {
            [proxy toggleInstanceAutoStart:instance:TRUE];
        }
        else {
            [proxy toggleInstanceAutoStart:instance:FALSE];
        }
    }
}
    
- (IBAction)toggleAutoStartAtLogin:sender {
    NSString * appPath = [[NSBundle mainBundle] bundlePath];
	
	// Create a reference to the shared file list.
	LSSharedFileListRef loginItems = LSSharedFileListCreate(NULL, kLSSharedFileListSessionLoginItems, NULL);
	if (loginItems) {
		if ([sender state] == NSOnState) {
        	[self disableLoginItemWithLoginItemsReference:loginItems ForPath:appPath];
        }
		else {
            [self enableLoginItemWithLoginItemsReference:loginItems ForPath:appPath];
        }
	}
	CFRelease(loginItems);
}

- (void)enableLoginItemWithLoginItemsReference:(LSSharedFileListRef )theLoginItemsRefs ForPath:(NSString *)appPath {
	// We call LSSharedFileListInsertItemURL to insert the item at the bottom of Login Items list.
	CFURLRef url = (CFURLRef)[NSURL fileURLWithPath:appPath];
	LSSharedFileListItemRef item = LSSharedFileListInsertItemURL(theLoginItemsRefs, kLSSharedFileListItemLast, NULL, NULL, url, NULL, NULL);		
	if (item)
		CFRelease(item);
}

- (void)disableLoginItemWithLoginItemsReference:(LSSharedFileListRef )theLoginItemsRefs ForPath:(NSString *)appPath {
	UInt32 seedValue;
	CFURLRef thePath = NULL;
	// We're going to grab the contents of the shared file list (LSSharedFileListItemRef objects)
	// and pop it in an array so we can iterate through it to find our item.
	CFArrayRef loginItemsArray = LSSharedFileListCopySnapshot(theLoginItemsRefs, &seedValue);
	for (id item in (NSArray *)loginItemsArray) {		
		LSSharedFileListItemRef itemRef = (LSSharedFileListItemRef)item;
		if (LSSharedFileListItemResolve(itemRef, 0, (CFURLRef*) &thePath, NULL) == noErr) {
			if ([[(NSURL *)thePath path] hasPrefix:appPath]) {
				LSSharedFileListItemRemove(theLoginItemsRefs, itemRef); // Deleting the item
			}
			// Docs for LSSharedFileListItemResolve say we're responsible
			// for releasing the CFURLRef that is returned
			if (thePath != NULL) CFRelease(thePath);
		}		
	}
	if (loginItemsArray != NULL) CFRelease(loginItemsArray);
}

- (BOOL)loginItemExistsWithLoginItemReference:(LSSharedFileListRef)theLoginItemsRefs ForPath:(NSString *)appPath {
	BOOL found = NO;  
	UInt32 seedValue;
	CFURLRef thePath = NULL;
	
	// We're going to grab the contents of the shared file list (LSSharedFileListItemRef objects)
	// and pop it in an array so we can iterate through it to find our item.
	CFArrayRef loginItemsArray = LSSharedFileListCopySnapshot(theLoginItemsRefs, &seedValue);
	for (id item in (NSArray *)loginItemsArray) {    
		LSSharedFileListItemRef itemRef = (LSSharedFileListItemRef)item;
		if (LSSharedFileListItemResolve(itemRef, 0, (CFURLRef*) &thePath, NULL) == noErr) {
			if ([[(NSURL *)thePath path] hasPrefix:appPath]) {
				found = YES;
				break;
			}
            // Docs for LSSharedFileListItemResolve say we're responsible
            // for releasing the CFURLRef that is returned
            if (thePath != NULL) CFRelease(thePath);
		}
	}
	if (loginItemsArray != NULL) CFRelease(loginItemsArray);
	
	return found;
}

-(void)createMenus {
    NSUInteger index = 0;
    InterSystemsInstance *instance;
    NSMenuItem *item;
    NSMenuItem *portalMenuItem;
    NSMenuItem *docsMenuItem;
    NSMenuItem *referencesMenuItem;
    NSMenuItem *terminalMenuItem;
    NSMenuItem *openDirMenuItem;
    NSMenuItem *startStopMenuItem;
    NSMenuItem *restartMenuItem;
    NSMenuItem *toggleInstanceAutoStartMenuItem;
    NSMenuItem *toggleAutoStartAtLoginMenuItem;
    NSMenu *subMenu;
    NSString *status;
    
    NSString * appPath = [[NSBundle mainBundle] bundlePath];
    
    // Reset menu
    [instancesMenu init];
    
    for (id object in instancesList) {
        instance = [[InterSystemsInstance alloc] init];
        instance = object;

        // Create menu
        item = [instancesMenu insertItemWithTitle:instance.name action:nil keyEquivalent:@"" atIndex:index++];
        [item setOnStateImage:[NSImage imageNamed:NSImageNameStatusAvailable]];
        [item setOffStateImage:[NSImage imageNamed:NSImageNameStatusUnavailable]];
        [item setMixedStateImage:[NSImage imageNamed:NSImageNameStatusPartiallyAvailable]];
        
        [item setTarget:self]; // or whatever target you want

        if ([instance.status isEqualToString: Started]) {
            [item setState:NSOnState];
        }
        else if ([instance.status isEqualToString: Stopped]) {
            [item setState:NSOffState];
        }
        else {
            [item setState:NSMixedState];
        }
        
        subMenu = [[NSMenu alloc] init];
        
        // version submenu
        [subMenu addItemWithTitle:instance.version action:nil keyEquivalent:@""];
        [subMenu addItem:[NSMenuItem separatorItem]];
        
        // csession submenu
        if ([InterSystemsInstance isInstanceRunning:instance]) {
            terminalMenuItem = [subMenu addItemWithTitle:@"Terminal session" action:@selector(terminal:) keyEquivalent:@""];
        }
        else {
            terminalMenuItem = [subMenu addItemWithTitle:@"Terminal session" action:nil keyEquivalent:@""];
        }
        [terminalMenuItem setRepresentedObject:instance];
        
        if ([InterSystemsInstance isInstanceRunning:instance]) {
            portalMenuItem = [subMenu addItemWithTitle:@"Management Portal" action:@selector(launchPortal:) keyEquivalent:@""];
        }
        else {
            portalMenuItem = [subMenu addItemWithTitle:@"Management Portal" action:nil keyEquivalent:@""];
        }
        [portalMenuItem setRepresentedObject:instance];
        
        openDirMenuItem = [subMenu addItemWithTitle:@"Open Installation directory" action:@selector(openDirectory:) keyEquivalent:@""];
        [openDirMenuItem setRepresentedObject:instance];
        
        [subMenu addItem:[NSMenuItem separatorItem]];
        
        // start/stop submenu
        if ([instance.status isEqualToString:Started]) {
            status = @"Stop Instance";
        }
        else if ([instance.status isEqualToString:Stopped]) {
            status = @"Start Instance";
        }
        else {
            status = @"Force Stop Instance";
        }
        startStopMenuItem = [subMenu addItemWithTitle:status action:@selector(startStopInstance:) keyEquivalent:@""];
        [startStopMenuItem setRepresentedObject:instance];
        
        // restart submenu
        if ([InterSystemsInstance isInstanceRunning:instance]) {
            restartMenuItem = [subMenu addItemWithTitle:@"Restart Instance" action:@selector(restartInstance:) keyEquivalent:@""];
        }
        else {
            restartMenuItem = [subMenu addItemWithTitle:@"Restart Instance" action:nil keyEquivalent:@""];
        }
        [restartMenuItem setRepresentedObject:instance];
        
        // autostart submenu
        toggleInstanceAutoStartMenuItem = [subMenu addItemWithTitle:@"Autostart on System Startup" action:@selector(toggleInstanceAutoStart:) keyEquivalent:@""];
        [toggleInstanceAutoStartMenuItem setRepresentedObject:instance];
        
        if ([InterSystemsInstance isStartupScriptInstalled:instance.name] == TRUE) {
            if ([InterSystemsInstance isStartupScriptDisabled:instance.name] == FALSE) {
                [toggleInstanceAutoStartMenuItem setState:NSOnState];
            }
        }
        
        [item setSubmenu:subMenu];
        
        [subMenu addItem:[NSMenuItem separatorItem]];
        
        // urls submenu
        if ([InterSystemsInstance isInstanceRunning:instance]) {
            docsMenuItem = [subMenu addItemWithTitle:@"Documentation" action:@selector(launchDocs:) keyEquivalent:@""];
        }
        else {
            docsMenuItem = [subMenu addItemWithTitle:@"Documentation" action:nil keyEquivalent:@""];
        }
        [docsMenuItem setRepresentedObject:instance];
        
        if ([InterSystemsInstance isInstanceRunning:instance]) {
            referencesMenuItem = [subMenu addItemWithTitle:@"Class Reference" action:@selector(launchReferences:) keyEquivalent:@""];
        }
        else {
            referencesMenuItem = [subMenu addItemWithTitle:@"Class Reference" action:nil keyEquivalent:@""];
        }
        [referencesMenuItem setRepresentedObject:instance];
        
        [instance release];
        [subMenu release];
    }
    
    if (index > 1) {
        [instancesMenu insertItem:[NSMenuItem separatorItem] atIndex:index++];
    }
    
    toggleAutoStartAtLoginMenuItem = [instancesMenu insertItemWithTitle:@"Start at Login" action:@selector(toggleAutoStartAtLogin:) keyEquivalent:@"" atIndex:index++];
    LSSharedFileListRef loginItems = LSSharedFileListCreate(NULL, kLSSharedFileListSessionLoginItems, NULL);
	if ([self loginItemExistsWithLoginItemReference:loginItems ForPath:appPath]) {
		[toggleAutoStartAtLoginMenuItem setState:NSOnState];
	}
	CFRelease(loginItems);
    
    [instancesMenu insertItem:[NSMenuItem separatorItem] atIndex:index++];
    
    [instancesMenu insertItemWithTitle:@"Quit" action:@selector(quit:) keyEquivalent:@"" atIndex:index++];
    
    // Display menu after constructing instancesMenu
    [instancesItem popUpStatusItemMenu:instancesMenu];
}

- (AuthorizationRef)createAuthRef
{
    AuthorizationRef authRef = NULL;
    AuthorizationItem authItem = { kSMRightBlessPrivilegedHelper, 0, NULL, 0 };
    AuthorizationRights authRights = { 1, &authItem };
    AuthorizationFlags flags = kAuthorizationFlagDefaults | kAuthorizationFlagInteractionAllowed | kAuthorizationFlagPreAuthorize | kAuthorizationFlagExtendRights;
    
    OSStatus status = AuthorizationCreate(&authRights, kAuthorizationEmptyEnvironment, flags, &authRef);
    if (status != errAuthorizationSuccess) {
        NSLog(@"Failed to create AuthorizationRef, return code %i", status);
    }
    
    return authRef;
}

- (BOOL)blessHelperWithLabel:(NSString *)label withAuthRef:(AuthorizationRef)authRef error:(NSError **)error
{
    CFErrorRef err;
    BOOL result = SMJobBless(kSMDomainSystemLaunchd, (CFStringRef)label, authRef, &err);
    *error = (NSError *)err;
    
    return result;
}

- (void)dealloc
{
    [instancesItem release];
    [super dealloc];
}

@end
