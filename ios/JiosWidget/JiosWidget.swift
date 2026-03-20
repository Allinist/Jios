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
    let timelineLines: [String]
    let widgetInfo: String
    let widgetScopes: [String]

    enum CodingKeys: String, CodingKey {
        case id
        case title
        case taskBookId = "task_book_id"
        case status
        case completed
        case isToday = "is_today"
        case timelineLines = "timeline_lines"
        case widgetInfo = "widget_info"
        case widgetScopes = "widget_scopes"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(Int.self, forKey: .id)
        title = try container.decodeIfPresent(String.self, forKey: .title) ?? ""
        taskBookId = try container.decodeIfPresent(Int.self, forKey: .taskBookId)
        status = try container.decodeIfPresent(String.self, forKey: .status)
        completed = try container.decodeIfPresent(Bool.self, forKey: .completed) ?? false
        isToday = try container.decodeIfPresent(Bool.self, forKey: .isToday) ?? false
        timelineLines = try container.decodeIfPresent([String].self, forKey: .timelineLines) ?? []
        widgetInfo = try container.decodeIfPresent(String.self, forKey: .widgetInfo) ?? ""
        widgetScopes = try container.decodeIfPresent([String].self, forKey: .widgetScopes) ?? []
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
    let hideLockscreenTitle: Bool
}

private struct Provider: TimelineProvider {
    let mode: WidgetMode
    let title: String
    let configKeyOverride: String?
    let hideLockscreenTitle: Bool

    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date(), tasks: [], title: title, hideLockscreenTitle: hideLockscreenTitle)
    }

    func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> Void) {
        completion(SimpleEntry(date: Date(), tasks: loadTasks(), title: title, hideLockscreenTitle: hideLockscreenTitle))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<SimpleEntry>) -> Void) {
        let entry = SimpleEntry(date: Date(), tasks: loadTasks(), title: title, hideLockscreenTitle: hideLockscreenTitle)
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

        let configKey = configStorageKey()
        let config: WidgetConfig = {
            guard let configString = defaults?.string(forKey: configKey) ?? defaults?.string(forKey: "widget_config"),
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
            if selected.isEmpty {
                return payload.tasks.filter { $0.isToday && !isCompleted($0) }
            }
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

    private func configStorageKey() -> String {
        if let key = configKeyOverride, !key.isEmpty {
            return key
        }
        switch mode {
        case .book:
            return "widget_config_book"
        case .selected:
            return "widget_config_selected"
        case .configured:
            return "widget_config_configured"
        default:
            return "widget_config_configured"
        }
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
        let filtered = entry.tasks.filter { task in
            isTaskVisible(task: task, for: family)
        }
        return Array(filtered.prefix(30).enumerated()).map { index, task in
            DisplayTask(id: "\(task.id ?? -1)-\(index)-\(task.title)", task: task)
        }
    }

    var smallView: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(entry.title)
                .font(.caption)
                .fontWeight(.semibold)

            if displayTasks.isEmpty {
                Text("无任务")
                    .font(.caption2)
            } else {
                VStack(alignment: .leading, spacing: 1) {
                    ForEach(displayTasks.prefix(6)) { item in
                        taskRow(item.task)
                    }
                }
            }
        }
        .padding(6)
    }

    var mediumView: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(entry.title)
                .font(.caption)
                .fontWeight(.semibold)

            if displayTasks.isEmpty {
                Text("无任务")
                    .font(.caption2)
            } else {
                twoColumnGrid(items: Array(displayTasks.prefix(12)))
            }
        }
        .padding(6)
    }

    var largeView: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(entry.title)
                .font(.caption)
                .fontWeight(.semibold)

            if displayTasks.isEmpty {
                Text("无任务")
                    .font(.caption2)
            } else {
                twoColumnGrid(items: Array(displayTasks.prefix(24)))
            }

            Spacer()
        }
        .padding(6)
    }

    var inlineView: some View {
        if let task = displayTasks.first?.task {
            if task.widgetInfo.isEmpty {
                return Text(task.title)
            }
            return Text("\(task.title) \(task.widgetInfo)")
        }
        return Text("无任务")
    }

    var circularView: some View {
        ZStack {
            Circle().fill(Color.blue.opacity(0.18))
            VStack(spacing: 2) {
                Text("\(displayTasks.count)")
                    .font(.headline)
                Text("项")
                    .font(.caption2)
            }
        }
    }

    var rectangularView: some View {
        VStack(alignment: .leading, spacing: 2) {
            if !(entry.hideLockscreenTitle) {
                Text(entry.title)
                    .font(.caption2)
                    .fontWeight(.semibold)
            }

            if displayTasks.isEmpty {
                Text("无任务")
                    .font(.caption2)
            } else {
                ForEach(displayTasks.prefix(3)) { item in
                    taskRow(item.task)
                }
            }
        }
    }

    @ViewBuilder
    private func twoColumnGrid(items: [DisplayTask]) -> some View {
        LazyVGrid(
            columns: [
                GridItem(.flexible(), alignment: .topLeading),
                GridItem(.flexible(), alignment: .topLeading),
            ],
            spacing: 4
        ) {
            ForEach(items) { item in
                taskCell(item.task)
            }
        }
    }

    @ViewBuilder
    private func taskCell(_ task: WidgetTask) -> some View {
        taskRow(task)
    }

    @ViewBuilder
    private func taskRow(_ task: WidgetTask) -> some View {
        HStack(spacing: 4) {
            Text(task.title)
                .font(.caption2)
                .lineLimit(1)
                .frame(maxWidth: .infinity, alignment: .leading)

            if !task.widgetInfo.isEmpty {
                Text(task.widgetInfo)
                    .font(.caption2)
                    .foregroundColor(.gray)
                    .lineLimit(1)
                    .multilineTextAlignment(.trailing)
            }
        }
    }

    private func isTaskVisible(task: WidgetTask, for family: WidgetFamily) -> Bool {
        let scopes = task.widgetScopes
        if scopes.isEmpty {
            return true
        }
        switch family {
        case .systemSmall:
            return scopes.contains("small")
        case .systemMedium:
            return scopes.contains("medium")
        case .systemLarge:
            return scopes.contains("large")
        case .accessoryInline, .accessoryCircular, .accessoryRectangular:
            return scopes.contains("lockscreen")
        default:
            return true
        }
    }
}

