import SwiftUI

struct TasksView: View {
    let model: AppModel
    @State private var scrolledID: String?
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack {
            Theme.stage.ignoresSafeArea()
            VStack(spacing: 0) {
                TasksHeader(model: model)
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                Color.clear
                    .frame(height: 36)
                ScrollView(.horizontal) {
                    LazyHStack(spacing: Theme.Size.taskCardSpacing) {
                        NewTaskCard(model: model).id("new")
                        ForEach(model.activeTasks) { task in
                            TaskCard(task: task, model: model, isBorn: model.bornTaskID == task.id)
                                .id(task.id)
                                .transition(reduceMotion ? .opacity : .asymmetric(insertion: .scale(scale: 0.8).combined(with: .opacity), removal: .opacity))
                        }
                        HistoryCard(model: model).id("history")
                    }
                    .scrollTargetLayout()
                }
                .contentMargins(.horizontal, 40)
                .scrollTargetBehavior(.viewAligned)
                .scrollPosition(id: $scrolledID)
                .scrollIndicators(.hidden)
                .scrollClipDisabled()
                .frame(height: 470)
                .sensoryFeedback(.selection, trigger: scrolledID)

                Text(model.bornTaskID == nil ? "Swipe for more · first card starts a new task" : "A new task was born")
                    .sproutFont(12, weight: .medium)
                    .foregroundStyle(Theme.textMuted)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                    .padding(.horizontal, 24)
                    .padding(.top, 22)
                    .animation(.easeInOut, value: model.bornTaskID)
                Spacer()
            }
        }
        .onAppear {
            if scrolledID == nil {
                scrolledID = model.selectedTaskID ?? model.activeTasks.first?.id ?? "new"
            }
        }
        .onChange(of: model.bornTaskID) {
            guard let id = model.bornTaskID else { return }
            withAnimation(.spring(duration: 0.8, bounce: 0.2)) { scrolledID = id }
        }
    }
}

private struct TasksHeader: View {
    let model: AppModel

    var body: some View {
        HStack {
            MascotView(character: .sprout, mood: model.assistantMood, style: .head)
                .frame(width: 44, height: 44)
            VStack(alignment: .leading, spacing: 1) {
                Text("Tasks").sproutFont(26, weight: .bold)
                Text(model.taskSubtitle).sproutFont(12).foregroundStyle(Theme.textMuted)
            }
            Spacer()
            Button { model.mode = .chat } label: {
                HStack(spacing: 6) {
                    Text("Chat").sproutFont(15, weight: .semibold)
                    Image(systemName: "chevron.down").sproutFont(12, weight: .bold)
                }
                .foregroundStyle(Theme.ink)
                .padding(.horizontal, 16)
                .frame(height: 44)
            }
            .buttonStyle(.glass)
            .buttonBorderShape(.capsule)
        }
    }
}

struct TaskCard: View {
    let task: AgentTask
    let model: AppModel
    let isBorn: Bool
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @State private var arrivalComplete = true

