//
//  ParkAssist.m
//  ParkAssist
//
//  Created by Gabriel Morales on 2/8/16.
//  Copyright © 2016 Phunware. All rights reserved.
//

#import "ParkAssist.h"
#import "AFNetworking.h"
//#import "NSString+MD5.h"
#import <CommonCrypto/CommonCrypto.h>

#define kParkingAssistBaseURL @"https://insights.parkassist.com/find_your_car/"
static NSString *deviceID;
static NSString *secretKey;
static NSString *siteSlug;

@interface ParkAssist()
@property (nonatomic, strong)AFHTTPRequestOperationManager *manager;
@end

@implementation ParkAssist

+ (instancetype)initWithSecret:(NSString *)secret andSiteSlug:(NSString *)slug {
    if (secret.length == 0 || [secret isEqualToString:@" "]) {
        @throw ([NSException exceptionWithName:@"Invalid Secret Key" reason:@"Please enter a valid key" userInfo:nil]);
    } else if (slug.length == 0 || [slug isEqualToString:@" "]) {
        @throw ([NSException exceptionWithName:@"Invalid Slug" reason:@"Please enter valid slug" userInfo:nil]);
    }else {
        secretKey = secret;
        siteSlug = slug;
    }
    
    return [[self alloc] init];
}

- (instancetype)init {
    if (self = [super init]) {
        _manager = [[AFHTTPRequestOperationManager alloc] initWithBaseURL:[NSURL URLWithString:kParkingAssistBaseURL]];
        _manager.requestSerializer = [AFJSONRequestSerializer serializer];
        
        AFJSONResponseSerializer *responseSerializer = [AFJSONResponseSerializer serializer];
        responseSerializer.removesKeysWithNullValues = YES;
        _manager.responseSerializer = responseSerializer;
        _manager.responseSerializer.acceptableContentTypes = [NSSet setWithArray:@[@"application/json"]];
    }
    return self;
}

+ (ParkAssist *)sharedInstance {
    static dispatch_once_t once;
    static ParkAssist *instance;
    dispatch_once(&once, ^{
        if (!instance) {
            instance = [[ParkAssist alloc] init];
        }
    });
    return instance;
}

- (dispatch_queue_t)sharedParserQueue {
    static dispatch_queue_t sharedQueue = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedQueue = dispatch_queue_create("PA-parser", NULL);
    });
    return sharedQueue;
}

- (void)runBlockInParserQueue:(void (^)())block {
    dispatch_async([self sharedParserQueue], ^{
        if (block != nil) {
            block();
        }
    });
}

-(NSString *)deviceId {
    if ([deviceID length] <=0) {
        deviceID = [[NSUUID UUID] UUIDString];
    }
    return deviceID;
}

- (NSString *) timeStamp {
    return [NSString stringWithFormat:@"%.0lf",[[NSDate date] timeIntervalSince1970] * 1000];
}

- (NSString *)constuctWithLat:(double)latitude andLon:(double)longitude {
    NSString *timeStamp = [self timeStamp];
    NSString *deviceId = [self deviceId];
    NSString *constructString = [NSString stringWithFormat:@"%@device=%@,lat=%lf,lon=%lf,site=%@,ts=%@",secretKey,deviceId,latitude,longitude,siteSlug,timeStamp];
    NSString *signature = [self MD5String:constructString];
    NSString *construct = [NSString stringWithFormat:@"device=%@&lat=%lf&lon=%lf&signature=%@&site=%@&ts=%@",deviceId,latitude,longitude,signature,siteSlug,timeStamp];
    
    return construct;
}

- (NSString *)constructWithoutCoordinates {
    NSString *timeStamp = [self timeStamp];
    NSString *deviceID = [self deviceId];
    NSString *constructString = [NSString stringWithFormat:@"%@device=%@,site=%@,ts=%@", secretKey, deviceID, siteSlug, timeStamp];
    NSString *signature = [self MD5String:constructString];
    NSString *construct = [NSString stringWithFormat:@"device=%@&signature=%@&site=%@&ts=%@", deviceID, signature, siteSlug, timeStamp];
    
    return construct;
}

//26.0725
//-80.1528
#pragma mark - Park Assist Methods
/**
 *  Search for license plates with no lat or long
 *
 *  @param plate      A minimum of 3 alpha numeric characters
 *  @param completion If success, API will return an array of dictionaries.
 */
- (void)searchLicensePlate:(NSString *)plate withCompletion:(void (^)(BOOL success, NSArray *results, NSError *error))completion {
    [self searchLicensePlate:plate withLat:0 andLon:0 withCompletion:^(BOOL success, NSArray *results, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            completion(success, results, error);
        });
    }];
}


