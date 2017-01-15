//
//  DetailViewController.m
//  MovieSearch
//
//  Created by Ritam Sarmah on 11/2/16.
//  Copyright © 2016 Ritam Sarmah. All rights reserved.
//

#import "DetailViewController.h"
#import "MovieSingleton.h"
#import "MovieID.h"
#import <Realm/Realm.h>

@interface DetailViewController ()

@property (nonatomic, strong) RLMResults *array;
@property (nonatomic, strong) RLMNotificationToken *notification;

@end

@implementation DetailViewController

- (void)configureView {
    // Update the user interface for the detail item.
    self.movieTitleLabel.text = self.movie.title;
    self.releaseLabel.text = [NSString stringWithFormat:@"Release date: %@", self.movie.releaseDate ?: @"TBA"];
    self.ratingLabel.text = [NSString stringWithFormat:@"%0.1f", [self.movie.rating doubleValue]];
    self.overviewLabel.text = self.movie.overview;
    
    // Format and display genres label text
    self.genreLabel.text = [self.movie.genres componentsJoinedByString:@" | "];
    
    // Download poster image from URL
    [self.posterLoadingIndicator startAnimating];
    NSURL *posterURL = [[NSURL alloc] initWithString:self.movie.posterURL];
    dispatch_async(dispatch_get_global_queue(0,0), ^{
        NSData *data = [[NSData alloc] initWithContentsOfURL:posterURL];
        dispatch_async(dispatch_get_main_queue(), ^{
            if (data != nil) {
                UIImage *posterImage = [UIImage imageWithData:data];
                [UIView transitionWithView:self.posterImageView
                                  duration:0.4f
                                   options:UIViewAnimationOptionTransitionCrossDissolve
                                animations:^{
                                    self.posterImageView.image = posterImage;
                                } completion:nil];
            } else {
                self.posterImageView.image = [UIImage imageNamed:@"BlankMoviePoster"];
            }
            [self.posterLoadingIndicator stopAnimating];
        });
    });
    
    // Download backdrop image from URL
    self.backdropImageView.image = [UIImage imageNamed:@"BlankBackdrop"];
    NSURL *backdropURL = [[NSURL alloc] initWithString:self.movie.backdropURL];
    dispatch_async(dispatch_get_global_queue(0,0), ^{
        NSData *data = [[NSData alloc] initWithContentsOfURL:backdropURL];
        
        if (data != nil) {
            UIImage *backdropImage = [UIImage imageWithData:data];
            CIContext *context = [CIContext contextWithOptions:nil];
            CIImage *inputImage = [CIImage imageWithCGImage:backdropImage.CGImage];
            
            CIFilter *filter = [CIFilter filterWithName:@"CIGaussianBlur"];
            [filter setValue:inputImage forKey:kCIInputImageKey];
            [filter setValue:[NSNumber numberWithFloat:5.0f] forKey:@"inputRadius"];
            CIImage *result = [filter valueForKey:kCIOutputImageKey];
            
            CGImageRef cgImage = [context createCGImage:result fromRect:[inputImage extent]];
            
            CALayer *maskLayer = [CALayer layer];
            maskLayer.frame = self.backdropImageView.bounds;
            maskLayer.shadowPath = CGPathCreateWithRect(CGRectInset(self.backdropImageView.bounds, 5, 5), nil);
            maskLayer.shadowOpacity = 1;
            maskLayer.shadowOffset = CGSizeZero;
            maskLayer.shadowColor = [UIColor whiteColor].CGColor;
            
            self.backdropImageView.layer.mask = maskLayer;
            
            dispatch_async(dispatch_get_main_queue(), ^{
                [UIView transitionWithView:self.backdropImageView
                                  duration:0.4f
                                   options:UIViewAnimationOptionTransitionCrossDissolve
                                animations:^{
                                    self.backdropImageView.image = [UIImage imageWithCGImage:cgImage];
                                } completion:nil];
                [self.posterLoadingIndicator stopAnimating];
                [self setNeedsStatusBarAppearanceUpdate];
            });
        }
    });
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.manager = [MovieSingleton sharedManager];
    self.array = [[MovieID allObjects] sortedResultsUsingKeyPath:@"movieID" ascending:YES];
    
    self.trailerButton.layer.cornerRadius = 5;
    self.trailerButton.layer.masksToBounds = YES;
    self.favoriteButton.layer.cornerRadius = 5;
    self.favoriteButton.layer.masksToBounds = YES;
    
    self.ratingView.layer.cornerRadius = 5;
    self.ratingView.layer.masksToBounds = YES;
    self.automaticallyAdjustsScrollViewInsets = NO;
    
    self.navigationController.navigationBar.hidden = YES;
    
    [self configureView];
    
    __weak typeof(self) weakSelf = self;
    self.notification = [self.array addNotificationBlock:^(RLMResults *data, RLMCollectionChange *changes, NSError *error) {
        if (error) {
            NSLog(@"Failed to open Realm on background worker: %@", error);
            return;
        }
        
        weakSelf.isFavorite = NO;
        
        for (MovieID *realmMovieID in weakSelf.array) {
            if (realmMovieID.movieID == [weakSelf.movie.idNumber integerValue]) {
                weakSelf.isFavorite = YES;
            }
        }
        
        if (!weakSelf.isFavorite) {
            [weakSelf.favoriteButton setTintColor:[UIColor whiteColor]];
            [weakSelf.favoriteButton setImage:[UIImage imageNamed:@"HeartHollow"] forState:UIControlStateNormal];
        } else {
            [weakSelf.favoriteButton setTintColor:[UIColor colorWithRed:1.00 green:0.32 blue:0.30 alpha:1.0]];
            [weakSelf.favoriteButton setImage:[UIImage imageNamed:@"HeartFilled"] forState:UIControlStateNormal];
        }
    }];
}