private func makeWidgetConfiguration(
    kind: String,
    title: String,
    description: String,
    mode: WidgetMode,
    hideLockscreenTitle: Bool = true,
    configKeyOverride: String? = nil
) -> some WidgetConfiguration {
    StaticConfiguration(
        kind: kind,
        provider: Provider(
            mode: mode,
            title: title,
            configKeyOverride: configKeyOverride,
            hideLockscreenTitle: hideLockscreenTitle
        )
    ) { entry in
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

private func makeLockscreenConfiguration(
    kind: String,
    title: String,
    description: String,
    mode: WidgetMode,
    configKeyOverride: String? = nil
) -> some WidgetConfiguration {
    StaticConfiguration(
        kind: kind,
        provider: Provider(
            mode: mode,
            title: title,
            configKeyOverride: configKeyOverride,
            hideLockscreenTitle: true
        )
    ) { entry in
        if #available(iOSApplicationExtension 17.0, *) {
            DayMasterWidgetEntryView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        } else {
            DayMasterWidgetEntryView(entry: entry)
        }
    }
    .configurationDisplayName(title)
    .description(description)
    .supportedFamilies([
        .accessoryCircular,
        .accessoryRectangular,
        .accessoryInline,
    ])
}

struct JiosLockSelectedWidget: Widget {
    var body: some WidgetConfiguration {
        makeLockscreenConfiguration(
            kind: "DayMasterLockSelectedWidget",
            title: "锁屏选定任务",
            description: "锁屏显示手动选择任务",
            mode: .selected,
            configKeyOverride: "widget_config_lock_selected"
        )
    }
}
