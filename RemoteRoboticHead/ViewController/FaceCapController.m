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

#define APPViewWidth               self.view.frame.size.width
#define APPViewHeight              self.view.frame.size.height
#define RGBColor(r, g, b) [UIColor colorWithRed:(r)/255.0 green:(g)/255.0 blue:(b)/255.0 alpha:1.0]

#define RETAINED_BUFFER_COUNT 6

#define MAX_GET_TIME  5

typedef NS_ENUM(NSInteger, BtnType) {
    BtnTypeLocation = 0,//定位
    BtnTypeGet = 1 //采集
};

#import "FaceCapController.h"

@interface FaceCapController () <MGVideoDelegate>
{
    dispatch_queue_t _detectImageQueue;
    dispatch_queue_t _drawFaceQueue;
}

@property (nonatomic, strong) MGOpenGLView *previewView;//预览头像的view

@property (nonatomic, assign) BOOL hasVideoFormatDescription;//是否为render进行了video的设置
@property (nonatomic, strong) MGOpenGLRenderer *renderer; //绘制头像上的点

@property (nonatomic, strong) MGFacepp *markManager; //face++处理数据

@property (nonatomic, strong) MGVideoManager *videoManager; //录制视频

@property (nonatomic, strong) NSMutableArray* locationArray;//定位的数组
@property (nonatomic, strong) NSMutableArray* getArray;//采集的数组

@property (nonatomic, assign) BtnType btnType;//区分是采集还是定位
@property (nonatomic, strong) UIButton* selectBtn;//区分是采集还是定位
@property (nonatomic, strong) MGFaceInfo* standardFaceInfo;//区分是采集还是定位
@property (nonatomic, strong) NSTimer* timerForGetData;//采集数据倒计时
@property (nonatomic, assign) NSInteger time;//区分是采集还是定位
@property (nonatomic, strong) FileUtil* fileUtil;
@end


@implementation FaceCapController

#pragma mark - 生命周期

-(void)dealloc{
    self.previewView = nil;
    self.renderer = nil;
}

-(instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.locationArray = [NSMutableArray array];
        self.getArray = [NSMutableArray array];
        self.btnType = BtnTypeLocation;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    //首先要检测是否开启相机权限，然后有权限则进行face++授权，授权成功后做初始化
    [self startCheck];
    //创建UI
    [self creatView];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
 
}

- (void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];
    [self.videoManager stopRunning];
}

#pragma mark -UI层
- (void)creatView{
    [self addImageView];
    [self addBtnView];
}

//加载图层预览
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

//人脸头像
- (void)addImageView {
    UIImageView* imageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, APPViewWidth, APPViewHeight)];
    imageView.image = [UIImage imageNamed:@"faceArea"];
    [self.view addSubview:imageView];
}

