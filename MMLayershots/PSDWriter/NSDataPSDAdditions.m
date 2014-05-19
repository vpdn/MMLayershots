//
//  NSDataPSDAdditions.m
//  PSDWriter
//
//  Created by Ben Gotow on 5/24/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "NSDataPSDAdditions.h"

#define MIN_RUN		3		/* minimum run length to encode */
#define MAX_RUN		127		/* maximum run length to encode */
#define MAX_COPY	128		/* maximum characters to copy */

/* maximum that can be read before copy block is written */
#define MAX_READ	(MAX_COPY + MIN_RUN - 1)


@implementation NSMutableData (PSDAdditions)

- (void)appendValue:(long)value withLength:(int)length
{
	Byte bytes[8];
	
	double divider = 1;
	for (int ii = 0; ii < length; ii++){
		bytes[length-ii-1] = (long)(value / divider) % 256;
		divider *= 256;
	}

	[self appendBytes:&bytes length:length];
}

@end

@implementation NSData (PSDAdditions)

- (NSString*)packedBitsDescription
{
	NSMutableString * description = [NSMutableString string];
	char * row = (char*)[self bytes];
	int pbOffset = 0;
	int pbResultBytes = 0;
	
	while (pbOffset < [self length]){
		int headerByte = (int)row[pbOffset];
		if (headerByte < 0){
			int repeatTimes = 1-headerByte;
			UInt8 repeatByte = (UInt8)row[pbOffset+1];
			[description appendFormat: @"Printing %u %d times. ", repeatByte, repeatTimes];
			
			pbResultBytes += repeatTimes;
			pbOffset += 2;
		} else if (headerByte >= 0){
			[description appendFormat: @"Printing %d literal bytes. ", headerByte + 1];
			pbResultBytes += headerByte + 1;
			pbOffset += 2 + headerByte;
		}
	}
	
	[description appendFormat: @"Total: %d bytes decoded.", pbResultBytes];
	return description;
}

- (NSData*)packedBitsForRange:(NSRange)range skip:(int)skip
{
	const char * bytesIn = [self bytes];
	unsigned long bytesLength = range.location + range.length;
	unsigned long	bytesOffset = range.location;
	NSMutableData * dataOut = [NSMutableData data];

	BOOL currIsEOF = NO;
	unsigned char currChar;			/* current character */
	unsigned char charBuf[MAX_READ];	/* buffer of already read characters */
	int count;						 /* number of characters in a run */

	/* prime the read loop */
	currChar = bytesIn[bytesOffset];
	bytesOffset = bytesOffset + skip;
	count = 0;

	/* read input until there's nothing left */
	while (!currIsEOF)
	{
		charBuf[count] = (unsigned char)currChar;
		count++;
		
		if (count >= MIN_RUN) {
			int i;
			/* check for run  charBuf[count - 1] .. charBuf[count - MIN_RUN]*/
			for (i = 2; i <= MIN_RUN; i++){
				if (currChar != charBuf[count - i]){
					/* no run */
					i = 0;
					break;
				}
			}

			if (i != 0)
			{
				/* we have a run write out buffer before run*/
				int nextChar;

				if (count > MIN_RUN){
					/* block size - 1 followed by contents */
					UInt8 a = count - MIN_RUN - 1;
					[dataOut appendBytes:&a length:sizeof(UInt8)];
					[dataOut appendBytes:&charBuf length:sizeof(unsigned char) * (count - MIN_RUN)];
				}

				/* determine run length (MIN_RUN so far) */
				count = MIN_RUN;
				while (true) {
					if (bytesOffset < bytesLength){
						nextChar = bytesIn[bytesOffset];
						bytesOffset += skip;
					} else {
						currIsEOF = YES;
						nextChar = EOF;
					}
					if (nextChar != currChar) break;
					
					count++;
					if (count == MAX_RUN){
						/* run is at max length */
						break;
					}
				}

				/* write out encoded run length and run symbol */
				UInt8 a = ((int)(1 - (int)(count)));
				[dataOut appendBytes:&a length:sizeof(UInt8)];
				[dataOut appendBytes:&currChar length:sizeof(UInt8)];

				if ((!currIsEOF) && (count != MAX_RUN)){
					/* make run breaker start of next buffer */
					charBuf[0] = nextChar;
					count = 1;
				} else {
					/* file or max run ends in a run */
					count = 0;
				}
			}
		}

		if (count == MAX_READ)
		{
			int i;

			/* write out buffer */
			UInt8 a = MAX_COPY - 1;
			[dataOut appendBytes:&a length:sizeof(UInt8)];
			[dataOut appendBytes:&charBuf[0] length:sizeof(unsigned char) * MAX_COPY];
		
			/* start a new buffer */
			count = MAX_READ - MAX_COPY;

			/* copy excess to front of buffer */
			for (i = 0; i < count; i++)
				charBuf[i] = charBuf[MAX_COPY + i];
		}

		if (bytesOffset < bytesLength)
			currChar = bytesIn[bytesOffset];
		else
			currIsEOF = YES;
		bytesOffset += skip;
	}

	/* write out last buffer */
	if (0 != count)
	{
		if (count <= MAX_COPY) {
			/* write out entire copy buffer */
			UInt8 a = count - 1;
			[dataOut appendBytes:&a length:sizeof(UInt8)];
			[dataOut appendBytes:&charBuf length:sizeof(unsigned char) * count];
		}
		else
		{
			/* we read more than the maximum for a single copy buffer */
			UInt8 a = MAX_COPY - 1;
			[dataOut appendBytes:&a length:sizeof(UInt8)];
			[dataOut appendBytes:&charBuf length:sizeof(unsigned char) * MAX_COPY];

			/* write out remainder */
			count -= MAX_COPY;
			a = count - 1;
			[dataOut appendBytes:&a length:sizeof(UInt8)];
			[dataOut appendBytes:&charBuf[MAX_COPY] length:sizeof(unsigned char) * count];
		}
	}

	return dataOut;
}



@end
