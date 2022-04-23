//
//  PremiereVersionUtilitiesTest.m
//  PlutoHelperAgentTests
//
//  Created by Andy Gallagher on 23/04/2022.
//  Copyright © 2022 Guardian News & Media. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "../PlutoHelperAgent/PremiereVersionUtilities.h"

@interface PremiereVersionUtilitiesTest : XCTestCase

@end

@implementation PremiereVersionUtilitiesTest

- (void) setUp {
    
}

- (void) tearDown {
    
}

/**
 refreshVersionData should read in the given file and parse out the premiere versions contained in it
 */
- (void)refreshVersionData {
    NSBundle *bundle = [NSBundle bundleForClass:[self class]];

    NSString *path = [bundle pathForResource:@"applications" ofType:@"xml"];
    
    XCTAssertTrue(path!=nil);
    
    // This is an example of a functional test case.
    // Use XCTAssert and related functions to verify your tests produce the correct results.
    NSDictionary *result = [PremiereVersionUtilities refreshVersionData:path];
    XCTAssertEqual([result count], 1);
    
    XCTAssertTrue([[result valueForKey:@"14.9.0"] compare:@"/Applications/Adobe Premiere Pro 2020/Adobe Premiere Pro 2020.app"]==0);
}


@end
