//
//  Vanilla.swift
//  NavigationTab
//
//  Created by Jaesung Lee on 2023/05/31.
//

import SwiftUI
import ComposableArchitecture

class AppModel: ObservableObject {
    @Published var firstTab: FirstTabModel {
        didSet { self.bind() }
    }
    @Published var selectedTab: Tab = .one
    
    init(
        firstTab: FirstTabModel,
        selectedTab: Tab = .one
    ) {
        self.firstTab = firstTab
        self.selectedTab = selectedTab
        self.bind()
    }
    
    private func bind() {
        self.firstTab.goToInventoryTab = { [weak self] in // to avoid retain cycle
            self?.selectedTab = .inventory
        }
    }
}

// 인젝션 느낌: `goToInventoryTab` 는 딱히 구현되어 있지 않고, FirstTabModel에 접근해서 세팅하면 되며,
// AppModel에서는 `AppModel/selectedTab` 을 변경하도록 되어있음.
// 테스트코드에서는 다른 걸로 세팅가능
class FirstTabModel: ObservableObject {
    var goToInventoryTab: () -> Void = unimplemented("FirstTabModel.goToInventoryTab") // test시 구현 안되었다고 즉각 에러 리턴해줌
    
    func goToInventoryButtonTapped() {
        // 테스트를 위해 함수를 변수로 따로 뽑아냄
        self.goToInventoryTab() // hey parent, go to inventory tab
    }
}
