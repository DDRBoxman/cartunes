//
//  cartunesApp.swift
//  cartunes
//
//  Created by Colin Edwards on 5/19/23.
//

import SwiftUI

@main
struct cartunesApp: App {
    var bluetoothManager: BluetoothManager
    
    init() {
        bluetoothManager = BluetoothManager()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
