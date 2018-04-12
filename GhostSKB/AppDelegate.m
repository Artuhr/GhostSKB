//
//  AppDelegate.m
//  testApp
//
//  Created by 丁明信 on 4/4/16.
//  Copyright © 2016 丁明信. All rights reserved.
//

#import "AppDelegate.h"
#import "PopoverViewController.h"
#import "GHDefaultManager.h"
#import "Constant.h"

#import <AppKit/AppKit.h>
#import <Carbon/Carbon.h>
#import <ApplicationServices/ApplicationServices.h>
@interface AppDelegate ()

- (void)toggleDarkModeTheme;
- (void)updateProfilesMenu:(NSMenu *)menu;
@end


@implementation AppDelegate
@synthesize preferenceController;
@synthesize isBecomeActiveTheFirstTime;
#pragma mark - App Life Cycle


- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    NSNotificationCenter *nc = [[NSWorkspace sharedWorkspace] notificationCenter];
    [nc addObserver:self selector:@selector(handleAppActivateNoti:) name:NSWorkspaceDidActivateApplicationNotification object:NULL];
    [nc addObserver:self selector:@selector(handleAppUnhideNoti:) name:NSWorkspaceDidUnhideApplicationNotification object:NULL];
    
    [[NSDistributedNotificationCenter defaultCenter] addObserver:self selector:@selector(darkModeChanged:) name:@"AppleInterfaceThemeChangedNotification" object:nil];
    
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleGHAppSelectedNoti:) name:GH_NK_APP_SELECTED object:NULL];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(profileListChanged) name:GH_NK_PROFILE_LIST_CHANGED object:NULL];
    [GHDefaultManager getInstance];
    
    [self initStatusItem];
    [self initPopover];
    [self toggleDarkModeTheme];
    isBecomeActiveTheFirstTime = true;
}

- (void)applicationDidBecomeActive:(NSNotification *)notification
{
    if (isBecomeActiveTheFirstTime) {
        isBecomeActiveTheFirstTime = false;
    }
    else {
        //再次点击的时候显示icon
        [statusItem setVisible:true];
    }
}

- (void)applicationWillTerminate:(NSNotification *)aNotification {
    // Insert code here to tear down your application
}

- (void)awakeFromNib {
    [imenu setDelegate:self];
}


+ (BOOL)isSystemCurrentDarkMode {
    NSDictionary *globalPersistentDomain = [[NSUserDefaults standardUserDefaults] persistentDomainForName:NSGlobalDomain];
    @try {
        NSString *interfaceStyle = [globalPersistentDomain valueForKey:@"AppleInterfaceStyle"];
        return [interfaceStyle isEqualToString:@"Dark"];
    }
    @catch (NSException *exception) {
        return NO;
    }
}

- (void)initPopover {
    popover = [[NSPopover alloc] init];
    popover.behavior = NSPopoverBehaviorTransient;
    popover.contentViewController = [[PopoverViewController alloc] init];
}

- (void)initStatusItem {
    statusItemSelected = false;
    NSString *imageName = @"ghost_dark_small";
    NSImage *normalImage = [NSImage imageNamed:imageName];
    [normalImage setTemplate:YES];
    
    statusItem = [[NSStatusBar systemStatusBar] statusItemWithLength:NSVariableStatusItemLength];
    statusItem.highlightMode = YES;
    statusItem.image = normalImage;
    
    //menus
    NSMenu *menu = [[NSMenu alloc] init];
    [self updateProfilesMenu:menu];
    [menu addItem:[NSMenuItem separatorItem]];
    [menu addItem:[[NSMenuItem alloc] initWithTitle:@"Preference..." action:@selector(showPreference) keyEquivalent:@","]];
    [menu addItem:[[NSMenuItem alloc] initWithTitle:@"Disable GhostSKB" action:@selector(toggleGhostSKB:) keyEquivalent:@""]];
    [menu addItem:[NSMenuItem separatorItem]];
    [menu addItem:[[NSMenuItem alloc] initWithTitle:@"Quit GhostSKB" action:@selector(quitGhostSKB) keyEquivalent:@"Q"]];
    statusItem.menu = menu;
    
    [statusItem.button setAction:@selector(onStatusItemSelected:)];
}

//TODO sort
- (void)updateProfilesMenu:(NSMenu *)menu {
    NSArray *profiles = [[GHDefaultManager getInstance] getProfileList];
    profiles = [profiles sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
        NSString *str1 = (NSString *)obj1;
        NSString *str2 = (NSString *)obj2;
        return [str1 compare:str2];
    }];
    NSString *defaultProfile = [[GHDefaultManager getInstance] getDefaultProfileName];
    for (NSInteger i=0; i<[profiles count]; i++) {
        NSString *profileName = (NSString *)[profiles objectAtIndex:i];
        NSMenuItem *item = [[NSMenuItem alloc] initWithTitle:profileName action:@selector(chooseProfile:) keyEquivalent:@""];
        [menu insertItem:item atIndex:i];
        if([profileName isEqualToString:defaultProfile]) {
            [item setState:NSOnState];
        }
        else {
            [item setState:NSOffState];
        }
    }
}

- (void)chooseProfile:(id)sender {
    NSMenuItem *item = (NSMenuItem *)sender;
    NSLog(@"chooseProfile: %@", item.title);
    
}

- (void)profileListChanged {
    NSMenu *menu = statusItem.menu;
    for (NSMenuItem *item in menu.itemArray) {
        if ([item.title isEqualToString:@""] || item.title == NULL) {
            break;
        }
        [menu removeItem:item];
    }
    
    [self updateProfilesMenu:menu];
}

