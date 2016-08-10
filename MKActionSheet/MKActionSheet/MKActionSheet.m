//
//  MKActionSheet.m
//  MKActionSheet
//
//  Created by xiaomk on 16/6/1.
//  Copyright © 2016年 MK. All rights reserved.
//

#import "MKActionSheet.h"
#import "MKActionSheetCell.h"
#import "NSObject+MKASAdditions.h"

#ifndef MKActionSheetDefine
#define MKSCREEN_WIDTH     [UIScreen mainScreen].bounds.size.width
#define MKSCREEN_HEIGHT    [UIScreen mainScreen].bounds.size.height
#define MKSCREEN_BOUNDS    [UIScreen mainScreen].bounds
#define MKCOLOR_RGBA(r, g, b, a)    [UIColor colorWithRed:(r/255.0f) green:(g/255.0f) blue:(b/255.0f) alpha:(a)]
#endif

#pragma mark - ***** MKActionSheet ******
@interface MKActionSheet()<UITableViewDelegate, UITableViewDataSource>{
    CGFloat _titleViewH;    /*!< title view height */
}
@property (nonatomic, strong) NSMutableArray *buttonTitles;             /*!< button titles array */
@property (nonatomic, strong) NSMutableArray *objArray;                 /*!< objects array */

@property (nonatomic, strong) UIWindow *bgWindow;
@property (nonatomic, strong) UIView *shadeView;
@property (nonatomic, strong) UIView *sheetView;
@property (nonatomic, strong) UITableView *tableView;

@property (nonatomic, strong) UIView *blurView;
@property (nonatomic, strong) UIToolbar *blurBar;

@property (nonatomic, strong) UIView *titleView;
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UIButton *cancelButton;

@property (nonatomic, strong) UIButton *confirmButton;

@property (nonatomic, assign) BOOL paramIsObject;                       /*!< init array is model or dictionary */

@end


@implementation MKActionSheet

#pragma mark - ***** init method ******

- (instancetype)initWithTitle:(NSString *)title buttonTitleArray:(NSArray *)buttonTitleArray{
    if (self = [super init]) {
        self.title = title;
        self.buttonTitles = [[NSMutableArray alloc] initWithArray:buttonTitleArray];
        self.selectType = MKActionSheetSelectType_common;
        [self initData];
    }
    
    return self;
}

- (instancetype)initWithTitle:(NSString *)title buttonTitleArray:(NSArray *)buttonTitleArray selectType:(MKActionSheetSelectType)selectType{
    if (self = [super init]) {
        self.title = title;
        self.buttonTitles = [[NSMutableArray alloc] initWithArray:buttonTitleArray];
        self.selectType = selectType;
        [self initData];
    }
    return self;
}

/** init with object array */
- (instancetype)initWithTitle:(NSString *)title objArray:(NSArray *)objArray titleKey:(NSString *)titleKey{
    if (self = [super init]) {
        self.title = title;
        self.titleKey = titleKey;
        self.objArray = [[NSMutableArray alloc] initWithArray:objArray];
        self.selectType = MKActionSheetSelectType_common;
        self.paramIsObject = YES;
        [self initData];
    }
    return self;
}

- (instancetype)initWithTitle:(NSString *)title objArray:(NSArray *)objArray titleKey:(NSString *)titleKey selectType:(MKActionSheetSelectType)selectType{
    if (self = [super init]) {
        self.title = title;
        self.titleKey = titleKey;
        self.objArray = [[NSMutableArray alloc] initWithArray:objArray];
        self.selectType = selectType;
        self.paramIsObject = YES;
        [self initData];
    }
    return self;
}

- (instancetype)initWithTitle:(NSString *)title buttonTitles:(NSString *)buttonTitle, ... NS_REQUIRES_NIL_TERMINATION{
    if (self = [super init]) {
        self.title = title;
        self.selectType = MKActionSheetSelectType_common;

        self.buttonTitles = [[NSMutableArray alloc] init];
        if (buttonTitle) {
            [self.buttonTitles addObject:buttonTitle];
            va_list args;
            va_start(args, buttonTitle);
            NSString *btnTitle;
            while ((btnTitle = va_arg(args, NSString *))) {
                [self.buttonTitles addObject:btnTitle];
            }
            va_end(args);
        }
        [self initData];
    }
    return self;
}

