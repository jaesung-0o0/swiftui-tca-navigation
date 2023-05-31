//
//  NavigationTabTests.swift
//  NavigationTabTests
//
//  Created by Jaesung Lee on 2023/05/31.
//

import XCTest
import ComposableArchitecture
@testable import NavigationTab

@MainActor
final class NavigationTabTests: XCTestCase {
    func testGoToInventory() async {
        let store = TestStore(
            initialState: AppFeatureReducer.State(),
            reducer: AppFeatureReducer()
        )
        
        await store.send(.firstTab(.goToInventoryButtonTapped))
        // ver1
        await store.receive(.firstTab(.delegate(.switchToInventoryTab))) { state in
            state.selectedTab = .inventory
        }
        //ver2
//        await store.receive { action in
//            guard case .firstTab(.delegate) = action else {
//                return false
//            }
//            return true
//        } assert: { state in
//            state.selectedTab = .inventory
//        }
        
//        await store.receive(
//            (/AppFeatureReducer.Action.firstTab).appending(path: /FirstTabReducer.Action.delegate)
//        ) {
//            $0.selectedTab = .inventory
//        }
    }
}
