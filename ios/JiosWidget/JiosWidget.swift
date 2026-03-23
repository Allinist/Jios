import SwiftUI
import WidgetKit

private enum WidgetMode: String {
    case configured
    case today
    case book
    case selected
    case all
}

private enum WidgetStyle {
    case standard
    case enhanced
}

private enum WidgetAppearanceTheme: String {
    case auto
    case mistLight = "mist_light"
    case slateBlue = "slate_blue"
    case warmSand = "warm_sand"
    case nightGraphite = "night_graphite"
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

private struct DisplayTask: Identifiable {
    let id: String
    let task: WidgetTask
}

private struct SimpleEntry: TimelineEntry {
    let date: Date
    let tasks: [WidgetTask]
    let title: String
    let hideLockscreenTitle: Bool
    let appearanceTheme: WidgetAppearanceTheme
}

private struct Provider: TimelineProvider {
    let mode: WidgetMode
    let title: String
    let configKeyOverride: String?
    let hideLockscreenTitle: Bool

    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date(), tasks: [], title: title, hideLockscreenTitle: hideLockscreenTitle, appearanceTheme: .auto)
    }

    func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> Void) {
        completion(makeEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<SimpleEntry>) -> Void) {
        completion(Timeline(entries: [makeEntry()], policy: .after(Date().addingTimeInterval(300))))
    }

    private func makeEntry() -> SimpleEntry {
        SimpleEntry(
            date: Date(),
            tasks: loadTasks(),
            title: title,
            hideLockscreenTitle: hideLockscreenTitle,
            appearanceTheme: loadAppearanceTheme()
        )
    }

    private func loadAppearanceTheme() -> WidgetAppearanceTheme {
        let raw = UserDefaults(suiteName: "group.com.example.jios")?.string(forKey: "widget_appearance_theme")
        return WidgetAppearanceTheme(rawValue: raw ?? "") ?? .auto
    }

    private func loadTasks() -> [WidgetTask] {
        let defaults = UserDefaults(suiteName: "group.com.example.jios")

        guard let payloadString = defaults?.string(forKey: "widget_tasks"),
              let payloadData = payloadString.data(using: .utf8),
              let payload = try? JSONDecoder().decode(WidgetPayload.self, from: payloadData) else {
            return []
        }

        let configKey = configKeyOverride ?? {
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
        }()

        let config: WidgetConfig = {
            guard let configString = defaults?.string(forKey: configKey) ?? defaults?.string(forKey: "widget_config"),
                  let configData = configString.data(using: .utf8),
                  let decoded = try? JSONDecoder().decode(WidgetConfig.self, from: configData) else {
                return WidgetConfig(mode: "today", taskBookId: nil, taskIds: [])
            }
            return decoded
        }()

        let effectiveMode: WidgetMode = {
            if mode != .configured { return mode }
            switch config.mode {
            case "book":
                return .book
            case "selected":
                return .selected
            default:
                return .today
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
}

private struct Palette {
    let top: Color
    let bottom: Color
    let orb: Color
    let card: Color
    let strongCard: Color
    let primary: Color
    let secondary: Color
    let accent: Color
    let divider: Color

    static func resolve(theme: WidgetAppearanceTheme, scheme: ColorScheme) -> Palette {
        let actual: WidgetAppearanceTheme = theme == .auto ? (scheme == .dark ? .nightGraphite : .mistLight) : theme
        switch actual {
        case .mistLight:
            return Palette(
                top: Color(red: 0.95, green: 0.97, blue: 0.99),
                bottom: Color(red: 0.87, green: 0.90, blue: 0.95),
                orb: Color(red: 0.75, green: 0.84, blue: 0.98),
                card: Color.white.opacity(0.46),
                strongCard: Color.white.opacity(0.62),
                primary: Color(red: 0.13, green: 0.17, blue: 0.24),
                secondary: Color(red: 0.34, green: 0.39, blue: 0.48),
                accent: Color(red: 0.28, green: 0.46, blue: 0.78),
                divider: Color.white.opacity(0.54)
            )
        case .slateBlue:
            return Palette(
                top: Color(red: 0.80, green: 0.86, blue: 0.96),
                bottom: Color(red: 0.60, green: 0.69, blue: 0.86),
                orb: Color(red: 0.33, green: 0.47, blue: 0.79),
                card: Color.white.opacity(0.28),
                strongCard: Color.white.opacity(0.40),
                primary: Color(red: 0.10, green: 0.14, blue: 0.21),
                secondary: Color(red: 0.23, green: 0.28, blue: 0.40),
                accent: Color(red: 0.18, green: 0.34, blue: 0.68),
                divider: Color.white.opacity(0.30)
            )
        case .warmSand:
            return Palette(
                top: Color(red: 0.97, green: 0.93, blue: 0.88),
                bottom: Color(red: 0.88, green: 0.81, blue: 0.74),
                orb: Color(red: 0.90, green: 0.73, blue: 0.54),
                card: Color.white.opacity(0.30),
                strongCard: Color.white.opacity(0.42),
                primary: Color(red: 0.23, green: 0.18, blue: 0.14),
                secondary: Color(red: 0.40, green: 0.31, blue: 0.23),
                accent: Color(red: 0.67, green: 0.41, blue: 0.22),
                divider: Color.white.opacity(0.30)
            )
        case .nightGraphite, .auto:
            return Palette(
                top: Color(red: 0.17, green: 0.20, blue: 0.25),
                bottom: Color(red: 0.09, green: 0.11, blue: 0.15),
                orb: Color(red: 0.39, green: 0.50, blue: 0.74),
                card: Color.white.opacity(0.11),
                strongCard: Color.white.opacity(0.16),
                primary: Color.white.opacity(0.95),
                secondary: Color.white.opacity(0.72),
                accent: Color(red: 0.63, green: 0.77, blue: 0.96),
                divider: Color.white.opacity(0.14)
            )
        }
    }
}

private struct WidgetBackground: View {
    let palette: Palette

    var body: some View {
        ZStack {
            LinearGradient(colors: [palette.top, palette.bottom], startPoint: .topLeading, endPoint: .bottomTrailing)
            Circle()
                .fill(palette.orb.opacity(0.26))
                .frame(width: 180, height: 180)
                .blur(radius: 18)
                .offset(x: 70, y: -50)
            LinearGradient(colors: [Color.white.opacity(0.12), .clear], startPoint: .topLeading, endPoint: .bottomTrailing)
        }
    }
}

private struct DayMasterWidgetEntryView: View {
    @Environment(\.widgetFamily) private var family
    @Environment(\.colorScheme) private var colorScheme

    let entry: SimpleEntry
    let style: WidgetStyle

    private var palette: Palette {
        Palette.resolve(theme: entry.appearanceTheme, scheme: colorScheme)
    }

    private var tasks: [DisplayTask] {
        let filtered = entry.tasks.filter { task in
            let scopes = task.widgetScopes
            if scopes.isEmpty { return true }
            switch family {
            case .systemSmall: return scopes.contains("small")
            case .systemMedium: return scopes.contains("medium")
            case .systemLarge: return scopes.contains("large")
            case .accessoryInline, .accessoryCircular, .accessoryRectangular: return scopes.contains("lockscreen")
            default: return true
            }
        }
        return Array(filtered.prefix(30).enumerated()).map { index, task in
            DisplayTask(id: "\(task.id ?? -1)-\(index)", task: task)
        }
    }

    var body: some View {
        Group {
            switch style {
            case .standard:
                standardView
            case .enhanced:
                enhancedView
            }
        }
        .widgetURL(URL(string: "jios://open"))
    }

    private var standardView: some View {
        Group {
            switch family {
            case .systemSmall:
                listContainer(limit: 6, columns: 1, enhanced: false)
            case .systemMedium:
                listContainer(limit: 12, columns: 2, enhanced: false)
            case .systemLarge:
                listContainer(limit: 24, columns: 2, enhanced: false)
            case .accessoryInline:
                inlineView(enhanced: false)
            case .accessoryCircular:
                circularView(enhanced: false)
            case .accessoryRectangular:
                rectangularView(enhanced: false)
            default:
                listContainer(limit: 12, columns: 2, enhanced: false)
            }
        }
    }

    private var enhancedView: some View {
        Group {
            switch family {
            case .systemSmall:
                frostedSmall
            case .systemMedium:
                frostedMedium
            case .systemLarge:
                editorialLarge
            case .accessoryInline:
                inlineView(enhanced: true)
            case .accessoryCircular:
                circularView(enhanced: true)
            case .accessoryRectangular:
                rectangularView(enhanced: true)
            default:
                frostedMedium
            }
        }
    }

    private func listContainer(limit: Int, columns: Int, enhanced: Bool) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(entry.title)
                .font(.caption)
                .fontWeight(.semibold)
            if tasks.isEmpty {
                Text("暂无任务").font(.caption2)
            } else if columns == 1 {
                ForEach(tasks.prefix(limit)) { item in
                    row(item.task, enhanced: enhanced, compact: true)
                }
            } else {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 2) {
                    ForEach(tasks.prefix(limit)) { item in
                        row(item.task, enhanced: enhanced, compact: true)
                    }
                }
            }
            Spacer(minLength: 0)
        }
        .padding(4)
    }

    private var frostedSmall: some View {
        ZStack {
            WidgetBackground(palette: palette)
            VStack(alignment: .leading, spacing: 8) {
                header(compact: true)
                if tasks.isEmpty {
                    emptyCard
                } else {
                    VStack(spacing: 0) {
                        ForEach(Array(tasks.prefix(7).enumerated()), id: \.element.id) { index, item in
                            row(item.task, enhanced: true, compact: true)
                            if index < min(tasks.count, 7) - 1 {
                                Divider().overlay(palette.divider)
                            }
                        }
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(card(fill: palette.card))
                }
            }
            .padding(12)
        }
    }

    private var frostedMedium: some View {
        ZStack {
            WidgetBackground(palette: palette)
            VStack(alignment: .leading, spacing: 10) {
                header(compact: false)
                if tasks.isEmpty {
                    emptyCard
                } else {
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                        ForEach(tasks.prefix(10)) { item in
                            taskCard(item.task)
                        }
                    }
                }
            }
            .padding(14)
        }
    }

    private var editorialLarge: some View {
        let lead = Array(tasks.prefix(4))
        let queue = Array(tasks.dropFirst(4).prefix(10))
        return ZStack {
            WidgetBackground(palette: palette)
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(entry.title.uppercased())
                            .font(.caption2.weight(.bold))
                            .tracking(1.4)
                            .foregroundStyle(palette.secondary)
                        Text(dateText)
                            .font(.title3.weight(.semibold))
                            .foregroundStyle(palette.primary)
                        Text("\(tasks.count) tasks")
                            .font(.caption)
                            .foregroundStyle(palette.secondary)
                    }
                    Spacer()
                    Text("JIOS")
                        .font(.caption2.weight(.bold))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Capsule().fill(palette.card))
                        .foregroundStyle(palette.primary)
                }

                sectionTitle("Focus")
                if lead.isEmpty {
                    emptyCard
                } else {
                    VStack(spacing: 8) {
                        ForEach(lead) { item in
                            HStack(alignment: .top, spacing: 10) {
                                Capsule().fill(palette.accent).frame(width: 4, height: 26)
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(item.task.title)
                                        .font(.subheadline.weight(.semibold))
                                        .foregroundStyle(palette.primary)
                                        .lineLimit(1)
                                    Text(subtitle(for: item.task))
                                        .font(.caption)
                                        .foregroundStyle(palette.secondary)
                                        .lineLimit(1)
                                }
                                Spacer()
                            }
                            .padding(10)
                            .background(card(fill: palette.strongCard))
                        }
                    }
                }

                if !queue.isEmpty {
                    sectionTitle("Queue")
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                        ForEach(queue) { item in
                            taskCard(item.task)
                        }
                    }
                }
                Spacer(minLength: 0)
            }
            .padding(16)
        }
    }

    private func inlineView(enhanced: Bool) -> some View {
        Group {
            if let task = tasks.first?.task {
                Text(task.widgetInfo.isEmpty ? task.title : "\(task.title) \(task.widgetInfo)")
            } else {
                Text("暂无任务")
            }
        }
    }

    private func circularView(enhanced: Bool) -> some View {
        ZStack {
            if enhanced {
                Circle().fill(AngularGradient(colors: [palette.accent, palette.orb, palette.accent], center: .center))
            } else {
                Circle().fill(Color.blue.opacity(0.18))
            }
            if enhanced {
                Circle().inset(by: 6).fill(palette.strongCard)
            }
            VStack(spacing: 2) {
                Text("\(tasks.count)").font(.headline).foregroundStyle(enhanced ? palette.primary : Color.primary)
                Text("项").font(.caption2).foregroundStyle(enhanced ? palette.secondary : Color.secondary)
            }
        }
    }

    private func rectangularView(enhanced: Bool) -> some View {
        ZStack {
            if enhanced {
                RoundedRectangle(cornerRadius: 18, style: .continuous).fill(palette.strongCard)
                RoundedRectangle(cornerRadius: 18, style: .continuous).stroke(Color.white.opacity(0.18), lineWidth: 1)
            }
            VStack(alignment: .leading, spacing: 3) {
                if !entry.hideLockscreenTitle {
                    Text(entry.title)
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(enhanced ? palette.primary : Color.primary)
                }
                if tasks.isEmpty {
                    Text("暂无任务")
                        .font(.caption2)
                        .foregroundStyle(enhanced ? palette.secondary : Color.secondary)
                } else {
                    ForEach(Array(tasks.prefix(4).enumerated()), id: \.element.id) { index, item in
                        row(item.task, enhanced: enhanced, compact: true)
                        if index < min(tasks.count, 4) - 1 {
                            Divider().overlay(enhanced ? palette.divider : Color.gray.opacity(0.2))
                        }
                    }
                }
            }
            .padding(.horizontal, enhanced ? 10 : 0)
            .padding(.vertical, enhanced ? 8 : 0)
        }
    }

    private func header(compact: Bool) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(entry.title)
                    .font(compact ? .caption.weight(.bold) : .caption.weight(.semibold))
                    .foregroundStyle(palette.primary)
                Text(dateText)
                    .font(.caption2)
                    .foregroundStyle(palette.secondary)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 1) {
                Text("\(tasks.count)")
                    .font(compact ? .title3.weight(.semibold) : .title2.weight(.semibold))
                    .foregroundStyle(palette.primary)
                Text("tasks")
                    .font(.caption2)
                    .foregroundStyle(palette.secondary)
            }
        }
    }

    private var emptyCard: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("暂无任务")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(palette.primary)
            Text("当前模式下没有未完成事项")
                .font(.caption)
                .foregroundStyle(palette.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .padding(12)
        .background(card(fill: palette.card))
    }

    private func taskCard(_ task: WidgetTask) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Capsule().fill(palette.accent).frame(width: 4, height: 18)
                Text(task.title)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(palette.primary)
                    .lineLimit(1)
                Spacer(minLength: 0)
            }
            Text(subtitle(for: task))
                .font(.caption2)
                .foregroundStyle(palette.secondary)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(card(fill: palette.strongCard))
    }

    private func row(_ task: WidgetTask, enhanced: Bool, compact: Bool) -> some View {
        HStack(spacing: 6) {
            if enhanced {
                Capsule().fill(palette.accent).frame(width: compact ? 3 : 4, height: compact ? 15 : 18)
            }
            Text(task.title)
                .font(compact ? .caption2.weight(.medium) : .caption.weight(.medium))
                .foregroundStyle(enhanced ? palette.primary : Color.primary)
                .lineLimit(1)
                .frame(maxWidth: .infinity, alignment: .leading)
            if !task.widgetInfo.isEmpty {
                Text(task.widgetInfo)
                    .font(.caption2)
                    .foregroundStyle(enhanced ? palette.secondary : Color.gray)
                    .lineLimit(1)
            }
        }
        .padding(.vertical, enhanced ? 5 : 0)
    }

    private func subtitle(for task: WidgetTask) -> String {
        if !task.widgetInfo.isEmpty { return task.widgetInfo }
        if let first = task.timelineLines.first, !first.isEmpty { return first }
        return "待处理"
    }

    private func sectionTitle(_ title: String) -> some View {
        HStack(spacing: 8) {
            Text(title.uppercased())
                .font(.caption2.weight(.bold))
                .tracking(1.2)
                .foregroundStyle(palette.secondary)
            Rectangle().fill(palette.divider).frame(height: 1)
        }
    }

    private func card(fill: Color) -> some View {
        RoundedRectangle(cornerRadius: 14, style: .continuous)
            .fill(fill)
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(Color.white.opacity(0.18), lineWidth: 1)
            )
    }

    private var dateText: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "M月d日 EEEE"
        return formatter.string(from: entry.date)
    }
}

