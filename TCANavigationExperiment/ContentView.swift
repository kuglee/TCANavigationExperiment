import ComposableArchitecture
import SwiftUI

@Reducer(state: .equatable, .sendable, action: .sendable) public enum AppPath {
  case featureA(FeatureA)
  case featureB(FeatureB)
  case featureC(FeatureC)
  case menuFeature(MenuFeature)
}

extension AppPath.State {
  var detailTag: AppFeature.DetailTag {
    switch self {
    case .featureA: .featureA
    case .featureB: .featureB
    case .featureC: .featureC
    case .menuFeature: .menuFeature
    }
  }
}

@Reducer struct AppFeature {
  enum DetailTag: Equatable, Hashable {
    case featureA
    case featureB
    case featureC
    case menuFeature

    var pathState: AppPath.State {
      switch self {
      case .featureA: .featureA(.init())
      case .featureB: .featureB(.init())
      case .featureC: .featureC(.init())
      case .menuFeature: .menuFeature(.init())
      }
    }
  }

  enum Tab { case home, menu }

  @ObservableState struct State {
    @Presents var _detail: AppPath.State?
    private var _detailTag: DetailTag?
    var path = StackState<AppPath.State>()

    var selectedTab: Tab = .home
    var homeTab: HomeTab.State = .init()
    var menuTab: MenuTab.State = .init()

    init(
      detail: AppPath.State = .featureA(.init()),
      path: StackState<AppPath.State> = StackState<AppPath.State>()
    ) {
      self.detail = detail
      self.detailTag = detail.detailTag
      self.path = path
    }

    public var detail: AppPath.State? {
      get { self._detail }
      set {
        self._detail = newValue
        self._detailTag = self.detail.map { $0.detailTag }
      }
    }

    public var detailTag: DetailTag? {
      get { self._detailTag }
      set {
        self._detailTag = newValue
        self._detail = self.detailTag.map { $0.pathState }
      }
    }
  }

  enum Action: BindableAction {
    case binding(BindingAction<State>)
    case detail(PresentationAction<AppPath.Action>)
    case path(StackActionOf<AppPath>)
    case homeTab(HomeTab.Action)
    case menuTab(MenuTab.Action)
    case tabViewOnAppear
    case navigationSplitViewOnAppear
  }

  var body: some ReducerOf<Self> {
    BindingReducer()

    Scope(state: \.homeTab, action: \.homeTab) { HomeTab() }
    Scope(state: \.menuTab, action: \.menuTab) { MenuTab() }

    Reduce { state, action in
      switch action {
      case .binding: return .none
      case let .detail(.presented(.featureA(.rootNavigated(rootNavigation)))):
        return self.rootNavigated(state: &state, action: rootNavigation)
      case let .detail(.presented(.featureB(.rootNavigated(rootNavigation)))):
        return self.rootNavigated(state: &state, action: rootNavigation)
      case .detail: return .none
      case let .path(.element(id: _, action: .featureB(.rootNavigated(rootNavigation)))):
        return self.rootNavigated(state: &state, action: rootNavigation)
      case .path: return .none
      case .homeTab, .menuTab: return .none
      case .tabViewOnAppear:
        if let detail = state.detail {
          switch detail {
          case let .featureA(rootFeature):
            state.selectedTab = .home
            state.homeTab.rootFeature = rootFeature
            state.homeTab.path = state.path
          case .featureB, .featureC:
            state.selectedTab = .menu
            state.menuTab.path = [detail] + state.path
          case .menuFeature:
            XCTFail(
              "The detail is the menu feature. This can only happen when the NavigationSplitView's detail is the menu feature. The NavigationSplitView shouldn't show the menu feature as the detail."
            )
          }

          state.detail = nil
          state.path = StackState([])
        }

        return .none
      case .navigationSplitViewOnAppear:
        switch state.selectedTab {
        case .home:
          state.detail = .featureA(state.homeTab.rootFeature)
          state.path = state.homeTab.path
          state.homeTab.path = StackState([])
        case .menu:
          state.detail = state.menuTab.path.first ?? .featureA(.init())
          state.path = StackState(state.menuTab.path.dropFirst())
          state.menuTab.path = StackState([])
        }

        return .none
      }
    }
    .ifLet(\.$_detail, action: \.detail) { AppPath.body }.forEach(\.path, action: \.path)
  }

