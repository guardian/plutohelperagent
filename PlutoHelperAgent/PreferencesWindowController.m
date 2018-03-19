//
//  PreferencesWindowController.m
//  PlutoHelperAgent
//
//  Created by Dave Allison on 26/02/2018.
//  Copyright © 2018 Guardian News & Media. All rights reserved.
//

#import "PreferencesWindowController.h"
#import "ProjectLockerAndKeychainFunctions.h"

@interface PreferencesWindowController ()

@end

@implementation PreferencesWindowController
@synthesize errorAlert;

- (void) write_data_to_keychain {
    
    NSString* service2 = @"PlutoHelperAgent";
    
    NSString* account = [_UsernameText stringValue];
    
    NSString* password2 = [_PasswordText stringValue];
    
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


- (void)windowDidLoad {
    [super windowDidLoad];
    NSDictionary *dataFromKeychain = [ProjectLockerAndKeychainFunctions load_data_from_keychain];
    _UsernameText.stringValue = dataFromKeychain[@"username"];
    _PasswordText.stringValue = dataFromKeychain[@"password"];
}


- (IBAction)saveClicked:(id)sender {
    
    [self write_data_to_keychain];
    [ProjectLockerAndKeychainFunctions logout_of_project_server:^(enum ReturnValues logoutResult) {
        if(logoutResult!=ALLOK) NSLog(@"Could not log out of server, see log for details");
        [ProjectLockerAndKeychainFunctions login_to_project_server:^(enum ReturnValues loginResult) {
            if(loginResult!=ALLOK) NSLog(@"Could not log back in to of server, see log for details");
            [super close];
        }];
    }];
}

- (IBAction)testClicked:(id)sender {
    _StatusText.stringValue = @"Testing connection...";
    
    [ProjectLockerAndKeychainFunctions logout_of_project_server:^(enum ReturnValues logoutResult) {
        if(logoutResult!=ALLOK) NSLog(@"Could not log out of server, see log for details");
        [ProjectLockerAndKeychainFunctions login_to_project_server:^(enum ReturnValues loginResult) {
            if(loginResult!=ALLOK) NSLog(@"Could not log back in to of server, see log for details");
            [ProjectLockerAndKeychainFunctions check_logged_in:^(enum ReturnValues connectionStatus) {
                switch(connectionStatus) {
                    case ALLOK:
                        _StatusText.stringValue = @"Connection Okay";
                        break;
                    case PERMISSION_DENIED:
                        _StatusText.stringValue = @"Could not log in";
                        break;
                    case SERVER_ERROR:
                        _StatusText.stringValue = @"Could not connect to server";
                        break;
                    default:
                        _StatusText.stringValue = @"Unkown error";
                        break;
                        
                }
            }];
        }];
    }];
}

@end
