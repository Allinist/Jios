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
    case roseBlush = "rose_blush"
}

private struct WidgetTask: Decodable {
    let id: Int?
    let title: String
    let taskBookId: Int?
    let color: Int?
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
        case color
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
    let logoVariant: String
}

private struct Provider: TimelineProvider {
    let mode: WidgetMode
    let title: String
    let configKeyOverride: String?
    let hideLockscreenTitle: Bool

    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(
            date: Date(),
            tasks: [],
            title: title,
            hideLockscreenTitle: hideLockscreenTitle,
            appearanceTheme: .auto,
            logoVariant: "PinkLogo"
        )
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
            appearanceTheme: loadAppearanceTheme(),
            logoVariant: loadLogoVariant()
        )
    }

    private func loadAppearanceTheme() -> WidgetAppearanceTheme {
        let raw = UserDefaults(suiteName: "group.com.example.jios")?.string(forKey: "widget_appearance_theme")
        return WidgetAppearanceTheme(rawValue: raw ?? "") ?? .auto
    }

    private func loadLogoVariant() -> String {
        let raw = UserDefaults(suiteName: "group.com.example.jios")?.string(forKey: "widget_logo_variant")
        if raw == "BlueLogo" {
            return "BlueLogo"
        }
        return "PinkLogo"
    }

    private func loadTasks() -> [WidgetTask] {
        let defaults = UserDefaults(suiteName: "group.com.example.jios")

        guard let payloadString = defaults?.string(forKey: "widget_tasks"),
              let payloadData = payloadString.data(using: .utf8),
              let payload = try? JSONDecoder().decode(WidgetPayload.self, from: payloadData) else {
            return []
        }

        let config: WidgetConfig = {
            let key = resolvedConfigKey()
            guard let configString = defaults?.string(forKey: key) ?? defaults?.string(forKey: "widget_config"),
                  let configData = configString.data(using: .utf8),
                  let decoded = try? JSONDecoder().decode(WidgetConfig.self, from: configData) else {
                return WidgetConfig(mode: "today", taskBookId: nil, taskIds: [])
            }
            return decoded
        }()

        let effectiveMode = resolvedMode(from: config)

        switch effectiveMode {
        case .book:
            if let bookId = config.taskBookId {
                return payload.tasks.filter { $0.taskBookId == bookId && !isCompleted($0) }
            }
            return payload.tasks.filter { $0.isToday && !isCompleted($0) }
        case .selected:
            let selectedIds = Set(config.taskIds)
            if selectedIds.isEmpty {
                return payload.tasks.filter { $0.isToday && !isCompleted($0) }
            }
            return payload.tasks.filter {
                guard let id = $0.id else { return false }
                return selectedIds.contains(id) && !isCompleted($0)
            }
        case .all:
            return payload.tasks.filter { !isCompleted($0) }
        case .today, .configured:
            return payload.tasks.filter { $0.isToday && !isCompleted($0) }
        }
    }

    private func resolvedConfigKey() -> String {
        if let configKeyOverride, !configKeyOverride.isEmpty {
            return configKeyOverride
        }
        switch mode {
        case .book:
            return "widget_config_book"
        case .selected:
            return "widget_config_selected"
        case .configured:
            return "widget_config_configured"
        case .today, .all:
            return "widget_config_configured"
        }
    }

    private func resolvedMode(from config: WidgetConfig) -> WidgetMode {
        guard mode == .configured else { return mode }
        switch config.mode {
        case "book":
            return .book
        case "selected":
            return .selected
        default:
            return .today
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
        let actualTheme: WidgetAppearanceTheme = theme == .auto
            ? (scheme == .dark ? .nightGraphite : .mistLight)
            : theme

        switch actualTheme {
        case .mistLight:
            return Palette(
                top: Color(red: 0.95, green: 0.97, blue: 0.99),
                bottom: Color(red: 0.87, green: 0.90, blue: 0.95),
                orb: Color(red: 0.75, green: 0.84, blue: 0.98),
                card: Color.white.opacity(0.48),
                strongCard: Color.white.opacity(0.64),
                primary: Color(red: 0.13, green: 0.17, blue: 0.24),
                secondary: Color(red: 0.33, green: 0.39, blue: 0.48),
                accent: Color(red: 0.28, green: 0.46, blue: 0.78),
                divider: Color.white.opacity(0.56)
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
        case .roseBlush:
            return Palette(
                top: Color(red: 0.99, green: 0.91, blue: 0.95),
                bottom: Color(red: 0.94, green: 0.75, blue: 0.84),
                orb: Color(red: 0.90, green: 0.47, blue: 0.67),
                card: Color.white.opacity(0.32),
                strongCard: Color.white.opacity(0.46),
                primary: Color(red: 0.32, green: 0.14, blue: 0.22),
                secondary: Color(red: 0.50, green: 0.24, blue: 0.35),
                accent: Color(red: 0.80, green: 0.28, blue: 0.51),
                divider: Color.white.opacity(0.34)
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
                .fill(palette.orb.opacity(0.28))
                .frame(width: 190, height: 190)
                .blur(radius: 20)
                .offset(x: 76, y: -52)
            LinearGradient(colors: [Color.white.opacity(0.12), .clear], startPoint: .topLeading, endPoint: .bottomTrailing)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
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

    private var visibleTasks: [DisplayTask] {
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
                standardBody
            case .enhanced:
                enhancedBody
            }
        }
        .widgetURL(URL(string: "jios://open"))
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var standardBody: some View {
        Group {
            switch family {
            case .systemSmall:
                standardList(limit: 6, columns: 1, compact: true)
            case .systemMedium:
                standardList(limit: 12, columns: 2, compact: false)
            case .systemLarge:
                standardList(limit: 24, columns: 2, compact: false)
            case .accessoryInline:
                inlineView(enhanced: false)
            case .accessoryCircular:
                circularView(enhanced: false)
            case .accessoryRectangular:
                rectangularView(enhanced: false)
            default:
                standardList(limit: 12, columns: 2, compact: false)
            }
        }
    }

    private var enhancedBody: some View {
        Group {
            switch family {
            case .systemSmall:
                enhancedSmall
            case .systemMedium:
                enhancedMedium
            case .systemLarge:
                enhancedLarge
            case .accessoryInline:
                inlineView(enhanced: true)
            case .accessoryCircular:
                circularView(enhanced: true)
            case .accessoryRectangular:
                rectangularView(enhanced: true)
            default:
                enhancedMedium
            }
        }
    }

    private func standardList(limit: Int, columns: Int, compact: Bool) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(entry.title)
                .font(compact ? .caption2 : .caption)
                .fontWeight(.semibold)

            if visibleTasks.isEmpty {
                Text("No tasks")
                    .font(.caption2)
            } else if columns == 1 {
                ForEach(visibleTasks.prefix(limit)) { item in
                    standardRow(item.task, compact: compact)
                }
            } else {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 3) {
                    ForEach(visibleTasks.prefix(limit)) { item in
                        standardRow(item.task, compact: compact)
                    }
                }
            }

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 2.5)
        .padding(.vertical, 5)
    }

    private var enhancedSmall: some View {
        ZStack {
            WidgetBackground(palette: palette)
                .scaleEffect(1.05, anchor: .center)
            VStack(alignment: .leading, spacing: 6) {
                header(compact: true)
                if visibleTasks.isEmpty {
                    emptyState
                } else {
                    enhancedTaskList(limit: 4, compact: true, radius: 13)
                }
            }
            .padding(.horizontal, 8)
            .padding(.top, 16)
            .padding(.bottom, 10)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
        .scaleEffect(0.9, anchor: .top)
        .offset(y: 15)
    }

    private var enhancedMedium: some View {
        ZStack {
            WidgetBackground(palette: palette)
                .scaleEffect(1.05, anchor: .center)
            VStack(alignment: .leading, spacing: 8) {
                header(compact: false, countOffsetX: 2)
                if visibleTasks.isEmpty {
                    emptyState
                } else {
                    enhancedTaskGrid(limit: 6, radius: 14)
                }
            }
            .padding(.horizontal, 7)
            .padding(.top, 16)
            .padding(.bottom, 10)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
        .scaleEffect(x: 1.10, y: 1.08, anchor: .top)
        .offset(y: 12)
    }

    private var enhancedLarge: some View {
        ZStack {
            WidgetBackground(palette: palette)
                .scaleEffect(1.05, anchor: .center)
            VStack(alignment: .leading, spacing: 10) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 3) {
                        HStack(spacing: 6) {
                            logoBadge(size: 18)
                            Text(entry.title)
                        }
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(palette.secondary)
                        Text(dateText)
                            .font(.title3.weight(.semibold))
                            .foregroundStyle(palette.primary)
                        Text("\(visibleTasks.count) 任务")
                            .font(.caption)
                            .foregroundStyle(palette.secondary)
                    }
                    Spacer()
                    Text("Jios")
                        .font(.caption2.weight(.bold))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Capsule().fill(palette.card))
                        .foregroundStyle(palette.primary)
                }

                if visibleTasks.isEmpty {
                    emptyState
                } else {
                    enhancedTaskList(limit: 8, compact: false, radius: 14)
                }

                Spacer(minLength: 0)
            }
            .padding(.horizontal, 7)
            .padding(.top, 16)
            .padding(.bottom, 10)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
        .scaleEffect(1.05, anchor: .center)
    }

    private func inlineView(enhanced: Bool) -> some View {
        Group {
            if let task = visibleTasks.first?.task {
                if task.widgetInfo.isEmpty {
                    Text(task.title)
                } else {
                    Text("\(task.title) \(task.widgetInfo)")
                }
            } else {
                Text("No tasks")
            }
        }
    }

    private func circularView(enhanced: Bool) -> some View {
        ZStack {
            if enhanced {
                Circle().fill(AngularGradient(colors: [palette.accent, palette.orb, palette.accent], center: .center))
                Circle().inset(by: 6).fill(palette.strongCard)
            } else {
                Circle().fill(Color.blue.opacity(0.18))
            }

            VStack(spacing: 1) {
                Text("\(visibleTasks.count)")
                    .font(.headline)
                    .foregroundStyle(enhanced ? palette.primary : Color.primary)
                Text("Items")
                    .font(.caption2)
                    .foregroundStyle(enhanced ? palette.secondary : Color.secondary)
            }
        }
    }

    private func rectangularView(enhanced: Bool) -> some View {
        ZStack {
            if enhanced {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(palette.strongCard)
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(Color.white.opacity(0.18), lineWidth: 1)
            }

            VStack(alignment: .leading, spacing: 3) {
                if !entry.hideLockscreenTitle {
                    Text(entry.title)
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(enhanced ? palette.primary : Color.primary)
                }

                if visibleTasks.isEmpty {
                    Text("No tasks")
                        .font(.caption2)
                        .foregroundStyle(enhanced ? palette.secondary : Color.secondary)
                } else {
                    ForEach(Array(visibleTasks.prefix(4).enumerated()), id: \.element.id) { index, item in
                        if enhanced {
                            enhancedRow(item.task, compact: true)
                            if index < min(visibleTasks.count, 4) - 1 {
                                Divider().overlay(palette.divider)
                            }
                        } else {
                            standardRow(item.task, compact: false)
                        }
                    }
                }
            }
            .padding(.horizontal, enhanced ? 10 : 0)
            .padding(.vertical, enhanced ? 8 : 0)
        }
    }

    private func header(compact: Bool, countOffsetX: CGFloat = 0) -> some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 1) {
                HStack(spacing: 5) {
                    if !compact {
                        logoBadge(size: 16)
                    }
                    Text(entry.title)
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(palette.primary)
                        .lineLimit(1)
                }
                .padding(.leading, compact ? 6 : 2)
                Text(dateText)
                    .font(.caption2)
                    .foregroundStyle(palette.secondary)
                    .lineLimit(1)
                    .padding(.leading, compact ? 6 : 2)
            }
            .offset(x: compact ? 2 : 1)

            Spacer()

            VStack(alignment: .leading, spacing: 0) {
                Text("\(visibleTasks.count)")
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(palette.primary)
                    .frame(width: compact ? 28 : 34, alignment: .leading)
                Text("任务")
                    .font(.caption2)
                    .foregroundStyle(palette.secondary)
                    .frame(width: compact ? 28 : 34, alignment: .leading)
            }
            .frame(maxWidth: .infinity, alignment: .trailing)
            .offset(x: (compact ? -2 : -1) + countOffsetX)
        }
    }

    private var emptyState: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("No tasks")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(palette.primary)
            Text("Nothing pending in this widget mode.")
                .font(.caption)
                .foregroundStyle(palette.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .padding(12)
        .background(card(fill: palette.card, radius: 14))
    }

    private func standardRow(_ task: WidgetTask, compact: Bool) -> some View {
        HStack(spacing: 4) {
            Text(task.title)
                .font(compact ? .system(size: 10, weight: .regular) : .caption2)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
                .frame(maxWidth: .infinity, alignment: .leading)

            if !task.widgetInfo.isEmpty {
                Text(task.widgetInfo)
                    .font(compact ? .system(size: 9, weight: .regular) : .caption2)
                    .foregroundColor(.gray)
                    .lineLimit(1)
            }
        }
    }

    private func enhancedRow(_ task: WidgetTask, compact: Bool) -> some View {
        HStack(spacing: compact ? 5 : 6) {
            Capsule()
                .fill(accentColor(for: task))
                .frame(width: compact ? 3 : 4, height: compact ? 14 : 18)

            Text(task.title)
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(palette.primary)
                .lineLimit(1)
                .frame(maxWidth: .infinity, alignment: .leading)

            if !task.widgetInfo.isEmpty {
                Text(task.widgetInfo)
                    .font(.system(size: 9, weight: .regular))
                    .foregroundStyle(palette.secondary)
                    .lineLimit(1)
            }
        }
        .padding(.vertical, compact ? 4 : 3)
    }

    private func enhancedTaskList(limit: Int, compact: Bool, radius: CGFloat) -> some View {
        VStack(spacing: 0) {
            ForEach(Array(visibleTasks.prefix(limit).enumerated()), id: \.element.id) { index, item in
                enhancedRow(item.task, compact: compact)
                if index < min(visibleTasks.count, limit) - 1 {
                    Divider().overlay(palette.divider)
                }
            }
        }
        .padding(.horizontal, compact ? 8 : 10)
        .padding(.vertical, compact ? 4 : 5)
        .background(card(fill: compact ? palette.card : palette.strongCard, radius: radius))
    }

    private func enhancedTaskGrid(limit: Int, radius: CGFloat) -> some View {
        LazyVGrid(
            columns: [
                GridItem(.flexible(), spacing: 8, alignment: .topLeading),
                GridItem(.flexible(), spacing: 8, alignment: .topLeading)
            ],
            spacing: 6
        ) {
            ForEach(visibleTasks.prefix(limit)) { item in
                enhancedGridCell(item.task, radius: radius)
            }
        }
    }

    private func enhancedGridCell(_ task: WidgetTask, radius: CGFloat) -> some View {
        HStack(spacing: 6) {
            Capsule()
                .fill(accentColor(for: task))
                .frame(width: 4, height: 16)

            Text(task.title)
                .font(.system(size: 9, weight: .medium))
                .foregroundStyle(palette.primary)
                .lineLimit(1)
                .frame(maxWidth: .infinity, alignment: .leading)

            if !task.widgetInfo.isEmpty {
                Text(task.widgetInfo)
                    .font(.system(size: 8, weight: .regular))
                    .foregroundStyle(palette.secondary)
                    .lineLimit(1)
            }
        }
        .padding(.horizontal, 9)
        .padding(.vertical, 4)
        .background(card(fill: palette.strongCard, radius: radius))
    }

    private func card(fill: Color, radius: CGFloat) -> some View {
        RoundedRectangle(cornerRadius: radius, style: .continuous)
            .fill(fill)
            .overlay(
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .stroke(Color.white.opacity(0.18), lineWidth: 1)
            )
    }

    private func logoBadge(size: CGFloat) -> some View {
        Image(entry.logoVariant)
            .resizable()
            .scaledToFit()
            .frame(width: size, height: size)
            .clipShape(RoundedRectangle(cornerRadius: size * 0.28, style: .continuous))
    }

    private func accentColor(for task: WidgetTask) -> Color {
        guard let value = task.color else {
            return palette.accent
        }
        let alpha = Double((value >> 24) & 0xff) / 255.0
        let red = Double((value >> 16) & 0xff) / 255.0
        let green = Double((value >> 8) & 0xff) / 255.0
        let blue = Double(value & 0xff) / 255.0
        return Color(.sRGB, red: red, green: green, blue: blue, opacity: alpha == 0 ? 1 : alpha)
    }

    private var dateText: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "M月d日 EEE"
        return formatter.string(from: entry.date)
    }
}

