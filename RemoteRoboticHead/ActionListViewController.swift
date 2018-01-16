//
//  ActionListViewController.swift
//  RemoteRoboticHead
//
//  Created by QiaoWu on 2018/1/14.
//  Copyright © 2018年 EXdoll. All rights reserved.
//

import UIKit

class ActionListViewController: UIViewController,UITableViewDelegate, UITableViewDataSource {
    
    //临时显示文字框
    @IBOutlet weak var showText: UILabel!
    //蓝牙输入框
    @IBOutlet weak var blueTinputText: UITextField!
    override func viewDidLoad() {
        super.viewDidLoad()
        //读取储存的数据列表到全局参数 actionDatas[OneFaceAction]
        readActionList()
    }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    
    // MARK: - tableViews
    
    //表格列表数量，读取数据 //还没写
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return actionDatas.count
    }
    //列表
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .default, reuseIdentifier: "ActionCellls")
        cell.textLabel?.text = "\(actionDatas[indexPath.row].name)"
        return cell
    }
    //列表选择一个动作
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        for i in tableView.visibleCells {
            i.accessoryType = .none
        }
        let cell = tableView.cellForRow(at: indexPath)
        //选中的打个钩 //是否需要写取消其他的钩？
        cell?.accessoryType = .checkmark
        tableView.deselectRow(at: indexPath, animated: true)
        //一旦点击开始输出数据到蓝牙
        self.showText.text = "当前选择:\(actionDatas[indexPath.row].name)"
        selectAction = indexPath.row
        //待写
    }
    //列表滑动选项
    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        selectAction = indexPath.row
        //上移，下移列表并保存
        let down = UITableViewRowAction(style: .normal, title: "下移", handler: { (_, indexPath) in
            let content=actionDatas[indexPath.row]
            actionDatas.remove(at: indexPath.row)
            actionDatas.insert(content, at: indexPath.row+1)
            tableView.reloadData()
            saveActionList()
        })
        let upon = UITableViewRowAction(style: .normal, title: "上移", handler: { (_, indexPath) in
            let content=actionDatas[indexPath.row]
            actionDatas.remove(at: indexPath.row)
            actionDatas.insert(content, at: indexPath.row-1)
            tableView.reloadData()
            saveActionList()
        })
        let edit = UITableViewRowAction(style: .normal, title: "编辑") { (_, indexPath) in
            //跳转到编辑页面  //跳转需要携带数据
            self.performSegue(withIdentifier: "showcontrolpage", sender: self)
        }
        let delect = UITableViewRowAction(style: .default, title: "删除") { (_, indexPath) in
            //删除确认对话框
            let alertbar = UIAlertController(title: "删除动作", message: "确认是否删除动作数组", preferredStyle: .actionSheet)
            //确定删除
            let okbtn = UIAlertAction(title: "确认", style: .default, handler: { (_) in
                //从数组和列表中移除
                actionDatas.remove(at: indexPath.row)
                tableView.deleteRows(at: [indexPath], with: .fade)
                saveActionList()
            })
            let nobtn = UIAlertAction(title: "取消", style: .cancel, handler: nil)
            alertbar.addAction(okbtn)
            alertbar.addAction(nobtn)
            //提交选项框
            self.present(alertbar, animated: true, completion: nil)
        }
        edit.backgroundColor = UIColor.blue
        delect.backgroundColor = UIColor.red
        down.backgroundColor = UIColor.brown
        upon.backgroundColor = UIColor.darkGray
        //检查上下移动cell是否超出数组
        var editbtns = [edit,delect]
        if(selectAction<actionDatas.count-1){
            editbtns.append(down)
        }
        if(selectAction>0){
            editbtns.append(upon)
        }
        return editbtns
    }
    
    
   // MARK: - stageChange
    
    @IBAction func creatNewActionClick(_ sender: UIButton) {
        var inputText:UITextField = UITextField();
        let msgAlertCtr = UIAlertController.init(title: "新建表情", message: "请输入新表情名称", preferredStyle: .alert)
        let ok = UIAlertAction.init(title: "确定", style:.default) { (action:UIAlertAction) ->() in
            if((inputText.text) != ""){
                //添加新的表情
                for i in 0...20 {
                    servosData[i].currentAngle = actionDatas[selectAction].actionData[i]
                }
                let nm = inputText.text //"新表情"+String(actionDatas.count)
                let lt = saveDataUpdate()
                let newAction = OneFaceAction(name: nm!, actionData: lt)
                actionDatas.append(newAction)
                //跳转到编辑页面  //跳转需要携带数据
                self.performSegue(withIdentifier: "makenewactionpage", sender: self)
            }else{
                self.self.showText.text = "输入名称错误"
            }
        }
        let cancel = UIAlertAction.init(title: "取消", style:.cancel) { (action:UIAlertAction) -> ()in
            self.self.showText.text = "取消新表情"
        }
        msgAlertCtr.addAction(ok)
        msgAlertCtr.addAction(cancel)
        //添加textField输入框
        msgAlertCtr.addTextField { (textField) in
            //设置传入的textField为初始化UITextField
            inputText = textField
            inputText.placeholder = "新表情"+String(actionDatas.count+1)
        }
        //设置到当前视图
        self.present(msgAlertCtr, animated: true, completion: nil)
    }
    
    //单独发送数据到蓝牙
    @IBAction func sendingTextToBTClick(_ sender: UIButton) {
        let ptxt = self.blueTinputText.text
        //以空格键分割数据 发送数组
        let listxt = ptxt?.components(separatedBy: " ")
        var datat:[UInt8] = []
        if(listxt!.count>1){
            for v in listxt! {
                //如果数值大于255 或是文字 为0
                var st = (v as NSString).intValue
                if(st>255){
                    st = 255
                }
                let temp = UInt8(st)
                datat.append(temp)
            }
            if(datat.count>0){
                //发送蓝牙数据
                writeToPeripheral(bytes: datat)
                showText.text = "发送了蓝牙数据\(listxt!.count)"
            }else{
                showText.text = "无法蓝牙数据"
            }
        }else{
            showText.text = "无法蓝牙数据"
        }
    }
    
    //转场
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        //一次测试 保存名称数组和二维数据数组
        /*actionNameList = []
        actionAngleList = []
        for r in 0...5 {
            actionNameList.append(actionDatas[r].name)
            actionAngleList.append(actionDatas[r].actionData)
        }
        saveActionList()*/
        if(segue.identifier=="showcontrolpage"){
            //编辑动作时，传递数组数据,给全局数组servosData付值当前选中的action数组
            for i in 0...20 {
                servosData[i].currentAngle = actionDatas[selectAction].actionData[i]
            }
            let page = segue.destination as! ControlViewController
            page.currentActionName = actionDatas[selectAction].name
        }
        if(segue.identifier=="makenewactionpage"){
            //给新增加的一个数组列表
            selectAction = actionDatas.count-1
            let page = segue.destination as! ControlViewController
            page.currentActionName = actionDatas[selectAction].name
        }
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
