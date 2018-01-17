//
//  RemoteRoboticHead-Brdging-Header.h
//  RemoteRoboticHead
//
//  Created by QiaoWu on 2018/1/13.
//  Copyright © 2018年 EXdoll. All rights reserved.
//


//关于用于 swift 中使用 oc
//在项目的 Build Settings 选项里，要确保Swift Compiler选项里有这个Bridging Header文件的设置，路径必须指向文件本身
//似乎只要吧OC 的头文件import进来，之后就可以直接使用oc里的变量和方法了

#ifndef RemoteRoboticHead_Brdging_Header_h
#define RemoteRoboticHead_Brdging_Header_h

#import "test.h"
#import "FaceCapController.h"

#endif /* RemoteRoboticHead_Brdging_Header_h */
