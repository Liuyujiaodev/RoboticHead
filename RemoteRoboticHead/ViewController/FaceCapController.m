//
//  FaceCapViewController.m
//  RemoteRoboticHead
//
//  Created by 刘玉娇 on 2018/1/17.
//  Copyright © 2018年 EXdoll. All rights reserved.
//

#import "MGOpenGLView.h"
#import "MGOpenGLRenderer.h"
#import "MGFaceModelArray.h"
#import <CoreMotion/CoreMotion.h>
#import <MGBaseKit/MGImage.h>
#import "MGDetectRectInfo.h"
#import <MGBaseKit/MGBaseKit.h>
#import "MGFacepp.h"
#import "MGFaceLicenseHandle.h"
#import "UIButton+Base.h"
#import "FaceModel.h"
#import "RemoteRoboticHead-Swift.h"

//拖动按钮的限制
typedef struct {
    CGFloat minW;
    CGFloat maxW;
    CGFloat minH;
    CGFloat maxH;
    CGFloat centerX;
    CGFloat centerY;
} LimitArea;

#define APPViewWidth               self.view.frame.size.width
#define APPViewHeight              self.view.frame.size.height
#define RGBColor(r, g, b) [UIColor colorWithRed:(r)/255.0 green:(g)/255.0 blue:(b)/255.0 alpha:1.0]

#define RETAINED_BUFFER_COUNT 6

#define MAX_GET_TIME  5 //采集多少秒
#define BLUETOOTH_SEND  5//蓝牙发送频率

typedef NS_ENUM(NSInteger, BtnType) {
    BtnTypeNone = 0,//不做数据采集工作，只显示摄像头内容
    BtnTypeLocation = 1,//采集定位的数据
    BtnTypeGet = 2 //采集发送蓝牙的数据
};

#import "FaceCapController.h"

@interface FaceCapController () <MGVideoDelegate>
{
    dispatch_queue_t _detectImageQueue;//检测人脸的线程
    dispatch_queue_t _drawFaceQueue;//绘制人脸的线程
    LimitArea limitRect;//拖动的限制范围
}

@property (nonatomic, strong) MGOpenGLView *previewView;//预览头像的view

//-----------face++相关-------
@property (nonatomic, assign) BOOL hasVideoFormatDescription;//是否为render进行了video的设置
@property (nonatomic, strong) MGOpenGLRenderer *renderer; //绘制头像上的点
@property (nonatomic, strong) MGFacepp *markManager; //face++处理数据
@property (nonatomic, strong) MGVideoManager *videoManager; //录制视频
@property (nonatomic, strong) MGFaceInfo* standardFaceInfo;//区分是采集还是定位

//-------UI相关-------
@property (nonatomic, strong) UILabel* showTextLabel;//底部的状态条
@property (nonatomic, strong) UIImageView* faceImgView;//人脸框的图片
@property (nonatomic, strong) UIImageView* getDataImageView;//采集时候左上角的摄像机的小图标
@property (nonatomic, strong) UILabel* errorMsgLabel;//获取不到数据的时候显示

//--------数据相关-------
@property (nonatomic, assign) BtnType btnType;//区分是采集还是定位
@property (nonatomic, strong) NSMutableArray* locationArray;//定位的数组
@property (nonatomic, strong) NSMutableArray* getArray;//采集的数组
@property (nonatomic, assign) CGFloat pointRelativeX;//肩膀左右
@property (nonatomic, assign) CGFloat pointRelativeY;//肩膀上下

//------采集时间倒计时-----
@property (nonatomic, strong) NSTimer* timerForGetData;//采集数据倒计时
@property (nonatomic, assign) NSInteger time;//区分是采集还是定位

//-------拖动的圆点相关-----
@property (nonatomic, strong) UIView* bkArea;//拖动的外框
@property (nonatomic, strong) UIView* mvPoint;//拖动的圆点

