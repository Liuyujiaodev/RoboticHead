//
//  SendData.swift
//  RemoteRoboticHead
//
//  Created by 刘玉娇 on 2018/1/19.
//  Copyright © 2018年 EXdoll. All rights reserved.
//

import Foundation

@objc class SendData : NSObject {
   @objc func initServosData(array:NSArray) {
    var servosData = [
        Servos(name: "左侧眉毛", currentAngle: array[0] as! UInt8, minA: 20, maxA: 160),
        Servos(name: "右侧眉毛", currentAngle: array[1] as! UInt8, minA: 20, maxA: 160),
        Servos(name: "眼睛左右", currentAngle: array[2] as! UInt8, minA: 10, maxA: 170),
        Servos(name: "眼睛上下", currentAngle: array[3] as! UInt8, minA: 10, maxA: 170),
        Servos(name: "左上眼皮", currentAngle: array[4] as! UInt8, minA: 20, maxA: 160),
        Servos(name: "右上眼皮", currentAngle: array[5] as! UInt8, minA: 20, maxA: 160),
        Servos(name: "左下眼皮", currentAngle: array[6] as! UInt8, minA: 20, maxA: 160),
        Servos(name: "右下眼皮", currentAngle: array[7] as! UInt8, minA: 20, maxA: 160),
        Servos(name: "左唇上下", currentAngle: array[8] as! UInt8, minA: 20, maxA: 160),
        Servos(name: "右唇上下", currentAngle: array[9] as! UInt8, minA: 20, maxA: 160),
        Servos(name: "左唇前后", currentAngle: array[10] as! UInt8, minA: 20, maxA: 160),
        Servos(name: "右唇前后", currentAngle: array[11] as! UInt8, minA: 20, maxA: 160),
        Servos(name: "嘴部张合", currentAngle: array[12] as! UInt8, minA: 10, maxA: 170),
        Servos(name: "头部旋转", currentAngle: array[13] as! UInt8, minA: 40, maxA: 140),
        Servos(name: "头部前后", currentAngle: array[14] as! UInt8, minA: 40, maxA: 140),
        Servos(name: "头部左右", currentAngle: array[15] as! UInt8, minA: 40, maxA: 140),
        Servos(name: "左肩上下", currentAngle: array[16] as! UInt8, minA: 40, maxA: 140),
        Servos(name: "右肩上下", currentAngle: array[17] as! UInt8, minA: 40, maxA: 140),
        Servos(name: "左肩前后", currentAngle: array[18] as! UInt8, minA: 40, maxA: 140),
        Servos(name: "右肩前后", currentAngle: array[19] as! UInt8, minA: 40, maxA: 140),
        Servos(name: "呼吸频率", currentAngle: array[20] as! UInt8, minA: 10, maxA: 170)
    ]
    }
}


