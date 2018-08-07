//
//  AppDelegate.m
//  PlutoHelperAgent
//
//  Created by localhome on 29/06/2016.
//  Copyright (c) 2016 Guardian News & Media. All rights reserved.
//

#import "AppDelegate.h"
#import "ProjectLockerAndKeychainFunctions.h"
#import <dispatch/dispatch.h>

@interface AppDelegate ()

@property (weak) IBOutlet NSWindow *window;
@end

@implementation AppDelegate
@synthesize errorAlert;
@synthesize statusBar;
@synthesize connectionWorking;

int connectionAttempts = 0;

- (id)init
{
    self=[super init];
    [[NSAppleEventManager sharedAppleEventManager]
     setEventHandler:self
     andSelector:@selector(getUrl:withReplyEvent:)
 		  forEventClass:kInternetEventClass
     andEventID:kAEGetURL];

    [self addObserver:self
           forKeyPath:@"connectionWorking"
              options:NSKeyValueObservingOptionNew
              context:nil];
    
    return self;
}

- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary<NSString *,id> *)change
                       context:(void *)context {
    if([keyPath compare:@"connectionWorking"]==0){
        NSNumber *newValue = [change valueForKey:NSKeyValueChangeNewKey];
        if([newValue boolValue]){   //we're now working
            [self.statusBar setImage:[NSImage imageNamed:@"PlutoIcon"]];
        } else {    //we're now not working
            [self.statusBar setImage:[NSImage imageNamed:@"PlutoIconError"]];
        }
    } else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
    
}

- (void)basicErrorMessage:(NSString *)msg informativeText:(NSString *)informativeText
{
    NSAlert *alert = [[NSAlert alloc] init];
    [alert setMessageText:msg];
    [alert setInformativeText:informativeText];
    [alert addButtonWithTitle:@"Okay"];
    [alert runModal];
}

void (^errorHandlerBlock)(NSURLResponse *response, NSError *error) = ^void(NSURLResponse *response, NSError *error){
    NSAlert *alert = [[NSAlert alloc] init];
    [alert addButtonWithTitle:@"Okay"];
    [alert setMessageText:@"Could not communicate with projectlocker"];
    [alert setInformativeText:[error localizedDescription]];
    [alert runModal];
};


- (void)tryOpenProject:(NSString *)projectid
{
    [ProjectLockerAndKeychainFunctions get_data_from_server:@"/api/project/"
                                                           :@"/files"
                                                           :projectid
                                          completionHandler:^void (NSURLResponse *response,NSDictionary *filesResult){
        [ProjectLockerAndKeychainFunctions get_data_from_server:@"/api/storage/"
                                                               :NULL
                                                               :filesResult[@"files"][0][@"storage"]
                                              completionHandler:^(NSURLResponse *response, NSDictionary *storageResult) {
            if (storageResult[@"result"][@"clientpath"] == NULL) {
                NSAlert *alert = [[NSAlert alloc] init];
                
                [alert addButtonWithTitle:@"Okay"];
                
                NSString *message = [NSString stringWithFormat: @"No client path on storage ID %@", filesResult[@"files"][0][@"storage"]];
                
                [alert setMessageText:message];
                
                [alert setInformativeText:@"Can't open project, because it's on a storage which has no client path set.\n\nPlease contact multimediatech@theguardian.com."];
            
                [alert setAlertStyle:NSWarningAlertStyle];
                
                if ([alert runModal] == NSAlertFirstButtonReturn) {
                    
                }
                
            } else {
                NSAlert *alert = [[NSAlert alloc] init];
                NSString *helperScript = [[NSUserDefaults standardUserDefaults] stringForKey:@"local_shell_script"];
                
                if([helperScript compare:@""]==0){
                    dispatch_async(dispatch_get_global_queue(0, 0), ^{
                        [alert setMessageText:@"Setup problem"];
                        [alert setInformativeText:@"Your mac does not appear to be set up correctly, no helper script is configured. Please contact multimediatech@theguardian.com."];
                        [alert setAlertStyle:NSWarningAlertStyle];
                        [alert runModal];
                    });
                    return;
                }
                
                NSString *pathToUse = [NSString stringWithFormat: @"%@/%@", storageResult[@"result"][@"clientpath"], filesResult[@"files"][0][@"filepath"]];
                NSLog(@"Going to run %@ %@", helperScript, pathToUse);
                
                NSTask *task = [[NSTask alloc] init];
                NSPipe *stdOutPipe = [NSPipe pipe];
                NSPipe *stdErrPipe = [NSPipe pipe];
                
                [task setLaunchPath:helperScript];
                [task setArguments:[NSArray arrayWithObjects:pathToUse, nil]];
                [task setStandardOutput:stdOutPipe];
                [task setStandardError:stdErrPipe];
                [task setStandardInput:[NSPipe pipe]];
                
                [task setTerminationHandler:^(NSTask *finishedTask){
                    if([finishedTask terminationStatus]!=0){
                        //[alert runModal] must be called on main thread. See https://stackoverflow.com/questions/4892182/run-method-on-main-thread-from-another-thread
                        dispatch_async(dispatch_get_global_queue(0, 0), ^{
                            [alert setMessageText:@"Open script failed"];
                            [alert setInformativeText:[NSString stringWithFormat:@"Couldn't open your project, because the open script returned error code %d.\n%@\n%@\n\nPlease contact multimediatech@theguardian.com and send a copy of this message",
                                                       [finishedTask terminationStatus],
                                                       [self getPipeData:stdOutPipe],
                                                       [self getPipeData:stdErrPipe]
                                                       ]
                             ];
                            [alert setAlertStyle:NSWarningAlertStyle];
                            [alert runModal];
                        });
                    }
                    if([finishedTask terminationReason]!=NSTaskTerminationReasonExit){
                        dispatch_async(dispatch_get_global_queue(0, 0), ^{
                            [alert setInformativeText:
                             [NSString stringWithFormat:@"Open script failed because the open script terminated unexpectedly.\n%@\n%@\nPlease contact multimediatech@theguardian.com and send a copy of this message",
                              [self getPipeData:stdOutPipe],
                              [self getPipeData:stdErrPipe]
                              ]];
                            
                            [alert setMessageText:@"Open script failed"];
                            [alert setAlertStyle:NSWarningAlertStyle];
                            [alert runModal];
                        });
                    }
                }];
                [task launch];
            }
        } errorHandler:errorHandlerBlock];
    } errorHandler:errorHandlerBlock];
}

