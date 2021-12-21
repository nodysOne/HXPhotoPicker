//
//  HXDateAlbumViewController.h
//  HXPhotoPickerExample
//
//  Created by Silence on 2017/10/14.
//  Copyright © 2017年 Silence. All rights reserved.
//

#import "HXAlbumCollectionViewController.h"
#import "HXPhotoViewController.h"
#import "UIViewController+HXExtension.h"
#import "HXAssetManager.h"

#define HX_hexColor(value) \
    [UIColor colorWithRed:((float)((value & 0xFF0000) >> 16)) / 255.0 \
                    green:((float)((value & 0xFF00) >> 8)) / 255.0 \
                    blue :((float)(value & 0xFF)) / 255.0 alpha:1.0]

@interface HXAlbumCollectionViewController ()
<
    HXPhotoViewControllerDelegate,
    UICollectionViewDelegate,
    UICollectionViewDataSource
>
@property (strong, nonatomic) UICollectionView *collectionView;
@property (strong, nonatomic) NSMutableArray *albumModelArray;
@property (strong, nonatomic) UILabel *authorizationLb;
@property (assign, nonatomic) BOOL orientationDidChange;
@property (strong, nonatomic) NSIndexPath *beforeOrientationIndexPath;
@end

@implementation HXAlbumCollectionViewController
- (instancetype)initWithManager:(HXPhotoManager *)manager {
    self = [super init];
    if (self) {
        self.manager = manager;
    }
    return self;
}

- (void)requestData {
    // 获取当前应用对照片的访问授权状态
    HXWeakSelf
    self.hx_customNavigationController.reloadAsset = ^(BOOL initialAuthorization) {
        if (initialAuthorization) {
            [weakSelf authorizationHandler];
        }
    };
    [self authorizationHandler];
}

- (void)authorizationHandler {
    PHAuthorizationStatus status = [HXPhotoTools authorizationStatus];
    if (status == PHAuthorizationStatusAuthorized) {
        [self getAlbumModelList:YES];
    }
#ifdef __IPHONE_14_0
    else if (@available(iOS 14, *)) {
        if (status == PHAuthorizationStatusLimited) {
            [self getAlbumModelList:YES];
            return;
        }
#endif
    else if (status == PHAuthorizationStatusDenied ||
             status == PHAuthorizationStatusRestricted) {
        [self.hx_customNavigationController.view hx_handleLoading];
        [self.view addSubview:self.authorizationLb];
        [HXPhotoTools showNoAuthorizedAlertWithViewController:self status:status];
    }
#ifdef __IPHONE_14_0
} else if (status == PHAuthorizationStatusDenied ||
           status == PHAuthorizationStatusRestricted)
{
    [self.hx_customNavigationController.view hx_handleLoading];
    [self.view addSubview:self.authorizationLb];
    [HXPhotoTools showNoAuthorizedAlertWithViewController:self status:status];
}
#endif
}
- (UIStatusBarStyle)preferredStatusBarStyle {
    if ([HXPhotoCommon photoCommon].isDark) {
        return UIStatusBarStyleLightContent;
    }
    return self.manager.configuration.statusBarStyle;
}

- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection {
    [super traitCollectionDidChange:previousTraitCollection];
#ifdef __IPHONE_13_0
    if (@available(iOS 13.0, *)) {
        if ([self.traitCollection hasDifferentColorAppearanceComparedToTraitCollection:previousTraitCollection]) {
            [self changeColor];
            [self changeStatusBarStyle];
            [self setNeedsStatusBarAppearanceUpdate];
            UIColor *authorizationColor = self.manager.configuration.authorizationTipColor;
            _authorizationLb.textColor = [HXPhotoCommon photoCommon].isDark ? [UIColor whiteColor] : authorizationColor;
        }
    }
#endif
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.extendedLayoutIncludesOpaqueBars = YES;
    self.edgesForExtendedLayout = UIRectEdgeAll;
    self.navigationController.popoverPresentationController.delegate = (id)self;
    [self requestData];
    [self setupUI];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(deviceOrientationChanged:) name:UIApplicationDidChangeStatusBarOrientationNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(customCameraViewControllerDidDoneClick) name:@"CustomCameraViewControllerDidDoneNotification" object:nil];
}

