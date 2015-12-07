// Copyright 2015 Google Inc. All rights reserved.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//    http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

import Foundation
import CoreBluetooth

///
/// BeaconID
///
/// Uniquely identifies an Eddystone compliant beacon.
///
class BeaconID : NSObject {

  enum BeaconType {
    case Eddystone
  }

  ///
  /// Currently there's only the Eddystone format, but we'd like to leave the door open to other
  /// possibilities, so let's have a beacon type here in the info.
  ///
  let beaconType: BeaconType

  ///
  /// The raw beaconID data. This is typically printed out in hex format.
  ///
  let beaconID: [UInt8]

  private init(beaconType: BeaconType!, beaconID: [UInt8]) {
    self.beaconID = beaconID
    self.beaconType = beaconType
  }

  override var description: String {
    if self.beaconType == BeaconType.Eddystone {
      let hexid = hexBeaconID(self.beaconID)
      return "BeaconID beacon: \(hexid)"
    } else {
      return "BeaconID with invalid type (\(beaconType))"
    }
  }

  private func hexBeaconID(beaconID: [UInt8]) -> String {
    var retval = ""
    for byte in beaconID {
      var s = String(byte, radix:16, uppercase: false)
      if s.characters.count == 1 {
        s = "0" + s
      }
      retval += s
    }
    return retval
  }

}

func ==(lhs: BeaconID, rhs: BeaconID) -> Bool {
  if lhs == rhs {
    return true;
  } else if lhs.beaconType == rhs.beaconType
    && rhs.beaconID == rhs.beaconID {
      return true;
  }

  return false;
}

///
/// BeaconInfo
///
/// Contains information fully describing a beacon, including its beaconID, transmission power,
/// RSSI, and possibly telemetry information.
///
class BeaconInfo : NSObject {

  static let EddystoneUIDFrameTypeID: UInt8 = 0x00
  static let EddystoneURLFrameTypeID: UInt8 = 0x10
  static let EddystoneTLMFrameTypeID: UInt8 = 0x20

  enum EddystoneFrameType {
    case UnknownFrameType
    case UIDFrameType
    case URLFrameType
    case TelemetryFrameType

    var description: String {
      switch self {
      case .UnknownFrameType:
        return "Unknown Frame Type"
      case .UIDFrameType:
        return "UID Frame"
      case .URLFrameType:
        return "URL Frame"
      case .TelemetryFrameType:
        return "TLM Frame"
      }
    }
  }

  let beaconID: BeaconID?
  let txPower: Int
  let RSSI: Int
  let telemetry: NSData?
    let tempValue:Float
    let batteryValue:Int
    
  let beaconUrl: String?
    let frameType: EddystoneFrameType
    

    private init(beaconID: BeaconID?, txPower: Int, RSSI: Int, telemetry: NSData?, beaconUrl:String,frameType:EddystoneFrameType) {
    self.beaconID = beaconID!
    self.txPower = txPower
    self.RSSI = RSSI
    self.tempValue = 0
    self.batteryValue = 0
    self.telemetry = telemetry
    self.beaconUrl = beaconUrl
    self.frameType = frameType

  }
    private init(tempVal:Float, batteryVal:Int, telemetry: NSData? ,frameType:EddystoneFrameType) {
        self.beaconID = nil
        self.txPower=0
        self.RSSI=0
        self.telemetry = telemetry
        self.beaconUrl = nil
        self.tempValue = tempVal
        self.batteryValue = batteryVal
        self.frameType = frameType
        
    }


  class func frameTypeForFrame(advertisementFrameList: [NSObject : AnyObject])
    -> EddystoneFrameType {
        let uuid = CBUUID(string: "FEAA")
    if let frameData = advertisementFrameList[uuid] as? NSData {
      if frameData.length > 1 {
        let count = frameData.length
        var frameBytes = [UInt8](count: count, repeatedValue: 0)
        frameData.getBytes(&frameBytes, length: count)

        if frameBytes[0] == EddystoneUIDFrameTypeID {
          return EddystoneFrameType.UIDFrameType
        }else if frameBytes[0] == EddystoneURLFrameTypeID {
            return EddystoneFrameType.URLFrameType
        } else if frameBytes[0] == EddystoneTLMFrameTypeID {
          return EddystoneFrameType.TelemetryFrameType
        }
      }
    }

    return EddystoneFrameType.UnknownFrameType
  }

  class func telemetryDataForFrame(advertisementFrameList: [NSObject : AnyObject]!) -> NSData? {
    return advertisementFrameList[CBUUID(string: "FEAA")] as? NSData
  }

