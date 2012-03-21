#import <Cocoa/Cocoa.h>
#import "CControl.h"

@interface InterSystems_menubarAppDelegate : NSObject <NSApplicationDelegate> {
    IBOutlet NSMenu *instancesMenu;
    
    NSMutableArray *instancesList;
    NSStatusItem * instancesItem;
    
@private
    NSWindow *window;
    NSPersistentStoreCoordinator *__persistentStoreCoordinator;
    NSManagedObjectModel *__managedObjectModel;
    NSManagedObjectContext *__managedObjectContext;
}

@property (assign) IBOutlet NSWindow *window;

@property (nonatomic, retain, readonly) NSPersistentStoreCoordinator *persistentStoreCoordinator;
@property (nonatomic, retain, readonly) NSManagedObjectModel *managedObjectModel;
@property (nonatomic, retain, readonly) NSManagedObjectContext *managedObjectContext;

- (IBAction)saveAction:sender;
- (IBAction)quit:sender;
- (IBAction)telnet:sender;
- (IBAction)openDirectory:sender;
- (IBAction)startStopInstance:sender;
- (IBAction)restartInstance:sender;
- (IBAction)launchPortal:sender;
- (IBAction)launchDocs:sender;
- (IBAction)launchReferences:sender;
- (IBAction)startAtLogin:sender;
    
- (void)awakeFromNib;
- (void)validateInstallationFiles;
- (void)createMenus;

- (void)enableLoginItemWithLoginItemsReference:(LSSharedFileListRef )theLoginItemsRefs ForPath:(NSString *)appPath;
- (void)disableLoginItemWithLoginItemsReference:(LSSharedFileListRef )theLoginItemsRefs ForPath:(NSString *)appPath;
- (BOOL)loginItemExistsWithLoginItemReference:(LSSharedFileListRef)theLoginItemsRefs ForPath:(NSString *)appPath;

@end
