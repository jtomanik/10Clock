//
// Created by Joseph Daniels on 04/09/16.
// Copyright (c) 2016 Joseph Daniels. All rights reserved.
//

import Foundation
extension Date {
    var startOfDay: Date {
        return Calendar.current.startOfDay(for: self)
    }

    var endOfDay: Date? {
        var components = DateComponents()
        components.day = 1
        components.second = -1
        return (Calendar.current as NSCalendar).date(byAdding: components, to: startOfDay, options: NSCalendar.Options())
    }
    
//    - (NSDate *)dateToNearest15Minutes {
//    // Set up flags.
//    unsigned unitFlags = NSYearCalendarUnit| NSMonthCalendarUnit | NSDayCalendarUnit | NSWeekCalendarUnit |  NSHourCalendarUnit | NSMinuteCalendarUnit | NSSecondCalendarUnit | NSWeekdayCalendarUnit | NSWeekdayOrdinalCalendarUnit;
//    // Extract components.
//    NSDateComponents *comps = [[NSCalendar currentCalendar] components:unitFlags fromDate:self];
//    // Set the minute to the nearest 15 minutes.
//    [comps setMinute:((([comps minute] - 8 ) / 15 ) * 15 ) + 15];
//    // Zero out the seconds.
//    [comps setSecond:0];
//    // Construct a new date.
//    return [[NSCalendar currentCalendar] dateFromComponents:comps];
//    }
}