  func rootNavigated(state: inout State, action: RootNavigationAction) -> Effect<Action> {
    switch action {
    case .goToAScreen:
      state.path.append(.featureA(.init()))

      return .none
    case .goToBScreen:
      state.path.append(.featureB(.init()))

      return .none
    case .goToCScreen:
      state.path.append(.featureC(.init()))

      return .none
    }
  }
}

public struct AppView: View {
  @Bindable var store: StoreOf<AppFeature>

  @State var columnVisibility = NavigationSplitViewVisibility.all
  @Environment(\.horizontalSizeClass) var horizontalSizeClass

  public var body: some View {
    if self.horizontalSizeClass == .compact {
      self.navigationStack.onAppear { self.store.send(.tabViewOnAppear) }
    } else {
      self.navigationSplitView.onAppear { self.store.send(.navigationSplitViewOnAppear) }
    }
  }

  var navigationStack: some View {
    TabView(selection: self.$store.selectedTab) {
      HomeTabView(store: self.store.scope(state: \.homeTab, action: \.homeTab))
        .tabItem { Label("Kezdőlap", systemImage: "house.fill") }.tag(AppFeature.Tab.home)
      MenuTabView(store: self.store.scope(state: \.menuTab, action: \.menuTab))
        .tabItem { Label("Menu", systemImage: "list.dash") }.tag(AppFeature.Tab.menu)
    }
  }

  var navigationSplitView: some View {
    NavigationSplitView(columnVisibility: self.$columnVisibility) {
      List(selection: $store.detailTag) {
        // no arrow in compact mode when not using NavigationLink
        // since we're using using a NavigationStack in compact mode so it's ok
        Text("Feature A").tag(AppFeature.DetailTag.featureA)
        Text("Feature B").tag(AppFeature.DetailTag.featureB)
        Text("Feature C").tag(AppFeature.DetailTag.featureC)
      }
    } detail: {
      NavigationStack(path: self.$store.scope(state: \.path, action: \.path)) {
        self.rootView(store: store.scope(state: \.detail, action: \.detail.presented))
      } destination: {
        self.destinationView(store: $0)
      }
    }
    .navigationSplitViewStyle(.balanced)
  }

  @ViewBuilder func rootView(store: Store<AppPath.State, AppPath.Action>?) -> some View {
    if let store {
      switch store.case {
      case let .featureA(store): FeatureAView(store: store)
      case let .featureB(store): FeatureBView(store: store)
      case let .featureC(store): FeatureCView(store: store)
      case let .menuFeature(store): MenuFeatureView(store: store)
      }
    } else {
      Text("root")
    }
  }

  @ViewBuilder func destinationView(store: Store<AppPath.State, AppPath.Action>) -> some View {
    switch store.case {
    case let .featureA(store): FeatureAView(store: store)
    case let .featureB(store): FeatureBView(store: store)
    case let .featureC(store): FeatureCView(store: store)
    case let .menuFeature(store): MenuFeatureView(store: store)
    }
  }
}

#Preview { AppView(store: Store(initialState: .init(), reducer: { AppFeature()._printChanges() })) }

@Reducer public struct FeatureA {
  @ObservableState public struct State: Equatable, Sendable {
    let title = "Feature A"
    var count: Int

    init(count: Int = 0) { self.count = count }
  }

  public enum Action: Sendable {
    case count
    case count2
    case rootNavigated(RootNavigationAction)
    case goToBButtonTapped
  }

