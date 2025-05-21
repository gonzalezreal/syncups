import DatadogCore
import DatadogInternal
import DatadogRUM
import DatadogSessionReplay
import Dependencies
import IdentifiedCollections
import Sharing
import SwiftUI

@main
struct SyncUpsApp: App {
  static let model = AppModel()

  init() {
    setUpDatadog()
    setUpForUITest()
  }

  var body: some Scene {
    WindowGroup {
      AppView(model: Self.model)
    }
  }
}

private func setUpDatadog() {
  guard let appConfiguration = AppConfiguration() else {
    reportIssue("Couldn't find app configuration. Make sure it is specified in `SyncUps.local.xcconfig`.")
    return
  }
  
  var configuration = Datadog.Configuration(
    clientToken: appConfiguration.clientToken,
    env: "prod",
    batchSize: .small,
    uploadFrequency: .frequent,
    backgroundTasksEnabled: true
  )
  
  configuration._internal_mutation {
    $0.additionalConfiguration[CrossPlatformAttributes.sdkVersion] = "2.27.0+4e28d23"
  }
  
  Datadog.initialize(
    with: .init(
      clientToken: appConfiguration.clientToken,
      env: "prod",
      batchSize: .small,
      uploadFrequency: .frequent,
      backgroundTasksEnabled: true
    ),
    trackingConsent: .granted
  )
  
  RUM.enable(
    with: .init(
      applicationID: appConfiguration.rumApplicationID,
      swiftUIViewsPredicate: DefaultSwiftUIRUMViewsPredicate()
    )
  )
  
  SessionReplay.enable(
    with: .init(
      textAndInputPrivacyLevel: .maskSensitiveInputs,
      imagePrivacyLevel: .maskNonBundledOnly,
      touchPrivacyLevel: .show,
      featureFlags: [.swiftui: true]
    )
  )
}

//// NB: During UI tests we override certain dependencies for the app and seed initial state.
private func setUpForUITest() {
  guard let testName = ProcessInfo.processInfo.environment["UI_TEST_NAME"]
  else {
    return
  }

  // Set up dependencies for UI testing.
  prepareDependencies {
    $0.continuousClock = ContinuousClock()
    $0.defaultFileStorage = .inMemory
    $0.soundEffectClient = .noop
    $0.uuid = UUIDGenerator { UUID() }
    switch testName {
    case "testAdd", "testDelete", "testEdit":
      break
    case "testRecord", "testRecord_Discard":
      $0.date = DateGenerator { Date(timeIntervalSince1970: 1_234_567_890) }
      $0.speechClient.authorizationStatus = { .authorized }
      $0.speechClient.startTask = { @Sendable _ in
        AsyncThrowingStream {
          $0.yield(
            SpeechRecognitionResult(
              bestTranscription: Transcription(formattedString: "Hello world!"),
              isFinal: true
            )
          )
          $0.finish()
        }
      }
    default:
      reportIssue("Unrecognized test: \(testName)")
    }
  }

  // Seed certain test cases with specific state.
  switch testName {
  case "testDelete", "testEdit", "testRecord", "testRecord_Discard":
    @Shared(.syncUps) var syncUps = [.mock]
  default:
    break
  }
}
