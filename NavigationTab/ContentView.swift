//
//  ContentView.swift
//  NavigationTab
//
//  Created by Jaesung Lee on 2023/05/31.
//

import SwiftUI
import ComposableArchitecture

struct AppFeatureReducer: Reducer {
    struct State: Equatable {
        var selectedTab: Tab = .one
        var firstTab = FirstTabReducer.State()
        var inventory = InventoryReducer.State()
        var thirdTab = ThirdTabReducer.State()
    }
    
    enum Action: Equatable {
        // when the user select a tab
        case selectedTabChanged(Tab)
        case firstTab(FirstTabReducer.Action)
        case inventory(InventoryReducer.Action)
        case thirdTab(ThirdTabReducer.Action)
    }
    
    var body: some ReducerOf<Self> {
        // 루트 레벨 of reducer
        Reduce<State, Action> { state, action in
            switch action {
            case let .firstTab(.delegate(action)): // 새 delegate action 추가되면 컴파일에러 유도하도록 case let 사용
                switch action {
                case .switchToInventoryTab:
                    state.selectedTab = .inventory
                    return .none
                }
                
            case .selectedTabChanged(let tab):
                state.selectedTab = tab
                return .none // 실행할 이펙트 없음
                
            case .firstTab, .inventory, .thirdTab:
                return .none
            }
        }
        
        // 그냥 각각 도메인을 써버리면 state, action 이 서로 완전히 달라서 계산 불가 (e.g,
        //        FirstTabReducer()
        //        InventoryReducer()
        //        ThirdTabReducer()
        // 그래서 scope 로 감싸서 각 state와 action이 Self 에 속한 통일 형태로 유추 되게 사용해야함
        
        Scope(state: \.firstTab, action: /Action.firstTab) {
            FirstTabReducer()
        }
        Scope(state: \.inventory, action: /Action.inventory) {
            InventoryReducer()
        }
        Scope(state: \.thirdTab, action: /Action.thirdTab) {
            ThirdTabReducer()
        }
    }
    
    // useraction -figure out--> state changes
    //    func reduce(into state: inout State, action: Action) -> Effect<Action> { // 리듀서는 실패하지 않는다 때문에 이펙트에 실패경우는 없음
    //        switch action {
    //        case .selectedTabChanged(let tab):
    //            state.selectedTab = tab
//            return .none // 실행할 이펙트 없음
//
//            // 여기서 none 해버리면 하위 리듀서랑 안맞음. -> 즉, 모양이 별로가 됨 -> body 를 사용할 것
//        case .firstTab, .inventory, .thirdTab:
//            return .none
//        }
//    }
}

enum Tab {
    case one
    case inventory
    case three
}

struct ContentView: View {
    // 가장 첫번째 생성자
//    @State var selectedTab: Tab = .one
    // actual runtime of the feature
    let store: StoreOf<AppFeatureReducer>
    // Store<AppFeatureReducer.State, AppFeatureReducer.Action>
    
    var body: some View {
        // 그저 탭 한번 누를때마다 전부다 재계산하는건 비효율적. observe 안의 state를 정말 필요한 만큼의 최소단위로 줄일 것 -> `\.selectedTab`
        WithViewStore(self.store, observe: \.selectedTab) { viewStore in
            TabView(
                selection: viewStore.binding(
                    send: AppFeatureReducer.Action.selectedTabChanged
                )
            ) {
                FirstTabView(
                    store: self.store.scope(
                        state: \.firstTab,
                        action: AppFeatureReducer.Action.firstTab)
                )
                .tabItem { Text("하나") }
                .tag(Tab.one)
                
                InventoryView(
                    store: self.store.scope(
                        state: \.inventory,
                        action: AppFeatureReducer.Action.inventory
                    )
                )
                .tabItem { Text("인벤토리") }
                .tag(Tab.inventory)
                
                ThirdTabView(
                    store: self.store.scope(
                        state: \.thirdTab,
                        action: AppFeatureReducer.Action.thirdTab
                    )
                )
                .tabItem { Text("셋") }
                .tag(Tab.three)
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        // 생성자에 state 초기값 세팅할 수 있음
        ContentView(
            store: Store(
                initialState: AppFeatureReducer.State(), // or State(selectedTab: {YOUR.INITVALUE})`
                reducer: AppFeatureReducer()
            )
        )
    }
}
