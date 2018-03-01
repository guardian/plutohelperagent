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


- (void) grab_data_from_keychain {
    
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
        
        _PasswordText.stringValue = password;
        
        SecKeychainAttribute attrs2[] = {
            
            { kSecAccountItemAttr, 0, NULL }
            
        };
        
        SecKeychainAttributeList attributes2 = { 1, attrs2 };
        
        OSStatus unAccessStatus = SecKeychainItemCopyContent(itemRef, NULL, &attributes2, NULL, NULL);
        
        if (unAccessStatus == errSecSuccess) {
            
            NSLog(@"Username retrived from Apple Keychain");
            
            NSData* data8 = [NSData dataWithBytes:attributes2.attr->data length:attributes2.attr->length];
            
            NSString* usernamedata = [[NSString alloc] initWithData:data8 encoding:NSUTF8StringEncoding];
            
            _UsernameText.stringValue = usernamedata;
            
        } else {
            
            NSLog(@"Username not retrived from Apple Keychain");
        }
        
    } else {
        
        NSLog(@"Read failed: %@", SecCopyErrorMessageString(pwAccessStatus, NULL));
        
    }
    
    if (pwData) SecKeychainItemFreeContent(NULL, pwData);  // Free memory
    
}


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
            
            NSLog(@"Update failed: %@", SecCopyErrorMessageString(dataSaveStatus, NULL));
            
        }
        
    } else {
        
        NSLog(@"Read failed: %@", SecCopyErrorMessageString(pwSearchStatus, NULL));
        
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
            
            NSLog(@"Write failed: %@", SecCopyErrorMessageString(pwSaveStatus, NULL));
            
        }
        
    }
}


- (void)windowDidLoad {
    [super windowDidLoad];
    [self grab_data_from_keychain];

}


- (IBAction)saveClicked:(id)sender {
    
    [self write_data_to_keychain];
    
    [super close];
    
}
@end
