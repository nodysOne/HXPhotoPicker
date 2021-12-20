//
//  HXPhotoPreviewBottomCollectionView.m
//  LappTest
//
//  Created by 张嘉迁 on 2020/11/27.
//

#import "HXPhotoPreviewBottomCollectionView.h"
#import "HXPhotoManager.h"
#import "UIImageView+HXExtension.h"
#import "HXPhotoEdit.h"
#import "UIColor+HXExtension.h"
#import "LColor_OC.h" //sunwf

@interface HXPhotoPreviewBottomCollectionView ()<UICollectionViewDelegate, UICollectionViewDataSource>

@property (strong, nonatomic) UICollectionView *collectionView;
@property (strong, nonatomic) HXPhotoManager *manager;
@property (strong, nonatomic) UIView *lineView;
@property (strong, nonatomic) NSIndexPath *currentIndexPath;


@end

@implementation HXPhotoPreviewBottomCollectionView


- (instancetype)initWithFrame:(CGRect)frame modelArray:(NSArray *)modelArray manager:(HXPhotoManager *)manager {
    self = [super initWithFrame:frame];
    if (self) {
        
        self.backgroundColor = [UIColor whiteColor];
        self.manager = manager;
        self.modelArray = [NSMutableArray arrayWithArray:modelArray];
        
        [self addSubview:self.collectionView];
        [self.collectionView registerClass:[HXPhotoPreviewBottomCollectionViewCell class] forCellWithReuseIdentifier:@"cell"];
        [self addSubview:self.lineView];
    }
    return self;
}




- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return [self.modelArray count];
}

- (__kindof UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    
    HXPhotoPreviewBottomCollectionViewCell *cell = (HXPhotoPreviewBottomCollectionViewCell *)[collectionView dequeueReusableCellWithReuseIdentifier:@"cell" forIndexPath:indexPath];
    cell.manager = self.manager;
    HXPhotoModel *model = self.modelArray[indexPath.item];
    cell.model = model;
    return cell;
}

#pragma mark - < UICollectionViewDelegate >
- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    if ([self.delegate respondsToSelector:@selector(photoPreviewBottomCollectionViewDidItem:currentIndex:beforeIndex:)]) {
        [self.delegate photoPreviewBottomCollectionViewDidItem:self.modelArray[indexPath.item] currentIndex:indexPath.item beforeIndex:self.currentIndex];
    }
}
- (void)collectionView:(UICollectionView *)collectionView didEndDisplayingCell:(UICollectionViewCell *)cell forItemAtIndexPath:(NSIndexPath *)indexPath {
    [(HXPhotoPreviewBottomCollectionViewCell *)cell cancelRequest];
}
- (void)deselectedWithIndex:(NSInteger)index {
    if (index < 0 || index > self.modelArray.count - 1 || self.currentIndex < 0) {
        return;
    }
    [self.collectionView deselectItemAtIndexPath:[NSIndexPath indexPathForItem:index inSection:0] animated:NO];
    _currentIndex = -1;
}

- (void)deselected {
    if (self.currentIndex < 0 || self.currentIndex > self.modelArray.count - 1) {
        return;
    }
    [self.collectionView deselectItemAtIndexPath:[NSIndexPath indexPathForItem:self.currentIndex inSection:0] animated:NO];
    _currentIndex = -1;
}

- (void)setSelectCount:(NSInteger)selectCount {
    _selectCount = selectCount;
    [self setHidden:(selectCount <= 0)];
}


- (void)reloadData {
    [self.collectionView reloadData];
    if (self.currentIndex >= 0 && self.currentIndex < self.modelArray.count) {
        [self.collectionView selectItemAtIndexPath:self.currentIndexPath animated:YES scrollPosition:UICollectionViewScrollPositionCenteredHorizontally];
    }
}

- (void)insertModel:(HXPhotoModel *)model {
    [self.modelArray addObject:model];
    [self.collectionView insertItemsAtIndexPaths:@[[NSIndexPath indexPathForItem:self.modelArray.count - 1 inSection:0]]];
    [self.collectionView selectItemAtIndexPath:[NSIndexPath indexPathForItem:self.modelArray.count - 1 inSection:0] animated:YES scrollPosition:UICollectionViewScrollPositionCenteredHorizontally];
    self.currentIndex = self.modelArray.count - 1;
}
- (void)deleteModel:(HXPhotoModel *)model {
    if ([self.modelArray containsObject:model] && self.currentIndex >= 0) {
        NSInteger index = [self.modelArray indexOfObject:model];
        [self.modelArray removeObject:model];
        [self.collectionView deleteItemsAtIndexPaths:@[[NSIndexPath indexPathForItem:index inSection:0]]];
        _currentIndex = -1;
    }
}

- (void)setCurrentIndex:(NSInteger)currentIndex {
    if (_currentIndex == currentIndex) {
        //return; sunwf
    }
    if (currentIndex < 0 || currentIndex > self.modelArray.count - 1) {
        return;
    }
    _currentIndex = currentIndex;
    self.currentIndexPath = [NSIndexPath indexPathForItem:currentIndex inSection:0];
    
    [self.collectionView selectItemAtIndexPath:self.currentIndexPath animated:YES scrollPosition:UICollectionViewScrollPositionCenteredHorizontally];
}


