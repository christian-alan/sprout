import Foundation
import Observation
import SwiftUI

enum MascotCharacter: String, Codable, CaseIterable, Sendable {
    case sprout, bloom, pop, dash, clover, tile, keys, rover, new

    var displayName: String { rawValue.capitalized }

    var palette: CharacterPalette {
        switch self {
        case .sprout: .init(body: "9FC8F3", accent: "3F86D8", tint: "E6F1FD", mid: "CFE3FA")
        case .bloom: .init(body: "C3B2F8", accent: "7D5CE6", tint: "EFEAFF", mid: "DDD3FC")
        case .pop: .init(body: "FFADC9", accent: "E0538C", tint: "FFE8F1", mid: "FFD3E3")
        case .dash: .init(body: "8FDACE", accent: "1F9A8C", tint: "DDF5F1", mid: "C3ECE6")
        case .clover: .init(body: "B3DF8F", accent: "5C9E35", tint: "EBF6E0", mid: "D6EEC2")
        case .tile: .init(body: "FFBF94", accent: "E27A3C", tint: "FFF0E4", mid: "FFDCC4")
        case .keys: .init(body: "F8D77A", accent: "C78A12", tint: "FFF6DC", mid: "FCEBB6")
        case .rover: .init(body: "FFA597", accent: "E05A49", tint: "FFEBE7", mid: "FFD2CA")
        case .new: .init(body: "FFFFFF", accent: "1B1A19", tint: "F4EEE6", mid: "EDE4D8")
        }
    }
}

struct CharacterPalette: Sendable {
    let bodyHex: String
    let accentHex: String
    let tintHex: String
    let midHex: String

    init(body: String, accent: String, tint: String, mid: String) {
        bodyHex = body
        accentHex = accent
        tintHex = tint
        midHex = mid
    }

    var body: Color { Color(hex: bodyHex) }
    var accent: Color { Color(hex: accentHex) }
    var tint: Color { Color(hex: tintHex) }
    var mid: Color { Color(hex: midHex) }
}

enum TaskStatus: String, Codable, CaseIterable, Sendable {
    case working, needs, ready, scheduled, done

    var mood: Mood {
        switch self {
        case .working: .working
        case .needs: .needs
        case .ready: .ready
        case .scheduled, .done: .asleep
        }
    }

    var label: String {
        switch self {
        case .working: "Working"
        case .needs: "Needs you"
        case .ready: "Ready"
        case .scheduled: "Scheduled"
        case .done: "Done"
        }
    }

    var sortRank: Int {
        switch self {
        case .needs: 0
        case .ready: 1
        case .working: 2
        case .scheduled: 3
        case .done: 4
        }
    }
}

enum Mood: String, CaseIterable, Sendable {
    case idle, working, needs, ready, asleep
}

struct ResultField: Codable, Hashable, Sendable {
    var label: String
    var value: String
}

struct Choice: Codable, Hashable, Identifiable, Sendable {
    var id: String
    var name: String
    var detail: String
    var tag: String
    var price: String
    var topHex: String
    var baseHex: String
    var backgroundHex: String
}

enum TaskQuestion: Codable, Hashable, Sendable {
    case options(prompt: String, note: String, primary: String, secondary: String, tertiary: String?)
    case pickOne(prompt: String, note: String, choices: [Choice])
}

struct AgentTask: Identifiable, Codable, Hashable, Sendable {
    var id: String
    var title: String
    var character: MascotCharacter
    var status: TaskStatus
    var createdAt: Date
    var timeLabel: String
    var line: String
    var summary: String? = nil
    var answerGiven: String? = nil
    var progress: Double
    var steps: [String]
    var stepIndex: Int
    var question: TaskQuestion? = nil
    var resultLabel: String? = nil
    var fields: [ResultField]
    var actionLabel: String? = nil
    var afterNote: String? = nil
    var doneLine: String? = nil
    var doneMessage: String? = nil
    var repeatLabel: String? = nil
    var repeatPrompt: String? = nil
    var category: String? = nil
    var isArchived: Bool
    var month: String? = nil
    var dateLabel: String? = nil
}

