//
//  GratitudeRoutes.swift
//  Reconnaissance
//
//  Created by Jose Blanco on 12/10/24.
//

enum GratitudeRoutes: Hashable {
    case detail(DailyGratitude)
    case edit(DailyGratitude)
    case add
    case homeList
}
