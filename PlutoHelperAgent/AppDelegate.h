//
//  AppDelegate.h
//  PlutoHelperAgent
//
//  Created by localhome on 29/06/2016.
//  Copyright (c) 2016 Guardian News & Media. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface AppDelegate : NSObject <NSApplicationDelegate>

@property (weak) IBOutlet NSMenu *statusMenu;
@property (strong, nonatomic) NSStatusItem *statusBar;

@end

