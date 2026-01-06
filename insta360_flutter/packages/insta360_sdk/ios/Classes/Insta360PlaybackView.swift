import Flutter
import UIKit

final class Insta360PlaybackView: NSObject, FlutterPlatformView {
  private let container: UIView
  private let playbackController: Insta360PlaybackController

  init(frame: CGRect, viewId: Int64, args: Any?, playbackController: Insta360PlaybackController) {
    container = UIView(frame: frame)
    self.playbackController = playbackController
    super.init()
    container.backgroundColor = UIColor.black
    playbackController.setContainer(container)
  }

  func view() -> UIView {
    return container
  }

  deinit {
    playbackController.clearContainer(container)
  }
}
