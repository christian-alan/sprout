import SwiftUI

struct TaskSheet: View {
    let taskID: String
    let model: AppModel
    @Environment(\.dismiss) private var dismiss
    @State private var progressExpanded = false
    @State private var measuredContentHeight: CGFloat = 620
    @State private var selectedDetent: PresentationDetent = .height(620)

    private var task: AgentTask? {
        if model.openTaskID == taskID {
            return model.openTask
        }
        return model.task(taskID)
    }

    var body: some View {
        if let task {
            ScrollView {
                VStack(spacing: 14) {
                    SheetHeader(task: task, model: model, dismiss: dismiss)
                    sheetContent(task)
                    progressSection(task)
                    footer(task)
                }
                .padding(.horizontal, 16)
                .padding(.top, 18)
                .padding(.bottom, 16)
                .onGeometryChange(for: CGFloat.self) { proxy in
                    proxy.size.height
                } action: { height in
                    measuredContentHeight = height
                    selectedDetent = .height(sheetHeight(for: height, task: task))
                }
            }
            .scrollIndicators(.hidden)
            .presentationCornerRadius(46)
            .presentationDetents([.height(sheetHeight(for: measuredContentHeight, task: task)), .large], selection: $selectedDetent)
            .presentationDragIndicator(.hidden)
        }
    }

    private func sheetHeight(for contentHeight: CGFloat, task: AgentTask) -> CGFloat {
        if task.status == .needs, !isPickOne(task) {
            return 750
        }
        let maximum: CGFloat = task.status == .needs ? 720 : 680
        return min(max(contentHeight, 320), maximum)
    }

    @ViewBuilder
    private func sheetContent(_ task: AgentTask) -> some View {
        if task.isArchived {
            DonePlatter(task: task, isPast: true)
            if let repeatLabel = task.repeatLabel {
                FilledCapsuleButton(title: repeatLabel, color: task.character.palette.accent, height: Theme.Size.sheetPrimaryButtonHeight) { model.repeatTask(task) }
            }
        } else {
            switch task.status {
            case .needs:
                if let question = task.question { QuestionPlatter(task: task, question: question, model: model) }
            case .ready:
                ResultPlatter(task: task, model: model)
            case .working, .scheduled:
                WorkingPlatter(task: task)
            case .done:
                DonePlatter(task: task, isPast: false)
            }
        }
    }

    @ViewBuilder
    private func progressSection(_ task: AgentTask) -> some View {
        if !task.steps.isEmpty {
            if (task.status == .working || (task.status == .needs && !isPickOne(task))) || progressExpanded {
                ProgressTimeline(task: task)
            } else {
                Button {
                    withAnimation(.easeInOut) { progressExpanded.toggle() }
                } label: {
                    HStack {
                        Text(task.status == .needs ? "What I've done so far · \(task.stepIndex) of \(task.steps.count) steps" : "How I found this · \(task.steps.count) steps")
                            .sproutFont(14, weight: .medium)
                        Spacer()
                        Image(systemName: "chevron.down").sproutFont(13, weight: .bold).foregroundStyle(Theme.textMuted)
                    }
                    .foregroundStyle(Theme.inkSecondary)
                    .padding(.horizontal, 18).frame(height: 50)
                }
                .buttonStyle(.glass)
                .buttonBorderShape(.capsule)
            }
        }
    }

    @ViewBuilder
    private func footer(_ task: AgentTask) -> some View {
        if task.isArchived {
            GlassCapsuleButton(title: "Back to history") { dismiss() }
        } else {
            switch task.status {
            case .working, .needs:
                GlassCapsuleButton(title: "Stop task", foreground: Theme.destructive) { model.stop(task) }
            case .ready:
                GlassCapsuleButton(title: "Not now") { dismiss() }
            case .done:
                GlassCapsuleButton(title: "Close") { dismiss() }
            case .scheduled:
                GlassCapsuleButton(title: "Stop task", foreground: Theme.destructive) { model.stop(task) }
            }
        }
    }

    private func isPickOne(_ task: AgentTask) -> Bool {
        guard case .pickOne = task.question else { return false }
        return true
    }
}

private struct SheetHeader: View {
    let task: AgentTask
    let model: AppModel
    let dismiss: DismissAction

    var body: some View {
        VStack(spacing: 6) {
            GlassEffectContainer(spacing: 16) {
                ZStack {
                    HStack {
                        GlassIconButton(systemName: "xmark", label: "Close") { dismiss() }
                        Spacer()
                        GlassIconButton(systemName: "bubble.left", label: "See it in chat") {
                            dismiss()
                            model.mode = .chat
                        }
                    }
                    FullMascotView(
                        character: task.character,
                        mood: task.status.mood,
                        width: Theme.Size.mascotInSheet
                    )
                }
            }
            .frame(height: 120)
            Text(task.title)
                .sproutFont(23, weight: .bold)
                .multilineTextAlignment(.center)
            HStack(spacing: 10) {
                StatusPill(status: task.status, character: task.character)
                Text(task.isArchived ? "Finished \(task.dateLabel ?? "")" : "Started \(task.timeLabel)")
                    .sproutFont(12, weight: .medium).foregroundStyle(Theme.textMuted)
            }
        }
    }
}