private struct WidgetConfigurationBuilder {
    static func build(
        kind: String,
        title: String,
        description: String,
        mode: WidgetMode,
        style: WidgetStyle = .standard,
        hideLockscreenTitle: Bool = true,
        configKeyOverride: String? = nil,
        families: [WidgetFamily] = [.systemSmall, .systemMedium, .systemLarge, .accessoryInline, .accessoryRectangular, .accessoryCircular]
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
                DayMasterWidgetEntryView(entry: entry, style: style)
                    .containerBackground(.clear, for: .widget)
            } else {
                DayMasterWidgetEntryView(entry: entry, style: style)
            }
        }
        .configurationDisplayName(title)
        .description(description)
        .supportedFamilies(families)
    }
}

struct JiosConfiguredWidget: Widget {
    var body: some WidgetConfiguration {
        WidgetConfigurationBuilder.build(kind: "DayMasterConfiguredWidget", title: "日程（按设置）", description: "按应用设置显示今日日程、任务本或指定任务", mode: .configured)
    }
}

struct JiosTodayWidget: Widget {
    var body: some WidgetConfiguration {
        WidgetConfigurationBuilder.build(kind: "DayMasterTodayWidget", title: "今日日程", description: "显示今日未完成日程", mode: .today)
    }
}

struct JiosTaskBookWidget: Widget {
    var body: some WidgetConfiguration {
        WidgetConfigurationBuilder.build(kind: "DayMasterTaskBookWidget", title: "任务本日程", description: "显示设置中选定任务本的未完成日程", mode: .book)
    }
}