//--------处理器-------
@property (nonatomic, strong) FileUtil* fileUtil;//文件操作的处理器
@property (nonatomic, strong) SendData* sendUtil;//发送蓝牙数据处理器
@property (nonatomic, assign) NSInteger count;//限制没五次发送一次

@end


@implementation FaceCapController

#pragma mark - 生命周期

//进入页面后初始化一些需要的值
-(instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.locationArray = [NSMutableArray array];
        self.getArray = [NSMutableArray array];
        self.btnType = BtnTypeNone;//进来后不采集数据
        self.pointRelativeX = 90;
        self.pointRelativeY = 90;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    //页面保持常亮
    [[UIApplication sharedApplication] setIdleTimerDisabled:YES];
    
    //首先要检测是否开启相机权限，然后有权限则进行face++授权，授权成功后做初始化
    [self startCheck];
    //创建UI
    [self creatView];
}

- (void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    //初始化摄像头
    [self.videoManager startRecording];
    //显示摄像头拍摄的内容
    [self setUpCameraLayer];
}

- (void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];
    //页面消失关闭摄像头
    [self.videoManager stopRunning];
}

#pragma mark -UI层
- (void)creatView{
    //创建顶部的titleView
    [self addTopView];
    //创建人脸头像
    [self addImageView];
    //创建底部四个按钮
    [self addBtnView];
    //创建拖动的小圆点和外边的框
    [self createDragView];
}

//加载图层预览---显示摄像头的数据
- (void)setUpCameraLayer
{
    if (!self.previewView) {
        self.previewView = [[MGOpenGLView alloc] initWithFrame:CGRectZero];
        self.previewView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
        
        // Front camera preview should be mirrored
        UIInterfaceOrientation currentInterfaceOrientation = [UIApplication sharedApplication].statusBarOrientation;
        CGAffineTransform transform =  [self.videoManager transformFromVideoBufferOrientationToOrientation:(AVCaptureVideoOrientation)currentInterfaceOrientation
                                                                                         withAutoMirroring:YES];
        self.previewView.transform = transform;
        [self.view insertSubview:self.previewView atIndex:0];
        
        CGRect bounds = CGRectZero;
        bounds.size = [self.view convertRect:self.view.bounds toView:self.previewView].size;
        self.previewView.bounds = bounds;
        self.previewView.center = CGPointMake(self.view.bounds.size.width/2.0, self.view.bounds.size.height/2.0);
    }
}

//创建顶部的titleView
- (void)addTopView {
    UIView* view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, APPViewWidth, 54)];
    view.backgroundColor = RGBColor(253, 146, 38);
    [self.view addSubview:view];
    
    UILabel* topLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 24, APPViewWidth, 30)];
    topLabel.text = @"脸部动作捕捉";
    topLabel.textColor = [UIColor whiteColor];
    topLabel.textAlignment = NSTextAlignmentCenter;
    topLabel.font = [UIFont systemFontOfSize:17];
    topLabel.backgroundColor =  RGBColor(253, 146, 38);
    [view addSubview:topLabel];
}

//创建人脸头像
- (void)addImageView {
    self.faceImgView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 30, APPViewWidth, APPViewHeight-30-87)];
    self.faceImgView.image = [UIImage imageNamed:@"faceArea"];
    [self.view addSubview:self.faceImgView];
}

