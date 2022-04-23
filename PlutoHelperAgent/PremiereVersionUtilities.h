//
//  PremiereVersionUtilities.h
//  PlutoHelperAgent
//
//  Created by Andy Gallagher on 23/04/2022.
//  Copyright © 2022 Guardian News & Media. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface PremiereVersionUtilities : NSObject
+ (NSDictionary *)refreshVersionData:(NSString *)filePath;

@end

NS_ASSUME_NONNULL_END
