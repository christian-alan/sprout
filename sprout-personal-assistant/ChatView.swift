import SwiftUI

struct ChatView: View {
    let model: AppModel
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack {
            LinearGradient(colors: [Theme.paperTop, Theme.paper, Theme.paper], startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()

            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 8) {
                        ForEach(model.messages) { message in
                            MessageRow(message: message, model: model)
                                .id(message.id)
                                .transition(reduceMotion ? .opacity : .move(edge: .bottom).combined(with: .opacity))
                        }
                        if model.isTyping {
                            TypingIndicator().id("typing")
                        }
                    }
                    .padding(.horizontal, Theme.Space.gutter)
                }
                .scrollIndicators(.hidden)
                .scrollEdgeEffectStyle(.soft, for: [.top, .bottom])
                .defaultScrollAnchor(.bottom)
                .onChange(of: model.messages.count) {
                    withAnimation(.easeOut(duration: Theme.Motion.messageDuration)) { proxy.scrollTo(model.messages.last?.id, anchor: .bottom) }
                }
                .onChange(of: model.isTyping) {
                    withAnimation(.easeOut(duration: 0.25)) { proxy.scrollTo(model.isTyping ? AnyHashable("typing") : AnyHashable(model.messages.last?.id), anchor: .bottom) }
                }
            }
        }
        .safeAreaInset(edge: .top, spacing: 0) {
            ChatHeader(model: model)
                .padding(.horizontal, 20)
                .background(Theme.paperTop.ignoresSafeArea(edges: .top))
                .zIndex(1)
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            VStack(spacing: 10) {
                if !model.activeTasks.isEmpty { TaskStrip(model: model) }
                Composer(model: model)
            }
            .padding(.horizontal, 14)
            .padding(.bottom, 8)
        }
    }
}

private struct ChatHeader: View {
    let model: AppModel
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        ZStack {
            HStack {
                GlassIconButton(systemName: "arrow.counterclockwise", label: "Restart") { model.reset() }
                Spacer()
                GlassIconButton(systemName: "rectangle.stack", label: "Open tasks") { model.mode = .tasks }
            }
            VStack(spacing: 2) {
                FullMascotView(character: .sprout, mood: model.assistantMood, width: 54)
                Text("Sprout")
                    .sproutFont(13, weight: .semibold)
                    .lineLimit(1)
            }
        }
        .padding(.top, 4)
        .padding(.bottom, dynamicTypeSize.isAccessibilitySize ? 12 : 4)
        .frame(height: dynamicTypeSize.isAccessibilitySize ? 132 : 116, alignment: .top)
        .zIndex(1)
    }
}

private struct MessageRow: View {
    let message: Message
    let model: AppModel

