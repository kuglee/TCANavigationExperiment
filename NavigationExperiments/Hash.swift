extension AppFeature.Path.State: Hashable {
  func hash(into hasher: inout Hasher) {
    switch self {
    case .featureA: hasher.combine(0)
    case .featureB: hasher.combine(1)
    case .featureC: hasher.combine(2)
    }
  }
}