//创建底部四个按钮
- (void)addBtnView {
    //定位按钮
    UIButton* locationBtn = [[UIButton alloc] initWithFrame:CGRectMake(0, APPViewHeight - 60, APPViewWidth/4, 60)];
    [locationBtn setBackgroundColor:RGBColor(67, 171, 212) forState:UIControlStateNormal];
    [locationBtn setBackgroundColor:[UIColor redColor] forState:UIControlStateSelected];
    [locationBtn addTarget:self action:@selector(locationBtnAction:) forControlEvents:UIControlEventTouchUpInside];
    [locationBtn setTitle:@"定位" forState:UIControlStateNormal];
    [locationBtn setTitle:@"确定" forState:UIControlStateSelected];
    [self.view addSubview:locationBtn];
    
    //采集按钮
    UIButton* getBtn = [[UIButton alloc] initWithFrame:CGRectMake(APPViewWidth/4, APPViewHeight - 60, APPViewWidth/4, 60)];
    [getBtn setBackgroundColor:RGBColor(67, 171, 212) forState:UIControlStateNormal];
    [getBtn setBackgroundColor:[UIColor redColor] forState:UIControlStateSelected];
    [getBtn addTarget:self action:@selector(getBtnAction:) forControlEvents:UIControlEventTouchUpInside];
    [getBtn setTitle:@"采集" forState:UIControlStateNormal];
    [getBtn setTitle:@"停止" forState:UIControlStateSelected];
    [self.view addSubview:getBtn];
    
    //数据按钮
    UIButton* palyBtn = [[UIButton alloc] initWithFrame:CGRectMake(APPViewWidth/4*2, APPViewHeight - 60, APPViewWidth/4, 60)];
    [palyBtn setBackgroundColor:RGBColor(67, 171, 212) forState:UIControlStateNormal];
    [palyBtn setBackgroundColor:RGBColor(30, 173, 251) forState:UIControlStateSelected];
    [palyBtn addTarget:self action:@selector(palyBtnAction:) forControlEvents:UIControlEventTouchUpInside];
    [palyBtn setTitle:@"数据" forState:UIControlStateNormal];
    [self.view addSubview:palyBtn];
    
    //返回按钮
    UIButton* backBtn = [[UIButton alloc] initWithFrame:CGRectMake(APPViewWidth/4*3, APPViewHeight - 60, APPViewWidth/4, 60)];
    [backBtn setBackgroundColor:RGBColor(107, 107, 107) forState:UIControlStateNormal];
    [backBtn addTarget:self action:@selector(backBtnAction) forControlEvents:UIControlEventTouchUpInside];
    [backBtn setTitle:@"返回" forState:UIControlStateNormal];
    [self.view addSubview:backBtn];
}

//创建拖动的小圆点和外边的框
- (void)createDragView {
    CGFloat height = APPViewHeight - 54 - 60 - 27;//目前背景高度
    //创建拖拽框
    self.bkArea = [[UIView alloc] initWithFrame:CGRectMake(APPViewWidth*0.2, (height - APPViewWidth*0.6)/2, APPViewWidth*0.6, APPViewWidth*0.6)];
    self.bkArea.layer.backgroundColor = [UIColor cyanColor].CGColor;
    self.bkArea.layer.borderWidth = 1;
    self.bkArea.layer.borderColor = [UIColor brownColor].CGColor;
    self.bkArea.alpha = 0.1;
    [self.view addSubview:self.bkArea];
    
    //创建拖拽点
    self.mvPoint = [[UIView alloc] initWithFrame:CGRectMake(CGRectGetMidX(self.bkArea.frame)-20, CGRectGetMidY(self.bkArea.frame)-20, 40, 40)];
    self.mvPoint.layer.cornerRadius = 20;
    self.mvPoint.layer.backgroundColor = [UIColor blueColor].CGColor;
    [self.view addSubview:self.mvPoint];

    //创建点的拖动事件
    UIPanGestureRecognizer* penDrag = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(pointDrag:)];
    [self.mvPoint addGestureRecognizer:penDrag];
    
    //创建最大拖动范围
    self->limitRect.minW = CGRectGetMinX(self.bkArea.frame);
    self->limitRect.maxW = CGRectGetMaxX(self.bkArea.frame);
    self->limitRect.minH = CGRectGetMinY(self.bkArea.frame);
    self->limitRect.maxH = CGRectGetMaxY(self.bkArea.frame);
    self->limitRect.centerX = CGRectGetMidX(self.bkArea.frame);
    self->limitRect.centerY = CGRectGetMidY(self.bkArea.frame);
}

#pragma mark - btn action

