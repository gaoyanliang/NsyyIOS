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
    
    var nsyyNotification: NsyyNotification = NsyyNotification()
    var bluetooth: NsyyBluetooth = NsyyBluetooth()
  
    init(port: Int) {
        self.port = port

        app = Application(.development)
        app.http.server.configuration.hostname = "0.0.0.0"
        app.http.server.configuration.port = port
        app.routes.defaultMaxBodySize = "1000kb"
        
        let corsConfiguration = CORSMiddleware.Configuration(
            allowedOrigin: .all,
            allowedMethods: [.GET, .POST, .PUT, .OPTIONS, .DELETE, .PATCH],
            allowedHeaders: [.accept, .authorization, .contentType, .origin, .xRequestedWith, .userAgent, .accessControlAllowOrigin]
        )
        let cors = CORSMiddleware(configuration: corsConfiguration)
        // cors middleware should come before default error middleware using `at: .beginning`
        app.middleware.use(cors, at: .beginning)
    }
    
    func start() {
      Task(priority: .background) {
          do {
              try routes(app)
              try nsyyNotification.routes_notification(app)
              try SignificantLocationManager.sharedManager.routes_location(app)
              try bluetooth.routes_bluetooth(app)
              try NsyyConfig().routes_config(app)
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
    }

}
