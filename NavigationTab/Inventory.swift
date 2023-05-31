//
//  Inventory.swift
//  NavigationTab
//
//  Created by Jaesung Lee on 2023/05/31.
//

import SwiftUI
import ComposableArchitecture

struct InventoryReducer: Reducer {
    struct State: Equatable { }
    
    enum Action: Equatable { }
    
    func reduce(into state: inout State, action: Action) -> Effect<Action> {
        switch action {
        }
        return .none
    }
}

struct InventoryView: View {
    let store: StoreOf<InventoryReducer>
    
    var body: some View {
        Text("인벤토리")
    }
}