  public var body: some Reducer<State, Action> {
    Reduce { state, action in
      switch action {
      case .count:
        state.count += 1

        return .none
      case .count2:
        state.count -= 1

        return .none
      case .rootNavigated: return .none
      case .goToBButtonTapped: return .run { send in await send(.rootNavigated(.goToBScreen)) }
      }
    }
  }
}

struct FeatureAView: View {
  let store: StoreOf<FeatureA>

  var body: some View {
    ScrollView {
      VStack {
        Text(self.store.title)
        Button("Go to B") { self.store.send(.goToBButtonTapped) }
        Button("Count up: \(self.store.count)") { self.store.send(.count) }
        Button("Count down: \(self.store.count)") { self.store.send(.count2) }
        Rectangle().fill(.red).frame(height: 2000, alignment: .top)
      }
    }
    .navigationTitle(self.store.title)
  }
}

@Reducer public struct FeatureB {
  @ObservableState public struct State: Equatable, Sendable {
    let title = "Feature B"
    var count: Int

    init(count: Int = 0) { self.count = count }
  }

  public enum Action: Sendable {
    case count
    case count2
    case rootNavigated(RootNavigationAction)
    case goToCButtonTapped
  }

  public var body: some Reducer<State, Action> {
    Reduce { state, action in
      switch action {
      case .count:
        state.count += 1

        return .none
      case .count2:
        state.count -= 1

        return .none
      case .rootNavigated: return .none
      case .goToCButtonTapped: return .run { send in await send(.rootNavigated(.goToCScreen)) }
      }
    }
  }
}

struct FeatureBView: View {
  let store: StoreOf<FeatureB>

  var body: some View {
    ScrollView {
      VStack {
        Text(self.store.title)
        Button("Go to C") { self.store.send(.goToCButtonTapped) }
        Button("Count up: \(self.store.count)") { self.store.send(.count) }
        Button("Count down: \(self.store.count)") { self.store.send(.count2) }
        Rectangle().fill(.red).frame(height: 2000, alignment: .top)
      }
    }
    .navigationTitle(self.store.title)
  }
}

@Reducer public struct FeatureC {
  @ObservableState public struct State: Equatable, Sendable { let title = "Feature C" }
}
struct FeatureCView: View {
  let store: StoreOf<FeatureC>

  var body: some View {
    ScrollView {
      VStack {
        Text(self.store.title)
        Rectangle().fill(.blue).frame(height: 2000, alignment: .top)
      }
    }
    .navigationTitle(self.store.title)
  }
}

@Reducer public struct MenuFeature {
  @ObservableState public struct State: Equatable, Sendable {
    let title = "Menu"

    public init() {}
  }

  public enum Action: Sendable {
    case goToBButtonTapped
    case rootNavigated(RootNavigationAction)
  }

  public var body: some Reducer<State, Action> {
    Reduce { state, action in
      switch action {
      case .goToBButtonTapped: return .run { send in await send(.rootNavigated(.goToBScreen)) }
      case .rootNavigated: return .none
      }
    }
  }
}

struct MenuFeatureView: View {
  let store: StoreOf<MenuFeature>

  var body: some View {
    ScrollView {
      VStack {
        Text(self.store.title)
        Button("Go to B") { self.store.send(.goToBButtonTapped) }
        Rectangle().fill(.red).frame(height: 2000, alignment: .top)
      }
    }
    .navigationTitle(self.store.title)
  }
}

public enum RootNavigationAction: Sendable {
  case goToAScreen
  case goToBScreen
  case goToCScreen
}

@Reducer public struct HomeTab {
  @ObservableState public struct State: Equatable, Sendable {
    var path = StackState<AppPath.State>()
    var rootFeature: FeatureA.State = .init()

    public init(path: StackState<AppPath.State> = StackState<AppPath.State>()) { self.path = path }
  }

  public enum Action: BindableAction, Sendable {
    case binding(BindingAction<State>)
    case rootNavigated(RootNavigationAction)
    case goToBButtonTapped
    case path(StackActionOf<AppPath>)
    case rootFeature(FeatureA.Action)
  }

