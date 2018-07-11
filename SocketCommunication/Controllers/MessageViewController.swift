//
//  MessageViewController.swift
//  SocketCommunication
//
//  Created by Vinit Ingale on 10/07/18.
//  Copyright © 2018 Vinit Ingale. All rights reserved.
//

import UIKit

class MessageViewController: UIViewController {

    @IBOutlet weak var connectionsLabel: UILabel!
    @IBOutlet weak var dataTextField: UITextField!
    @IBOutlet weak var dataDisplayLabel: UILabel!
    @IBOutlet weak var sendButton: UIButton!
    
    var connectedDevice: Device?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        WiFiDeviceManager.shared.wifiManagerDelegate = self
        setUpInitialData()
    }
    
    private func setUpInitialData() {
        connectionsLabel.text = "Connected device: \(connectedDevice?.deviceName ?? "Test")"
        dataDisplayLabel.text = ""
    }
    
    @IBAction func sendButtonClicked(_ sender: UIButton) {
        if let text = dataTextField.text, text.count > 0 {
            let keyEventDictionary = ["value": text]
            connectedDevice?.sendData(withDictionary: keyEventDictionary)
        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        dataTextField.resignFirstResponder()
    }
}

extension MessageViewController: WiFiManagerDelegate {
    func wifiReceivedData(message: String) {
        DispatchQueue.main.async {
            self.dataDisplayLabel.text = message
        }
    }
    
    func wifiDevicesListUpdated(list: [Device]) {
    }
    
    func wifiDeviceConnected(device: Device) {
        
    }
    
    func wifiDeviceConnectionClosed() {
        self.navigationController?.popViewController(animated: true)
    }
    
    func wifiDeviceFailedToEstablishConnection() {
        self.navigationController?.popViewController(animated: true)
    }
}