- (void)customCameraViewControllerDidDoneClick {
    NSInteger i = 0;
    for (HXAlbumModel *albumMd in self.albumModelArray) {
        albumMd.cameraCount = [self.manager cameraCount];
        if (i == 0 && !albumMd.localIdentifier) {
            albumMd.tempImage = [self.manager firstCameraModel].thumbPhoto;
        }
        i++;
    }
    [self.collectionView reloadData];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    if (self.orientationDidChange) {
        [self changeSubviewFrame];
        self.orientationDidChange = NO;
    }
}

- (void)deviceOrientationChanged:(NSNotification *)notify {
    self.orientationDidChange = YES;
}

- (void)changeSubviewFrame {
    UIInterfaceOrientation orientation = [[UIApplication sharedApplication] statusBarOrientation];
    CGFloat navBarHeight = hxNavigationBarHeight;
#pragma clang diagnostic push
#pragma clang diagnostic ignored"-Wdeprecated-declarations"
    if (orientation == UIInterfaceOrientationPortrait || orientation == UIInterfaceOrientationPortraitUpsideDown) {
        navBarHeight = hxNavigationBarHeight;
        [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarAnimationFade];
    } else if (orientation == UIInterfaceOrientationLandscapeRight || orientation == UIInterfaceOrientationLandscapeLeft) {
        [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarAnimationFade];
        if ([UIApplication sharedApplication].statusBarHidden) {
            navBarHeight = self.navigationController.navigationBar.hx_h;
        } else {
            navBarHeight = self.navigationController.navigationBar.hx_h + 20;
        }
    }
#pragma clang diagnostic pop
    CGFloat leftMargin = 0;
    CGFloat rightMargin = 0;
    CGFloat bottomMargin = hxBottomMargin;
    if (HX_IS_IPhoneX_All && (orientation == UIInterfaceOrientationLandscapeLeft || orientation == UIInterfaceOrientationLandscapeRight)) {
        leftMargin = 35;
        rightMargin = 35;
        bottomMargin = 0;
    }

    self.collectionView.contentInset = UIEdgeInsetsMake(0, leftMargin, bottomMargin, rightMargin);

#ifdef __IPHONE_13_0
    if (@available(iOS 13.0, *)) {
    } else {
        self.collectionView.scrollIndicatorInsets = UIEdgeInsetsMake(0, leftMargin, bottomMargin, rightMargin);
    }
#else
    self.collectionView.scrollIndicatorInsets = UIEdgeInsetsMake(0, leftMargin, bottomMargin, rightMargin);
#endif
    self.collectionView.frame = self.view.bounds;
    if (self.manager.configuration.albumListCollectionView) {
        self.manager.configuration.albumListCollectionView(self.collectionView);
    }

    self.navigationController.navigationBar.translucent = self.manager.configuration.navBarTranslucent;
    if (self.manager.configuration.navigationBar) {
        self.manager.configuration.navigationBar(self.navigationController.navigationBar, self);
    }
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self changeStatusBarStyle];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
}

#pragma clang diagnostic push
#pragma clang diagnostic ignored"-Wdeprecated-declarations"
- (void)changeStatusBarStyle {
    if ([HXPhotoCommon photoCommon].isDark) {
        [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent animated:YES];
        return;
    }
    [[UIApplication sharedApplication] setStatusBarStyle:self.manager.configuration.statusBarStyle animated:YES];
}

#pragma clang diagnostic pop
- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    if (!self.albumModelArray.count) {
        PHAuthorizationStatus status = [HXPhotoTools authorizationStatus];
        if (status == PHAuthorizationStatusAuthorized) {
            [self getAlbumModelList:NO];
        }
#ifdef __IPHONE_14_0
        else if (@available(iOS 14, *)) {
            if (status == PHAuthorizationStatusLimited) {
                [self getAlbumModelList:NO];
            }
        }
#endif
    }
}

