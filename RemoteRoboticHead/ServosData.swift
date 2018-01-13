//
//  ServosData.swift
//  RemoteRoboticHead
//
//  Created by QiaoWu on 2018/1/13.
//  Copyright © 2018年 EXdoll. All rights reserved.
//

import Foundation
import UIKit
import CoreBluetooth

//蓝牙
var dataperipheral: CBPeripheral!
var datawriteCharacteristic: CBCharacteristic!

//蓝牙传输用，待测试看能否使用全局变量
//写入数据
public func writeToPeripheral(bytes:[UInt8]) {
    if datawriteCharacteristic != nil {
        let data:NSData = dataWithHexstring(bytes: bytes)
        dataperipheral!.writeValue(data as Data, for: datawriteCharacteristic!, type: .withoutResponse)
        print("输出 \(bytes)")
    } else{
        print("无法发送数据")
    }
}
//数组换算
func dataWithHexstring(bytes:[UInt8]) -> NSData {
    let data = NSData(bytes: bytes, length: bytes.count)
    return data
}

//电动机数据
struct Servos {
    var name:String
    var currentAngle:Int
    var minA:Int
    var maxA:Int
}
//设备屏幕尺寸
public let SCREEN_WIDTH=UIScreen.main.bounds.size.width
public let SCREEN_HEIGHT=UIScreen.main.bounds.size.height

//获取视图尺寸
public func VIEW_WIDTH(view:UIView)->CGFloat{
    return view.frame.size.width
}
public func VIEW_HEIGHT(view:UIView)->CGFloat{
    return view.frame.size.height
}

//蓝牙传输数据21
var blueData = [90,90,90,90,90,90,90,90,90,90,90,90,90,90,90,90,90,90,90,90,90]
//滑动块用列表数据
var servosData = [
    Servos(name: "左侧眉毛", currentAngle: 90, minA: 20, maxA: 160),
    Servos(name: "右侧眉毛", currentAngle: 90, minA: 20, maxA: 160),
    Servos(name: "眼睛左右", currentAngle: 90, minA: 10, maxA: 170),
    Servos(name: "眼睛上下", currentAngle: 90, minA: 10, maxA: 170),
    Servos(name: "左上眼皮", currentAngle: 90, minA: 20, maxA: 160),
    Servos(name: "右上眼皮", currentAngle: 90, minA: 20, maxA: 160),
    Servos(name: "左下眼皮", currentAngle: 90, minA: 20, maxA: 160),
    Servos(name: "右下眼皮", currentAngle: 90, minA: 20, maxA: 160),
    Servos(name: "左唇上下", currentAngle: 90, minA: 20, maxA: 160),
    Servos(name: "右唇上下", currentAngle: 90, minA: 20, maxA: 160),
    Servos(name: "左唇前后", currentAngle: 90, minA: 20, maxA: 160),
    Servos(name: "右唇前后", currentAngle: 90, minA: 20, maxA: 160),
    Servos(name: "嘴部张合", currentAngle: 90, minA: 10, maxA: 170),
    Servos(name: "头部旋转", currentAngle: 90, minA: 40, maxA: 140),
    Servos(name: "头部前后", currentAngle: 90, minA: 40, maxA: 140),
    Servos(name: "头部左右", currentAngle: 90, minA: 40, maxA: 140),
    Servos(name: "左肩上下", currentAngle: 90, minA: 40, maxA: 140),
    Servos(name: "右肩上下", currentAngle: 90, minA: 40, maxA: 140),
    Servos(name: "左肩前后", currentAngle: 90, minA: 40, maxA: 140),
    Servos(name: "右肩前后", currentAngle: 90, minA: 40, maxA: 140),
    Servos(name: "呼吸频率", currentAngle: 90, minA: 10, maxA: 170)
]

