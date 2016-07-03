//
//  PopoverViewController.m
//  GhostSKB
//
//  Created by 丁明信 on 16/4/6.
//  Copyright © 2016年 丁明信. All rights reserved.
//

#import "PopoverViewController.h"
#import "GHInputDefaultCellView.h"
#import "GHInputAddDefaultCellView.h"
#import "GHDefaultManager.h"
#import "AppListController.h"
#import "GHDefaultInfo.h"

@interface PopoverViewController ()

@end

@implementation PopoverViewController
@synthesize appPopOver;
@synthesize defaultKeyBoards;

- (void)viewDidLoad {
    [super viewDidLoad];
    
    _tableView.dataSource = self;
    _tableView.delegate = self;
//    _tableView.gridStyleMask = NSTableViewSolidHorizontalGridLineMask;
    _tableView.headerView = NULL;
    self.defaultKeyBoards = [[GHDefaultManager getInstance] getDefaultKeyBoards];
    
    //init app popover
    self.appPopOver = [[NSPopover alloc] init];
    self.appPopOver.contentViewController = [[AppListController alloc] init];
    self.appPopOver.behavior = NSPopoverBehaviorTransient;
}

#pragma mark - table view datasource

-(NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
    NSInteger num = [self.defaultKeyBoards count] + 1;
    return num;
}


// for view-based tableview
-(NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
    
    if (row < [self.defaultKeyBoards count]) {
        GHInputDefaultCellView *view = [tableView makeViewWithIdentifier:@"MainCell" owner:self];
        return view;
    }
    else {
        GHInputAddDefaultCellView *view = [tableView makeViewWithIdentifier:@"BottomCell" owner:self];
        return view;
    }

}


#pragma mark - table view delegate


- (IBAction)onAddDefault:(id)sender {
    BOOL hasEmptyEntry = [self checkEmptyEntryInList];
    if (hasEmptyEntry) {
        NSLog(@"有空列表项");
        return;
    }
    
    GHDefaultInfo *info = [[GHDefaultInfo alloc] init];
    [self.defaultKeyBoards addObject:info];
    [self.tableView reloadData];
}

- (IBAction)onRemoveDefault:(id)sender {
    
    NSInteger row = [_tableView rowForView:(NSView *)sender];
    NSLog(@"on remove clicked, row:%d", row);
    
    [self.defaultKeyBoards removeObjectAtIndex:row];
    [self.tableView reloadData];
}

- (IBAction)onAppButtonClick:(id)sender {
    NSLog(@"onAppPopButtonClick");
    [self showOpenPanel];
}

- (BOOL)checkEmptyEntryInList{
    for (GHDefaultInfo *info in self.defaultKeyBoards) {
        if (info.appBundleId == NULL) {
            return TRUE;
        }
    }
    return FALSE;
}

- (void)showAppListController:(id)sender {
    if ([self.appPopOver isShown]) {
        [self.appPopOver performClose:nil];
    }
    else {
        NSButton *button = (NSButton *)sender;
        [self.appPopOver showRelativeToRect:button.bounds ofView:button preferredEdge:NSRectEdgeMinX];
    }
}

- (void)showOpenPanel {
    NSOpenPanel *panel = [NSOpenPanel openPanel];
    NSArray *appDirs = NSSearchPathForDirectoriesInDomains(NSApplicationDirectory, NSLocalDomainMask, YES);
    NSString *appDir = [appDirs objectAtIndex:0];
    [panel setDirectoryURL:[NSURL URLWithString:appDir]];
    [panel setCanChooseFiles:YES];
    [panel setCanChooseDirectories:NO];
    [panel setAllowsMultipleSelection:NO]; // yes if more than one dir is allowed
    
    NSInteger clicked = [panel runModal];
    
    if (clicked == NSFileHandlingPanelOKButton) {
        for (NSURL *url in [panel URLs]) {
            NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:url, @"appUrl", nil];
            [[NSNotificationCenter defaultCenter] postNotificationName:@"GH_APP_SELECTED" object:NULL userInfo:userInfo];
            // do something with the url here.
//            NSLog(@"=-=-=-=-=%@", [url description]);
        }
    }
}

- (IBAction)onInputSourcePopButtonClick:(id)sender {
}
@end