- (void)setupUI {
    UILabel *lb = [[UILabel alloc] init];
    lb.textAlignment = NSTextAlignmentCenter;
    lb.font = [UIFont hx_regularPingFangOfSize:18];
    lb.text = [NSBundle hx_localizedStringForKey:@"相册"];
    self.navigationItem.titleView = lb;

    [self changeColor];
//    UIBarButtonItem *cancelItem = [[UIBarButtonItem alloc] initWithTitle:[NSBundle hx_localizedStringForKey:@"发布"] style:UIBarButtonItemStylePlain target:self action:@selector(cancelClick)];
//    [cancelItem setTitleTextAttributes:@{ NSForegroundColorAttributeName: self.manager.configuration.themeColor, NSFontAttributeName: [UIFont hx_regularPingFangOfSize:14] } forState:UIControlStateNormal];
//    self.navigationItem.rightBarButtonItem = cancelItem;
    
    UIBarButtonItem *leftItem = [[UIBarButtonItem alloc] initWithImage:[[UIImage hx_imageNamed:@"hx_nav_back"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal] style:UIBarButtonItemStylePlain target:self action: @selector(backClick)];
    self.navigationItem.leftBarButtonItem = leftItem;
    self.navigationItem.rightBarButtonItem = nil;//sunwf
    
    if (self.manager.configuration.navigationBar) {
        self.manager.configuration.navigationBar(self.navigationController.navigationBar, self);
    }
}

-(void)backClick{
    [self.navigationController dismissViewControllerAnimated:YES completion:nil];
}


- (void)changeColor {
    UIColor *backgroudColor;
    UIColor *themeColor;
    UIColor *navBarBackgroudColor;
    UIColor *navigationTitleColor;
    if ([HXPhotoCommon photoCommon].isDark) {
        backgroudColor = [UIColor colorWithRed:0.075 green:0.075 blue:0.075 alpha:1];
        themeColor = [UIColor whiteColor];
        navBarBackgroudColor = [UIColor blackColor];
        navigationTitleColor = [UIColor whiteColor];
    } else {
        backgroudColor = self.manager.configuration.albumListViewBgColor;
        themeColor = self.manager.configuration.themeColor;
        navBarBackgroudColor = self.manager.configuration.navBarBackgroudColor;
        navigationTitleColor = self.manager.configuration.navigationTitleColor;
    }
    self.view.backgroundColor = backgroudColor;
    [self.navigationController.navigationBar setTintColor:themeColor];
    self.navigationController.navigationBar.barTintColor = navBarBackgroudColor;
    self.navigationController.navigationBar.barStyle = self.manager.configuration.navBarStyle;

    if (self.manager.configuration.navBarBackgroundImage) {
        [self.navigationController.navigationBar setBackgroundImage:self.manager.configuration.navBarBackgroundImage forBarMetrics:UIBarMetricsDefault];
    }
    //    if (navBarBackgroudColor) {
    //        [self.navigationController.navigationBar setBackgroundColor:navBarBackgroudColor];
    //        [self.navigationController.navigationBar setBackgroundImage:nil forBarMetrics:UIBarMetricsDefault];
    //    }

    if (self.manager.configuration.navigationTitleSynchColor) {
        self.navigationController.navigationBar.titleTextAttributes = @{ NSForegroundColorAttributeName: themeColor };
    } else {
        if (navigationTitleColor) {
            self.navigationController.navigationBar.titleTextAttributes = @{ NSForegroundColorAttributeName: navigationTitleColor };
        } else {
            self.navigationController.navigationBar.titleTextAttributes = @{ NSForegroundColorAttributeName: [UIColor blackColor] };
        }
    }
}

- (void)configCollectionView {
    [self.view addSubview:self.collectionView];

    [self changeSubviewFrame];
}

- (void)cancelClick {
    [self.manager cancelBeforeSelectedList];
    if ([self.delegate respondsToSelector:@selector(albumCollectionViewControllerDidCancel:)]) {
        [self.delegate albumCollectionViewControllerDidCancel:self];
    }
    if (self.cancelBlock) {
        self.cancelBlock(self, self.manager);
    }
    self.manager.selectPhotoing = NO;

    BOOL selectPhotoCancelDismissAnimated = self.manager.selectPhotoCancelDismissAnimated;
    [self dismissViewControllerAnimated:selectPhotoCancelDismissAnimated completion:^{
        if ([self.delegate respondsToSelector:@selector(albumCollectionViewControllerCancelDismissCompletion:)]) {
            [self.delegate albumCollectionViewControllerCancelDismissCompletion:self];
        }
    }];
}

#pragma mark - < HXPhotoViewControllerDelegate >
- (void)photoViewController:(HXPhotoViewController *)photoViewController didDoneAllList:(NSArray<HXPhotoModel *> *)allList photos:(NSArray<HXPhotoModel *> *)photoList videos:(NSArray<HXPhotoModel *> *)videoList original:(BOOL)original {
    if ([self.delegate respondsToSelector:@selector(albumCollectionViewController:didDoneAllList:photos:videos:original:)]) {
        [self.delegate albumCollectionViewController:self didDoneAllList:allList photos:photoList videos:videoList original:original];
    }
    if (self.doneBlock) {
        self.doneBlock(allList, photoList, videoList, original, self, self.manager);
    }
}

- (void)photoViewControllerDidCancel:(HXPhotoViewController *)photoViewController {
    [self cancelClick];
}

- (void)photoViewControllerDidChangeSelect:(HXPhotoModel *)model selected:(BOOL)selected {
    if (self.albumModelArray.count > 0) {
        //        HXAlbumModel *albumModel = self.albumModelArray[model.currentAlbumIndex];
        //        if (selected) {
        //            albumModel.selectedCount++;
        //        }else {
        //            albumModel.selectedCount--;
        //        }
        //        [self.collectionView reloadItemsAtIndexPaths:@[[NSIndexPath indexPathForItem:model.currentAlbumIndex inSection:0]]];
    }
}

- (void)pushPhotoListViewControllerWithAlbumModel:(HXAlbumModel *)albumModel animated:(BOOL)animated {
    if (self.navigationController.topViewController != self) {
        [self.navigationController popToViewController:self animated:NO];
    }
    HXPhotoViewController *vc = [[HXPhotoViewController alloc] init];
    vc.manager = self.manager;
    vc.title = albumModel.albumName;
    vc.albumModel = albumModel;
    vc.delegate = self;
    [self.navigationController pushViewController:vc animated:animated];
}

- (void)getAlbumModelList:(BOOL)isFirst {
    HXWeakSelf
    if (isFirst) {
        if (self.hx_customNavigationController.cameraRollAlbumModel) {
            [self.view hx_handleLoading];
            [self pushPhotoListViewControllerWithAlbumModel:self.hx_customNavigationController.cameraRollAlbumModel animated:NO];
        } else {
            self.hx_customNavigationController.requestCameraRollCompletion = ^{
                [weakSelf.view hx_handleLoading];
                [weakSelf pushPhotoListViewControllerWithAlbumModel:weakSelf.hx_customNavigationController.cameraRollAlbumModel animated:NO];
            };
        }
    } else {
        [self configCollectionView];
        [self.view hx_showLoadingHUDText:nil];
        if (self.hx_customNavigationController.albums) {
            self.albumModelArray = self.hx_customNavigationController.albums;
            [self.collectionView reloadData];
            [self.view hx_handleLoading:YES];
        } else {
            self.hx_customNavigationController.requestAllAlbumCompletion = ^{
                weakSelf.albumModelArray = weakSelf.hx_customNavigationController.albums;
                [weakSelf.collectionView reloadData];
                [weakSelf.view hx_handleLoading:YES];
            };
        }
    }
}

#pragma mark - < UICollectionViewDataSource >
- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.albumModelArray.count;
}

