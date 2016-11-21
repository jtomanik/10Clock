//
//  Date+Extensions.swift
//  TenClock
//
//  Created by Justyn Spooner on 21/11/2016.
//  Copyright © 2016 Joseph Daniels. All rights reserved.
//

import Foundation

extension Date {
    /**
     * Rounds the current date to the
     */
    func dateToNearestNextHalfHour() -> Date {
        
        let calendar = Calendar.current
        
        let components: Set<Calendar.Component> = [.year, .month, .weekday, .day, .hour, .minute, .second, .weekday, .weekdayOrdinal]
        
        var dateComps = calendar.dateComponents(components, from: self)
        
        dateComps.minute = ((dateComps.minute! / 30) * 30) + 30
        
        dateComps.second = 0
        
        return calendar.date(from: dateComps)!
    }
}
