//
//  FirstTab.swift
//  NavigationTab
//
//  Created by Jaesung Lee on 2023/05/31.
//

import SwiftUI
import ComposableArchitecture

struct FirstTabReducer: Reducer {
    struct State: Equatable { }
    
    enum Action: Equatable {
        case goToInventoryButtonTapped
        case delegate(Delegate) // Old pattern of uikit
        
        enum Delegate: Equatable {
            case switchToInventoryTab
        }
    }
    
    
    func reduce(into state: inout State, action: Action) -> Effect<Action> {
        switch action {
        case .delegate:
            // 액션 무시
            return .none
            
        case .goToInventoryButtonTapped:
            return .send(.delegate(.switchToInventoryTab)) // send는 delegate 액션에 적합
        }
    }
}

struct FirstTabView: View {
    let store: StoreOf<FirstTabReducer>
    
    var body: some View {
        WithViewStore(self.store, observe: { $0 }) { viewStore in
            Button {
                // 인벤토리 탭으로 가는 버튼
                // 하지만 현재 선택된 탭이 뭔지 모름
                // pre-selected 탭으로 시작하는 방법도 모름
                // 이때 필요한게 state
                //            viewStore.send(.selectedTabChanged(.inventory))
                viewStore.send(.goToInventoryButtonTapped)
            } label: {
                Text("인벤토리 가기")
            }
        }
    }
}
