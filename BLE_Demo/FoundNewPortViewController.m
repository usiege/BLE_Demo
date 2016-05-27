//
//  FoundNewPortViewController.m
//  BLEDataGateway
//
//  Created by 王 维 on 8/27/14.
//  Copyright (c) 2014 BDE. All rights reserved.
//

#import "FoundNewPortViewController.h"
#import <QuartzCore/CALayer.h>
#import "CardactionViewController.h"

#import "BluetoochManager.h"
#import "PeripheralDevice.h"

#import "HHAlertView.h"

static NSString* RIGHT_BUTTON_STATE_NORMAL = @"正常";
static NSString* RIGHT_BUTTON_STATE_SCAN = @"扫描";
static NSString* RIGHT_BUTTON_STATE_STOP = @"停止";

@interface FoundNewPortViewController () <BluetoochDelegate>
{
    
    
    NSString* rButtonState;
    
//    BLEManageController *_bleController;
    BluetoochManager*  _bleManager;
}
@property (strong,nonatomic) UITableView *foundDevicesTableView;
@property (strong,nonatomic) UIActivityIndicatorView* aInView;
@property (strong,nonatomic) UIButton* rightButton;

-(void)connectDevice:(PeripheralDevice*)device;
@end

@implementation FoundNewPortViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.title = @"BLE Demo";
    self.devicesCount = 0;


    [self createUI];
    _bleManager = [BluetoochManager shareInstance];
    _bleManager.delegate = self;
    
}

- (void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    [_bleManager startSearchPeriphralsUntil:[NSDate distantFuture]];
}

- (void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];
    [_bleManager stopSearchPeriphrals];
}

- (void)bluetoochManager:(BluetoochManager *)manager didFoundNewPerigheralDevice:(PeripheralDevice *)device{
    self.devicesCount = _bleManager.seekedDevices.count;
    [self.foundDevicesTableView reloadData];
}


- (void)viewDidAppear:(BOOL)animated{
    [self searchDevice];
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleDefault];
}

-(void)searchDevice{
//    [_bleController startScanWithChannelType:self.channelType];
}


- (void)rightButtonClick:(UIButton *)rightButton{
    rightButton.selected = !rightButton.selected;
    
    if (rightButton.selected) {
        [self.aInView startAnimating];
        [_bleManager startSearchPeriphralsUntil:[NSDate distantFuture]];
    }else{
        [self.aInView stopAnimating];
        [_bleManager stopSearchPeriphrals];
    }
}


- (void)viewDidUnload{
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
    
}


/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/


#pragma  mark  -table view delegate&datasource


- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    return 1;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    self.devicesCount = _bleManager.seekedDevices.count;
    return self.devicesCount;
}


- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    return 60.0;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{

    UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle  reuseIdentifier:@"FoundNewPortViewControllerCellReusedID"];
    
    PeripheralDevice *device = [_bleManager.seekedDevices objectAtIndex:indexPath.row];
    cell.textLabel.text = device.name;
    
    return cell;
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];

    PeripheralDevice *device = [_bleManager.seekedDevices objectAtIndex:indexPath.row];
//    [self connectDevice:device];
    
    CardactionViewController *cardDetial = [[CardactionViewController alloc]init];
    cardDetial.device = device;
    [self.navigationController pushViewController:cardDetial animated:YES];
 }




#pragma mark -setupUI
- (void)createUI{
    self.view.backgroundColor = [UIColor blackColor];
    
    self.rightButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 60, 25)];
    [_rightButton setTitle:RIGHT_BUTTON_STATE_SCAN forState:UIControlStateNormal];
    [_rightButton setTitle:RIGHT_BUTTON_STATE_STOP forState:UIControlStateSelected];
    [self.rightButton addTarget:self action:@selector(rightButtonClick:) forControlEvents:UIControlEventTouchUpInside];
    UIBarButtonItem* rightItem = [[UIBarButtonItem alloc] initWithCustomView:_rightButton];
    self.navigationItem.rightBarButtonItem = rightItem;
    
    self.aInView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
    //    [_aInView startAnimating];
    UIBarButtonItem* leftItem = [[UIBarButtonItem alloc] initWithCustomView:_aInView];
    self.navigationItem.leftBarButtonItem = leftItem;
    
    self.foundDevicesTableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width,self.view.bounds.size.height) style:UITableViewStylePlain];
    self.foundDevicesTableView.delegate = self;
    self.foundDevicesTableView.dataSource = self;
    self.foundDevicesTableView.layer.borderWidth = 1;
    self.foundDevicesTableView.layer.borderColor = [UIColor blackColor].CGColor;
    UILabel *titlelabel=[[UILabel alloc] initWithFrame:CGRectMake(0,0,320,25)];
    titlelabel.text = @"请打开蓝牙设备，选择蓝牙";
    //    titlelabel.backgroundColor = [UIColor blueColor];
    titlelabel.textAlignment = NSTextAlignmentCenter;
    titlelabel.textColor = [UIColor blackColor];
    self.foundDevicesTableView.tableHeaderView = titlelabel;
    [self.view addSubview:self.foundDevicesTableView];
}

@end