- (instancetype)initWithTitle:(NSString *)title selectType:(MKActionSheetSelectType)selectType buttonTitles:(NSString *)buttonTitle, ... NS_REQUIRES_NIL_TERMINATION{
    if (self = [super init]) {
        self.title = title;
        self.selectType = selectType;

        self.buttonTitles = [[NSMutableArray alloc] init];
        if (buttonTitle) {
            [self.buttonTitles addObject:buttonTitle];
            va_list args;
            va_start(args, buttonTitle);
            NSString *btnTitle;
            while ((btnTitle = va_arg(args, NSString *))) {
                [self.buttonTitles addObject:btnTitle];
            }
            va_end(args);
        }
        [self initData];
    }
    return self;
}



#pragma mark - ***** methods ******
/** init data */
- (void)initData{
    //默认样式
    _titleColor = MKCOLOR_RGBA(100.0f, 100.0f, 100.0f, 1.0f);
    _titleFont = [UIFont systemFontOfSize:14];
    _titleAlignment = NSTextAlignmentCenter;
    
    _buttonTitleColor = MKCOLOR_RGBA(51.0f,51.0f,51.0f,1.0f);
    _buttonTitleFont = [UIFont systemFontOfSize:18.0f];
    _buttonOpacity = 0.6;
    _buttonHeight = 48.0f;
    _buttonTitleAlignment = MKActionSheetButtonTitleAlignment_center;

    _destructiveButtonTitleColor = MKCOLOR_RGBA(250.0f, 10.0f, 10.0f, 1.0f);
    _destructiveButtonIndex = -1;
    _cancelTitle = @"取消";
    _titleMargin = 20.0f;
    _animationDuration = 0.3f;
    _blurOpacity = 0.0f;
    _blackgroundOpacity = 0.3f;
    _maxShowButtonCount = -1;
    _needCancelButton = YES;
    
    //以 object array 初始化，默认没有取消按钮
    if (self.paramIsObject) {
        _needCancelButton = NO;
    }
    
    // 根据 selectType 初始化默认样式
    if (_selectType == MKActionSheetSelectType_multiselect || _selectType == MKActionSheetSelectType_selected) {       //多选 样式， title 默认 居左对齐，无取消按钮
        _titleAlignment = NSTextAlignmentLeft;
        _buttonTitleAlignment = MKActionSheetButtonTitleAlignment_left;
        _needCancelButton = NO;
    }
}

- (void)setImageKey:(NSString *)imageKey imageValueType:(MKActionSheetButtonImageValueType)imageValueType{
    NSAssert(imageKey && imageKey.length > 0 && imageValueType , @"设置带 icon 图片的类型， imageKey 和 imageValueType 不能为nil 或者 空");
    _imageKey = imageKey;
    _imageValueType = imageValueType;
    // 带icon 图片的 样式 模式也是 左对齐
    _buttonTitleAlignment = MKActionSheetButtonTitleAlignment_left;
    _titleAlignment = NSTextAlignmentLeft;
}

- (void)setSelectedIndex:(NSInteger)selectedIndex{
    if (self.selectType == MKActionSheetSelectType_selected) {
        _selectedIndex = selectedIndex;
    }else{
        NSAssert(NO, @"初始化 selectType = MKActionSheetSelectType_selected 时 设置 selectedIndex 才有效");
    }
}

- (void)addButtonWithTitle:(NSString *)title{
    NSAssert(!self.paramIsObject, @"以 objArray 初始化时，不能直接添加 title, 请使用 addButtonWithObj:(id)obj");
    if (!_buttonTitles) {
        _buttonTitles = [[NSMutableArray alloc] init];
    }
    [_buttonTitles addObject:title];
}

