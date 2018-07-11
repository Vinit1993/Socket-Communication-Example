//
//  ViewController.swift
//  SocketCommunication
//
//  Created by Vinit Ingale on 10/07/18.
//  Copyright © 2018 Vinit Ingale. All rights reserved.
//

import UIKit
import CocoaAsyncSocket

class ViewController: UIViewController {

    @IBOutlet weak var wifiDeivceListTableView: UITableView!
    
    var wifiDevices: [Device] = []
    var selectedDevice: Device?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        WiFiDeviceManager.shared.wifiManagerDelegate = self
        WiFiDeviceManager.shared.scanWiFiDevices()
    }
}

extension ViewController: UITableViewDelegate, UITableViewDataSource {
    

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return wifiDevices.count
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableViewAutomaticDimension
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        guard let cell = wifiDeivceListTableView.dequeueReusableCell(withIdentifier: "WifiDeviceListTableViewCell", for: indexPath) as? WifiDeviceListTableViewCell else {
            fatalError("WifiDeviceListTableViewCell not found.")
        }
        cell.setupCellData(name: wifiDevices[indexPath.row].deviceName)
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let wifiDevice = wifiDevices[indexPath.row]
        if let device = wifiDevice.netService {
            selectedDevice = wifiDevice
            WiFiDeviceManager.shared.connect(netService: device)
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "MessageViewController" {
            let destinationVC = segue.destination as! MessageViewController
            destinationVC.connectedDevice = selectedDevice
        }
    }
}

extension ViewController: WiFiManagerDelegate {
    
    func wifiReceivedData(message: String) {
        
    }
    
    func wifiDevicesListUpdated(list: [Device]) {
        wifiDevices = list
        DispatchQueue.main.async {
            self.wifiDeivceListTableView.reloadData()
        }
    }
    
    func wifiDeviceConnected(device: Device) {
        selectedDevice = device
        performSegue(withIdentifier: "toMessageViewController", sender: self)
    }
    
    func wifiDeviceConnectionClosed() {
        
    }
    
    func wifiDeviceFailedToEstablishConnection() {
        
    }
}
