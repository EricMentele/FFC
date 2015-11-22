//
//  Free_Film_CampTests.swift
//  Free Film CampTests
//
//  Created by Eric Mentele on 10/4/15.
//  Copyright © 2015 Eric Mentele. All rights reserved.
//
import UIKit
import XCTest
@testable import Free_Film_Camp

class Free_Film_CampTests: XCTestCase {
    
    // MARK: Tests
    // Tests Scene initialization
    func testSceneInit() {
        let potentialScene = Scene(shotVideos: [NSURL](), shotImages: [UIImage](), voiceOver: NSURL(fileReferenceLiteral: "home/docs/scenes"))
        XCTAssertNotNil(potentialScene)
    }
    
    
}
