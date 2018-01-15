//
//  ActionListViewController.swift
//  RemoteRoboticHead
//
//  Created by QiaoWu on 2018/1/14.
//  Copyright © 2018年 EXdoll. All rights reserved.
//

import UIKit

class ActionListViewController: UIViewController,UITableViewDelegate, UITableViewDataSource {
    
    @IBOutlet weak var showText: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    // MARK: - data save and load
    
    //等待写保存和读取
    var actionDatas = [
        OneFaceAction(name:"预设",actionData:[90,120,90,90,90,90,90,90,90,90,90,90,90,90,90,90,90,90,90,90,90]),
        OneFaceAction(name:"笑容",actionData:[90,90,120,90,90,90,90,90,90,90,90,90,90,90,90,90,90,90,90,90,90]),
        OneFaceAction(name:"闭眼",actionData:[90,90,90,120,90,90,90,90,90,90,90,90,90,90,90,90,90,90,90,90,90]),
        OneFaceAction(name:"生气",actionData:[90,90,90,90,120,90,90,90,90,90,90,90,90,90,90,90,90,90,90,90,90]),
        OneFaceAction(name:"微笑",actionData:[90,90,90,90,90,120,90,90,90,90,90,90,90,90,90,90,90,90,90,90,90]),
        OneFaceAction(name:"眨眼",actionData:[90,90,90,90,90,90,120,90,90,90,90,90,90,90,90,90,90,90,90,90,90])
    ]
    var selectAction = 0;
    
    
    // MARK: - tableViews
    
    //表格列表数量，读取数据 //还没写
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.actionDatas.count
    }
    //列表
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .default, reuseIdentifier: "ActionCellls")
        cell.textLabel?.text = self.actionDatas[indexPath.row].name
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
        self.showText.text = "当前选择:\(self.actionDatas[indexPath.row].name)"
        self.selectAction = indexPath.row
        //待写
    }
    //列表滑动选项
    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        self.selectAction = indexPath.row
        let edit = UITableViewRowAction(style: .normal, title: "编辑") { (_, indexPath) in
            //跳转到编辑页面  //跳转需要携带数据
            self.performSegue(withIdentifier: "showcontrolpage", sender: self)
        }
        let delect = UITableViewRowAction(style: .normal, title: "删除") { (_, indexPath) in
            //删除确认对话框
            let alertbar = UIAlertController(title: "删除动作", message: "确认是否删除动作数组", preferredStyle: .actionSheet)
            //确定删除
            let okbtn = UIAlertAction(title: "确认", style: .default, handler: { (_) in
                //从数组和列表中移除
                self.self.actionDatas.remove(at: indexPath.row)
                tableView.deleteRows(at: [indexPath], with: .fade)
            })
            let nobtn = UIAlertAction(title: "取消", style: .cancel, handler: nil)
            alertbar.addAction(okbtn)
            alertbar.addAction(nobtn)
            //完成事件，暂时没用
            self.present(alertbar, animated: true, completion: {
                //print("completed click action")
            })
        }
        edit.backgroundColor = UIColor.magenta
        delect.backgroundColor = UIColor.red
        return[edit,delect]
    }
    
    //转场
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if(segue.identifier=="showcontrolpage"){
            //编辑动作时，携带数组数据
            for i in 0...20 {
                servosData[i].currentAngle = actionDatas[selectAction].actionData[i]
            }
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
