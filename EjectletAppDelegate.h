/**
 * EjectletAppDelegate header.
 */

#import <Cocoa/Cocoa.h>

#define MCE_ICON_SIZE 14.0
#define MCE_FONT_FAMILY @"Lucida Grande"
#define MCE_FONT_SIZE 14.0
#define MCE_EJECT_UNICODE_CHARACTER 0x23CF
#define MCE_MACINTOSH_HD @"Macintosh HD"
#define MCE_ROOT_VOLUME @"/"
#define MCE_LABEL_QUIT @"Quit"
#define MCE_LABEL_EJECT_ALL @"Eject All"
#define MCE_LABEL_NO_VOLUMES @"No Volumes"
#define MCE_ERROR_VOLUMES @"Error Ejecting Volumes"
#define MCE_ERROR_NOT_EJECTED @"Could not eject all of the volumes"
#define MCE_ERROR_VOLUME @"Error ejecting volume"
#define MCE_ERROR_VOLUME_ERROR @"Could not eject the %s volume - try ejecting it through the finder"

@interface EjectletAppDelegate : NSObject {
	NSApplication *application;
	NSMenu *menu;
	NSStatusBar *statusbar;
	NSStatusItem *statusitem;
	NSWorkspace *workspace;
	NSMutableDictionary *ejectables;
	NSFileManager *fileman;
	NSFont *menufont;
	NSDictionary *stringAttributeDict;
	NSArray *ignoreVolumes;
	NSArray *volumePaths;
	NSArray *mediaNames;
	Boolean updatedAtLeastOnce;
}

- (void) updateAll;
- (void) buildMenu;
- (void) discoverVolumes;
- (void) addEjectAll;
- (void) addLabelItem;
- (void) buildStatusItem;
- (void) addSeperator;
- (void) addQuitItem;
- (void) quit:(id) sender;
- (Boolean) hasEjectableVolumes;
- (Boolean) shouldUpdate;
- (void)unmount:(NSString *)volumePath;
//- (Boolean) unmountAndEjectDevice:(NSString *)volumePath andRemoveKeyFromEjectables:(NSString *)key;
- (Boolean) unmountAtPath:(NSString *)volumePath withDisplayName:(NSString *)displayName;
- (void)menuWillOpen:(NSMenu *)menu;
- (void)bringForward;

@end
