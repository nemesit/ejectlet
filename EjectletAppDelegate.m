/**
 * App delegate that contains actions for NSMenuItem's
 * in the NSStatusItem's menu.
 */

#import "EjectletAppDelegate.h"

@implementation EjectletAppDelegate

/**
 * On awake from nib.
 */
- (void) awakeFromNib {
	application = [NSApplication sharedApplication];
	statusbar = [NSStatusBar systemStatusBar];
	workspace = [NSWorkspace sharedWorkspace];
	fileman = [NSFileManager defaultManager];
	menufont = [[NSFont fontWithName:MCE_FONT_FAMILY size:MCE_FONT_SIZE] retain];
	stringAttributeDict = [[NSDictionary dictionaryWithObject:menufont forKey:NSFontAttributeName] retain];
	ejectables = [[[NSMutableDictionary alloc] init] retain];
	ignoreVolumes = [[NSArray arrayWithObjects:MCE_MACINTOSH_HD,MCE_ROOT_VOLUME,nil] retain];
	notificationCenter = [workspace notificationCenter];
	[self registerNotifications];
	[self updateAll];
}

/**
 * Registers observers with the notification center
 * for volume [un]mount.
 */
- (void) registerNotifications {
	[notificationCenter addObserver:self selector:@selector(mountedVolume:) name:NSWorkspaceDidMountNotification object:nil];
	[notificationCenter addObserver:self selector:@selector(unmountedVolume:) name:NSWorkspaceDidUnmountNotification object:nil];
}

/**
 * When a volume is mounted.
 */
- (void) mountedVolume:(NSNotification *)notification {
	[self updateAll];
}

/**
 * When a volume is unmounted.
 */
- (void) unmountedVolume:(NSNotification *)notification {
	[self updateAll];
}
	
/**
 * Does the work to render out the menu.
 */
- (void) updateAll {
	//if(![self shouldUpdate] && updatedAtLeastOnce) return;
	//updatedAtLeastOnce=TRUE;
	//printf("UPDATING\n");
	[self discoverVolumes];
	[self buildMenu];
	[self buildStatusItem];
}

/**
 * Whether or not the NSMenu should be updated,
 * because the volumes have changed.
 */
- (Boolean) shouldUpdate {
	NSArray *mn = [workspace mountedRemovableMedia];
	NSArray *vp = [workspace mountedLocalVolumePaths];
	if([mediaNames isEqualToArray:mn] || [volumePaths isEqualToArray:vp]) return FALSE;
	return TRUE;
}

/**
 * Builds the status item.
 */
- (void) buildStatusItem {
	if(!statusitem) {
		statusitem = [[statusbar statusItemWithLength:NSVariableStatusItemLength] retain];
		[statusitem setTitle:[NSString stringWithFormat:@"%C",MCE_EJECT_UNICODE_CHARACTER]];
		[statusitem setHighlightMode:TRUE];
	}
	[statusitem setMenu:menu];
}

/**
 * Builds the menu of unmountable volumes.
 */
- (void) buildMenu {
	if(menu) [menu release];
	menu = [[[NSMenu alloc] init] retain];
	[menu setDelegate:self];
	
	if(![self hasEjectableVolumes]) {
		[self addLabelItem];
	} else {
		
		
		NSString *key;
		NSEnumerator *enumerator = [ejectables keyEnumerator];
		
		//builds out menu items for each volume discovered
		while(key = [enumerator nextObject])
		{
			//printf("KEY: %s VALUE: %s\n",[key UTF8String],[[ejectables valueForKey:key] UTF8String]);
			NSMenuItem *item = [[NSMenuItem alloc] init];
			NSAttributedString *label = [[[NSAttributedString alloc] initWithString:key attributes:stringAttributeDict] autorelease];
			NSImage *icon = [workspace iconForFile:[ejectables valueForKey:key]];
			[item setAttributedTitle:label];
			[item setAction:@selector(ejectVolume:)];
			[item setToolTip:[NSString stringWithFormat:@"Eject %s",[key UTF8String]]];
			[item setTarget:self];
			[item setImage:icon];
			[icon setSize:NSMakeSize(MCE_ICON_SIZE,MCE_ICON_SIZE)];
			[menu addItem:item];
		}
		[self addSeperator];
		[self addEjectAll];
		[self addSeperator];
	}
	[self addQuitItem];
}

/**
 * Whether or not there are volumes that
 * can be ejected.
 */
- (Boolean) hasEjectableVolumes {
	if(!ejectables) return FALSE;
	if([ejectables count] > 0) return TRUE;
	return FALSE;
}

/**
 * Method for NSMenu delegate.
 */
- (void)menuWillOpen:(NSMenu *)menu {
	//[self updateAll];
}

/**
 * Adds the quit item.
 */
- (void) addQuitItem {
	NSMenuItem *qwit =[[NSMenuItem alloc] init];
	NSAttributedString *attrString = [[[NSAttributedString alloc] initWithString:MCE_LABEL_QUIT attributes:stringAttributeDict] autorelease];
	[qwit setTarget:self];
	[qwit setAction:@selector(quit:)];
	[qwit setAttributedTitle:attrString];
	[menu addItem:qwit];
}

/**
 * Adds a seperator to the menu.
 */
- (void) addSeperator {
	NSMenuItem *item = [NSMenuItem separatorItem];
	[menu addItem:item];
}

/**
 * Adds the eject all menu item to the menu.
 */
