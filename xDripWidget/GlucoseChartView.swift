//
//  GlucoseChartView.swift
//  xdrip
//
//  Created by Paul Plant on 13/01/2024.
//  Copyright © 2023 Johan Degraeve. All rights reserved.
//

import Charts
import SwiftUI
import Foundation

@available(iOS 16, *)
struct GlucoseChartView: View {
    
    var bgReadingValues: [Double]
    var bgReadingDates: [Date]
    let glucoseChartWidgetType: GlucoseChartWidgetType
    let isMgDl: Bool
    let urgentLowLimitInMgDl: Double
    let lowLimitInMgDl: Double
    let highLimitInMgDl: Double
    let urgentHighLimitInMgDl: Double
    let liveActivityNotificationSizeType: LiveActivityNotificationSizeType
    
    init(bgReadingValues: [Double], bgReadingDates: [Date], glucoseChartWidgetType: GlucoseChartWidgetType, isMgDl: Bool, urgentLowLimitInMgDl: Double, lowLimitInMgDl: Double, highLimitInMgDl: Double, urgentHighLimitInMgDl: Double, liveActivityNotificationSizeType: LiveActivityNotificationSizeType) {
        
        // as all widget instances are passed 12 hours of bg values, we must initialize this instance to use only the amount of hours of value required by the glucoseChartWidgetType passed
        self.bgReadingValues = []
        self.bgReadingDates = []
        
        var index = 0
        
        for _ in bgReadingValues {
            if bgReadingDates[index] > Date().addingTimeInterval(-glucoseChartWidgetType.hoursToShow(liveActivityNotificationSizeType: liveActivityNotificationSizeType) * 60 * 60) {
                self.bgReadingValues.append(bgReadingValues[index])
                self.bgReadingDates.append(bgReadingDates[index])
            }
            index += 1
        }
        
        self.glucoseChartWidgetType = glucoseChartWidgetType
        self.isMgDl = isMgDl
        self.urgentLowLimitInMgDl = urgentLowLimitInMgDl
        self.lowLimitInMgDl = lowLimitInMgDl
        self.highLimitInMgDl = highLimitInMgDl
        self.urgentHighLimitInMgDl = urgentHighLimitInMgDl
        self.liveActivityNotificationSizeType = liveActivityNotificationSizeType
    }
    
    /// Blood glucose color dependant on the user defined limit values
    /// - Returns: a Color object either red, yellow or green
    func bgColor(bgValueInMgDl: Double) -> Color {
        if bgValueInMgDl >= urgentHighLimitInMgDl || bgValueInMgDl <= urgentLowLimitInMgDl {
            return .red
        } else if bgValueInMgDl >= highLimitInMgDl || bgValueInMgDl <= lowLimitInMgDl {
            return .yellow
        } else {
            return .green
        }
    }
    
    func xAxisValues() -> [Date] {
        
        // adapted from generateXAxisValues() from GlucoseChartManager.swift in xDrip target
                
        let startDate: Date = bgReadingDates.last ?? Date().addingTimeInterval(-glucoseChartWidgetType.hoursToShow(liveActivityNotificationSizeType: liveActivityNotificationSizeType) * 3600)
        let endDate: Date = Date()
        
        /// how many full hours between startdate and enddate
        let amountOfFullHours = Int(ceil(endDate.timeIntervalSince(startDate) / 3600))
        
        /// create array that goes from 1 to number of full hours, as helper to map to array of ChartAxisValueDate - array will go from 1 to 6
        let mappingArray = Array(1...amountOfFullHours)
        
        /// set the stride count interval to make sure we don't add too many labels to the x-axis if the user wants to view >6 hours
        let intervalBetweenAxisValues: Int = glucoseChartWidgetType.intervalBetweenAxisValues(liveActivityNotificationSizeType: liveActivityNotificationSizeType)
        
        /// first, for each int in mappingArray, we create a Date, starting with the lower hour + 1 hour - we will create 5 in this example, starting with hour 08 (7 + 3600 seconds)
        let startDateLower = startDate.toLowerHour()
        
        let xAxisValues: [Date] = stride(from: 1, to: mappingArray.count + 1, by: intervalBetweenAxisValues).map {
            startDateLower.addingTimeInterval(Double($0)*3600)
        }
        
        return xAxisValues
        
    }
    

