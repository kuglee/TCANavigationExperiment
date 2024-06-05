import ComposableArchitecture
import SwiftUI

@Reducer struct AppFeature {
  @Reducer(state: .hashable) enum Detail {
    case featureA(FeatureA)
    case featureB(FeatureB)
    case featureC(FeatureC)
  }

  @Reducer(state: .equatable, .sendable, action: .sendable) public enum Path {
    case featureA(FeatureA)
    case featureB(FeatureB)
    case featureC(FeatureC)
  }

  @ObservableState struct State {
    @Presents var detail: Detail.State?
    var path = StackState<Path.State>()
  }

  enum Action: BindableAction {
    case binding(BindingAction<State>)
    case detail(PresentationAction<Detail.Action>)
    case path(StackActionOf<Path>)
  }

  var body: some ReducerOf<Self> {
    BindingReducer()

    Reduce { state, action in
      switch action {
      case .binding: return .none
      case .detail: return .none
      case .path: return .none
      }
    }
    .ifLet(\.$detail, action: \.detail) { Detail.body }.forEach(\.path, action: \.path)
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
      List(selection: $store.detail) {
        NavigationLink(value: AppFeature.Detail.State.featureA(FeatureA.State())) {
          Text("Feature A")
        }
        NavigationLink(value: AppFeature.Detail.State.featureB(FeatureB.State())) {
          Text("Feature B")
        }
        NavigationLink(value: AppFeature.Detail.State.featureC(FeatureC.State())) {
          Text("Feature C")
        }
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

  @ViewBuilder func rootView(store: Store<AppFeature.Detail.State, AppFeature.Detail.Action>?)
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
  @ObservableState public struct State: Hashable {
    let title = "Feature A"
    var count: Int

    init(count: Int = 0) { self.count = count }
  }

  public enum Action: Sendable { case count }

  public var body: some Reducer<State, Action> {
    Reduce { state, action in
      switch action {
      case .count:
        state.count += 1

        return .none
      }
    }
  }
}
struct FeatureAView: View {
  let store: StoreOf<FeatureA>

  var body: some View {
    ScrollView {
      VStack {
        Text(store.title)
        Button("Count: \(self.store.count)") { self.store.send(.count) }
        Rectangle().fill(.red).frame(height: 2000, alignment: .top)
      }
    }
  }
}

@Reducer public struct FeatureB {
  @ObservableState public struct State: Hashable { let title = "Feature B" }
}
struct FeatureBView: View {
  let store: StoreOf<FeatureB>

  var body: some View {
    ScrollView {
      VStack {
        Text(store.title)
        Rectangle().fill(.green).frame(height: 2000, alignment: .top)
      }
    }
  }
}

@Reducer public struct FeatureC {
  @ObservableState public struct State: Hashable { let title = "Feature C" }
}
struct FeatureCView: View {
  let store: StoreOf<FeatureC>

  var body: some View {
    ScrollView {
      VStack {
        Text(store.title)
        Rectangle().fill(.blue).frame(height: 2000, alignment: .top)
      }
    }
  }
}