//定位按钮事件
- (void)locationBtnAction:(UIButton*)btn {
    btn.selected = !btn.selected;
    if (btn.selected) {
        //按下定位按钮，显示红色框，状态显示开始定位，然后设置btnType,来将数据存到locationArray里，清除上次定位存放的数据
        self.faceImgView.image = [UIImage imageNamed:@"faceAreaRed"];
        self.showTextLabel.text = @"开始定位";
        self.btnType = BtnTypeLocation;
        [self.locationArray removeAllObjects];
    } else {
        //设置btntype为BtnTypeNone，摄像头数据将不存到locationArray，状态显示定位结束，判断采集回来的数据是否可用，如果可用，计算定位里数据的平均值，放到locationArray，否则弹窗提示定位失败
        self.btnType = BtnTypeNone;
        self.showTextLabel.text = @"定位结束";
        self.faceImgView.image = [UIImage imageNamed:@"faceArea"];
        if (self.locationArray.count > 0) {
            self.standardFaceInfo = [FaceModel getCenterPoint:self.locationArray];
            AudioServicesPlaySystemSound(1012);//播放系统声音
        } else {
            [self alertErrorMsg:@"定位失败" msg:@"请重新定位"];
        }
    }
}

- (void)getBtnAction:(UIButton*)btn {

    //没有可用的定位信息，提示用户先进行定位
    if (!self.standardFaceInfo) {
        [self alertErrorMsg:@"请先进行定位" msg:@"点击定位按钮进行定位"];
        return;
    }
    btn.selected = !btn.selected;
    if (btn.selected) {
        //人脸框变红，显示左上角采集的图标，状态提示正在采集，btnType设为BtnTypeGet，将视频采集到的数据存到getArray，清除以前存放的数据
        self.faceImgView.image = [UIImage imageNamed:@"faceAreaRed"];
        self.getDataImageView.hidden = NO;
        self.showTextLabel.text = @"正在采集";
        self.btnType = BtnTypeGet;
        [self.getArray removeAllObjects];
        self.count = 0;
        
        //开启时间倒计时
        [self.timerForGetData invalidate];
        self.time = MAX_GET_TIME;
        
        //修改按钮为几秒后停止，因为时间timer里会一秒后执行，所以需要先执行一次title修改
        [btn setTitle:[NSString stringWithFormat:@"%ld秒停止", (long)self.time] forState:UIControlStateSelected];
        
        //启动倒计时，修改按钮的title，时间到时停止
        self.timerForGetData = [NSTimer timerWithTimeInterval:1.0 repeats:YES block:^(NSTimer * _Nonnull timer) {
            //没到时间，值修改btntitle，时间到后结束采集
            if (self.time > 0) {
                [btn setTitle:[NSString stringWithFormat:@"%ld秒停止", (long)self.time] forState:UIControlStateSelected];
            } else {
                //采集完成
                [self finishGetData];
                btn.selected = NO;
            }
            self.time--;
        }];
        [[NSRunLoop mainRunLoop] addTimer:self.timerForGetData forMode:NSRunLoopCommonModes];
    } else {
        //手动点停止按钮，采集完成
        [self finishGetData];
    }
 
}

//采集完成的方法
- (void)finishGetData {
    //人脸框变蓝，状态显示采集完成，隐藏左上角摄像机图标，倒计时结束，并且停止收集数据
    self.faceImgView.image = [UIImage imageNamed:@"faceArea"];
    self.showTextLabel.text = @"采集完成";
    self.getDataImageView.hidden = YES;
    [self.timerForGetData invalidate];
    self.btnType = BtnTypeNone;
    
    //弹出新建表情的窗口
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"新建表情" message:@"输入表情名称" preferredStyle:UIAlertControllerStyleAlert];
    [alertController addTextFieldWithConfigurationHandler:^(UITextField *textField){
    }];
    UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        UITextField *textField = alertController.textFields.firstObject;
        //保存到本地文件里
        [self.fileUtil saveFileWithFileName:textField.text data:self.getArray];
    }];
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil];
    [alertController addAction:cancelAction];
    [alertController addAction:okAction];
    [self presentViewController:alertController animated:YES completion:nil];
}

