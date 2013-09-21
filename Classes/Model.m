//
//    Model.m
//    LatestChatty2
//
//  Created by Alex Wayne on 3/16/09.
//  Copyright 2009. All rights reserved.
//

#import "Model.h"
#import "ModelLoadingDelegate.h"

static NSString *kDateFormat = @"MMM d, yyyy hh:mm a";          // Feb 25, 2010 12:22 AM
static NSString *kParseDateFormat = @"yyyy/M/d kk:mm:ss Z";     // 2010/03/06 16:13:00 -0800
static NSString *kParseDateFormat2 = @"MMM d, yyyy hh:mma zzz"; // Mar 15, 2011 6:28pm PDT
static NSString *kParseDateFormat3 = @"MMM d, yyyy, hh:mm a";   // Mar 15, 2011, 6:28 pm

@implementation Model

@synthesize modelId;

#pragma mark Encoding

- (id)initWithCoder:(NSCoder *)coder {
    if (!(self = [super init])) return nil;
    modelId = [coder decodeIntForKey:@"modelId"];
    return self;
}

- (void)encodeWithCoder:(NSCoder *)encoder {
    [encoder encodeInt:modelId forKey:@"modelId"];
}

#pragma mark Class Helpers

+ (NSString *)formatDate:(NSDate *)date; {
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    //Force the 12hr locale so dates appear on the 24hr guys
    [formatter setLocale:[[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"]];
    [formatter setDateFormat:kDateFormat];
    return [formatter stringFromDate:date];
}

+ (NSDate *)decodeDate:(NSString *)string {
    if ((id)string == [NSNull null]) return nil;
  
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    //Force the 12hr locale so dates appear on the 24hr guys    
    [formatter setLocale:[[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"]];
    [formatter setDateFormat:kParseDateFormat];

    NSDate *date = [formatter dateFromString:string];
    if (!date) {
        [formatter setDateFormat:kParseDateFormat2];
        date = [formatter dateFromString:string];
    }
    if (!date) {
        [formatter setDateFormat:kParseDateFormat3];
        date = [formatter dateFromString:string];
    }

    return date;
}

+ (NSString *)host {
    return [[NSUserDefaults standardUserDefaults] objectForKey:@"server"];
}

+ (NSString *)urlStringWithPath:(NSString *)path {
    NSString *urlString = [NSString stringWithFormat:@"http://%@%@", [self host], path];
    if ([urlString isMatchedByRegex:@"\\?"]) {
        urlString = [urlString stringByReplacingOccurrencesOfRegex:@"\\?" withString:@".json?"];
    } else {
        urlString = [urlString stringByAppendingString:@".json"];
    }
    return urlString;
}
+ (NSString *)urlStringWithPathNoRewrite:(NSString *)path {
    NSString *urlString = [NSString stringWithFormat:@"http://%@%@", [self host], path];
    return urlString;
}

#pragma mark Class Methods

+ (ModelLoader *)loadAllFromUrl:(NSString *)urlString delegate:(id<ModelLoadingDelegate>)delegate {
    ModelLoader *loader =    [[ModelLoader alloc] initWithAllObjectsAtURL:[self urlStringWithPath:urlString]
                                                             dataDelegate:(id)self
                                                            modelDelegate:delegate];
    return loader;
}

//Patch-E: 10/13/2012, stonedonkey API URL rewriting is broken when paging is needed for search
//mimic'd loadAllFromUrl: class function with a function that bypasses the construction of the rewritten URL
+ (ModelLoader *)loadAllFromUrlNoRewrite:(NSString *)urlString delegate:(id<ModelLoadingDelegate>)delegate {
    ModelLoader *loader =    [[ModelLoader alloc] initWithAllObjectsAtURL:[self urlStringWithPathNoRewrite:urlString]
                                                             dataDelegate:(id)self
                                                            modelDelegate:delegate];
    return loader;
}

+ (ModelLoader *)loadObjectFromUrl:(NSString *)urlString delegate:(id<ModelLoadingDelegate>)delegate {
    ModelLoader *loader =    [[ModelLoader alloc] initWithObjectAtURL:[self urlStringWithPath:urlString]
                                                         dataDelegate:(id)self
                                                        modelDelegate:delegate];
    return loader;
}


#pragma mark Completion Callbacks

+ (id)otherDataForResponseData:(id)responseData {
    return nil;
}

+ (id)didFinishLoadingPluralData:(id)dataObject {
    NSArray *modelDataArray = dataObject;
    NSMutableArray *models = [NSMutableArray arrayWithCapacity:[modelDataArray count]];
    for (NSDictionary *dictionary in modelDataArray) {
        if ([dictionary isKindOfClass:[NSDictionary class]]) {
            Model *model = [[self alloc] initWithDictionary:dictionary];
            [models addObject:model];
        }
    }
    return models;
}

+ (id)didFinishLoadingData:(id)dataObject {
    return [[self alloc] initWithDictionary:dataObject];
}

#pragma mark Model Initializer

- (id)initWithDictionary:(NSDictionary *)dictionary {
    if (!(self = [super init])) return nil;
    modelId = [[dictionary objectForKey:@"id"] intValue];
    return self;
}

@end