- (UICollectionView *)collectionView {
    if (!_collectionView) {
        UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
        layout.itemSize = CGSizeMake(HX_Width(160), HX_Width(160));
        layout.sectionInset = UIEdgeInsetsMake(0, HX_Width(32), 0, HX_Width(32));
        layout.minimumLineSpacing = 8;
        layout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
        UICollectionView *collect = [[UICollectionView alloc] initWithFrame:CGRectMake(0, HX_Height(32), HX_ScreenWidth, HX_Height(160)) collectionViewLayout:layout];
        collect.delegate = self;
        collect.dataSource = self;
        collect.backgroundColor = [UIColor whiteColor];
        collect.showsHorizontalScrollIndicator = NO;
        _collectionView = collect;
    }
    return _collectionView;
}

- (UIView *)lineView {
    if (!_lineView) {
        _lineView = [[UIView alloc] initWithFrame:CGRectMake(0, self.frame.size.height-1, HX_ScreenWidth, 1)];
        _lineView.backgroundColor = [[LColor_OC colorType: line] color];//sunwf
    }
    return _lineView;
}


@end


@interface HXPhotoPreviewBottomCollectionViewCell ()

@property (strong, nonatomic) UIImageView *imageView;
@property (strong, nonatomic) UIView *editTipView;
@property (strong, nonatomic) UIImageView *editTipIcon;
@property (assign, nonatomic) PHImageRequestID requestID;
@end

@implementation HXPhotoPreviewBottomCollectionViewCell
- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection {
    [super traitCollectionDidChange:previousTraitCollection];
#ifdef __IPHONE_13_0
    if (@available(iOS 13.0, *)) {
        if ([self.traitCollection hasDifferentColorAppearanceComparedToTraitCollection:previousTraitCollection]) {
            
            UIColor *themeColor = [HXPhotoCommon photoCommon].isDark ? [UIColor colorWithRed:0.1 green:0.1 blue:0.1 alpha:1] : self.manager.configuration.previewBottomSelectColor;
            
            self.layer.borderColor = self.selected ? themeColor.CGColor : nil;
            
        }
    }
#endif
}
- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self setupUI];
    }
    return self;
}
- (void)setupUI {
    self.layer.cornerRadius = 2;
    self.layer.masksToBounds = YES;
    [self.contentView addSubview:self.imageView];
    [self.contentView addSubview:self.editTipView];
}
- (void)setModel:(HXPhotoModel *)model {
    _model = model;
    self.editTipView.hidden = !(model.photoEdit);
    if (model.photoEdit) {
        self.imageView.image = model.photoEdit.editPosterImage;
    }else {
        HXWeakSelf
        if (model.thumbPhoto) {
            self.imageView.image = model.thumbPhoto;
            if (model.networkPhotoUrl) {
                [self.imageView hx_setImageWithModel:model progress:^(CGFloat progress, HXPhotoModel *model) {
                    if (weakSelf.model == model) {
                        
                    }
                } completed:^(UIImage *image, NSError *error, HXPhotoModel *model) {
                    if (weakSelf.model == model) {
                        if (error != nil) {
                        }else {
                            if (image) {
                                weakSelf.imageView.image = image;
                            }
                        }
                    }
                }];
            }
        }else {
            self.requestID = [self.model requestThumbImageCompletion:^(UIImage *image, HXPhotoModel *model, NSDictionary *info) {
                if (weakSelf.model == model) {
                    weakSelf.imageView.image = image;
                }
            }];
        }
    }
    
}
- (void)layoutSubviews {
    [super layoutSubviews];
    self.imageView.frame = self.bounds;
    self.editTipView.frame = self.imageView.frame;
    self.editTipIcon.center = CGPointMake(self.hx_w / 2, self.hx_h / 2);
}
- (UIImageView *)imageView {
    if (!_imageView) {
        _imageView = [[UIImageView alloc] init];
        _imageView.contentMode = UIViewContentModeScaleAspectFill;
        _imageView.clipsToBounds = YES;
    }
    return _imageView;
}
- (UIView *)editTipView {
    if (!_editTipView) {
        _editTipView = [[UIView alloc] init];
        _editTipView.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.3f];
        [_editTipView addSubview:self.editTipIcon];
    }
    return _editTipView;;
}
- (UIImageView *)editTipIcon {
    if (!_editTipIcon) {
        _editTipIcon = [[UIImageView alloc] initWithImage:[UIImage hx_imageNamed:@"hx_photo_edit_show_tip"]];
        _editTipIcon.hx_size = CGSizeMake(15.5, 11);
    }
    return _editTipIcon;
}

- (void)setManager:(HXPhotoManager *)manager {
    _manager = manager;
    _manager.configuration.previewBottomSelectColor = manager.configuration.previewBottomSelectColor ? : manager.configuration.themeColor;
    self.layer.borderWidth = self.selected ? manager.configuration.previewBottomSelectBorderWidth : 0; //sunwf
    self.layer.borderColor = self.selected ? [([HXPhotoCommon photoCommon].isDark ? [UIColor colorWithRed:0.1 green:0.1 blue:0.1 alpha:1] : manager.configuration.previewBottomSelectColor) colorWithAlphaComponent:1].CGColor : nil;
}

- (void)setSelected:(BOOL)selected {
    [super setSelected:selected];
    self.layer.borderWidth = selected ? self.manager.configuration.previewBottomSelectBorderWidth : 0; //sunwf
    self.layer.borderColor = selected ? [([HXPhotoCommon photoCommon].isDark ? [UIColor colorWithRed:0.1 green:0.1 blue:0.1 alpha:1] : self.manager.configuration.previewBottomSelectColor) colorWithAlphaComponent:1].CGColor : nil;
}
- (void)cancelRequest {
    if (self.requestID) {
        [[PHImageManager defaultManager] cancelImageRequest:self.requestID];
        self.requestID = -1;
    }
}
- (void)dealloc {
    [self cancelRequest];
}
@end
