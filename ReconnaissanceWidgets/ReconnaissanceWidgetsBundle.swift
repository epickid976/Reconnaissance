//
//  ReconnaissanceWidgetsBundle.swift
//  ReconnaissanceWidgets
//
//  Created by Jose Blanco on 12/17/24.
//

import WidgetKit
import SwiftUI

@main
struct GratitudeWidgetBundle: WidgetBundle {
    @WidgetBundleBuilder
    var body: some Widget {
        GratitudeTodayWidget()
        MilestonesWidget()
        ReflectionSummaryWidget()
        MemoryOfGratitudeWidget()
       // HeatmapWidget()

        if #available(iOS 17.0, *) {
            ReconnaissanceWidgetsLiveActivity()
        }
    }
}
