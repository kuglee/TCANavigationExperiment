import ComposableArchitecture
import SwiftUI

@Reducer struct AppFeature {
  @Reducer(state: .equatable, .sendable, action: .sendable) enum Path {
    case featureA(FeatureA)
    case featureB(FeatureB)
    case featureC(FeatureC)
  }

  enum DetailTag: Equatable, Hashable {
    case featureA
    case featureB
    case featureC
  }

  @ObservableState struct State {
    @Presents var _detail: Path.State?
    private var _detailTag: DetailTag?
    var path = StackState<Path.State>()

    init(
      detail: AppFeature.Path.State = .featureA(.init()),
      path: StackState<AppFeature.Path.State> = StackState<Path.State>()
    ) {
      self.detail = detail
      self.detailTag = detail.detailTag
      self.path = path
    }

    public var detail: Path.State? {
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
    case detail(PresentationAction<Path.Action>)
    case path(StackActionOf<Path>)
  }

  var body: some ReducerOf<Self> {
    BindingReducer()

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
      }
    }
    .ifLet(\.$_detail, action: \.detail) { Path.body }.forEach(\.path, action: \.path)
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
      self.navigationStack
    } else {
      self.navigationSplitView
    }
  }

  var navigationStack: some View {
    NavigationStack(path: self.$store.scope(state: \.path, action: \.path)) {
      self.rootView(store: store.scope(state: \.detail, action: \.detail.presented))
    } destination: {
      self.destinationView(store: $0)
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

  @ViewBuilder func rootView(store: Store<AppFeature.Path.State, AppFeature.Path.Action>?)
    -> some View
  {
    if let store {
      switch store.case {
      case let .featureA(store): FeatureAView(store: store)
      case let .featureB(store): FeatureBView(store: store)
      case let .featureC(store): FeatureCView(store: store)
      }
    } else {
      Text("root")
    }
  }

  @ViewBuilder func destinationView(store: Store<AppFeature.Path.State, AppFeature.Path.Action>)
    -> some View
  {
    switch store.case {
    case let .featureA(store): FeatureAView(store: store)
    case let .featureB(store): FeatureBView(store: store)
    case let .featureC(store): FeatureCView(store: store)
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

public enum RootNavigationAction: Sendable {
  case goToAScreen
  case goToBScreen
  case goToCScreen
}
