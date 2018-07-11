//
//  WifiDeviceManager.swift
//  SocketCommunication
//
//  Created by Vinit Ingale on 10/07/18.
//  Copyright © 2018 Vinit Ingale. All rights reserved.
//

import Foundation
import CocoaAsyncSocket

protocol WiFiManagerDelegate {
    func wifiDevicesListUpdated(list: [Device])
    func wifiDeviceConnected(device: Device)
    func wifiDeviceConnectionClosed()
    func wifiDeviceFailedToEstablishConnection()
    func wifiReceivedData(message: String)
}


public class WiFiDeviceManager: NSObject {
    
    fileprivate var wifiDevices = [Device]()
    var wifiManagerDelegate: WiFiManagerDelegate?
    fileprivate var wifiDeviceBrowser: NetServiceBrowser?
    fileprivate var createdSocket: GCDAsyncUdpSocket?

    private var foundServices: [NetService] = []
    
    let NET_BROWSER_SERVICE_TYPE = "_http._tcp."

    // MARK: Shared Instance
    public static let shared = WiFiDeviceManager()
    
    // Can't init singleton
    private override init() {
        super.init()
        wifiDeviceBrowser = NetServiceBrowser()
        wifiDeviceBrowser?.delegate = self
        wifiDeviceBrowser?.includesPeerToPeer = true
    }
    
    public func scanWiFiDevices()  {
        wifiDeviceBrowser?.searchForServices(ofType: NET_BROWSER_SERVICE_TYPE, inDomain: "local.")
    }
    
    public func stopScan()  {
        wifiDeviceBrowser?.stop()
    }
    
    public func connect(netService: NetService) {
        if let addresses = netService.addresses, addresses.count > 0 {
            enum UDPSocketError: Error {
                case connectionNotEstablished
            }

            createdSocket = GCDAsyncUdpSocket(delegate: self , delegateQueue: DispatchQueue.main)
            let port: Int = netService.port

            do {
                try createdSocket?.bind(toPort: UInt16(port))
                try createdSocket?.beginReceiving()
                try createdSocket?.enableBroadcast(true)
                try createdSocket?.enableReusePort(true)

                let addressData = addresses[0]
                let hostAddressForService: String = GCDAsyncUdpSocket.host(fromAddress: addressData)!

                try createdSocket?.connect(toHost: hostAddressForService, onPort: UInt16(port))

            } catch _ as NSError {
            }
        }
    }
    
    private func startResolvingNextService() {
        if foundServices.count > 0 {
            let firstService = foundServices[0]
            firstService.delegate = self
            firstService.resolve(withTimeout: 10)
        }
    }
}

//MARK: Net Service Browser Delegate methods
extension WiFiDeviceManager: NetServiceBrowserDelegate {
    
    public func netServiceBrowser(_ browser: NetServiceBrowser, didFindDomain domainString: String, moreComing: Bool) {
    }
    
    public func netServiceBrowser(_ browser: NetServiceBrowser, didFind service: NetService, moreComing: Bool) {
        
        foundServices.append(service)
        if !moreComing {
            startResolvingNextService()
        }
    }
    
    public func netServiceBrowser(_ browser: NetServiceBrowser, didRemoveDomain domainString: String, moreComing: Bool) {
    }
    
    public func netServiceBrowser(_ browser: NetServiceBrowser, didRemove service: NetService, moreComing: Bool) {
        wifiDevices = wifiDevices.filter { (tempDevice: Device) -> Bool in
            return !(tempDevice.netService === service)
        }
    }
    
    public func netServiceBrowser(_ browser: NetServiceBrowser, didNotSearch errorDict: [String : NSNumber]) {
    }
}

//MARK: Net service delegate methods
extension WiFiDeviceManager: NetServiceDelegate {
    
    public func netService(_ sender: NetService, didAcceptConnectionWith inputStream: InputStream, outputStream: OutputStream) {
    }
    
    public func netServiceDidResolveAddress(_ sender: NetService) {
        
        let deviceName = sender.name
        
        let netServiceDevice = Device(netService: sender)
        netServiceDevice.deviceName = deviceName
        
        if let existingDevice = wifiDevices.first(where: { $0.deviceName == deviceName }), let index = wifiDevices.index(of: existingDevice) {
            wifiDevices.remove(at: index)
        }
        
        wifiDevices.append(netServiceDevice)
        wifiManagerDelegate?.wifiDevicesListUpdated(list: wifiDevices)
        sender.stop()
        
        if foundServices.count > 0 {
            foundServices.remove(at: 0)
            startResolvingNextService()
        }
    }
    
    public func netService(_ sender: NetService, didNotResolve errorDict: [String : NSNumber]) {
        if foundServices.count > 0 {
            foundServices.remove(at: 0)
            startResolvingNextService()
        }
    }
}

//MARK: UDP Socket delegate methods
extension WiFiDeviceManager: GCDAsyncUdpSocketDelegate  {

    public func udpSocket(_ sock: GCDAsyncUdpSocket, didConnectToAddress address: Data) {
        if let createdSocket = createdSocket {
            let device = Device(udpSocket: createdSocket)
            wifiManagerDelegate?.wifiDeviceConnected(device: device)
        }
    }

    public func udpSocket(_ sock: GCDAsyncUdpSocket, didNotConnect error: Error?) {
        wifiManagerDelegate?.wifiDeviceConnectionClosed()
    }

    public func udpSocketDidClose(_ sock: GCDAsyncUdpSocket, withError error: Error?) {
        wifiManagerDelegate?.wifiDeviceConnectionClosed()
    }

    public func udpSocket(_ sock: GCDAsyncUdpSocket, didSendDataWithTag tag: Int) {
    }

    public func udpSocket(_ sock: GCDAsyncUdpSocket, didNotSendDataWithTag tag: Int, dueToError error: Error?) {
    }

    public func udpSocket(_ sock: GCDAsyncUdpSocket, didReceive data: Data, fromAddress address: Data, withFilterContext filterContext: Any?) {
        do {
            if let dataDictionary = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                if let message = dataDictionary["value"] as? String {
                    wifiManagerDelegate?.wifiReceivedData(message: message)
                }
            }
        } catch {

        }
    }
}