- (void)addButtonWithObj:(id)obj{
    NSAssert(self.paramIsObject, @"不是由 objArray 初始化时，不能直接添加 object, 请使用 addButtonWithTitle:(NSString *)title");
    if (!_objArray) {
        _objArray = [[NSMutableArray alloc] init];
    }
    [_objArray addObject:obj];
}


#pragma mark - ***** show ******
- (void)showWithDelegate:(id<MKActionSheetDelegate>)delegate{
    if (delegate) {
        _delegate = delegate;
    }
    [self show];
}

- (void)showWithBlock:(MKActionSheetBlock)block{
    NSAssert(self.selectType != MKActionSheetSelectType_multiselect, @"多选样式 应该使用 showWithMultiselectBlock: 方法");
    if (block) {
        _block = block;
    }
    [self show];
}

- (void)showWithMultiselectBlock:(MKActionSheetMultiselectBlock)multiselectblock{
    NSAssert(self.selectType == MKActionSheetSelectType_multiselect, @"非多选模式，应该使用 showWithBlock: 方法");
    if (multiselectblock) {
        _multiselectBlock = multiselectblock;
    }
    [self show];
}

- (void)show{
    if (self.paramIsObject) {
        NSAssert(self.titleKey && self.titleKey.length > 0, @"titleKey 不能为nil 或者 空, 必须是有效的 NSString");
        for (id obj in self.objArray) {
            id titleValue = [obj valueForKey:self.titleKey];
            NSAssert(titleValue && [titleValue isKindOfClass:[NSString class]], @"obj.titleKey 必须为 有效的 NSString");
        }
        self.buttonTitles = [self.objArray valueForKey:self.titleKey];
    }
    
    if (self.blackgroundOpacity < 0.1f) {
        self.blackgroundOpacity = 0.1f;
    }
    
    [self setupMainView];
    self.bgWindow.hidden = NO;
    [self.bgWindow addSubview:self];
    
    [UIView animateWithDuration:self.animationDuration delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
        [self.shadeView setAlpha:self.blackgroundOpacity];
        [self.shadeView setUserInteractionEnabled:YES];

        CGRect frame = self.sheetView.frame;
        frame.origin.y = MKSCREEN_HEIGHT - frame.size.height;
        self.sheetView.frame = frame;
    } completion:nil];
}

#pragma mark - ***** dismiss ******
- (void)btnOnclicked:(UIButton *)sender{
    NSInteger index = sender.tag;
    
    if (self.selectType == MKActionSheetSelectType_multiselect){
        //多选
        if (self.isNeedCancelButton && sender.tag == self.buttonTitles.count) { //点击取消按钮
            [self dismissWithButtonIndex:index];
        }else{
            NSString *title = [self.buttonTitles objectAtIndex:index];
            
            UIButton *btnSelect = (UIButton *)[sender viewWithTag:100];
            if (btnSelect) {
                btnSelect.selected = !btnSelect.selected;
                title.mk_isSelect = btnSelect.isSelected;
            }
        }
    }else if(self.selectType == MKActionSheetSelectType_selected){
        self.selectedIndex = sender.tag;
        [self.tableView reloadData];
        [self dismissWithButtonIndex:index];
    }else{
        [self dismissWithButtonIndex:index];
    }
}

- (void)dismissWithButtonIndex:(NSInteger)index{
    [self dismiss];
    
    if (self.selectType == MKActionSheetSelectType_multiselect) {
        //多选样式下 只有 取消按钮才会走这里
        if (self.multiselectBlock) {
            self.multiselectBlock(self, nil);
        }
        if ([self.delegate respondsToSelector:@selector(actionSheet:selectArray:)]) {
            [self.delegate actionSheet:self selectArray:nil];
        }
    }else{
        if (self.block) {
            self.block(self, index);
        }
    }
    if (self.delegate && [self.delegate respondsToSelector:@selector(actionSheet:didClickButtonAtIndex:)]) {
        [self.delegate actionSheet:self didClickButtonAtIndex:index];
    }
}

