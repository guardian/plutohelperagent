//
//  SharedFunctions.m
//  PlutoHelperAgent
//
//  Created by Dave Allison on 05/03/2018.
//  Copyright © 2018 Guardian News & Media. All rights reserved.
//

#import "SharedFunctions.h"

@implementation SharedFunctions

+ (void) testfunction {
    NSLog(@"Test Function Worked!");
}

+ (NSArray *) load_data_from_keychain {
    
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

+ (void) login_to_project_server {
    
    NSArray *dataFromKeychain = [self load_data_from_keychain];
    
    NSString *URLToUse = [NSString stringWithFormat: @"%@/api/login", [[NSUserDefaults standardUserDefaults] stringForKey:@"project_locker_url"]];
    
    NSURL *url = [NSURL URLWithString:URLToUse];
    NSURLSessionConfiguration *config = [NSURLSessionConfiguration defaultSessionConfiguration];
    NSURLSession *session = [NSURLSession sessionWithConfiguration:config];
    
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:url];
    request.HTTPMethod = @"POST";
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    NSLog(@"Request %@", request);
    
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
    
    sleep(1);
    
    NSHTTPCookie *cookie;
    NSHTTPCookieStorage *cookieJar = [NSHTTPCookieStorage sharedHTTPCookieStorage];
    for (cookie in [cookieJar cookies]) {
        NSLog(@"%@", cookie);
    }
    
    NSString *URLToUse2 = [NSString stringWithFormat: @"%@/api/isLoggedIn", [[NSUserDefaults standardUserDefaults] stringForKey:@"project_locker_url"]];
    
    NSURL *url2 = [NSURL URLWithString:URLToUse2];
    NSURLSessionConfiguration *config2 = [NSURLSessionConfiguration defaultSessionConfiguration];
    NSURLSession *session2 = [NSURLSession sessionWithConfiguration:config2];
    
    NSMutableURLRequest *request2 = [[NSMutableURLRequest alloc] initWithURL:url2];
    request2.HTTPMethod = @"GET";
    [request2 setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    NSDictionary * headers = [NSHTTPCookie requestHeaderFieldsWithCookies:[cookieJar cookies]];
    [request2 setAllHTTPHeaderFields:headers];
    NSLog(@"Request %@", request2);
    NSLog(@"Request %@", request2.allHTTPHeaderFields);
    
    NSError *error2 = nil;
    
    
    if (!error2) {
        NSURLSessionDataTask *uploadTask2 = [session2 dataTaskWithRequest:request2 completionHandler:^(NSData *data2,NSURLResponse *response2,NSError *error2) {
            NSString *datastring2 = [[NSString alloc] initWithData:data2 encoding:NSUTF8StringEncoding];
            NSLog(@"Data2 %@", datastring2);
            NSLog(@"Response2 %@", response2);
            if (error2 != NULL) {
                NSLog(@"Error2 %@", error2);
                
            }
            
            
        }];
        
        [uploadTask2 resume];
    }
    
    
}

+ (void) logout_of_project_server {
    
    NSHTTPCookieStorage *cookieJar = [NSHTTPCookieStorage sharedHTTPCookieStorage];
    
    NSString *URLToUse = [NSString stringWithFormat: @"%@/api/logout", [[NSUserDefaults standardUserDefaults] stringForKey:@"project_locker_url"]];
    
    NSURL *url = [NSURL URLWithString:URLToUse];
    NSURLSessionConfiguration *config = [NSURLSessionConfiguration defaultSessionConfiguration];
    NSURLSession *session = [NSURLSession sessionWithConfiguration:config];
    
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:url];
    request.HTTPMethod = @"GET";
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    NSDictionary * headers = [NSHTTPCookie requestHeaderFieldsWithCookies:[cookieJar cookies]];
    [request setAllHTTPHeaderFields:headers];
    
    NSError *error = nil;
    
    if (!error) {
        NSURLSessionDataTask *uploadTask = [session dataTaskWithRequest:request completionHandler:^(NSData *data,NSURLResponse *response,NSError *error) {
            NSString *datastring = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
            NSLog(@"Data before quit: %@", datastring);
            NSLog(@"Response before quit: %@", response);
            if (error != NULL) {
                NSLog(@"Error before quit: %@", error);
                
            }
            
        }];
        
        [uploadTask resume];
    }
    
}



@end

