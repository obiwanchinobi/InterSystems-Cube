#import "cubeAppDelegate.h"

@implementation cubeAppDelegate

@synthesize window;

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    NSImage *instancesImage = [NSImage imageNamed:@"cube.png"];
    instancesItem = [[[NSStatusBar systemStatusBar] statusItemWithLength:NSVariableStatusItemLength] retain];
    
    //Use SetTemplate to set image as template.
    //This image should uses only black and clear colors.
    //Click over a template image in statusBar converts black color in white and alpha channel in blue.
    [instancesImage setTemplate:YES];
    
    //    [instancesItem setMenu:instancesMenu];
    [instancesItem setImage:instancesImage];
    [instancesItem setToolTip:@"Manage InterSystems Instances"];
    [instancesItem setHighlightMode:YES];
    
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

/**
    Returns the directory the application uses to store the Core Data store file. This code uses a directory named "cube" in the user's Library directory.
 */
- (NSURL *)applicationFilesDirectory {

    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSURL *libraryURL = [[fileManager URLsForDirectory:NSLibraryDirectory inDomains:NSUserDomainMask] lastObject];
    return [libraryURL URLByAppendingPathComponent:@"cube"];
}

/**
    Creates if necessary and returns the managed object model for the application.
 */
- (NSManagedObjectModel *)managedObjectModel {
    if (__managedObjectModel) {
        return __managedObjectModel;
    }
	
    NSURL *modelURL = [[NSBundle mainBundle] URLForResource:@"cube" withExtension:@"momd"];
    __managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];    
    return __managedObjectModel;
}

/**
    Returns the persistent store coordinator for the application. This implementation creates and return a coordinator, having added the store for the application to it. (The directory for the store is created, if necessary.)
 */
- (NSPersistentStoreCoordinator *) persistentStoreCoordinator {
    if (__persistentStoreCoordinator) {
        return __persistentStoreCoordinator;
    }

    NSManagedObjectModel *mom = [self managedObjectModel];
    if (!mom) {
        NSLog(@"%@:%@ No model to generate a store from", [self class], NSStringFromSelector(_cmd));
        return nil;
    }

    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSURL *applicationFilesDirectory = [self applicationFilesDirectory];
    NSError *error = nil;
    
    NSDictionary *properties = [applicationFilesDirectory resourceValuesForKeys:[NSArray arrayWithObject:NSURLIsDirectoryKey] error:&error];
        
    if (!properties) {
        BOOL ok = NO;
        if ([error code] == NSFileReadNoSuchFileError) {
            ok = [fileManager createDirectoryAtPath:[applicationFilesDirectory path] withIntermediateDirectories:YES attributes:nil error:&error];
        }
        if (!ok) {
            [[NSApplication sharedApplication] presentError:error];
            return nil;
        }
    }
    else {
        if ([[properties objectForKey:NSURLIsDirectoryKey] boolValue] != YES) {
            // Customize and localize this error.
            NSString *failureDescription = [NSString stringWithFormat:@"Expected a folder to store application data, found a file (%@).", [applicationFilesDirectory path]]; 
            
            NSMutableDictionary *dict = [NSMutableDictionary dictionary];
            [dict setValue:failureDescription forKey:NSLocalizedDescriptionKey];
            error = [NSError errorWithDomain:@"YOUR_ERROR_DOMAIN" code:101 userInfo:dict];
            
            [[NSApplication sharedApplication] presentError:error];
            return nil;
        }
    }
    
    NSURL *url = [applicationFilesDirectory URLByAppendingPathComponent:@"cube.storedata"];
    __persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:mom];
    if (![__persistentStoreCoordinator addPersistentStoreWithType:NSXMLStoreType configuration:nil URL:url options:nil error:&error]) {
        [[NSApplication sharedApplication] presentError:error];
        [__persistentStoreCoordinator release], __persistentStoreCoordinator = nil;
        return nil;
    }

    return __persistentStoreCoordinator;
}

