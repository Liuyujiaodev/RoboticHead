//
//  SendData.swift
//  RemoteRoboticHead
//
//  Created by 刘玉娇 on 2018/1/19.
//  Copyright © 2018年 EXdoll. All rights reserved.
//

import Foundation

@objc class SendData : NSObject {

    @objc func writeData(array:Array<NSNumber>) {
        var outdatas:[UInt8] = [250]
        
        for data in array {
            
            outdatas.append(UInt8(data))
        }
        for _ in 0...4 {
            outdatas.append(90)
        }
        print(outdatas)
        writeToPeripheral(bytes: outdatas)
    }
    
}


