//
//  TVHTagListViewController.m
//  TVHeadend iPhone Client
//
//  Created by zipleen on 2/9/13.
//  Copyright (c) 2013 zipleen. All rights reserved.
//

#import "TVHTagStoreViewController.h"
#import "TVHChannelStoreViewController.h"
#import "WBErrorNoticeView.h"
#import "CKRefreshControl.h"
#import "UIImageView+AFNetworking.h"

@interface TVHTagStoreViewController ()
@property (strong, nonatomic) TVHTagStore *tagList;
@end

@implementation TVHTagStoreViewController

@synthesize tagList = _tagList;

- (TVHTagStore*) tagList {
    if ( _tagList == nil) {
        _tagList = [TVHTagStore sharedInstance];
    }
    return _tagList;
}

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self.tagList setDelegate:self];
    [self.tagList fetchTagList];
    
    //pull to refresh
    self.refreshControl = [[UIRefreshControl alloc] init];
    [self.refreshControl addTarget:self action:@selector(pullToRefreshViewShouldRefresh) forControlEvents:UIControlEventValueChanged];
    //self.refreshControl.attributedTitle = [[NSAttributedString alloc] initWithString:@"Pull to refresh"];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)pullToRefreshViewShouldRefresh
{
    [self.tagList resetTagStore];
    [self.tableView reloadData];
    [self.tagList fetchTagList];
}

#pragma mark - Table view data source


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.tagList count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"TagListTableItems";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier ];
   
    if(cell==nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }
    
    // Configure the cell...
    TVHTag *tag = [self.tagList objectAtIndex:indexPath.row];
    
    UILabel *tagNameLabel = (UILabel *)[cell viewWithTag:100];
	UILabel *tagNumberLabel = (UILabel *)[cell viewWithTag:101];
	UIImageView *channelImage = (UIImageView *)[cell viewWithTag:102];
    tagNameLabel.text = tag.name;
    tagNumberLabel.text = nil;
    [channelImage setImageWithURL:[NSURL URLWithString:tag.imageUrl] placeholderImage:[UIImage imageNamed:@"tag.png"]];
    
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    
    return cell;
}

#pragma mark - Table view delegate

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if([segue.identifier isEqualToString:@"Show Channel List"]) {
        
        NSIndexPath *path = [self.tableView indexPathForSelectedRow];
        TVHTag *tag = [self.tagList objectAtIndex:path.row];
        
        TVHChannelStoreViewController *ChannelList = segue.destinationViewController;
        [ChannelList setFilterTagId: tag.tagid];
        
        [segue.destinationViewController setTitle:tag.name];
    }
}

- (void)didLoadTags {
    [self.tableView reloadData];
    [self.refreshControl endRefreshing];
}

- (void)didErrorLoadingTagStore:(NSError*) error {
    WBErrorNoticeView *notice = [WBErrorNoticeView errorNoticeInView:self.view title:NSLocalizedString(@"Network Error", nil) message:error.localizedDescription];
    [notice setSticky:true];
    [notice show];
    
    [self.refreshControl endRefreshing];
}


@end
