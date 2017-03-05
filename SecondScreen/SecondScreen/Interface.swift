//
//  Interface.swift
//  SecondScreen
//
//  Created by Lorenz Hänggi on 05.02.17.
//  Copyright © 2017 Lorenz Hänggi. All rights reserved.
//

import Foundation

public class Interface : NSObject {
    public var name: String
    lazy public var prefix: String = {
        return self.ifPrefix(name: self.name)
    }()
    lazy public var nameDescription: String = {
        return self.isValidIF(name: self.name).first!.value
    }()
    
    public var addrFamily: Int32?
    public var addrFamilyString: String?
    
    public var IPV6: Bool = false
    public var ipAddress: String?
    public var macAddress: String?
    
    init(name: String) {
        self.name = name
    }
    
    private func addrFamilyToString(addrFamily: Int32) -> String {
        switch addrFamily {
        case AF_UNSPEC: return "AF_UNSPEC -  unspecified "
        case AF_UNIX: return "AF_UNIX -  local to host (pipes) "
        case AF_LOCAL: return "AF_LOCAL -  backward compatibility "
        case AF_INET: return "AF_INET -  internetwork"
        case AF_IMPLINK: return "AF_IMPLINK -  arpanet imp addresses "
        case AF_PUP: return "AF_PUP -  pup protocols"
        case AF_CHAOS: return "AF_CHAOS -  mit CHAOS protocols "
        case AF_NS: return "AF_NS -  XEROX NS protocols "
        case AF_ISO: return "AF_ISO -  ISO protocols "
        case AF_ECMA: return "AF_ECMA -  European computer manufacturers "
        case AF_DATAKIT: return "AF_DATAKIT -  datakit protocols "
        case AF_CCITT: return "AF_CCITT -  CCITT protocols, X.25 etc "
        case AF_SNA: return "AF_SNA -  IBM SNA "
        case AF_DECnet: return "AF_DECnet -  DECnet "
        case AF_DLI: return "AF_DLI -  DEC Direct data link interface "
        case AF_LAT: return "AF_LAT -  LAT "
        case AF_HYLINK: return "AF_HYLINK -  NSC Hyperchannel "
        case AF_APPLETALK: return "AF_APPLETALK -  Apple Talk "
        case AF_ROUTE: return "AF_ROUTE -  Internal Routing Protocol "
        case AF_LINK: return "AF_LINK -  Link layer interface "
        case pseudo_AF_XTP: return "pseudo_AF_XTP -  eXpress Transfer Protocol (no AF) "
        case AF_COIP: return "AF_COIP -  connection-oriented IP, aka ST II "
        case AF_CNT: return "AF_CNT -  Computer Network Technology "
        case pseudo_AF_RTIP: return "pseudo_AF_RTIP -  Help Identify RTIP packets "
        case AF_IPX: return "AF_IPX -  Novell Internet Protocol "
        case AF_SIP: return "AF_SIP -  Simple Internet Protocol "
        case pseudo_AF_PIP: return "pseudo_AF_PIP -  Help Identify PIP packets "
        case AF_NDRV: return "AF_NDRV -  Network Driver 'raw' access "
        case AF_ISDN: return "AF_ISDN -  Integrated Services Digital Network "
        case AF_E164: return "AF_E164 -  CCITT E.164 recommendation "
        case pseudo_AF_KEY: return "pseudo_AF_KEY -  Internal key-management function "
        case AF_INET6: return "AF_INET6 -  IPv6 "
        case AF_NATM: return "AF_NATM -  native ATM access "
        case AF_SYSTEM: return "AF_SYSTEM -  Kernel event messages "
        case AF_NETBIOS: return "AF_NETBIOS -  NetBIOS "
        case AF_PPP: return "AF_PPP -  PPP communication protocol "
        case AF_RESERVED_36: return "AF_RESERVED_36 -  Reserved for internal usage "
        case AF_IEEE80211: return "AF_IEEE80211 -  IEEE 802.11 protocol "
        case AF_UTUN: return "AF_UTUN -  UTUN"
        case AF_MAX: return "AF_MAX -  MAX"
        default:
            return "AFcode=\(addrFamily)"
        }
    }
    
