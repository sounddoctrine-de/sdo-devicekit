//
//  SdoBleManager.swift
//  SdoDeviceKit
//
//  Created by Joel Kingsley on 06.09.25.
//

import CoreBluetooth

import Foundation
import CoreBluetooth

/// BLE manager for connecting and sending commands
@MainActor
public class SdoBleManager: NSObject {

    // MARK: - Public

    public static let shared = SdoBleManager()

    /// Callback when a command is received
    public var onCommandReceived: ((SdoBleCommand) -> Void)?

    /// Start scanning for peripherals
    public func startScanning() {
        guard centralManager.state == .poweredOn else {
            print("⚠️ Bluetooth not powered on yet")
            return
        }
        centralManager.scanForPeripherals(withServices: [serviceUUID], options: nil)
        print("🔍 Started scanning for peripherals with service \(serviceUUID.uuidString)")
    }

    /// Stop scanning for peripherals
    public func stopScanning() {
        centralManager.stopScan()
        print("🛑 Stopped scanning")
    }

    /// Send a command to the connected peripheral
    public func sendCommand(_ command: SdoBleCommand) {
        guard let peripheral = connectedPeripheral,
              let characteristic = commandCharacteristic else {
            print("⚠️ No connected peripheral or characteristic")
            return
        }
        if let data = command.rawValue.data(using: .utf8) {
            peripheral.writeValue(data, for: characteristic, type: .withResponse)
            print("📤 Sent command: \(command.rawValue)")
        }
    }

    // MARK: - Private

    private var centralManager: CBCentralManager!
    private var connectedPeripheral: CBPeripheral?
    private var commandCharacteristic: CBCharacteristic?

    private let serviceUUID = CBUUID(string: "1234ABCD-0000-0000-0000-000000000000")
    private let commandCharacteristicUUID = CBUUID(string: "5678ABCD-0000-0000-0000-000000000000")

    // MARK: - Init

    private override init() {
        super.init()
        centralManager = CBCentralManager(delegate: self, queue: nil)
    }
}

// MARK: - CBCentralManagerDelegate
extension SdoBleManager: @MainActor CBCentralManagerDelegate {

    public func centralManagerDidUpdateState(_ central: CBCentralManager) {
        let stateCopy = central.state
        DispatchQueue.main.async {
            switch stateCopy {
            case .poweredOn: print("✅ Bluetooth is powered on")
            case .unsupported: print("⚠️ Bluetooth unsupported")
            case .unauthorized: print("⚠️ Bluetooth unauthorized")
            case .poweredOff: print("⚠️ Bluetooth powered off")
            case .resetting: print("⚠️ Bluetooth resetting")
            case .unknown: print("⚠️ Bluetooth state unknown")
            @unknown default: print("⚠️ Unexpected Bluetooth state")
            }
        }
    }

    public func centralManager(_ central: CBCentralManager,
                               didDiscover peripheral: CBPeripheral,
                               advertisementData: [String: Any],
                               rssi RSSI: NSNumber) {
        let peripheralCopy = peripheral
        let peripheralName = peripheral.name
        DispatchQueue.main.async {
            print("📱 Discovered peripheral: \(peripheralName ?? "Unknown")")
            self.connectedPeripheral = peripheralCopy
            self.centralManager.stopScan()
            self.centralManager.connect(peripheralCopy, options: nil)
        }
    }

    public func centralManager(_ central: CBCentralManager,
                               didConnect peripheral: CBPeripheral) {
        let peripheralCopy = peripheral
        DispatchQueue.main.async {
            print("🔗 Connected to \(peripheralCopy.name ?? "device")")
            self.connectedPeripheral = peripheralCopy
            peripheralCopy.delegate = self
            peripheralCopy.discoverServices([self.serviceUUID])
        }
    }

    public func centralManager(_ central: CBCentralManager,
                               didFailToConnect peripheral: CBPeripheral,
                               error: Error?) {
        let errorCopy = error
        DispatchQueue.main.async {
            print("❌ Failed to connect: \(errorCopy?.localizedDescription ?? "Unknown error")")
        }
    }

    public func centralManager(_ central: CBCentralManager,
                               didDisconnectPeripheral peripheral: CBPeripheral,
                               error: Error?) {
        let peripheralCopy = peripheral
        DispatchQueue.main.async {
            print("🔌 Disconnected from \(peripheralCopy.name ?? "device")")
            self.connectedPeripheral = nil
            self.commandCharacteristic = nil
            self.startScanning()
        }
    }
}

// MARK: - CBPeripheralDelegate
extension SdoBleManager: @MainActor CBPeripheralDelegate {

    public func peripheral(_ peripheral: CBPeripheral,
                           didDiscoverServices error: Error?) {
        if let errorCopy = error {
            print("❌ Error discovering services: \(errorCopy.localizedDescription)")
            return
        }
        guard let services = peripheral.services else { return }
        for service in services where service.uuid == self.serviceUUID {
            peripheral.discoverCharacteristics([self.commandCharacteristicUUID], for: service)
        }
    }

    public func peripheral(_ peripheral: CBPeripheral,
                           didDiscoverCharacteristicsFor service: CBService,
                           error: Error?) {
        if let errorCopy = error {
            print("❌ Error discovering characteristics: \(errorCopy.localizedDescription)")
            return
        }
        guard let characteristics = service.characteristics else { return }
        for characteristic in characteristics where characteristic.uuid == self.commandCharacteristicUUID {
            DispatchQueue.main.async {
                self.commandCharacteristic = characteristic
                peripheral.setNotifyValue(true, for: characteristic)
                print("✅ Subscribed to command characteristic")
            }
        }
    }

    public func peripheral(_ peripheral: CBPeripheral,
                           didUpdateValueFor characteristic: CBCharacteristic,
                           error: Error?) {
        if let errorCopy = error {
            print("❌ Error receiving value: \(errorCopy.localizedDescription)")
            return
        }
        guard let data = characteristic.value,
              let commandString = String(data: data, encoding: .utf8),
              let command = SdoBleCommand(rawValue: commandString) else {
            print("⚠️ Invalid command data")
            return
        }
        DispatchQueue.main.async {
            print("📥 Received command: \(command.rawValue)")
            self.onCommandReceived?(command)
        }
    }
}
