//
//  BluetoothManager.swift
//  XDKNotifications
//
//  Created by Daniel Reyes Sánchez on 10/9/18.
//  Copyright © 2018 Robert Bosch. All rights reserved.
//

import CoreBluetooth


@objc public protocol BluetoothManagerDelegate: class {
    
    @objc optional func bluetoothDidTurnOn()
    @objc optional func bluetoothDidTurnOff()
    
    @objc optional func bluetoothDidFindDevice(_ peripheral:CBPeripheral)
    @objc optional func bluetoothFailedToConnect()
    @objc optional func bluetoothDidConnect()
    
    @objc optional func bluetoothDidFindService(_ service:CBService)
    
    @objc optional func bluetoothDidFindCharacteristic(_ characteristic:CBCharacteristic)
    
    @objc optional func bluetoothWillSendData(_ data:String)
    @objc optional func bluetoothDidSendData()
    @objc optional func bluetoothDidReceiveData(_ data:Data)
    
}

/*
 This is the class responsible for managing all bluetooth native events
 */
public class BluetoothManager: NSObject {
    
    public weak var delegate:BluetoothManagerDelegate?
    fileprivate var centralManager:CBCentralManager!
    fileprivate var peripheralDevice:CBPeripheral?
    
    
    fileprivate var currentCharacteristic:CBCharacteristic!
    
    fileprivate var scannedDevices = [String]()
    
    fileprivate var servicesUUIDs = [String]()
    fileprivate var characteristicsUUIDs = [String]()
    
    
    
    
    /// Initialize the BluetoothManager
    ///
    /// - Parameters:
    ///     - delegate: The designated class that will receive the updates from the events
    public init(delegate:BluetoothManagerDelegate) {
        self.delegate = delegate
        super.init()
        self.startManager(self)
    }
    
    // TODO:- Consider changing it to a Backgorund Queue
    // 0. Start Manager
    fileprivate func startManager(_ delegate:CBCentralManagerDelegate) {
        self.centralManager = CBCentralManager(delegate: delegate, queue: nil)
    }
    
    public func discoverDevices() {
        self.centralManager.scanForPeripherals(withServices: nil, options: nil)
    }
    
    public func connectToBleDevice(_ device:CBPeripheral) {
        peripheralDevice = device
        peripheralDevice?.delegate = self
        centralManager.stopScan()
        centralManager.connect(device, options: nil)
    }
    
    public func discoverServices() {
        self.peripheralDevice?.discoverServices(nil)
    }
    
    public func discoverCharacteristics(from service:CBService) {
        self.peripheralDevice?.discoverCharacteristics(nil, for: service)
    }
    
    public func write(value:Data, for characteristic:CBCharacteristic) {
        self.peripheralDevice?.writeValue(value, for: characteristic, type: .withResponse)
    }
    
    public func readValue(for characteristic:CBCharacteristic) {
        self.peripheralDevice?.readValue(for: characteristic)
    }
    
    public func setNotify(for characteristic:CBCharacteristic) {
        self.peripheralDevice?.setNotifyValue(true, for: characteristic)
    }
}


extension BluetoothManager:CBCentralManagerDelegate {
    // 1. Scan
    public func centralManagerDidUpdateState(_ central: CBCentralManager) {
        if central.state == CBManagerState.poweredOn {
            self.delegate?.bluetoothDidTurnOn?()
        } else {
            self.delegate?.bluetoothDidTurnOff?()
        }
    }
    
    // 2. Connect to Peripheral
    public func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        if let peripheralName = advertisementData[CBAdvertisementDataLocalNameKey] as? String {
            
            if !self.scannedDevices.contains(peripheral.identifier.uuidString) {
                print("Name: \(peripheralName) - ID: \(peripheral.identifier.uuidString)")
                self.delegate?.bluetoothDidFindDevice?(peripheral)
                scannedDevices.append(peripheral.identifier.uuidString)
            }
        }
    }
    
    // 3. Connected Successfully
    public func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        self.delegate?.bluetoothDidConnect?()
    }
    
    // 3.1 Failed To Connect
    public func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        self.delegate?.bluetoothFailedToConnect?()
    }
    
    // 3.2 Handle Disconnection
    // TODO:- Test the module commenting out this method and see if the module is prepared to stay conencted
    public func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        if self.peripheralDevice != nil {
            self.peripheralDevice?.delegate = nil
            self.peripheralDevice = nil
        } else {
            //self.delegate?.bluetoothReconnectionIntent()
            
        }
    }
    
    
    
    
}


extension BluetoothManager: CBPeripheralDelegate {
    
    // 4. Discover Services
    public func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        guard let services = peripheral.services else {return}
        for service in services {
            print(service) // For Debug Only
            let serviceUUID = service.uuid.uuidString
            self.delegate?.bluetoothDidFindService?(service)
        }
    }
    
    
    // 5. Discovering Characteristics
    public func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        guard let characteristics = service.characteristics else { return }
        for characteristic in characteristics {
            print(characteristic)
            
            self.delegate?.bluetoothDidFindCharacteristic?(characteristic)
            
            
            
            
            //            print("UUID: \(uuidString)")
            
            //            if uuidString == Constants.Services.DeviceInfo.ProductTypeIndex{
            //                self.currentCharacteristic = characteristic
            //                peripheral.readValue(for: characteristic)
            //
            //                //self.delegate?.bluetoothDidFindNotifyCharacteristic(with: characteristic.uuid.uuidString)
            //                //peripheral.setNotifyValue(true, for: characteristic)
            //            }
            
            // Enlarge MTU:
            // Devices running iOS < 10 will request an MTU size of 158. Newer devices running iOS 10 will request an MTU size of 185.
            // https://stackoverflow.com/questions/41977767/iosble-get-negotiate-mtu
            //peripheral.maximumWriteValueLength(for: myCharacteristic)
            
            //TODO:- Uncomment
            //            let uuidString = characteristic.uuid.uuidString
            //
            //            if uuidString == notifyCharacteristicUUID {
            //                self.delegate?.bluetoothDidFindWriteCharacteristic(with: characteristic.uuid.uuidString)
            //                self.currentCharacteristic = characteristic
            //                let valueForSend = "A" // 1.- escanear-huella
            //                if let value = valueForSend.data(using: .utf8) {
            //                    self.delegate?.bluetoothWillSendData(valueForSend)
            //                    self.peripheralDevice?.writeValue(value, for: self.currentCharacteristic, type: .withResponse)
            //                }
            //            } else if uuidString == readCharacteristicUUID {
            //                self.currentCharacteristic = characteristic
            //                self.delegate?.bluetoothDidFindNotifyCharacteristic(with: characteristic.uuid.uuidString)
            //                peripheral.setNotifyValue(true, for: characteristic)
            //            }
        }
    }
    
    
    // 6.1 Updating Values (Reading Values)
    public func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        if let error = error {
            print("updated error \(error)")
        }
        print("DidUpdateValue:")
        guard let rawData = characteristic.value else {return}
        
        
        self.delegate?.bluetoothDidReceiveData?(rawData)
    }
    
    // 6.2 DidWriteValue
    public func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        if let error = error {
            print("⚠️ Writing error \(error)")
        } else {
            //            guard let data = characteristic.value else {return}
            //            guard let value = String(data: data , encoding: .utf8) else {return}
            self.delegate?.bluetoothDidSendData?()
        }
    }
    
    // Delegate MethodNot Used for now
    //    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor descriptor: CBDescriptor, error: Error?) {
    //    }
    
}

