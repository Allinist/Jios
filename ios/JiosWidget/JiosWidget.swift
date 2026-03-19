import SwiftUI
import WidgetKit

private enum WidgetMode: String {
    case configured
    case today
    case book
    case selected
    case all
}

private struct WidgetTask: Decodable {
    let id: Int?
    let title: String
    let taskBookId: Int?
    let status: String?
    let completed: Bool
    let isToday: Bool
    let time: String

    enum CodingKeys: String, CodingKey {
        case id
        case title
        case taskBookId = "task_book_id"
        case status
        case completed
        case isToday = "is_today"
        case time
    }
}

private struct DisplayTask: Identifiable {
    let id: String
    let task: WidgetTask
}

private struct WidgetConfig: Decodable {
    let mode: String
    let taskBookId: Int?
    let taskIds: [Int]

    enum CodingKeys: String, CodingKey {
        case mode
        case taskBookId = "task_book_id"
        case taskIds = "task_ids"
    }
}

private struct WidgetPayload: Decodable {
    let tasks: [WidgetTask]
}

private struct SimpleEntry: TimelineEntry {
    let date: Date
    let tasks: [WidgetTask]
    let title: String
}

private struct Provider: TimelineProvider {
    let mode: WidgetMode
    let title: String

    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date(), tasks: [], title: title)
    }

    func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> Void) {
        completion(SimpleEntry(date: Date(), tasks: loadTasks(), title: title))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<SimpleEntry>) -> Void) {
        let entry = SimpleEntry(date: Date(), tasks: loadTasks(), title: title)
        let timeline = Timeline(entries: [entry], policy: .after(Date().addingTimeInterval(300)))
        completion(timeline)
    }

    private func loadTasks() -> [WidgetTask] {
        let defaults = UserDefaults(suiteName: "group.com.example.jios")

        guard let payloadString = defaults?.string(forKey: "widget_tasks"),
              let payloadData = payloadString.data(using: .utf8),
              let payload = try? JSONDecoder().decode(WidgetPayload.self, from: payloadData) else {
            return []
        }

        let config: WidgetConfig = {
            guard let configString = defaults?.string(forKey: "widget_config"),
                  let configData = configString.data(using: .utf8),
                  let cfg = try? JSONDecoder().decode(WidgetConfig.self, from: configData) else {
                return WidgetConfig(mode: "today", taskBookId: nil, taskIds: [])
            }
            return cfg
        }()

        let effectiveMode: WidgetMode = {
            switch mode {
            case .configured:
                switch config.mode {
                case "book":
                    return .book
                case "selected":
                    return .selected
                default:
                    return .today
                }
            default:
                return mode
            }
        }()

        switch effectiveMode {
        case .book:
            if let bookId = config.taskBookId {
                return payload.tasks.filter { $0.taskBookId == bookId && !isCompleted($0) }
            }
            return payload.tasks.filter { $0.isToday && !isCompleted($0) }
        case .selected:
            let selected = Set(config.taskIds)
            return payload.tasks.filter {
                guard let id = $0.id else { return false }
                return selected.contains(id) && !isCompleted($0)
            }
        case .all:
            return payload.tasks.filter { !isCompleted($0) }
        case .today, .configured:
            return payload.tasks.filter { $0.isToday && !isCompleted($0) }
        }
    }

    private func isCompleted(_ task: WidgetTask) -> Bool {
        task.completed || task.status == "completed"
    }
}

private struct DayMasterWidgetEntryView: View {
    @Environment(\.widgetFamily) var family
    let entry: SimpleEntry

    var body: some View {
        Group {
            switch family {
            case .systemSmall:
                smallView
            case .systemMedium:
                mediumView
            case .systemLarge:
                largeView
            case .accessoryInline:
                inlineView
            case .accessoryCircular:
                circularView
            case .accessoryRectangular:
                rectangularView
            default:
                mediumView
            }
        }
        .widgetURL(URL(string: "jios://open"))
    }

    private var displayTasks: [DisplayTask] {
        Array(entry.tasks.prefix(8).enumerated()).map { index, task in
            DisplayTask(id: "\(task.id ?? -1)-\(index)-\(task.title)", task: task)
        }
    }

    var smallView: some View {
        VStack(alignment: .leading) {
            Text(entry.title)
                .font(.headline)

            if let task = entry.tasks.first {
                Text("• \(task.title)")
                    .font(.caption)
                    .lineLimit(2)
            } else {
                Text("无任务")
                    .font(.caption)
            }
        }
        .padding()
    }