//跳转到数据页面
- (void)palyBtnAction:(UIButton*)btn {
    UIStoryboard *UpgradeHardware = [UIStoryboard storyboardWithName:@"ShowData" bundle:nil];
    UIViewController *showDataVC = [UpgradeHardware instantiateViewControllerWithIdentifier:@"ShowDataController"];//跳转VC的名称
    [self presentViewController:showDataVC animated:YES completion:nil];
}

//返回按钮事件
- (void)backBtnAction {
    [self dismissViewControllerAnimated:YES completion:nil];
}

//拖动小圆点事件
- (void)pointDrag:(UIPanGestureRecognizer*)sender {
    if (sender.state == UIGestureRecognizerStateBegan) {
        self.showTextLabel.text = @"拖动控制肩膀";
        self.bkArea.alpha = 0.5;
        self.mvPoint.layer.backgroundColor = [UIColor redColor].CGColor;
        self.mvPoint.alpha = 0.7;
    }
    
    //保持拖拽点在边缘
    CGPoint point = [sender translationInView:self.view];
    if ((sender.view.center.x + point.x) > limitRect.maxW || sender.view.center.x + point.x < limitRect.minW) {
        point.x = 0;
    }

    if((sender.view.center.y + point.y)>(limitRect.maxH) || (sender.view.center.y + point.y)<limitRect.minH){
        point.y = 0;
    }
    
    sender.view.center = CGPointMake(sender.view.center.x + point.x, sender.view.center.y + point.y);
    [sender setTranslation:CGPointZero inView:self.view];
    
    //计算并输出坐标点
    [self checkAngleOnPage];
    self.showTextLabel.text = [NSString stringWithFormat:@"移动坐标点 x:%f | y:%f", sender.view.center.x, sender.view.center.y];
    
    if(sender.state == UIGestureRecognizerStateEnded){
        //拖拽点回弹到起始位置
        [UIView animateWithDuration:0.3 delay:0.2 options:UIViewAnimationOptionCurveEaseOut animations:^{
            sender.view.center = CGPointMake(self.bkArea.center.x, self.bkArea.center.y);
        } completion:^(BOOL finished) {
            if (finished) {
                //回弹动画结束后恢复默认约束值
                self.bkArea.alpha = 0.1;
                self.mvPoint.layer.backgroundColor = [UIColor blueColor].CGColor;
                self.mvPoint.alpha = 1;
                self.showTextLabel.text = @"肩膀位置拖拽完成";
                [self checkAngleOnPage];
            }
        }];
    }
}

//给拖动的左右奸数据赋值
- (void)checkAngleOnPage {
   self.pointRelativeX = [FaceModel map:self.mvPoint.center.x inMin:CGRectGetMinX(self.bkArea.frame) inMax:CGRectGetMaxX(self.bkArea.frame) outMin:40 outMax:140 index:0];//前后
    self.pointRelativeY = [FaceModel map:self.mvPoint.center.y inMin:CGRectGetMinY(self.bkArea.frame) inMax:CGRectGetMaxY(self.bkArea.frame) outMin:40 outMax:140 index:0];//上下
}

