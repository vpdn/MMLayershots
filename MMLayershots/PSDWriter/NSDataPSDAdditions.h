//
//  NSDataPSDAdditions.h
//  PSDWriter
//
//  Created by Ben Gotow on 5/24/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface NSMutableData (PSDAdditions)

/** Allows you to append a numeric value to an NSMutableData object and pad it to any length. 

For example, we could say [data appendValue: 2 withLength: 5], and 00002 would be written
into the data object. Very useful for writing to file formats that have header structures
that require a certain number of bytes be used for a certain value. i.e. PSD and TIFF 

@param value: The value to append
@param length: The number of bytes that should be used to store the value. The value will be padded
to length bytes regardless of the number of bytes required to store it.
*/
- (void)appendValue:(long)value withLength:(int)length;

@end

@interface NSData (PSDAdditions)

/** Takes packedBits data and prints out a description of the packed contents by
running the decode operation and explaining via NSLog how the data is being 
decoded. Useful for checking that packedBits data is correct. */
- (NSString *)packedBitsDescription;

/** A special version of packedBits which will take the data and pack every nth
value. 

This is important for PSDWriter because it's necessary to encode R, then G,
then B, then A data - so we essentially start at offset 0, skip 4, then do offset 1,
skip 4, etc... to compress the data with very minimal memory footprint. 

For normal packbits just to skip = 1 

@param range: The range within the data object that should be encoded. Useful
for specifying a non-zero starting offset to get a certain channel encoded.
@param skip: The number of bytes to advance as the data is encoded. Skip = 1 will
encode every byte, skip = 4 will encode every fourth byte, and so on.
*/
- (NSData *)packedBitsForRange:(NSRange)range skip:(int)skip;


@end
