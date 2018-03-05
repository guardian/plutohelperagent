//
//  PreferencesWindowController.m
//  PlutoHelperAgent
//
//  Created by Dave Allison on 26/02/2018.
//  Copyright © 2018 Guardian News & Media. All rights reserved.
//

#import "PreferencesWindowController.h"
#import "SharedFunctions.h"

@interface PreferencesWindowController ()

@end

@implementation PreferencesWindowController


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
    NSArray *dataFromKeychain = [SharedFunctions load_data_from_keychain];
    _UsernameText.stringValue = dataFromKeychain[0];
    _PasswordText.stringValue = dataFromKeychain[1];
}


- (IBAction)saveClicked:(id)sender {
    
    [self write_data_to_keychain];
    
    [super close];
    
}

- (IBAction)testClicked:(id)sender {
    [SharedFunctions logout_of_project_server];
    NSString *connectionStatus = [SharedFunctions login_to_project_server];
    
    _StatusText.stringValue = connectionStatus;
    
}

@end