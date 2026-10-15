import SwiftUI

struct ContentView: View {
    @State private var model: AppModel
    private let isReviewScenario: Bool
    private let usesReviewDynamicType: Bool

    init() {
        let model = AppModel()
#if DEBUG
        let scenario = ProcessInfo.processInfo.environment["SPROUT_UI_STATE"]
        if let scenario { ReviewScenario.configure(scenario, model: model) }
        isReviewScenario = scenario != nil
        usesReviewDynamicType = ProcessInfo.processInfo.environment["SPROUT_UI_SIZE"] == "XXL"
#else
        isReviewScenario = false
        usesReviewDynamicType = false
#endif
        _model = State(initialValue: model)
    }

    var body: some View {
        Group {
#if DEBUG
            if usesReviewDynamicType {
                RootView(model: model)
                    .environment(\.dynamicTypeSize, .accessibility2)
            } else {
                RootView(model: model)
            }
#else
            RootView(model: model)
#endif
        }
            .task {
                if !isReviewScenario { model.start() }
            }
    }
}

#if DEBUG
@MainActor
private enum ReviewScenario {
    static func configure(_ state: String, model: AppModel) {
        switch state {
        case "02":
            model.mode = .chat
            let reminder = AgentTask(
                id: "preview-mum",
                title: "Call mum",
                character: .clover,
                status: .scheduled,
                createdAt: .now,
                timeLabel: "today 19:00",
                line: "I'll remind you tonight at 19:00.",
                summary: "Tonight at 19:00",
                progress: 1,
                steps: ["Set reminder for 19:00"],
                stepIndex: 1,
                fields: [],
                isArchived: false
            )
            let dentist = AgentTask(
                id: "preview-dentist-born",
                title: "Find a dentist",
                character: .bloom,
                status: .working,
                createdAt: .now,
                timeLabel: "just now",
                line: "Searching clinics near work",
                progress: 0.2,
                steps: ["Search clinics near work", "Check who takes new patients", "Ask your preferred time", "Book the appointment"],
                stepIndex: 0,
                fields: [],
                isArchived: false
            )
            model.tasks[reminder.id] = reminder
            model.tasks[dentist.id] = dentist
            model.order.append(contentsOf: [reminder.id, dentist.id])
            model.messages.append(.init(role: .separator, text: "Today 08:12"))
            model.messages.append(.init(role: .user, text: "Remind me to call mum tonight, and find a dentist near work that takes new patients"))
            model.messages.append(.init(role: .assistant, text: "Done for mum, I'll remind you at 19:00. Looking for dentists now.", taskIDs: [reminder.id, dentist.id]))
            model.bornTaskID = dentist.id
        case "03":
            model.mode = .tasks
            model.selectedTaskID = "dinner"
        case "04":
            model.mode = .tasks
            model.newTaskText = ""
            model.selectedTaskID = "new"
        case "05":
            let cake = AgentTask(
                id: "preview-cake-born",
                title: "Birthday cake",
                character: .tile,
                status: .working,
                createdAt: .now,
                timeLabel: "just now",
                line: "Looking at bakeries near you",
                progress: 0.2,
                steps: ["Find bakeries nearby", "Check Saturday availability", "Choose a cake", "Place the order"],
                stepIndex: 0,
                fields: [],
                isArchived: false
            )
            model.tasks[cake.id] = cake
            model.order.append(cake.id)
            model.mode = .tasks
            model.bornTaskID = cake.id
            model.selectedTaskID = cake.id
        case "06":
            model.mode = .tasks
            model.selectedTaskID = "history"
        case "07":
            let task = AgentTask(
                id: "preview-dentist",
                title: "Find a dentist",
                character: .bloom,
                status: .needs,
                createdAt: .now,
                timeLabel: "today 08:12",
                line: "Morning or afternoon appointments?",
                progress: 0.65,
                steps: ["Search clinics near work", "Check who takes new patients", "Ask your preferred time", "Book the appointment"],
                stepIndex: 2,
                question: .options(prompt: "Morning or afternoon appointments?", note: "5 clinics near Kista take new patients. Two have openings next week.", primary: "Morning", secondary: "Afternoon", tertiary: "Either is fine"),
                fields: [],
                isArchived: false
            )
            model.tasks[task.id] = task
            model.order.append(task.id)
            model.selectedTaskID = task.id
            present(task.id, over: .tasks, model: model)
        case "08":
            let task = AgentTask(
                id: "preview-cake",
                title: "Birthday cake",
                character: .tile,
                status: .needs,
                createdAt: .now,
                timeLabel: "today 08:20",
                line: "Which one would she love?",
                progress: 0.5,
                steps: ["Find bakeries nearby", "Check Saturday availability", "Choose a cake", "Place the order"],
                stepIndex: 2,
                question: .pickOne(prompt: "Which one would she love?", note: "All three can be ready for pickup next Saturday morning.", choices: model.cakeChoices),
                fields: [],
                isArchived: false
            )
            model.tasks[task.id] = task
            model.order.append(task.id)
            model.selectedTaskID = task.id
            present(task.id, over: .tasks, model: model)
        case "09":
            present("dinner", over: .tasks, model: model)
        case "10":
            if var task = model.tasks["dinner"] {
                task.status = .done
                model.tasks[task.id] = task
                present(task.id, over: .tasks, model: model)
            }
        case "11":
            model.mode = .chat
            model.messages.append(.init(role: .separator, text: "Today 09:02"))
            model.messages.append(.init(role: .user, text: "When did I last see the dentist?"))
            model.messages.append(.init(role: .assistant, text: "Your last check-up was on Aug 30 at Kista Tandvård. They suggested coming back in about a year.", action: .init(kind: .openHistory, label: "See it in history", historyQuery: "dentist")))
        case "12":
            model.mode = .history
        case "13":
            model.mode = .history
            model.historyQuery = "booked"
        case "14":
            present("p-dentist", over: .history, model: model)
        default:
            model.mode = .chat
        }
    }

    private static func present(_ taskID: String, over mode: AppMode, model: AppModel) {
        model.mode = mode
        model.openTaskSource = mode
        model.openTaskID = taskID
    }
}
#endif

#Preview {
    ContentView()
}