#pragma mark - Managing the detail item

- (void)setMovie:(Movie *)newMovie {
    if (_movie != newMovie) {
        _movie = newMovie;
    }
}

- (IBAction)back:(UIButton *)sender {
    UINavigationController *navCon = [self.splitViewController.viewControllers objectAtIndex:0];
    [navCon popViewControllerAnimated: YES];
}

- (IBAction)favoritePressed:(UIButton *)sender {
    RLMRealm *realm = RLMRealm.defaultRealm;
    if (self.favoriteButton.tintColor != [UIColor whiteColor]) {
        // Animate to empty heart
        [UIView animateWithDuration:0.3/2.5 animations:^{
            sender.transform = CGAffineTransformScale(CGAffineTransformIdentity, 1.1, 1.1);
            [self.favoriteButton setTintColor:[UIColor whiteColor]];
            [self.favoriteButton setImage:[UIImage imageNamed:@"HeartHollow"] forState:UIControlStateNormal];
        } completion:^(BOOL finished) {
            [UIView animateWithDuration:0.3/2.5 animations:^{
                sender.transform = CGAffineTransformScale(CGAffineTransformIdentity, 0.9, 0.9);
            } completion:^(BOOL finished) {
                [UIView animateWithDuration:0.3/2.5 animations:^{
                    sender.transform = CGAffineTransformIdentity;
                }];
            }];
        }];
        
        // Remove from favorites list
        MovieID *movieToDelete = [MovieID objectForPrimaryKey:@([self.movie.idNumber integerValue])];
        
        [realm beginWriteTransaction];
        [realm deleteObject:movieToDelete];
        [realm commitWriteTransaction];
        
    } else {
        // Animate to red filled heart
        [UIView animateWithDuration:0.3/2.5 animations:^{
            sender.transform = CGAffineTransformScale(CGAffineTransformIdentity, 1.1, 1.1);
            [self.favoriteButton setTintColor:[UIColor colorWithRed:1.00 green:0.32 blue:0.30 alpha:1.0]];
            [self.favoriteButton setImage:[UIImage imageNamed:@"HeartFilled"] forState:UIControlStateNormal];
        } completion:^(BOOL finished) {
            [UIView animateWithDuration:0.3/2.5 animations:^{
                sender.transform = CGAffineTransformScale(CGAffineTransformIdentity, 0.9, 0.9);
            } completion:^(BOOL finished) {
                [UIView animateWithDuration:0.3/2.5 animations:^{
                    sender.transform = CGAffineTransformIdentity;
                }];
            }];
        }];
        
        // Add to favorites list
        [realm beginWriteTransaction];
        [MovieID createInRealm:realm withValue:@{@"movieID": @([self.movie.idNumber integerValue])}];
        [realm commitWriteTransaction];
    }
}

- (IBAction)openTrailer:(UIButton *)sender {
    [self.manager.database getTrailerForID:self.movie.idNumber completion:^(NSString *trailer) {
        if (trailer != nil) {
            NSURL *appTrailer = [NSURL URLWithString:[NSString stringWithFormat:@"youtube:///watch?v=%@", trailer]];
            NSURL *webTrailer = [NSURL URLWithString:[NSString stringWithFormat:@"https://www.youtube.com/watch?v=%@", trailer]];
            
            if ([[UIApplication sharedApplication] canOpenURL:appTrailer]) {
                [[UIApplication sharedApplication] openURL:appTrailer];
            }
            else {
                [[UIApplication sharedApplication] openURL:webTrailer];
            }
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
            
            [self presentViewController:alert animated:true completion:nil];
        }
    }];
}

@end
