//
//  DetailViewController.m
//  CineSearch
//
//  Created by Ritam Sarmah on 11/2/16.
//  Copyright © 2016 Ritam Sarmah. All rights reserved.
//

#import "AppDelegate.h"
#import "DetailViewController.h"
#import "MovieSearchManager.h"
#import "MovieID.h"
#import "CastCollectionViewCell.h"
#import <Realm/Realm.h>
#import <SDWebImage/UIImageView+WebCache.h>
#import <MXParallaxHeader/MXParallaxHeader.h>
#import <SafariServices/SafariServices.h>

@interface DetailViewController () {
    BOOL isRotationAllowed;
}

@property (nonatomic, strong) RLMResults *array;
@property (nonatomic, strong) RLMNotificationToken *notification;

@end

@implementation DetailViewController {}

- (void)configureView {
    isRotationAllowed = NO;
    
    // Configure buttons
    self.trailerButton.layer.cornerRadius = 5;
    self.trailerButton.layer.masksToBounds = YES;
    self.ratingView.layer.cornerRadius = 5;
    self.ratingView.layer.masksToBounds = YES;
    
    self.automaticallyAdjustsScrollViewInsets = NO;
    
    // Set actionBackgroundView shadow
    self.actionBackgroundView.layer.masksToBounds = NO;
    self.actionBackgroundView.layer.shadowColor = UIColor.blackColor.CGColor;
    self.actionBackgroundView.layer.shadowOffset = CGSizeMake(0, -3);
    self.actionBackgroundView.layer.shadowRadius = 3;
    self.actionBackgroundView.layer.shadowOpacity = 0.3f;
    
    // Update the user interface for the detail item.
    self.movieTitleLabel.text = self.movie.title;
    self.detailLabel.text = [NSString stringWithFormat:@"%@ ‧ %@ ‧ %@", self.movie.certification, self.movie.runtime, self.movie.releaseDate ?: @"TBA"];
    self.ratingLabel.text = [NSString stringWithFormat:@"%0.1f", [self.movie.rating doubleValue]];
    self.overviewLabel.text = self.movie.overview;
    if ([self.overviewLabel.text isEqualToString:@""]) {
        self.overviewLabel.text = @"No summary available.";
    }
    
    // Format and display genres label text
    self.genreLabel.text = [self.movie.genres componentsJoinedByString:@" | "];
    
    // Set up parallax header
    self.scrollView.parallaxHeader.view = self.headerView;
    
    // Download poster image from URL
    [self.posterLoadingIndicator startAnimating];
    NSURL *posterURL = [[NSURL alloc] initWithString:self.movie.posterURL];
    self.posterImageView.layer.shadowRadius = 5;
    self.posterImageView.layer.shadowColor = UIColor.blackColor.CGColor;
    self.posterImageView.layer.shadowOffset = CGSizeMake(0, 4);
    self.posterImageView.layer.shadowOpacity = 0.4;
    
    SDWebImageManager *manager = [SDWebImageManager sharedManager];
    [manager loadImageWithURL:posterURL options:0 progress:nil completed:^(UIImage * _Nullable image, NSData * _Nullable data, NSError * _Nullable error, SDImageCacheType cacheType, BOOL finished, NSURL * _Nullable imageURL) {
        [self.posterLoadingIndicator stopAnimating];
        if (image) {
            self.posterImageView.image = image;
            if (cacheType == SDImageCacheTypeNone) {
                [UIView transitionWithView:self.posterImageView
                                  duration:0.2
                                   options:UIViewAnimationOptionTransitionCrossDissolve
                                animations:^{
                                    self.posterImageView.image = image;
                                } completion:nil];
            } else {
                self.posterImageView.image = image;
            }
        } else {
            self.posterImageView.image = [UIImage imageNamed:@"BlankMoviePoster"];
        }
    }];
    
    // Download backdrop image from URL
    self.backdropImageView.image = [UIImage imageNamed:@"BlankBackdrop"];
    self.backdropImageView.contentMode = UIViewContentModeScaleAspectFill;
    
    self.scrollView.parallaxHeader.height = self.view.frame.size.height/3;
    self.scrollView.parallaxHeader.mode = MXParallaxHeaderModeFill;
    
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        switch ((int)[[UIScreen mainScreen] nativeBounds].size.height) {
            case 2436: // iPhone X Height
                self.scrollView.parallaxHeader.minimumHeight = 88;
                break;
            default:
                self.scrollView.parallaxHeader.minimumHeight = 64;
        }
    }
    
    NSURL *backdropURL = [[NSURL alloc] initWithString:self.movie.backdropURL];
    [manager loadImageWithURL:backdropURL options:0 progress:nil completed:^(UIImage * _Nullable image, NSData * _Nullable data, NSError * _Nullable error, SDImageCacheType cacheType, BOOL finished, NSURL * _Nullable imageURL) {
        [self.posterLoadingIndicator stopAnimating];
        if (image) {
            CIContext *context = [CIContext contextWithOptions:nil];
            CIImage *inputImage = [CIImage imageWithCGImage:image.CGImage];
            
            CIFilter *filter = [CIFilter filterWithName:@"CIGaussianBlur"];
            [filter setValue:inputImage forKey:kCIInputImageKey];
            [filter setValue:[NSNumber numberWithFloat:4.0f] forKey:@"inputRadius"];
            CIImage *result = [filter valueForKey:kCIOutputImageKey];
            
            CGImageRef cgImage = [context createCGImage:result fromRect:[inputImage extent]];
            [UIView transitionWithView:self.backdropImageView
                              duration:0.4
                               options:UIViewAnimationOptionTransitionCrossDissolve
                            animations:^{
                                self.backdropImageView.image = [UIImage imageWithCGImage:cgImage];
                            } completion:nil];
            [self setNeedsStatusBarAppearanceUpdate];
        }
    }];
    
    // Set up cast collection view
    self.castCollectionView.backgroundColor = [UIColor clearColor];
    
    [self.manager.database getCastForID:[self.movie getMovieID] completion:^(NSArray *cast) {
        int actorCount = (int)MIN(6, cast.count);
        self.castImageDict = [[NSMutableDictionary alloc] init];
        self.castArray = [cast subarrayWithRange:NSMakeRange(0, actorCount)];
        
        if (actorCount == 0) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.castCollectionView removeConstraint:self.castCollectionViewHeight];
                [self.castCollectionView layoutIfNeeded];
            });
        } else {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.castCollectionView reloadData];
                self.castCollectionView.hidden = NO;
                [UIView animateWithDuration:0.4 animations:^() {
                    self.castCollectionView.alpha = 1.0;
                }];
            });
            dispatch_group_t actorGroup = dispatch_group_create();
            
            for (int i = 0; i < actorCount; i++) {
                Actor *actor = self.castArray[i];
                NSURL *url = [[NSURL alloc] initWithString:actor.profileURL];
                dispatch_group_enter(actorGroup);
                [manager loadImageWithURL:url options:0 progress:nil completed:^(UIImage * _Nullable image, NSData * _Nullable data, NSError * _Nullable error, SDImageCacheType cacheType, BOOL finished, NSURL * _Nullable imageURL) {
                    if (image) {
                        NSString *key = [NSString stringWithFormat: @"%d", i];
                        [self.castImageDict setValue:image forKey:key];
                    }
                    if (cacheType == SDImageCacheTypeNone) {
                        self.castImagesFromWeb = YES;
                    }
                    dispatch_group_leave(actorGroup);
                }];
            }
            
            dispatch_group_notify(actorGroup, dispatch_get_main_queue(),^{
                [self.castCollectionView reloadData];
            });
        }
    }];
}

