import WidgetKit
import SwiftUI

struct PixelData: Codable {
    let pixels: [[String]]
}

struct Provider: TimelineProvider {
    let gridSize = 32
    
    func placeholder(in context: Context) -> PixelEntry {
        PixelEntry(date: Date(), pixels: Array(repeating: Array(repeating: "#FFFFFF", count: gridSize), count: gridSize))
    }

    func getSnapshot(in context: Context, completion: @escaping (PixelEntry) -> ()) {
        let entry = PixelEntry(date: Date(), pixels: loadPixels())
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        let entry = PixelEntry(date: Date(), pixels: loadPixels())
        let timeline = Timeline(entries: [entry], policy: .atEnd)
        completion(timeline)
    }
    
    func loadPixels() -> [[String]] {
        if let sharedDefaults = UserDefaults(suiteName: "group.com.thiendevlab.cute-pixel"),
           let data = sharedDefaults.data(forKey: "pixelData"),
           let pixelData = try? JSONDecoder().decode(PixelData.self, from: data) {
            return pixelData.pixels
        }
        return Array(repeating: Array(repeating: "#FFFFFF", count: gridSize), count: gridSize)
    }
}

struct PixelEntry: TimelineEntry {
    let date: Date
    let pixels: [[String]]
}

struct PixelWidgetEntryView : View {
    var entry: Provider.Entry
    
    var body: some View {
        GeometryReader { geometry in
            let gridSize = entry.pixels.count
            let size = max(geometry.size.width, geometry.size.height)
            let pixelSize = size / CGFloat(gridSize)
            
            VStack(spacing: 0) {
                ForEach(0..<gridSize, id: \.self) { row in
                    HStack(spacing: 0) {
                        ForEach(0..<gridSize, id: \.self) { col in
                            Rectangle()
                                .fill(Color(hex: entry.pixels[row][col]))
                                .frame(width: pixelSize, height: pixelSize)
                                .border(Color.black.opacity(0.1), width: 0.5)
                        }
                    }
                }
            }
        }
        .containerBackground(Color(hex: "#9BBC0F"), for: .widget)
    }
}

struct PixelWidget: Widget {
    let kind: String = "PixelWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            PixelWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Pixel Art")
        .description("Display your generated pixel art")
        .supportedFamilies([.systemSmall, .systemLarge])
    }
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r, g, b: UInt64
        switch hex.count {
        case 6:
            (r, g, b) = ((int >> 16) & 0xFF, (int >> 8) & 0xFF, int & 0xFF)
        default:
            (r, g, b) = (255, 255, 255)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: 1
        )
    }
}