struct JiosSelectedWidget: Widget {
    var body: some WidgetConfiguration {
        WidgetConfigurationBuilder.build(kind: "DayMasterSelectedWidget", title: "选定日程", description: "显示设置中选定的一组日程", mode: .selected)
    }
}

struct JiosAllWidget: Widget {
    var body: some WidgetConfiguration {
        WidgetConfigurationBuilder.build(kind: "DayMasterAllWidget", title: "全部待办", description: "显示全部未完成日程", mode: .all)
    }
}

struct JiosLockSelectedWidget: Widget {
    var body: some WidgetConfiguration {
        WidgetConfigurationBuilder.build(
            kind: "DayMasterLockSelectedWidget",
            title: "锁屏选定任务",
            description: "锁屏显示手动选择任务",
            mode: .selected,
            hideLockscreenTitle: true,
            configKeyOverride: "widget_config_lock_selected",
            families: [.accessoryCircular, .accessoryRectangular, .accessoryInline]
        )
    }
}

struct JiosConfiguredEnhancedWidget: Widget {
    var body: some WidgetConfiguration {
        WidgetConfigurationBuilder.build(kind: "DayMasterConfiguredEnhancedWidget", title: "日程（按设置）", description: "毛玻璃雾面渐变与杂志排版风格", mode: .configured, style: .enhanced)
    }
}

