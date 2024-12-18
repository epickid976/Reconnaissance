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
        GratitudeTodayWidget() // iOS 17-compatible widget

        if #available(iOS 18.0, *) {
            ReconnaissanceWidgetsLiveActivity()
        }
    }
}
