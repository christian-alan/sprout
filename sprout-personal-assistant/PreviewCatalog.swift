import SwiftUI

struct MascotGallery: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                ForEach(MascotCharacter.allCases, id: \.self) { character in
                    VStack(alignment: .leading, spacing: 8) {
                        Text(character.displayName).font(.headline)
                        HStack(spacing: 6) {
                            ForEach(Mood.allCases, id: \.self) { mood in
                                VStack(spacing: 3) {
                                    FullMascotView(character: character, mood: mood, width: 58)
                                    Text(mood.rawValue).font(.caption2)
                                }
                            }
                        }
                    }
                }
            }
            .padding()
        }
        .background(Theme.paper)
    }
}

private struct PreviewRootHost: View {
    let model: AppModel

    init(mode: AppMode, configure: (AppModel) -> Void = { _ in }) {
        let model = AppModel()
        model.mode = mode
        configure(model)
        self.model = model
    }

    var body: some View { RootView(model: model) }
}

private struct PreviewSheetHost: View {
    let model: AppModel
    let taskID: String

    init(kind: Kind) {
        let model = AppModel()
        switch kind {
        case .ready:
            taskID = "dinner"
        case .done:
            var task = model.tasks["dinner"]!
            task.status = .done
            model.tasks[task.id] = task
            taskID = task.id
        case .past:
            taskID = "p-dentist"
        case .dentist:
            let task = AgentTask(id: "preview-dentist", title: "Find a dentist", character: .bloom, status: .needs, createdAt: .now, timeLabel: "today 08:12", line: "Morning or afternoon appointments?", progress: 0.65, steps: ["Search clinics near work", "Check who takes new patients", "Ask your preferred time", "Book the appointment"], stepIndex: 2, question: .options(prompt: "Morning or afternoon appointments?", note: "5 clinics near Kista take new patients. Two have openings next week.", primary: "Morning", secondary: "Afternoon", tertiary: "Either is fine"), fields: [], isArchived: false)
            model.tasks[task.id] = task
            taskID = task.id
        case .cake:
            let choices = [
                Choice(id: "one", name: "Raspberry princess cake", detail: "Söder Sockerbageri · serves 10", tag: "Classic Swedish", price: "465 kr", topHex: "9FD27A", baseHex: "F7C6D6", backgroundHex: "FDEEF3"),
                Choice(id: "two", name: "Lemon & elderflower", detail: "Konditori Älv · serves 8", tag: "Light, not too sweet", price: "420 kr", topHex: "FFF1A8", baseHex: "F6E7C8", backgroundHex: "FDF7E6"),
                Choice(id: "three", name: "Chocolate truffle", detail: "Bageri Lumen · serves 8", tag: "Most popular", price: "445 kr", topHex: "6B4232", baseHex: "9A6A52", backgroundHex: "F3ECE7")
            ]
            let task = AgentTask(id: "preview-cake", title: "Birthday cake", character: .tile, status: .needs, createdAt: .now, timeLabel: "today 08:20", line: "Which one would she love?", progress: 0.5, steps: ["Find bakeries nearby", "Check Saturday availability", "Choose a cake", "Place the order"], stepIndex: 2, question: .pickOne(prompt: "Which one would she love?", note: "All three can be ready for pickup next Saturday morning.", choices: choices), fields: [], isArchived: false)
            model.tasks[task.id] = task
            taskID = task.id
        }
        self.model = model
    }

    enum Kind { case dentist, cake, ready, done, past }
    var body: some View { TaskSheet(taskID: taskID, model: model) }
}

#Preview("Foundation · Mascot grid") { MascotGallery() }
#Preview("01 · Home") { PreviewRootHost(mode: .chat) }
#Preview("02 · Task born in chat") {
    PreviewRootHost(mode: .chat) { model in
        let reminder = AgentTask(id: "preview-mum", title: "Call mum", character: .clover, status: .scheduled, createdAt: .now, timeLabel: "today 19:00", line: "I'll remind you tonight at 19:00.", summary: "Tonight at 19:00", progress: 1, steps: ["Set reminder for 19:00"], stepIndex: 1, fields: [], isArchived: false)
        let dentist = AgentTask(id: "preview-dentist-born", title: "Find a dentist", character: .bloom, status: .working, createdAt: .now, timeLabel: "just now", line: "Searching clinics near work", progress: 0.2, steps: ["Search clinics near work", "Check who takes new patients", "Ask your preferred time", "Book the appointment"], stepIndex: 0, fields: [], isArchived: false)
        model.tasks[reminder.id] = reminder
        model.tasks[dentist.id] = dentist
        model.order.append(contentsOf: [reminder.id, dentist.id])
        model.messages.append(.init(role: .separator, text: "Today 08:12"))
        model.messages.append(.init(role: .user, text: "Remind me to call mum tonight, and find a dentist near work that takes new patients"))
        model.messages.append(.init(role: .assistant, text: "Done for mum, I'll remind you at 19:00. Looking for dentists now.", taskIDs: [reminder.id, dentist.id]))
        model.bornTaskID = dentist.id
    }
}
#Preview("03 · Tasks slider") { PreviewRootHost(mode: .tasks) }
#Preview("04 · New task card") { PreviewRootHost(mode: .tasks) { $0.selectedTaskID = "new" } }
#Preview("05 · Task born in slider") {
    PreviewRootHost(mode: .tasks) { model in
        let cake = AgentTask(id: "preview-cake-born", title: "Birthday cake", character: .tile, status: .working, createdAt: .now, timeLabel: "just now", line: "Looking at bakeries near you", progress: 0.2, steps: ["Find bakeries nearby", "Check Saturday availability", "Choose a cake", "Place the order"], stepIndex: 0, fields: [], isArchived: false)
        model.tasks[cake.id] = cake
        model.order.append(cake.id)
        model.selectedTaskID = cake.id
        model.bornTaskID = cake.id
    }
}
#Preview("06 · History card") { PreviewRootHost(mode: .tasks) }
#Preview("07 · Needs answer") { PreviewSheetHost(kind: .dentist) }
#Preview("08 · Pick one") { PreviewSheetHost(kind: .cake) }
#Preview("09 · Ready") { PreviewSheetHost(kind: .ready) }
#Preview("10 · Done") { PreviewSheetHost(kind: .done) }
#Preview("11 · Ask about history") {
    PreviewRootHost(mode: .chat) {
        $0.messages.append(.init(role: .separator, text: "Today 09:02"))
        $0.messages.append(.init(role: .user, text: "When did I last see the dentist?"))
        $0.messages.append(.init(role: .assistant, text: "Your last check-up was on Aug 30 at Kista Tandvård. They suggested coming back in about a year.", action: .init(kind: .openHistory, label: "See it in history", historyQuery: "dentist")))
    }
}
#Preview("12 · History") { PreviewRootHost(mode: .history) }
#Preview("13 · History search") { PreviewRootHost(mode: .history) { $0.historyQuery = "booked" } }
#Preview("14 · Past task") { PreviewSheetHost(kind: .past) }
