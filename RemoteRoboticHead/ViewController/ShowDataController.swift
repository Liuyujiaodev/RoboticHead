//
//  ShowDataController.swift
//  RemoteRoboticHead
//
//  Created by 刘玉娇 on 2018/1/20.
//  Copyright © 2018年 EXdoll. All rights reserved.
//

import UIKit

class ShowDataController: UIViewController,UITableViewDelegate,UITableViewDataSource {
    @IBOutlet weak var tableView : UITableView!
    @IBOutlet weak var showText : UILabel!
    
    var dataSource : NSMutableArray = NSMutableArray()

    override func viewDidLoad() {
        super.viewDidLoad()
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
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dataSource.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .default, reuseIdentifier: "ShowDataCell")
        let text : String = dataSource.object(at: indexPath.row) as! String
        cell.textLabel?.text = text
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.tableView!.deselectRow(at: indexPath, animated: true)
        showText.text = "正在发送数据"

        let fileUtil = FileUtil.init()
        let filePath : String = dataSource.object(at: indexPath.row) as! String
        let dataArray = fileUtil.getFileData(fileName: filePath) as NSArray
        let sendData : SendData = SendData.init()

        DispatchQueue.global().async {
            //开启新线程去发送数据
            for item in dataArray {
                sendData.writeData(array: item as! Array<NSNumber>)
                Thread.sleep(forTimeInterval: 0.1)
            }
            DispatchQueue.main.async {
                self.showText.text = "发送完成"
            }
            
        }
    }

    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        let delete = UITableViewRowAction(style: .normal, title: "删除", handler: { (_, indexPath)
            in
            
            let filePath : String = self.dataSource.object(at: indexPath.row) as! String
            let fileUtil = FileUtil.init()
            //删除文件
            fileUtil.removeFile(fileName: filePath)
            //删除datasource重新加载tableview
            self.dataSource.remove(filePath)
            self.tableView.reloadData()
        })
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