- (void)setActionBackgroundViewShadow:(BOOL)isVisible animated:(BOOL)animated {
    CABasicAnimation *animation  = [CABasicAnimation animation];
    animation.duration = animated ? 0.2f : 0.f;
    
    if (isVisible) {
        if (self.actionBackgroundView.layer.shadowOpacity == 0) {
            CGFloat start = 0.0, end = 0.3;
            animation.fromValue= @(start);
            animation.toValue= @(end);
            [self.actionBackgroundView.layer addAnimation:animation forKey:@"shadowOpacity"];
            self.actionBackgroundView.layer.shadowOpacity = end;
        }
    }
    else {
        if (self.actionBackgroundView.layer.shadowOpacity != 0) {
            CGFloat start = 0.3, end = 0.0;
            animation.fromValue= @(start);
            animation.toValue= @(end);
            [self.actionBackgroundView.layer addAnimation:animation forKey:@"shadowOpacity"];
            self.actionBackgroundView.layer.shadowOpacity = end;
        }
    }
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.manager = [MovieSearchManager sharedManager];
    self.array = [[MovieID allObjects] sortedResultsUsingKeyPath:MovieID.primaryKey ascending:YES];
    self.scrollView.delegate = self;
    self.castCollectionView.delegate = self;
    self.castCollectionView.dataSource = self;
    self.castCollectionView.hidden = YES;
    self.castCollectionView.alpha = 0;
    self.castImagesFromWeb = NO;
    
    [self configureView];
    
    __weak typeof(self) weakSelf = self;
    self.notification = [self.array addNotificationBlock:^(RLMResults *data, RLMCollectionChange *changes, NSError *error) {
        if (error) {
            NSLog(@"Failed to open Realm on background worker: %@", error);
            return;
        }
        
        weakSelf.isFavorite = NO;
        
        for (MovieID *realmMovieID in weakSelf.array) {
            if (realmMovieID.value == [weakSelf.movie.idNumber integerValue]) {
                weakSelf.isFavorite = YES;
            }
        }
        
        [weakSelf.favoriteButton setFavorite:weakSelf.isFavorite animated:NO];
    }];
}

