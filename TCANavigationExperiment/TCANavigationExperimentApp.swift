import SwiftUI
import ComposableArchitecture

@main
struct TCANavigationExperimentApp: App {
  let store = Store(initialState: .init(), reducer: { AppFeature()._printChanges() })

    var body: some Scene {
        WindowGroup {
          AppView(store: self.store)
        }
    }
}