- (void)showError:(NSString *)showError informativeText:(NSString *)informativeText showPrefs:(BOOL)showPrefs
{
    NSAlert *alert = [[NSAlert alloc] init];
    [alert setMessageText:showError];
    [alert setInformativeText:informativeText];
    [alert addButtonWithTitle:@"Okay"];
    if (showPrefs == YES) {
        [NSApp setActivationPolicy:NSApplicationActivationPolicyAccessory];
        [[self prefsWindow] setLevel:NSFloatingWindowLevel];
        [[[self prefsWindow] windowController] showWindow:self];
    }
    [alert runModal];
}

-    (void)getUrl:(NSAppleEventDescriptor *)event
   withReplyEvent:(NSAppleEventDescriptor *)replyEvent
{
    //we are expecting something in the form of pluto:action:data
    NSString *url = [[event paramDescriptorForKeyword:keyDirectObject] stringValue];
    
    
    // Now you can parse the URL and perform whatever action is needed
    NSArray *parts = [url componentsSeparatedByString:@":"];
    
    // Check the action, and then perform it
    NSString *action = [parts objectAtIndex:1];
    
    // Check the action string to see if we recognise it
    
    if ([action isEqualToString:@"openfolder"]){
        
        NSWorkspace *ws = [NSWorkspace sharedWorkspace];
        NSFileManager *fm =[NSFileManager defaultManager];
        NSURL *folderUrl = [NSURL URLWithString:[parts objectAtIndex:2]];
        NSString *folderToOpen = [folderUrl path];
        BOOL isDir = NO;
        
        // Search and replace the first path component replacing /srv/ with /Volumes/
        
        NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"^/srv/" options:NSRegularExpressionCaseInsensitive error:nil];
        folderToOpen = [regex stringByReplacingMatchesInString:folderToOpen options:0 range:NSMakeRange(0, [folderToOpen length]) withTemplate:@"/Volumes/"];
        
        // Check if the folder is an available directory
        [fm fileExistsAtPath:folderToOpen isDirectory:&isDir];
        
        if (!folderToOpen){
            NSLog(@"No folder path passed.");
            [self basicErrorMessage:@"Internal error" informativeText:@"No path to open was found, this shouldn't happen and is probably a bug in PlutoHelperAgent.  Please contact multimediatech@guardian.co.uk to report this."];
            return;
        }
        
        if (!isDir){
            NSLog(@"%@ is not a valid path on this filesystem.", folderToOpen);
            NSString *errorInfo = [NSString stringWithFormat:@"Could not find folder at %@.\n\nDo you have the SAN volumes mounted?\n\nContact multimediatech@theguardian.co.uk for help.", folderToOpen];
            
            [self basicErrorMessage:@"Asset folder not found" informativeText:errorInfo];
            return;
        }
        
        if (folderToOpen && isDir) {
            // Actually perform the action
            [ws openFile:folderToOpen withApplication:@"Finder"];
        }
        
    } else if ([action isEqualToString:@"openproject"]){
        
        NSString *projectid = [parts objectAtIndex:2];
        
    
        [ProjectLockerAndKeychainFunctions check_logged_in:^(enum ReturnValues connectionStatus) {

            switch(connectionStatus){
                case ALLOK:
                    [self tryOpenProject:projectid];
                    break;
                case PERMISSION_DENIED:
                    if (connectionAttempts == 0) {
                        connectionAttempts = connectionAttempts + 1;
                        NSDictionary *keychainData = [ProjectLockerAndKeychainFunctions load_data_from_keychain];
                        
                        [ProjectLockerAndKeychainFunctions login_to_project_server:[keychainData valueForKey:@"username"]
                                                                          password:[keychainData valueForKey:@"password"]
                                                                 completionHandler:^(enum ReturnValues loginResult) {
                            if(loginResult!=ALLOK) {
                                NSLog(@"Could not log in to projectlocker - error was %lu", (unsigned long)loginResult);
                                [self showError:@"Permission Denied" informativeText:@"Please check you have entered your username and password correctly." showPrefs:YES];
                            }
                        } errorHandler:^(NSURLResponse *response, NSError *err) {
                            [self setErrorAlert:[err localizedDescription]];
                            NSLog(@"Could not log in to projectlocker: %@", [err localizedDescription]);
                        }];
                        break;
                    }
                    [self showError:@"Permission Denied" informativeText:@"Please check you have entered your username and password correctly." showPrefs:YES];
                    break;
                case SERVER_ERROR:
                    [self showError:@"Server Error" informativeText:@"An error occurred on the server. Please report this error to multimediatech@theguardian.com" showPrefs:NO];
                    break;
                default:
                    [self showError:@"Unknown Error" informativeText:@"An unknown error occurred. Please report this error to multimediatech@theguardian.com" showPrefs:NO];
                    break;
            }
            
            } errorHandler:^(NSURLResponse *response, NSError *error) {
                [self basicErrorMessage:@"Error Checking Log In Status" informativeText:@"An error occurred when attempting to check if the user is logged in."];
                NSLog(@"Error Checking Log In Status: %@", error);
        }];

    } else {
        NSLog(@"%@ is not a recognised action for this helper", action);
        [self basicErrorMessage:@"Action not supported"
                informativeText:[NSString stringWithFormat:@"%@ is not a recognised action for this helper", action]
         ];
    }
    
}

