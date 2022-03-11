//
//  PreferencesWindowController.h
//  PlutoHelperAgent
//
//  Created by Dave Allison on 26/02/2018.
//  Copyright © 2018 Guardian News & Media. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface PreferencesWindowController : NSWindowController

@property NSNumber *hasChanged;

- (IBAction)saveClicked:(id)sender;

@end
