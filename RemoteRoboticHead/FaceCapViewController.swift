//
//  FaceCapViewController.swift
//  RemoteRoboticHead
//
//  Created by QiaoWu on 2018/1/12.
//  Copyright © 2018年 EXdoll. All rights reserved.
//

import UIKit
import CoreBluetooth

class FaceCapViewController: UIViewController {
    
    //用于蓝牙输出的
    var peripheral: CBPeripheral?
    var writeCharacteristic: CBCharacteristic?
    //显示当前状态的文字框
    @IBOutlet weak var showText: UILabel!
    //用于拖拽的一个标记点，计算坐标，并一起输出到数组中 //可以拖拽 //这个标记点位于显示最上层
    @IBOutlet weak var dragBtn: UIView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        //拖拽标记点的，用不上
        //self.dragBtn.addGestureRecognizer(UIPanGestureRecognizer(target: self, action: #selector(dragMoving(pan:))))
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    
    //拖动一个屏幕上的坐标点，用于得到这个点的位置坐标比值，这个坐标点是一个控制器，他的坐标位置比例和数组一起用蓝牙输出 //初始角度 x:90，y:90
    @IBAction func dragPintMove(_ sender: UIPanGestureRecognizer) {
        let point = sender.translation(in: view)
        sender.view?.center = CGPoint(x: sender.view!.center.x + point.x, y: sender.view!.center.y + point.y)
        sender.setTranslation(.zero, in: view)
        
        print(sender.view?.center ?? "none")
    }
    
    
    // pan手势事件
    
    /*
     @IBAction func dragepin(_ sender: UIPanGestureRecognizer) {
     
     let point = sender.translation(in: view)
     sender.view?.center = CGPoint(x: sender.view!.center.x + point.x, y: sender.view!.center.y + point.y)
     sender.setTranslation(.zero, in: view)
     print(sender.view?.center ?? "none")
     
     }*/
    
    /*@objc func dragMoving(pan: UIPanGestureRecognizer){
     
     let point = pan.translation(in: view)
     
     if pan.state == .began {
     
     pan.view?.alpha = 0.8
     
     }
     
     pan.view?.center = CGPoint(x: pan.view!.center.x + point.x, y: pan.view!.center.y + point.y)
     
     pan.setTranslation(.zero, in: view)
     */
    
    /*if pan.state == .ended {
     
     if let v = pan.view{
     
     // 计算 当前view 距离屏幕上下左右的距离
     
     let top = v.frame.minY ; let left = v.frame.minX ; v.alpha = 1
     
     let bottom = view.frame.height - v.frame.maxY - 49
     
     let right = KW-v.frame.maxX
     
     // 计算出 view 距离屏幕边缘距离的最小值
     
     let temp = [top,left,bottom,right].sorted().first
     
     // 平移动画
     
     UIView.animate(withDuration: 0.3, delay: 0.3, usingSpringWithDamping: 1, initialSpringVelocity: 1, options: .curveEaseInOut, animations: {
     
     if temp == top{
     
     v.transform = v.transform.translatedBy(x: 0, y: -top)
     
     }else if temp == left{
     
     v.transform = v.transform.translatedBy(x: -left, y: 0)
     
     }else if temp == bottom{
     
     v.transform = v.transform.translatedBy(x: 0, y: bottom)
     
     }else{
     
     v.transform = v.transform.translatedBy(x: right, y: 0)
     
     }
     
     }, completion: { (finish) in
     
     
     
     })
     
     }
     
     }
     
     }*/
    
    
    
    // 点手势 事件处理
    
    /*@objc func tap(tap: UITapGestureRecognizer){
     
     print("tap")
     
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
