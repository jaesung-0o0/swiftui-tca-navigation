//
//  ThirdTab.swift
//  NavigationTab
//
//  Created by Jaesung Lee on 2023/05/31.
//

import SwiftUI

import ComposableArchitecture

struct ThirdTabReducer: Reducer {
    struct State: Equatable { }
    
    enum Action: Equatable { }
    
    func reduce(into state: inout State, action: Action) -> Effect<Action> {
        switch action {
        }
        return .none
    }
}

struct ThirdTabView: View {
    let store: StoreOf<ThirdTabReducer>
    
    var body: some View {
        Text("셋")
    }
}