struct JiosTodayEnhancedWidget: Widget {
    var body: some WidgetConfiguration {
        WidgetConfigurationBuilder.build(kind: "DayMasterTodayEnhancedWidget", title: "今日日程", description: "毛玻璃雾面渐变风格显示今日未完成日程", mode: .today, style: .enhanced)
    }
}

struct JiosTaskBookEnhancedWidget: Widget {
    var body: some WidgetConfiguration {
        WidgetConfigurationBuilder.build(kind: "DayMasterTaskBookEnhancedWidget", title: "任务本日程", description: "毛玻璃雾面渐变风格显示任务本未完成日程", mode: .book, style: .enhanced)
    }
}

struct JiosSelectedEnhancedWidget: Widget {
    var body: some WidgetConfiguration {
        WidgetConfigurationBuilder.build(kind: "DayMasterSelectedEnhancedWidget", title: "选定日程", description: "毛玻璃雾面渐变风格显示选定任务", mode: .selected, style: .enhanced)
    }
}

struct JiosAllEnhancedWidget: Widget {
    var body: some WidgetConfiguration {
        WidgetConfigurationBuilder.build(kind: "DayMasterAllEnhancedWidget", title: "全部待办", description: "毛玻璃雾面渐变风格显示全部未完成日程", mode: .all, style: .enhanced)
    }
}

struct JiosLockSelectedEnhancedWidget: Widget {
    var body: some WidgetConfiguration {
        WidgetConfigurationBuilder.build(
            kind: "DayMasterLockSelectedEnhancedWidget",
            title: "锁屏选定任务",
            description: "锁屏毛玻璃风格显示选定任务",
            mode: .selected,
            style: .enhanced,
            hideLockscreenTitle: true,
            configKeyOverride: "widget_config_lock_selected",
            families: [.accessoryCircular, .accessoryRectangular, .accessoryInline]
        )
    }
}
