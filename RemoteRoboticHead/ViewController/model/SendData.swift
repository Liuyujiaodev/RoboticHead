//
//  SendData.swift
//  RemoteRoboticHead
//
//  Created by 刘玉娇 on 2018/1/19.
//  Copyright © 2018年 EXdoll. All rights reserved.
//

import Foundation

@objc class SendData : NSObject {
    //发送给蓝牙
    @objc func writeData(array:Array<NSNumber>) {
        var outdatas:[UInt8] = [250]
        
        for data in array {
            
            outdatas.append(UInt8(data))
        }
        outdatas.append(90)
        print(outdatas)
        writeToPeripheral(bytes: outdatas)
    }
    
}


