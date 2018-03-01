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
        
        NSString* password = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        
        //NSLog(@"Read password %@", password);
        
        _PasswordText.stringValue = password;
        
        SecKeychainAttribute attrs2[] = {
            
            { kSecAccountItemAttr, 0, NULL }
            
        };
        
        SecKeychainAttributeList attributes2 = { 1, attrs2 };

        OSStatus status5 = SecKeychainItemCopyContent(itemRef, NULL, &attributes2, NULL, NULL);
        
        if (status5 == errSecSuccess) {
            
            NSLog(@"Access sucessful");
            
            //char const* usefuldata = attributes2.attr->data;
            
            //NSLog(@"Account %s", (char *)usefuldata);

            NSData* data8 = [NSData dataWithBytes:attributes2.attr->data length:attributes2.attr->length];
            
            NSString* usernamedata = [[NSString alloc] initWithData:data8 encoding:NSUTF8StringEncoding];

            _UsernameText.stringValue = usernamedata;
   
        } else {
            
            NSLog(@"Access failed");
        }

    } else {
        
        NSLog(@"Read failed: %@", SecCopyErrorMessageString(status, NULL));
        
    }
    
    if (pwData) SecKeychainItemFreeContent(NULL, pwData);  // Free memory
    
    // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
}


- (IBAction)saveClicked:(id)sender {
    
    NSString* service2 = @"PlutoHelperAgent";
    
    NSString* account = [_UsernameText stringValue];
    
    NSString* password2 = [_PasswordText stringValue];
    
    const void* passwordData = [[password2 dataUsingEncoding:NSUTF8StringEncoding] bytes];
    
    UInt32 pwLength2 = 0;
    
    void* pwData2 = NULL;
    
    SecKeychainItemRef itemRef2 = NULL;
    
    
    OSStatus status2 = SecKeychainFindGenericPassword(
                                                     
                                                     NULL,         // Search default keychains
                                                     
                                                     (UInt32)service2.length,
                                                     
                                                     [service2 UTF8String],
                                                     
                                                     0,
                                                     
                                                     NULL,
                                                     
                                                     &pwLength2,
                                                     
                                                     &pwData2,
                                                     
                                                     &itemRef2      // Get a reference this time
                                                     
                                                     );
    
    
    
    if (status2 == errSecSuccess) {
        
        //NSData* data2 = [NSData dataWithBytes:pwData2 length:pwLength2];
        
        //NSString* password3 = [[NSString alloc] initWithData:data2 encoding:NSUTF8StringEncoding];
        
        //NSLog(@"Read password %@", password3);
        
        char const* account2 = [account UTF8String];
        
        SecKeychainAttribute attrs[] = {
            
            { kSecAccountItemAttr, (UInt32)account.length, (char *)account2 }

        };
        
        SecKeychainAttributeList attributes = { 1, attrs };
        
        
        
        OSStatus status3 = SecKeychainItemModifyAttributesAndData(
                                                                  
                                                                  itemRef2,
                                                                  
                                                                  &attributes,
                                                                  
                                                                  (UInt32)password2.length,
                                                                  
                                                                  passwordData
                                                                  
                                                                  );
        
        
        
        if (status3 != errSecSuccess) {
            
            NSLog(@"Update failed: %@", SecCopyErrorMessageString(status3, NULL));
            
        }
        
    } else {
        
        NSLog(@"Read failed: %@", SecCopyErrorMessageString(status2, NULL));
        
        OSStatus status6 = SecKeychainAddGenericPassword(
                                                        
                                                        NULL,        // Use default keychain
                                                        
                                                        (UInt32)service2.length,
                                                        
                                                        [service2 UTF8String],
                                                        
                                                        (UInt32)account.length,
                                                        
                                                        [account UTF8String],
                                                        
                                                        (UInt32)password2.length,
                                                        
                                                        passwordData,
                                                        
                                                        NULL         // Uninterested in item reference
                                                        
                                                        );
        

        if (status6 != errSecSuccess) {
            
            NSLog(@"Write failed: %@", SecCopyErrorMessageString(status6, NULL));
            
        }
        
    }
    
    [super close];
    
}
@end
