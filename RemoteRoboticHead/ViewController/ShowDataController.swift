//
//  ShowDataController.swift
//  RemoteRoboticHead
//
//  Created by 刘玉娇 on 2018/1/20.
//  Copyright © 2018年 EXdoll. All rights reserved.
//

import UIKit

class ShowDataController: UIViewController,UITableViewDelegate,UITableViewDataSource {
    @IBOutlet weak var tableView : UITableView!//tableView
    @IBOutlet weak var showText : UILabel! //状态栏
    
    var dataSource : NSMutableArray = NSMutableArray()

    override func viewDidLoad() {
        super.viewDidLoad()
        //从文件里拿到数据，加载到tableView
        let fileUtil = FileUtil.init()
        dataSource = fileUtil.getFileList().mutableCopy() as! NSMutableArray
        tableView.reloadData()
        showText.text = "共有 \(dataSource.count)条数据"
        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    //table view的数据源设置
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dataSource.count
    }
    
    //tableview的cell设置
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .default, reuseIdentifier: "ShowDataCell")
        let text : String = dataSource.object(at: indexPath.row) as! String
        cell.textLabel?.text = text
        return cell
    }
    
    //点击tableview，开始蓝牙发送
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        showText.text = "开始传输"

        let fileUtil = FileUtil.init()
        let filePath : String = dataSource.object(at: indexPath.row) as! String
        let dataArray = fileUtil.getFileData(fileName: filePath) as NSArray
        let sendData : SendData = SendData.init()

        //开启线程发送数据，这样不会卡主线程的操作
        DispatchQueue.global().async {
            //开启新线程去发送数据
            for item in dataArray {
                sendData.writeData(array: item as! Array<NSNumber>)
                Thread.sleep(forTimeInterval: 0.1)
            }
            DispatchQueue.main.async {
                self.showText.text = "传输完成"
                //改变cell的选中态
                self.tableView!.deselectRow(at: indexPath, animated: true)
            }
            
        }
    }
    
    //右滑删除
    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        //删除方法
        let delete = UITableViewRowAction(style: .normal, title: "删除", handler: { (_, indexPath)
            in
              let alertView = UIAlertController(title: "删除表情", message: "确认删除表情", preferredStyle: .alert)
            
            //确定删除弹窗
            let okbtn = UIAlertAction(title: "确认", style: .default, handler: { (_) in
                let filePath : String = self.dataSource.object(at: indexPath.row) as! String
                let fileUtil = FileUtil.init()
                //删除文件
                fileUtil.removeFile(fileName: filePath)
                //删除datasource重新加载tableview
                self.dataSource.remove(filePath)
                self.tableView.reloadData()
            })
            //取消按钮
            let cancelBtn = UIAlertAction(title: "取消", style: .cancel, handler: nil)
            alertView.addAction(okbtn)
            alertView.addAction(cancelBtn)
            //提交选项框
            self.present(alertView, animated: true, completion: nil)
           
        })
        //设置删除的按钮为红色
        delete.backgroundColor = UIColor.red
        return [delete]
    }
    
    @IBAction func backBtnAction(_ sender: UIButton) {
        self.dismiss(animated: true, completion: nil)
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
