> **링크**: [Navigation: Alerts & Dialogs | pointfree.co](https://www.pointfree.co/episodes/ep223-composable-navigation-alerts-dialogs)

## Alerts today (17 steps)

### Item 
```swift
struct Item: Equatable, Identifiable {
    ...
    
    // var quantity: Int?
    // var isOnBackOrder: Bool?
    
    enum Status: Equatable {
        case inStock(quantity: Int) // 재고
        case outOfStock(isOnBackOrder: Bool) // 재고없음
        
        var isInStock: Bool { self == .inStock }
    }
}
```
### Inventory
```swift
struct InventoryFeature: Reducer {
    struct State: Equatable {
        // 1
        var items: IdentifiedArrayOf<Item> = []
        // 7
        var alert: AlertState<Action.Alert>?
    }
    
    enum Action: Equatable {
        // 4
        case deleteButtonTapped(id: Item.ID)
        // 8
        // case confirmDeletion(id: Item.ID)
        // 10
        case alert(Alert)
        
        // 9
        enum Alert: Equatable {
            case confirmDeletion(id: Item.ID)
            // 14
            case dismiss
        }
    }
    
    func reduce(into state: inout State, action: Action) -> Effect<Action> {
        // 6
        switch action {
        case .deleteButtonTapped(let id):
            // TODO: show alert
            // 12
            guard let item = state.items[id: id] else { return .none }
            state.alert = AlertState {
                TextState(#"Delete "\#(item.name)""#) // what's # do? -> quote
            } actions: {
                ButtonState(
                    role: .destructive, 
                    action: .confirmDeletion(id: item.id)
                    // 17: 애니메이션 넣기
                    // action: send(.confirmDeletion(id: item.id), animation: .default)
                ) {
                    TextState("삭제" )
                }
            } message: {
                TextState("정말 삭제하시겠습니까?")
            }
            return .none
        // 11
        case .alert(.confirmDeletion(let id)):
            state.items.remove(id: id) // IdentifiedArray 의 메소드
            return .none
        // 15
        case .alert(.dismiss):
            state.alert = nil
            return .none
        }
    }
}
```

```swift
struct InventoryView: View {
    let store: StoreOf<InventoryFeature>
    
    var body: some View {
        // 2
        WithViewStore(self.store, observe: \.items) { viewStore in
            // 3
            List {
                ForEach(viewStore.state) { item in
                    HStack {
                        VStack(alignment: .leading) {
                            Text(item.name)
                            
                            switch item.status {
                            case .inStock(let quantity):
                                Text("In stock: \(quantity)")
                            case .outOfStock(isOnBackOrder):
                                Text("Out of stock" + (isOnBackOrder ? ": on back order" : ""))
                            }
                        }
                        
                        Spacer()
                        
                        Button {
                            // TODO: Delete item
                            // 5
                            viewStore.send(.deleteButtonTapped(id: item.id))
                        } label: {
                            Image(systemName: "trash.fill")
                        }
                        .padding(.leading)
                    }
                    .buttonStyle(.plain)
                    .foregroundColor(item.status.isInStock ? nil : Color.gray)
                }
            }
            // 13
            .alert(
                self.store.scope(
                    state: \.alert,
                    action: InventoryFeature.Action.alert
                ),
                // 16
                dismiss: .dimiss
            )
        }
    }
}
```

문제점.
item 을 지우고 나서 alert state는 살아있고, 그 다음 단계에서 사라진다.
즉, 2 steps 를 거쳐야하는 문제가 있다.

### 테스트
```swift
func testDelete() async {
    let item = Item.headphones
    
    let store = TestStore(
        initialState: InventoryFeature.State(items: [item]),
        reducer: InventoryFeature()
    )
    await store.send(.deleteButtonTapped(id: item.id)) {
        $0.alert = .delete(item: item)
    }
    await store.send(.alert(.confirmDeletion(id: item.id))) {
        $0.items = []
    }
    await store.send(.alert(.dismiss)) {
        $0.alert = nil
    }
}
```

## Reducer Alert
- NOTE: `ifLet`, `ifLetStore` 등 전부 IdentifiedArray를 받고 있다.

### Reducer.alert
```swift
// Navigation.swift
import ComposableArchitecture

extension Reducer {
    func alert<Action>(
        state alertKeyPath: WritableKeyPath<State, AlertState<Action>?>,
        action alertCasePath: CasePath<Self.Action, AlertAction<Action>>
    ) -> some ReducerOf<Self> {
        // Alert reducer
        Reduce { state, action in
            let effects = self.reduce(into: &state, action: action)
            if alertCasePath ~= action {
                state[keyPath: alertKeyPath] = nil
            }
            return effects
        }
    }
}
```
### Reducer body
```swift
var body: some ReudcerOf<Self> {
    Reduce { state, action in 
        switch action {
        case .deleteButtonTapped(let id):
            guard let item = state.items[id: id] else { return .none }
            state.alert = AlertState {
                TextState(#"Delete "\#(item.name)""#) // what's # do? -> quote
            } actions: {
                ButtonState(
                    role: .destructive, 
                    action: .send(.confirmDeletion(id: item.id), animation: .default)
                ) {
                    TextState("삭제" )
                }
            } message: {
                TextState("정말 삭제하시겠습니까?")
            }
            return .none
       
        case .alert(.confirmDeletion(let id)):
            state.items.remove(id: id) // IdentifiedArray 의 메소드
            return .none
        
        // 2: remove 
        // - case .alert(.dismiss):
        // -     state.alert = nil
        // -     return .none
        // - }
        case .alert:
            return .none
    }
    // 1
    .alert(
        state: \.alert,
        action: /Action.alert
    )
}
```
### AlertAction and View.alert
```swift
enum AlertAction<Action> {
    case dismiss
    case presented(Action)
}

// Action 이 Equatable 이면 AlertAction 도 Equtable
extension AlertAction: Equatable where Action: Equatable { }
```

```swift
extension View {
    func alert<Action>(
        store: Store<AlertState<Action>?, AlertAction<Action>>
    ) -> some View {
        WithViewStore(
            store, 
            observe: { $0 },
            removeDuplicates: { ($0 != nil) == ($1 != nil) }
        ) { viewStore in
            self.alert( // SwiftUINavigation
                unwrapping: Binding(
                    get: { viewStore.state },
                    set: { newState in
                      if viewStore.state ~= nil {
                          viewStore.send(.dismiss)
                      }
                )
            ) { action in
                if let action {
                    viewStore.send(.presendted(action)
                }
            }
        }
    }
}
```

### State
```swift
struct State: Equatable {
    var alert: AlertState<Aciton.Alert>?
}
```
### Action
```swift
enum Action: Equatable {
    case alert(AlertAction<Alert>)
    
    enum Alert: Equatable {
        // - case dismiss
    }
}
```
### Reducer
```swift
switch action {
// 해석: alert 이 presented 상태일때, confirmDeletion 액션이 들어온다면
case .alert(.presented(.confirmDeletion(id))):
  ...

```
### ViewStore

```swift
.alert(
    store: self.store.scope(state: \.alert, action: InventoryFeature.Action.alert)
)
```
### 테스트
```swift
func testDelete() async {
    let item = Item.headphones
    
    let store = TestStore(
        initialState: InventoryFeature.State(items: [item]),
        reducer: InventoryFeature()
    )
    await store.send(.deleteButtonTapped(id: item.id)) {
        $0.alert = .delete(item: item)
    }
    await store.send(.alert(.presented(.confirmDeletion(id: item.id)))) {
        $0.alert = nil
        $0.items = []
    }
    // - await store.send(.alert(.dismiss)) {
    // -     $0.alert = nil
    // - }
}
```

## Summary
### State
```swift
struct State: Equatable {
    var alert: AlertState<Action.Alert>?
}
```
### Action
```swift
enum Action: Equatable {
    case alert(Alert)
    
    enum Alert: Equatable {
        case confirmDeletion(id: Item.ID)
        case dismiss
    }
}
```
### Reducer
```swift
func reduce(into state: inout State, action: Action) -> Effect<Action> {
    switch action {
    case .alert(.confirmDeletion(let id)):
        ...
    case .alert(.dimiss):
        ...
    case .deleteButtonTapped(let id):
        state.alert = AlertState {
            ...
        } actions: {
            ButtonState(
                role: .destructive, 
                action: .confirmDeletion(id: item.id)
            ) { ... }
        } message: {
            ...
        }
    }
}
```
### ViewStore
```swift
Button {
    viewStore.send(.deleteButtonTapped(id: item.id))
} label: {
    ...
}
```
```swift
.alert(
    self.store.scope(state: \.alert, action: InventoryFeature.Action.alert),
    dismiss: .dismiss
)
```

## 디버깅하기

```swift
ContentView(
    store: Store(
        initialState: ...,
        reducer: AppFeture()
            ._printChanges()
    )
)
```
