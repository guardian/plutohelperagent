//
//  SharedFunctions.h
//  PlutoHelperAgent
//
//  Created by Dave Allison on 05/03/2018.
//  Copyright © 2018 Guardian News & Media. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ProjectLockerAndKeychainFunctions : NSObject {}

extern NSString *connectionStatusString;

extern int connectionStatus;

extern int communicationStatus;

typedef NS_ENUM(NSUInteger, ReturnValues) {
    ALLOK=0,
    ERROR=1
};

+ (NSDictionary *)load_data_from_keychain;

+ (int) communicate_with_server:(NSString*)url :(NSString*)method :(NSString*)type :(NSDictionary*)body :(BOOL)send_cookie :(BOOL)test_connection;

+ (int)check_logged_in;

+ (void)login_to_project_server;

+ (void)logout_of_project_server;

@end