#pragma mark - 视频处理
//处理视频数据并显示
- (void)rotateAndDetectSampleBuffer:(CMSampleBufferRef)sampleBuffer{
    if (self.markManager.status != MGMarkWorking) {
        
        //拷贝一份到内存做处理
        CMSampleBufferRef detectSampleBufferRef = NULL;
        CMSampleBufferCreateCopy(kCFAllocatorDefault, sampleBuffer, &detectSampleBufferRef);
        
        /* 进入检测人脸专用线程 */
        dispatch_async(_detectImageQueue, ^{
            @autoreleasepool {
                //拿到摄像头的image数据
                MGImageData *imageData = [[MGImageData alloc] initWithSampleBuffer:detectSampleBufferRef];
                
                /** 开启检测新的一帧，在每次调用 detectWithImageData: 之前调用。 */
                [self.markManager beginDetectionFrame];
                
                NSArray *tempArray = [self.markManager detectWithImageData:imageData];
                //回到主线程来显示，人脸是否离开摄像头，做提示
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (tempArray.count==0) {
                        self.errorMsgLabel.hidden = NO;
                    } else {
                        self.errorMsgLabel.hidden = YES;
                    }
                    //回到子线程继续处理视频
                    dispatch_async(_detectImageQueue, ^{
                        
                        //这是获取到的人脸数据
                        MGFaceModelArray *faceModelArray = [[MGFaceModelArray alloc] init];
                        faceModelArray.getFaceInfo = NO;
                        faceModelArray.faceArray = [NSMutableArray arrayWithArray:tempArray];
                        faceModelArray.get3DInfo = NO;
                        [faceModelArray setDetectRect:CGRectNull];
                        for (int i = 0; i < faceModelArray.count; i ++) {
                            MGFaceInfo *faceInfo = faceModelArray.faceArray[i];
                            [self.markManager GetGetLandmark:faceInfo isSmooth:YES pointsNumber:81];
                        }
                        //绘制人脸信息并显示
                        [self displayWithfaceModel:faceModelArray SampleBuffer:detectSampleBufferRef];
                        [self.markManager endDetectionFrame];
                    });
                });
            }
            
        });
    }
}

//绘制人脸信息并显示
- (void)displayWithfaceModel:(MGFaceModelArray *)modelArray SampleBuffer:(CMSampleBufferRef)sampleBuffer{
    @autoreleasepool {
        __unsafe_unretained FaceCapController *weakSelf = self;
        dispatch_async(_drawFaceQueue, ^{
            if (modelArray) {
                CVPixelBufferRef renderedPixelBuffer = [weakSelf.renderer drawPixelBuffer:sampleBuffer custumDrawing:^{

                    //拷贝出一份单门做显示，因为显示的要比实际采集的多，所以做了单门的处理
                    MGFaceModelArray *showArrayModel = [[MGFaceModelArray alloc] init];
                    showArrayModel.faceArray = [NSMutableArray arrayWithArray:modelArray.faceArray];
                    MGFaceModelArray* showArray = [FaceModel getShowArray:showArrayModel];

                    //显示脸上的点
                    [weakSelf.renderer drawFaceLandMark:showArray];//

                    //存到数据的数据处理
                    MGFaceModelArray* ownModelArray = [FaceModel getOwnModelArrayFromArray:modelArray];
                    if (self.btnType == BtnTypeLocation) {
                        [self.locationArray addObject:ownModelArray];
                    } else if (self.btnType == BtnTypeGet){
                        NSMutableArray* sendArray = [[FaceModel getSendData:ownModelArray.faceArray] mutableCopy];//face++拿到的数据
                        [sendArray addObject:[NSNumber numberWithInt:self.pointRelativeY]];//左肩上下
                        [sendArray addObject:[NSNumber numberWithInt:self.pointRelativeY]];//右肩上下
                        [sendArray addObject:[NSNumber numberWithInt:self.pointRelativeX]];//左肩前后
                        [sendArray addObject:[NSNumber numberWithInt:self.pointRelativeX]];//右肩前后
                        if (self.count > BLUETOOTH_SEND) {
                            //向蓝牙发送数据
                            [self.sendUtil writeDataWithArray:sendArray];//发送给蓝牙
                            self.count = 0;
                        } else {
                            self.count++;
                        }
                      
                        
                        //保存到视频组
                        [self.getArray addObject:sendArray];
                    }
                    //多显示几个点

                    if (!CGRectIsNull(modelArray.detectRect)) {
                        [weakSelf.renderer drawFaceWithRect:modelArray.detectRect];
                    }
                }];
                
                if (renderedPixelBuffer)
                {
                    //显示摄像头数据
                    [weakSelf.previewView displayPixelBuffer:renderedPixelBuffer];
                    //释放对象
                    CFRelease(sampleBuffer);
                    CVBufferRelease(renderedPixelBuffer);
                }
            }
        });
    }
}


