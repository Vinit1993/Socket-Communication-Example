//
//  WifiDeviceListTableViewCell.swift
//  SocketCommunication
//
//  Created by Vinit Ingale on 10/07/18.
//  Copyright © 2018 Vinit Ingale. All rights reserved.
//

import UIKit

class WifiDeviceListTableViewCell: UITableViewCell {

    @IBOutlet weak var deviceName: UILabel!
    
    func setupCellData(name: String) {
        deviceName.text = name
    }
}
