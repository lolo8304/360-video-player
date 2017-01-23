//
//  SecondScreenServer.swift
//  SecondScreenFeature
//
//  Created by Lorenz Hänggi on 25.12.16.
//  Copyright © 2016 lolo. All rights reserved.
//

import Foundation

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
            // Check interface name:
            let name = String(cString: interface.ifa_name)
            NSLog("IF \(name)");
            
            if  (name.hasPrefix("en") || name.hasPrefix("bridge")) {
                // Check for IPv4 or IPv6 interface:
                let addrFamily = interface.ifa_addr.pointee.sa_family
                if addrFamily == UInt8(AF_INET) || addrFamily == UInt8(AF_INET6) {
                    // Convert interface address to a human readable string:
                    var addr = interface.ifa_addr.pointee
                    var hostname = [CChar](repeating: 0, count: Int(NI_MAXHOST))
                    getnameinfo(&addr, socklen_t(interface.ifa_addr.pointee.sa_len),
                                &hostname, socklen_t(hostname.count),
                                nil, socklen_t(0), NI_NUMERICHOST)
                    let tempAddress = String(cString: hostname)
                    if (!tempAddress.isEmpty) {
                        address = tempAddress
                        NSLog("IF \(name) = \(address!)");
                    }
                }
            }
        }
        freeifaddrs(ifaddr)
        
        return address
    }
    func endPoint() -> String {
        return self.urlString!
    }
    func start(delegate: PSWebSocketServerDelegate, udpDelegate: GCDAsyncSocketDelegate, bonjourDelegate: NetServiceDelegate) {
        let endPoint: String? = self.getWiFiAddress()
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
                try
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

