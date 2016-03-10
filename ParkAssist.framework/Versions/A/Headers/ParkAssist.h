//
//  ParkAssist.h
//  ParkAssist
//
//  Created by Gabriel Morales on 2/8/16.
//  Copyright © 2016 Phunware. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface ParkAssist : NSObject

+ (ParkAssist *)sharedInstance;

+ (instancetype)initWithSecret:(NSString *)secret andSiteSlug:(NSString *)slug;


/**
 *  Search for license plate without lat and long.
 *
 *  @param plate      A minimum of 3 alpha numeric characters.
 *  @param completion If success, response will be an array of dictionaries. 3 max.
 */
- (void)searchLicensePlate:(NSString *)plate withCompletion:(void(^)(BOOL success, NSArray *results, NSError *error))completion;

/**
 *  Search for license plates.
 *
 *  @param plate      A minimum of 3 alpha numberic characters
 *  @param latitude   Latitude needs to have 3 digits after the decimal point
 *  @param longitude  Longiture needs to have 3 digits after the decicmal point
 *  @param completion If success, api will return a maximum of 3 items.
 */
- (void)searchLicensePlate:(NSString *)plate withLat:(double)latitude
                    andLon:(double)longitude withCompletion:(void(^)(BOOL success, NSArray *results, NSError *error))completion;

/**
 *  Get available parking info without lat and long
 *
 *  @param completion Response is an array of dictionaries.
 */
- (void)getAvailableParkingInfo:(void(^)(BOOL success, NSArray*results, NSError*error))completion;

/**
 *  Get available parking spaces for zone.
 *
 *  @param latitude   Latitude needs to have 3 digits after the decimal point
 *  @param longitude  Longiture needs to have 3 digits after the decicmal point
 *  @param completion response is an array.
 */
- (void)getAvailableParkingInfoWithLat:(double)latitude
                                andLon:(double)longitude withCompletion:(void (^)(BOOL success, NSArray *results, NSError *error))completion;

/**
 *  Method us used to get vehicle images for license plate result.
 *
 *  @param uuid       API requires the parking space UUID
 *  @param completion Response is an image.
 */
- (void)getVehicleThumbnailWithUUID:(NSString *)uuid withCompletion:(void (^)(BOOL success, UIImage *image, NSError *error))completion;

/**
 *  Method is used to get vehicle images for license plate result.
 *
 *  @param latitude   Latitude needs to have 3 digits after the decimal point
 *  @param longitude  Longiture needs to have 3 digits after the decicmal point
 *  @param uuid       API requires the parking space UUID
 *  @param completion Response is an image.
 */
- (void)getVehicleThumbnailWithLat:(double)latitude
                            andLon:(double)longitude withUUID:(NSString *)uuid withCompletion:(void (^)(BOOL success, UIImage *image, NSError *error))completion;

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
- (void)getMapImageWithName:(NSString *)name andUUID:(NSString *)uuid withCompletion:(void (^)(BOOL success, UIImage *image, NSError *error))completion;

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
                     andLon:(double)longitude withUUID:(NSString *)uuid withCompletion:(void (^)(BOOL success, UIImage *image, NSError *error))completion;

/**
 *  CAShapeLayer to create bluedot bezier path using x and y coordinates to set the path on top of map.
 *
 *  @param view This is the UIImageView for the PNG map
 *  @param x    x coordinate provided in map response.
 *  @param y    y coordinate provided in map response.
 */
-(void)addSublayerToView:(UIView *)view atX:(long)x Y:(long)y andColor:(UIColor *)color;

@end