  ///
  /// Unfortunately, this can't be a failable convenience initialiser just yet because of a "bug"
  /// in the Swift compiler — it can't tear-down partially initialised objects, so we'll have to 
  /// wait until this gets fixed. For now, class method will do.
  ///
    class func beaconInfoForUIDFrameData(frameData: NSData, telemetry: NSData?, RSSI: Int)
        -> BeaconInfo? {
            if frameData.length > 1 {
                let count = frameData.length
                var frameBytes = [UInt8](count: count, repeatedValue: 0)
                frameData.getBytes(&frameBytes, length: count)
                
                if frameBytes[0] != EddystoneUIDFrameTypeID {
                    NSLog("Unexpected non UID Frame passed to BeaconInfoForUIDFrameData.")
                    return nil
                } else if frameBytes.count < 18 {
                    NSLog("Frame Data for UID Frame unexpectedly truncated in BeaconInfoForUIDFrameData.")
                }
                
                let txPower = Int(Int8(bitPattern:frameBytes[1]))
                let beaconID: [UInt8] = Array(frameBytes[2..<18])
                let bid = BeaconID(beaconType: BeaconID.BeaconType.Eddystone, beaconID: beaconID)
                return BeaconInfo(beaconID: bid, txPower: txPower, RSSI: RSSI, telemetry: telemetry,beaconUrl: String(),frameType: EddystoneFrameType.UIDFrameType)
            }
            
            return nil
    }

    class func beaconInfoForTLMFrameData(frameData: NSData, telemetry: NSData?, RSSI: Int)
        -> BeaconInfo? {
            if frameData.length > 1 {
                let count = frameData.length
                var frameBytes = [UInt8](count: count, repeatedValue: 0)
                frameData.getBytes(&frameBytes, length: count)
                
                if frameBytes[0] != EddystoneTLMFrameTypeID {
                    NSLog("Unexpected non TLM Frame passed to BeaconInfoForTLMFrameData.")
                    return nil
                }
//                else if frameBytes.count < 18 {
//                    NSLog("Frame Data for UID Frame unexpectedly truncated in BeaconInfoForUIDFrameData.")
//                }
                
                let version = Int(Int8(bitPattern:frameBytes[1]))
                
                
                let batteryalV:Int = Int(frameBytes[2])*256+Int(frameBytes[3])
                
//                let tempVal:Double = Double(Int(frameBytes[4]))
                let tempVal:Float = Float(Int(frameBytes[4])*256>>8)+Float(frameBytes[5])/256.0

                
                
                
                
                
                return BeaconInfo(tempVal: tempVal, batteryVal: batteryalV, telemetry: telemetry, frameType: EddystoneFrameType.TelemetryFrameType)
            }
            
            return nil
    }
    
    
    class func beaconInfoForURLFrameData(frameData: NSData, telemetry: NSData?, RSSI: Int)
        -> BeaconInfo? {
/*
            0	Frame Type	Value = 0x10
            1	TX Power	Calibrated Tx power at 0 m
            2	URL Scheme	Encoded Scheme Prefix
            3+	Encoded URL	Length 0-17
*/
            if frameData.length > 1 {
                let count = frameData.length
                var frameBytes = [UInt8](count: count, repeatedValue: 0)
                frameData.getBytes(&frameBytes, length: count)
                var urlString = String()
                
                if frameBytes[0] != EddystoneURLFrameTypeID {
                    NSLog("Unexpected non URL Frame passed to BeaconInfoForURLFrameData.")
                    return nil
                }
//                else if frameBytes.count < 18 {
//                    NSLog("Frame Data for UID Frame unexpectedly truncated in BeaconInfoForUIDFrameData.")
//                }
                
                let txPower = Int(Int8(bitPattern:frameBytes[1]))
                let urlScheme = Int8(bitPattern: frameBytes[2])
                
                switch urlScheme{
                case 0:
                    urlString += "http://www."
                case 1:
                    urlString += "https://www."
                case 2:
                    urlString += "http://"
                case 3:
                    urlString += "https://"
                default:
                    break
                }
//                let url:String = 
//                let bid = BeaconID(beaconType: BeaconID.BeaconType.Eddystone, beaconID: beaconID)
                let urlArray = frameBytes[3...count-1]
                
                for i in urlArray{
                    urlString.append(UnicodeScalar(i))
                }
                let bid = BeaconID(beaconType: BeaconID.BeaconType.Eddystone, beaconID: [])
                return BeaconInfo(beaconID: bid, txPower: txPower, RSSI: RSSI, telemetry: telemetry,beaconUrl:urlString,frameType:EddystoneFrameType.URLFrameType)
            }
            
            return nil
    }

  override var description: String {
    if self.frameType == EddystoneFrameType.UIDFrameType{
        return "Eddystone \(self.beaconID), txPower: \(self.txPower), RSSI: \(self.RSSI)"
    }else if self.frameType == EddystoneFrameType.TelemetryFrameType{
        return "Eddystone 溫度：\(self.tempValue) 電量:\(self.batteryValue)"
    }else{
        return "Eddystone URL:\(self.beaconUrl)"
    }
    
  }

}

