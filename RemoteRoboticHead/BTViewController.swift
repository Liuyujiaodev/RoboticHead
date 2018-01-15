//
//  BLViewController.swift
//  RemoteRoboticHead
//
//  Created by QiaoWu on 2017/12/6.
//  Copyright © 2017年 EXdoll. All rights reserved.
//

import UIKit
//蓝牙
import CoreBluetooth


class BTViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, CBCentralManagerDelegate, CBPeripheralDelegate  {
    
    //显示状态的文字框
    @IBOutlet weak var showText: UILabel!
    //蓝牙的列表
    @IBOutlet weak var blTableView: UITableView!
    //确认链接蓝牙的按钮
    @IBOutlet weak var linbtn: UIButton!
    @IBOutlet weak var goFaceCapBtn: UIButton!
    @IBOutlet weak var goControlBtn: UIButton!
    //蓝牙用的属性
    var manager: CBCentralManager!
    var peripheral: CBPeripheral!
    var writeCharacteristic: CBCharacteristic!
    //保存收到的蓝牙设备
    var deviceList:NSMutableArray = NSMutableArray()
    
    //服务和特征的UUID 没用上
    //let kServiceUUID = [CBUUID(string: "FFE0")] //不起作用
    //let kCharacteristicUUID = [CBUUID(string:"FFE1")] //不起作用

    //蓝牙计数
    var selectCell:Int = 0
    var blnumber = 0
    var bluetoothActive:Bool = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        //启动延迟1秒
        Thread.sleep(forTimeInterval: 1.0)
        //停止按键功能
        self.linbtn.isEnabled=false
        self.goControlBtn.isEnabled=false
        self.goFaceCapBtn.isEnabled=false
        self.goControlBtn.backgroundColor=UIColor.lightGray
        self.goFaceCapBtn.backgroundColor=UIColor.lightGray
        self.linbtn.backgroundColor=UIColor.lightGray
        
