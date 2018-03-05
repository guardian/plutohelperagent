//
//  SharedFunctions.h
//  PlutoHelperAgent
//
//  Created by Dave Allison on 05/03/2018.
//  Copyright © 2018 Guardian News & Media. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SharedFunctions : NSObject {}

extern NSString *connectionStatusString;

extern int connectionStatus;

typedef NS_ENUM(NSUInteger, ReturnValues) {
    ALLOK=0,
    ERROR=1
};

+ (NSArray *)load_data_from_keychain;

+ (int)check_logged_in;

+ (int)login_to_project_server;

+ (void)logout_of_project_server;

@end



