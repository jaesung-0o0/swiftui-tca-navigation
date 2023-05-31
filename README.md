# TCA Navigations

## Tab

> Tip: prerelease/1.0 브랜치에서는 다음과 같은 public interfaces 변경이 있다
> 
> `ReducerProtocol` -> `Reducer`
>
> `EffectTask` -> `Effect`

Tab 종류가 아래와 같다고 가정 (실제 코드보다 간소화함)

```swift
enum Tab {
    case one
    case inventory
}
```

### TCA 적용전 ParentView 의 코드

```swift
struct ContentView: View {
    @State var selectedTab: Tab = .one
    
    var body: some View {
        TabView(selection: $selectedTab) {
            Button {
                selectedTab = .inventory
            } label: {
                Text("인벤토리 가기")
            }
            .tabItem { Text("하나") }
            .tag(Tab.one)
            
            Text("인벤토리")
                .tabItem { Text("인벤토리") }
                .tag(Tab.inventory)
        }
    }
}
```

```swift
struct ConetntView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView() 
        // 생성자에서 state 세팅가능. e.g., .init(selectedTab: .inventory)
    }
}
```


### Parent feature

```swift
struct AppFeature: Reducer {
    struct State: Equatable {
        var selectedTab: Tab = .one
        var firstTab = FirstTabReducer.State()
        var inventory = InventoryReducer.State()
        // ...
    }
    
    enum Action: Equatable {
        case selectedTabChanged(Tab)
        case firstTab(FirstTabReducer.Action)
        case inventory(InventoryReducer.Action)
        // ...
    }
    
    var body: some ReducerOf<Self> {
        // Reducer의 루트 레벨
        Reduce<State, Action> { state, action in
            switch action {
            case .firstTab(.delegate(let action)):
                // 새 delegate action 추가되면 컴파일에러 유도하도록 case let 사용
                switch action {
                case .switchToInventoryTab:
                    state.selectedTab = .inventory
                    return .none
                }
                
            case .selectedTabChanged(let tab):
                state.selectedTab = tab
                return .none
                
            case .firstTab, .inventory:
                return .none
            }
        }
        
        // 하위 도메인 Scope
        Scope(state: \.firstTab, action: /Action.firstTab) {
            FirstTabReducer()
        }
        Scope(state: \.inventory, action: /Action.inventory) {
            InventoryReducer()
        }
        
        // 그냥 각각 도메인을 써버리면 state, action 이 서로 완전히 달라서 계싼 불가
        // 예:
        // FirstTabReducer()
        // InventoryReducer()
        // 그래서 scope 으로 감싸서 각각의 state, action 이 Self 에 속한 통일 형태로 유추 되게 사용해야함.
    }
}
```

### Parent View

- 탭뷰 selection 에 바인딩할 때 `ViewStore/binding(send:)` 사용 (`get` 까지 필요 없음)
- 하위 뷰에 store 주입할 때 `Store/scope(state:action:)` 사용. 
    - `state`: key path 를 사용하므로 백슬래시 통해서 프로퍼티 접근 `\.firstTab`
    - `action`: Case path 이므로 슬래시 사용하거나 직접 타입에 접근 `AppFeature.Action.firstTab`

```swift
struct ContentView: View {
    /// 기능에 대한 실제 런타임
    let store: StoreOf<AppFeature>
    /// or `Store<AppFeature.State, AppFeature.Action>
    
    var body: some View {
        /// why `observe: \.selectedTab` ?
        /// 탭 한번 누를때마다 전부 다 재계산 하는 건 비효율적. 
        /// `observe` 안의 `state` 를 정말 필요한 만큼의 최소단위로 줄일 것.
        WithViewStore(self.store, observe: \.selectedTab) { viewStore in
            TabView(
                selection: viewStore.binding(send: AppFeature.Action.selectedTabChanged)
            ) {
                FirstTabView(
                    store: self.store.scope(
                        state: \.firstTab,
                        action: AppFeature.Action.firstTab
                    )
                )
                .tabItem { Text("하나") }
                .tab(Tab.one)
                
                InventoryView(
                    store: self.store.scope(
                        state: \.inventory,
                        action: AppFeature.Action.inventory
                    )
                )
                .tabItem { Text("인벤토리") }
                .tag(Tab.inventory)
            }
        }
    }
}
```

```swift
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView(
            store: Store(
                initialState: AppFeature.State(), // or State(selectedTab:)
                reducer: AppFeature()
            )
        )
    }
}
```

### First tab

```swift
struct FirstTabReducer: Reducer {
    struct State: Equatable { }
    
    enum Action: Equatable {
        case goToInventoryButtonTapped
        case delegate(Delegate) // old pattern of UIKit
        
        enum Delegate: Equatable {
            case switchToInventoryTab
        }
    }
    
    func reduce(into state: inout State, action: Action) -> Effect<Action> {
        switch action {
        case .delegate:
            return .none
        case .goToInventoryButtonTapped:
            // send는 delegate 액션에 적합
            return .send(.delegate(.switchToInventoryTab))
        }
    }
}
```

```swift
struct FirstTabView: View {
    let store: StoreOf<FirstTabReducer>
    
    var body: some View {
        WithViewStore(self.store, observe: { $0 }) { viewStore in
            Button {
                // viewStore.send(.selectedTabChanged(.inventory)
                viewStore.send(.goToInventoryButtonTapped) // Delegate
            } label: {
                Text("인벤토리 가기")
            }
        }
    }
}
```

### InventoryReducer

```swift
struct InventoryReducer: Reducer {
    struct State: Equatable { }
    
    enum Action: Equatable { }

    func reduce(into state: inout State, action: Action) -> Effect<Action> { }
}
```

```swift
struct InventoryView: View {
    let store: StoreOf<InventoryReducer>
    
    var body: some View {
        Text("인벤토리")
    }
}
```

### Tests

```swift
@MainActor
final class NavigationTabTests: XCTestCase {
    let store = TestStore(
        initialstate: AppFeature.State(),
        reducer: AppFeature()
    )
    
    await store.send(.firstTab(.goToInventoryButtonTapped))
    await store.receive(.firstTab(.delegate(.switchToInventoryTab))) {
        state.selectedTab = .inventory // $0 은 state
    }
}
```
