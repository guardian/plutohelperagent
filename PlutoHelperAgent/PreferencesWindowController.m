//
//  PreferencesWindowController.m
//  PlutoHelperAgent
//
//  Created by Dave Allison on 26/02/2018.
//  Copyright © 2018 Guardian News & Media. All rights reserved.
//

#import "PreferencesWindowController.h"

@interface PreferencesWindowController ()

@end

@implementation PreferencesWindowController

- (void)windowDidLoad {
    [super windowDidLoad];
    
    UInt32 pwLength = 0;
    
    void* pwData = NULL;
    
    SecKeychainItemRef itemRef = NULL;
    
    NSString* service = @"PlutoHelperAgent";
    
    
    OSStatus status = SecKeychainFindGenericPassword(
                                                     
                                                     NULL,         // Search default keychains
                                                     
                                                     (UInt32)service.length,
                                                     
                                                     [service UTF8String],
                                                     
                                                     0,
                                                     
                                                     NULL,
                                                     
                                                     &pwLength,
                                                     
                                                     &pwData,
                                                     
                                                     &itemRef      // Get a reference this time
                                                     
                                                     );
    
    
    
    if (status == errSecSuccess) {
        
        NSData* data = [NSData dataWithBytes:pwData length:pwLength];
        
        NSString* password = [[NSString alloc] initWithData:data
                              
                                                   encoding:NSUTF8StringEncoding];
        
        NSLog(@"Read password %@", password);
        
    } else {
        
        NSLog(@"Read failed: %@", SecCopyErrorMessageString(status, NULL));
        
    }
      
    
    if (pwData) SecKeychainItemFreeContent(NULL, pwData);  // Free memory
    
    // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
}


- (IBAction)saveClicked:(id)sender {
    
    
    
    NSString* service = @"PlutoHelperAgent";
    
    NSString* account = [_UsernameText stringValue];
    
    NSString* password = [_PasswordText stringValue];
    
    const void* passwordData = [[password dataUsingEncoding:NSUTF8StringEncoding] bytes];
    
    
    UInt32 pwLength = 0;
    
    void* pwData = NULL;
    
    SecKeychainItemRef itemRef = NULL;
    
    
    OSStatus status2 = SecKeychainFindGenericPassword(
                                                     
                                                     NULL,         // Search default keychains
                                                     
                                                     (UInt32)service.length,
                                                     
                                                     [service UTF8String],
                                                     
                                                     0,
                                                     
                                                     NULL,
                                                     
                                                     &pwLength,
                                                     
                                                     &pwData,
                                                     
                                                     &itemRef      // Get a reference this time
                                                     
                                                     );
    
    
    
    if (status2 == errSecSuccess) {
        
        NSData* data = [NSData dataWithBytes:pwData length:pwLength];
        
        NSString* password2 = [[NSString alloc] initWithData:data
                              
                                                   encoding:NSUTF8StringEncoding];
        
        NSLog(@"Read password %@", password2);
        
        char const* account2 = [account UTF8String];
        
        SecKeychainAttribute attrs[] = {
            
            { kSecAccountItemAttr, (UInt32)account.length, (char *)account2 }

        };
        
        SecKeychainAttributeList attributes = { 1, attrs };
        
        
        
        OSStatus status3 = SecKeychainItemModifyAttributesAndData(
                                                                  
                                                                  itemRef,
                                                                  
                                                                  &attributes,
                                                                  
                                                                  (UInt32)password.length,
                                                                  
                                                                  passwordData
                                                                  
                                                                  );
        
        
        
        if (status3 != errSecSuccess) {
            
            NSLog(@"Update failed: %@", SecCopyErrorMessageString(status3, NULL));
            
        }
        
    } else {
        
        NSLog(@"Read failed: %@", SecCopyErrorMessageString(status2, NULL));
        
        OSStatus status = SecKeychainAddGenericPassword(
                                                        
                                                        NULL,        // Use default keychain
                                                        
                                                        (UInt32)service.length,
                                                        
                                                        [service UTF8String],
                                                        
                                                        (UInt32)account.length,
                                                        
                                                        [account UTF8String],
                                                        
                                                        (UInt32)password.length,
                                                        
                                                        passwordData,
                                                        
                                                        NULL         // Uninterested in item reference
                                                        
                                                        );
        
        
        
        if (status != errSecSuccess) {     // Always check the status
            
            NSLog(@"Write failed: %@", SecCopyErrorMessageString(status, NULL));
            
        }
        
        
    }

    
    [super close];
    
}
@end