private struct QuestionPlatter: View {
    let task: AgentTask
    let question: TaskQuestion
    let model: AppModel
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        Platter {
            switch question {
            case .options(let prompt, let note, let primary, let secondary, let tertiary):
                VStack(alignment: .leading, spacing: 10) {
                    eyebrow
                    Text(prompt).sproutFont(21, weight: .semibold).foregroundStyle(Theme.ink)
                    Text(note).sproutFont(14).foregroundStyle(Theme.textMuted)
                    Group {
                        if dynamicTypeSize.isAccessibilitySize {
                            VStack(spacing: 8) {
                                FilledCapsuleButton(title: primary, color: task.character.palette.accent) { model.answer(task, choice: primary) }
                                GlassCapsuleButton(title: secondary) { model.answer(task, choice: secondary) }
                            }
                        } else {
                            HStack(spacing: 8) {
                                FilledCapsuleButton(title: primary, color: task.character.palette.accent) { model.answer(task, choice: primary) }
                                GlassCapsuleButton(title: secondary) { model.answer(task, choice: secondary) }
                            }
                        }
                    }
                    if let tertiary {
                        Button { model.answer(task, choice: tertiary) } label: {
                            Text(tertiary)
                                .sproutFont(14, weight: .medium)
                                .foregroundStyle(Theme.inkSecondary)
                                .padding(.horizontal, 16)
                                .padding(.vertical, dynamicTypeSize.isAccessibilitySize ? 6 : 0)
                                .frame(minHeight: Theme.Size.compactControlHeight)
                                .glassEffect(.regular.interactive(), in: .capsule)
                                .minimumTouchTarget()
                        }
                        .buttonStyle(.plain)
                        .fixedSize(horizontal: true, vertical: false)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, dynamicTypeSize.isAccessibilitySize ? 0 : (Theme.Size.compactControlHeight - Theme.Size.minTouchTarget) / 2)
                    }
                }
            case .pickOne(let prompt, let note, let choices):
                VStack(alignment: .leading, spacing: 13) {
                    eyebrow
                    Text(prompt).sproutFont(21, weight: .semibold).foregroundStyle(Theme.ink)
                    Text(note).sproutFont(14).foregroundStyle(Theme.textMuted)
                    ForEach(choices) { choice in
                        Button { model.answer(task, choice: choice.name) } label: {
                            choiceRow(choice)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private var eyebrow: some View {
        Text("\(task.character.displayName.uppercased()) ASKS")
            .sproutFont(12, weight: .semibold).tracking(0.6)
            .foregroundStyle(task.character.palette.accent)
    }

    @ViewBuilder
    private func choiceRow(_ choice: Choice) -> some View {
        if dynamicTypeSize.isAccessibilitySize {
            VStack(alignment: .leading, spacing: 8) {
                HStack(alignment: .top, spacing: 12) {
                    CakeIllustration(choice: choice)
                    choiceDescription(choice)
                }
                HStack(spacing: 8) {
                    Text(choice.tag)
                        .sproutFont(12, weight: .medium)
                        .foregroundStyle(task.character.palette.accent)
                    Spacer()
                    Text(choice.price).sproutFont(14, weight: .semibold).foregroundStyle(Theme.ink)
                    Image(systemName: "chevron.right").sproutFont(13, weight: .bold).foregroundStyle(Theme.textFaint)
                }
            }
        } else {
            HStack(spacing: 12) {
                CakeIllustration(choice: choice)
                choiceDescription(choice)
                Spacer(minLength: 4)
                Text(choice.price).sproutFont(14, weight: .semibold).foregroundStyle(Theme.ink)
                Image(systemName: "chevron.right").sproutFont(13, weight: .bold).foregroundStyle(Theme.textFaint)
            }
        }
    }

    private func choiceDescription(_ choice: Choice) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(choice.name).sproutFont(15, weight: .semibold).foregroundStyle(Theme.ink).lineLimit(2)
            Text(choice.detail)
                .sproutFont(12)
                .foregroundStyle(Theme.textMuted)
                .lineLimit(dynamicTypeSize.isAccessibilitySize ? 3 : 2)
            if !dynamicTypeSize.isAccessibilitySize {
                Text(choice.tag).sproutFont(12, weight: .medium).foregroundStyle(task.character.palette.accent)
            }
        }
    }
}

private struct ResultPlatter: View {
    let task: AgentTask
    let model: AppModel

    var body: some View {
        VStack(spacing: 12) {
            Platter {
                VStack(alignment: .leading, spacing: 12) {
                    Text((task.resultLabel ?? "RESULT").uppercased())
                        .sproutFont(12, weight: .semibold).tracking(0.6).foregroundStyle(task.character.palette.accent)
                    Text(task.line).sproutFont(21, weight: .semibold).foregroundStyle(Theme.ink)
                    FieldRows(fields: task.fields)
                }
            }
            FilledCapsuleButton(title: task.actionLabel ?? "Confirm", color: task.character.palette.accent, height: Theme.Size.sheetPrimaryButtonHeight) { model.confirm(task) }
            if let note = task.afterNote {
                Text(note).sproutFont(12).foregroundStyle(Theme.textMuted)
            }
        }
    }
}

private struct WorkingPlatter: View {
    let task: AgentTask
    var body: some View {
        Platter {
            VStack(alignment: .leading, spacing: 14) {
                Text(task.line).sproutFont(18, weight: .semibold)
                ProgressView(value: task.progress).tint(task.character.palette.accent)
                Text("Nothing needed from you. I'll tell you when it's ready.")
                    .sproutFont(14).foregroundStyle(Theme.textMuted)
            }
        }
    }
}

private struct DonePlatter: View {
    let task: AgentTask
    let isPast: Bool
    var body: some View {
        Platter {
            VStack(alignment: .leading, spacing: 14) {
                HStack(spacing: 14) {
                    Image(systemName: "checkmark")
                        .sproutFont(20, weight: .bold).foregroundStyle(.white)
                        .frame(width: 48, height: 48).background(task.character.palette.accent, in: Circle())
                    VStack(alignment: .leading, spacing: 3) {
                        Text(task.doneLine ?? task.line).sproutFont(19, weight: .semibold)
                        Text(isPast ? "Finished \(task.dateLabel ?? "")" : "All set. Nothing else to do.").sproutFont(14).foregroundStyle(Theme.textMuted)
                    }
                }
                FieldRows(fields: task.fields)
            }
        }
    }
}

private struct FieldRows: View {
    let fields: [ResultField]
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        Group {
            if dynamicTypeSize.isAccessibilitySize {
                rows(stacked: true)
            } else {
                ViewThatFits(in: .horizontal) {
                    rows(stacked: false)
                    rows(stacked: true)
                }
            }
        }
    }

    private func rows(stacked: Bool) -> some View {
        VStack(spacing: 0) {
            ForEach(Array(fields.enumerated()), id: \.offset) { index, field in
                if index > 0 { Divider().overlay(Theme.hairline) }
                Group {
                    if stacked {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(field.label).foregroundStyle(Theme.textMuted)
                            Text(field.value).fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    } else {
                        HStack(alignment: .firstTextBaseline) {
                            Text(field.label).foregroundStyle(Theme.textMuted)
                            Spacer()
                            Text(field.value)
                                .fontWeight(.semibold)
                                .multilineTextAlignment(.trailing)
                                .fixedSize(horizontal: true, vertical: false)
                        }
                    }
                }
                .sproutFont(14)
                .padding(.vertical, 11)
            }
        }
    }
}

private struct ProgressTimeline: View {
    let task: AgentTask

