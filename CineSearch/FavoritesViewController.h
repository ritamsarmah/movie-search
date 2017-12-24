//
//  FavoritesViewController.h
//  CineSearch
//
//  Created by Ritam Sarmah on 12/21/16.
//  Copyright © 2016 Ritam Sarmah. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MovieSingleton.h"

@class DetailViewController;

@interface FavoritesViewController : UITableViewController <UIGestureRecognizerDelegate>

@property (strong, nonatomic) DetailViewController *detailViewController;
@property NSMutableDictionary *moviesForID;
@property MovieSingleton *manager;
@property BOOL enteredSegue;

@end