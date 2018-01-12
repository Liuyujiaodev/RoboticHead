//
//  ViewController.swift
//  RemoteRoboticHead
//
//  Created by QiaoWu on 2018/1/11.
//  Copyright © 2018年 EXdoll. All rights reserved.
//

import UIKit
//蓝牙
import CoreBluetooth



class ViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, CBCentralManagerDelegate, CBPeripheralDelegate {
    
    @IBOutlet weak var textBTstatus: UILabel!
    @IBOutlet weak var btTableView: UITableView!
    
    //蓝牙属性，IOS蓝牙到底怎么用的？//
    //蓝牙管理器？
    var manager: CBCentralManager!
    //蓝牙设备？
    var peripheral: CBPeripheral!
    //发送蓝牙的特征？
    var writeCharacteristic: CBCharacteristic!
    
    //保存收到的蓝牙设备数组
    var deviceList:NSMutableArray = NSMutableArray()
    //选择蓝牙计数用的
    var selectCell:Int = 0
    var blnumber = 0
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        Thread.sleep(forTimeInterval: 1.0) //延迟一小会
        
        self.textBTstatus.text = "data status info"
        
        //蓝牙 1. 创建一个蓝牙中央管理对象？
        self.manager = CBCentralManager(delegate: self, queue: nil)
        
    }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK - TableView
    
    //蓝牙列表UI
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        //返回蓝牙列表的数量
        return self.deviceList.count>0 ? self.deviceList.count : 1
    }
    //蓝牙列表UI
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .default, reuseIdentifier: "BlueTCells")
        if(blnumber>0){
            let device:CBPeripheral=self.deviceList.object(at: indexPath.row) as! CBPeripheral
            //列表的主标题 //测试用
            cell.textLabel?.text = "NONE"
            if (device.name != nil && device.name != "")  {
                //给列表里的项目显示一个蓝牙的名字
                cell.textLabel?.text = device.name
            }else{
                //这个部分正式使用时不需要，没有正经名字的蓝牙设备不用在列表中显示
                cell.textLabel?.text = device.identifier.uuidString
            }
        }else{
            //这个部分正式使用时不需要，没有蓝牙的话，就不显示列表
            cell.textLabel?.text="None Bluetooth"
        }
        return cell
    }
    //蓝牙列表UI
    //蓝牙列表UI //选择的蓝牙打个钩
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        for i in tableView.visibleCells {
            i.accessoryType = .none
        }
        let cell = tableView.cellForRow(at: indexPath)
        cell?.accessoryType = .checkmark
        tableView.deselectRow(at: indexPath, animated: true)
        //当前选择的蓝牙
        selectCell = indexPath.row
    }
    

    // MARK - BlueThooth
    
    
    //蓝牙 2检查运行这个App的设备是不是支持BLE。代理方法
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case CBManagerState.poweredOn:
            //扫描周边蓝牙外设.
            //写nil表示扫描所有蓝牙外设，如果传上面的kServiceUUID,那么只能扫描出FFEO这个服务的外设。
            //CBCentralManagerScanOptionAllowDuplicatesKey为true表示允许扫到重名，false表示不扫描重名的。
            self.manager.scanForPeripherals(withServices: nil, options: [CBCentralManagerScanOptionAllowDuplicatesKey:false])
            self.textBTstatus.text = "蓝牙已打开扫描设备"
        case CBManagerState.unauthorized:
            self.textBTstatus.text = "这个应用程序是无权使用蓝牙低功耗"
        case CBManagerState.poweredOff:
            self.textBTstatus.text = "蓝牙目前已关闭"
        default:
            self.textBTstatus.text = "蓝牙不知道什么错误"
        }
    }
    //蓝牙 3.查到外设后，停止扫描，连接设备
    //广播、扫描的响应数据保存在advertisementData 中，可以通过CBAdvertisementData 来访问它。
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        if(!self.deviceList.contains(peripheral)){
            self.deviceList.add(peripheral)
            print("find bt : \(String(describing: peripheral.name))")
        }
        self.btTableView.reloadData()
        self.blnumber += 1
        self.textBTstatus.text = "蓝牙: \(self.deviceList.count)"
    }
    //蓝牙 4.连接蓝牙设备成功，开始找设备蓝牙服务
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        //停止扫描外设
        self.manager.stopScan()
        self.peripheral = peripheral
        self.peripheral.delegate = self
        self.peripheral.discoverServices(nil)
        self.textBTstatus.text = "已经链接： \(self.peripheral.name ?? "none")"
    }
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        self.textBTstatus.text = "链接端口错误：\(error.debugDescription)"
    }
    
    //5.请求周边去寻找它的服务所列出的特征
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        if(error != nil){
            self.textBTstatus.text = "服务特征错误1：\(error?.localizedDescription ?? "none")"
            return
        }
        for service in peripheral.services!{
            self.textBTstatus.text = "UUID:\(service.uuid)"
            peripheral.discoverCharacteristics(nil, for: service)
        }
    }
    
    //6.已搜索到Characteristics
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        if(error != nil){
            self.textBTstatus.text = "发现特征错误2:\(error?.localizedDescription ?? "none")"
            return
        }
        //罗列出所有特性，看哪些是notify方式的，哪些是read方式的，哪些是可写入的。
        for cht in service.characteristics! {
            if(cht.uuid.uuidString == "FFE1"){
                //如果以通知的形式读取数据，则直接发到didUpdateValueForCharacteristic方法处理数据。
                self.peripheral.setNotifyValue(true, for: cht)
                self.textBTstatus.text = "发送UUID FFE1"
                self.writeCharacteristic = cht
            }
            if(cht.uuid.uuidString == "FFE3"){
                self.textBTstatus.text = "发送UUID FFE3"
                self.writeCharacteristic = cht
            }
        }
        
    }
    
    //8.获取外设发来的数据，不论是read和notify,获取数据都是从这个方法中读取。2AF1
    func peripheral(_ peripheral: CBPeripheral, didUpdateNotificationStateFor characteristic: CBCharacteristic, error: Error?) {
        if(error != nil){
            self.textBTstatus.text = "发现特征错误2:\(error?.localizedDescription ?? "none")"
            return
        }
        if(characteristic.uuid.description == "FFE1" || characteristic.uuid.description == "2AF1"){
            self.textBTstatus.text = "特征发来的:\(String(describing: characteristic.descriptors))"
            //print("特征发来的:\(String(describing: characteristic.descriptors))")
            //实际跳转测试
            //self.performSegue(withIdentifier: "showmovepage", sender: self)
        }else{
            self.textBTstatus.text = "特征发来不明"
        }
    }

}