enum MessageRole: String, Codable, Sendable { case user, assistant, separator }

struct MessageAction: Codable, Hashable, Sendable {
    enum Kind: String, Codable, Sendable { case answer, confirm, openHistory }
    var kind: Kind
    var taskID: String?
    var expectedStatus: TaskStatus?
    var label: String
    var historyQuery: String?
}

struct Message: Identifiable, Codable, Hashable, Sendable {
    var id = UUID()
    var role: MessageRole
    var text: String
    var taskIDs: [String] = []
    var action: MessageAction?
}

enum AssistantEvent: Sendable {
    case typing(Bool)
    case message(Message)
    case taskCreated(AgentTask)
    case taskUpdated(AgentTask)
    case taskRemoved(String)
}

struct AssistantContext: Sendable {
    var tasks: [String: AgentTask]
    var history: [AgentTask]
    var cakeChoices: [Choice]
    var genericCharacter: MascotCharacter
}

@MainActor
protocol AssistantService {
    func handle(_ text: String, context: AssistantContext) -> AsyncStream<AssistantEvent>
    func answer(task: AgentTask, with choice: String, context: AssistantContext) -> AsyncStream<AssistantEvent>
    func confirm(task: AgentTask) -> AsyncStream<AssistantEvent>
    func stop(task: AgentTask) -> AsyncStream<AssistantEvent>
}

enum AppMode: Sendable, Equatable { case chat, tasks, history }

enum Theme {
    static let ink = Color(hex: "1B1A19")
    static let inkSecondary = Color(hex: "4F4942")
    static let textMuted = Color(hex: "7A736B")
    static let textFaint = Color(hex: "9A938B")
    static let paper = Color(hex: "FAF6F1")
    static let paperTop = Color(hex: "F6EFE6")
    static let stage = Color(hex: "F4EEE6")
    static let sheetGround = Color(hex: "FFFCF8")
    static let destructive = Color(hex: "C2412D")
    static let ready = Color(hex: "34A865")
    static let hairline = Color.black.opacity(0.07)

    enum Radius {
        static let taskCard: CGFloat = 40
        static let sheet: CGFloat = 46
        static let platter: CGFloat = 28
        static let glassPanel: CGFloat = 30
        static let messageCard: CGFloat = 22
        static let bubble: CGFloat = 20
        static let taskRow: CGFloat = 17
        static let headTile: CGFloat = 13
    }

    enum Space {
        static let gutter: CGFloat = 16
        static let stack: CGFloat = 8
        static let group: CGFloat = 14
        static let section: CGFloat = 24
    }

    enum Size {
        static let minTouchTarget: CGFloat = 44
        static let taskCardWidth: CGFloat = 310
        static let taskCardHeight: CGFloat = 450
        static let taskCardSpacing: CGFloat = 12
        static let mascotOnCard: CGFloat = 200
        static let mascotInSheet: CGFloat = 96
        static let mascotHeader: CGFloat = 54
        static let composerHeight: CGFloat = 46
        static let primaryButtonHeight: CGFloat = 50
        static let sheetPrimaryButtonHeight: CGFloat = 56
        static let compactControlHeight: CGFloat = 34
        static let statusPillHeight: CGFloat = 30
        static let historyRowHeight: CGFloat = 64
        static let historyHeadTile: CGFloat = 40
    }

    enum Motion {
        static let messageDuration = 0.3
        static let taskBornDuration = 0.9
        static let taskBornScale = 0.8
        static let taskBornBlur: CGFloat = 8
        static let stripPulseDuration = 0.35
        static let stripPulseScale = 1.08
    }
}

extension Color {
    init(hex: String) {
        let clean = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var value: UInt64 = 0
        Scanner(string: clean).scanHexInt64(&value)
        let red = Double((value >> 16) & 0xff) / 255
        let green = Double((value >> 8) & 0xff) / 255
        let blue = Double(value & 0xff) / 255
        self.init(.sRGB, red: red, green: green, blue: blue, opacity: 1)
    }
}

