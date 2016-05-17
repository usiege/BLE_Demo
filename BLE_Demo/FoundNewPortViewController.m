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
#import "BLEManageController.h"

static NSString* RIGHT_BUTTON_STATE_NORMAL = @"正常";
static NSString* RIGHT_BUTTON_STATE_SCAN = @"扫描";
static NSString* RIGHT_BUTTON_STATE_STOP = @"停止";

@interface FoundNewPortViewController ()
{
  BOOL addInputDeviceObs;
  BOOL addOutputDeviceObs;
    
    NSString* rButtonState;
    
    BLEManageController *Public_BleController;
}
@property (nonatomic) UIActivityIndicatorView* aInView;
@property (nonatomic) UIButton* rightButton;

@end

@implementation FoundNewPortViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        self.title = @"BLE Demo";
        Public_BleController = [BLEManageController sharedInstance];
    }
    return self;
}

- (void)viewDidAppear:(BOOL)animated{
    [self searchDevice];
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleDefault];
}

-(void)searchDevice{
    [Public_BleController startScanWithChannelType:self.channelType];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor blackColor];

    addInputDeviceObs = false;
    addOutputDeviceObs = false;
    
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
    titlelabel.backgroundColor = [UIColor blueColor];
    titlelabel.textAlignment = NSTextAlignmentCenter;
    titlelabel.textColor = [UIColor blackColor];
    self.foundDevicesTableView.tableHeaderView = titlelabel;
    [self.view addSubview:self.foundDevicesTableView];
    
    [Public_BleController.foundDevicesArray removeAllObjects];
    
    
}

- (void)rightButtonClick:(UIButton *)rightButton{
    rightButton.selected = !rightButton.selected;
    
    if (rightButton.selected) {
        [self.aInView startAnimating];
        [Public_BleController startScanWithChannelType:self.channelType];
    }else{
        [self.aInView stopAnimating];
        [Public_BleController stopScan];
    }
}


- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context{
    
     if ([keyPath isEqualToString:@"inputDevice"])
    {
        NSLog(@"there is a inputDevice");
    }
     else if ([keyPath isEqualToString:@"outputDevice"])
    {
        NSLog(@"there is a outputDevice");
    }
      else
    {
        [self.foundDevicesTableView reloadData];
        
        [Public_BleController stopScan];
        [self.aInView stopAnimating];
        self.rightButton.selected = NO;
        
        NSLog(@"Deveces info count:------>%d",Public_BleController.foundDevicesArray.count);
    }

}

- (void)viewWillDisappear:(BOOL)animated{
    
}

- (void)viewDidUnload{
    
    [Public_BleController removeObserver:self forKeyPath:@"countOfFoundDevices"];
    
    if(addInputDeviceObs)
    {
        [Public_BleController removeObserver:self forKeyPath:@"inputDevice"];
        addInputDeviceObs = false;
    }
    if(addOutputDeviceObs)
    {
        [Public_BleController removeObserver:self forKeyPath:@"outputDevice"];
        addOutputDeviceObs = false;
    }
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
    return Public_BleController.foundDevicesArray.count;
}


- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    return 60.0;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{

    UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle  reuseIdentifier:@"FoundNewPortViewControllerCellReusedID"];
    
    DeviceInforModel *device = [Public_BleController.foundDevicesArray objectAtIndex:indexPath.row];
    
    cell.textLabel.text = device.advertisementDataLocal;
    return cell;
    
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];

    DeviceInforModel *device = [Public_BleController.foundDevicesArray objectAtIndex:indexPath.row];
  
    [self connectDevice:device];
    
    CardactionViewController *cardDetial = [[CardactionViewController alloc]init];
    [self.navigationController pushViewController:cardDetial animated:YES];
 }



- (void)connectDevice:(DeviceInforModel*)device{
  
    if (self.channelType == _channelType_Input)
    {
        addInputDeviceObs = true;
    }
     else
    {
        addOutputDeviceObs = true;
    }
    [Public_BleController createDataChannelWithDevice:device withType:self.channelType];
    
 }

@end
