//
//  SharedFunctions.m
//  PlutoHelperAgent
//
//  Created by Dave Allison on 05/03/2018.
//  Copyright © 2018 Guardian News & Media. All rights reserved.
//

#import "ProjectLockerAndKeychainFunctions.h"

@implementation ProjectLockerAndKeychainFunctions

NSString *connectionStatusString;

int connectionStatus;

int communicationStatus;

+ (NSDictionary *) load_data_from_keychain {
    
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
       
            return [NSDictionary dictionaryWithObjectsAndKeys:
                    usernamedata,
                    @"username",
                    password,
                    @"password",
                    nil,
                    @"error",
                    nil];
            
        } else {
            
            NSLog(@"Username not retrived from Apple Keychain");
        }
        
    } else {
        
        NSLog(@"Keychain read failed: %@", SecCopyErrorMessageString(pwAccessStatus, NULL));
        
    }
    
    if (pwData) SecKeychainItemFreeContent(NULL, pwData);  // Free memory
    
    return [NSDictionary dictionaryWithObjectsAndKeys:
            @"",
            @"username",
            nil,
            @"password",
            @"Could not load data",
            @"error",
            nil];
    
}

+ (int) communicate_with_server:(NSString*)url :(NSString*)method :(NSString*)type :(NSDictionary*)body :(BOOL)send_cookie :(BOOL)test_connection {
  
    NSString *URLToUse = [NSString stringWithFormat: url, [[NSUserDefaults standardUserDefaults] stringForKey:@"project_locker_url"]];
    
    NSURL *urlComplete = [NSURL URLWithString:URLToUse];
    NSURLSessionConfiguration *config = [NSURLSessionConfiguration defaultSessionConfiguration];
    NSURLSession *session = [NSURLSession sessionWithConfiguration:config];
    
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:urlComplete];
    request.HTTPMethod = method;
    [request setValue:type forHTTPHeaderField:@"Content-Type"];
    
    if (send_cookie == 1) {
        
        NSHTTPCookie *cookie;
        NSHTTPCookieStorage *cookieJar = [NSHTTPCookieStorage sharedHTTPCookieStorage];
        for (cookie in [cookieJar cookies]) {
            NSLog(@"%@", cookie);
        }
        
        NSDictionary * headers = [NSHTTPCookie requestHeaderFieldsWithCookies:[cookieJar cookies]];
        [request setAllHTTPHeaderFields:headers];
        
    }
    
    NSLog(@"Request %@", request);
    
    communicationStatus = 1;
    
    if (body != NULL) {
        
        NSError *error = nil;
        NSData *data = [NSJSONSerialization dataWithJSONObject:body
                                                       options:kNilOptions error:&error];
        
        if (!error) {
            NSURLSessionUploadTask *uploadTask = [session uploadTaskWithRequest:request
                                                                       fromData:data completionHandler:^(NSData *data,NSURLResponse *response,NSError *error) {
                                                                           NSString *datastring = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
                                                                           NSLog(@"Data %@", datastring);
                                                                           NSLog(@"Response %@", response);
                                                                           if (error != NULL) {
                                                                               NSLog(@"Error %@", error);
                                                                           } else {
                                                                               communicationStatus = 0;
                                                                           }
                                                                           
                                                                       }];
            
            [uploadTask resume];
        }
        
        sleep(1);
        
    } else {
        
        NSURLSessionDataTask *uploadTask = [session dataTaskWithRequest:request completionHandler:^(NSData *data,NSURLResponse *response,NSError *error) {
            NSString *datastring = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
            NSLog(@"Data %@", datastring);
            NSLog(@"Response %@", response);
            if (error != NULL) {
                NSLog(@"Error %@", error);
            }
            
            if (test_connection == 1) {
                NSString *compareThisPartOfTheString = [datastring substringToIndex:14];
                
                if ([compareThisPartOfTheString isEqual: @"{\"status\":\"ok\""]) {
                    connectionStatus = 0;
                }
            }
            
        }];
        
        [uploadTask resume];
        
        sleep(1);
        
    }
    
    return communicationStatus;
    
}

+ (int) check_logged_in {
    
    connectionStatus = 1;
    
    [self communicate_with_server:@"%@/api/isLoggedIn" :@"GET" :@"application/json" :NULL :1 :1];
    
    return connectionStatus;
    
}

+ (void) login_to_project_server {
    
    NSDictionary *dataFromKeychain = [self load_data_from_keychain];
    
    [self communicate_with_server:@"%@/api/login" :@"POST" :@"application/json" :@{@"username": dataFromKeychain[@"username"], @"password": dataFromKeychain[@"password"]} :0 :0];
    
    
}

+ (void) logout_of_project_server {

    [self communicate_with_server:@"%@/api/logout" :@"GET" :@"application/json" :NULL :1 :0];

    NSHTTPCookieStorage *cookieStorage = [NSHTTPCookieStorage sharedHTTPCookieStorage];
    for (NSHTTPCookie *each in cookieStorage.cookies) {
        [cookieStorage deleteCookie:each];
    }
    
}

@end
