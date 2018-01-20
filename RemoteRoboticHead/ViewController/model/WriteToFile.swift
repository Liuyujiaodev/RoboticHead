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
    let basePath = NSHomeDirectory() + "/Documents/action/"

    @objc public func saveFile(fileName: String, data:NSArray) {
        // 储存的沙盒路径
        
        if !fileManager.fileExists(atPath: basePath) {
           try! fileManager.createDirectory(atPath: basePath, withIntermediateDirectories: true, attributes: nil)
        }
        let filePath = basePath + fileName
        data.write(toFile: filePath, atomically: true)
}
    
    @objc public func getFileList()->NSArray {
        var array : NSArray? = nil
        array = try? fileManager.contentsOfDirectory(atPath: basePath) as NSArray
        return array!
    }
    
    @objc public func getFileData(fileName: String)->NSArray {
        let filePath = basePath + fileName
        let array = NSArray(contentsOfFile:filePath)
        
        return array!
    }

    public func removeFile(fileName: String) {
        let filePath = basePath + fileName
        try! fileManager.removeItem(atPath: filePath)
    }
}


