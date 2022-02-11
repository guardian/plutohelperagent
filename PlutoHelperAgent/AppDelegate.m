//
//  AppDelegate.m
//  PlutoHelperAgent
//
//  Created by localhome on 29/06/2016.
//  Copyright (c) 2016 Guardian News & Media. All rights reserved.
//

#import "AppDelegate.h"
#import <dispatch/dispatch.h>

@interface AppDelegate ()

@property (weak) IBOutlet NSWindow *window;
@end

@implementation AppDelegate
@synthesize errorAlert;
@synthesize statusBar;
@synthesize connectionWorking;

- (id)init
{
    self=[super init];
    [[NSAppleEventManager sharedAppleEventManager]
     setEventHandler:self
     andSelector:@selector(getUrl:withReplyEvent:)
 		  forEventClass:kInternetEventClass
     andEventID:kAEGetURL];
    
    return self;
}

- (void)basicErrorMessage:(NSString *)msg informativeText:(NSString *)informativeText
{
    [self showError:msg informativeText:informativeText showPrefs:false];
}

void (^errorHandlerBlock)(NSURLResponse *response, NSError *error) = ^void(NSURLResponse *response, NSError *error){

    dispatch_async(dispatch_get_main_queue(), ^{    //we can't call the member function as we are not in the class here
        NSAlert *alert = [[NSAlert alloc] init];
        [alert addButtonWithTitle:@"Okay"];
        [alert setMessageText:@"Could not communicate with projectlocker"];
        [alert setInformativeText:[error localizedDescription]];
        [alert runModal];
    });
};


- (void)tryOpenProject:(NSString *)projectPath
{

    NSString *helperScript = [[NSUserDefaults standardUserDefaults] stringForKey:@"local_shell_script"];

    if([helperScript compare:@""]==0){
        dispatch_async(dispatch_get_main_queue(), ^{
            NSAlert *alert = [[NSAlert alloc] init];
            [alert setMessageText:@"Setup problem"];
            [alert setInformativeText:@"Your mac does not appear to be set up correctly, no helper script is configured. Please contact multimediatech@theguardian.com."];
            [alert setAlertStyle:NSWarningAlertStyle];
            [alert runModal];
        });
        return;
    }

    NSString *pathToUse = [NSString stringWithFormat: @"%@", projectPath];
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
            NSLog(@"Error attempting to run the script %@ on the path %@. The attempt finished with the status %d.", helperScript, pathToUse, [finishedTask terminationStatus]);
            //[alert runModal] must be called on main thread. See https://stackoverflow.com/questions/4892182/run-method-on-main-thread-from-another-thread
            dispatch_async(dispatch_get_main_queue(), ^{
                NSAlert *alert = [[NSAlert alloc] init];
                [alert setMessageText:@"Opening Project Failed"];
                [alert setInformativeText:[NSString stringWithFormat:@"Couldn’t open your project as it appears you may not have all the required Multimedia production drives mounted.\n\nRestarting your Mac should mount the drives, if they still don’t appear try contacting multimediatech@guardian.co.uk and send a copy of this message."
                                           ]
                 ];
                [alert setAlertStyle:NSWarningAlertStyle];
                [alert runModal];
            });
        }
        if([finishedTask terminationReason]!=NSTaskTerminationReasonExit){
            dispatch_async(dispatch_get_main_queue(), ^{
                NSAlert *alert = [[NSAlert alloc] init];
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

- (void)showError:(NSString *)showError informativeText:(NSString *)informativeText showPrefs:(BOOL)showPrefs
{
    dispatch_async(dispatch_get_main_queue(), ^{
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
    });
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
            NSString *errorInfo = [NSString stringWithFormat:@"Could not find the requested folder at:\n\n%@.\n\nDo you have the Multimedia production drives mounted?\n\nIf not, rebooting your mac should mount them or try contacting multimediatech@guardian.co.uk for help.", folderToOpen];
            
            [self basicErrorMessage:@"Asset folder not found" informativeText:errorInfo];
            return;
        }
        
        NSString *assetWhiteListString = [[NSUserDefaults standardUserDefaults] stringForKey:@"asset_white_list"];
        NSArray *assetWhiteList = [assetWhiteListString componentsSeparatedByString:@","];
        BOOL pathGood = false;
        for (id item in assetWhiteList) {
            if ([folderToOpen hasPrefix:item]) {
                pathGood = true;
            }
        }
        
        if (!pathGood) {
            NSLog(@"PlutoHelperAgent could not open the folder at: %@ due to its path not being in the white list.", folderToOpen);
            [self basicErrorMessage:@"Could not open folder"
                    informativeText:[NSString stringWithFormat:@"The folder at %@ could not be opened because its path is not in the white list.", folderToOpen]
             ];
        }
        
        if (folderToOpen && isDir && pathGood) {
            // Actually perform the action
            [ws openFile:folderToOpen withApplication:@"Finder"];
        }
        
    } else if ([action isEqualToString:@"openproject"]){
        NSString *projectPath = [parts objectAtIndex:2];
        
        NSString *pathsWhiteListString = [[NSUserDefaults standardUserDefaults] stringForKey:@"paths_white_list"];
        NSArray *pathsWhiteList = [pathsWhiteListString componentsSeparatedByString:@","];
        BOOL pathGood = false;
        for (id item in pathsWhiteList) {
            if ([projectPath hasPrefix:item]) {
                pathGood = true;
            }
        }

        NSString *extensionsWhiteListString = [[NSUserDefaults standardUserDefaults] stringForKey:@"extensions_white_list"];
        NSArray *extensionsWhiteList = [extensionsWhiteListString componentsSeparatedByString:@","];
        BOOL extensionGood = false;
        for (id item in extensionsWhiteList) {
            if ([projectPath hasSuffix:item]) {
                extensionGood = true;
            }
        }
        
        if (pathGood && extensionGood) {
            [self tryOpenProject:projectPath];
        } else {
            if (pathGood) {
                NSLog(@"PlutoHelperAgent could not open the file at: %@ due to its extension not being in the white list.", projectPath);
                [self basicErrorMessage:@"Could not open file"
                        informativeText:[NSString stringWithFormat:@"The file at %@ could not be opened because its extension is not in the white list.", projectPath]
                 ];
            } else if (extensionGood) {
                NSLog(@"PlutoHelperAgent could not open the file at: %@ due to its path not being in the white list.", projectPath);
                [self basicErrorMessage:@"Could not open file"
                        informativeText:[NSString stringWithFormat:@"The file at %@ could not be opened because its path is not in the white list.", projectPath]
                 ];
            } else {
                NSLog(@"PlutoHelperAgent could not open the file at: %@ due to its path and extension not being in the correct white lists.", projectPath);
                [self basicErrorMessage:@"Could not open file"
                        informativeText:[NSString stringWithFormat:@"The file at %@ could not be opened because its path and extension are not in the correct white lists.", projectPath]
                 ];
            }
        }

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
}

- (void)applicationWillTerminate:(NSNotification *)aNotification {
    // Insert code here to tear down your application
    NSLog(@"Application about to quit.");
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
