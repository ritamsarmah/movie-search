//
//  DetailViewController.h
//  MovieSearch
//
//  Created by Ritam Sarmah on 11/2/16.
//  Copyright © 2016 Ritam Sarmah. All rights reserved.
//

#import <UIKit/UIKit.h>

@class MovieSingleton;
@class Movie;

@interface DetailViewController : UIViewController

@property (strong, nonatomic) Movie *movie;
@property (weak, nonatomic) NSURL *trailerURL;
@property (nonatomic) BOOL isFavorite;
@property MovieSingleton *manager;

@property (weak, nonatomic) IBOutlet UIImageView *posterImageView;
@property (weak, nonatomic) IBOutlet UILabel *movieTitleLabel;
@property (weak, nonatomic) IBOutlet UILabel *releaseLabel;
@property (weak, nonatomic) IBOutlet UILabel *genreLabel;
@property (weak, nonatomic) IBOutlet UIImageView *backdropImageView;
@property (weak, nonatomic) IBOutlet UILabel *ratingLabel;
@property (weak, nonatomic) IBOutlet UIView *ratingView;
@property (weak, nonatomic) IBOutlet UILabel *overviewLabel;
@property (weak, nonatomic) IBOutlet UIButton *trailerButton;
@property (weak, nonatomic) IBOutlet UIButton *favoriteButton;
@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *posterLoadingIndicator;

- (IBAction)back:(UIButton *)sender;
- (IBAction)favoritePressed:(UIButton *)sender;
- (IBAction)openTrailer:(UIButton *)sender;

@end

