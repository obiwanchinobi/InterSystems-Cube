#import <Cocoa/Cocoa.h>
#import "CControl.h"
#import "PrivilegedActions.h"
#import <ServiceManagement/ServiceManagement.h>
#import <Security/Authorization.h>

@interface cubeAppDelegate : NSObject <NSApplicationDelegate> {
    IBOutlet NSMenu *instancesMenu;
    
    NSMutableArray *instancesList;
    NSStatusItem * instancesItem;
    
@private
    NSWindow *window;
}

@property (assign) IBOutlet NSWindow *window;

- (IBAction)quit:sender;
- (IBAction)telnet:sender;
- (IBAction)openDirectory:sender;
- (IBAction)startStopInstance:sender;
- (IBAction)restartInstance:sender;
- (IBAction)launchPortal:sender;
- (IBAction)launchDocs:sender;
- (IBAction)launchReferences:sender;
- (IBAction)toggleInstanceAutoStart:sender;
- (IBAction)toggleAutoStartAtLogin:sender;

- (void)awakeFromNib;
- (void)validateInstallationFiles;
- (void)createMenus;

- (void)enableLoginItemWithLoginItemsReference:(LSSharedFileListRef )theLoginItemsRefs ForPath:(NSString *)appPath;
- (void)disableLoginItemWithLoginItemsReference:(LSSharedFileListRef )theLoginItemsRefs ForPath:(NSString *)appPath;
- (BOOL)loginItemExistsWithLoginItemReference:(LSSharedFileListRef)theLoginItemsRefs ForPath:(NSString *)appPath;

- (AuthorizationRef)createAuthRef;
- (BOOL)blessHelperWithLabel:(NSString *)label withAuthRef:(AuthorizationRef)authRef error:(NSError **)error;

@end