    var body: some View {
        switch message.role {
        case .separator:
            Text(message.text)
                .sproutFont(11, weight: .medium)
                .foregroundStyle(Theme.textFaint)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
        case .user:
            HStack {
                Spacer(minLength: 70)
                Text(message.text)
                    .sproutFont(14)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 13)
                    .padding(.vertical, 9)
                    .background(Theme.ink, in: RoundedRectangle(cornerRadius: Theme.Radius.bubble, style: .continuous))
            }
        case .assistant:
            VStack(alignment: .leading, spacing: 8) {
                if let action = message.action {
                    VStack(alignment: .leading, spacing: 10) {
                        Text(message.text)
                            .sproutFont(14)
                            .foregroundStyle(Theme.ink)
                        ChatActionRow(action: action, model: model)
                    }
                    .padding(5)
                    .padding(.top, 8)
                    .padding(.horizontal, 8)
                    .background(.white, in: RoundedRectangle(cornerRadius: Theme.Radius.messageCard, style: .continuous))
                    .shadow(color: .black.opacity(0.055), radius: 8, y: 3)
                    .frame(maxWidth: 340, alignment: .leading)
                } else {
                    Text(message.text)
                        .sproutFont(14)
                        .foregroundStyle(Theme.ink)
                        .padding(.horizontal, 13)
                        .padding(.vertical, 10)
                        .background(.white, in: RoundedRectangle(cornerRadius: Theme.Radius.bubble, style: .continuous))
                        .shadow(color: .black.opacity(0.045), radius: 7, y: 2)
                        .frame(maxWidth: 304, alignment: .leading)
                }

                if !message.taskIDs.isEmpty {
                    ScrollView(.horizontal) {
                        HStack(spacing: 8) {
                            ForEach(message.taskIDs, id: \.self) { id in
                                if let task = model.task(id) { MiniTaskCard(task: task, model: model) }
                            }
                        }
                    }
                    .scrollIndicators(.hidden)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

private struct ChatActionRow: View {
    let action: MessageAction
    let model: AppModel
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        let task = action.taskID.flatMap(model.task)
        HStack(spacing: 8) {
            Button {
                model.perform(action)
            } label: {
                HStack(spacing: 8) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 10, style: .continuous).fill(.white.opacity(0.72))
                        MascotView(character: task?.character ?? .sprout, mood: task?.status.mood ?? .idle, style: .head).padding(3)
                    }
                    .frame(width: 30, height: 30)
                    VStack(alignment: .leading, spacing: 1) {
                        HStack(spacing: 3) {
                            Text(task?.title ?? "History")
                                .sproutFont(13, weight: .semibold)
                                .lineLimit(dynamicTypeSize.isAccessibilitySize ? 2 : 1)
                            Image(systemName: "chevron.right").sproutFont(10, weight: .bold).foregroundStyle(Theme.textFaint)
                        }
                        Text(summary(for: task))
                            .sproutFont(11)
                            .foregroundStyle(Theme.textMuted)
                            .lineLimit(dynamicTypeSize.isAccessibilitySize ? 2 : 1)
                    }
                }
            }
            .buttonStyle(.plain)

            Spacer(minLength: 0)

            Button {
                if action.kind == .confirm, let task, task.status == action.expectedStatus { model.confirm(task) }
                else { model.perform(action) }
            } label: {
                Text(buttonLabel(for: task))
                    .sproutFont(12, weight: .semibold)
                    .foregroundStyle(isActionAvailable(task) ? .white : Theme.inkSecondary)
                    .padding(.horizontal, 13)
                    .padding(.vertical, dynamicTypeSize.isAccessibilitySize ? 6 : 0)
                    .frame(minHeight: Theme.Size.compactControlHeight)
                    .background(isActionAvailable(task) ? (task?.character.palette.accent ?? Theme.ink) : .white.opacity(0.72), in: Capsule())
                    .minimumTouchTarget()
            }
            .buttonStyle(.plain)
        }
        .padding(6)
        .background(task?.character.palette.tint ?? MascotCharacter.sprout.palette.tint, in: RoundedRectangle(cornerRadius: Theme.Radius.taskRow, style: .continuous))
    }

    private func isActionAvailable(_ task: AgentTask?) -> Bool {
        action.kind == .openHistory || task?.status == action.expectedStatus
    }

    private func buttonLabel(for task: AgentTask?) -> String {
        if action.kind == .openHistory { return action.label }
        guard let task else { return action.label }
        if task.status == action.expectedStatus { return action.label }
        if action.kind == .answer { return "✓ Answered" }
        switch task.status {
        case .done: return "✓ Done"
        case .working: return "Working…"
        default: return task.status.label
        }
    }

    private func summary(for task: AgentTask?) -> String {
        guard let task else { return "Your last 6 months" }
        if action.kind == .answer, let answer = task.answerGiven { return answer }
        if task.status == .done { return task.doneLine ?? task.line }
        if task.status == .needs { return "Needs your answer" }
        return task.summary ?? task.status.label
    }
}