private func makeWidgetConfiguration(
    kind: String,
    title: String,
    description: String,
    mode: WidgetMode,
    style: WidgetStyle = .standard,
    hideLockscreenTitle: Bool = true,
    configKeyOverride: String? = nil
) -> some WidgetConfiguration {
    StaticConfiguration(
        kind: kind,
        provider: Provider(mode: mode, title: title, configKeyOverride: configKeyOverride, hideLockscreenTitle: hideLockscreenTitle)
    ) { entry in
        if #available(iOSApplicationExtension 17.0, *) {
            DayMasterWidgetEntryView(entry: entry, style: style)
                .containerBackground(.clear, for: .widget)
        } else {
            DayMasterWidgetEntryView(entry: entry, style: style)
        }
    }
    .configurationDisplayName(title)
    .description(description)
    .supportedFamilies([.systemSmall, .systemMedium, .systemLarge, .accessoryInline, .accessoryRectangular, .accessoryCircular])
}

struct JiosConfiguredWidget: Widget {
    var body: some WidgetConfiguration {
        makeWidgetConfiguration(kind: "DayMasterConfiguredWidget", title: "日程（按设置）", description: "按应用设置显示今日日程、任务本或指定任务", mode: .configured)
    }
}

struct JiosTodayWidget: Widget {
    var body: some WidgetConfiguration {
        makeWidgetConfiguration(kind: "DayMasterTodayWidget", title: "今日日程", description: "显示今日未完成日程", mode: .today)
    }
}

