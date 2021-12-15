//
//  HXPhotoPreviewBottomCollectionView.h
//  LappTest
//
//  Created by 张嘉迁 on 2020/11/27.
//

#import <UIKit/UIKit.h>
#import "HXPhotoTools.h"


NS_ASSUME_NONNULL_BEGIN

@protocol HXPhotoPreviewBottomCollectionViewDelegate <NSObject>

- (void)photoPreviewBottomCollectionViewDidItem:(HXPhotoModel *)model currentIndex:(NSInteger)currentIndex beforeIndex:(NSInteger)beforeIndex;

@end

@interface HXPhotoPreviewBottomCollectionView : UIView

@property (strong, nonatomic) NSMutableArray *modelArray;
@property (assign, nonatomic) NSInteger currentIndex;
@property (assign, nonatomic) NSInteger selectCount;
@property (weak, nonatomic) id<HXPhotoPreviewBottomCollectionViewDelegate> delegate;


- (instancetype)initWithFrame:(CGRect)frame modelArray:(NSArray *)modelArray manager:(HXPhotoManager *)manager;
- (void)reloadData;
- (void)insertModel:(HXPhotoModel *)model;
- (void)deleteModel:(HXPhotoModel *)model;
- (void)deselected;
- (void)deselectedWithIndex:(NSInteger)index;

@end

@interface HXPhotoPreviewBottomCollectionViewCell : UICollectionViewCell

@property (strong, nonatomic) HXPhotoModel *model;
@property (strong, nonatomic) HXPhotoManager *manager;
- (void)cancelRequest;

@end


NS_ASSUME_NONNULL_END
