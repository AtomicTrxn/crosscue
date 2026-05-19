import Flutter
import Foundation

/// Method-channel handler for the iCloud Documents transport.
///
/// Mirrors the API surface in `lib/core/sync/transport/sync_transport.dart`.
/// All access to the ubiquity container is wrapped in `NSFileCoordinator` so
/// concurrent writes from another device on the same iCloud account don't
/// corrupt files. When no ubiquity identity token is present (user not
/// signed into iCloud, iCloud Drive off for the app, or entitlement not
/// configured), every method returns nil/empty — the Dart side surfaces
/// that as `SyncSignedOut` to the orchestrator.
///
/// See `docs/architecture/sync-icloud-setup.md` for the one-time Xcode
/// setup required before this handler can do any real work.
final class ICloudSyncHandler {
  static let channelName = "crosscue.sync.icloud"

  /// Subdirectory under `<container>/Documents` where all sync blobs live.
  /// Keeping everything under one folder lets us nuke the cloud copy with a
  /// single directory remove on "Delete cloud data."
  static let rootFolderName = "sync"

  static func register(with messenger: FlutterBinaryMessenger) {
    let channel = FlutterMethodChannel(
      name: channelName,
      binaryMessenger: messenger
    )
    let handler = ICloudSyncHandler()
    channel.setMethodCallHandler { call, result in
      handler.handle(call: call, result: result)
    }
  }

  private let coordinator = NSFileCoordinator(filePresenter: nil)
  private let fileManager = FileManager.default

  // MARK: - Method dispatch

  func handle(call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "account":
      result(account())
    case "list":
      guard let prefix = stringArg(call, "prefix") else {
        result(invalidArgs); return
      }
      result(list(prefix: prefix))
    case "read":
      guard let key = stringArg(call, "key") else {
        result(invalidArgs); return
      }
      result(read(key: key))
    case "write":
      guard let key = stringArg(call, "key"),
            let bytes = stringArg(call, "bytes") else {
        result(invalidArgs); return
      }
      result(write(key: key, bytes: bytes))
    case "delete":
      guard let key = stringArg(call, "key") else {
        result(invalidArgs); return
      }
      delete(key: key)
      result(nil)
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  // MARK: - Container access

  /// Returns the `<ubiquity>/Documents/sync/` URL, creating it if needed.
  /// Nil when the user hasn't authorised iCloud Drive for this app.
  private func containerRoot() -> URL? {
    guard fileManager.ubiquityIdentityToken != nil,
          let containerURL = fileManager.url(
            forUbiquityContainerIdentifier: nil
          )
    else { return nil }

    let root = containerURL
      .appendingPathComponent("Documents", isDirectory: true)
      .appendingPathComponent(Self.rootFolderName, isDirectory: true)
    try? fileManager.createDirectory(
      at: root,
      withIntermediateDirectories: true
    )
    return root
  }

  private func fileURL(for key: String) -> URL? {
    containerRoot()?.appendingPathComponent(key)
  }

  // MARK: - Account

  func account() -> [String: Any?]? {
    guard fileManager.ubiquityIdentityToken != nil else { return nil }
    // iCloud doesn't expose a user-visible identifier here; the token is a
    // private NSData. We surface a stable-but-opaque label.
    return [
      "displayName": "iCloud",
      "id": nil as String? as Any,
    ]
  }

  // MARK: - List

  func list(prefix: String) -> [String] {
    guard let root = containerRoot() else { return [] }
    let prefixDir = root.appendingPathComponent(prefix, isDirectory: true)

    var keys: [String] = []
    var coordError: NSError?
    coordinator.coordinate(
      readingItemAt: prefixDir,
      options: .immediatelyAvailableMetadataOnly,
      error: &coordError
    ) { dir in
      guard let entries = try? fileManager.contentsOfDirectory(
        at: dir,
        includingPropertiesForKeys: nil,
        options: [.skipsHiddenFiles]
      ) else { return }
      keys = entries.map { url in
        // Return key relative to root: `<prefix><filename>`.
        url.path.replacingOccurrences(of: root.path + "/", with: "")
      }
    }
    return keys
  }

  // MARK: - Read

  func read(key: String) -> String? {
    guard let url = fileURL(for: key) else { return nil }

    var bytes: String?
    var coordError: NSError?
    coordinator.coordinate(
      readingItemAt: url,
      options: [],
      error: &coordError
    ) { coordinatedURL in
      bytes = try? String(contentsOf: coordinatedURL, encoding: .utf8)
    }
    return bytes
  }

  // MARK: - Write

  func write(key: String, bytes: String) -> String? {
    guard let url = fileURL(for: key) else { return nil }

    // Ensure intermediate dirs exist (e.g. `sync/puzzles/`).
    try? fileManager.createDirectory(
      at: url.deletingLastPathComponent(),
      withIntermediateDirectories: true
    )

    var coordError: NSError?
    coordinator.coordinate(
      writingItemAt: url,
      options: .forReplacing,
      error: &coordError
    ) { coordinatedURL in
      try? bytes.write(to: coordinatedURL, atomically: true, encoding: .utf8)
    }
    // No ETag concept on a plain ubiquity-container file.
    return nil
  }

  // MARK: - Delete

  func delete(key: String) {
    guard let url = fileURL(for: key) else { return }

    var coordError: NSError?
    coordinator.coordinate(
      writingItemAt: url,
      options: .forDeleting,
      error: &coordError
    ) { coordinatedURL in
      try? fileManager.removeItem(at: coordinatedURL)
    }
  }

  // MARK: - Helpers

  private func stringArg(_ call: FlutterMethodCall, _ key: String) -> String? {
    (call.arguments as? [String: Any])?[key] as? String
  }

  private var invalidArgs: FlutterError {
    FlutterError(
      code: "INVALID_ARGS",
      message: "Missing or wrong-typed argument",
      details: nil
    )
  }
}
