//
//  MovieTableViewCell.h
//  CineSearch
//
//  Created by Ritam Sarmah on 11/9/16.
//  Copyright © 2016 Ritam Sarmah. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MovieID.h"
#import "FavoriteButton.h"

@interface MovieTableViewCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UIImageView *posterImageView;
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UILabel *releaseLabel;
@property (weak, nonatomic) IBOutlet UILabel *ratingLabel;
@property (weak, nonatomic) IBOutlet UIView *ratingView;
@property (weak, nonatomic) IBOutlet FavoriteButton *favoriteButton;

@property (nonatomic) MovieID *movieID;

- (IBAction)favoritePressed:(FavoriteButton *)sender;
- (BOOL)isMovieInFavorites:(NSInteger)movieID;

@end