- (__kindof UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    HXAlbumCollectionSingleViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"HXAlbumCollectionSingleViewCell" forIndexPath:indexPath];
    cell.bgColor = self.manager.configuration.albumListViewCellBgColor;
    cell.textColor = self.manager.configuration.albumListViewCellTextColor;
    cell.selectedBgColor = self.manager.configuration.albumListViewCellSelectBgColor;
    cell.lineViewColor = self.manager.configuration.albumListViewCellLineColor;
    cell.model = self.albumModelArray[indexPath.row];
    return cell;
}

#pragma mark - < UICollectionViewDelegate >

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    
    if (self.navigationController.topViewController != self) {
        return;
    }
    [self.hx_customNavigationController clearAssetCache];
    HXAlbumModel *model = self.albumModelArray[indexPath.row];
    [self pushPhotoListViewControllerWithAlbumModel:model animated:YES];
}

- (void)collectionView:(UICollectionView *)collectionView didEndDisplayingCell:(UICollectionViewCell *)cell forItemAtIndexPath:(NSIndexPath *)indexPath {
    [(HXAlbumCollectionSingleViewCell *)cell cancelRequest];
}


#pragma mark - < 懒加载 >

- (UICollectionView *)collectionView {
    if (!_collectionView) {
        CGFloat item_w = (HX_ScreenWidth-HX_Width(50)*2-HX_Width(20))/2.0;
        CGFloat item_h = item_w+HX_Height(118);
        UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
        layout.itemSize = CGSizeMake(item_w, item_h);
        layout.sectionInset = UIEdgeInsetsMake(HX_Height(20), HX_Width(50), HX_Height(20), HX_Height(50));
        layout.minimumLineSpacing = HX_Width(20);
        layout.minimumInteritemSpacing = HX_Height(18);
        UICollectionView *collect = [[UICollectionView alloc] initWithFrame:CGRectMake(0, 0, self.view.hx_w, self.view.hx_h) collectionViewLayout:layout];
        collect.delegate = self;
        collect.dataSource = self;
        collect.backgroundColor = [UIColor whiteColor];
        [collect registerClass:[HXAlbumCollectionSingleViewCell class] forCellWithReuseIdentifier:@"HXAlbumCollectionSingleViewCell"];
        _collectionView = collect;
    }
    return _collectionView;
}