/**
 *  Search for license plates.
 *
 *  @param plate      A minimum of 3 alpha numberic characters
 *  @param latitude   Latitude needs to have 3 digits after the decimal point
 *  @param longitude  Longiture needs to have 3 digits after the decicmal point
 *  @param completion If success, api will return a maximum of 3 items.
 */
- (void)searchLicensePlate:(NSString *)plate withLat:(double)latitude
                    andLon:(double)longitude withCompletion:(void (^)(BOOL success, NSArray *results, NSError *error))completion {
    NSString *timeStamp = [self timeStamp];
    NSString *deviceId = [self deviceId];
    NSString *constructString = [NSString stringWithFormat:@"%@device=%@,lat=%lf,lon=%lf,plate=%@,site=%@,ts=%@",secretKey,deviceId,latitude,longitude,plate,siteSlug,timeStamp];
    NSString *signature = [self MD5String:constructString];
    NSString *construct = [NSString stringWithFormat:@"site=%@&device=%@&plate=%@&signature=%@&ts=%@&lat=%lf&lon=%lf",siteSlug,deviceId,plate,signature,timeStamp,latitude,longitude];
    
    [_manager GET:[NSString stringWithFormat:@"search.json?%@", construct] parameters:nil success:^(AFHTTPRequestOperation * _Nonnull operation, id  _Nonnull responseObject) {
        if (responseObject && operation.response.statusCode == 200) {
            [self runBlockInParserQueue:^{
                NSArray *response = (NSArray *)responseObject;
                NSMutableArray *parsedResponse = [NSMutableArray array];
                for (NSDictionary *dict in response) {
                    [parsedResponse addObject:dict];
                }
                dispatch_async(dispatch_get_main_queue(), ^{
                    completion(YES,[parsedResponse copy], nil);
                });
            }];
        }
    } failure:^(AFHTTPRequestOperation * _Nullable operation, NSError * _Nonnull error) {
        completion(NO, nil, error);
    }];
}

- (void)getAvailableParkingInfo:(void(^)(BOOL success, NSArray*results, NSError*error))completion {
    [self getAvailableParkingInfoWithLat:0 andLon:0 withCompletion:^(BOOL success, NSArray *results, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            completion(success, results, error);
        });
    }];
}

/**
 *  Get available parking spaces for zone.
 *
 *  @param latitude   Latitude needs to have 3 digits after the decimal point
 *  @param longitude  Longiture needs to have 3 digits after the decicmal point
 *  @param completion response is an array.
 */
- (void)getAvailableParkingInfoWithLat:(double)latitude
                                andLon:(double)longitude withCompletion:(void (^)(BOOL success, NSArray *results, NSError *error))completion {
    
    [_manager GET:[NSString stringWithFormat:@"zones.json?%@", [self constuctWithLat:latitude andLon:longitude]]
       parameters:nil success:^(AFHTTPRequestOperation * _Nonnull operation, id  _Nonnull responseObject) {
           
           [self runBlockInParserQueue:^{
               NSError *error = nil;
               NSArray *response = (NSArray *)responseObject;
               NSMutableArray *parsedResponse = [NSMutableArray array];
               
               for (NSDictionary *dict in response) {
                   [parsedResponse addObject:dict];
               }
               
               if (!error) {
                   dispatch_async(dispatch_get_main_queue(), ^{
                       completion(YES, [parsedResponse copy], nil);
                   });
               }
           }];
       }
          failure:^(AFHTTPRequestOperation * _Nullable operation, NSError * _Nonnull error) {
              completion(NO, nil, error);
          }];
}

/**
 *  Method us used to get vehicle images for license plate result.
 *
 *  @param uuid       API requires the parking space UUID
 *  @param completion Response is an image.
 */
- (void)getVehicleThumbnailWithUUID:(NSString *)uuid withCompletion:(void (^)(BOOL success, UIImage *image, NSError *error))completion {
    [self getVehicleThumbnailWithLat:0 andLon:0 withUUID:uuid withCompletion:^(BOOL success, UIImage *image, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            completion(success, image, error);
        });
    }];
}

/**
 *  Method is used to get vehicle images for license plate result.
 *
 *  @param latitude   Latitude needs to have 3 digits after the decimal point
 *  @param longitude  Longiture needs to have 3 digits after the decicmal point
 *  @param uuid       API requires the parking space UUID
 *  @param completion Response is an image.
 */
