import Foundation

struct AppConfiguration {
  let clientToken: String
  let rumApplicationID: String
  
  init?(bundle: Bundle = .main) {
    guard
      let clientToken = bundle.infoDictionary?["DatadogClientToken"] as? String, !clientToken.isEmpty,
      let rumApplicationID = bundle.infoDictionary?["DatadogRUMApplicationID"] as? String, !rumApplicationID.isEmpty
    else {
      return nil
    }
    
    self.init(clientToken: clientToken, rumApplicationID: rumApplicationID)
  }
  
  private init (clientToken: String, rumApplicationID: String) {
    self.clientToken = clientToken
    self.rumApplicationID = rumApplicationID
  }
}