/** 多选确认按钮 */
- (void)confirmButtonOnclick:(UIButton *)sender{
    [self dismiss];
    
    NSMutableArray *selectedArray = [[NSMutableArray alloc] init];
    
    for (NSInteger i = 0; i < self.buttonTitles.count; i++) {
        NSString *title = [self.buttonTitles objectAtIndex:i];
        if (title.mk_isSelect) {
            if (self.paramIsObject){
                [selectedArray addObject:[self.objArray objectAtIndex:i]];
            }else{
                [selectedArray addObject:[self.buttonTitles objectAtIndex:i]];
            }
        }
        title.mk_isSelect = NO;
    }
    
    if (self.multiselectBlock) {
        self.multiselectBlock(self, selectedArray);
    }
    
    if ([self.delegate respondsToSelector:@selector(actionSheet:selectArray:)]) {
        [self.delegate actionSheet:self selectArray:selectedArray];
    }
}

- (void)dismiss{
    [UIView animateWithDuration:self.animationDuration delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
        [self.shadeView setAlpha:0];
        [self.shadeView setUserInteractionEnabled:NO];
        
        CGRect frame = self.sheetView.frame;
        frame.origin.y = MKSCREEN_HEIGHT;
        self.sheetView.frame = frame;
        
    } completion:^(BOOL finished) {
        [self removeFromSuperview];
        self.bgWindow.hidden = YES;
    }];
}

#pragma mark - ***** setup UI ******
- (void)setupMainView{
    self.frame = MKSCREEN_BOUNDS;
    [self addSubview:self.shadeView];
    [self addSubview:self.sheetView];
    [self.sheetView addSubview:self.tableView];

    CGFloat sheetViewH = 0;

    //title
    if (self.selectType == MKActionSheetSelectType_multiselect && !self.title) {
        self.title = @"";
    }
    
    if (self.title) {
        [self.sheetView addSubview:self.titleView];
        [self.titleView addSubview:self.titleLabel];
    
        CGFloat titleLabWidth = MKSCREEN_WIDTH - self.titleMargin*2;
        if (self.selectType == MKActionSheetSelectType_multiselect) {
            titleLabWidth = titleLabWidth - 80 + self.titleMargin-4;
            [self.titleView addSubview:self.confirmButton];
        }
        CGSize titleSize = [self.titleLabel.text boundingRectWithSize:CGSizeMake(titleLabWidth, MAXFLOAT)
                                                              options:NSStringDrawingUsesLineFragmentOrigin
                                                           attributes:@{NSFontAttributeName: self.titleLabel.font}
                                                              context:nil].size;
        
        self.titleLabel.frame = CGRectMake(self.titleMargin, 10, titleLabWidth, titleSize.height);
        self.titleView.frame = CGRectMake(0, 0, MKSCREEN_WIDTH, titleSize.height+20);
        
        CALayer *separatorLayer = [CALayer layer];
        separatorLayer.frame = CGRectMake(0, self.titleView.frame.size.height, MKSCREEN_WIDTH, 0.5);
        separatorLayer.backgroundColor = MKCOLOR_RGBA(0, 0, 0, 0.2).CGColor;
        [self.titleView.layer addSublayer:separatorLayer];
        
        sheetViewH += self.titleView.frame.size.height;
        
        if (_confirmButton) {
            _confirmButton.frame = CGRectMake(titleLabWidth+self.titleMargin+4, 0, 80, sheetViewH);
            
            CALayer *leftLayer = [CALayer layer];
            leftLayer.frame = CGRectMake(0, sheetViewH/2-10, 1, 20);
            leftLayer.backgroundColor = MKCOLOR_RGBA(0, 0, 0, 0.2).CGColor;
            [_confirmButton.layer addSublayer:leftLayer];
        }
    }
    
    CGFloat maxCount = self.buttonTitles.count;
    if (self.maxShowButtonCount > 0) {
        maxCount = self.buttonTitles.count > self.maxShowButtonCount ? self.maxShowButtonCount : self.buttonTitles.count;
    }
    CGFloat tableViewH = maxCount * self.buttonHeight;
    
    self.tableView.frame = CGRectMake(0, sheetViewH, MKSCREEN_WIDTH, tableViewH);

    sheetViewH += tableViewH;
    
    
    
    
    //取消按钮
    if (self.isNeedCancelButton) {
        sheetViewH += self.buttonHeight + 6;
        
        UIView *cancelView = [[UIView alloc] initWithFrame:CGRectMake(0, self.tableView.frame.origin.y+self.tableView.frame.size.height, self.frame.size.width, self.buttonHeight + 6)];
        [cancelView addSubview:self.cancelButton];
        [self.sheetView addSubview:cancelView];
        
        UIView *sepView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, MKSCREEN_WIDTH, 6)];
        sepView.backgroundColor = MKCOLOR_RGBA(100, 100, 100, 0.1);
        [cancelView addSubview:sepView];
        
        CALayer *topBorderLayer = [CALayer layer];
        topBorderLayer.frame = CGRectMake(0, 0, sepView.frame.size.width, 0.5);
        topBorderLayer.backgroundColor = MKCOLOR_RGBA(0, 0, 0, 0.1).CGColor;
        [sepView.layer addSublayer:topBorderLayer];
        
        CALayer *botBorderLayer = [CALayer layer];
        botBorderLayer.frame = CGRectMake(0, sepView.frame.size.height - 0.5, sepView.frame.size.width, 0.5);
        botBorderLayer.backgroundColor = MKCOLOR_RGBA(0, 0, 0, 0.1).CGColor;
        [sepView.layer addSublayer:botBorderLayer];
        
    }
    
    self.sheetView.frame = CGRectMake(0, MKSCREEN_HEIGHT, MKSCREEN_WIDTH, sheetViewH);
    
    
    self.blurView = [[UIView alloc] initWithFrame:self.sheetView.bounds];
    [self.blurView setClipsToBounds:YES];
    self.blurView.backgroundColor = [UIColor clearColor];
    
    self.blurBar = [[UIToolbar alloc] initWithFrame:self.blurView.bounds];
    self.blurBar = [[UIToolbar alloc] initWithFrame:[self bounds]];
    [self.blurView.layer insertSublayer:[self.blurBar layer] atIndex:0];
    
    [self.sheetView addSubview:self.blurView];
    [self.sheetView sendSubviewToBack:self.blurView];
    [self setBlurAlpha:self.blurOpacity];

    [self.tableView reloadData];
}

