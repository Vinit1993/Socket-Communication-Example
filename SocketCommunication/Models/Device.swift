//
//  Device.swift
//  SocketCommunication
//
//  Created by Vinit Ingale on 10/07/18.
//  Copyright © 2018 Vinit Ingale. All rights reserved.
//

import Foundation
import CocoaAsyncSocket


public class Device: NSObject {
    
    public var deviceName = ""
    public var udpSocket: GCDAsyncUdpSocket?
    public var netService: NetService?
    private var currentTag: Int = 0
    
    init(udpSocket asyncUdpSocket: GCDAsyncUdpSocket) {
        udpSocket = asyncUdpSocket
    }

    
    init(netService netServiceParam: NetService) {
        netService = netServiceParam
    }
    
    func sendData(withDictionary dataDictionary: [AnyHashable: Any]) {

        if let keyEventData: Data = try? JSONSerialization.data(withJSONObject: dataDictionary, options: .prettyPrinted) {
            if let udpSocket = udpSocket {
                if udpSocket.isConnected() {

                    udpSocket.send(keyEventData, withTimeout: 20, tag: currentTag)
                    currentTag += 1
                } else if let netService = netService {
                    // create socket again
                    // check connectedHost, connectedPort.
                    WiFiDeviceManager.shared.connect(netService: netService)
                    sendData(withDictionary: dataDictionary)
                }
            }
        }
    }
}