#pragma mark - video delegate 视频回来的处理(系统拿到视频数据回传过来的delegate方法)
-(void)MGCaptureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection{
    @synchronized(self) {
        //视频开始录制的时候，需要清除以前的buffer
        if (self.hasVideoFormatDescription == NO) {
            [self setupVideoPipelineWithInputFormatDescription:[self.videoManager formatDescription]];
        }
        //处理数据
        [self rotateAndDetectSampleBuffer:sampleBuffer];
    }
}

//系统视频回来错误方法
- (void)MGCaptureOutput:(AVCaptureOutput *)captureOutput error:(NSError *)error{
    UIAlertController *alertViewController = [UIAlertController alertControllerWithTitle:@"相机异常"
                                                                                 message:nil preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *action = [UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [self dismissViewControllerAnimated:YES completion:nil];
    }];
    [alertViewController addAction:action];
    [self presentViewController:alertViewController animated:YES completion:nil];
}

- (void)setupVideoPipelineWithInputFormatDescription:(CMFormatDescriptionRef)inputFormatDescription
{
    MGLog( @"-[%@ %@] called", NSStringFromClass([self class]), NSStringFromSelector(_cmd) );
    self.hasVideoFormatDescription = YES;
    
    [_renderer prepareForInputWithFormatDescription:inputFormatDescription
                      outputRetainedBufferCountHint:RETAINED_BUFFER_COUNT];
}

#pragma mark- 获取摄像头

- (AVCaptureDevicePosition)getCamera:(BOOL)index{
    AVCaptureDevicePosition tempVideo;
    if (index == NO) {
        tempVideo = AVCaptureDevicePositionFront;
    }else{
        tempVideo = AVCaptureDevicePositionBack;
    }
    return tempVideo;
}

#pragma mark- 初始化的一些方法

//检测权限
- (void)startCheck{
    AVAuthorizationStatus authStatus =  [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];
    if (authStatus == AVAuthorizationStatusRestricted || authStatus ==AVAuthorizationStatusDenied) {
        //检测权限失败
        [self showAVAuthorizationStatusDeniedAlert];
    } else if (authStatus == AVAuthorizationStatusNotDetermined) {
        //获取权限
        [AVCaptureDevice requestAccessForMediaType:AVMediaTypeVideo completionHandler:^(BOOL granted) {
            if (granted) {
                //获取成功
                [self authFace];
            } else {
                //失败
                [self showAVAuthorizationStatusDeniedAlert];
            }
        }];
    } else {
        //已经获取
        [self authFace];
    }
}

//检测权限失败提示用户
- (void)showAVAuthorizationStatusDeniedAlert{
    [self alertErrorMsg:@"请打开相机权限" msg:@"获取相机权限失败"];
}

- (void)authFace {
    /** 进行联网授权版本判断，联网授权就需要进行网络授权 */
    BOOL needLicense = [MGFaceLicenseHandle getNeedNetLicense];
    
    if (needLicense) {
        [MGFaceLicenseHandle licenseForNetwokrFinish:^(bool License, NSDate *sdkDate) {
            if (!License) {
                NSLog(@"联网授权失败 ！！！");
            } else {
                NSLog(@"联网授权成功");
                [self initVideo];
            }
        }];
    } else {
        NSLog(@"SDK 为非联网授权版本！");
    }
}

