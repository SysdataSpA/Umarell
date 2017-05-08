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

// This code is compatible with our logger "Blabber".
#define kUmarellLogModuleName @"Umarell"

#if __has_include("SDLogger.h") || __has_include("Blabber/SDLogger.h")
#define SD_LOGGER_AVAILABLE 1
#import <Blabber/SDLogger.h>
#else
#define SDLogError(frmt, ...)   NSLog(frmt, ##__VA_ARGS__)
#define SDLogWarning(frmt, ...) NSLog(frmt, ##__VA_ARGS__)
#define SDLogInfo(frmt, ...)    NSLog(frmt, ##__VA_ARGS__)
#define SDLogVerbose(frmt, ...) NSLog(frmt, ##__VA_ARGS__)
#define SDLogModuleError(mdl, frmt, ...)   NSLog(frmt, ##__VA_ARGS__)
#define SDLogModuleWarning(mdl, frmt, ...) NSLog(frmt, ##__VA_ARGS__)
#define SDLogModuleInfo(mdl, frmt, ...)    NSLog(frmt, ##__VA_ARGS__)
#define SDLogModuleVerbose(mdl, frmt, ...) NSLog(frmt, ##__VA_ARGS__)
#endif
