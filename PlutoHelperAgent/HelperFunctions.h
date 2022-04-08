//
//  HelperFunctions.h
//  PlutoHelperAgent
//
//  Created by David Allison on 08/04/2022.
//  Copyright © 2022 Guardian News & Media. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface HelperFunctions : NSObject

+ (NSString *) getLatestVersion:(NSArray *)versionsArray;

+ (NSMutableDictionary *)parseURLQueryToDictionary:(NSString *)url;

@end

NS_ASSUME_NONNULL_END
