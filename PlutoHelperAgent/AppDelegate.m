//
//  AppDelegate.m
//  PlutoHelperAgent
//
//  Created by localhome on 29/06/2016.
//  Copyright (c) 2016 Guardian News & Media. All rights reserved.
//

#import "AppDelegate.h"
#import "ProjectLockerAndKeychainFunctions.h"

@interface AppDelegate ()

@property (weak) IBOutlet NSWindow *window;
@end

@implementation AppDelegate

- (id)init
{
    self=[super init];
    [[NSAppleEventManager sharedAppleEventManager]
     setEventHandler:self
     andSelector:@selector(getUrl:withReplyEvent:)
 		  forEventClass:kInternetEventClass
     andEventID:kAEGetURL];
    
    [self setup_defaults];
    [ProjectLockerAndKeychainFunctions login_to_project_server];
    
    return self;
}


- (void)setup_defaults

{
    
    NSString *userDefaultsValuesPath = [@"~/Library/Preferences/com.GNM.PlutoHelperAgent.plist" stringByExpandingTildeInPath];
    NSDictionary *userDefaultsValuesDict;
    userDefaultsValuesDict=[NSDictionary dictionaryWithContentsOfFile:userDefaultsValuesPath];
    [[NSUserDefaults standardUserDefaults] registerDefaults:userDefaultsValuesDict];
    NSLog(@"Defaults %@", userDefaultsValuesDict);
    
}


-    (void)getUrl:(NSAppleEventDescriptor *)event
   withReplyEvent:(NSAppleEventDescriptor *)replyEvent
{
    //we are expecting something in the form of pluto:action:data
    NSString *url = [[event paramDescriptorForKeyword:keyDirectObject] stringValue];
    NSLog(@"getURL got %@",url);
    
    
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
        }
        
        if (!isDir){
            NSLog(@"%@ is not a valid path on this filesystem.", folderToOpen);
        }
        
        if (folderToOpen && isDir) {
            
            // Actually perform the action
            [ws openFile:folderToOpen withApplication:@"Finder"];
        
        }
        
    } else if ([action isEqualToString:@"openproject"]){
        
        NSString *projectid = [parts objectAtIndex:2];
        
        NSString *dataFromServer = [ProjectLockerAndKeychainFunctions get_data_from_server:@"%@/api/project/" :@"/files" :projectid];
        
        NSDictionary *results = [ProjectLockerAndKeychainFunctions parse_json:dataFromServer];

        NSString *storageDataFromServer = [ProjectLockerAndKeychainFunctions get_data_from_server:@"%@/api/storage/" :NULL :results[@"files"][0][@"storage"]];

        NSDictionary *storageResults = [ProjectLockerAndKeychainFunctions parse_json:storageDataFromServer];

        NSString *pathToUse = [NSString stringWithFormat: @"%@/%@", storageResults[@"result"][@"clientpath"], results[@"files"][0][@"filepath"]];

        NSTask *task = [[NSTask alloc] init];
        [task setLaunchPath:[[NSUserDefaults standardUserDefaults] stringForKey:@"local_shell_script"]];
        [task setArguments:[NSArray arrayWithObjects:pathToUse, nil]];
        [task setStandardOutput:[NSPipe pipe]];
        [task setStandardInput:[NSPipe pipe]];
        
        [task launch];

    } else {
        
        NSLog(@"%@ is not a recognised action for this helper", action);
        
    }
    
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    // Insert code here to initialize your application
}

- (void)applicationWillTerminate:(NSNotification *)aNotification {
    // Insert code here to tear down your application
    NSLog(@"Application about to quit.");
    [ProjectLockerAndKeychainFunctions logout_of_project_server];
    sleep(1);
}

@synthesize statusBar = _statusBar;

- (void) awakeFromNib {
    self.statusBar = [[NSStatusBar systemStatusBar] statusItemWithLength:NSVariableStatusItemLength];
    
    //self.statusBar.title = @"P";

   
    // you can also set an image
    self.statusBar.image = [NSImage imageNamed:@"PlutoIcon"];
    
    self.statusBar.menu = self.statusMenu;
    self.statusBar.highlightMode = YES;
}

- (IBAction)preferencesClicked:(id)sender {
    if(!_preferencesWindowController) {
        _preferencesWindowController = [[PreferencesWindowController alloc] initWithWindowNibName:@"PreferencesWindowController"];
    }
    [_preferencesWindowController showWindow:self];
}
@end