struct JiosTaskBookWidget: Widget {
    var body: some WidgetConfiguration {
        makeWidgetConfiguration(kind: "DayMasterTaskBookWidget", title: "任务本日程", description: "显示设置中选定任务本的未完成日程", mode: .book)
    }
}

struct JiosSelectedWidget: Widget {
    var body: some WidgetConfiguration {
        makeWidgetConfiguration(kind: "DayMasterSelectedWidget", title: "选定日程", description: "显示设置中选定的一组日程", mode: .selected)
    }
}

struct JiosAllWidget: Widget {
    var body: some WidgetConfiguration {
        makeWidgetConfiguration(kind: "DayMasterAllWidget", title: "全部待办", description: "显示全部未完成日程", mode: .all)
    }
}

struct JiosLockSelectedWidget: Widget {
    var body: some WidgetConfiguration {
        makeWidgetConfiguration(
            kind: "DayMasterLockSelectedWidget",
            title: "锁屏选定任务",
            description: "锁屏显示手动选择任务",
            mode: .selected,
            hideLockscreenTitle: true,
            configKeyOverride: "widget_config_lock_selected"
        )
        .supportedFamilies([.accessoryCircular, .accessoryRectangular, .accessoryInline])
    }
}

struct JiosConfiguredEnhancedWidget: Widget {
    var body: some WidgetConfiguration {
        makeWidgetConfiguration(kind: "DayMasterConfiguredEnhancedWidget", title: "日程美化版（按设置）", description: "新增毛玻璃雾面渐变与杂志排版风格", mode: .configured, style: .enhanced)
    }
}