- (void)toggleGhostSKB:(id)sender {
    NSMenuItem *item = (NSMenuItem *)sender;
    if ([sender respondsToSelector:@selector(setState:)]) {
        [item setState:NSOnState];
    }
}

- (void)quitGhostSKB {
    
}

- (void)showPreference {
    NSStoryboard *board = [NSStoryboard storyboardWithName:@"Storyboard" bundle:nil];
    
    if (preferenceController == NULL) {
        preferenceController = [board instantiateInitialController];
    }
    [preferenceController showWindow:nil];
    [NSApp activateIgnoringOtherApps:YES];
}

-(void)darkModeChanged:(NSNotification *)notif
{
    [self toggleDarkModeTheme];
}

-(void)toggleDarkModeTheme
{
    popover.appearance = [NSAppearance appearanceNamed:NSAppearanceNameAqua];
    PopoverViewController *controller = (PopoverViewController *)popover.contentViewController;
    [controller toggleDarkMode];

}

- (void) onStatusItemSelected:(id) sender {
    statusItemSelected = !statusItemSelected;
//    [self showPopover:sender];
}

- (void)showPopover:(id)sender {
    NSStatusBarButton* button = statusItem.button;
    _statusBarButton = button;
    if (popover.isShown) {
        [popover performClose:button];
    }
    else {
        //get forcus
        [[NSRunningApplication currentApplication] activateWithOptions:NSApplicationActivateIgnoringOtherApps];
        //show popover
        [popover showRelativeToRect:button.bounds ofView:button preferredEdge:NSRectEdgeMaxY];
    }
}

- (NSMutableString *)getCurrentInputSourceId
{
    TISInputSourceRef inputSource = TISCopyCurrentKeyboardInputSource();
    NSMutableString *inputId = (__bridge NSMutableString *)(TISGetInputSourceProperty(inputSource, kTISPropertyInputSourceID));
    return inputId;
}

- (void)doChangeInputSource:(NSString *)targetInputId
{
    TISInputSourceRef inputSource = NULL;
    TISInputSourceRef currentInputSource = TISCopyCurrentKeyboardInputSource();
    NSMutableString *currentInputSourceId = (__bridge NSMutableString *)(TISGetInputSourceProperty(currentInputSource, kTISPropertyInputSourceID));
    if ([targetInputId isEqualToString:currentInputSourceId]) {
        return;
    }
    NSDictionary *property=[NSDictionary dictionaryWithObject:(NSString*)kTISCategoryKeyboardInputSource
                                                      forKey:(NSString*)kTISPropertyInputSourceCategory];
    CFArrayRef availableInputs = TISCreateInputSourceList((__bridge CFDictionaryRef)property, FALSE);
    NSUInteger count = CFArrayGetCount(availableInputs);
    
    
    
    for (int i = 0; i < count; i++) {
        inputSource = (TISInputSourceRef)CFArrayGetValueAtIndex(availableInputs, i);
        
        //获取输入源的id
        NSMutableString *inputSourceId = (__bridge NSMutableString *)(TISGetInputSourceProperty(inputSource, kTISPropertyInputSourceID));
        if ([inputSourceId isEqualToString:targetInputId]) {
            NSNumber* pIsSelectCapable = (__bridge NSNumber*)(TISGetInputSourceProperty(inputSource, kTISPropertyInputSourceIsSelectCapable));
            BOOL canSelect = [pIsSelectCapable boolValue];
            
            NSNumber *pIsEnableCapable= (__bridge NSNumber *)(TISGetInputSourceProperty(inputSource, kTISPropertyInputSourceIsEnableCapable));
            BOOL canEnable = [pIsEnableCapable boolValue];
            if (canEnable) {
                TISEnableInputSource(inputSource);
            }
            if (canSelect) {
                TISSelectInputSource(inputSource);
            }
            
            break;
        }
    }
}

- (void) handleAppUnhideNoti:(NSNotification *)noti {
    NSRunningApplication *runningApp = (NSRunningApplication *)[noti.userInfo objectForKey:@"NSWorkspaceApplicationKey"];
    NSString *identifier = runningApp.bundleIdentifier;
    [self changeInputSourceForApp:identifier];
}

- (void) handleAppActivateNoti:(NSNotification *)noti {
    
    _lastAppInputSourceId = [self getCurrentInputSourceId];
    NSRunningApplication *runningApp = (NSRunningApplication *)[noti.userInfo objectForKey:@"NSWorkspaceApplicationKey"];
    NSString *identifier = runningApp.bundleIdentifier;
    [self changeInputSourceForApp:identifier];
}

- (void)changeInputSourceForApp:(NSString *)bundleId {
    NSString *targetInputId = [[GHDefaultManager getInstance] getInputId:bundleId withProfile:NULL];
    
    if (targetInputId != NULL) {
        [self performSelector:@selector(doChangeInputSource:) withObject:targetInputId afterDelay:0.018];
    }
}

- (void) changeStatusItemImage:(BOOL)isLight {
    if (isLight) {
        statusItem.image = [NSImage imageNamed:@"ghost_white_small"];
    }
    else {
        statusItem.image =[NSImage imageNamed:@"ghost_dark_small"];
    }
}
- (void) handleGHAppSelectedNoti:(NSNotification *)noti {
    //get forcus
    [[NSRunningApplication currentApplication] activateWithOptions:NSApplicationActivateIgnoringOtherApps];
    //show popover
    [popover showRelativeToRect:_statusBarButton.bounds ofView:_statusBarButton preferredEdge:NSRectEdgeMaxY];
}

@end