/**
    Returns the managed object context for the application (which is already
    bound to the persistent store coordinator for the application.) 
 */
- (NSManagedObjectContext *) managedObjectContext {
    if (__managedObjectContext) {
        return __managedObjectContext;
    }

    NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
    if (!coordinator) {
        NSMutableDictionary *dict = [NSMutableDictionary dictionary];
        [dict setValue:@"Failed to initialize the store" forKey:NSLocalizedDescriptionKey];
        [dict setValue:@"There was an error building up the data file." forKey:NSLocalizedFailureReasonErrorKey];
        NSError *error = [NSError errorWithDomain:@"YOUR_ERROR_DOMAIN" code:9999 userInfo:dict];
        [[NSApplication sharedApplication] presentError:error];
        return nil;
    }
    __managedObjectContext = [[NSManagedObjectContext alloc] init];
    [__managedObjectContext setPersistentStoreCoordinator:coordinator];

    return __managedObjectContext;
}

/**
    Returns the NSUndoManager for the application. In this case, the manager returned is that of the managed object context for the application.
 */
- (NSUndoManager *)windowWillReturnUndoManager:(NSWindow *)window {
    return [[self managedObjectContext] undoManager];
}

/**
    Performs the save action for the application, which is to send the save: message to the application's managed object context. Any encountered errors are presented to the user.
 */
- (IBAction) saveAction:(id)sender {
    NSError *error = nil;
    
    if (![[self managedObjectContext] commitEditing]) {
        NSLog(@"%@:%@ unable to commit editing before saving", [self class], NSStringFromSelector(_cmd));
    }

    if (![[self managedObjectContext] save:&error]) {
        [[NSApplication sharedApplication] presentError:error];
    }
}

- (NSApplicationTerminateReply)applicationShouldTerminate:(NSApplication *)sender {

    // Save changes in the application's managed object context before the application terminates.

    if (!__managedObjectContext) {
        return NSTerminateNow;
    }

    if (![[self managedObjectContext] commitEditing]) {
        NSLog(@"%@:%@ unable to commit editing to terminate", [self class], NSStringFromSelector(_cmd));
        return NSTerminateCancel;
    }

    if (![[self managedObjectContext] hasChanges]) {
        return NSTerminateNow;
    }

    NSError *error = nil;
    if (![[self managedObjectContext] save:&error]) {

        // Customize this code block to include application-specific recovery steps.              
        BOOL result = [sender presentError:error];
        if (result) {
            return NSTerminateCancel;
        }

        NSString *question = NSLocalizedString(@"Could not save changes while quitting. Quit anyway?", @"Quit without saves error question message");
        NSString *info = NSLocalizedString(@"Quitting now will lose any changes you have made since the last successful save", @"Quit without saves error question info");
        NSString *quitButton = NSLocalizedString(@"Quit anyway", @"Quit anyway button title");
        NSString *cancelButton = NSLocalizedString(@"Cancel", @"Cancel button title");
        NSAlert *alert = [[NSAlert alloc] init];
        [alert setMessageText:question];
        [alert setInformativeText:info];
        [alert addButtonWithTitle:quitButton];
        [alert addButtonWithTitle:cancelButton];

        NSInteger answer = [alert runModal];
        [alert release];
        alert = nil;
        
        if (answer == NSAlertAlternateReturn) {
            return NSTerminateCancel;
        }
    }

    return NSTerminateNow;
}

-(void)awakeFromNib {

}

-(IBAction)quit:sender {
    [NSApp performSelector:@selector(terminate:) withObject:nil afterDelay:0.0];
}