struct JiosTodayEnhancedWidget: Widget {
    var body: some WidgetConfiguration {
        makeWidgetConfiguration(kind: "DayMasterTodayEnhancedWidget", title: "今日日程美化版", description: "以雾面渐变风格显示今日未完成日程", mode: .today, style: .enhanced)
    }
}

struct JiosTaskBookEnhancedWidget: Widget {
    var body: some WidgetConfiguration {
        makeWidgetConfiguration(kind: "DayMasterTaskBookEnhancedWidget", title: "任务本日程美化版", description: "以雾面渐变风格显示任务本未完成日程", mode: .book, style: .enhanced)
    }
}

struct JiosSelectedEnhancedWidget: Widget {
    var body: some WidgetConfiguration {
        makeWidgetConfiguration(kind: "DayMasterSelectedEnhancedWidget", title: "选定日程美化版", description: "以雾面渐变风格显示选定任务", mode: .selected, style: .enhanced)
    }
}

struct JiosAllEnhancedWidget: Widget {
    var body: some WidgetConfiguration {
        makeWidgetConfiguration(kind: "DayMasterAllEnhancedWidget", title: "全部待办美化版", description: "以雾面渐变风格显示全部未完成日程", mode: .all, style: .enhanced)
    }
}

struct JiosLockSelectedEnhancedWidget: Widget {
    var body: some WidgetConfiguration {
        makeWidgetConfiguration(
            kind: "DayMasterLockSelectedEnhancedWidget",
            title: "锁屏选定任务美化版",
            description: "锁屏以毛玻璃风格显示选定任务",
            mode: .selected,
            style: .enhanced,
            hideLockscreenTitle: true,
            configKeyOverride: "widget_config_lock_selected"
        )
        .supportedFamilies([.accessoryCircular, .accessoryRectangular, .accessoryInline])
    }
}
