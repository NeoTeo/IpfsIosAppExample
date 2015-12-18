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

    @IBOutlet weak var ipfsNodeId: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
            do {
                let api = try IpfsApi(host: "192.168.5.9", port: 5001)
                
                try api.id() {
                    (idData : JsonType) in
                    
                    let winName = idData.object?["ID"]?.string
                    
                    self.ipfsNodeId.text = winName
                }
            } catch {
                print("There was an error initializing the IPFS api client: \(error)")
            }

        
        let disco = IpfsNodeDiscovery()
        disco.searchForNodeIP() {
            return "ARSE"
        }
        print("So far...")
        NSRunLoop.currentRunLoop().run()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}

/**
 Service: <NSNetService 0x7fd843b411e0> . _tcp.local. _airplay
 Service: <NSNetService 0x7fd843b411e0> . _tcp.local. _raop
 Service: <NSNetService 0x7fd84241e6c0> . _tcp.local. _touch-able
 Service: <NSNetService 0x7fd84241e6c0> . _tcp.local. _appletv-v2
 Service: <NSNetService 0x7fd84251b2e0> . _tcp.local. _icloud-ds
 Service: <NSNetService 0x7fd84251b2e0> . _tcp.local. _apple-mobdev2
 Service: <NSNetService 0x7fd84251b2e0> . _tcp.local. _dacp
 Service: <NSNetService 0x7fd84251b2e0> . _udp.local. _sleep-proxy
 Service: <NSNetService 0x7fd84251b2e0> . _tcp.local. _acp-sync
 Service: <NSNetService 0x7fd84251b2e0> . _tcp.local. _airport
 Service: <NSNetService 0x7fd84251b2e0> . _tcp.local. _workstation
 Service: <NSNetService 0x7fd84251b2e0> . _tcp.local. _udisks-ssh
 Service: <NSNetService 0x7fd84251b2e0> . _tcp.local. _afpovertcp
 Service: <NSNetService 0x7fd84251b2e0> . _tcp.local. _ssh
 Service: <NSNetService 0x7fd84251b2e0> . _tcp.local. _sftp-ssh
 as in: 
 ...
 Service: <NSNetService 0x7fd84251b2e0> . _tcp.local. _rfb
 Service: <NSNetService 0x7fd84251b2e0> . _tcp.local. _1password4
 Service: <NSNetService 0x7fd8438005a0> . ipfs.local. discovery
 ...
*/
class IpfsNodeDiscovery : NSObject, NSNetServiceBrowserDelegate, NSNetServiceDelegate {
    let DOMAIN = "" //"local"
//    let SERVICE_TYPE = "_services._dns-sd._udp."//"_airplay._tcp."
//    let SERVICE_TYPE = "_discovery._ipfs."
        let SERVICE_TYPE = "_ipfs._tcp."
//    let SERVICE_TYPE = "_1password4._tcp."
    let domainBrowser: NSNetServiceBrowser
    var active_service: NSNetService?
    
    override init() {
        domainBrowser = NSNetServiceBrowser()
        super.init()
    }
    
    func searchForNodeIP(handler: ()->String?) {
        domainBrowser.delegate = self
        domainBrowser.searchForServicesOfType(SERVICE_TYPE, inDomain: DOMAIN)
    }
    
    func netServiceBrowser(browser: NSNetServiceBrowser, didFindService service: NSNetService, moreComing: Bool) {
        print("Service: \(service)")
        print("name: \(service.name)")
        print("type: \(service.type)")

        if service.type == SERVICE_TYPE {
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
        print("nohappy")
    }
    func netServiceDidStop(sender: NSNetService) {
        print("stop")
        active_service = nil
    }
}


