//
//  Connector.swift
//  SecondScreen
//
//  Created by Lorenz Hänggi on 28.12.16.
//  Copyright © 2016 Lorenz Hänggi. All rights reserved.
//

import Foundation

protocol ConnectorDelegate {
    func device()
    func statusChanged(started: Bool, server:ConnectorStatus, bonjourServer: ConnectorBonjourStatus, connections: Int)
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

enum DeviceStatus {
    case closed
    case accepted
    case connected
    case selected
}


class Device: NSObject {
    
    private static var maxId: Int = 0
    
    public var id: Int
    public var connector: Connector
    public var uuid: String
    public var ip: String
    public var name: String
    public var webSocket: PSWebSocket? = nil
    public var status: DeviceStatus = .closed
    public var pinged: Bool = false
    public var ponged: Bool = false

    public static func create(connector: Connector, uuid: String, ip: String, name: String) -> Device {
        let device: Device = Device(connector: connector, uuid: uuid, ip: ip, name: name)
        connector.add(device: device)
        return device
    }
    public static func create(connector: Connector, json: JSON) -> Device {
        let device: Device = Device(connector: connector, json: json)
        connector.add(device: device)
        return device
    }
    private init(connector: Connector, uuid: String, ip: String, name: String) {
        Device.maxId = Device.maxId + 1
        self.id = Device.maxId
        self.connector = connector
        self.uuid = uuid
        self.ip = ip
        self.name = name
    }
    private init(connector: Connector, json: JSON) {
        Device.maxId = Device.maxId + 1
        self.id = Device.maxId
        self.connector = connector
        self.uuid = json["device.uuid"].string!
        self.ip = json["device.ip"].string!
        self.name = json["device.name"].string!
    }
    public func connect() {
        self.connector.add(device: self)
    }
    public func connect(webSocket: PSWebSocket) {
        if (self.isConnected()) {
            self.disconnect()
        }
        self.webSocket = webSocket
        self.connect()
        self.status = .connected
    }
    public func disconnect() {
        self.connector.remove(device: self)
    }
    
    public func isConnected() -> Bool {
        return self.webSocket != nil
    }
    public func getConnection() -> PSWebSocket {
        return self.webSocket!
    }
    
    public func play() {
        CurrentQuaternion.instance().play()
    }
    public func stop() {
        CurrentQuaternion.instance().stop()
    }
    
    public func toJSON() -> JSON {
        return JSON.init(["name": self.name, "ip": self.ip, "uuid": self.uuid, "status" : "\(self.status)"])
    }
    public func toString() -> String {
        let json: JSON = self.toJSON()
        let jsonString: String? = json.rawString(.utf8, options: .prettyPrinted)
        return jsonString!
    }
    
}

class Connector: NSObject {
    
    static let instance: Connector = {
        return Connector()
    }()
    
    private var socketServer: SecondScreenServer?
    private var connectedDevices = [ String : Device ]()
    private var connectedDevicesByWebSocket = [ PSWebSocket : Device ]()
    public var connectedDevice: Device?
    
    public var delegate: ConnectorDelegate?
    public var status: ConnectorStatus = .Stopped
    public var bonjourStatus: ConnectorBonjourStatus = .Stopped
    var timer = Timer()
    
    private override init() {
        
    }
    
    // timer functions
    
    fileprivate func startTimer() {
        let aSelector : Selector = #selector(Connector.validateDevices)
        timer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: aSelector, userInfo: nil, repeats: true)
    }
    fileprivate func stopTimer() {
        timer.invalidate()
    }
    
    /*
    func pongResult (pongData: Data?) -> Void {
        let pongDataString: String = pongData!.base64EncodedString()
        NSLog("Pong arrived \(pongDataString)")
    }
     webSocket.ping(pingData, handler: pongResult)

    */

    public func validateDevices() {
        if (self.connectedDevicesByWebSocket.count == 0) { return }
        var allNonValidDevices = [PSWebSocket : Device]()
        var allValidDevices = [PSWebSocket : Device]()
        for (key, value) in (self.connectedDevicesByWebSocket) {
            if (value.pinged && value.ponged) {
                //NSLog("validation: valid device \(value.ip)")
                allValidDevices[key] = value
                value.pinged = false
                value.ponged = false
            } else if (value.pinged && !value.ponged) {
                allNonValidDevices[key] = value
            } else {
                let pingData: Data = "hello-from-server".data(using: .utf8)!
                value.pinged = true
                key.ping(pingData, handler: { (pongData) in
                    value.ponged = true
                })
            }
        }
        if (!allNonValidDevices.isEmpty) {
            NSLog("validate all \(self.connectedDevicesByWebSocket.count) devices")
            for (_, value) in allNonValidDevices {
                NSLog("validation: non valid device \(value.ip)")
                value.disconnect()
            }
        }
    }
    
    
    
