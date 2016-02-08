//
//  NSString+MD5.m
//  ParkAssist
//
//  Created by Gabriel Morales on 2/5/16.
//  Copyright © 2016 Phunware. All rights reserved.
//

#import "NSString+MD5.h"
#import <CommonCrypto/CommonCrypto.h>
@implementation NSString (MD5)

-(NSString *)MD5String
{
    const char* str = [self UTF8String];
    unsigned char result[CC_MD5_DIGEST_LENGTH];
    CC_MD5(str, (CC_LONG)strlen(str), result);
    
    NSMutableString *md5Result = [NSMutableString stringWithCapacity:CC_MD5_DIGEST_LENGTH*2];
    for(int i = 0; i<CC_MD5_DIGEST_LENGTH; i++) {
        [md5Result appendFormat:@"%02x",result[i]];
    }
    return md5Result;
}

@end