- (void)addBtnView {
    UIButton* locationBtn = [[UIButton alloc] initWithFrame:CGRectMake(0, APPViewHeight - 60, APPViewWidth/4, 60)];
    [locationBtn setBackgroundColor:RGBColor(67, 171, 212) forState:UIControlStateNormal];
    [locationBtn setBackgroundColor:RGBColor(30, 173, 251) forState:UIControlStateSelected];
    [locationBtn addTarget:self action:@selector(locationBtnAction:) forControlEvents:UIControlEventTouchUpInside];
    [locationBtn setTitle:@"定位" forState:UIControlStateNormal];
    [locationBtn setTitle:@"停止定位" forState:UIControlStateSelected];
    [self.view addSubview:locationBtn];
    
    UIButton* getBtn = [[UIButton alloc] initWithFrame:CGRectMake(APPViewWidth/4, APPViewHeight - 60, APPViewWidth/4, 60)];
    [getBtn setBackgroundColor:RGBColor(67, 171, 212) forState:UIControlStateNormal];
    [getBtn setBackgroundColor:RGBColor(30, 173, 251) forState:UIControlStateSelected];
    [getBtn addTarget:self action:@selector(getBtnAction:) forControlEvents:UIControlEventTouchUpInside];
    [getBtn setTitle:@"采集" forState:UIControlStateNormal];
    [getBtn setTitle:@"停止" forState:UIControlStateSelected];
    [self.view addSubview:getBtn];
    
    UIButton* palyBtn = [[UIButton alloc] initWithFrame:CGRectMake(APPViewWidth/4*2, APPViewHeight - 60, APPViewWidth/4, 60)];
    [palyBtn setBackgroundColor:RGBColor(67, 171, 212) forState:UIControlStateNormal];
    [palyBtn setBackgroundColor:RGBColor(30, 173, 251) forState:UIControlStateSelected];
    [palyBtn addTarget:self action:@selector(palyBtnAction:) forControlEvents:UIControlEventTouchUpInside];
    [palyBtn setTitle:@"播放" forState:UIControlStateNormal];
    [self.view addSubview:palyBtn];
    
    UIButton* backBtn = [[UIButton alloc] initWithFrame:CGRectMake(APPViewWidth/4*3, APPViewHeight - 60, APPViewWidth/4, 60)];
    [backBtn setBackgroundColor:RGBColor(107, 107, 107) forState:UIControlStateNormal];
    [backBtn addTarget:self action:@selector(backBtnAction) forControlEvents:UIControlEventTouchUpInside];
    [backBtn setTitle:@"返回" forState:UIControlStateNormal];
    [self.view addSubview:backBtn];
}

#pragma mark - btn action

- (void)locationBtnAction:(UIButton*)btn {
    btn.selected = !btn.selected;
    if (btn.selected) {
        self.btnType = BtnTypeLocation;
        [self.locationArray removeAllObjects];
        [self.videoManager startRecording];
        [self setUpCameraLayer];
    } else {
        [self.videoManager stopRceording];
        self.standardFaceInfo = [FaceModel getCenterPoint:self.locationArray];
    }
}

- (void)getBtnAction:(UIButton*)btn {
    btn.selected = !btn.selected;
    if (btn.selected) {
        [self.getArray removeAllObjects];
        [self.videoManager startRecording];
        [self setUpCameraLayer];
        
        self.btnType = BtnTypeGet;
        [self.timerForGetData invalidate];
        self.time = MAX_GET_TIME;
        [btn setTitle:[NSString stringWithFormat:@"%ld秒停止", (long)self.time] forState:UIControlStateSelected];
        self.timerForGetData = [NSTimer timerWithTimeInterval:1.0 repeats:YES block:^(NSTimer * _Nonnull timer) {
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
        [self finishGetData];
    }
 
}

- (void)finishGetData {
    [self.timerForGetData invalidate];
    [self.videoManager stopRceording];
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"新建表情" message:@"输入表情名称" preferredStyle:UIAlertControllerStyleAlert];
    [alertController addTextFieldWithConfigurationHandler:^(UITextField *textField){
    }];
    UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        UITextField *textField = alertController.textFields.firstObject;
        [self.fileUtil saveFileWithFileName:textField.text data:self.getArray];
    }];
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil];
    [alertController addAction:cancelAction];
    [alertController addAction:okAction];
    [self presentViewController:alertController animated:YES completion:nil];
}

- (void)palyBtnAction:(UIButton*)btn {
    NSArray* array = [self.fileUtil getFileList];
    NSArray* data = [self.fileUtil getFileDataWithFileName:[array objectAtIndex:0]];
}

