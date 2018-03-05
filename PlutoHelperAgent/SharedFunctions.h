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

+ (NSArray *)load_data_from_keychain;

+ (NSString *)login_to_project_server;

+ (void)logout_of_project_server;

@end



