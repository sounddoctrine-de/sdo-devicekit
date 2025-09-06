//
//  SdoBleCommand.swift
//  SdoDeviceKit
//
//  Created by Joel Kingsley on 06.09.25.
//

import CoreBluetooth

/// Enum for playback commands
public enum SdoBleCommand: String {
    case play, pause, stop, seekForward, seekBackward, volumeUp, volumeDown
}

// MARK: - CBCentralManagerDelegate
extension SdoBleManager: CBCentralManagerDelegate {
    public func centralManagerDidUpdateState(_ central: CBCentralManager) { /* handle powered on/off */ }
    public func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral,
                        advertisementData: [String: Any], rssi RSSI: NSNumber) { /* choose & connect */ }
    public func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) { /* discover services */ }
}
