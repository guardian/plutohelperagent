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

/**
 refreshVersionData should read in the given file and parse out the premiere versions contained in it
 */
- (void)testRefreshVersionData {
    NSBundle *bundle = [NSBundle bundleForClass:[self class]];
    NSString *path = [bundle pathForResource:@"applications" ofType:@"xml"];
    
    XCTAssertTrue(path!=nil);
    
    // This is an example of a functional test case.
    // Use XCTAssert and related functions to verify your tests produce the correct results.
    NSDictionary *result = [PremiereVersionUtilities refreshVersionData:path];
    XCTAssertEqual([result count], 1);
    
    XCTAssertTrue([[result valueForKey:@"14.9.0"] compare:@"/Applications/Adobe Premiere Pro 2020/Adobe Premiere Pro 2020.app"]==0);
}

- (void) testNormaliseVersionThreepart {
    NSString *result = [PremiereVersionUtilities normaliseVersionParts:@"1.2.3"];
    XCTAssertEqual(result, @"1.2.3");
}

- (void) testNormaliseVersionTwopart {
    NSString *result = [PremiereVersionUtilities normaliseVersionParts:@"1.2"];
    XCTAssertTrue([result compare:@"1.2.0"]==0);
}

- (void) testNormaliseVersionOnepart {
    NSString *result = [PremiereVersionUtilities normaliseVersionParts:@"1"];
    XCTAssertTrue([result compare:@"1.0.0"]==0);
}

- (void) testNormaliseVersionFourpart {
    NSString *result = [PremiereVersionUtilities normaliseVersionParts:@"1.2.3.4"];
    XCTAssertTrue([result compare:@"1.2.3.4"]==0);
}

- (void) testGetApplicationsXmlToFile {
    NSError *err;
    NSString *filename = [PremiereVersionUtilities getApplicationsXmlToFile];
    XCTAssertNotNil(filename);
    NSArray *content = [NSArray arrayWithContentsOfFile:filename];
    [[NSFileManager defaultManager] removeItemAtPath:filename error:&err];
    
    if(err!=nil) {
        NSLog(@"ERROR could not remove temporary file: %@", [err localizedDescription]);

        XCTFail(@"could not remove temporary file");
    }
    //yeah, the schema is weird. Don't blame me.
    NSArray<NSDictionary *> *apps = [[content objectAtIndex:0] valueForKey:@"_items"];
    
    XCTAssertGreaterThan([apps count], 1);
    //we rely on all apps having the following information keys present
    for(NSDictionary *app in apps) {
        XCTAssertNotNil([app valueForKey:@"_name"]);
        XCTAssertNotNil([app valueForKey:@"path"]);
        //I would check the "version" field is valid as well, but unfortunately version=nil is a valid outcome
        //for some apps
    }
}
@end
