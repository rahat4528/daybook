// DayBook iOS WidgetKit Target: Trip Countdown with Live Widgets (Page 01)
// Built in SwiftUI with @bacons/apple-targets and App Group Shared Container.

import WidgetKit
import SwiftUI

struct TripWidgetSnapshot: Codable {
    let tripId: String
    let route: String
    let destination: String
    let flightNum: String
    let targetTimestamp: Int
    let statusText: String
    let countdownText: String
}

struct TripEntry: TimelineEntry {
    let date: Date
    let route: String
    let destination: String
    let targetDate: Date
    let flightNum: String
    let statusText: String
}

struct TripTimelineProvider: TimelineProvider {
    func placeholder(in context: Context) -> TripEntry {
        TripEntry(
            date: Date(),
            route: "DAC ➔ LHR",
            destination: "London",
            targetDate: Date().addingTimeInterval(86400 * 5),
            flightNum: "BG201",
            statusText: "SCHEDULED"
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (TripEntry) -> Void) {
        completion(loadSharedSnapshot())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<TripEntry>) -> Void) {
        let entry = loadSharedSnapshot()
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 30, to: Date())!
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }

    private func loadSharedSnapshot() -> TripEntry {
        guard let userDefaults = UserDefaults(suiteName: "group.org.daybook.app"),
              let jsonString = userDefaults.string(forKey: "trip_widget_data"),
              let data = jsonString.data(using: .utf8),
              let snapshot = try? JSONDecoder().decode(TripWidgetSnapshot.self, from: data) else {
            return placeholder(in: .init())
        }

        let target = Date(timeIntervalSince1970: TimeInterval(snapshot.targetTimestamp))
        return TripEntry(
            date: Date(),
            route: snapshot.route,
            destination: snapshot.destination,
            targetDate: target,
            flightNum: snapshot.flightNum,
            statusText: snapshot.statusText
        )
    }
}

struct TripWidgetEntryView: View {
    var entry: TripTimelineProvider.Entry
    @Environment(\.widgetFamily) var family

    var body: some View {
        ZStack {
            Color.black

            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Image(systemName: "airplane")
                        .foregroundColor(Color(hex: "#B6FF00"))
                        .font(.system(size: 13, weight: .bold))
                    Text(entry.route)
                        .foregroundColor(.white)
                        .font(.system(size: 12, weight: .black, design: .monospaced))
                    Spacer()
                    if !entry.flightNum.isEmpty {
                        Text(entry.flightNum)
                            .foregroundColor(Color(hex: "#8E8E93"))
                            .font(.system(size: 10, weight: .bold))
                    }
                }

                Spacer()

                Text(entry.targetDate, style: .relative)
                    .foregroundColor(Color(hex: "#B6FF00"))
                    .font(.system(size: 20, weight: .heavy, design: .monospaced))
                    .privacySensitive()

                Text(entry.destination)
                    .foregroundColor(Color(hex: "#8E8E93"))
                    .font(.system(size: 11, weight: .medium))
            }
            .padding(14)
        }
    }
}

extension Color {
    init(hex: String) {
        let scanner = Scanner(string: hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted))
        var int: UInt64 = 0
        scanner.scanHexInt64(&int)
        let r = Double((int >> 16) & 0xFF) / 255.0
        let g = Double((int >> 8) & 0xFF) / 255.0
        let b = Double(int & 0xFF) / 255.0
        self.init(red: r, green: g, blue: b)
    }
}

@main
struct DayBookWidgetBundle: WidgetBundle {
    var body: some Widget {
        TripWidget()
    }
}

struct TripWidget: Widget {
    let kind: String = "TripWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: TripTimelineProvider()) { entry in
            TripWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("DayBook Trip Countdown")
        .description("Glance upcoming travel departure times directly from your Home or Lock screen.")
        .supportedFamilies([.systemSmall, .systemMedium, .accessoryRectangular])
    }
}
