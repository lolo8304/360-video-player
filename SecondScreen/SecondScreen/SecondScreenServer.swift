//
//  SecondScreenServer.swift
//  SecondScreenFeature
//
//  Created by Lorenz Hänggi on 25.12.16.
//  Copyright © 2016 lolo. All rights reserved.
//

import Foundation

class SecondScreenServer : NSObject {
    
    var url: URL?
    let port: Int!
    var socketServer: PSWebSocketServer?
    var gcdSocket: GCDAsyncSocket?
    var bonjourService: NetService?
    
    public init(port: Int) {
        self.port = port
    }
    
    // Return IP address of WiFi interface (en0) as a String, or `nil`
    func getWiFiAddress() -> String? {
        var address : String?
        
        // Get list of all interfaces on the local machine:
        var ifaddr : UnsafeMutablePointer<ifaddrs>?
        guard getifaddrs(&ifaddr) == 0 else { return nil }
        guard let firstAddr = ifaddr else { return nil }
        
        // For each interface ...
        for ifptr in sequence(first: firstAddr, next: { $0.pointee.ifa_next }) {
            let interface = ifptr.pointee
            
            // Check for IPv4 or IPv6 interface:
            let addrFamily = interface.ifa_addr.pointee.sa_family
            if addrFamily == UInt8(AF_INET) || addrFamily == UInt8(AF_INET6) {
                
                // Check interface name:
                let name = String(cString: interface.ifa_name)
                if  name == "en0" {
                    
                    // Convert interface address to a human readable string:
                    var addr = interface.ifa_addr.pointee
                    var hostname = [CChar](repeating: 0, count: Int(NI_MAXHOST))
                    getnameinfo(&addr, socklen_t(interface.ifa_addr.pointee.sa_len),
                                &hostname, socklen_t(hostname.count),
                                nil, socklen_t(0), NI_NUMERICHOST)
                    address = String(cString: hostname)
                }
            }
        }
        freeifaddrs(ifaddr)
        
        return address
    }
    func endPoint() -> URL {
        let inetAddress: String = self.getWiFiAddress()!
        let urlString: String = "ws://\(inetAddress):\(self.port!)"
        let url: URL = URL(string: urlString)!
        return url
    }
    func start(delegate: PSWebSocketServerDelegate, udpDelegate: GCDAsyncSocketDelegate, bonjourDelegate: NetServiceDelegate) {
        self.stop()
        self.socketServer = PSWebSocketServer.init(host: self.getWiFiAddress(), port: 12345)
        self.socketServer?.delegate = delegate
        self.socketServer?.start()
        
        self.gcdSocket = GCDAsyncSocket(delegate: udpDelegate, delegateQueue: DispatchQueue.main)
        var port: UInt16 = 0
        do {
            try self.gcdSocket?.accept(onPort: port)
            port = (self.gcdSocket?.localPort)!
            self.bonjourService = NetService(domain: "local.", type: "_ws._tcp.", name: "ws://\(self.getWiFiAddress()!):12345", port: Int32(port))
            self.bonjourService?.delegate = bonjourDelegate
            self.bonjourService?.publish()
        } catch {
            self.stop()
        }
    }
    func stop() {
        if (self.socketServer != nil) {
            self.socketServer?.stop()
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

