//
//  SdoBleManager.swift
//  SdoDeviceKit
//
//  Created by Joel Kingsley on 06.09.25.
//

import CoreBluetooth

/// SdoDeviceKit (modular SDK)
public class SdoBleManager: NSObject {
    private var centralManager: CBCentralManager!
    private var connectedPeripheral: CBPeripheral?
    
    var onCommandReceived: ((SdoBleCommand) -> Void)?
    
    override init() {
        super.init()
        centralManager = CBCentralManager(delegate: self, queue: nil)
    }
    
    func startScanning() { /* scan for peripherals with target service UUID */ }
    func connect(to peripheral: CBPeripheral) { /* connect & discover services */ }
    func sendCommand(_ command: SdoBleCommand) { /* write characteristic */ }
}

// MARK: - CBPeripheralDelegate
extension SdoBleManager: CBPeripheralDelegate {
    public func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) { /* discover characteristics */ }
    public func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        /* parse BLE command and call onCommandReceived */
    }
}
