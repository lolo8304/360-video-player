//
//  Connector.swift
//  SecondScreen
//
//  Created by Lorenz Hänggi on 28.12.16.
//  Copyright © 2016 Lorenz Hänggi. All rights reserved.
//

import Foundation


class Connector: NSObject {
    
    static let instance: Connector = {
        return Connector()
    }()
    
    private var socketServer: SecondScreenServer?
    
    private override init() {
    }
    
    
    func startServer() {
        if (self.isStarted()) { return }
        self.socketServer = SecondScreenServer(port: 6577)
        self.socketServer?.start(delegate: self, udpDelegate: self, bonjourDelegate: self)
    }
    func stopServer() {
        if (self.isStopped()) { return }
        self.socketServer?.stop()
        self.socketServer = nil
    }
    func isStarted() -> Bool {
        return (self.socketServer != nil && self.socketServer!.isStarted())
    }
    func isStopped() -> Bool {
        return !isStarted()
    }
    func endPoint() -> String {
        return self.isStarted() ? self.socketServer!.endPoint() : "none"
    }
    
    
    public func appendLog(_ message: String) {
        NSLog("message arrived: \(message)")
    }
    public func showError(_ message: String, stack: Bool) {
        if (stack) {
            NSLog("error message \(message): see stack")
            for symbol: String in Thread.callStackSymbols {
                NSLog("%@", symbol)
            }
        } else {
            NSLog("error message \(message)")
        }
    }

}

extension Connector : PSWebSocketServerDelegate {
    
    func server(_ server: PSWebSocketServer!, webSocket: PSWebSocket!, didReceiveMessage message: Any!) {
        self.appendLog(message as! String)
    }
    
    
    func serverDidStop(_ server: PSWebSocketServer!) {
    }
    func serverDidStart(_ server: PSWebSocketServer!) {
    }
    func server(_ server: PSWebSocketServer!, didFailWithError error: Error!) {
        self.showError("webSocket didFailWithError \(error!)", stack: true)
    }
    func server(_ server: PSWebSocketServer!, webSocketDidOpen webSocket: PSWebSocket!) {
    }
    func server(_ server: PSWebSocketServer!, webSocketDidFlushInput webSocket: PSWebSocket!) {
    }
    func server(_ server: PSWebSocketServer!, webSocketDidFlushOutput webSocket: PSWebSocket!) {
    }
    func server(_ server: PSWebSocketServer!, acceptWebSocketWith request: URLRequest!) -> Bool {
        return true
    }
    func server(_ server: PSWebSocketServer!, webSocket: PSWebSocket!, didFailWithError error: Error!) {
        self.showError("webSocket didFailWithError \(error!)", stack: true)
    }
    func server(_ server: PSWebSocketServer!, webSocket: PSWebSocket!, didCloseWithCode code: Int, reason: String!, wasClean: Bool) {
        self.showError("didCloseWithCode code=\(code), reason=\(reason)", stack: true)
    }
    func server(_ server: PSWebSocketServer!, acceptWebSocketWith request: URLRequest!, address: Data!, trust: SecTrust!, response: AutoreleasingUnsafeMutablePointer<HTTPURLResponse?>!) -> Bool {
        return true
    }
}


extension Connector : GCDAsyncSocketDelegate {
    func socket(_ sock: GCDAsyncSocket, didAcceptNewSocket newSocket: GCDAsyncSocket) {
        
    }
    func socketDidDisconnect(_ sock: GCDAsyncSocket, withError err: Error?) {
        
    }
}
extension Connector : NetServiceDelegate {
    func netServiceDidPublish(_ sender: NetService) {
        NSLog("Bonjour Service Published: domain(\(sender.domain)) type(\(sender.type)) name(\(sender.name)) host(\(sender.hostName)) port(\(sender.port))");
    }
    func netService(_ sender: NetService, didNotPublish errorDict: [String : NSNumber]) {
        NSLog("Failed to Publish: domain(\(sender.domain)) type(\(sender.type)) name(\(sender.name)) host(\(sender.hostName)) port(\(sender.port))");
        
    }
    func netServiceDidResolveAddress(_ sender: NetService) {
        NSLog("Bonjour Service Did Resolved Address: domain(\(sender.domain)) type(\(sender.type)) name(\(sender.name)) host(\(sender.hostName)) port(\(sender.port))");
    }

}