- (void)getVehicleThumbnailWithLat:(double)latitude
                            andLon:(double)longitude withUUID:(NSString *)uuid withCompletion:(void (^)(BOOL success, UIImage *image, NSError *error))completion {
    
    NSString *urlString = [NSString stringWithFormat:@"thumbnails/%@.jpg?%@", uuid, [self constuctWithLat:latitude andLon:longitude]];
    _manager.responseSerializer = [AFImageResponseSerializer serializer];
    
    [_manager GET:urlString
       parameters:nil success:^(AFHTTPRequestOperation * _Nonnull operation, id  _Nonnull responseObject) {
           [self runBlockInParserQueue:^{
               UIImage *image = responseObject;
               
               dispatch_async(dispatch_get_main_queue(), ^{
                   completion(YES, image, nil);
               });
           }];
       }
          failure:^(AFHTTPRequestOperation * _Nullable operation, NSError * _Nonnull error) {
              completion(NO, nil, error);
          }];
}

/**
 *  Use this to get the image representation of the parking lot map where the vehicle is located.
 *  X and Y coordinates are provided. You can then center based on the scale of the image. For example:
 *  long x = _parkingSpaceModel.position.x / image.scale;
 *  long y = _parkingSpaceModel.position.y / image.scale;
 *
 *  @param name       Map name in available parking response
 *  @param uuid       API requires the parking space UUID
 *  @param completion Response is a PNG representation of the map. Blue dot can be created using CAShapeLayer and use the x and y coordinates to set the path.
 */
- (void)getMapImageWithName:(NSString *)name andUUID:(NSString *)uuid withCompletion:(void (^)(BOOL success, UIImage *image, NSError *error))completion {
    [self getMapImageWithName:name andLat:0 andLon:0 withUUID:uuid withCompletion:^(BOOL success, UIImage *image, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            completion(success, image, error);
        });
    }];
}

/**
 *  Use this to get the image representation of the parking lot map where the vehicle is located.
 *  X and Y coordinates are provided. You can then center based on the scale of the image. For example:
 *  long x = _parkingSpaceModel.position.x / image.scale;
 *  long y = _parkingSpaceModel.position.y / image.scale;
 *
 *  @param name       Map name in available parking response
 *  @param latitude   Latitude needs to have 3 digits after the decimal point
 *  @param longitude  Longiture needs to have 3 digits after the decicmal point
 *  @param uuid       API requires the parking space UUID
 *  @param completion Response is an PNG representation of the map. Blue dot can be created using CAShapeLayer and use the x and y coordinates to set the path.
 */
- (void)getMapImageWithName:(NSString *)name andLat:(double)latitude
                     andLon:(double)longitude withUUID:(NSString *)uuid withCompletion:(void (^)(BOOL success, UIImage *image, NSError *error))completion {
    
    NSString *urlString = [NSString stringWithFormat:@"maps/%@.png?%@", name, [self constuctWithLat:latitude andLon:longitude]];
    _manager.responseSerializer = [AFImageResponseSerializer serializer];
    
    [_manager GET:urlString
       parameters:nil success:^(AFHTTPRequestOperation * _Nonnull operation, id  _Nonnull responseObject) {
           [self runBlockInParserQueue:^{
               UIImage *image = responseObject;
               
               dispatch_async(dispatch_get_main_queue(), ^{
                   completion(YES, image, nil);
               });
           }];
       }
          failure:^(AFHTTPRequestOperation * _Nullable operation, NSError * _Nonnull error) {
              completion(NO, nil, error);
          }];
}

/**
 *  CAShapeLayer to create bluedot bezier path using x and y coordinates to set the path on top of map.
 *
 *  @param view This is the UIImageView for the PNG map
 *  @param x    x coordinate provided in map response.
 *  @param y    y coordinate provided in map response.
 */
-(void)addSublayerToView:(UIView *)view atX:(long)x Y:(long)y andColor:(UIColor *)color {
    CAShapeLayer *circleLayer = [CAShapeLayer layer];
    [circleLayer setPath:[[UIBezierPath bezierPathWithOvalInRect:CGRectMake(x-3, y-3, 10, 10)] CGPath]];
    [circleLayer setFillColor:[color CGColor]];
    [[view layer] addSublayer:circleLayer];
}

-(NSString *)MD5String:(NSString *)string
{
    const char* str = [string UTF8String];
    unsigned char result[CC_MD5_DIGEST_LENGTH];
    CC_MD5(str, (CC_LONG)strlen(str), result);
    
    NSMutableString *md5Result = [NSMutableString stringWithCapacity:CC_MD5_DIGEST_LENGTH*2];
    for(int i = 0; i<CC_MD5_DIGEST_LENGTH; i++) {
        [md5Result appendFormat:@"%02x",result[i]];
    }
    return md5Result;
}

@end