@MainActor
@Observable
final class AppModel {
    var messages: [Message] = []
    var tasks: [String: AgentTask] = [:]
    var order: [String] = []
    var mode: AppMode = .chat
    var openTaskID: String?
    var openTaskSource: AppMode?
    var bornTaskID: String?
    var historyQuery = ""
    var historyMonth: String?
    var isTyping = false
    var composerText = ""
    var newTaskText = ""
    var isCreatingTask = false
    var selectedTaskID: String?
    var needsFeedbackToken = 0
    var successFeedbackToken = 0

    private(set) var cakeChoices: [Choice] = []
    private var historyItems: [AgentTask] = []
    private let assistant: any AssistantService
    private var genericIndex = 0
    private var didStart = false

    init(assistant: any AssistantService = ScriptedAssistant()) {
        self.assistant = assistant
        loadSeed()
    }

    var activeTasks: [AgentTask] {
        order.compactMap { tasks[$0] }
            .filter { !$0.isArchived && $0.status != .done }
            .sorted {
                if $0.status.sortRank == $1.status.sortRank {
                    return order.firstIndex(of: $0.id) ?? 0 < order.firstIndex(of: $1.id) ?? 0
                }
                return $0.status.sortRank < $1.status.sortRank
            }
    }

    var archivedTasks: [AgentTask] { historyItems }
    var openTask: AgentTask? {
        guard let id = openTaskID else { return nil }
        if openTaskSource == .history,
           let archived = historyItems.first(where: { $0.id == id }) {
            return archived
        }
        return tasks[id] ?? historyItems.first(where: { $0.id == id })
    }

    var assistantMood: Mood {
        if isTyping { return .working }
        if activeTasks.contains(where: { $0.status == .needs }) { return .needs }
        return .idle
    }

    var taskSubtitle: String {
        let open = activeTasks.filter { $0.status != .done }.count
        let needs = activeTasks.filter { $0.status == .needs }.count
        let ready = activeTasks.filter { $0.status == .ready }.count
        if needs > 0 { return "\(open) open · \(needs) needs you" }
        return "\(open) open · \(ready) ready"
    }

    var filteredHistory: [AgentTask] {
        historyItems.filter { task in
            let monthMatches = historyMonth == nil || task.month == historyMonth
            let query = historyQuery.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            let queryMatches = query.isEmpty || [task.title, task.line, task.category ?? ""]
                .joined(separator: " ").lowercased().contains(query)
            return monthMatches && queryMatches
        }
    }

    var historyGroups: [(String, [AgentTask])] {
        let order = ["October", "September", "August", "July", "June", "May"]
        return order.compactMap { month in
            let items = filteredHistory.filter { $0.month == month }
            return items.isEmpty ? nil : (month, items)
        }
    }

    func start() {
        guard !didStart else { return }
        didStart = true
        Task {
            try? await Task.sleep(for: .seconds(12))
            guard var train = tasks["train"], train.status == .working else { return }
            train.status = .ready
            train.progress = 1
            train.stepIndex = 2
            train.line = "17:22 from Stockholm C, arrives 18:01."
            tasks[train.id] = train
            messages.append(.init(role: .assistant, text: "Found your train: 17:22 from Stockholm C, arriving 18:01. Want me to buy the ticket?", action: .init(kind: .confirm, taskID: train.id, expectedStatus: .ready, label: "Buy ticket · 98 kr")))
            pulse(taskID: train.id)
        }
    }

    func reset() {
        messages.removeAll()
        tasks.removeAll()
        order.removeAll()
        historyItems.removeAll()
        mode = .chat
        openTaskID = nil
        openTaskSource = nil
        historyQuery = ""
        historyMonth = nil
        isTyping = false
        didStart = false
        loadSeed()
        start()
    }

    func send(_ rawText: String) {
        let text = rawText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        composerText = ""
        newTaskText = ""
        messages.append(.init(role: .user, text: text))
        let context = context()
        Task { await consume(assistant.handle(text, context: context)) }
    }

    func sendFromSlider(_ text: String) {
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        isCreatingTask = true
        send(text)
    }

    func answer(_ task: AgentTask, choice: String) {
        let returnToTasks = openTaskSource == .tasks
        messages.append(.init(role: .user, text: choice))
        openTaskID = nil
        openTaskSource = nil
        if returnToTasks { mode = .tasks }
        Task { await consume(assistant.answer(task: task, with: choice, context: context())) }
    }

