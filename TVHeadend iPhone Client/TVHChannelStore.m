//
//  ModelChannelList.m
//  TVHeadend iPhone Client
//
//  Created by zipleen on 2/3/13.
//  Copyright (c) 2013 zipleen. All rights reserved.
//

#import "TVHChannelStore.h"
#import "TVHEpg.h"
#import "TVHSettings.h"

@interface TVHChannelStore ()
@property (nonatomic, strong) NSArray *channels;
@property (nonatomic, weak) id <TVHChannelStoreDelegate> delegate;
@property (nonatomic, weak) TVHEpgStore *epgList;
@end

@implementation TVHChannelStore 
@synthesize channels = _channels;
@synthesize delegate = _delegate;
@synthesize filterTag = _filterTag;
@synthesize epgList = _epgList;

+ (id)sharedInstance {
    static TVHChannelStore *__sharedInstance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        __sharedInstance = [[TVHChannelStore alloc] init];
    });
    
    return __sharedInstance;
}

- (TVHEpgStore*) epgList {
    if(!_epgList){
        _epgList = [TVHEpgStore sharedInstance];
    }
    return _epgList;
}



- (void)fetchedData:(NSData *)responseData {
    //parse out the json data
    NSError* error;
    NSDictionary* json = [NSJSONSerialization JSONObjectWithData:responseData //1
                                                         options:kNilOptions
                                                           error:&error];
    
    if( error ) {
        NSLog(@"[JSON Error]: %@", error.description);
        if ([self.delegate respondsToSelector:@selector(didErrorLoadingChannelStore:)]) {
            [self.delegate didErrorLoadingChannelStore:error];
        }
        return ;
    }
    
    NSArray *entries = [json objectForKey:@"entries"];
    NSMutableArray *channels = [[NSMutableArray alloc] init];
    
    NSEnumerator *e = [entries objectEnumerator];
    id channel;
    //for (NSEnumerator *channel in entries) {
    while (channel = [e nextObject]) {
        //NSLog(@"json : %@", channel);
        TVHChannel *c = [[TVHChannel alloc] init];
        
        NSInteger ch_id = [[channel objectForKey:@"chid"] intValue];
        NSString *ch_icon = [channel objectForKey:@"ch_icon"];
        NSString *name = [channel objectForKey:@"name"];
        NSString *number = [channel objectForKey:@"number"];
        NSString *tags = [channel objectForKey:@"tags"];
        
        [c setName:name];
        [c setNumber:number];
        [c setImageUrl:ch_icon];
        [c setChid:ch_id];
        [c setTags:[tags componentsSeparatedByString:@","]];
                
        [channels addObject:c];
    }
    self.channels =  [[channels copy] sortedArrayUsingSelector:@selector(compareByName:)];
    //self.channels = [channels copy];
    NSLog(@"[Loaded Channels]: %d", [self.channels count]);
}


- (void)fetchChannelList {
    if( [self.channels count] == 0 ) {
        TVHSettings *settings = [TVHSettings sharedInstance];
        AFHTTPClient *httpClient = [[AFHTTPClient alloc] initWithBaseURL:[settings baseURL] ];
        
        NSDictionary *params = [NSDictionary dictionaryWithObjectsAndKeys:@"list", @"op", nil];
       
        [httpClient postPath:@"/channels" parameters:params success:^(AFHTTPRequestOperation *operation, id responseObject) {
            [self fetchedData:responseObject];
            [self.delegate didLoadChannels];
            
            [self.epgList setDelegate:self];
            [self.epgList downloadEpgList];
            
           // NSString *responseStr = [[NSString alloc] initWithData:responseObject encoding:NSUTF8StringEncoding];
           // NSLog(@"Request Successful, response '%@'", responseStr);
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            if ([self.delegate respondsToSelector:@selector(didErrorLoadingChannelStore:)]) {
                [self.delegate didErrorLoadingChannelStore:error];
            }
            NSLog(@"[ChannelList HTTPClient Error]: %@", error.localizedDescription);
        }];
    } 
}

- (TVHChannel*) getChannelById:(NSInteger)channelId {
    NSEnumerator *e = [self.channels objectEnumerator];
    TVHChannel *channel;
    while (channel = [e nextObject]) {
        if ( [channel chid] == channelId ) {
            return channel;
        }
    }
    return nil;
}

#pragma mark EPG delegatee stuff

- (void) didLoadEpg:(TVHEpgStore*)epgList {
    // for each epg
    NSArray *list = [epgList getEpgList];
    NSEnumerator *e = [list objectEnumerator];
    TVHEpg *epg;
    while (epg = [e nextObject]) {
        TVHChannel *channel = [self getChannelById:epg.channelId];
        [channel addEpg:epg];
    }
    [self.delegate didLoadChannels];
}

-(void) didErrorLoadingEpgStore:(NSError*)error {
    if ([self.delegate respondsToSelector:@selector(didErrorLoadingChannelStore:)]) {
        [self.delegate didErrorLoadingChannelStore:error];
    }
}

#pragma mark Controller delegate stuff

- (NSArray*) getFilteredChannelList {
    NSMutableArray *filteredChannels = [[NSMutableArray alloc] init];
    
    NSEnumerator *e = [self.channels objectEnumerator];
    TVHChannel *channel;
    while (channel = [e nextObject]) {
        if( [channel hasTag:self.filterTag] ) {
            [filteredChannels addObject:channel];
        }
    }
    return [filteredChannels copy];
}

- (TVHChannel*) objectAtIndex:(int) row {
    if(self.filterTag == 0) {
        return [self.channels objectAtIndex:row];
    } else {
        NSArray *filteredTag = [self getFilteredChannelList];
        return [filteredTag objectAtIndex:row];
    }
}

- (int) count {
    if(self.filterTag == 0) {
        return [self.channels count];
    } else {
        NSArray *filteredTag = [self getFilteredChannelList];
        return [filteredTag count];
    }
}

- (void)setDelegate:(id <TVHChannelStoreDelegate>)delegate {
    if (_delegate != delegate) {
        _delegate = delegate;
    }
}

@end