    var body: some View {
        ZStack {
            TaskSceneBackground(character: task.character)

            VStack(spacing: -40) {
                Spacer(minLength: 0)
                FullMascotView(
                    character: task.character,
                    mood: task.status.mood,
                    width: dynamicTypeSize.isAccessibilitySize ? 150 : Theme.Size.mascotOnCard
                )
                taskPanel
            }
            .padding(10)

            GlassEffectContainer(spacing: 10) {
                HStack {
                    StatusPill(status: task.status, character: task.character)
                    if !dynamicTypeSize.isAccessibilitySize {
                        Spacer()
                        Text(task.timeLabel)
                            .sproutFont(12, weight: .medium)
                            .foregroundStyle(Theme.inkSecondary)
                            .padding(.horizontal, 13)
                            .frame(height: Theme.Size.statusPillHeight)
                            .glassEffect(.regular, in: .capsule)
                    }
                }
            }
            .padding(.horizontal, 14)
            .padding(.top, 14)
            .frame(maxHeight: .infinity, alignment: .top)

        }
        .frame(width: Theme.Size.taskCardWidth, height: Theme.Size.taskCardHeight)
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.taskCard, style: .continuous))
        .shadow(color: task.character.palette.accent.opacity(0.35), radius: 30, y: 28)
        .shadow(color: Color(hex: "3C2814").opacity(0.12), radius: 14, y: 10)
        .overlay {
            if isBorn {
                RoundedRectangle(cornerRadius: Theme.Radius.taskCard, style: .continuous)
                    .stroke(task.character.palette.accent.opacity(0.33), lineWidth: 4)
                    .shadow(color: task.character.palette.accent.opacity(0.65), radius: 16)
            }
        }
        .scaleEffect(isBorn && !arrivalComplete && !reduceMotion ? Theme.Motion.taskBornScale : 1)
        .blur(radius: isBorn && !arrivalComplete && !reduceMotion ? Theme.Motion.taskBornBlur : 0)
        .opacity(task.status == .done ? 0.76 : 1)
        .animation(.spring(duration: Theme.Motion.taskBornDuration, bounce: 0.3), value: arrivalComplete)
        .onTapGesture { model.showTask(task.id) }
        .onAppear { animateArrivalIfNeeded() }
        .onChange(of: isBorn) { animateArrivalIfNeeded() }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("\(task.title), \(task.status.label)")
        .accessibilityValue(task.line)
        .accessibilityHint("Opens task details")
        .accessibilityAction(named: "Open details") { model.showTask(task.id) }
    }

    private var taskPanel: some View {
        VStack(alignment: .leading, spacing: 8) {
                Text(task.title)
                    .sproutFont(23, weight: .bold)
                    .foregroundStyle(Theme.ink)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
                Text(task.line)
                    .sproutFont(14)
                    .foregroundStyle(Theme.inkSecondary)
                    .lineLimit(dynamicTypeSize.isAccessibilitySize ? 3 : 2)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(minHeight: 38, alignment: .top)
                actionArea
            }
            .padding(18)
            .frame(maxWidth: .infinity, alignment: .leading)
            .glassPanel(cornerRadius: Theme.Radius.glassPanel)
    }

    private func animateArrivalIfNeeded() {
        guard isBorn, !reduceMotion else {
            arrivalComplete = true
            return
        }
        arrivalComplete = false
        Task { @MainActor in
            await Task.yield()
            withAnimation(.spring(duration: Theme.Motion.taskBornDuration, bounce: 0.3)) { arrivalComplete = true }
        }
    }

    @ViewBuilder private var actionArea: some View {
        switch task.status {
        case .needs:
            FilledCapsuleButton(title: "Answer", color: task.character.palette.accent) { model.showTask(task.id) }
        case .ready:
            HStack(spacing: 8) {
                Button(task.actionLabel ?? "Confirm") { model.confirm(task) }
                    .sproutFont(15, weight: .semibold)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity).frame(height: Theme.Size.primaryButtonHeight)
                    .background(Theme.ink, in: Capsule())
                    .buttonStyle(.plain)
                GlassIconButton(systemName: "ellipsis", label: "View details", size: 50) { model.showTask(task.id) }
            }
        case .working:
            VStack(alignment: .leading, spacing: 7) {
                GeometryReader { geometry in
                    Capsule().fill(.white.opacity(0.55))
                        .overlay(alignment: .leading) {
                            Capsule().fill(task.character.palette.accent).frame(width: geometry.size.width * task.progress)
                        }
                }
                .frame(height: 6)
                Text("Step \(min(task.stepIndex + 1, task.steps.count)) of \(task.steps.count) · \(task.line)")
                    .sproutFont(11, weight: .medium).foregroundStyle(Theme.textMuted).lineLimit(1)
            }
        case .scheduled:
            GlassCapsuleButton(title: "Change time") { model.showTask(task.id) }
        case .done:
            GlassCapsuleButton(title: "View details") { model.showTask(task.id) }
        }
    }
}

