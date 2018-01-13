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
    
    var peripheral: CBPeripheral!
    var writeCharacteristic: CBCharacteristic!
    //显示临时状态的文字
    @IBOutlet weak var showText: UILabel!
    //电动机列表
    @IBOutlet weak var servoList: UITableView!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // 测试用，读取OC数据到swift
        let te = testoc.getintoc()
        showText.text = "测试从OC读取数据：\(te)"
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    //电动机控制列表数量 //ServosData.swift里设置了电动机数组
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return servosData.count
    }
    //按电动机数组生成列表
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "CSCells", for: indexPath) as! CSTableViewCell
        let sp = servosData[indexPath.row]
        //给列表数据付值
        cell.nameText.text = sp.name
        cell.angleText.text = String(sp.currentAngle)
        cell.angleSlider.maximumValue = Float(sp.maxA)
        cell.angleSlider.minimumValue = Float(sp.minA)
        cell.angleSlider.value = Float(sp.currentAngle)
        //每个滑动块给一个编号，方便查找
        cell.angleSlider.tag = indexPath.row
        //滑动块添加事件 事件为onChangeOfSlider
        cell.angleSlider.addTarget(self, action:#selector(ControlViewController.onChangeOfSlider(slider:)), for: UIControlEvents.valueChanged)
        return cell
    }
    //调节角度事件 //改变全局变量数组 ServosData.swift
    @objc func onChangeOfSlider(slider:UISlider) -> () {
        let index = slider.tag
        let nu = Int(slider.value)
        let cell = slider.superview?.superview?.superview as! CSTableViewCell
        cell.angleText.text = String(nu)
        servosData[index].currentAngle = nu
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
