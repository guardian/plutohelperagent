//
//  AppDelegate.m
//  PlutoHelperAgent
//
//  Created by localhome on 29/06/2016.
//  Copyright (c) 2016 Guardian News & Media. All rights reserved.
//

#import "AppDelegate.h"
#import <dispatch/dispatch.h>
#import "WhiteListProcessor.h"
#import "XMLDictionary.h"
#import "HelperFunctions.h"
#import "PremiereVersionUtilities.h"

@interface AppDelegate ()

@property (weak) IBOutlet NSWindow *window;
@end

@implementation AppDelegate
@synthesize errorAlert;
@synthesize statusBar;

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

    NSLog(@"Going to run %@ %@", helperScript, projectPath);

    NSTask *task = [[NSTask alloc] init];
    NSPipe *stdOutPipe = [NSPipe pipe];
    NSPipe *stdErrPipe = [NSPipe pipe];

    [task setLaunchPath:helperScript];
    [task setArguments:[NSArray arrayWithObjects:projectPath, nil]];
    [task setStandardOutput:stdOutPipe];
    [task setStandardError:stdErrPipe];
    [task setStandardInput:[NSPipe pipe]];

    [task setTerminationHandler:^(NSTask *finishedTask){
        if([finishedTask terminationStatus]!=0){
            NSLog(@"Error attempting to run the script %@ on the path %@. The attempt finished with the status %d.", helperScript, projectPath, [finishedTask terminationStatus]);
            //[alert runModal] must be called on main thread. See https://stackoverflow.com/questions/4892182/run-method-on-main-thread-from-another-thread
            dispatch_async(dispatch_get_main_queue(), ^{
                NSAlert *alert = [[NSAlert alloc] init];
                NSImage *iconImage = [NSImage imageNamed:@"DriveIcon"];
                [alert setIcon: iconImage];
                [alert setMessageText:@"Opening Project Failed"];
                [alert setInformativeText:[NSString stringWithFormat:@"Your project file could not be opened as it appears you may not have all the required Multimedia production drives mounted on your desktop.\n\nTry the “Mount Multimedia Drives” icon found on your application Dock, or in the “Hard Disk X/Applications” folder.\n\nAdditionally, try restarting your Mac. If they still do not appear after these steps contact multimediatech@guardian.co.uk and send a screenshot of this message."
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
                 [NSString stringWithFormat:@"Open script failed because the open script terminated unexpectedly.\n%@\n%@\nPlease contact multimediatech@theguardian.com and send a copy of this message along with the asset tag number of this computer.",
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
        if ([showError isEqualToString:@"Unable to Open Asset Folder"]){
            NSImage *iconImage = [NSImage imageNamed:@"DriveIcon"];
            [alert setIcon: iconImage];
        }
        if (showPrefs == YES) {
            [NSApp setActivationPolicy:NSApplicationActivationPolicyAccessory];
            [[self prefsWindow] setLevel:NSFloatingWindowLevel];
            [[[self prefsWindow] windowController] showWindow:self];
        }
        [alert runModal];
    });
}

- (void) processVersion:(NSString *)premiereVersion filePath:(NSString *)filePath {
    NSLog(@"Starting processVersion with premiereVersion: %@ and filePath: %@", premiereVersion, filePath);

    NSDictionary * premiereVersions = [[NSUserDefaults standardUserDefaults] objectForKey:@"Premiere_versions"];
    if (!premiereVersions) {
        NSLog(@"Warning: premiereVersions dictionary not found in UserDefaults.");
        return;
    }
    NSLog(@"Fetched premiereVersions from UserDefaults: %@", premiereVersions);

    NSArray *allKeys = [premiereVersions allKeys];
    NSLog(@"All available versions: %@", allKeys);

    NSArray *versionComponents = [premiereVersion componentsSeparatedByString:@"."];
    if ([versionComponents count] < 1) {
        NSLog(@"Error: Invalid premiereVersion format");
        return;
    }

    NSString *majorVersion = versionComponents[0];
    NSLog(@"Extracted major version: %@", majorVersion);

    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"SELF BEGINSWITH %@", majorVersion];
    NSArray *filteredKeys = [allKeys filteredArrayUsingPredicate:predicate];
    NSLog(@"Filtered versions with the same major version: %@", filteredKeys);

    if ([filteredKeys count] > 0) {
        NSString *latestVersion = [HelperFunctions getLatestVersion:filteredKeys];
        NSLog(@"Latest available version with the same major version: %@", latestVersion);

        NSLog(@"Launched app with version: %@", premiereVersions[latestVersion]);
        NSTask *openTask = [[NSTask alloc] init];
        [openTask setLaunchPath:@"/usr/bin/open"];
        [openTask setCurrentDirectoryPath:@"/"];
        [openTask setArguments:@[ @"-a", premiereVersions[latestVersion], filePath ]];
        [openTask launch];
    } else {
        NSString *requiredVersion = [HelperFunctions getLatestVersion:allKeys];
        NSLog(@"No matching versions found. Falling back to latest version: %@", requiredVersion);

        NSString *plutoURL = [NSString stringWithFormat:@"%@pluto-core/file/changePremiereVersion?project=%@&requiredVersion=%@", [[NSUserDefaults standardUserDefaults] stringForKey:@"pluto_url"], filePath, requiredVersion];
        [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:plutoURL]];

        NSLog(@"Opened URL for version change: %@", plutoURL);
    }
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
    
    NSDictionary * urlParams = [HelperFunctions parseURLQueryToDictionary:url];
    
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
            NSString *errorInfo = [NSString stringWithFormat:@"Your Asset Folder could not be opened as it appears you may not have all the required Multimedia production drives mounted on your desktop.\n\nTry the “Mount Multimedia Drives” icon found on your application Dock, or in the “Hard Disk X/Applications” folder.\n\nAdditionally, try restarting your Mac. If they still do not appear after these steps contact multimediatech@guardian.co.uk and send a screenshot of this message.", folderToOpen];
            
            [self basicErrorMessage:@"Unable to Open Asset Folder" informativeText:errorInfo];
            return;
        }

        BOOL pathGood = [WhiteListProcessor checkIsInWhitelist:folderToOpen whiteListName:@"asset_list" prefix:true];
        
        if (!pathGood) {
            NSLog(@"PlutoHelperAgent could not open the folder at: %@ due to its path not being in the white list.", folderToOpen);
            [self basicErrorMessage:@"Could not open folder"
                    informativeText:[NSString stringWithFormat:@"The folder at %@ could not be opened because its path is not in the white list.\n\nPlease contact multimediatech@theguardian.com if you see this error message.", folderToOpen]
             ];
        }
        
        if (folderToOpen && isDir && pathGood) {
            // Actually perform the action
            [ws openFile:folderToOpen withApplication:@"Finder"];
        }
        
    } else if ([action isEqualToString:@"openproject"]){
        NSString *projectPath = [parts objectAtIndex:2];
        NSString *decodedPath = [projectPath stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];

        
        BOOL pathGood = [WhiteListProcessor checkIsInWhitelist:decodedPath whiteListName:@"paths_list" prefix:true];
        
        BOOL extensionGood = [WhiteListProcessor checkIsInWhitelist:decodedPath whiteListName:@"extensions_list" prefix:false];
              
        if (pathGood && extensionGood) {
            NSArray *pathParts = [decodedPath componentsSeparatedByString:@"?"];
            NSString *pathPartZero = [pathParts objectAtIndex:0];
            if ((urlParams[@"premiereVersion"]) && (!urlParams[@"force"])) {
                [self processVersion:urlParams[@"premiereVersion"] filePath:pathPartZero];
            } else {
                [self tryOpenProject:pathPartZero];
            }
        } else {
            if (pathGood) {
                NSLog(@"PlutoHelperAgent could not open the file at: %@ due to its extension not being in the white list.", decodedPath);
                [self basicErrorMessage:@"Could not open file"
                        informativeText:[NSString stringWithFormat:@"The file at %@ could not be opened because its extension is not in the white list.\n\nPlease contact multimediatech@theguardian.com if you see this error message.", decodedPath]
                 ];
            } else if (extensionGood) {
                NSLog(@"PlutoHelperAgent could not open the file at: %@ due to its path not being in the white list.", decodedPath);
                [self basicErrorMessage:@"Could not open file"
                        informativeText:[NSString stringWithFormat:@"The file at %@ could not be opened because its path is not in the white list.\n\nPlease contact multimediatech@theguardian.com if you see this error message.", decodedPath]
                 ];
            } else {
                NSLog(@"PlutoHelperAgent could not open the file at: %@ due to its path and extension not being in the correct white lists.", decodedPath);
                [self basicErrorMessage:@"Could not open file"
                        informativeText:[NSString stringWithFormat:@"The file at %@ could not be opened because its path and extension are not in the correct white lists.\n\nPlease contact multimediatech@theguardian.com if you see this error message.", decodedPath]
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
    self.statusBar.image = [NSImage imageNamed:@"PlutoIcon"];
    self.statusBar.menu = self.statusMenu;
    self.statusBar.highlightMode = YES;
    [self getVersionData];
}

- (void) getVersionData {
    NSString *tempFile = [PremiereVersionUtilities getApplicationsXmlToFile];
    if(tempFile) {
        NSDictionary *premiereData = [PremiereVersionUtilities refreshVersionData:tempFile];
        NSLog(@"Refreshed premiere data, found %lu versions", [premiereData count]);
        [[NSFileManager defaultManager] removeItemAtPath:tempFile error:nil];
    } else {
        NSLog(@"ERROR Could not update available premiere versions");
    }
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
