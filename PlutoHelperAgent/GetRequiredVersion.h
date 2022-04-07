//
//  GetRequiredVersion.h
//  PlutoHelperAgent
//
//  Created by David Allison on 07/04/2022.
//  Copyright © 2022 Guardian News & Media. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface GetRequiredVersion : NSObject

+ (NSString *) getRequiredVersion:(NSArray *)versionsArray;

@end

NS_ASSUME_NONNULL_END