private struct MiniTaskCard: View {
    let task: AgentTask
    let model: AppModel
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        Button { model.showTask(task.id) } label: {
            HStack(spacing: 8) {
                ZStack {
                    RoundedRectangle(cornerRadius: 11, style: .continuous).fill(task.character.palette.tint)
                    MascotView(character: task.character, mood: task.status.mood, style: .head).padding(4)
                }
                .frame(width: 34, height: 34)
                VStack(alignment: .leading, spacing: 3) {
                    Text(task.title)
                        .sproutFont(13, weight: .semibold)
                        .lineLimit(dynamicTypeSize.isAccessibilitySize ? 2 : 1)
                    HStack(spacing: 5) {
                        Circle().fill(task.status == .ready ? Theme.ready : task.character.palette.accent).frame(width: 6, height: 6)
                        Text(task.status.label).sproutFont(11).foregroundStyle(Theme.textMuted)
                    }
                }
            }
            .padding(7)
            .frame(width: dynamicTypeSize.isAccessibilitySize ? 260 : 156, alignment: .leading)
            .background(.white, in: RoundedRectangle(cornerRadius: 19, style: .continuous))
            .shadow(color: .black.opacity(0.045), radius: 6, y: 2)
        }
        .buttonStyle(.plain)
    }
}

private struct TaskStrip: View {
    let model: AppModel
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        Button { model.mode = .tasks } label: {
            HStack(spacing: 10) {
                HStack(spacing: -9) {
                    ForEach(Array(model.activeTasks.prefix(4))) { task in
                        MascotView(character: task.character, mood: task.status.mood, style: .head)
                            .padding(3)
                            .frame(width: 32, height: 32)
                            .background(task.character.palette.tint, in: Circle())
                            .overlay(Circle().stroke(.white, lineWidth: 2))
                    }
                }
                Text("\(model.activeTasks.count) tasks").sproutFont(14, weight: .semibold)
                Image(systemName: "chevron.up").sproutFont(13, weight: .bold)
            }
            .foregroundStyle(Theme.ink)
            .padding(.leading, 8)
            .padding(.trailing, 14)
            .frame(height: Theme.Size.composerHeight)
        }
        .buttonStyle(.glass)
        .buttonBorderShape(.capsule)
        .scaleEffect(reduceMotion || model.bornTaskID == nil ? 1 : Theme.Motion.stripPulseScale)
        .animation(reduceMotion ? nil : .bouncy(duration: Theme.Motion.stripPulseDuration), value: model.bornTaskID)
        .sensoryFeedback(.success, trigger: model.bornTaskID)
        .accessibilityLabel("Open \(model.activeTasks.count) tasks")
        .accessibilityHint("Shows the task cards")
    }
}

private struct Composer: View {
    let model: AppModel

    var body: some View {
        GlassEffectContainer(spacing: 10) {
            HStack(spacing: 10) {
                GlassIconButton(systemName: "plus", label: "Add", size: 46) { }
                HStack(spacing: 8) {
                    TextField(
                        text: Binding(get: { model.composerText }, set: { model.composerText = $0 }),
                        prompt: Text("Ask Sprout").foregroundStyle(Theme.textMuted)
                    ) { EmptyView() }
                        .sproutFont(17)
                        .submitLabel(.send)
                        .onSubmit { model.send(model.composerText) }
                    if model.composerText.isEmpty {
                        Image(systemName: "mic.fill").foregroundStyle(Theme.textMuted)
                    }
                    Button { model.send(model.composerText) } label: {
                        Image(systemName: "arrow.up")
                            .sproutFont(15, weight: .bold)
                            .foregroundStyle(.white)
                            .frame(width: 34, height: 34)
                            .background(Theme.ink, in: Circle())
                            .minimumTouchTarget()
                    }
                    .disabled(model.composerText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    .accessibilityLabel("Send")
                }
                .padding(.leading, 17)
                .padding(.trailing, 6)
                .frame(height: Theme.Size.composerHeight)
                .glassEffect(.regular.interactive(), in: .capsule)
            }
        }
    }
}

private struct TypingIndicator: View {
    @State private var active = false
    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<3, id: \.self) { index in
                Circle().fill(Theme.textMuted).frame(width: 6, height: 6)
                    .offset(y: active ? -3 : 2)
                    .animation(.easeInOut(duration: 0.55).repeatForever().delay(Double(index) * 0.12), value: active)
            }
        }
        .padding(.horizontal, 15).frame(height: 36)
        .background(.white, in: Capsule())
        .frame(maxWidth: .infinity, alignment: .leading)
        .onAppear { active = true }
        .accessibilityLabel("Sprout is typing")
    }
}

#Preview("01 Home") {
    ChatView(model: AppModel())
}
