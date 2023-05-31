//
//  VanillaTests.swift
//  NavigationTabTests
//
//  Created by Jaesung Lee on 2023/05/31.
//

import XCTest
@testable import NavigationTab

class VanillaTests: XCTestCase {
    func testFirstTabModel() {
        let expectation = self.expectation(description: "gotoInventoryTab")
        
        let model = FirstTabModel()
        model.goToInventoryTab = {
            expectation.fulfill()
        }
        model.goToInventoryButtonTapped()
        
        self.wait(for: [expectation], timeout: 0) // why 0? it shoud happen immediately
    }
    
    func testAppModel() {
        let model = AppModel(firstTab: FirstTabModel())
        
        model.firstTab.goToInventoryButtonTapped()
        XCTAssertEqual(model.selectedTab, .inventory)
    }
}
