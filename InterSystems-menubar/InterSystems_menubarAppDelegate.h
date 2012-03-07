#import <Cocoa/Cocoa.h>
#import "CControl.h"

@interface InterSystems_menubarAppDelegate : NSObject <NSApplicationDelegate> {
    IBOutlet NSMenu *instancesMenu;
    IBOutlet NSMenuItem *missingInstancesDescription;
    IBOutlet NSMenuItem *installedInstancesSeparator;
    IBOutlet NSMenuItem *refreshMenu;
    
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
- (void)awakeFromNib;
- (void)displayMissingInstancesMsg;
- (void)hideMenus;
- (void)createMenus:(NSMutableArray *)array;

@end
