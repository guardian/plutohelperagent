//
//  PreferencesWindowController.m
//  PlutoHelperAgent
//
//  Created by Dave Allison on 26/02/2018.
//  Copyright © 2018 Guardian News & Media. All rights reserved.
//

#import "PreferencesWindowController.h"
#import "ProjectLockerAndKeychainFunctions.h"
#import "AppDelegate.h"

@interface PreferencesWindowController ()

@end

@implementation PreferencesWindowController
@synthesize statusString;
@synthesize username;
@synthesize password;

- (void) write_data_to_keychain:(NSString *)account password:(NSString *)password2 {
    NSString* service2 = @"PlutoHelperAgent";
    const void* passwordData = [[password2 dataUsingEncoding:NSUTF8StringEncoding] bytes];
    UInt32 pwLength2 = 0;
    void* pwData2 = NULL;
    SecKeychainItemRef itemRef2 = NULL;
    OSStatus pwSearchStatus = SecKeychainFindGenericPassword(
                                                             NULL,         // Search default keychains
                                                             (UInt32)service2.length,
                                                             [service2 UTF8String],
                                                             0,
                                                             NULL,
                                                             &pwLength2,
                                                             &pwData2,
                                                             &itemRef2      // Get a reference this time
                                                             );
    if (pwSearchStatus == errSecSuccess) {
        char const* account2 = [account UTF8String];
        SecKeychainAttribute attrs[] = {
            { kSecAccountItemAttr, (UInt32)account.length, (char *)account2 }
        };
        SecKeychainAttributeList attributes = { 1, attrs };
        OSStatus dataSaveStatus = SecKeychainItemModifyAttributesAndData(
                                                                         itemRef2,
                                                                         &attributes,
                                                                         (UInt32)password2.length,
                                                                         passwordData
                                                                         );
        if (dataSaveStatus != errSecSuccess) {
            NSLog(@"Keychain update failed: %@", SecCopyErrorMessageString(dataSaveStatus, NULL));
        }
    } else {
        NSLog(@"Keychain read failed: %@", SecCopyErrorMessageString(pwSearchStatus, NULL));
        OSStatus pwSaveStatus = SecKeychainAddGenericPassword(
                                                              NULL,        // Use default keychain
                                                              (UInt32)service2.length,
                                                              [service2 UTF8String],
                                                              (UInt32)account.length,
                                                              [account UTF8String],
                                                              (UInt32)password2.length,
                                                              passwordData,
                                                              NULL         // Uninterested in item reference
                                                              );
        if (pwSaveStatus != errSecSuccess) {
            NSLog(@"Keychain write failed: %@", SecCopyErrorMessageString(pwSaveStatus, NULL));
        }
    }
}

- (void)awakeFromNib {
    NSDictionary *dataFromKeychain = [ProjectLockerAndKeychainFunctions load_data_from_keychain];
    [self setUsername:dataFromKeychain[@"username"]];
    NSLog(@"Got username from keychain: %@", username);
    NSLog(@"Stored username: %@", [self username]);
    [self setPassword:dataFromKeychain[@"password"]];
    
    NSLog(@"adding observers\n");
    
    [self addObserver:self forKeyPath:@"username" options:NSKeyValueObservingOptionNew context:(void *)CFBridgingRetain(dataFromKeychain)];
    [self addObserver:self forKeyPath:@"password" options:NSKeyValueObservingOptionNew context:(void *)dataFromKeychain];
}

- (void) observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSString *,id> *)change context:(void *)context {
    
    if([keyPath compare:@"username"]==0){
        NSDictionary *dataFromKeychain = (__bridge NSDictionary *)(context);
        NSLog(@"username changed");
        NSString *newValue = [change valueForKey:NSKeyValueChangeNewKey];
        NSLog(@"new username: %@", newValue);
        if([newValue compare:dataFromKeychain[@"username"]]==0){
            [self setHasChanged:[NSNumber numberWithBool:NO]];
        } else {
            [self setHasChanged:[NSNumber numberWithBool:YES]];
        }
    } else if([keyPath compare:@"password"]==0){
        NSDictionary *dataFromKeychain = (__bridge NSDictionary *)(context);
        NSLog(@"password changed");
        NSString *newValue = [change valueForKey:NSKeyValueChangeNewKey];
        if([newValue compare:dataFromKeychain[@"password"]]==0){
            [self setHasChanged:[NSNumber numberWithBool:NO]];
        } else {
            [self setHasChanged:[NSNumber numberWithBool:YES]];
        }
    } else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}


- (IBAction)saveClicked:(id)sender {
    AppDelegate *appDelegate = [NSApp delegate];
    if([[self hasChanged] boolValue]){
        [self write_data_to_keychain:[self username] password:[self password]];
        
        [self setHasChanged:[NSNumber numberWithBool:NO]];
        [ProjectLockerAndKeychainFunctions logout_of_project_server:^(enum ReturnValues logoutResult) {
            if(logoutResult!=ALLOK) NSLog(@"Could not log out of server, see log for details");
            [ProjectLockerAndKeychainFunctions login_to_project_server:[self username]
                                                              password:[self password]
                                                     completionHandler:^(enum ReturnValues loginResult) {
                 if(loginResult==ALLOK){
                     [appDelegate setConnectionWorking:[NSNumber numberWithBool:YES]];
                 } else {
                     [appDelegate setConnectionWorking:[NSNumber numberWithBool:NO]];
                     NSLog(@"Could not log back in to of server, see log for details");
                 }
            } errorHandler:^(NSURLResponse *response, NSError *error){
                [appDelegate setConnectionWorking:[NSNumber numberWithBool:NO]];
            }];
        } errorHandler:^(NSURLResponse *response, NSError *error){
            [appDelegate setConnectionWorking:[NSNumber numberWithBool:NO]];
        }];
    } else {
        [self close];
    }
}

- (NSString *)getErrorString:(NSError *)err {
    return [err localizedDescription];
}

- (IBAction)testClicked:(id)sender {
    [self setStatusString:@"Testing connection..."];
    
    [ProjectLockerAndKeychainFunctions logout_of_project_server:^(enum ReturnValues logoutResult) {
        if(logoutResult!=ALLOK) NSLog(@"Could not log out of server, see log for details");
        [ProjectLockerAndKeychainFunctions login_to_project_server:[self username]
                                                          password:[self password]
                                                 completionHandler: ^(enum ReturnValues loginResult) {
            if(loginResult!=ALLOK) NSLog(@"Could not log back in to of server, see log for details");
            [ProjectLockerAndKeychainFunctions check_logged_in:^(enum ReturnValues connectionStatus) {
                switch(connectionStatus) {
                    case ALLOK:
                        [self setStatusString:@"Connection Okay"];
                        break;
                    case PERMISSION_DENIED:
                        [self setStatusString:@"Could not log in"];
                        break;
                    case SERVER_ERROR:
                        [self setStatusString:@"Could not connect to server"];
                        break;
                    default:
                        [self setStatusString:@"Unkown error"];
                        break;
                        
                }
            } errorHandler:^(NSURLResponse *response, NSError *error) {
                [self setStatusString:[NSString stringWithFormat:@"Could not check login: %@", [self getErrorString: error]]];
            }];
        }
                                                      errorHandler:^(NSURLResponse *response, NSError *error) {
            [self setStatusString:[NSString stringWithFormat:@"Could not log back in: %@", [self getErrorString: error]]];
        }];
    } errorHandler:^(NSURLResponse *response, NSError *error) {
        [self setStatusString:[NSString stringWithFormat:@"Could not log out: %@", [self getErrorString: error]]];
    }];
}

@end
