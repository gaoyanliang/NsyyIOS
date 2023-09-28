//
//  WebServer.swift
//  NsyyIOS
//
//  Created by yanliang gao on 2023/9/26.
//

import Vapor

class NsyyWebServer: ObservableObject {

    var app: Application
    let port: Int
    
    var nsyyLocation: NsyyLocation
    var nsyyNotification: NsyyNotification
  
    init(port: Int) {
        self.port = port

        app = Application(.development)
        app.http.server.configuration.hostname = "0.0.0.0"
        app.http.server.configuration.port = port
        app.routes.defaultMaxBodySize = "500kb"
        
        nsyyLocation = NsyyLocation()
        nsyyNotification = NsyyNotification()
    }
    
    func start() {
      Task(priority: .background) {
          do {
              try routes(app)
              try nsyyNotification.routes_notification(app)
              try nsyyLocation.routes_location(app)
              try app.start()
          } catch {
              fatalError(error.localizedDescription)
          }
        }
    }
    
    func routes(_ app: Application) throws {
        app.get("ping") { req async -> ReturnData in
            return ReturnData(isSuccess: true, code: 200, errorMsg: "nil", data: "SERVER OK")
        }
        
        app.get("hello", ":name") { req async throws -> String in
            let name = try req.parameters.require("name")
            return "Hello, \(name.capitalized)!"
        }
    }

}