- (UILabel *)authorizationLb {
    if (!_authorizationLb) {
        _authorizationLb = [[UILabel alloc] initWithFrame:CGRectMake(0, 200, self.view.frame.size.width, 100)];
        _authorizationLb.text = [NSBundle hx_localizedStringForKey:@"无法访问照片\n请点击这里前往设置中允许访问照片"];
        _authorizationLb.textAlignment = NSTextAlignmentCenter;
        _authorizationLb.numberOfLines = 0;
        UIColor *authorizationColor = self.manager.configuration.authorizationTipColor;
        _authorizationLb.textColor = [HXPhotoCommon photoCommon].isDark ? [UIColor whiteColor] : authorizationColor;
        _authorizationLb.font = [UIFont systemFontOfSize:15];
        _authorizationLb.userInteractionEnabled = YES;
        [_authorizationLb addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(goSetup)]];
    }
    return _authorizationLb;
}

- (void)dealloc {
    self.manager.selectPhotoing = NO;
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"CustomCameraViewControllerDidDoneNotification" object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidChangeStatusBarOrientationNotification object:nil];
}

- (void)goSetup {
    NSURL *url = [NSURL URLWithString:UIApplicationOpenSettingsURLString];
    if (@available(iOS 10.0, *)) {
        [[UIApplication sharedApplication] openURL:url options:@{} completionHandler:nil];
    } else {
        [[UIApplication sharedApplication] openURL:url];
    }
}

@end

@interface HXAlbumCollectionSingleViewCell ()
@property (strong, nonatomic) UIImageView *coverView1;
@property (strong, nonatomic) UILabel *albumNameLb;
@property (strong, nonatomic) UILabel *photoNumberLb;
@property (assign, nonatomic) PHImageRequestID requestId1;
@property (assign, nonatomic) PHImageRequestID requestId2;
@property (assign, nonatomic) PHImageRequestID requestId3;
@end

@implementation HXAlbumCollectionSingleViewCell


- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self setupUI];
    }
    return self;
}
- (void)setupUI {
    [self.contentView addSubview:self.coverView1];
    [self.contentView addSubview:self.albumNameLb];
    [self.contentView addSubview:self.photoNumberLb];
}

- (void)cancelRequest {
    if (self.requestId1) {
        [[PHImageManager defaultManager] cancelImageRequest:self.requestId1];
        self.requestId1 = -1;
    }
}

