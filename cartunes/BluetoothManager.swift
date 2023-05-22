//
//  BluetoothManager.swift
//  cartunes
//
//  Created by Colin Edwards on 5/19/23.
//

import Foundation
import CoreBluetooth
import IOBluetooth
import SwiftMsgPack

class BluetoothManager: IOBluetoothRFCOMMChannelDelegate {
    var cbManager: CBCentralManager
    
    var serviceRecord : IOBluetoothSDPServiceRecord? = nil;
    var channel : IOBluetoothRFCOMMChannel? = nil;
    var handle: BluetoothSDPServiceRecordHandle? = nil
    var serverID : BluetoothRFCOMMChannelID = 255;
    var notification2 : IOBluetoothUserNotification? = nil;

    init() {
        cbManager = CBCentralManager()

        let path = Bundle.main.path(forResource: "CarThingSDP", ofType: "plist")!
        let serviceDictionary = NSMutableDictionary(contentsOfFile: path)

        serviceRecord = IOBluetoothSDPServiceRecord.publishedServiceRecord(with: serviceDictionary! as [NSObject: AnyObject])
        if serviceRecord == nil {
            fatalError("Failed to add SDP Service Record.")
        }
        
        var id = BluetoothRFCOMMChannelID()
        serviceRecord?.getRFCOMMChannelID(&id)
        serverID = id
        
        print(serverID)
        
        
        var recordHandle = BluetoothSDPServiceRecordHandle()
        serviceRecord?.getHandle(&recordHandle)
        handle = recordHandle
        
        print(recordHandle)
        
        notification2 = IOBluetoothRFCOMMChannel.register(forChannelOpenNotifications: self, selector: #selector(self.rfcommChannelOpen(notification:channel:)), withChannelID: id, direction: kIOBluetoothUserNotificationChannelDirectionIncoming);
    }
    
    @objc func rfcommChannelOpen(notification: IOBluetoothUserNotification, channel: IOBluetoothRFCOMMChannel) {
        /*if (self.serverID != channel.getID()) {
           return;
       }*/
        
        print("Notification Recieved!!!");
        print(channel);
        //print(notification);
        
        //notification.unregister()

        self.channel = channel
        self.channel?.setDelegate(self)
    }
        
    func rfcommChannelData(_ rfcommChannel: IOBluetoothRFCOMMChannel!, data dataPointer: UnsafeMutableRawPointer!, length dataLength: Int) {
        let data = Data(bytes: dataPointer, count: Int(dataLength))
        let size: UInt32 = UInt32(data[3]) | UInt32(data[2]) << 8 | UInt32(data[1]) << 16 | UInt32(data[0]) << 24;
        let dataSmall = data.subdata(in: 4..<Int(size+4))
        
        processMessage(data: dataSmall)
    }
        
    func rfcommChannelClosed(_ rfcommChannel: IOBluetoothRFCOMMChannel!) {
        print("closed")
    }
    
    func rfcommChannelOpenComplete(_ rfcommChannel: IOBluetoothRFCOMMChannel!, status error: IOReturn) {
        print("open")
    }
    
    func processMessage(data: Data) {
        do {
          let decodedObj: Any? = try data.unpack()
            print(decodedObj)
            
            switch decodedObj  {
            case let messageArray as [Any?]:
                switch CarThingMessage(rawValue: messageArray[0] as! Int8)! {
                case CarThingMessage.HELLO:
                    print("HELLO")
                    
                    let messageDict = messageArray[2] as! [String : Any]
                    let authid = messageDict["authid"]
                    
                    let dateFormatter = DateFormatter()
                    dateFormatter.dateFormat = "yyyy-MM-ddTHH:mm:ss"
                    let timestamp = dateFormatter.string(from: Date())
                    
                    let jsonChallenge = [
                        "authid": authid,
                        "authmethod": "wampcra",
                        "authprovider": "spotify",
                        "authrole": "app",
                        "nonce": "dummy_nonce",
                        "session": 0,
                        "timestamp": timestamp,
                    ] as [String : Any]
                    
                    let jsonData = try JSONSerialization.data(withJSONObject: jsonChallenge)
                    let jsonString = String(data: jsonData, encoding: String.Encoding.utf8)
                    
                    var msgData = Data()
                    do {
                        try msgData.pack([UInt64(CarThingMessage.CHALLENGE.rawValue), "wampcra", [ "challenge": jsonString]])
                        
                        let test = try msgData.unpack()
                        print(test)
                        
                        var prefix = Data.init(count: 4)
                        
                        let size: UInt32 = UInt32(msgData.count)
                        prefix[3] = UInt8(size >> 0);
                        prefix[2] = UInt8(size >> 8);
                        prefix[1] = UInt8(size >> 16);
                        prefix[0] = UInt8(size >> 24);
                        
                        var msgBuff = prefix + msgData
                        
                        msgBuff.withUnsafeMutableBytes { rawBufferPointer in
                            self.channel?.writeSync(rawBufferPointer.baseAddress!, length: UInt16(rawBufferPointer.count))
                        }
                    }
                    catch {
                        print("Something went wrong while packing data: \(error)")
                    }
                    
                    
                case CarThingMessage.AUTHENTICATE:
                    print("AUTHENTICATE")
                    
                    
                default:
                    print("Unknown message type")
                }
            default:
                print("YIKES")
            }

            
        } catch {
          print("Something went wrong while unpacking data: \(error)")
        }
    }
}
