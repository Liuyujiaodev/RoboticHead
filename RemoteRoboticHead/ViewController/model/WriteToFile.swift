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

    @objc public func saveFile(fileName: String, data:NSArray) {
        // 储存的沙盒路径
        
        let basePath = NSHomeDirectory() + "/Documents/action/"
        if !fileManager.fileExists(atPath: basePath) {
           try! fileManager.createDirectory(atPath: basePath, withIntermediateDirectories: true, attributes: nil)
        }
        let filePath = basePath + fileName
        data.write(toFile: filePath, atomically: true)
}
    
    @objc public func getFileList()->NSArray {
        let basePath =  NSHomeDirectory() + "/Documents/action/"
        var array : NSArray? = nil
        do {
            array = try? fileManager.contentsOfDirectory(atPath: basePath) as! NSArray
        } catch let error as NSError {
            print("get file path error: \(error)")
        }
        return array!
    }
    
    @objc public func getFileData(fileName: String)->NSArray {
        let basePath = NSHomeDirectory() + "/Documents/action/"
        let filePath = basePath + fileName
        let array = NSArray(contentsOfFile:filePath)
        
        return array!
    }

}