- (NSString *)getPipeData:(NSPipe *)pipe {
    NSFileHandle *fp = [pipe fileHandleForReading];
    NSData *d = [fp readDataToEndOfFile];
    return [[NSString alloc] initWithData:d encoding:NSUTF8StringEncoding];
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    // Insert code here to initialize your application
    self.statusBar = [[NSStatusBar systemStatusBar] statusItemWithLength:NSVariableStatusItemLength];
    
    //set up the status bar
    //self.statusBar.image = [NSImage imageNamed:@"PlutoIcon"];
    self.statusBar.menu = self.statusMenu;
    self.statusBar.highlightMode = YES;
    [self setConnectionWorking:[NSNumber numberWithBool:YES]];
    
    NSDictionary *keychainData = [ProjectLockerAndKeychainFunctions load_data_from_keychain];
    
    [ProjectLockerAndKeychainFunctions login_to_project_server:[keychainData valueForKey:@"username"]
                                                      password:[keychainData valueForKey:@"password"]
                                             completionHandler:^(enum ReturnValues loginResult) {
        if(loginResult!=ALLOK) {
            [self setConnectionWorking:[NSNumber numberWithBool:NO]];
            [self setErrorAlert:@"Could not log in to projectlocker"];
            NSLog(@"Could not log in to projectlocker - error was %lu", (unsigned long)loginResult);
        }
    } errorHandler:^(NSURLResponse *response, NSError *err) {
        self.statusBar.image = [NSImage imageNamed:@"PlutoIconError"];
        [self setErrorAlert:[err localizedDescription]];
        NSLog(@"Could not log in to projectlocker: %@", [err localizedDescription]);
    }];
}

- (void)applicationWillTerminate:(NSNotification *)aNotification {
    // Insert code here to tear down your application
    NSLog(@"Application about to quit.");
//    [ProjectLockerAndKeychainFunctions logout_of_project_server];
//    sleep(1);
}

- (void) awakeFromNib {
    
}

- (IBAction)preferencesClicked:(id)sender {
    [NSApp setActivationPolicy:NSApplicationActivationPolicyAccessory];
    [[self prefsWindow] setLevel:NSFloatingWindowLevel];
    [[[self prefsWindow] windowController] showWindow:self];
}
@end
