//
//  PreferencesWindowController.h
//  PlutoHelperAgent
//
//  Created by Dave Allison on 26/02/2018.
//  Copyright © 2018 Guardian News & Media. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface PreferencesWindowController : NSWindowController

@property (weak) IBOutlet NSTextField *UsernameText;

@property (weak) IBOutlet NSTextField *PasswordText;

@property (weak) IBOutlet NSTextFieldCell *StatusText;

@property (strong) NSString *errorAlert;    //text to display as an error

- (IBAction)saveClicked:(id)sender;

- (IBAction)testClicked:(id)sender;

@end
