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
/// Error contract (iOS 16+ async/throws; see #113): a *missing* blob is
/// reported as nil/empty, while an *access* failure (coordination conflict,
/// quota, permission, generic I/O) is thrown back to Dart as a `FlutterError`
/// with a structured `ICLOUD_*` code so the orchestrator never mistakes a
/// locked file for a missing one.
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

  private let fileManager = FileManager.default

  // MARK: - Method dispatch

  func handle(call: FlutterMethodCall, result: @escaping FlutterResult) {
    Task {
      let outcome: Result<Any?, Error>
      do {
        outcome = .success(try await dispatch(call: call))
      } catch {
        outcome = .failure(error)
      }
      // FlutterResult must be delivered on the platform (main) thread.
      await MainActor.run {
        switch outcome {
        case .success(let value):
          result(value)
        case .failure(is InvalidArgsError):
          result(Self.invalidArgs)
        case .failure(let error as ICloudSyncError):
          result(error.flutterError)
        case .failure(let error):
          result(ICloudSyncError.classify(error).flutterError)
        }
      }
    }
  }

  private func dispatch(call: FlutterMethodCall) async throws -> Any? {
    switch call.method {
    case "account":
      return account()
    case "list":
      guard let prefix = stringArg(call, "prefix") else { throw InvalidArgsError() }
      return try await list(prefix: prefix)
    case "read":
      guard let key = stringArg(call, "key") else { throw InvalidArgsError() }
      return try await read(key: key)
    case "write":
      guard let key = stringArg(call, "key"),
            let bytes = stringArg(call, "bytes") else { throw InvalidArgsError() }
      return try await write(key: key, bytes: bytes)
    case "delete":
      guard let key = stringArg(call, "key") else { throw InvalidArgsError() }
      try await delete(key: key)
      return nil
    default:
      return FlutterMethodNotImplemented
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

  func list(prefix: String) async throws -> [String] {
    guard let root = containerRoot() else { return [] }
    let prefixDir = root.appendingPathComponent(prefix, isDirectory: true)

    do {
      return try await coordinatedRead(
        at: prefixDir,
        options: .immediatelyAvailableMetadataOnly
      ) { dir in
        let entries = try self.fileManager.contentsOfDirectory(
          at: dir,
          includingPropertiesForKeys: nil,
          options: [.skipsHiddenFiles]
        )
        // Return each key relative to root: `<prefix><filename>`.
        return entries.map { url in
          url.path.replacingOccurrences(of: root.path + "/", with: "")
        }
      }
    } catch {
      // A prefix directory that doesn't exist yet is "empty", not an error.
      if Self.isFileNotFound(error) { return [] }
      throw error
    }
  }

  // MARK: - Read

  func read(key: String) async throws -> String? {
    guard let url = fileURL(for: key) else { return nil }

    do {
      return try await coordinatedRead(at: url) { coordinatedURL in
        try String(contentsOf: coordinatedURL, encoding: .utf8)
      }
    } catch {
      // A missing file is reported as nil (the "we don't have it" signal) —
      // only genuine access failures propagate.
      if Self.isFileNotFound(error) { return nil }
      throw error
    }
  }

  // MARK: - Write

  func write(key: String, bytes: String) async throws -> String? {
    guard let url = fileURL(for: key) else { return nil }

    // Ensure intermediate dirs exist (e.g. `sync/puzzles/`).
    try fileManager.createDirectory(
      at: url.deletingLastPathComponent(),
      withIntermediateDirectories: true
    )

    try await coordinatedWrite(at: url, options: .forReplacing) { coordinatedURL in
      try bytes.write(to: coordinatedURL, atomically: true, encoding: .utf8)
    }
    // No ETag concept on a plain ubiquity-container file.
    return nil
  }

  // MARK: - Delete

  func delete(key: String) async throws {
    guard let url = fileURL(for: key) else { return }

    do {
      try await coordinatedWrite(at: url, options: .forDeleting) { coordinatedURL in
        try self.fileManager.removeItem(at: coordinatedURL)
      }
    } catch {
      // Deleting something already gone is a no-op success.
      if Self.isFileNotFound(error) { return }
      throw error
    }
  }

  // MARK: - File coordination (continuation wrappers)

  /// Runs [body] inside a read coordination. `NSFileCoordinator.coordinate`
  /// is synchronous and blocking, so we hop to a background queue and bridge
  /// back with a checked continuation. A coordination failure (the out-param
  /// error) is surfaced as `ICloudSyncError.locked`; errors thrown by [body]
  /// propagate unchanged for the caller to classify.
  private func coordinatedRead<T>(
    at url: URL,
    options: NSFileCoordinator.ReadingOptions = [],
    _ body: @escaping (URL) throws -> T
  ) async throws -> T {
    try await withCheckedThrowingContinuation { continuation in
      DispatchQueue.global(qos: .userInitiated).async {
        let coordinator = NSFileCoordinator(filePresenter: nil)
        var coordError: NSError?
        var bodyResult: Result<T, Error>?
        coordinator.coordinate(
          readingItemAt: url,
          options: options,
          error: &coordError
        ) { coordinatedURL in
          bodyResult = Result { try body(coordinatedURL) }
        }
        Self.resume(continuation, coordError: coordError, bodyResult: bodyResult)
      }
    }
  }

  private func coordinatedWrite<T>(
    at url: URL,
    options: NSFileCoordinator.WritingOptions = [],
    _ body: @escaping (URL) throws -> T
  ) async throws -> T {
    try await withCheckedThrowingContinuation { continuation in
      DispatchQueue.global(qos: .userInitiated).async {
        let coordinator = NSFileCoordinator(filePresenter: nil)
        var coordError: NSError?
        var bodyResult: Result<T, Error>?
        coordinator.coordinate(
          writingItemAt: url,
          options: options,
          error: &coordError
        ) { coordinatedURL in
          bodyResult = Result { try body(coordinatedURL) }
        }
        Self.resume(continuation, coordError: coordError, bodyResult: bodyResult)
      }
    }
  }

  private static func resume<T>(
    _ continuation: CheckedContinuation<T, Error>,
    coordError: NSError?,
    bodyResult: Result<T, Error>?
  ) {
    if let coordError {
      // Couldn't acquire coordinated access — most often another presenter
      // (device) holds a conflicting claim.
      continuation.resume(
        throwing: ICloudSyncError.locked(coordError.localizedDescription)
      )
    } else if let bodyResult {
      continuation.resume(with: bodyResult)
    } else {
      // Neither the closure ran nor an error was reported — shouldn't happen.
      continuation.resume(
        throwing: ICloudSyncError.locked("File coordination did not execute")
      )
    }
  }

  // MARK: - Helpers

  private func stringArg(_ call: FlutterMethodCall, _ key: String) -> String? {
    (call.arguments as? [String: Any])?[key] as? String
  }

  private static var invalidArgs: FlutterError {
    FlutterError(
      code: "INVALID_ARGS",
      message: "Missing or wrong-typed argument",
      details: nil
    )
  }

  /// True for the Cocoa "no such file" errors, which callers treat as
  /// missing rather than as a failure.
  private static func isFileNotFound(_ error: Error) -> Bool {
    let ns = error as NSError
    return ns.domain == NSCocoaErrorDomain
      && (ns.code == NSFileReadNoSuchFileError || ns.code == NSFileNoSuchFileError)
  }
}

/// Thrown when a required method-channel argument is missing/mistyped.
private struct InvalidArgsError: Error {}

/// Typed iCloud transport failure, mapped to a structured `FlutterError` the
/// Dart side turns into a `SyncTransportException`.
private enum ICloudSyncError: Error {
  case locked(String)
  case quota(String)
  case permission(String)
  case io(String)

  var flutterError: FlutterError {
    switch self {
    case .locked(let m):
      return FlutterError(code: "ICLOUD_LOCKED", message: m, details: nil)
    case .quota(let m):
      return FlutterError(code: "ICLOUD_QUOTA", message: m, details: nil)
    case .permission(let m):
      return FlutterError(code: "ICLOUD_PERMISSION", message: m, details: nil)
    case .io(let m):
      return FlutterError(code: "ICLOUD_IO", message: m, details: nil)
    }
  }

  /// Best-effort classification of an arbitrary error thrown during I/O.
  static func classify(_ error: Error) -> ICloudSyncError {
    if let already = error as? ICloudSyncError { return already }
    let ns = error as NSError
    if ns.domain == NSCocoaErrorDomain {
      switch ns.code {
      case NSFileWriteOutOfSpaceError:
        return .quota(ns.localizedDescription)
      case NSFileReadNoPermissionError, NSFileWriteNoPermissionError:
        return .permission(ns.localizedDescription)
      default:
        break
      }
    }
    return .io(ns.localizedDescription)
  }
}
