//
//  JiosWidgetBundle.swift
//  JiosWidget
//
//  Created by EternallyAscend on 2026/3/18.
//

import WidgetKit
import SwiftUI

@main
struct JiosWidgetBundle: WidgetBundle {
    var body: some Widget {
        JiosConfiguredWidget()
        JiosTodayWidget()
        JiosTaskBookWidget()
        JiosSelectedWidget()
        JiosAllWidget()
        JiosLockSelectedWidget()
    }
}