    func confirm(_ task: AgentTask) {
        Task { await consume(assistant.confirm(task: task)) }
    }

    func stop(_ task: AgentTask) {
        openTaskID = nil
        Task { await consume(assistant.stop(task: task)) }
    }

    func repeatTask(_ task: AgentTask) {
        guard let prompt = task.repeatPrompt else { return }
        openTaskID = nil
        openTaskSource = nil
        mode = .chat
        send(prompt)
    }

    func showTask(_ id: String) {
        openTaskSource = mode
        openTaskID = id
    }

    func task(_ id: String) -> AgentTask? {
        tasks[id] ?? historyItems.first(where: { $0.id == id })
    }

    func perform(_ action: MessageAction) {
        if action.kind == .openHistory {
            historyQuery = action.historyQuery ?? ""
            mode = .history
        } else if let id = action.taskID { openTaskID = id }
    }

    func askAboutEmptyHistory() {
        let query = historyQuery
        mode = .chat
        composerText = "When did I last \(query)?"
    }

    private func context() -> AssistantContext {
        let cycle: [MascotCharacter] = [.keys, .rover, .dash, .pop]
        let character = cycle[genericIndex % cycle.count]
        genericIndex += 1
        return .init(tasks: tasks, history: historyItems, cakeChoices: cakeChoices, genericCharacter: character)
    }

    private func consume(_ stream: AsyncStream<AssistantEvent>) async {
        for await event in stream { apply(event) }
    }

    private func apply(_ event: AssistantEvent) {
        switch event {
        case .typing(let value): isTyping = value
        case .message(let message):
            messages.append(message)
        case .taskCreated(let task):
            withAnimation(.spring(duration: 0.9, bounce: 0.3)) {
                tasks[task.id] = task
                if !order.contains(task.id) { order.append(task.id) }
            }
            isCreatingTask = false
            pulse(taskID: task.id)
        case .taskUpdated(let task):
            let previousStatus = tasks[task.id]?.status
            tasks[task.id] = task
            if task.status == .needs, previousStatus != .needs { needsFeedbackToken += 1 }
            if task.status == .done, previousStatus != .done {
                successFeedbackToken += 1
                archiveCompletedTask(task)
            }
            if task.status == .needs || task.status == .ready { pulse(taskID: task.id) }
        case .taskRemoved(let id):
            withAnimation(.easeOut(duration: 0.25)) {
                tasks[id] = nil
                order.removeAll { $0 == id }
            }
        }
    }

    private func pulse(taskID: String) {
        bornTaskID = taskID
        Task {
            try? await Task.sleep(for: .seconds(1.6))
            if bornTaskID == taskID { bornTaskID = nil }
        }
    }

    private func archiveCompletedTask(_ task: AgentTask) {
        let now = Date()
        let locale = Locale(identifier: "en_US_POSIX")
        var archived = task
        archived.isArchived = true
        archived.month = now.formatted(.dateTime.month(.wide).locale(locale))
        archived.dateLabel = now.formatted(.dateTime.month(.abbreviated).day().locale(locale))
        archived.repeatLabel = task.repeatLabel ?? "Do it again"
        archived.repeatPrompt = task.repeatPrompt ?? task.title
        historyItems.removeAll { $0.id == task.id }
        historyItems.insert(archived, at: 0)
    }

