//
//  GetRequiredVersion.m
//  PlutoHelperAgent
//
//  Created by David Allison on 07/04/2022.
//  Copyright © 2022 Guardian News & Media. All rights reserved.
//

#import "GetRequiredVersion.h"

@implementation GetRequiredVersion

+ (NSString *) getRequiredVersion:(NSArray *)versionsArray {
    NSMutableArray *processedVersionsArray = [NSMutableArray new];
    for (id version in versionsArray) {
        NSString *versionForProcessing = version;
        NSUInteger numberOfOccurrencesInVersion = [[versionForProcessing componentsSeparatedByString:@"."] count] - 1;
        if (numberOfOccurrencesInVersion == 0) {
            versionForProcessing = [NSString stringWithFormat:@"%@00", versionForProcessing];
        } else if (numberOfOccurrencesInVersion == 1) {
            versionForProcessing = [NSString stringWithFormat:@"%@0", versionForProcessing];
        }
        NSUInteger versionStringLength = [versionForProcessing length];
        if (versionStringLength == 5) {
            versionForProcessing = [NSString stringWithFormat:@"0%@", versionForProcessing];
        }
        [processedVersionsArray addObject:versionForProcessing];
    }
    NSArray *sortedProcessedVersionsArray = [processedVersionsArray sortedArrayUsingComparator:
                                ^NSComparisonResult(id obj1, id obj2){
                                    return [obj2 compare:obj1];
                                }];
    NSString *requiredVersion = sortedProcessedVersionsArray[0];
    if ([[requiredVersion substringToIndex:1] isEqualTo:@"0"]) {
        requiredVersion = [requiredVersion substringFromIndex:1];
        //return [requiredVersion substringFromIndex:1];
    }
    return requiredVersion;
}

@end