- (IBAction)telnet:sender {
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
    NSMutableDictionary *dict = [sender representedObject];
    InterSystemsInstance *instance = [dict objectForKey:@"instance"];
    NSMenuItem *telnetMenuItem = [dict objectForKey:@"telnet"];
    NSMenuItem *restartMenuItem = [dict objectForKey:@"restart"];
    NSMenuItem *portalMenuItem = [dict objectForKey:@"portal"];
    NSMenuItem *docsMenuItem = [dict objectForKey:@"docs"];
    NSMenuItem *referencesMenuItem = [dict objectForKey:@"references"];
    
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
    
    // Connect to Helper
    NSConnection *c = [NSConnection connectionWithRegisteredName:@"com.InterSystems.CubeHelper.mach" host:nil]; 
    PrivilegedActions *proxy = (PrivilegedActions *)[c rootProxy];
    
    if ([proxy startStopInstance:instance] == TRUE) {
        if ([instance.status isEqualToString:Started]) {
            [sender setTitle:@"Stop Instance"];
            [telnetMenuItem setAction:@selector(telnet:)];
            [restartMenuItem setAction:@selector(restartInstance:)];
            [portalMenuItem setAction:@selector(launchPortal:)];
            [docsMenuItem setAction:@selector(launchDocs:)];
            [referencesMenuItem setAction:@selector(launchReferences:)];
            [[sender parentItem] setState:NSOnState];
        }
        else if ([instance.status isEqualToString:Stopped]) {
            [sender setTitle:@"Start Instance"];
            [telnetMenuItem setAction:nil];
            [restartMenuItem setAction:nil];
            [portalMenuItem setAction:nil];
            [docsMenuItem setAction:nil];
            [referencesMenuItem setAction:nil];
            [[sender parentItem] setState:NSOffState];
        }
        else {
            [[sender parentItem] setState:NSMixedState];
            NSLog(@"'%@' is niether running or down", instance.name);
        }
    }
    else {
        NSLog(@"Error starting/stopping '%@'", instance.name);
    }
}

- (IBAction)restartInstance:sender {
    InterSystemsInstance *instance = [sender representedObject];
    
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
    
    // Connect to Helper
    NSConnection *c = [NSConnection connectionWithRegisteredName:@"com.InterSystems.CubeHelper.mach" host:nil]; 
    PrivilegedActions *proxy = (PrivilegedActions *)[c rootProxy];

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
    
    // Connect to Helper
    NSConnection *c = [NSConnection connectionWithRegisteredName:@"com.InterSystems.CubeHelper.mach" host:nil]; 
    PrivilegedActions *proxy = (PrivilegedActions *)[c rootProxy];
    
    if ([InterSystemsInstance isStartupScriptInstalled:instance.name] == FALSE) {
        [proxy createAutoStartFiles:instance];
        [sender setState:NSOnState];
    }
    else {
        if ([InterSystemsInstance isStartupScriptDisabled:instance.name] == TRUE) {
            [proxy toggleInstanceAutoStart:instance:TRUE];
            [sender setState:NSOnState];
        }
        else {
            [proxy toggleInstanceAutoStart:instance:FALSE];
            [sender setState:NSOffState];
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
            [sender setState:NSOffState];
        }
		else {
            [self enableLoginItemWithLoginItemsReference:loginItems ForPath:appPath];
            [sender setState:NSOnState];
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
    NSMenuItem *telnetMenuItem;
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
            telnetMenuItem = [subMenu addItemWithTitle:@"Telnet session" action:@selector(telnet:) keyEquivalent:@""];
        }
        else {
            telnetMenuItem = [subMenu addItemWithTitle:@"Telnet session" action:nil keyEquivalent:@""];
        }
        [telnetMenuItem setRepresentedObject:instance];
        
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
        
        // setup objects for start/stop submenu - done after other menus are assigned
        [startStopMenuItem setRepresentedObject:
         [NSDictionary dictionaryWithObjectsAndKeys:
          instance, @"instance",
          telnetMenuItem, @"telnet",
          restartMenuItem, @"restart",
          portalMenuItem, @"portal", 
          docsMenuItem, @"docs", 
          referencesMenuItem, @"references", 
          nil]
         ];
        
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
    
    [__managedObjectContext release];
    [__persistentStoreCoordinator release];
    [__managedObjectModel release];
    [super dealloc];
}

@end