- (void)viewWillAppear:(BOOL)animated {
    // Force portrait orientation
    AppDelegate *shared = (AppDelegate *)[UIApplication sharedApplication].delegate;
    shared.isRotationEnabled = NO;
    [[UIDevice currentDevice] setValue:@(UIInterfaceOrientationPortrait) forKey:@"orientation"];
    [UINavigationController attemptRotationToDeviceOrientation];
    
    [self.favoriteButton setFavorite:self.isFavorite animated:NO];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    if (@available(iOS 11.0, *)) {
        self.navigationItem.largeTitleDisplayMode = UINavigationItemLargeTitleDisplayModeNever;
    }
}

#pragma mark - UIScrollViewDelegate

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    if (self.scrollView == scrollView) {
        self.posterImageView.alpha = scrollView.parallaxHeader.progress;
        // Remove shadow if at bottom
        CGFloat scrollViewHeight = scrollView.frame.size.height;
        CGFloat scrollContentSizeHeight = scrollView.contentSize.height;
        CGFloat scrollOffset = scrollView.contentOffset.y;
        if (scrollOffset == 0) {
            [self setActionBackgroundViewShadow:YES animated:NO];
        } else if (scrollOffset + scrollViewHeight >= scrollContentSizeHeight && scrollContentSizeHeight != 0) {
            [self setActionBackgroundViewShadow:NO animated:YES];
        } else {
            [self setActionBackgroundViewShadow:YES animated:YES];
        }
    }
}

#pragma mark - Managing the detail item

- (void)setMovie:(Movie *)movie {
    if (_movie.idNumber != movie.idNumber) {
        _movie = movie;
    }
}

- (IBAction)back:(UIButton *)sender {
    UINavigationController *navCon = [self.splitViewController.viewControllers objectAtIndex:0];
    [navCon popViewControllerAnimated: YES];
}

- (IBAction)favoritePressed:(FavoriteButton *)sender {
    RLMRealm *realm = RLMRealm.defaultRealm;
    if ([sender toggleWithAnimation:YES]) {
        // Add to favorites list
        [realm transactionWithBlock:^{
            [MovieID createInRealm:realm withValue:@{MovieID.primaryKey: @([self.movie.idNumber integerValue])}];
        }];
    } else {
        // Remove from favorites list
        MovieID *movieToDelete = [MovieID objectForPrimaryKey:@([self.movie.idNumber integerValue])];
        [realm transactionWithBlock:^{
            [realm deleteObject:movieToDelete];
        }];
    }
}