        //蓝牙 1.创建一个蓝牙中央控制对象
        self.manager = CBCentralManager(delegate: self, queue: nil)
    }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    // MARK: - tableView
    
    //蓝牙列表数量
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        //蓝牙列表数量，没有蓝牙的话返回一个测试用
        return self.deviceList.count>0 ? self.deviceList.count : 1
    }
    //蓝牙列表
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .default, reuseIdentifier: "BlueTCells")
        if(blnumber>0){
            let device:CBPeripheral=self.deviceList.object(at: indexPath.row) as! CBPeripheral
            //蓝牙列表CELL主标题就写个蓝牙名称
            cell.textLabel?.text = "NONE"
            if(indexPath.row != self.selectCell){
                cell.accessoryType = .none
            }
            if (device.name != nil && device.name != "")  {
                cell.textLabel?.text = device.name
            }else{
                //测试用，之后没有名称的蓝牙不用显示
                cell.textLabel?.text = device.identifier.uuidString
            }
        }else{
            //测试用，没有蓝牙的时候凑数1个
            cell.textLabel?.text="None Bluetooth"
        }
        return cell
    }
    //蓝牙列表选项
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        for i in tableView.visibleCells {
            i.accessoryType = .none
        }
        let cell = tableView.cellForRow(at: indexPath)
        //选中的蓝牙打个钩 //是否需要写取消其他的钩
        cell?.accessoryType = .checkmark
        tableView.deselectRow(at: indexPath, animated: true)
        //选择的蓝牙是哪个
        self.selectCell = indexPath.row
        self.showText.text = "选择蓝牙设备：\(cell!.textLabel!.text ?? "NONE")"
        //启动蓝牙按钮
        self.linbtn.isEnabled=true
        self.linbtn.backgroundColor=UIColor(red: 55/255, green: 177/255, blue: 1, alpha: 1)
    }
    
    
    
    // MARK: - BlueThooth
    
    //蓝牙 2. 检查运行这个App的设备是不是支持BLE。开始扫描蓝牙设备
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case CBManagerState.poweredOn:
            //扫描周边蓝牙外设:scanForPeripherals
            //withServices写nil表示扫描所有蓝牙外设，如果传上面的FFEO,那么只能扫描出FFEO这个服务的外设。
            //CBCentralManagerScanOptionAllowDuplicatesKey为true表示允许扫到重名，false表示不扫描重名的。
            self.manager.scanForPeripherals(withServices: nil, options: [CBCentralManagerScanOptionAllowDuplicatesKey:false])
            self.showText.text = "蓝牙已打开扫描设备"
        case CBManagerState.unauthorized:
            self.showText.text = "这个应用程序是无权使用蓝牙"
        case CBManagerState.poweredOff:
            self.showText.text = "蓝牙目前关闭"
        default:
            self.showText.text = "蓝牙不错误无法使用"
        }
    }
    
    //蓝牙 3.查到外设，更新列表
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        //广播、扫描的响应数据保存在advertisementData 中，可以通过CBAdvertisementData 来访问它。
        if(!self.deviceList.contains(peripheral)){
            //把扫描到的蓝牙保存到数组里
            self.deviceList.add(peripheral)
        }
        //更新蓝牙列表 //这里需要改进，更新完成之前按钮不能点击
        self.blTableView.reloadData()
        self.blnumber += 1
        self.showText.text = "发现蓝牙设备: \(self.deviceList.count)个"
    }
    
   //蓝牙 4.连接外设成功，停止扫描，开始发现服务
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        //停止扫描外设
        self.manager.stopScan()
        self.peripheral = peripheral
        self.peripheral.delegate = self
        self.peripheral.discoverServices(nil)
        self.showText.text = "已经链接： \(self.peripheral.name ?? "none")"
        //全局变量？待测试
        dataperipheral = self.peripheral
    }
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        self.showText.text = "链接端口错误：\(error.debugDescription)"
    }
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        self.showText.text = "蓝牙连接上端口"
    }

    //蓝牙 5.请求蓝牙设备周边去寻找它的服务所列出的特征
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        if(error != nil){
            self.showText.text = "发现服务错误：\(error?.localizedDescription ?? "none")"
            return
        }
        for service in peripheral.services!{
            self.showText.text = "查找服务特征UUID:\(service.uuid)"
            //测试新的
            peripheral.discoverCharacteristics(nil, for: service)
            //测试只搜索serviceuuid ffe0的
            /*if (service.uuid == CBUUID(string: "FFE0")) {
                peripheral.discoverCharacteristics(nil, for: service as CBService)
            }*/
        }
    }
    
    //蓝牙 6.已搜索到Characteristics
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        if(error != nil){
            showText.text = "发现特征错误1:\(error?.localizedDescription ?? "none")"
            return
        }
        //罗列出所有特性，看哪些是notify方式的，哪些是read方式的，哪些是可写入的。付值给蓝牙特征
        for cht in service.characteristics! {
            if(cht.uuid.uuidString == "FFE1"){
                //如果以通知的形式读取数据，则直接发到didUpdateValueForCharacteristic方法处理数据。
                self.peripheral.setNotifyValue(true, for: cht)
                self.showText.text = "当前特征UUID FFE1"
                self.writeCharacteristic = cht
                //全局变量?
                datawriteCharacteristic = cht
            }
            if(cht.uuid.uuidString == "FFE3"){
                self.showText.text = "当前特征UUID FFE3"
                self.writeCharacteristic = cht
                //全局变量?
                datawriteCharacteristic = cht
            }
            //下面2个基本没用，测试后可以删除？
            if(cht.uuid.uuidString == "2A37"){
                //通知关闭，read方式接受数据。则先发送到didUpdateNotificationStateForCharacteristic方法，再通过readValueForCharacteristic发到didUpdateValueForCharacteristic方法处理数据。
                self.peripheral.readValue(for: cht as CBCharacteristic)
            }
            if(cht.uuid.uuidString == "2A38"){
                self.peripheral.readValue(for: cht as CBCharacteristic)
            }
        }
        
    }
    
    //蓝牙 8.获取外设发来的数据，不论是read和notify,获取数据都是从这个方法中读取。//待测试是否需要
    func peripheral(_ peripheral: CBPeripheral, didUpdateNotificationStateFor characteristic: CBCharacteristic, error: Error?) {
        if(error != nil){
            self.showText.text = "发现特征错误2:\(error?.localizedDescription ?? "none")"
            return
        }
        if(characteristic.uuid.description == "FFE1" || characteristic.uuid.uuidString == "FFE1" || characteristic.uuid.description == "2AF1" || characteristic.uuid.uuidString == "2AF1"){
            self.showText.text = "完成特征发来的:\(String(describing: characteristic.uuid.uuidString))"
            //蓝牙成功，启动按钮
            //测试时候关闭
            //self.btnActive()
        }else{
            self.showText.text = "蓝牙特征发来不明"
        }
    }
    
    /*/蓝牙 是否发送成功
    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        if(error != nil){
            print("发送数据失败")
        }else{
            print("发送数据成功")
        }
    }*/
    
    
    // MARK: - changeStage
    
    
    //点击链接bt
    @IBAction func clicklin(_ sender: UIButton) {
        //取消按钮，防止误触
        self.showText.text = "点击链接蓝牙"
        self.linbtn.isEnabled=false
        self.linbtn.backgroundColor=UIColor.darkGray
        self.linbtn.setTitle("正在尝试连接", for:.normal)
        //开始尝试连接蓝牙
        if(self.deviceList.count>0){
            self.peripheral = self.deviceList.object(at: self.selectCell) as! CBPeripheral
            self.showText.text = "开始尝试链接:\(self.peripheral.name ?? "none")"
            //连接蓝牙
            self.manager.connect(self.peripheral, options: nil)
        }else{
            //重置按钮
            self.showText.text = "蓝牙设备错误"
            self.linbtn.isEnabled=false
            self.linbtn.backgroundColor=UIColor.lightGray
            self.linbtn.setTitle("再次选择", for: .normal)
            //测试用
            btnActive()
        }
    }
    
    //无意思的按钮点击
    @IBAction func clickFaceCapBtn(_ sender: UIButton) {
        //self.performSegue(withIdentifier: "showfacecappage", sender: self)
        self.showText.text = "跳转动作捕捉页面"
    }
    @IBAction func clickControlBtn(_ sender: UIButton) {
        //self.performSegue(withIdentifier: "showcontrolpage", sender: self)
        self.showText.text = "跳转电机控制页面"
    }
    
    //按钮起动
    func btnActive() -> (){
        self.linbtn.setTitle("连接完成", for:.normal)
        self.goFaceCapBtn.isEnabled = true
        self.goControlBtn.isEnabled = true;
        self.goFaceCapBtn.backgroundColor=UIColor(red: 55/255, green: 177/255, blue: 1, alpha: 1)
        self.goControlBtn.backgroundColor=UIColor(red: 55/255, green: 177/255, blue: 1, alpha: 1)
    }
    
    
    
    //转场 ?待测试全局函数，目前不需要
    /*override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if(segue.identifier=="showfacecappage"){
            let fcontroller = segue.destination as! FaceCapViewController
            fcontroller.peripheral = self.peripheral
            fcontroller.writeCharacteristic = self.writeCharacteristic
        }
        if(segue.identifier=="showcontrolpage"){
            let scontroller = segue.destination as! ControlViewController
            scontroller.peripheral = self.peripheral
            scontroller.writeCharacteristic = self.writeCharacteristic
        }
    }*/
    
    
    
    
    /*
     // MARK: - Navigation
     
     // In a storyboard-based application, you will often want to do a little preparation before navigation
     override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
     // Get the new view controller using segue.destinationViewController.
     // Pass the selected object to the new view controller.
     }
     */
    
}
