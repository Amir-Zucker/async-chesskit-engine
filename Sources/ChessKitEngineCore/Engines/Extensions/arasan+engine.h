//
//  arasan+engine.h
//
//  Created by Amir Zucker on 10/01/2025
//

#ifndef arasan_engine_h
#define arasan_engine_h

#import "engine.h"
#import <string>
#include <CoreFoundation/CoreFoundation.h>

/// Arasan implementation of `Engine`.
class ArasanEngine: public Engine {
public:
    void initialize();
    void deinitialize();
    
private:
    void copyBundleFiles();
    void copyBundleFile(CFStringRef fileName, CFStringRef fileExtenstion);
};

#endif /* arasan_engine_h */