- (void) addEjectAll {
	NSMenuItem *ejectAll = [[NSMenuItem alloc] init];
	NSAttributedString *label = [[[NSAttributedString alloc] initWithString:MCE_LABEL_EJECT_ALL attributes:stringAttributeDict] autorelease];
	[ejectAll setAction:@selector(ejectAll:)];
	[ejectAll setTarget:self];
	[ejectAll setAttributedTitle:label];
	[menu addItem:ejectAll];
}

/**
 * Adds a label item to the menu.
 */
- (void) addLabelItem {
	NSMenuItem *item = [[NSMenuItem alloc] init];
	NSAttributedString *label = [[[NSAttributedString alloc] initWithString:MCE_LABEL_NO_VOLUMES attributes:stringAttributeDict] autorelease];
	[item setAttributedTitle:label];
	[menu addItem:item];
}

/**
 * Forces a umount with diskutil.
 */
- (void) unmount:(NSString *)volumePath {
	NSTask *task = [[NSTask alloc] init];
	[task setLaunchPath:@"/usr/sbin/diskutil"];
	[task setArguments:[NSArray arrayWithObjects:@"umount",@"force",volumePath,nil]];
	[task launch];
}

/**
 * Does the work to unmount a volume using
 * either diskutil, or NSWorkspace, depending
 * on the type of media.
 */
- (Boolean) unmountAtPath:(NSString *)volumePath withDisplayName:(NSString *)displayName {
	BOOL removeable = 0;
	BOOL writable = 0;
	BOOL unmountable = 0;
	NSString *description = [[NSString alloc] init];
	NSString *fileSystemType = [[NSString alloc] init];
	[workspace getFileSystemInfoForPath:volumePath isRemovable:&removeable isWritable:&writable isUnmountable:&unmountable description:(NSString **)description type:(NSString **)fileSystemType];
	//return FALSE;
	if(!writable) return [workspace unmountAndEjectDeviceAtPath:volumePath];
	else [self unmount:volumePath];
	return TRUE;
}

/**
 * Action for the eject all menu item.
 */
- (void) ejectAll:(id) sender {
	NSEnumerator *enumer = [ejectables keyEnumerator];
	NSString *key;
	Boolean ejectedAll = TRUE;
	while(key = [enumer nextObject]) {
		NSString *volumePath = [ejectables valueForKey:key];
		if(![self unmountAtPath:volumePath withDisplayName:key]) ejectedAll=FALSE;
	}
	if(!ejectedAll) {
		[self bringForward];
		NSAlert *alert = [NSAlert alertWithMessageText:MCE_ERROR_VOLUMES  \
						defaultButton:NULL alternateButton:NULL otherButton:NULL \
						informativeTextWithFormat:MCE_ERROR_NOT_EJECTED];
		[alert setAlertStyle:NSCriticalAlertStyle];
		[alert runModal];
	}
	//[self updateAll];
}

/**
 * Ejects the volume that was clicked in the NSMenu.
 */
- (void) ejectVolume:(id) sender {
	NSMenuItem *item = (NSMenuItem *)sender;
	NSString *title = [item title];
	NSString *volumePath = [ejectables valueForKey:title];
	if(![self unmountAtPath:volumePath withDisplayName:title]) {
		[self bringForward];
		NSAlert *alert = [NSAlert alertWithMessageText:MCE_ERROR_VOLUME  \
						defaultButton:NULL alternateButton:NULL otherButton:NULL \
						informativeTextWithFormat:[NSString stringWithFormat:MCE_ERROR_VOLUME_ERROR,[title UTF8String]]];
		[alert setAlertStyle:NSCriticalAlertStyle];
		[alert runModal];
	}
	//[ejectables removeObjectForKey:title];
	//[self updateAll];
}

/**
 * Brings this application forward, for modal windows.
 */
- (void) bringForward {
	//NSString *appPath = [workspace absolutePathForAppBundleWithIdentifier:@"com.codeendeavor.ejectlet"];
	[workspace launchApplication:[[NSBundle mainBundle] bundlePath]];
}

/**
 * Discovers volumes that are unmountable.
 */
- (void) discoverVolumes {
	
	NSString *object;
	NSString *volumeName;
	NSEnumerator *enumer;
	
	[ejectables release];
	ejectables = [[[NSMutableDictionary alloc] init] retain];
	
	mediaNames = [workspace mountedRemovableMedia];
	volumePaths = [workspace mountedLocalVolumePaths];
	
	enumer = [mediaNames objectEnumerator];
	while(object = [enumer nextObject]) {
		volumeName = [fileman displayNameAtPath:object];
		if([ignoreVolumes containsObject:volumeName]) continue;
		if([ejectables doesContain:object]) continue;
		[ejectables setObject:object forKey:volumeName];
	}
	
	enumer = [volumePaths objectEnumerator];
	while(object = [enumer nextObject]) {
		volumeName = [fileman displayNameAtPath:object];
		if([ignoreVolumes containsObject:volumeName]) continue;
		if([ejectables doesContain:object]) continue;
		[ejectables setObject:object forKey:volumeName];
	}
}

/**
 * Deallocation
 */
- (void) dealloc {
	[super dealloc];
	[menu release];
	[statusitem release];
	[ejectables release];
	[menufont release];
	[stringAttributeDict release];
}

/**
 * Action for the quit item.
 */
- (void) quit:(id) sender {
	[application terminate:self];
}

@end