    private func ifPrefix(name: String) -> String {
        let prefixes = ["en", "pdp_ip", "ipsec", "bridge", "lo", "utun"];
        for prefix in prefixes {
            if (name.hasPrefix(prefix)) {
                return prefix
            }
        }
        return "unknown - \(name)"
    }

    public func isValidIF(name: String) -> [Bool : String] {
        if (name.hasPrefix("en")) {
            return [true : "ethernet"]
        } else if (name.hasPrefix("pdp_ip")) {
            return [false : "mobile GSGM"]
        } else if (name.hasPrefix("ipsec")) {
            return [false : "Wifi calling"]
        } else if (name.hasPrefix("bridge")) {
            return [true : "bridge"]
        } else if (name.hasPrefix("lo")) {
            return [false : "localhost"]
        } else if (name.hasPrefix("utun")) {
            return [false : "networksetup"]
        } else {
            return [false : "unknown - \(name)"]
        }
    }
    
    public func isValid() -> Bool {
        return !self.IPV6 && (self.isValidIF(name: self.name).first!.key)
    }
    
    private func isAddrFamilyIPx(addrFamily: Int32) -> Bool {
        return addrFamily == AF_INET || addrFamily == AF_INET6
    }
    private func isAddrFamilyIP6(addrFamily: Int32) -> Bool {
        return addrFamily == AF_INET6
    }
    private func isAddrFamilyMacAddress(addrFamily: Int32) -> Bool {
        return addrFamily == AF_LINK
    }
    
    public func updateIF(addrFamily: Int32, address: String) {
        if (self.isAddrFamilyIPx(addrFamily: addrFamily)) {
            self.addrFamily = addrFamily
            self.addrFamilyString = self.addrFamilyToString(addrFamily: addrFamily)
            self.IPV6 = self.isAddrFamilyIP6(addrFamily: addrFamily)
            self.ipAddress = address
            NSLog("IF \(name) IP \(address) family \(addrFamily)=\(addrFamilyString!)");
        } else if self.isAddrFamilyMacAddress(addrFamily: addrFamily) {
            self.macAddress = address
            NSLog("IF \(name) MAC \(address)")
        }
    }

}

public class InterfaceBuilder : NSObject {
    public static let instance: InterfaceBuilder = {
        return InterfaceBuilder().reload()
    }()
    
    public var interfaces = [String : Interface]()
    
    private override init() {
    }

    public func reload() -> InterfaceBuilder {
        self.interfaces = [String : Interface]()
        return self
    }
    
    public func validInterface() -> Interface? {
        for interface in self.interfaces {
            let IF = interface.value
            if (IF.isValid()) {
                NSLog("VALID IF \(IF.name) IP \(IF.ipAddress!) family \(IF.addrFamily!)=\(IF.addrFamilyString!)");
                return interface.value
            }
        }
        return nil
    }
    
    public func getIF(name: String) -> Interface {
        var interface = self.interfaces[name]
        if (interface == nil) {
            interface = Interface(name: name)
        }
        return interface!
    }
    
    // Return IP address of WiFi interface (en0) as a String, or `nil`
    public func getWiFiAddress() -> String? {
        if (self.interfaces.count > 0) {
            return self.validInterface()?.ipAddress
        }
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
            let addrFamily = interface.ifa_addr.pointee.sa_family
            let ifObject: Interface = self.getIF(name: name)
                // Check for IPv4 or IPv6 interface:
                if addrFamily == UInt8(AF_INET) || addrFamily == UInt8(AF_INET6)  || addrFamily == UInt8(AF_LINK){
                    // Convert interface address to a human readable string:
                    var addr = interface.ifa_addr.pointee
                    var hostname = [CChar](repeating: 0, count: Int(NI_MAXHOST))
                    getnameinfo(&addr, socklen_t(interface.ifa_addr.pointee.sa_len),
                                &hostname, socklen_t(hostname.count),
                                nil, socklen_t(0), NI_NUMERICHOST)
                    let tempAddress = String(cString: hostname)
                    if (!tempAddress.isEmpty) {
                        address = tempAddress
                        ifObject.updateIF(addrFamily: Int32(addrFamily), address: address!)
                    }
                }
        }
        freeifaddrs(ifaddr)
        return self.validInterface()?.ipAddress
    }
    
}
