import Foundation

@MainActor
struct ScriptedAssistant: AssistantService {
    func handle(_ text: String, context: AssistantContext) -> AsyncStream<AssistantEvent> {
        let lowered = text.lowercased()
        if ["history", "past tasks", "when did i", "last time", "what did you do"].contains(where: lowered.contains) {
            return historyFlow(text, context: context)
        }
        if lowered.contains("cake") || lowered.contains("birthday") {
            return cakeFlow(context: context)
        }
        if lowered.contains("dentist") || lowered.contains("call mum") {
            return dentistFlow(includeReminder: lowered.contains("call mum"))
        }
        return genericFlow(text, character: context.genericCharacter)
    }

    func answer(task: AgentTask, with choice: String, context: AssistantContext) -> AsyncStream<AssistantEvent> {
        stream { continuation in
            var working = task
            working.status = .working
            working.question = nil
            working.answerGiven = choice
            working.stepIndex = min(task.stepIndex + 1, task.steps.count - 1)
            working.progress = task.id == "cake" ? 0.72 : 0.76
            working.line = task.id == "cake" ? "Checking \(choice) with the bakery" : "Checking \(choice.lowercased()) slots"
            continuation.yield(.taskUpdated(working))
            continuation.yield(.message(.init(role: .assistant, text: task.id == "cake" ? "Great choice. I'll check the final details with the bakery." : "Got it, I'll look at \(choice.lowercased()) slots.")))
            await pause(3.1)

            var ready = working
            ready.status = .ready
            ready.progress = 1
            ready.stepIndex = max(ready.steps.count - 1, 0)
            if task.id == "cake" {
                let picked = context.cakeChoices.first(where: { $0.name == choice }) ?? context.cakeChoices.first
                ready.line = "\(picked?.name ?? choice), ready Saturday morning."
                ready.summary = "Saturday 11:00 · \(picked?.price ?? "465 kr")"
                ready.resultLabel = "Order"
                ready.fields = [
                    .init(label: "Bakery", value: picked?.detail.components(separatedBy: " · ").first ?? "Söder Sockerbageri"),
                    .init(label: "Serves", value: picked?.detail.components(separatedBy: "serves ").last ?? "10"),
                    .init(label: "Pickup", value: "Saturday 11:00"),
                    .init(label: "On top", value: "Grattis Mamma 60"),
                    .init(label: "Price", value: picked?.price ?? "465 kr")
                ]
                ready.actionLabel = "Order · \(picked?.price ?? "465 kr")"
                ready.afterNote = "I'll remind you that morning."
                ready.doneLine = "Ordered for pickup Saturday at 11:00."
                ready.doneMessage = "Ordered! Pick it up Saturday at 11:00 from \(ready.fields.first?.value ?? "the bakery"). I'll remind you that morning."
                continuation.yield(.taskUpdated(ready))
                continuation.yield(.message(.init(role: .assistant, text: "The cake is ready to order for Saturday morning.", action: .init(kind: .confirm, taskID: ready.id, expectedStatus: .ready, label: ready.actionLabel ?? "Order"))))
            } else {
                ready.line = "Kista Tandvård has a slot on Tuesday at 08:30."
                ready.summary = "Tue 08:30 · Kista Tandvård"
                ready.resultLabel = "Appointment"
                ready.fields = [.init(label: "Clinic", value: "Kista Tandvård"), .init(label: "When", value: "Tuesday 08:30"), .init(label: "Type", value: "New-patient check-up")]
                ready.actionLabel = "Book Tue 08:30"
                ready.afterNote = "I'll add it to your calendar."
                ready.doneLine = "Booked for Tuesday at 08:30."
                ready.doneMessage = "Booked! Tuesday 08:30 at Kista Tandvård. I added it to your calendar."
                continuation.yield(.taskUpdated(ready))
                continuation.yield(.message(.init(role: .assistant, text: "Kista Tandvård has a slot on Tuesday at 08:30. Want me to book it?", action: .init(kind: .confirm, taskID: ready.id, expectedStatus: .ready, label: "Book Tue 08:30"))))
            }
        }
    }

