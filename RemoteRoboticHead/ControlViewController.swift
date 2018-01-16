//
//  ControlViewController.swift
//  RemoteRoboticHead
//
//  Created by QiaoWu on 2018/1/13.
//  Copyright © 2018年 EXdoll. All rights reserved.
//

import UIKit
import CoreBluetooth


class ControlViewController: UIViewController,UITableViewDelegate, UITableViewDataSource{
    
    //蓝牙，待测试全局变量
    //var peripheral: CBPeripheral!
    //var writeCharacteristic: CBCharacteristic!
    //显示临时状态的文字
    @IBOutlet weak var showText: UILabel!
    //电动机列表
    @IBOutlet weak var servoList: UITableView!
    
    var currentActionName = "Action name"
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // 测试用，读取OC数据到swift
        let te = testoc.getintoc()
        self.showText.text = "测试从OC读取数据：\(te)"
        self.showText.text = "当前动作：\(currentActionName)"
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    //电动机控制列表数量 //ServosData.swift里设置了电动机数组
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return servosData.count //固定值
    }
    //按电动机数组生成列表
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "CSCells", for: indexPath) as! CSTableViewCell
        let sp = servosData[indexPath.row]
        //给列表数据付值
        cell.nameText.text = sp.name                    //固定值
        cell.angleText.text = String(sp.currentAngle)   //可变值
        cell.angleSlider.maximumValue = Float(sp.maxA)  //固定值
        cell.angleSlider.minimumValue = Float(sp.minA)  //固定值
        cell.angleSlider.value = Float(sp.currentAngle) //可变值
        //每个滑动块给一个编号，方便查找
        cell.angleSlider.tag = indexPath.row
        //滑动块添加事件 事件为onChangeOfSlider ? 这个地方是否会重复添加？
        cell.angleSlider.addTarget(self, action:#selector(ControlViewController.onChangeOfSlider(slider:)), for: UIControlEvents.valueChanged)
        return cell
    }
    //调节角度事件 //改变全局变量数组 ServosData.swift
    @objc func onChangeOfSlider(slider:UISlider) -> () {
        let index = slider.tag
        let nu = Int(slider.value)
        let cell = slider.superview?.superview?.superview as! CSTableViewCell
        cell.angleText.text = String(nu)
        servosData[index].currentAngle = UInt8(nu)
        //改变之后发送蓝牙数据 //电动机号码+注册号 和 转动角度[angle]
        let servonu = index + ServoOneAccount
        if(dataperipheral != nil){
            wirteToPeripheralOne(servonu: servonu, angle: servosData[index].currentAngle)
        }
        self.showText.text = "转动电机\(index)角度\(servosData[index].currentAngle)"
    }
    
    
    //保存当前编辑的数据
    @IBAction func saveFaceData(_ sender: UIButton) {
        if(selectAction>=actionDatas.count){
            let newAC = OneFaceAction(name: currentActionName, actionData: saveDataUpdate())
            actionDatas.append(newAC)
        }else{
            actionDatas[selectAction].name = currentActionName
            actionDatas[selectAction].actionData = saveDataUpdate()
        }
        saveActionList()
        self.showText.text = "保存动作数据:\(currentActionName)"
    }
    
    //回复初试数据
    @IBAction func defaultFaceData(_ sender: UIButton) {
        for i in 0..<20{
            servosData[i].currentAngle = 90
        }
        servoList.reloadData()
        self.showText.text = "动作数据恢复初始值"
    }
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
