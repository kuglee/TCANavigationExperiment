import ComposableArchitecture
import SwiftUI

@Reducer struct AppFeature {
  @Reducer(state: .hashable) enum Detail {
    case featureA(FeatureA)
    case featureB(FeatureB)
    case featureC(FeatureC)
  }

  @ObservableState struct State { @Presents var detail: Detail.State? }

  enum Action: BindableAction {
    case binding(BindingAction<State>)
    case detail(PresentationAction<Detail.Action>)
  }

  var body: some ReducerOf<Self> {
    BindingReducer()

    Reduce { state, action in
      switch action {
      case .binding: return .none
      case .detail: return .none
      }
    }
    .ifLet(\.$detail, action: \.detail) { Detail.body }
  }
}

public struct AppView: View {
  @Bindable var store: StoreOf<AppFeature>

  @State var columnVisibility = NavigationSplitViewVisibility.all

  public var body: some View {
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
      if let store = store.scope(state: \.detail, action: \.detail.presented) {
        switch store.case {
        case let .featureA(store): FeatureAView(store: store)
        case let .featureB(store): FeatureBView(store: store)
        case let .featureC(store): FeatureCView(store: store)
        }
      }
    }
    .navigationSplitViewStyle(.balanced)
  }
}

#Preview { AppView(store: Store(initialState: .init(), reducer: { AppFeature()._printChanges() })) }

@Reducer public struct FeatureA {
  @ObservableState public struct State: Hashable { var title = "Feature A" }
}
struct FeatureAView: View {
  let store: StoreOf<FeatureA>

  var body: some View {
    ScrollView {
      VStack {
        Text(store.title)
        Rectangle().fill(.red).frame(height: 2000, alignment: .top)
      }
    }
  }
}

@Reducer public struct FeatureB {
  @ObservableState public struct State: Hashable { var title = "Feature B" }
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
  @ObservableState public struct State: Hashable { var title = "Feature C" }
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
