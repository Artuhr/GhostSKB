//
//  GHDefaultInfo.h
//  GhostSKB
//
//  Created by 丁明信 on 7/3/16.
//  Copyright © 2016 丁明信. All rights reserved.
//

#ifndef GHDefaultInfo_h
#define GHDefaultInfo_h

#import <Foundation/Foundation.h>
#import <Cocoa/Cocoa.h>
#import "Constant.h"
#import "GHDefaultManager.h"

@interface GHDefaultInfo : NSObject 

@property (nonatomic, strong) NSString* appUrl;
@property (nonatomic, strong) NSString* appBundleId;
@property (nonatomic, retain) NSString* defaultInput;

- (id)initWithAppBundle:(NSString *)bundleId appUrl:(NSString *)url input:(NSString *)defaultInput;

@end

#endif /* GHDefaultInfo_h */