  public var body: some Reducer<State, Action> {
    BindingReducer()

    Scope(state: \.rootFeature, action: \.rootFeature) { FeatureA() }

    Reduce { state, action in
      switch action {
      case .binding: return .none
      case .rootNavigated: return .none
      case .goToBButtonTapped: return .run { send in await send(.rootNavigated(.goToBScreen)) }
      case let .path(.element(id: _, action: .featureB(.rootNavigated(rootNavigation)))):
        return self.rootNavigated(state: &state, action: rootNavigation)
      case .path: return .none
      case let .rootFeature(.rootNavigated(rootNavigation)):
        return self.rootNavigated(state: &state, action: rootNavigation)
      case .rootFeature: return .none
      }
    }
    .forEach(\.path, action: \.path)
  }

  func rootNavigated(state: inout State, action: RootNavigationAction) -> Effect<Action> {
    switch action {
    case .goToAScreen:
      state.path.append(.featureA(.init()))

      return .none
    case .goToBScreen:
      state.path.append(.featureB(.init()))

      return .none
    case .goToCScreen:
      state.path.append(.featureC(.init()))

      return .none
    }
  }

}

struct HomeTabView: View {
  @Bindable var store: StoreOf<HomeTab>

  var body: some View {
    NavigationStack(path: self.$store.scope(state: \.path, action: \.path)) {
      FeatureAView(store: self.store.scope(state: \.rootFeature, action: \.rootFeature))
    } destination: { store in
      switch store.case {
      case let .featureA(store): FeatureAView(store: store)
      case let .featureB(store): FeatureBView(store: store)
      case let .featureC(store): FeatureCView(store: store)
      case let .menuFeature(store): MenuFeatureView(store: store)
      }
    }
  }
}

@Reducer public struct MenuTab {
  @ObservableState public struct State: Equatable, Sendable {
    var path = StackState<AppPath.State>()
    var rootFeature: MenuFeature.State = .init()

    public init(
      rootFeature: MenuFeature.State = .init(),
      path: StackState<AppPath.State> = StackState<AppPath.State>()
    ) {
      self.rootFeature = rootFeature
      self.path = path
    }
  }

  public enum Action: BindableAction, Sendable {
    case binding(BindingAction<State>)
    case rootNavigated(RootNavigationAction)
    case path(StackActionOf<AppPath>)
    case rootFeature(MenuFeature.Action)
  }

  public var body: some Reducer<State, Action> {
    BindingReducer()

    Scope(state: \.rootFeature, action: \.rootFeature) { MenuFeature() }

    Reduce { state, action in
      switch action {
      case .binding: return .none
      case .rootNavigated: return .none
      case let .path(.element(id: _, action: .featureB(.rootNavigated(rootNavigation)))):
        return self.rootNavigated(state: &state, action: rootNavigation)
      case .path: return .none
      case let .rootFeature(.rootNavigated(rootNavigation)):
        return self.rootNavigated(state: &state, action: rootNavigation)
      case .rootFeature: return .none
      }
    }
    .forEach(\.path, action: \.path)
  }

  func rootNavigated(state: inout State, action: RootNavigationAction) -> Effect<Action> {
    switch action {
    case .goToAScreen:
      state.path.append(.featureA(.init()))

      return .none
    case .goToBScreen:
      state.path.append(.featureB(.init()))

      return .none
    case .goToCScreen:
      state.path.append(.featureC(.init()))

      return .none
    }
  }

}

struct MenuTabView: View {
  @Bindable var store: StoreOf<MenuTab>

  var body: some View {
    NavigationStack(path: self.$store.scope(state: \.path, action: \.path)) {
      MenuFeatureView(store: self.store.scope(state: \.rootFeature, action: \.rootFeature))
    } destination: { store in
      switch store.case {
      case let .featureA(store): FeatureAView(store: store)
      case let .featureB(store): FeatureBView(store: store)
      case let .featureC(store): FeatureCView(store: store)
      case let .menuFeature(store): MenuFeatureView(store: store)
      }
    }
  }
}
