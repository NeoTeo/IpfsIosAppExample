//
//  ViewController.swift
//  IpfsIosApp
//
//  Created by Teo on 15/12/15.
//  Copyright © 2015 Teo Sartori. All rights reserved.
//

import UIKit
import SwiftIpfsApi

class ViewController: UIViewController {
    
    @IBOutlet weak var ipfsNodeId: UILabel!
    var disco: IpfsNodeDiscovery?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        disco = IpfsNodeDiscovery()
        disco!.searchForNodeIP() { ip in
            print("Handler received \(ip)")
            self.goApi(ip)
        }
    }

    func goApi(_ theIp: String) {
        do {

            let api = try IpfsApi(host: theIp, port: 5001)
            
            try api.id() {
                (idData : JsonType) in
                
                print("inside api id")
                let nodeId = idData.object?["ID"]?.string
                print("node id is \(nodeId)")
                /// Any UIKit calls need to happen on the main thread.
                DispatchQueue.main.async {
                    self.ipfsNodeId.text = nodeId
                }
            }
        } catch {
            print("There was an error initializing the IPFS api client: \(error)")
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}

class IpfsNodeDiscovery : NSObject, NetServiceBrowserDelegate, NetServiceDelegate {
    let DOMAIN = "" //"local"
//    let SERVICE_TYPE = "_services._dns-sd._udp."//"_airplay._tcp."
    let SERVICE_TYPE = "_ipfs-discovery._udp."
//    let SERVICE_TYPE = "_ipfs._tcp."
//    let SERVICE_TYPE = "_1password4._tcp."
    let domainBrowser: NetServiceBrowser
    var active_service: NetService?
    var active_handler: ((String) -> ())?
    var node_address: String?
    
    override init() {
        domainBrowser = NetServiceBrowser()
        super.init()
    }
    
    func searchForNodeIP(_ handler: @escaping (String) -> ()) {
        active_handler = handler
        domainBrowser.delegate = self
        domainBrowser.searchForServices(ofType: SERVICE_TYPE, inDomain: DOMAIN)
    }
    
    func netServiceBrowser(_ browser: NetServiceBrowser, didFind service: NetService, moreComing: Bool) {
        print("Service: \(service)")
        print("name: \(service.name)")
        print("type: \(service.type)")

        print("comparing \(SERVICE_TYPE) with \(service.type)")
        if service.type == SERVICE_TYPE {
            print("success")
//            if service.name == "_ipfs" {
            // Store the service so we can be sure it's not released.
            
            active_service = service
            print(active_service!.hostName)
            active_service!.delegate = self
            active_service!.resolve(withTimeout: 2.0)
        }
    }
    
    func netServiceBrowserWillSearch(_ browser: NetServiceBrowser) {
        print("going...")
    }
    func netServiceBrowserDidStopSearch(_ browser: NetServiceBrowser) {
        print("gone.")
    }
    
    func netServiceDidResolveAddress(_ sender: NetService) {
        print("Bingo \(sender.addresses)")
        guard let addresses = sender.addresses else { return }
        
        enum Ip_socket_address {
            case sa(sockaddr)
            case ipv4(sockaddr_in)
            case ipv6(sockaddr_in6)
        }
        
        for addr in addresses {
            var storage = sockaddr_storage()
            (addr as NSData).getBytes(&storage, length: MemoryLayout<sockaddr_storage>.size)
//            let buf = UnsafeMutablePointer<Int8>(allocatingCapacity: Int(INET6_ADDRSTRLEN))
            let buf = UnsafeMutablePointer<Int8>.allocate(capacity: Int(INET6_ADDRSTRLEN))
            var ipc: UnsafePointer<Int8>? = nil
            
            switch Int32(storage.ss_family){
                
            case AF_INET:
//                let addrData = withUnsafePointer(to: &storage) { UnsafePointer<sockaddr_in>($0).pointee }
                let addrData = withUnsafePointer(to: &storage) {
                    $0.withMemoryRebound(to: sockaddr_in.self, capacity: 1) { $0.pointee }
                }
                var addr = addrData.sin_addr
                ipc = inet_ntop(Int32(addrData.sin_family), &addr, buf, __uint32_t(INET6_ADDRSTRLEN))
                /// Return the first ip we find (ignoring localhost)
                if let addrString = String(validatingUTF8: ipc!) , addrString != "127.0.0.1" {
                    node_address = addrString //String.fromCString(ipc)
                    return
                }
            case AF_INET6:
//                let addr6Data = withUnsafePointer(to: &storage) { UnsafePointer<sockaddr_in6>($0).pointee }
                let addr6Data = withUnsafePointer(to: &storage) {
                    $0.withMemoryRebound(to: sockaddr_in6.self, capacity: 1) { $0.pointee }
                }
                var addr = addr6Data.sin6_addr
                ipc = inet_ntop(Int32(addr6Data.sin6_family), &addr, buf, __uint32_t(INET6_ADDRSTRLEN))

            default: break
            }

            print(String(cString: ipc!))
        }
    }
    
    func netServiceWillResolve(_ sender: NetService) {
        print("Resolving...")
    }
    
    func netService(_ sender: NetService, didNotResolve errorDict: [String : NSNumber]) {
        print("nohappy \(errorDict)")
    }
    
    func netServiceDidStop(_ sender: NetService) {
        print("stop")
        active_service = nil
        if let handler = active_handler, let node = node_address {
            active_handler = nil
            handler(node)
        } else {
            print("Error: no node address")
        }
    }
}


