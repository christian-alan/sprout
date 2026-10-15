import SwiftUI

struct RootView: View {
    let model: AppModel
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    private var presentedTask: Binding<AgentTask?> {
        Binding(
            get: { model.openTask },
            set: { newValue in
                model.openTaskID = newValue?.id
                if newValue == nil { model.openTaskSource = nil }
            }
        )
    }

    var body: some View {
        ZStack {
            Group {
                switch model.mode {
                case .chat: ChatView(model: model).transition(.opacity)
                case .tasks: TasksView(model: model).transition(.move(edge: .bottom).combined(with: .opacity))
                case .history: HistoryView(model: model).transition(.move(edge: .trailing).combined(with: .opacity))
                }
            }
            if let task = model.openTask {
                ZStack {
                    task.character.palette.tint.opacity(0.55)
                    RadialGradient(
                        colors: [task.character.palette.accent.opacity(0.18), .clear],
                        center: .top,
                        startRadius: 0,
                        endRadius: 420
                    )
                }
                .ignoresSafeArea()
                .allowsHitTesting(false)
                .transition(.opacity)
            }
        }
        .animation(reduceMotion ? nil : .easeInOut(duration: 0.3), value: model.mode)
        .animation(reduceMotion ? nil : .easeInOut(duration: 0.25), value: model.openTaskID)
        .sensoryFeedback(.impact(weight: .light), trigger: model.needsFeedbackToken)
        .sensoryFeedback(.success, trigger: model.successFeedbackToken)
        .sheet(item: presentedTask) { task in
            TaskSheet(taskID: task.id, model: model)
                .environment(\.dynamicTypeSize, dynamicTypeSize)
                .presentationBackgroundInteraction(.enabled)
        }
        .tint(Theme.ink)
        .preferredColorScheme(.light)
    }
}