- (void)setBlurAlpha:(CGFloat)alpha{
    unsigned long numComponents = CGColorGetNumberOfComponents([[self.blurView backgroundColor] CGColor]);
    if (numComponents == 4){
        const CGFloat *components = CGColorGetComponents([[self.blurView backgroundColor] CGColor]);
        CGFloat red = components[0];
        CGFloat green = components[1];
        CGFloat blue = components[2];
        [self.blurView setBackgroundColor:[UIColor colorWithRed:red green:green blue:blue alpha:alpha]];
    }else{
        [self.blurView setBackgroundColor:[UIColor colorWithRed:1 green:1 blue:1 alpha:alpha]];
    }
}


#pragma mark - ***** UITableView delegate ******
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    MKActionSheetCell *cell = [MKActionSheetCell cellWithTableView:tableView];
//    cell.separatorView.hidden = indexPath.row == self.buttonTitles.count - 1;

    [cell.btnCell setBackgroundImage:[self imageWithColor:MKCOLOR_RGBA(255, 255, 255, self.buttonOpacity)] forState:UIControlStateNormal];
    [cell.btnCell setBackgroundImage:[self imageWithColor:MKCOLOR_RGBA(255, 255, 255, 0)] forState:UIControlStateHighlighted];
    [cell.btnCell addTarget:self action:@selector(btnOnclicked:) forControlEvents:UIControlEventTouchUpInside];
    cell.btnCell.titleLabel.font = self.buttonTitleFont;
    [cell.btnCell setTitleColor:self.buttonTitleColor forState:UIControlStateNormal];
    
    
    if (self.paramIsObject && self.imageKey && self.imageKey.length > 0 && self.imageValueType) {
        self.buttonTitleAlignment = MKActionSheetButtonTitleAlignment_left;
        
        id obj = [self.objArray objectAtIndex:indexPath.row];
        id imageValue = [obj valueForKey:self.imageKey];
        if (self.imageValueType == MKActionSheetButtonImageValueType_name) {
            if ([imageValue isKindOfClass:[NSString class]]) {
                [cell.btnCell setImage:[UIImage imageNamed:imageValue] forState:UIControlStateNormal];
            }
        }else if (self.imageValueType == MKActionSheetButtonImageValueType_image){
            if ([imageValue isKindOfClass:[UIImage class]]) {
                [cell.btnCell setImage:imageValue forState:UIControlStateNormal];
            }
        }else if (self.imageValueType == MKActionSheetButtonImageValueType_url){
            //由于加载url图片需要导入 SDWebImage，而且有些人在项目中用的也不一定是SDWebImage, 或用不到此类型，
            //为了不增加 使用MKActionSheet 的成本，加载url 图片  用一个block 或 delegate 回调出去，根据大家自己的实际情况设置 图片，并设置自己的默认图片。
            if ([imageValue isKindOfClass:[NSString class]]) {
                if (self.buttonImageBlock) {
                    self.buttonImageBlock(self, cell.btnCell, imageValue);
                }else if (_delegate && [_delegate respondsToSelector:@selector(actionSheet:button:imageUrl:)]) {
                    [_delegate actionSheet:self button:cell.btnCell imageUrl:imageValue];
                }
            }
        }
        
        [cell.btnCell setTitleEdgeInsets:UIEdgeInsetsMake(0, 12, 0, 0)];
    }
    
    if (self.buttonTitleAlignment == MKActionSheetButtonTitleAlignment_left) {
        cell.btnCell.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
        [cell.btnCell setContentEdgeInsets:UIEdgeInsetsMake(0, self.titleMargin, 0, 0)];
    }else if (self.buttonTitleAlignment == MKActionSheetButtonTitleAlignment_right){
        cell.btnCell.contentHorizontalAlignment = UIControlContentHorizontalAlignmentRight;
        [cell.btnCell setContentEdgeInsets:UIEdgeInsetsMake(0, 0, 0, self.titleMargin)];
    }
    
    cell.btnCell.tag = indexPath.row;
    [cell.btnCell setTitle:self.buttonTitles[indexPath.row] forState:UIControlStateNormal];
    
    if (indexPath.row == self.destructiveButtonIndex) {
        [cell.btnCell setTitleColor:self.destructiveButtonTitleColor forState:UIControlStateNormal];
    }

    cell.btnSelect.hidden = YES;

    if (self.selectType == MKActionSheetSelectType_multiselect) {
        cell.btnSelect.hidden = NO;
        NSString *title = [self.buttonTitles objectAtIndex:indexPath.row];
        cell.btnSelect.selected = title.mk_isSelect;
    }else if (self.selectType == MKActionSheetSelectType_selected){
        cell.btnSelect.enabled = NO;
        if (self.selectedIndex == indexPath.row) {
            cell.btnSelect.hidden = NO;
        }
    }
    return cell;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return self.buttonTitles.count > 0 ? self.buttonTitles.count : 0;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    return self.buttonHeight;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    return 1;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section{
    return 0.1;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section{
    return 0.1;
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath{\
    if ([tableView respondsToSelector:@selector(setSeparatorInset:)]) {
        [tableView setSeparatorInset:UIEdgeInsetsZero];
    }
    if ([tableView respondsToSelector:@selector(setLayoutMargins:)]) {
        [tableView setLayoutMargins:UIEdgeInsetsZero];
    }
    if ([cell respondsToSelector:@selector(setLayoutMargins:)]) {
        [cell setLayoutMargins:UIEdgeInsetsZero];
    }
}


#pragma mark - ***** lazy ******
- (UIWindow *)bgWindow{
    if (!_bgWindow) {
        _bgWindow = [[UIWindow alloc] initWithFrame:MKSCREEN_BOUNDS];
        _bgWindow.windowLevel = UIWindowLevelStatusBar;
        _bgWindow.backgroundColor = [UIColor clearColor];
        _bgWindow.hidden = NO;
    }
    return _bgWindow;
}

- (UIView *)shadeView{
    if (!_shadeView) {
        _shadeView = [[UIView alloc] init];
        [_shadeView setFrame:MKSCREEN_BOUNDS];
        [_shadeView setBackgroundColor:MKCOLOR_RGBA(0, 0, 0, 1)];
        [_shadeView setUserInteractionEnabled:NO];
        [_shadeView setAlpha:0];
        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(dismiss)];
        [_shadeView addGestureRecognizer:tap];
    }
    return _shadeView;
}


- (UIView *)sheetView{
    if (!_sheetView) {
        _sheetView = [[UIView alloc] init];
        [_sheetView setBackgroundColor:[UIColor clearColor]];
    }
    return _sheetView;
}

- (UITableView *)tableView{
    if (!_tableView) {
        _tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
        _tableView.delegate = self;
        _tableView.dataSource = self;
        _tableView.rowHeight = self.buttonHeight;
        _tableView.bounces = NO;
        _tableView.backgroundColor = [UIColor clearColor];
        _tableView.tableFooterView = [UIView new];
    }
    return _tableView;
}

- (UIView *)titleView{
    if (!_titleView) {
        _titleView = [[UIView alloc] init];
        _titleView.backgroundColor = MKCOLOR_RGBA(255, 255, 255, self.buttonOpacity);
    }
    return _titleView;
}

- (UILabel *)titleLabel{
    if (!_titleLabel) {
        _titleLabel = [[UILabel alloc] init];
        _titleLabel.text = self.title;
        _titleLabel.numberOfLines = 0;
        _titleLabel.textColor = self.titleColor;
        _titleLabel.textAlignment = _titleAlignment;
        _titleLabel.font = self.titleFont;
    }
    return _titleLabel;
}

- (UIButton *)cancelButton{
    if (!_cancelButton) {
        _cancelButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [_cancelButton setBackgroundImage:[self imageWithColor:MKCOLOR_RGBA(255, 255, 255, self.buttonOpacity)] forState:UIControlStateNormal];
        [_cancelButton setBackgroundImage:[self imageWithColor:MKCOLOR_RGBA(255, 255, 255, 0)] forState:UIControlStateHighlighted];
        [_cancelButton setTitle:self.cancelTitle forState:UIControlStateNormal];
        [_cancelButton setTitleColor:self.buttonTitleColor forState:UIControlStateNormal];
        _cancelButton.titleLabel.font = self.buttonTitleFont;
        _cancelButton.tag = self.buttonTitles.count;
        [_cancelButton addTarget:self action:@selector(btnOnclicked:) forControlEvents:UIControlEventTouchUpInside];
        _cancelButton.frame = CGRectMake(0, 6, MKSCREEN_WIDTH, self.buttonHeight);
    }
    return _cancelButton;
}

- (UIButton *)confirmButton{
    if (!_confirmButton) {
        _confirmButton = [UIButton buttonWithType:UIButtonTypeSystem];
        [_confirmButton setTitle:@"确定" forState:UIControlStateNormal];
        [_confirmButton setTitleColor:self.titleColor forState:UIControlStateNormal];
        _confirmButton.titleLabel.font = [UIFont systemFontOfSize:16];
        [_confirmButton addTarget:self action:@selector(confirmButtonOnclick:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _confirmButton;
}

- (UIImage *)imageWithColor:(UIColor *)color{
    CGRect rect = CGRectMake(0.0f, 0.0f, 1.0f, 1.0f);
    UIGraphicsBeginImageContext(rect.size);
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetFillColorWithColor(context, [color CGColor]);
    CGContextFillRect(context, rect);
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
}

@end
