//
//  ViewController.swift
//  XDKNotifications
//
//  Created by Daniel Reyes Sánchez on 10/9/18.
//  Copyright © 2018 Robert Bosch. All rights reserved.
//

import UIKit
import CoreBluetooth
import UserNotifications


class ViewController: UIViewController, BluetoothManagerDelegate{

    let center = UNUserNotificationCenter.current()
    var bluetoothManager:BluetoothManager!
    var timer:Timer!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        bluetoothManager = BluetoothManager(delegate: self)
        
        
        
    }
    
    func bluetoothDidTurnOn() {
        bluetoothManager.discoverDevices()
    }
    
    func bluetoothDidFindDevice(_ peripheral: CBPeripheral) {
        if peripheral.name == "XDK_CROSS_SELLING" {
            bluetoothManager.connectToBleDevice(peripheral)
        }
    }
    
    func bluetoothDidConnect() {
        bluetoothManager.discoverServices()
    }
    
    func bluetoothDidFindService(_ service: CBService) {
        print(service)
        bluetoothManager.discoverCharacteristics(from: service)
//        guard let firstService = service.includedServices?.first else {return}
        
    }
    
    var readCharacteristic:CBCharacteristic!
    
    func bluetoothDidFindCharacteristic(_ characteristic: CBCharacteristic) {
        print(characteristic.uuid.uuidString)
        if characteristic.uuid.uuidString == "0C68D100-266F-11E6-B388-0002A5D5C51B" {
            guard let command = "start".data(using: String.Encoding.utf8) else {return}
            bluetoothManager.write(value: command, for: characteristic)
        } else if characteristic.uuid.uuidString == "1ED9E2C0-266F-11E6-850B-0002A5D5C51B" {
            //bluetoothManager.write(value: command, for: characteristic)
            self.readCharacteristic = characteristic
            self.timer = Timer.scheduledTimer(timeInterval: 5, target: self, selector: #selector(readValues), userInfo: nil, repeats: true)
        }
    }
    
    @objc private func readValues() {
        bluetoothManager.readValue(for: readCharacteristic)
    }
    
//    El número 1 es para acelerómetro.
//    Warning: Vibration issue detected!
//    El número 2 es para magnetómetro.
//    Warning: Current issue detected!
//    El número 3 es para presión.
//    Warning: Pressure limit value exceeded!
//    El número 4 es para temperatura.
//    Warning: Temperature limit value exceeded!
//    El número 5 es para humedad relativa
//    Warning: Humidity limit value exceeded!
    
    func bluetoothDidReceiveData(_ data: Data) {
        guard let str = String.init(data: data, encoding: String.Encoding.utf8) else {return}
        guard let character = str.first else {return}
        var message = ""
        switch character {
        case "1": message = "Warning: Vibration issue detected!"; break
        case "2": message = "Warning: Current issue detected!"; break
        case "3": message = "Warning: Pressure limit value exceeded!"; break
        case "4": message = "Warning: Temperature limit value exceeded!"; break
        case "5": message = "Warning: Humidity limit value exceeded!"; break
        default: return // Does nothing
        }
        
        
        let content = UNMutableNotificationContent()
        content.title = "XDK"
        content.body = message
        content.sound = UNNotificationSound.default
        
        let trigger = UNTimeIntervalNotificationTrigger.init(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest.init(identifier: "mx.bosch.XDKNotifications.xdknotification", content: content, trigger: trigger)
        let center = UNUserNotificationCenter.current()
        center.add(request, withCompletionHandler: nil)
    }
}