    var body: some View {
        Platter {
            VStack(alignment: .leading, spacing: 0) {
                Text("PROGRESS").sproutFont(12, weight: .semibold).tracking(0.6).foregroundStyle(Theme.textMuted)
                    .padding(.bottom, 16)
                ForEach(Array(task.steps.enumerated()), id: \.offset) { index, step in
                    HStack(alignment: .top, spacing: 13) {
                        VStack(spacing: 0) {
                            ZStack {
                                if index < task.stepIndex {
                                    Circle().fill(Theme.ink)
                                    Image(systemName: "checkmark").sproutFont(8, weight: .bold).foregroundStyle(.white)
                                } else if index == task.stepIndex {
                                    Circle().fill(task.character.palette.tint).frame(width: 30, height: 30)
                                    Circle().fill(task.character.palette.accent).frame(width: 15, height: 15)
                                } else {
                                    Circle().stroke(Theme.textFaint.opacity(0.55), style: StrokeStyle(lineWidth: 1.5, dash: [4, 3]))
                                }
                            }
                            .frame(width: 24, height: 24)
                            if index < task.steps.count - 1 {
                                Rectangle()
                                    .fill(Theme.hairline.opacity(1.5))
                                    .frame(width: 2, height: 12)
                            }
                        }
                        Text(step)
                            .sproutFont(14, weight: index == task.stepIndex ? .semibold : .regular)
                            .foregroundStyle(index > task.stepIndex ? Theme.textFaint : Theme.ink)
                            .padding(.bottom, index < task.steps.count - 1 ? 12 : 0)
                    }
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel(step)
                    .accessibilityValue(accessibilityState(for: index))
                }
            }
        }
    }

    private func accessibilityState(for index: Int) -> String {
        if index < task.stepIndex { return "Completed" }
        if index == task.stepIndex { return "In progress" }
        return "Not started"
    }
}

#Preview("07 Needs answer") {
    let model = AppModel()
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
    return TaskSheet(taskID: task.id, model: model)
}
