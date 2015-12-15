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
        dispatch_async(dispatch_get_main_queue(), {
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
        })

    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

