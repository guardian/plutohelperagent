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

NSString *responseData;

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
    
    return nil;
    
}

+ (NSURLSessionTask *) communicate_with_server:(NSString*)url :(NSString*)method :(NSString*)type :(NSDictionary*)body :(BOOL)send_cookie
                         completionHandler:(void (^) (NSURLResponse*, NSDictionary *))completionHandlerBlock {
  
    NSString *URLToUse = [NSString stringWithFormat: @"%@%@", [[NSUserDefaults standardUserDefaults] stringForKey:@"project_locker_url"], url];
    
    NSURL *urlComplete = [NSURL URLWithString:URLToUse];
    NSURLSessionConfiguration *config = [NSURLSessionConfiguration defaultSessionConfiguration];
    NSURLSession *session = [NSURLSession sessionWithConfiguration:config];
    
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:urlComplete];
    request.HTTPMethod = method;
    [request setValue:type forHTTPHeaderField:@"Content-Type"];
    
    if (send_cookie) {
        
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
    
    void (^urlCompletionHandler)(NSData *, NSURLResponse *, NSError *);
    NSURLSessionTask *uploadTask;
    
    urlCompletionHandler = ^(NSData *data,NSURLResponse *response,NSError *error) {
        NSString *datastring = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        NSLog(@"Data %@", datastring);
        NSLog(@"Response %@", response);
        if (error != NULL) {
            NSLog(@"Error %@", error);
        } else {
            communicationStatus = 0;
        }
        completionHandlerBlock(response,[self parse_json:datastring]);
    };

    if (body != NULL) {
        NSError *error = nil;
        NSData *data = [NSJSONSerialization dataWithJSONObject:body options:kNilOptions error:&error];
        
        if (!error) {
            uploadTask = [session uploadTaskWithRequest:request fromData:data completionHandler:urlCompletionHandler];
            [uploadTask resume];
        }
    } else {
        uploadTask = [session dataTaskWithRequest:request completionHandler:urlCompletionHandler];
        [uploadTask resume];
    }
    
    return uploadTask;
    
}

+ (enum ReturnValues) returnValueFromStatusCode:(NSInteger)statusCode{
    switch(statusCode){
        case 200:
            return ALLOK;
        case 403:
            return PERMISSION_DENIED;
        case 500:
            return SERVER_ERROR;
        case 400:
            return DATA_ERROR;
        default:
            return UNKNOWN_ERROR;
    }
}

+ (NSURLSessionTask *) check_logged_in:(void (^) (enum ReturnValues))completionHandlerBlock {
    return [self communicate_with_server:@"/api/isLoggedIn" :@"GET" :@"application/json" :NULL :1 completionHandler:^(NSURLResponse *response,NSDictionary *jsonData) {
        completionHandlerBlock([self returnValueFromStatusCode:[(NSHTTPURLResponse *)response statusCode]]);
    }];
}

+ (void) login_to_project_server:(void (^) (enum ReturnValues))completionHandlerBlock {
    
    NSDictionary *dataFromKeychain = [self load_data_from_keychain];
    if(!dataFromKeychain){
        NSLog(@"Could not load login data from keychain");
        completionHandlerBlock(MISSING_VALUES); //tell the caller about it
        return;
    };
    
    [self communicate_with_server:@"/api/login"
                                 :@"POST"
                                 :@"application/json"
                                 :@{@"username": dataFromKeychain[@"username"],
                                    @"password": dataFromKeychain[@"password"]
                                    }
                                 :0
                completionHandler:^(NSURLResponse *response, NSDictionary *jsonData) {
                    completionHandlerBlock([self returnValueFromStatusCode:[(NSHTTPURLResponse *)response statusCode]]);
                }
     ];
    
}

+ (void) logout_of_project_server:(void (^) (enum ReturnValues))completionHandlerBlock {

    [self communicate_with_server:@"/api/logout" :@"GET" :@"application/json" :NULL :1 completionHandler:^(NSURLResponse *response, NSDictionary *jsonData) {
        
        NSHTTPCookieStorage *cookieStorage = [NSHTTPCookieStorage sharedHTTPCookieStorage];
        for (NSHTTPCookie *each in cookieStorage.cookies) {
            [cookieStorage deleteCookie:each];
        }
        completionHandlerBlock([self returnValueFromStatusCode:[(NSHTTPURLResponse *)response statusCode]]);
    }];
    
}

+ (NSURLSessionTask *) get_data_from_server:(NSString*)url :(NSString*)url2 :(NSString*)inputid completionHandler:(void (^) (NSURLResponse *, NSDictionary *))completionHandlerBlock{

    NSString *urlToUse;
    
    if (url2 != NULL) {
        urlToUse = [NSString stringWithFormat: @"%@%@%@", url, inputid, url2];
    } else {
        
        urlToUse = [NSString stringWithFormat: @"%@%@", url, inputid];
    }

    return [self communicate_with_server:urlToUse :@"GET" :@"application/json" :NULL :0 completionHandler:completionHandlerBlock];
}

+ (NSDictionary *) parse_json:(NSString*)json {
    
    NSData *returnedData = [json dataUsingEncoding:NSUTF8StringEncoding];
    
    NSError *error = nil;
    id object = [NSJSONSerialization
                 JSONObjectWithData:returnedData
                 options:0
                 error:&error];
    
    if(error) {
        NSLog(@"Could not parse JSON object: %@", error);
        return NULL;
        
    }
    
    if([object isKindOfClass:[NSDictionary class]])
    {
        NSDictionary *results = object;
        return results;
    }
    else
    {
        NSLog(@"Json parsed but is not a dictionary");
        return NULL;
    }
}

@end
