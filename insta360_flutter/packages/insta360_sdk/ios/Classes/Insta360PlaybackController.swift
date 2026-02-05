import Foundation
import UIKit
#if !targetEnvironment(simulator)
import INSCameraSDK
import INSCameraServiceSDK
import INSCoreMedia
#endif

#if targetEnvironment(simulator)
final class Insta360PlaybackController: NSObject {
  static let shared = Insta360PlaybackController()

  weak var eventHandler: Insta360EventStreamHandler?

  func setContainer(_ container: UIView) {}

  func clearContainer(_ container: UIView) {}

  func setVideoSources(_ sources: [String], completion: @escaping (String?) -> Void) {
    completion("simulator_not_supported")
  }

  func play() {}

  func pause() {}

  func stop() {}
}
#else
final class Insta360PlaybackController: NSObject {
  static let shared = Insta360PlaybackController()

  weak var eventHandler: Insta360EventStreamHandler?

  private weak var container: UIView?
  private var renderView: INSRenderView?
  private var previewer: INSPreviewer3?

  func setContainer(_ container: UIView) {
    DispatchQueue.main.async {
      self.container = container
      self.attachRenderViewIfNeeded()
    }
  }

  func clearContainer(_ container: UIView) {
    DispatchQueue.main.async {
      if self.container === container {
        self.container = nil
        self.previewer?.shutdown()
        self.previewer = nil
      }
      if let renderView = self.renderView, renderView.superview === container {
        renderView.removeFromSuperview()
      }
    }
  }

  func setVideoSources(_ sources: [String], completion: @escaping (String?) -> Void) {
    DispatchQueue.main.async {
      guard let container = self.container else {
        completion("player_view_not_ready")
        return
      }
      guard !sources.isEmpty else {
        completion("missing_sources")
        return
      }
      let urls = sources.compactMap { self.urlFromStringOrURI($0) }
      guard !urls.isEmpty else {
        completion("invalid_sources")
        return
      }

      self.previewer?.shutdown()
      self.previewer = nil

      self.attachRenderViewIfNeeded()
      guard let renderView = self.renderView else {
        completion("render_view_unavailable")
        return
      }

      let previewer = INSPreviewer3()
      previewer.displayDelegate = renderView
      self.previewer = previewer

      self.configureRenderView(renderView)

      let metadata = self.parseVideoMetadata(url: urls[0])
      let durationMs = max(metadata.durationMs, 1)

      let segment = INSEmSegment(url: urls, totalSrcDurationMs: durationMs, isValid: true)
      let clip = INSFileClip(
        emSegment: [segment],
        startTimeMs: 0,
        endTimeMs: durationMs,
        totalSrcDurationMs: durationMs,
        timeScales: nil,
        hasAudio: false,
        mediaFileSize: metadata.mediaFileSize,
        videoTrackCount: metadata.videoTrackCount,
        reverseVideoTrackOrder: metadata.reverseVideoTrackOrder
      )

      previewer.setVideoSource([clip], bgmSource: nil, videoSilent: false)
      previewer.prepareAsync(0)
      renderView.playVideo(withOffset: metadata.offset)
      completion(nil)
    }
  }

  func play() {
    DispatchQueue.main.async {
      self.previewer?.play()
    }
  }

  func pause() {
    DispatchQueue.main.async {
      self.previewer?.pause()
    }
  }

  func stop() {
    DispatchQueue.main.async {
      self.previewer?.shutdown()
      self.previewer = nil
    }
  }

  private func attachRenderViewIfNeeded() {
    guard let container = container else { return }
    if renderView == nil {
      renderView = INSRenderView(frame: container.bounds, renderType: .sphericalPanoRender)
    }
    guard let renderView else { return }
    if renderView.superview !== container {
      container.subviews.forEach { $0.removeFromSuperview() }
      renderView.frame = container.bounds
      renderView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
      container.addSubview(renderView)
    }
  }

  private func configureRenderView(_ renderView: INSRenderView) {
    let stitchInfo = INSStitchingInfo()
    renderView.render.stitchingInfo = stitchInfo
    renderView.render.colorFusion = true
    renderView.render.stitchType = .disflow
  }

  private func urlFromStringOrURI(_ value: String) -> URL? {
    if value.hasPrefix("file://"), let url = URL(string: value) {
      return url
    }
    if value.hasPrefix("/") {
      return URL(fileURLWithPath: value)
    }
    if let url = URL(string: value), url.scheme != nil {
      return url
    }
    return INSHTTPURLForResourceURI(value)
  }

  private func parseVideoMetadata(url: URL) -> (offset: String?, durationMs: Double, mediaFileSize: Int64, videoTrackCount: Int32, reverseVideoTrackOrder: Bool) {
    let cacheDir = NSHomeDirectory() + "/Documents/com.insta360.asset.video"
    let asset = INSVideoAsset(path: url.absoluteString, cacheDir: cacheDir, option: .All)

    var offset: String?
    var durationMs: Double = 0
    var mediaFileSize: Int64 = 0
    var videoTrackCount: Int32 = 1
    var reverseVideoTrackOrder = false

    if asset.open() == nil {
      if let offsetV3 = asset.extraMetadata?.offsetV3, !offsetV3.isEmpty {
        offset = offsetV3
      } else if let offsetV2 = asset.extraMetadata?.offsetV2, !offsetV2.isEmpty {
        offset = offsetV2
      } else if let offsetV1 = asset.extraMetadata?.offset, !offsetV1.isEmpty {
        offset = offsetV1
      }

      let durationS = asset.demuxerInfo?.videoDurationS ?? 0
      durationMs = durationS * 1000
      mediaFileSize = Int64(asset.mediaFileSize)
      videoTrackCount = asset.extraMetadata?.videoTrackCount ?? 1
      reverseVideoTrackOrder = asset.extraMetadata?.reverseVideoTrackOrder == true
    }

    return (offset, durationMs, mediaFileSize, videoTrackCount, reverseVideoTrackOrder)
  }
}
#endif
