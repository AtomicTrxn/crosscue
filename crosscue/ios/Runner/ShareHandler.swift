import Flutter
import LinkPresentation
import UIKit

/// Method-channel handler for sharing a solve result with a *branded* iOS
/// share-sheet thumbnail.
///
/// `share_plus` can only brand the share-sheet preview by attaching an image
/// to the shared payload (its `LPLinkMetadata.imageProvider` is derived from
/// the shared file). We want the opposite: a text-only share whose preview
/// still shows the Crosscue icon. iOS supports this via
/// `LPLinkMetadata.iconProvider`, which is metadata only — it is NOT delivered
/// to the recipient. So this handler presents its own
/// `UIActivityViewController` with a custom `UIActivityItemSource` that shares
/// the result text and supplies the icon purely as link metadata.
///
/// Dart calls this on iOS only (see `lib/.../native_share.dart`); Android keeps
/// using `share_plus`.
final class ShareHandler: NSObject {
  static let channelName = "crosscue.share"

  static func register(with messenger: FlutterBinaryMessenger) {
    let channel = FlutterMethodChannel(
      name: channelName,
      binaryMessenger: messenger
    )
    let handler = ShareHandler()
    channel.setMethodCallHandler { call, result in
      handler.handle(call: call, result: result)
    }
  }

  func handle(call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "shareResult":
      shareResult(call: call, result: result)
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  private func shareResult(call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard let args = call.arguments as? [String: Any],
          let text = args["text"] as? String else {
      result(
        FlutterError(
          code: "BAD_ARGS",
          message: "shareResult requires a 'text' string",
          details: nil
        )
      )
      return
    }
    let subject = args["subject"] as? String
    var icon: UIImage?
    if let bytes = (args["iconPng"] as? FlutterStandardTypedData)?.data {
      icon = UIImage(data: bytes)
    }
    // iPad anchors the share sheet to a rect; iPhone ignores this.
    let origin = CGRect(
      x: (args["originX"] as? Double) ?? 0,
      y: (args["originY"] as? Double) ?? 0,
      width: (args["originWidth"] as? Double) ?? 0,
      height: (args["originHeight"] as? Double) ?? 0
    )

    DispatchQueue.main.async {
      guard let presenter = Self.topViewController() else {
        result(
          FlutterError(
            code: "NO_PRESENTER",
            message: "No view controller available to present the share sheet",
            details: nil
          )
        )
        return
      }

      let item = ShareResultItem(text: text, subject: subject, icon: icon)
      let activityVC = UIActivityViewController(
        activityItems: [item],
        applicationActivities: nil
      )

      if let popover = activityVC.popoverPresentationController {
        popover.sourceView = presenter.view
        if origin.isEmpty {
          // No anchor supplied — center it and drop the arrow.
          popover.sourceRect = CGRect(
            x: presenter.view.bounds.midX,
            y: presenter.view.bounds.midY,
            width: 0,
            height: 0
          )
          popover.permittedArrowDirections = []
        } else {
          popover.sourceRect = origin
        }
      }

      activityVC.completionWithItemsHandler = { _, _, _, error in
        if let error = error {
          result(
            FlutterError(
              code: "SHARE_FAILED",
              message: error.localizedDescription,
              details: nil
            )
          )
        } else {
          result(nil)
        }
      }

      presenter.present(activityVC, animated: true)
    }
  }

  /// Walk to the front-most presented controller so we never try to present
  /// from a controller that's already covered.
  private static func topViewController() -> UIViewController? {
    let keyWindow = UIApplication.shared.connectedScenes
      .compactMap { $0 as? UIWindowScene }
      .flatMap { $0.windows }
      .first { $0.isKeyWindow }
    var top = keyWindow?.rootViewController
    while let presented = top?.presentedViewController {
      top = presented
    }
    return top
  }
}

/// Shares the result text, supplying the Crosscue icon as link metadata only.
/// The icon is shown in the share-sheet preview but is not part of the shared
/// content — recipients receive just the text.
private final class ShareResultItem: NSObject, UIActivityItemSource {
  private let text: String
  private let subject: String?
  private let icon: UIImage?

  init(text: String, subject: String?, icon: UIImage?) {
    self.text = text
    self.subject = subject
    self.icon = icon
  }

  func activityViewControllerPlaceholderItem(
    _ activityViewController: UIActivityViewController
  ) -> Any {
    return text
  }

  func activityViewController(
    _ activityViewController: UIActivityViewController,
    itemForActivityType activityType: UIActivity.ActivityType?
  ) -> Any? {
    return text
  }

  func activityViewController(
    _ activityViewController: UIActivityViewController,
    subjectForActivityType activityType: UIActivity.ActivityType?
  ) -> String {
    return subject ?? ""
  }

  func activityViewControllerLinkMetadata(
    _ activityViewController: UIActivityViewController
  ) -> LPLinkMetadata? {
    let metadata = LPLinkMetadata()
    metadata.title = (subject?.isEmpty == false) ? subject : text
    if let icon = icon {
      metadata.iconProvider = NSItemProvider(object: icon)
    }
    return metadata
  }
}