    // server activities
    public func startServer() {
        if (self.isStarted()) { return }
        self.changeState(server: .Starting)
        self.changeState(bonjourServer: .Starting)
        
        self.socketServer = SecondScreenServer(port: 6577)
        self.socketServer?.start(delegate: self, udpDelegate: self, bonjourDelegate: self)
    }
    public func stopServer() {
        if (self.isStopped()) { return }
        self.changeState(server: .Stopping)
        self.changeState(bonjourServer: .Stopping)
        
        self.socketServer?.stop()
        self.socketServer = nil
    }
    public func isStarted() -> Bool {
        return (self.status == .Ready || self.status == .Connected) && (self.bonjourStatus == .Ready)
    }
    public func isStopped() -> Bool {
        return (self.status == .Stopped) && (self.bonjourStatus == .Stopped)
    }
    public func endPoint() -> String {
        return self.isStarted() ? self.socketServer!.endPoint() : "none"
    }

    private func statusChanged() {
        self.delegate?.statusChanged(started: self.isStarted(), server: self.status, bonjourServer: self.bonjourStatus, connections: self.connectedDevices.count)
    }
    // state management
    func changeState(server: ConnectorStatus) {
        self.status = server
        self.statusChanged()
    }
    func changeState(bonjourServer: ConnectorBonjourStatus) {
        self.bonjourStatus = bonjourServer
        self.statusChanged()
    }
    func refreshState() {
        self.statusChanged()
    }

    
    // device management

    public func add(device: Device) {
        let ip: String = device.ip
        NSLog("register device: \(ip), data=\(device.toString())")
        self.connectedDevices[ip] = device
        if (device.isConnected()) {
            self.connectedDevicesByWebSocket[device.webSocket!] =  device
            NSLog("register websocket of device: \(ip), data=\(device.toString())")
            self.status = .Connected
            self.statusChanged()
            self.connectedDevice = device
        }
    }

    public func add(json: JSON) {
        self.add(device: Device.create(connector: self, json: json))
    }
    public func remove(device: Device) {
        self.connectedDevices.removeValue(forKey: device.ip)
        if (device.isConnected()) {
            self.connectedDevicesByWebSocket.removeValue(forKey: device.webSocket!)
            NSLog("remove connected device: \(device.ip), data=\(device.toString())")
            if (self.connectedDevicesByWebSocket.count == 0) {
                self.status = .Ready
            }
            self.statusChanged()
        }
    }
    
    public func get(deviceIp: String) -> Device? {
        return self.connectedDevices[deviceIp]
    }
    public func get(webSocket: PSWebSocket) -> Device? {
        return self.connectedDevicesByWebSocket[webSocket]
    }
    
    public func choose(device: Device) {
        self.connectedDevice = device
    }
    public func choose(id: Int) {
        for (_, value) in self.connectedDevices {
            if (value.id == id) {
                self.connectedDevice = value
                return
            }
        }
        self.connectedDevice = nil
    }
    
    public func sortedDevicesById() -> [Device] {
        var list: [Device] = [Device]();
        for (_, value) in self.connectedDevices {
            list.append(value)
        }
        list.sort {
            $0.id < $1.id
        }
        return list
    }
    
    public func play() {
        self.connectedDevice?.play()
    }

    // logs

     func appendLog(_ message: String) {
        NSLog("message arrived: \(message)")
    }
     func showError(_ message: String, stack: Bool) {
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
        self.server(server, webSocket: webSocket, didReceive: message as! String)
    }
    func server(_ server: PSWebSocketServer!, webSocket: PSWebSocket!, didReceive message: String!) {
        let device: Device? = self.get(webSocket: webSocket)
        if (device != nil) {
            device!.pinged = true
            device!.ponged = true
            let json:JSON = JSON.init(data: message.data(using: .utf8, allowLossyConversion: false)!)
            if (json["action"].stringValue == "position") {
                
                CurrentQuaternion.instance().enqueue(json["X"].floatValue, add: json["Y"].floatValue, add: json["Z"].floatValue, add: json["W"].floatValue)
                //{"action":"position", "X":0.21428485, "Y":-0.32440406, "Z":-0.71701926, "W":-0.5779501}
                //NSLog("queue size = \(CurrentQuaternion.instance().count())");
            }
            
        } else {
            let json: JSON = JSON.init(data: message.data(using: .utf8)!)
            if (json["action"].stringValue == "request-connection-data") {
                // retrieve IP, name of device to map it with device-object and websocket
                let device: Device? = self.get(deviceIp: json["ip"].stringValue)
                if (device != nil) {
                    device!.connect(webSocket: webSocket)
                }
            }
        }
    }
    
    func serverDidStop(_ server: PSWebSocketServer!) {
        self.changeState(server: .Stopped)
        self.stopTimer()
    }
    func serverDidStart(_ server: PSWebSocketServer!) {
        self.changeState(server: .Ready)
        self.startTimer()
    }
    func server(_ server: PSWebSocketServer!, webSocketDidOpen webSocket: PSWebSocket!) {
        let acknowledgeRequest = JSON.init(["action": "request-connection-data", "device.ip": "", "device.uuid": ""])
        webSocket.send(acknowledgeRequest.rawString())
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
            let device: Device = Device.create(connector: self, json: deviceId)
            device.status = .accepted
            return true
        } else {
            return false
        }
    }
    fileprivate func getDeviceId(headers: [String : String]) -> JSON {
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