    private func loadSeed() {
        guard let url = Bundle.main.url(forResource: "SampleData", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let seed = try? JSONDecoder().decode(SeedData.self, from: data) else {
            loadFallback()
            return
        }

        cakeChoices = seed.cakeOptions.enumerated().map { index, item in
            Choice(id: "cake-\(index)", name: item.name, detail: "\(item.bakery) · serves \(item.serves)", tag: item.tag, price: item.price, topHex: item.illustration.topLayer, baseHex: item.illustration.baseLayer, backgroundHex: item.illustration.tileBackground)
        }

        for item in seed.activeTasks {
            let task = item.task
            tasks[task.id] = task
            order.append(task.id)
        }

        historyItems = seed.history.map(\.task)

        for item in seed.initialMessages {
            if let separator = item.sep {
                messages.append(.init(role: .separator, text: separator))
            } else {
                let action = item.action.map { MessageAction(kind: .confirm, taskID: $0.task, expectedStatus: TaskStatus(rawValue: $0.status), label: $0.label) }
                messages.append(.init(role: item.f == "u" ? .user : .assistant, text: item.t ?? "", taskIDs: item.cards ?? [], action: action))
            }
        }
    }

    private func loadFallback() {
        let dinner = AgentTask(id: "dinner", title: "Saturday dinner", character: .pop, status: .ready, createdAt: .now, timeLabel: "yesterday 21:40", line: "Bistro Linnea, Sat 19:30, table for four.", summary: "Sat 19:30 · table for 4", progress: 1, steps: ["Checked 8 places on Södermalm", "Found a table for four", "Confirm the booking"], stepIndex: 2, resultLabel: "Reservation", fields: [.init(label: "Where", value: "Bistro Linnea, Södermalm"), .init(label: "When", value: "Saturday 19:30"), .init(label: "Guests", value: "4")], actionLabel: "Confirm", afterNote: "I'll add it to your calendar.", doneLine: "Booked for Saturday at 19:30.", doneMessage: "Booked Bistro Linnea for Saturday at 19:30. It's in your calendar.", isArchived: false)
        tasks[dinner.id] = dinner
        order = [dinner.id]
        messages = [.init(role: .assistant, text: "Good morning! Your Saturday table is ready to confirm.", action: .init(kind: .confirm, taskID: dinner.id, expectedStatus: .ready, label: "Confirm"))]
    }
}

private struct SeedData: Decodable {
    var activeTasks: [ActiveTaskSeed]
    var initialMessages: [SeedMessage]
    var cakeOptions: [CakeSeed]
    var history: [HistorySeed]
}

private struct ActiveTaskSeed: Decodable {
    var id: String
    var title: String
    var status: TaskStatus
    var time: String
    var line: String
    var pct: Double
    var summary: String?
    var result: String?
    var resultLabel: String?
    var fields: [ResultField]
    var afterNote: String?
    var actionLabel: String?
    var doneLine: String?
    var doneMsg: String?
    var steps: [String]
    var idx: Int
    var character: MascotCharacter

    var task: AgentTask {
        AgentTask(id: id, title: title, character: character, status: status, createdAt: .now, timeLabel: time, line: result ?? line, summary: summary, progress: pct / 100, steps: steps, stepIndex: idx, resultLabel: resultLabel, fields: fields, actionLabel: actionLabel, afterNote: afterNote, doneLine: doneLine, doneMessage: doneMsg, isArchived: false)
    }
}

private struct SeedMessage: Decodable {
    var sep: String?
    var f: String?
    var t: String?
    var cards: [String]?
    var action: SeedMessageAction?
}

private struct SeedMessageAction: Decodable { var task: String; var status: String; var label: String }

private struct CakeSeed: Decodable {
    var name: String
    var bakery: String
    var serves: String
    var price: String
    var tag: String
    var illustration: CakeIllustrationSeed
}

private struct CakeIllustrationSeed: Decodable { var topLayer: String; var baseLayer: String; var tileBackground: String }

private struct HistorySeed: Decodable {
    var id: String
    var month: String
    var date: String
    var title: String
    var outcome: String
    var fields: [ResultField]
    var repeatLabel: String
    var repeatPrompt: String
    var character: MascotCharacter
    var category: String
    var doneLine: String

    var task: AgentTask {
        AgentTask(
            id: id,
            title: title,
            character: character,
            status: .done,
            createdAt: .now,
            timeLabel: date,
            line: outcome,
            summary: outcome,
            progress: 1,
            steps: ["Understood the request", "Compared the best options", "Completed the task"],
            stepIndex: 3,
            resultLabel: category,
            fields: fields,
            doneLine: doneLine,
            repeatLabel: repeatLabel,
            repeatPrompt: repeatPrompt,
            category: category,
            isArchived: true,
            month: month,
            dateLabel: date
        )
    }
}