- (IBAction)openTrailer:(UIButton *)sender {
    [self.manager.database getTrailerForID:[self.movie getMovieID] completion:^(NSString *trailer) {
        if (trailer != nil) {
            NSURL *webTrailer = [NSURL URLWithString:[NSString stringWithFormat:@"https://www.youtube.com/embed/%@?rel=0", trailer]];
            
            dispatch_async(dispatch_get_main_queue(), ^{
                AppDelegate *shared = (AppDelegate *)[UIApplication sharedApplication].delegate;
                shared.isRotationEnabled = YES;
                SFSafariViewController *svc = [[SFSafariViewController alloc] initWithURL:webTrailer];
                svc.preferredBarTintColor = [UIColor colorWithRed:0.09 green:0.10 blue:0.12 alpha:1.0];
                [self presentViewController:svc animated:YES completion:nil];
            });
        } else {
            UIAlertController *alert = [UIAlertController
                                        alertControllerWithTitle:@"Trailer not found"
                                        message:@"Search YouTube for movie trailer?"
                                        preferredStyle:UIAlertControllerStyleAlert];
            
            UIAlertAction* yesButton = [UIAlertAction
                                        actionWithTitle:@"OK"
                                        style:UIAlertActionStyleDefault
                                        
                                        handler:^(UIAlertAction * action) {
                                            NSString* query = [self.movie.title stringByReplacingOccurrencesOfString:@" "
                                                                                                          withString:@"+"];
                                            
                                            NSURL *appTrailer = [NSURL URLWithString:[NSString stringWithFormat:@"youtube:///results?q=%@+trailer", query]];
                                            NSURL *webTrailer = [NSURL URLWithString:[NSString stringWithFormat:@"https://www.youtube.com/results?q=%@+trailer", query]];
                                            
                                            if ([[UIApplication sharedApplication] canOpenURL:appTrailer]) {
                                                [[UIApplication sharedApplication] openURL:appTrailer];
                                            }
                                            else {
                                                [[UIApplication sharedApplication] openURL:webTrailer];
                                            }
                                        }];
            
            UIAlertAction* cancelButton = [UIAlertAction
                                           actionWithTitle:@"Cancel"
                                           style:UIAlertActionStyleCancel
                                           
                                           handler:^(UIAlertAction * action) {
                                               
                                           }];
            
            [alert addAction:cancelButton];
            [alert addAction:yesButton];
            
            [self presentViewController:alert animated:YES completion:nil];
        }
    }];
}

#pragma mark - UICollectionView

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.castArray.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"CastCell";
    
    CastCollectionViewCell *cell = (CastCollectionViewCell *)[collectionView dequeueReusableCellWithReuseIdentifier:CellIdentifier forIndexPath:indexPath];
    
    Actor *actor = self.castArray[indexPath.row];
    
    cell.nameLabel.text = actor.name;
    cell.roleLabel.text = actor.role;
    cell.profileImageView.image = [UIImage imageNamed:@"BlankActor"];
    cell.profileImageView.contentMode = UIViewContentModeScaleAspectFill;
    cell.profileImageView.layer.cornerRadius = 6;
    cell.profileImageView.layer.masksToBounds = YES;
    
    NSString *key = [NSString stringWithFormat:@"%lu", indexPath.row];
    if (self.castImageDict[key] != nil) {
        if (self.castImagesFromWeb) {
            [UIView transitionWithView:cell.profileImageView
                              duration:0.2
                               options:UIViewAnimationOptionTransitionCrossDissolve
                            animations:^{
                                cell.profileImageView.image = self.castImageDict[key];
                            } completion:nil];
        } else {
            cell.profileImageView.image = self.castImageDict[key];
        }
    }
    
    return cell;
}

@end