- (void)setModel:(HXAlbumModel *)model {
    _model = model;
    [self changeColor];
    self.albumNameLb.text = self.model.albumName;
    if (!model.assetResult && model.localIdentifier) {
        HXWeakSelf
        [model getResultWithCompletion:^(HXAlbumModel *albumModel) {
            if (albumModel == weakSelf.model) {
                [weakSelf setAlbumImage];
            }
        }];
    } else {
        [self setAlbumImage];
    }
    if (!model.assetResult || !model.count) {
        self.coverView1.image = model.tempImage ? : [UIImage hx_imageNamed:@"hx_yundian_tupian"];
    }
}

- (void)setAlbumImage {
    NSInteger photoCount = self.model.count;
    HXWeakSelf
    PHAsset *asset = self.model.assetResult.lastObject;
    self.requestId1 = [HXAssetManager requestThumbnailImageForAsset:asset targetWidth:300 completion:^(UIImage *_Nonnull result, NSDictionary<NSString *, id> *_Nonnull info) {
        if (weakSelf.model.assetResult.lastObject == asset && result) {
            weakSelf.coverView1.image = result;
        }
    }];

    self.photoNumberLb.text = [@(photoCount + self.model.cameraCount).stringValue hx_countStrBecomeComma];
    if (self.getResultCompleteBlock) {
        self.getResultCompleteBlock(photoCount + self.model.cameraCount, self);
    }
}

- (void)layoutSubviews {
    [super layoutSubviews];
    self.coverView1.frame = CGRectMake(0, 0, self.hx_w, self.hx_w);
    CGFloat albumNameLbX = 0;
    CGFloat albumNameLbY = CGRectGetMaxY(self.coverView1.frame) + HX_Height(20);
    self.albumNameLb.frame = CGRectMake(albumNameLbX, albumNameLbY, self.hx_w, HX_Height(48));
    self.photoNumberLb.frame = CGRectMake(albumNameLbX, CGRectGetMaxY(self.albumNameLb.frame), self.hx_w, HX_Height(34));

}

- (void)dealloc {
    //    [self cancelRequest];
}

#pragma mark - < cell懒加载 >

- (UIImageView *)coverView1 {
    if (!_coverView1) {
        _coverView1 = [[UIImageView alloc] init];
        _coverView1.contentMode = UIViewContentModeScaleAspectFill;
        _coverView1.clipsToBounds = YES;
        _coverView1.layer.borderColor = [UIColor whiteColor].CGColor;
        _coverView1.layer.borderWidth = 0.5f;
    }
    return _coverView1;
}

- (UILabel *)albumNameLb {
    if (!_albumNameLb) {
        _albumNameLb = [[UILabel alloc] init];
        _albumNameLb.font = [UIFont hx_regularPingFangOfSize:16];
        _albumNameLb.textColor = HX_hexColor(0x040B29);
        //_albumNameLb.textColor = [UIColor colorWithHexString:@"#040B29"];
    }
    return _albumNameLb;
}

- (UILabel *)photoNumberLb {
    if (!_photoNumberLb) {
        _photoNumberLb = [[UILabel alloc] init];
        _albumNameLb.textColor = HX_hexColor(0x9B9DA9);
//        _photoNumberLb.textColor = [UIColor colorWithHexString:@"#9B9DA9"];
        _photoNumberLb.font = [UIFont hx_regularPingFangOfSize:14];
    }
    return _photoNumberLb;
}


- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection {
    [super traitCollectionDidChange:previousTraitCollection];
#ifdef __IPHONE_13_0
    if (@available(iOS 13.0, *)) {
        if ([self.traitCollection hasDifferentColorAppearanceComparedToTraitCollection:previousTraitCollection]) {
            [self changeColor];
        }
    }
#endif
}

- (void)changeAlbumNameTextColor {
    if ([HXPhotoCommon photoCommon].isDark) {
        self.albumNameLb.textColor = [UIColor whiteColor];
    } else {
        self.albumNameLb.textColor = HX_hexColor(0x040B29);
//        self.albumNameLb.textColor = [UIColor colorWithHexString:@"#040B29"];
    }
}

- (void)changeColor {
    self.backgroundColor = [HXPhotoCommon photoCommon].isDark ? [UIColor colorWithRed:0.075 green:0.075 blue:0.075 alpha:1] : self.bgColor;
    [self changeAlbumNameTextColor];
}

@end
