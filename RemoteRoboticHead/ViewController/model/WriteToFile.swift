//
//  WriteToFile.swift
//  RemoteRoboticHead
//
//  Created by 刘玉娇 on 2018/1/19.
//  Copyright © 2018年 EXdoll. All rights reserved.
//

import Foundation

@objc class FileUtil : NSObject {
    let fileManager = FileManager.default
    let basePath = NSHomeDirectory() + "/Documents/action/"//存放表情的根目录

    //储存数据文件
    @objc public func saveFile(fileName: String, data:NSArray) {
        if !fileManager.fileExists(atPath: basePath) {
           try! fileManager.createDirectory(atPath: basePath, withIntermediateDirectories: true, attributes: nil)
        }
        let filePath = basePath + fileName
        data.write(toFile: filePath, atomically: true)
    }
    
    //拿到文件的列表，返回文件的名字
    @objc public func getFileList()->NSArray {
        var array : NSArray? = nil
        array = try? fileManager.contentsOfDirectory(atPath: basePath) as NSArray
        if (array != nil) {
            return array!
        }
        return []
    }
    
    //拿到文件的数据，及发送蓝牙的数据
    @objc public func getFileData(fileName: String)->NSArray {
        let filePath = basePath + fileName
        let array = NSArray(contentsOfFile:filePath)
        return array!
    }

    //删除文件
    public func removeFile(fileName: String) {
        let filePath = basePath + fileName
        try! fileManager.removeItem(atPath: filePath)
    }
}