//初始化face++sdk
- (void)initVideo {
    //视频采集器
    AVCaptureDevicePosition device = [self getCamera:NO];
    self.videoManager = [MGVideoManager videoPreset:AVCaptureSessionPreset640x480
                                     devicePosition:device
                                        videoRecord:YES
                                         videoSound:NO];
    
    if (self.videoManager.videoDelegate != self) {
        self.videoManager.videoDelegate = self;
    }
    
    NSString *modelPath = [[NSBundle mainBundle] pathForResource:KMGFACEMODELNAME ofType:@""];
    NSData *modelData = [NSData dataWithContentsOfFile:modelPath];
    
    //数据分析工具
    self.markManager = [[MGFacepp alloc] initWithModel:modelData
                                          maxFaceCount:0
                                         faceppSetting:^(MGFaceppConfig *config) {
                                             config.minFaceSize = 100;
                                             config.interval = 100;//帧数
                                             config.orientation = 90;
                                             config.detectionMode = MGFppDetectionModeTrackingFast;
                                             config.detectROI = MGDetectROIMake(0, 0, 0, 0);
                                             config.pixelFormatType = PixelFormatTypeRGBA;
                                         }];
    
    //初始化两个线程，第一个用于face++解析采集到的视频数据，第二个用于绘制图像
    _detectImageQueue = dispatch_queue_create("com.megvii.image.detect", DISPATCH_QUEUE_SERIAL);
    _drawFaceQueue = dispatch_queue_create("com.megvii.image.drawFace", DISPATCH_QUEUE_SERIAL);
    
    //绘制点
    self.renderer = [[MGOpenGLRenderer alloc] init];
    [self.renderer setShow3DView:NO];
}

//公共弹出alert方法
- (void)alertErrorMsg:(NSString*)title msg:(NSString*)msg {
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:title message:msg preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"我知道了" style:UIAlertActionStyleCancel handler:nil];
    [alertController addAction:cancelAction];
    [self presentViewController:alertController animated:YES completion:nil];
}

//以下有可能用不到，所以等用到的时候再去创建对象
//文件的读取，写入的Uitl对象，初始化fileUtil属性
-(FileUtil*)fileUtil {
    if (!_fileUtil) {
        _fileUtil = [[FileUtil alloc] init];
    }
    return _fileUtil;
}

//初始化sendUtil属性，发送给蓝牙的属性
- (SendData*)sendUtil {
    if (!_sendUtil) {
        _sendUtil = [[SendData alloc] init];
    }
    return _sendUtil;
}

//下边的状态栏的view
- (UILabel*)showTextLabel {
    if (!_showTextLabel) {
        _showTextLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, APPViewHeight - 60 - 27, APPViewWidth, 27)];
        _showTextLabel.textAlignment = NSTextAlignmentCenter;
        _showTextLabel.textColor = [UIColor whiteColor];
        _showTextLabel.backgroundColor = RGBColor(253, 146, 38);
        _showTextLabel.font = [UIFont systemFontOfSize:14];
        [self.view addSubview:_showTextLabel];
    }
    return _showTextLabel;
}

//采集时候左上角的摄像头的view
- (UIImageView*)getDataImageView {
    if (!_getDataImageView) {
        _getDataImageView = [[UIImageView alloc] initWithFrame:CGRectMake(18, 86, 40, 40)];
        _getDataImageView.image = [UIImage imageNamed:@"rec"];
        _getDataImageView.hidden = YES;
        [self.view addSubview:_getDataImageView];
    }
    return _getDataImageView;
}

//顶部采集不到数据的view
- (UILabel*)errorMsgLabel {
    if (!_errorMsgLabel) {
        _errorMsgLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, APPViewWidth, 60)];
        _errorMsgLabel.textAlignment = NSTextAlignmentCenter;
        _errorMsgLabel.backgroundColor = [UIColor whiteColor];
        _errorMsgLabel.textColor = [UIColor redColor];
        _errorMsgLabel.hidden = YES;
        _errorMsgLabel.text = @"无法采集到您的数据，请对准屏幕";
        [self.view addSubview:_errorMsgLabel];
    }
    return _errorMsgLabel;
}
@end