    var body: some View {
        let domain = 40 ... max(bgReadingValues.max() ?? 400, urgentHighLimitInMgDl)
        
        Chart {
            if domain.contains(urgentLowLimitInMgDl) {
                RuleMark(y: .value("", urgentLowLimitInMgDl))
                    .lineStyle(StrokeStyle(lineWidth: 1 * glucoseChartWidgetType.relativeYAxisLineSize, dash: [2 * glucoseChartWidgetType.relativeYAxisLineSize, 6 * glucoseChartWidgetType.relativeYAxisLineSize]))
                    .foregroundStyle(glucoseChartWidgetType.urgentLowHighLineColor)
            }
            
            if domain.contains(urgentHighLimitInMgDl) {
                RuleMark(y: .value("", urgentHighLimitInMgDl))
                    .lineStyle(StrokeStyle(lineWidth: 1 * glucoseChartWidgetType.relativeYAxisLineSize, dash: [2 * glucoseChartWidgetType.relativeYAxisLineSize, 6 * glucoseChartWidgetType.relativeYAxisLineSize]))
                    .foregroundStyle(glucoseChartWidgetType.urgentLowHighLineColor)
            }

            if domain.contains(lowLimitInMgDl) {
                RuleMark(y: .value("", lowLimitInMgDl))
                    .lineStyle(StrokeStyle(lineWidth: 1 * glucoseChartWidgetType.relativeYAxisLineSize, dash: [4 * glucoseChartWidgetType.relativeYAxisLineSize, 3 * glucoseChartWidgetType.relativeYAxisLineSize]))
                    .foregroundStyle(glucoseChartWidgetType.lowHighLineColor)
            }
            
            if domain.contains(highLimitInMgDl) {
                RuleMark(y: .value("", highLimitInMgDl))
                    .lineStyle(StrokeStyle(lineWidth: 1 * glucoseChartWidgetType.relativeYAxisLineSize, dash: [4 * glucoseChartWidgetType.relativeYAxisLineSize, 3 * glucoseChartWidgetType.relativeYAxisLineSize]))
                    .foregroundStyle(glucoseChartWidgetType.lowHighLineColor)
            }

            ForEach(bgReadingValues.indices, id: \.self) { index in
                    PointMark(x: .value("Time", bgReadingDates[index]),
                              y: .value("BG", bgReadingValues[index]))
                    .symbol(Circle())
                    .symbolSize(glucoseChartWidgetType.glucoseCircleDiameter)
                    .foregroundStyle(bgColor(bgValueInMgDl: bgReadingValues[index]))
            }
        }
        .chartXAxis {
            // https://developer.apple.com/documentation/charts/customizing-axes-in-swift-charts
            AxisMarks(values: xAxisValues()) {
                
                if let v = $0.as(Date.self) {
                    AxisValueLabel {
                        Text(v.formatted(.dateTime.hour()))
                            .foregroundStyle(Color.white)
                    }
                    .offset(x: glucoseChartWidgetType.xAxisLabelOffset)
                    AxisGridLine()
                        .foregroundStyle(glucoseChartWidgetType.xAxisGridLineColor)
                }
            }
        }
        .chartYAxis(.hidden)
        .chartYScale(domain: domain)
        .frame(width: glucoseChartWidgetType.viewSize(liveActivityNotificationSizeType: liveActivityNotificationSizeType).width, height: glucoseChartWidgetType.viewSize(liveActivityNotificationSizeType: liveActivityNotificationSizeType).height)
    }
}