    func confirm(task: AgentTask) -> AsyncStream<AssistantEvent> {
        stream { continuation in
            var done = task
            done.status = .done
            done.progress = 1
            done.stepIndex = done.steps.count
            done.question = nil
            continuation.yield(.taskUpdated(done))
            continuation.yield(.message(.init(role: .assistant, text: done.doneMessage ?? done.doneLine ?? "All set.")))
        }
    }

    func stop(task: AgentTask) -> AsyncStream<AssistantEvent> {
        stream { continuation in
            continuation.yield(.taskRemoved(task.id))
            continuation.yield(.message(.init(role: .assistant, text: "Okay, I stopped \"\(task.title)\".")))
        }
    }

    private func dentistFlow(includeReminder: Bool) -> AsyncStream<AssistantEvent> {
        stream { continuation in
            continuation.yield(.typing(true))
            await pause(1.1)
            continuation.yield(.typing(false))

            let reminder = AgentTask(id: "mum-\(UUID().uuidString.prefix(5))", title: "Call mum", character: .clover, status: .scheduled, createdAt: .now, timeLabel: "today 19:00", line: "I'll remind you tonight at 19:00.", summary: "Tonight at 19:00", progress: 1, steps: ["Set reminder for 19:00"], stepIndex: 1, fields: [], isArchived: false)
            let dentist = AgentTask(id: "dentist-\(UUID().uuidString.prefix(5))", title: "Find a dentist", character: .bloom, status: .working, createdAt: .now, timeLabel: "now", line: "Searching clinics near work", progress: 0.2, steps: ["Search clinics near work", "Check who takes new patients", "Ask your preferred time", "Book the appointment"], stepIndex: 0, fields: [], isArchived: false)
            if includeReminder { continuation.yield(.taskCreated(reminder)) }
            continuation.yield(.taskCreated(dentist))
            continuation.yield(.message(.init(
                role: .assistant,
                text: includeReminder ? "Done for mum, I'll remind you at 19:00. Looking for dentists now." : "I'll find a dentist near work that takes new patients.",
                taskIDs: includeReminder ? [reminder.id, dentist.id] : [dentist.id]
            )))
            await pause(2.2)
            var checking = dentist
            checking.line = "Checking who takes new patients"
            checking.progress = 0.48
            checking.stepIndex = 1
            continuation.yield(.taskUpdated(checking))
            await pause(2)
            var needs = checking
            needs.status = .needs
            needs.line = "Morning or afternoon appointments?"
            needs.progress = 0.65
            needs.stepIndex = 2
            needs.question = .options(prompt: "Morning or afternoon appointments?", note: "5 clinics near Kista take new patients. Two have openings next week.", primary: "Morning", secondary: "Afternoon", tertiary: "Either is fine")
            continuation.yield(.taskUpdated(needs))
            continuation.yield(.message(.init(role: .assistant, text: "Quick question about the dentist: morning or afternoon?", action: .init(kind: .answer, taskID: needs.id, expectedStatus: .needs, label: "Answer"))))
        }
    }

    private func cakeFlow(context: AssistantContext) -> AsyncStream<AssistantEvent> {
        stream { continuation in
            continuation.yield(.typing(true))
            await pause(1.1)
            continuation.yield(.typing(false))
            let cake = AgentTask(id: "cake", title: "Birthday cake", character: .tile, status: .working, createdAt: .now, timeLabel: "now", line: "Finding bakeries for next Saturday", progress: 0.2, steps: ["Find bakeries nearby", "Check Saturday availability", "Choose a cake", "Place the order"], stepIndex: 0, fields: [], isArchived: false)
            continuation.yield(.taskCreated(cake))
            continuation.yield(.message(.init(role: .assistant, text: "Lovely! I'll find a cake for your mom that's ready in time for next Saturday.", taskIDs: [cake.id])))
            await pause(2.2)
            var checking = cake
            checking.line = "Checking who can make it by next Saturday"
            checking.progress = 0.48
            checking.stepIndex = 1
            continuation.yield(.taskUpdated(checking))
            await pause(2.4)
            var needs = checking
            needs.status = .needs
            needs.line = "Which one would she love?"
            needs.stepIndex = 2
            needs.question = .pickOne(prompt: "Which one would she love?", note: "All three can be ready for pickup next Saturday morning.", choices: context.cakeChoices)
            continuation.yield(.taskUpdated(needs))
            continuation.yield(.message(.init(role: .assistant, text: "Found three cakes she might love. Want to pick one?", action: .init(kind: .answer, taskID: needs.id, expectedStatus: .needs, label: "Pick a cake"))))
        }
    }