- (void)backBtnAction {
    [self dismissViewControllerAnimated:YES completion:nil];
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
                
                MGImageData *imageData = [[MGImageData alloc] initWithSampleBuffer:detectSampleBufferRef];
                
                /** 开启检测新的一帧，在每次调用 detectWithImageData: 之前调用。 */
                [self.markManager beginDetectionFrame];
                
                NSArray *tempArray = [self.markManager detectWithImageData:imageData];
                if (tempArray.count > 0) {
                    
                    NSDate *date1, *date2, *date3;
                    date1 = [NSDate date];
                    date2 = [NSDate date];
                    double timeUsed = [date2 timeIntervalSinceDate:date1] * 1000;
                    
                    //这是获取到的人脸数据
                    MGFaceModelArray *faceModelArray = [[MGFaceModelArray alloc] init];
                    faceModelArray.getFaceInfo = NO;
                    faceModelArray.faceArray = [NSMutableArray arrayWithArray:tempArray];
                    faceModelArray.timeUsed = timeUsed;
                    faceModelArray.get3DInfo = NO;
                    [faceModelArray setDetectRect:CGRectNull];
                    
                    for (int i = 0; i < faceModelArray.count; i ++) {
                        MGFaceInfo *faceInfo = faceModelArray.faceArray[i];
                        [self.markManager GetGetLandmark:faceInfo isSmooth:YES pointsNumber:81];
                    }
                    date3 = [NSDate date];
                    double timeUsed3D = [date3 timeIntervalSinceDate:date2] * 1000;
                    faceModelArray.AttributeTimeUsed = timeUsed3D;
                    
                    [self displayWithfaceModel:faceModelArray SampleBuffer:detectSampleBufferRef];
                }
                [self.markManager endDetectionFrame];

            }
            
        });
    }
}

/** 根据人脸信息绘制，并且显示 */
- (void)displayWithfaceModel:(MGFaceModelArray *)modelArray SampleBuffer:(CMSampleBufferRef)sampleBuffer{
    @autoreleasepool {
        __unsafe_unretained FaceCapController *weakSelf = self;
        dispatch_async(_drawFaceQueue, ^{
            if (modelArray) {
                CVPixelBufferRef renderedPixelBuffer = [weakSelf.renderer drawPixelBuffer:sampleBuffer custumDrawing:^{
                    MGFaceModelArray* ownModelArray = [FaceModel getOwnModelArrayFromArray:modelArray];
                    if (self.btnType == BtnTypeLocation) {
                        [self.locationArray addObject:ownModelArray];
                    } else {
                        //向蓝牙发送数据
                        NSArray* sendArray = [FaceModel getSendData:[ownModelArray.faceArray objectAtIndex:0]];
                        SendData* send = [[SendData alloc] init];
                        [send writeDataWithArray:sendArray];
                        //保存到视频组
                        [self.getArray addObject:sendArray];
                    }
                    [weakSelf.renderer drawFaceLandMark:ownModelArray];
                    
                    if (!CGRectIsNull(modelArray.detectRect)) {
                        [weakSelf.renderer drawFaceWithRect:modelArray.detectRect];
                    }
                }];
                
                if (renderedPixelBuffer)
                {
                    [weakSelf.previewView displayPixelBuffer:renderedPixelBuffer];
                    
                    CFRelease(sampleBuffer);
                    CVBufferRelease(renderedPixelBuffer);
                }
            }
        });
    }
}


#pragma mark - video delegate 视频回来的处理
-(void)MGCaptureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection{
    
    @synchronized(self) {
        if (self.hasVideoFormatDescription == NO) {
            [self setupVideoPipelineWithInputFormatDescription:[self.videoManager formatDescription]];
        }
        //处理数据
        [self rotateAndDetectSampleBuffer:sampleBuffer];
    }
}

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
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"请打开相机权限" message:nil preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *action = [UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        
    }];
    [alertController addAction:action];
    [self presentViewController:alertController animated:YES completion:nil];
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
    
    _detectImageQueue = dispatch_queue_create("com.megvii.image.detect", DISPATCH_QUEUE_SERIAL);
    _drawFaceQueue = dispatch_queue_create("com.megvii.image.drawFace", DISPATCH_QUEUE_SERIAL);
    
    //绘制点
    self.renderer = [[MGOpenGLRenderer alloc] init];
    [self.renderer setShow3DView:NO];
}

-(FileUtil*)fileUtil {
    if (!_fileUtil) {
        _fileUtil = [[FileUtil alloc] init];
    }
    return _fileUtil;
}


@end
