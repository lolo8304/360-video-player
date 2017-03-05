//
//  SecondScreenServer.swift
//  SecondScreenFeature
//
//  Created by Lorenz Hänggi on 25.12.16.
//  Copyright © 2016 lolo. All rights reserved.
//

import Foundation
import PocketSocket
import CocoaAsyncSocket

class SecondScreenServer : NSObject {
    
    var urlString: String?
    var port: Int
    var socketServer: PSWebSocketServer?
    var gcdSocket: GCDAsyncSocket?
    var bonjourService: NetService?
    
    
    public init(port: Int) {
        self.port = port
        self.urlString = "none"
    }
        func endPoint() -> String {
        return self.urlString!
    }
    func start(delegate: PSWebSocketServerDelegate, udpDelegate: GCDAsyncSocketDelegate, bonjourDelegate: NetServiceDelegate) {
        let endPoint: String? = InterfaceBuilder.instance.getWiFiAddress()
        if (endPoint != nil) {
            let hostname: String = endPoint!
            self.stop()
            self.socketServer = PSWebSocketServer.init(host: hostname, port: UInt(self.port))
            self.socketServer?.delegate = delegate
            self.socketServer?.start()
            self.urlString = "ws://\(hostname):\(self.port)"

            self.gcdSocket = GCDAsyncSocket(delegate: udpDelegate, delegateQueue: DispatchQueue.main)
            var localPort: UInt16 = 0
            do {
                try self.gcdSocket?.accept(onPort: localPort)
                localPort = (self.gcdSocket?.localPort)!
                self.bonjourService = NetService(domain: "local.", type: "_ws._tcp.", name: self.urlString!, port: Int32(localPort))
                self.bonjourService?.delegate = bonjourDelegate
                self.bonjourService?.publish()
            } catch {
                self.stop()
            }
        }
    }
    func stop() {
        if (self.socketServer != nil) {
            do {
                self.socketServer?.stop()
            } catch {
                NSLog("error orrured while stopping server ")
            }
            self.socketServer = nil
        }
        if (self.gcdSocket != nil) {
            self.gcdSocket?.disconnect()
            self.gcdSocket = nil
        }
        if (self.bonjourService != nil) {
            self.bonjourService?.stop()
            self.bonjourService = nil
        }
    }
    
    
}