    private func genericFlow(_ request: String, character: MascotCharacter) -> AsyncStream<AssistantEvent> {
        stream { continuation in
            continuation.yield(.typing(true))
            await pause(1.1)
            continuation.yield(.typing(false))
            let words = request.split(separator: " ").prefix(4).map(String.init)
            let title = words.joined(separator: " ").capitalized
            var task = AgentTask(id: "generic-\(UUID().uuidString.prefix(6))", title: title, character: character, status: .working, createdAt: .now, timeLabel: "now", line: "Getting started", progress: 0.2, steps: ["Understand the request", "Compare a few options", "Share the best result"], stepIndex: 0, fields: [], isArchived: false)
            continuation.yield(.taskCreated(task))
            continuation.yield(.message(.init(role: .assistant, text: "On it. I'll take care of that and come back with options.", taskIDs: [task.id])))
            await pause(2.2)
            task.line = "Comparing a few options"
            task.progress = 0.6
            task.stepIndex = 1
            continuation.yield(.taskUpdated(task))
            await pause(3.3)
            task.status = .ready
            task.line = "Done looking into \"\(request)\". I have a few options for you."
            task.summary = "A few options are ready"
            task.progress = 1
            task.stepIndex = 2
            task.resultLabel = "Result"
            task.fields = [.init(label: "Request", value: request), .init(label: "Status", value: "Options ready")]
            task.actionLabel = "Looks good"
            task.doneLine = "Finished."
            continuation.yield(.taskUpdated(task))
            continuation.yield(.message(.init(role: .assistant, text: task.line, action: .init(kind: .confirm, taskID: task.id, expectedStatus: .ready, label: "Looks good"))))
        }
    }

    private func historyFlow(_ query: String, context: AssistantContext) -> AsyncStream<AssistantEvent> {
        stream { continuation in
            continuation.yield(.typing(true))
            await pause(0.8)
            continuation.yield(.typing(false))
            let lowered = query.lowercased()
            let words = lowered.components(separatedBy: CharacterSet.alphanumerics.inverted).filter { $0.count > 4 }
            let match = context.history.first { task in
                let haystack = "\(task.title) \(task.line) \(task.category ?? "")".lowercased()
                return words.contains { haystack.contains($0) }
            }
            if let match {
                let monthDate = match.dateLabel ?? "recently"
                continuation.yield(.message(.init(role: .assistant, text: "Found it: \"\(match.title)\" from \(monthDate). \(match.line).", taskIDs: [match.id], action: .init(kind: .openHistory, label: "See it in history", historyQuery: match.title.components(separatedBy: " ").first))))
            } else {
                continuation.yield(.message(.init(role: .assistant, text: "Here's everything I've done for you over the last 6 months.", action: .init(kind: .openHistory, label: "Open history"))))
            }
        }
    }

    private func stream(_ work: @escaping @MainActor (AsyncStream<AssistantEvent>.Continuation) async -> Void) -> AsyncStream<AssistantEvent> {
        AsyncStream { continuation in
            Task {
                await work(continuation)
                continuation.finish()
            }
        }
    }

    private func pause(_ seconds: Double) async {
        try? await Task.sleep(for: .seconds(seconds))
    }
}
