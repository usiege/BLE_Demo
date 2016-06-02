//
//  AppDelegate.m
//  BLE_Demo
//
//  Created by 先锋电子技术 on 16/5/17.
//  Copyright © 2016年 先锋电子技术. All rights reserved.
//

#import "AppDelegate.h"

#import "FoundNewPortViewController.h"

@interface AppDelegate () 
{
    
}
@end

@implementation AppDelegate

- (instancetype)init{
    if (self = [super init]) {
        
    }
    return self;
}


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    
    FoundNewPortViewController *foundNewPortVC = [[FoundNewPortViewController alloc] init];
    UINavigationController* foundNav = [[UINavigationController alloc] initWithRootViewController:foundNewPortVC];
    
    [[UINavigationBar appearance] setTitleTextAttributes:@{NSForegroundColorAttributeName:[UIColor whiteColor]}];
    [[UINavigationBar appearance] setBarTintColor:[UIColor colorWithRed:20/255.0 green:155/255.0 blue:213/255.0 alpha:1.0]];
    
    self.window.rootViewController = foundNav;
    
    [self setupCompontents];
    
    int a = 1;
    int b = a;
    printf("------>%p %p %p\n",a,1,b);
    
    
    [self.window makeKeyAndVisible];
    return YES;
}

- (void)testNewD:(NSString *)str{
    str = @"321";
    
}

- (void)testData:(NSString **)string{
    //    NSString* oriString = @"123";
    ////    NSString** oriSS = &oriString;
    //
    //    [self testData:&oriString];
    //
    //    //
    //    [self testNewD:oriString];
    //
    //    NSLog(@"%@",oriString);
    //
    //    //
    //    NSError* error = nil;
    //
    //    [NSURLConnection sendSynchronousRequest:nil returningResponse:nil error:&error];
    //    
    //    if(error){
    //        
    //    }
    *string = @"进来了";
}

- (void)setupCompontents{
//    [BLEManageController sharedInstance];
}

- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

#pragma mark - Split view


@end
