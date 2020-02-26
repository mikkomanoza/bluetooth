//
//  ViewController.swift
//  bluetooth
//
//  Created by Joseph Mikko Mañoza on 21/02/2020.
//  Copyright © 2020 Joseph Mikko Mañoza. All rights reserved.
//

import CoreBluetooth
import UIKit

class ViewController: UIViewController {

    @IBOutlet weak var tableView: UITableView!
    var watches : Array<String> = Array<String>()
    
    let charRead = "0000FFF1-1000-1000-8000-00805F9B34FB"
    let charNotif = "0000FFF3-1000-1000-8000-00805F9B34FB"
    let charWrite = "0000FFF2-1000-1000-8000-00805F9B34FB"
    var backgroundUUID: UUID! = nil
    var writeChannel: CBCharacteristic!
    var centralManager: CBCentralManager!
    var heartRatePeripheral: CBPeripheral!
    var watchesPeriperhalCode : [String : CBPeripheral] = [:]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.dataSource = self
        tableView.delegate = self
        centralManager = CBCentralManager(delegate: self, queue: nil)
    }
    
    @IBAction func scan(_ sender: UIBarButtonItem) {
        self.watchesPeriperhalCode.removeAll()
        self.watches.removeAll()
        centralManager.scanForPeripherals(withServices: nil)
        self.tableView.reloadData()
    }
}

extension ViewController: UITableViewDataSource, UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell")!
        cell.textLabel?.text = watches[indexPath.row]
        return cell
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return watches.count
    }
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        centralManager.stopScan()
        if let currentPeripheral = watchesPeriperhalCode[watches[indexPath.row]] {
            heartRatePeripheral = currentPeripheral
            heartRatePeripheral.delegate = self
            centralManager.connect(heartRatePeripheral)
        }
    }
}

extension ViewController: CBPeripheralDelegate {
    
    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        print("Command Received: \(String(describing: String(bytes: characteristic.value!, encoding: String.Encoding.utf8)))")
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic,
                     error: Error?) {
         switch characteristic.uuid.uuidString {
         case charNotif: break

         default:
             ()
         }
     }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
       guard let services = peripheral.services else { return }
       for service in services {
           peripheral.discoverCharacteristics(nil, for: service)
       }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService,
                    error: Error?) {
        guard let characteristics = service.characteristics else { return }
        
        for characteristic in characteristics {
            
            if characteristic.properties.contains(.read) {
                peripheral.readValue(for: characteristic)
            }
            
            if characteristic.properties.contains(.notify) {
                peripheral.setNotifyValue(true, for: characteristic)
            }
            
            if characteristic.properties.contains(.write) {
                print("Write Channel Discovered")
                writeChannel = characteristic
            }
        }
    }
}

extension ViewController: CBCentralManagerDelegate {
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        print("successfully connected")
        self.heartRatePeripheral.discoverServices(nil)
        self.writeCharacteristic(commandType: 1)
        self.backgroundUUID = peripheral.identifier
    }
    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        heartRatePeripheral = peripheral
        centralManager.scanForPeripherals(withServices: nil)
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String: Any], rssi RSSI: NSNumber) {
        
        print("peripherals: - \(String(describing: peripheral.name))")
        
        if peripheral.name != nil {
            watches.append(peripheral.name!)
            watchesPeriperhalCode = [peripheral.name! : peripheral]
            tableView.reloadData()
        }
    }
    
    func writeCharacteristic(commandType: Int) {
         
         if heartRatePeripheral != nil {
             
             var command:[UInt8]
             
             if commandType == 0 {
                 command = [0xA3]
             } else {
                 command = [0xA2]
             }
             
             if writeChannel != nil {
                 heartRatePeripheral.writeValue(Data(command), for: writeChannel!, type: .withResponse)
             } else {
                 print("No channel found.")
             }
             
         } else {
             print("Not connected to any device.")
         }
     }
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case .unknown:
            print("central.state is .unknown")
        case .resetting:
            print("central.state is .resetting")
        case .unsupported:
            print("central.state is .unsupported")
        case .unauthorized:
            print("central.state is .unauthorized")
        case .poweredOff:
            print("central.state is .poweredOff")
        case .poweredOn:
            print("central.state is .poweredOn")
        default: break
        }
    }
}
