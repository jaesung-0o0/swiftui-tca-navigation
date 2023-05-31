//
//  NavigationTabApp.swift
//  NavigationTab
//
//  Created by Jaesung Lee on 2023/05/31.
//

import SwiftUI
import ComposableArchitecture

@main
struct NavigationTabApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView(
                store: Store(
                    initialState: AppFeatureReducer.State(),
                    reducer: AppFeatureReducer()
                )
            )
        }
    }
}