    var mediumView: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(entry.title)
                .font(.headline)

            if displayTasks.isEmpty {
                Text("无任务")
                    .font(.caption)
            } else {
                ForEach(displayTasks.prefix(4)) { item in
                    VStack(alignment: .leading, spacing: 2) {
                        Text("• \(item.task.title)")
                            .font(.caption)
                            .lineLimit(1)

                        if !item.task.time.isEmpty {
                            Text(item.task.time)
                                .font(.caption2)
                                .foregroundColor(.gray)
                        }
                    }
                }
            }
        }
        .padding()
    }

    var largeView: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Day Master")
                .font(.title3)

            Text(entry.title)
                .font(.headline)

            if displayTasks.isEmpty {
                Text("无任务")
                    .font(.caption)
            } else {
                ForEach(displayTasks) { item in
                    VStack(alignment: .leading, spacing: 2) {
                        Text("• \(item.task.title)")
                            .lineLimit(1)

                        if !item.task.time.isEmpty {
                            Text(item.task.time)
                                .font(.caption2)
                                .foregroundColor(.gray)
                        }
                    }
                }
            }

            Spacer()
        }
        .padding()
    }

    var inlineView: some View {
        if let task = entry.tasks.first {
            return Text("\(entry.title): \(task.title)")
        }
        return Text("\(entry.title): 无任务")
    }

    var circularView: some View {
        ZStack {
            Circle().fill(Color.blue.opacity(0.18))
            VStack(spacing: 2) {
                Text("\(entry.tasks.count)")
                    .font(.headline)
                Text("项")
                    .font(.caption2)
            }
        }
    }

    var rectangularView: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(entry.title)
                .font(.caption)
                .fontWeight(.semibold)

            if let first = entry.tasks.first {
                Text(first.title)
                    .font(.caption2)
                    .lineLimit(2)
            } else {
                Text("无任务")
                    .font(.caption2)
            }
        }
    }
}

private func makeWidgetConfiguration(
    kind: String,
    title: String,
    description: String,
    mode: WidgetMode
) -> some WidgetConfiguration {
    StaticConfiguration(kind: kind, provider: Provider(mode: mode, title: title)) { entry in
        if #available(iOSApplicationExtension 17.0, *) {
            DayMasterWidgetEntryView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        } else {
            DayMasterWidgetEntryView(entry: entry)
        }
    }
    .configurationDisplayName(title)
    .description(description)
    .supportedFamilies(supportedFamilies())
}

private func supportedFamilies() -> [WidgetFamily] {
    var families: [WidgetFamily] = [
        .systemSmall,
        .systemMedium,
        .systemLarge,
    ]

    if #available(iOSApplicationExtension 16.0, *) {
        families.append(contentsOf: [
            .accessoryInline,
            .accessoryRectangular,
            .accessoryCircular,
        ])
    }

    return families
}

struct JiosConfiguredWidget: Widget {
    var body: some WidgetConfiguration {
        makeWidgetConfiguration(
            kind: "DayMasterConfiguredWidget",
            title: "日程（按设置）",
            description: "按应用设置显示今日日程/任务本/指定任务",
            mode: .configured
        )
    }
}

struct JiosTodayWidget: Widget {
    var body: some WidgetConfiguration {
        makeWidgetConfiguration(
            kind: "DayMasterTodayWidget",
            title: "今日日程",
            description: "显示今日未完成日程",
            mode: .today
        )
    }
}

struct JiosTaskBookWidget: Widget {
    var body: some WidgetConfiguration {
        makeWidgetConfiguration(
            kind: "DayMasterTaskBookWidget",
            title: "任务本日程",
            description: "显示设置中选定任务本的未完成日程",
            mode: .book
        )
    }
}

struct JiosSelectedWidget: Widget {
    var body: some WidgetConfiguration {
        makeWidgetConfiguration(
            kind: "DayMasterSelectedWidget",
            title: "选定日程",
            description: "显示设置中选定的一组日程",
            mode: .selected
        )
    }
}

struct JiosAllWidget: Widget {
    var body: some WidgetConfiguration {
        makeWidgetConfiguration(
            kind: "DayMasterAllWidget",
            title: "全部待办",
            description: "显示全部未完成日程",
            mode: .all
        )
    }
}
