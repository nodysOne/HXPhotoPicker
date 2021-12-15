//
//  HXBaseViewController.m
//  LappTest
//
//  Created by 张嘉迁 on 2020/11/29.
//

#import "HXBaseViewController.h"
#import "UIImage+HXExtension.h"
#import "HXPhotoTools.h"

@interface HXBaseViewController ()

@end

@implementation HXBaseViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    
    self.navigationController.navigationBar.shadowImage = [[UIImage alloc] init];
    [self.navigationController.navigationBar setBarTintColor:[UIColor whiteColor]];
}

- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleDarkContent;
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
