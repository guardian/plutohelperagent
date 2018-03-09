//
//  SharedFunctions.h
//  PlutoHelperAgent
//
//  Created by Dave Allison on 05/03/2018.
//  Copyright © 2018 Guardian News & Media. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSUInteger, ReturnValues) {
    ALLOK=0,
    SERVER_ERROR=1,
    DATA_ERROR=2,
    PERMISSION_DENIED=3,
    UNKNOWN_ERROR=4
} OperationStatus;

@interface ProjectLockerAndKeychainFunctions : NSObject {}

//extern NSString *connectionStatusString;
//
//extern int connectionStatus;
//
//extern int communicationStatus;
//
//extern NSString *responseData;


+ (NSDictionary *)load_data_from_keychain;

+ (NSURLSessionTask *) communicate_with_server:(NSString*)url :(NSString*)method :(NSString*)type :(NSDictionary*)body :(BOOL)send_cookie :(BOOL)test_connection completionHandler:(void (^) (NSURLResponse *,NSDictionary *))completionHandlerBlock;

+ (NSURLSessionTask *)check_logged_in:(void (^) (enum ReturnValues))completionHandlerBlock;

+ (void)login_to_project_server:(void (^) (enum ReturnValues)) completionHandlerBlock;

+ (void)logout_of_project_server:(void (^) (enum ReturnValues)) completionHandlerBlock;

+ (NSURLSessionTask *) get_data_from_server:(NSString*)url :(NSString*)url2 :(NSString*)inputid completionHandler:(void (^) (NSURLResponse *,NSDictionary *))completionHandlerBlock;

+ (NSDictionary *) parse_json:(NSString*)json;

@end
