//
//  AppDelegate.m
//  PlutoHelperAgent
//
//  Created by localhome on 29/06/2016.
//  Copyright (c) 2016 Guardian News & Media. All rights reserved.
//

#import "AppDelegate.h"

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
    [self login_to_project_server];
    
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

- (NSArray *) load_data_from_keychain {
    
    UInt32 pwLength = 0;
    
    void* pwData = NULL;
    
    SecKeychainItemRef itemRef = NULL;
    
    NSString* service = @"PlutoHelperAgent";
    
    OSStatus pwAccessStatus = SecKeychainFindGenericPassword(
                                                             
                                                             NULL,         // Search default keychains
                                                             
                                                             (UInt32)service.length,
                                                             
                                                             [service UTF8String],
                                                             
                                                             0,
                                                             
                                                             NULL,
                                                             
                                                             &pwLength,
                                                             
                                                             &pwData,
                                                             
                                                             &itemRef      // Get a reference this time
                                                             
                                                             );
    
    if (pwAccessStatus == errSecSuccess) {
        
        NSData* data = [NSData dataWithBytes:pwData length:pwLength];
        
        NSString* password = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        
        SecKeychainAttribute attrs2[] = {
            
            { kSecAccountItemAttr, 0, NULL }
            
        };
        
        SecKeychainAttributeList attributes2 = { 1, attrs2 };
        
        OSStatus unAccessStatus = SecKeychainItemCopyContent(itemRef, NULL, &attributes2, NULL, NULL);
        
        if (unAccessStatus == errSecSuccess) {
            
            NSLog(@"Username retrived from Apple Keychain");
            
            NSData* data8 = [NSData dataWithBytes:attributes2.attr->data length:attributes2.attr->length];
            
            NSString* usernamedata = [[NSString alloc] initWithData:data8 encoding:NSUTF8StringEncoding];
            
            NSArray *returnStrings = [NSArray arrayWithObjects:
                                    usernamedata,
                                    password,
                                    nil];
            
            return returnStrings;
            

        } else {
            
            NSLog(@"Username not retrived from Apple Keychain");
        }
        
    } else {
        
        NSLog(@"Keychain read failed: %@", SecCopyErrorMessageString(pwAccessStatus, NULL));
        
    }
    
    if (pwData) SecKeychainItemFreeContent(NULL, pwData);  // Free memory
    
    NSArray *failedReturnStrings = [NSArray arrayWithObjects:
                            @"Username not loaded",
                            @"Password not loaded",
                            nil];
    
    return failedReturnStrings;
    
}


- (void) login_to_project_server {
    
    NSArray *dataFromKeychain = [self load_data_from_keychain];
    
    NSString *URLToUse = [NSString stringWithFormat: @"%@/api/login", [[NSUserDefaults standardUserDefaults] stringForKey:@"project_locker_url"]];
    
    NSURL *url = [NSURL URLWithString:URLToUse];
    NSURLSessionConfiguration *config = [NSURLSessionConfiguration defaultSessionConfiguration];
    NSURLSession *session = [NSURLSession sessionWithConfiguration:config];
    
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:url];
    request.HTTPMethod = @"POST";
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    
    NSDictionary *dictionary = @{@"username": dataFromKeychain[0], @"password": dataFromKeychain[1]};
    NSError *error = nil;
    NSData *data = [NSJSONSerialization dataWithJSONObject:dictionary
                                                   options:kNilOptions error:&error];
    
    if (!error) {
        NSURLSessionUploadTask *uploadTask = [session uploadTaskWithRequest:request
                                                                   fromData:data completionHandler:^(NSData *data,NSURLResponse *response,NSError *error) {
                                                                       NSString *datastring = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
                                                                       NSLog(@"Data %@", datastring);
                                                                       NSLog(@"Response %@", response);
                                                                       if (error != NULL) {
                                                                           NSLog(@"Error %@", error);
                                                                       }
                                                                   }];
        
        [uploadTask resume];
    }
    
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
        
    } else {
        
        NSLog(@"%@ is not a recognised action for this helper", action);
        
    }
    
    
    
    
    
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    // Insert code here to initialize your application
}

- (void)applicationWillTerminate:(NSNotification *)aNotification {
    // Insert code here to tear down your application
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
