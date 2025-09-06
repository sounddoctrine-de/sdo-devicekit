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
