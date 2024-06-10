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

extension AppFeature.DetailTag {
  var pathState: AppPath.State {
    switch self {
    case .featureA: .featureA(.init())
    case .featureB: .featureB(.init())
    case .featureC: .featureC(.init())
    case .menuFeature: .menuFeature(.init())
    }
  }
}
