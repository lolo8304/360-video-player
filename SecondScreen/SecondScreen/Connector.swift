//
//  Connector.swift
//  SecondScreen
//
//  Created by Lorenz Hänggi on 28.12.16.
//  Copyright © 2016 Lorenz Hänggi. All rights reserved.
//

import Foundation

protocol ConnectorDelegate {
    func serverDidStart()
    func serverDidStop()
    func device()
    func statusChanged()
}

enum ConnectorStatus {
    case Starting
    case Ready
    case Connected
    case Stopping
    case Stopped
}
enum ConnectorBonjourStatus {
    case Starting
    case Ready
    case Stopping
    case Stopped
}

class Connector: NSObject {
    
    static let instance: Connector = {
        return Connector()
    }()
    
    private var socketServer: SecondScreenServer?
    private var connectedDevices = [ String : JSON ]()
    public var delegate: ConnectorDelegate?
    public var status: ConnectorStatus = .Stopped
    public var bonjourStatus: ConnectorBonjourStatus = .Stopped
    
    private override init() {
    }
    
    
    // server activities
    func startServer() {
        if (self.isStarted()) { return }
        self.changeState(server: .Starting)
        self.changeState(bonjourServer: .Starting)
        
        self.socketServer = SecondScreenServer(port: 6577)
        self.socketServer?.start(delegate: self, udpDelegate: self, bonjourDelegate: self)
    }
    func stopServer() {
        if (self.isStopped()) { return }
        self.changeState(server: .Starting)
        self.changeState(bonjourServer: .Stopping)
        
        self.socketServer?.stop()
        self.socketServer = nil
    }
    func isStarted() -> Bool {
        return (self.status == .Ready || self.status == .Connected) && (self.bonjourStatus == .Ready)
    }
    func isStopped() -> Bool {
        return (self.status == .Stopped) && (self.bonjourStatus == .Stopped)
    }
    func endPoint() -> String {
        return self.isStarted() ? self.socketServer!.endPoint() : "none"
    }

    // state management
    func changeState(server: ConnectorStatus) {
        self.status = server
        self.delegate?.statusChanged()
        if (self.isStarted()) { self.delegate?.serverDidStart() }
        if (self.isStopped()) { self.delegate?.serverDidStop() }
    }
    func changeState(bonjourServer: ConnectorBonjourStatus) {
        self.bonjourStatus = bonjourServer
        self.delegate?.statusChanged()
        if (self.isStarted()) { self.delegate?.serverDidStart() }
        if (self.isStopped()) { self.delegate?.serverDidStop() }
    }
    func refreshState() {
        if (self.isStarted()) { self.delegate?.serverDidStart() }
        if (self.isStopped()) { self.delegate?.serverDidStop() }
    }

    
    // device management
    
    func addDevice(_ deviceId: JSON) {
        let uuid: String = deviceId["device.uuid"].string!
        NSLog("register device: \(uuid), data=\(deviceId.rawString()!)")
        self.connectedDevices[uuid] = deviceId
        self.status = .Connected
    }

    // logs

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
        self.changeState(server: .Stopped)
    }
    func serverDidStart(_ server: PSWebSocketServer!) {
        self.changeState(server: .Ready)
    }
    func pongResult (pongData: Data?) -> Void {
        let pongDataString: String = pongData!.base64EncodedString()
        NSLog("Pong arrived \(pongDataString)")
    }
    func server(_ server: PSWebSocketServer!, webSocketDidOpen webSocket: PSWebSocket!) {
        let pingData: Data = "hello-from-server".data(using: .utf8)!
        webSocket.ping(pingData, handler: pongResult)
    }
    
    func server(_ server: PSWebSocketServer!, webSocket: PSWebSocket!, didFailWithError error: Error!) {
        //self.showError("webSocket didFailWithError \(error!)", stack: true)
    }
    public func server(_ server: PSWebSocketServer!, didFailWithError error: Error!) {
        //self.showError("webSocket didFailWithError \(error!)", stack: true)
    }
    func server(_ server: PSWebSocketServer!, webSocket: PSWebSocket!, didCloseWithCode code: Int, reason: String!, wasClean: Bool) {
        self.showError("didCloseWithCode code=\(code), reason=\(reason)", stack: false)
    }
    func server(_ server: PSWebSocketServer!, acceptWebSocketWith request: URLRequest!, address: Data!, trust: SecTrust!, response: AutoreleasingUnsafeMutablePointer<HTTPURLResponse?>!) -> Bool {
        
        if (PSWebSocket.isWebSocketRequest(request)) {
            let headers: [String : String] = request.allHTTPHeaderFields!
            let deviceId: JSON = self.getDeviceId(headers: headers)
            self.addDevice(deviceId)
            return true
        } else {
            return false
        }
    }
    private func getDeviceId(headers: [String : String]) -> JSON {
        var deviceName: String = "none"
        var deviceIp: String = "0.0.0.0"
        var deviceUUID: String = ""
        for (key, value) in headers {
            if (key == "device.name") { deviceName = value }
            if (key == "device.ip") { deviceIp = value }
            if (key == "Sec-WebSocket-Key") { deviceUUID = value }
        }
        return JSON.init(["device.name": deviceName, "device.ip": deviceIp, "device.uuid": deviceUUID])
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
        self.changeState(bonjourServer: .Ready)
    }
    func netService(_ sender: NetService, didNotPublish errorDict: [String : NSNumber]) {
        NSLog("Failed to Publish: domain(\(sender.domain)) type(\(sender.type)) name(\(sender.name)) host(\(sender.hostName)) port(\(sender.port))");
        
    }
    func netServiceDidResolveAddress(_ sender: NetService) {
        NSLog("Bonjour Service Did Resolved Address: domain(\(sender.domain)) type(\(sender.type)) name(\(sender.name)) host(\(sender.hostName)) port(\(sender.port))");
    }
    func netServiceDidStop(_ sender: NetService) {
        self.changeState(bonjourServer: .Stopped)
    }

}


extension String {
    func fromBase64() -> String? {
        guard let data = Data(base64Encoded: self) else {
            return nil
        }
        
        return String(data: data, encoding: .utf8)
    }
    
    func toBase64() -> String {
        return Data(self.utf8).base64EncodedString()
    }
}
