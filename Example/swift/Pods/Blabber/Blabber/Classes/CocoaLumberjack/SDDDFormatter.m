// Copyright 2016 Sysdata Digital
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

#import "SDDDFormatter.h"

@implementation SDDDFormatter

- (id) init
{
	if ((self = [super init]))
	{
		dateFormatter = [[NSDateFormatter alloc] init];
		[dateFormatter setFormatterBehavior:NSDateFormatterBehavior10_4];
		[dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss:SSS"];
	}
	return self;
}

- (NSString*) formatLogMessage:(DDLogMessage*)logMessage
{
	NSString* logLevel;

	switch (logMessage->_flag)
	{
		case DDLogFlagError :
			logLevel = @"Error:";
			break;

		case DDLogFlagWarning :
			logLevel = @"Warning:";
			break;

		case DDLogFlagInfo :
			logLevel = @"Info:";
			break;

        case DDLogFlagDebug :
			logLevel = @"Debug:";
			break;

		default :
			logLevel = @"Verbose:";
			break;
	}

	NSString* dateAndTime = [dateFormatter stringFromDate:(logMessage->_timestamp)];
	NSString* logMsg = logMessage->_message;

	return [NSString stringWithFormat:@"%@ in %@ #%lu (%@ %@)\n%@", [logMessage function], [logMessage fileName], (unsigned long)logMessage->_line, logLevel, dateAndTime, logMsg];
}

@end
