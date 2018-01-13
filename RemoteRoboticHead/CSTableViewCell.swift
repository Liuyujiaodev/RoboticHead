//
//  CSTableViewCell.swift
//  RemoteRoboticHead
//
//  Created by QiaoWu on 2018/1/13.
//  Copyright © 2018年 EXdoll. All rights reserved.
//

import UIKit

class CSTableViewCell: UITableViewCell {

    //电动机名称
    @IBOutlet weak var nameText: UILabel!
    //显示当前角度
    @IBOutlet weak var angleText: UILabel!
    //转动角度滑块
    @IBOutlet weak var angleSlider: UISlider!

    
    override func awakeFromNib() {
        super.awakeFromNib()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
}
