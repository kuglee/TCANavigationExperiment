extension AppFeature.Path.State {
  var detailTag: AppFeature.DetailTag {
    switch self {
    case .featureA: .featureA
    case .featureB: .featureB
    case .featureC: .featureC
    }
  }
}

extension AppFeature.DetailTag {
  var pathState: AppFeature.Path.State {
    switch self {
    case .featureA: .featureA(.init())
    case .featureB: .featureB(.init())
    case .featureC: .featureC(.init())
    }
  }
}