private struct NewTaskCard: View {
    let model: AppModel
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: Theme.Radius.taskCard, style: .continuous)
                .fill(LinearGradient(colors: [.white.opacity(0.8), Theme.paperTop], startPoint: .top, endPoint: .bottom))
                .overlay(RoundedRectangle(cornerRadius: Theme.Radius.taskCard, style: .continuous).stroke(Theme.textMuted.opacity(0.2), style: StrokeStyle(lineWidth: 1.5, dash: [8, 7])))
            VStack(spacing: 0) {
                Text("+ New task")
                    .sproutFont(12, weight: .semibold)
                    .padding(.horizontal, 15).frame(height: 30)
                    .overlay(Capsule().stroke(Theme.textMuted.opacity(0.45), style: StrokeStyle(lineWidth: 1.2, dash: [5, 4])))
                    .padding(.top, 14)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.leading, 14)
                Spacer(minLength: 0)
                FullMascotView(
                    character: .new,
                    mood: model.isCreatingTask ? .working : .idle,
                    width: dynamicTypeSize.isAccessibilitySize ? 118 : 150
                )
                VStack(alignment: .leading, spacing: 11) {
                    Text(model.isCreatingTask ? "Sprout is setting it up…" : "What should I take care of?")
                        .sproutFont(21, weight: .bold)
                        .fixedSize(horizontal: false, vertical: true)
                        .layoutPriority(1)
                    HStack(spacing: 7) {
                        TextField(
                            text: Binding(get: { model.newTaskText }, set: { model.newTaskText = $0 }),
                            prompt: Text("Describe it in a few words").foregroundStyle(Theme.textMuted)
                        ) { EmptyView() }
                            .sproutFont(15)
                            .submitLabel(.send)
                            .onSubmit { model.sendFromSlider(model.newTaskText) }
                        Button { model.sendFromSlider(model.newTaskText) } label: {
                            Image(systemName: "arrow.up").sproutFont(13, weight: .bold).foregroundStyle(.white)
                                .frame(width: 32, height: 32).background(Theme.ink, in: Circle())
                                .minimumTouchTarget()
                        }
                        .disabled(model.newTaskText.isEmpty)
                    }
                    .padding(.leading, 14).padding(.trailing, 5).frame(height: 48)
                    .background(.white.opacity(0.7), in: Capsule())
                    VStack(alignment: .leading, spacing: 6) {
                        quickChip("Birthday cake for mom") { model.sendFromSlider("Can you find a birthday cake for my mom? She is celebrating her birthday next Saturday.") }
                        HStack(spacing: 6) {
                            quickChip("Book a haircut") { model.sendFromSlider("Book a haircut") }
                            quickChip("Remind me to…") { model.newTaskText = "Remind me to " }
                        }
                    }
                }
                .padding(17)
                .frame(height: 212, alignment: .topLeading)
                .glassPanel(cornerRadius: Theme.Radius.glassPanel)
                .padding(10)
            }
        }
        .frame(width: Theme.Size.taskCardWidth, height: Theme.Size.taskCardHeight)
        .shadow(color: Color(hex: "3C2814").opacity(0.12), radius: 14, y: 10)
    }

    private func quickChip(_ title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .sproutFont(11, weight: .medium)
                .foregroundStyle(Theme.inkSecondary)
                .padding(.horizontal, 11).frame(height: Theme.Size.statusPillHeight)
                .background(.white.opacity(0.64), in: Capsule())
                .minimumTouchTarget()
        }
        .buttonStyle(.plain)
        .padding(.vertical, (Theme.Size.statusPillHeight - Theme.Size.minTouchTarget) / 2)
    }
}

private struct HistoryCard: View {
    let model: AppModel
    private let previewCharacters: [MascotCharacter] = [.keys, .dash, .tile, .rover, .clover, .pop]

    var body: some View {
        Button { model.mode = .history } label: {
            ZStack {
                RoundedRectangle(cornerRadius: Theme.Radius.taskCard, style: .continuous).fill(Theme.ink)
                    .overlay(alignment: .topLeading) { Circle().fill(MascotCharacter.bloom.palette.accent.opacity(0.36)).frame(width: 230).blur(radius: 55).offset(x: -70, y: -70) }
                    .overlay(alignment: .bottomTrailing) { Circle().fill(MascotCharacter.tile.palette.accent.opacity(0.3)).frame(width: 210).blur(radius: 52).offset(x: 70, y: 70) }
                VStack(alignment: .leading, spacing: 14) {
                    Text("LAST 6 MONTHS").sproutFont(12, weight: .semibold).tracking(0.6).foregroundStyle(.white.opacity(0.62))
                    LazyVGrid(columns: Array(repeating: GridItem(.fixed(66), spacing: 10), count: 3), spacing: 10) {
                        ForEach(previewCharacters, id: \.self) { character in
                            MascotView(character: character, mood: .asleep, style: .head)
                                .padding(9).frame(width: 66, height: 66)
                                .glassEffect(.regular, in: .rect(cornerRadius: 18))
                        }
                    }
                    Spacer()
                    Text("History").sproutFont(27, weight: .bold).foregroundStyle(.white)
                    Text("\(model.archivedTasks.count) finished tasks, from flights to flowers").sproutFont(14).foregroundStyle(.white.opacity(0.72))
                    Text("Browse past tasks")
                        .sproutFont(15, weight: .semibold).foregroundStyle(.white)
                        .frame(maxWidth: .infinity).frame(height: 50)
                        .glassEffect(.regular.interactive(), in: .capsule)
                }
                .padding(24)
            }
            .frame(width: Theme.Size.taskCardWidth, height: Theme.Size.taskCardHeight)
        }
        .buttonStyle(.plain)
        .shadow(color: Color(hex: "3C2814").opacity(0.18), radius: 16, y: 12)
        .accessibilityLabel("History, \(model.archivedTasks.count) finished tasks")
        .accessibilityHint("Browses past tasks")
    }
}

#Preview("03 Tasks slider") {
    TasksView(model: AppModel())
}
