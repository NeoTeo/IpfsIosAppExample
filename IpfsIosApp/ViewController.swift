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

    func goApi(theIp: String) {
        do {

            let api = try IpfsApi(host: theIp, port: 5001)
            
            try api.id() {
                (idData : JsonType) in
                
                print("inside api id")
                let nodeId = idData.object?["ID"]?.string
                print("node id is \(nodeId)")
                /// Any UIKit calls need to happen on the main thread.
                dispatch_async(dispatch_get_main_queue()) {
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

class IpfsNodeDiscovery : NSObject, NSNetServiceBrowserDelegate, NSNetServiceDelegate {
    let DOMAIN = "" //"local"
//    let SERVICE_TYPE = "_services._dns-sd._udp."//"_airplay._tcp."
    let SERVICE_TYPE = "_ipfs-discovery._udp."
//    let SERVICE_TYPE = "_ipfs._tcp."
//    let SERVICE_TYPE = "_1password4._tcp."
    let domainBrowser: NSNetServiceBrowser
    var active_service: NSNetService?
    var active_handler: ((String) -> ())?
    var node_address: String?
    
    override init() {
        domainBrowser = NSNetServiceBrowser()
        super.init()
    }
    
    func searchForNodeIP(handler: (String) -> ()) {
        active_handler = handler
        domainBrowser.delegate = self
        domainBrowser.searchForServicesOfType(SERVICE_TYPE, inDomain: DOMAIN)
    }
    
    func netServiceBrowser(browser: NSNetServiceBrowser, didFindService service: NSNetService, moreComing: Bool) {
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
            active_service!.resolveWithTimeout(2.0)
        }
    }
    
    func netServiceBrowserWillSearch(browser: NSNetServiceBrowser) {
        print("going...")
    }
    func netServiceBrowserDidStopSearch(browser: NSNetServiceBrowser) {
        print("gone.")
    }
    
    func netServiceDidResolveAddress(sender: NSNetService) {
        print("Bingo \(sender.addresses)")
        guard let addresses = sender.addresses else { return }
        
        enum Ip_socket_address {
            case sa(sockaddr)
            case ipv4(sockaddr_in)
            case ipv6(sockaddr_in6)
        }
        
        for addr in addresses {
            var storage = sockaddr_storage()
            addr.getBytes(&storage, length: sizeof(sockaddr_storage))
            let buf = UnsafeMutablePointer<Int8>.alloc(Int(INET6_ADDRSTRLEN))
            var ipc = UnsafePointer<Int8>()
            
            switch Int32(storage.ss_family){
                
            case AF_INET:
                let addrData = withUnsafePointer(&storage) { UnsafePointer<sockaddr_in>($0).memory }
                var addr = addrData.sin_addr
                ipc = inet_ntop(Int32(addrData.sin_family), &addr, buf, __uint32_t(INET6_ADDRSTRLEN))
                /// ignore localhost
                if let addrString = String.fromCString(ipc) where addrString != "127.0.0.1" {
                    node_address = addrString //String.fromCString(ipc)
                }
            case AF_INET6:
                let addr6Data = withUnsafePointer(&storage) { UnsafePointer<sockaddr_in6>($0).memory }
                var addr = addr6Data.sin6_addr
                ipc = inet_ntop(Int32(addr6Data.sin6_family), &addr, buf, __uint32_t(INET6_ADDRSTRLEN))

            default: break
            }

            print(String.fromCString(ipc))
        }
    }
    
    func netServiceWillResolve(sender: NSNetService) {
        print("Resolving...")
    }
    
    func netService(sender: NSNetService, didNotResolve errorDict: [String : NSNumber]) {
        print("nohappy \(errorDict)")
    }
    
    func netServiceDidStop(sender: NSNetService) {
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


