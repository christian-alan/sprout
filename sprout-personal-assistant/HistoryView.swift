import SwiftUI

struct HistoryView: View {
    let model: AppModel
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    private let months: [(String, String?)] = [("All", nil), ("Oct", "October"), ("Sep", "September"), ("Aug", "August"), ("Jul", "July"), ("Jun", "June"), ("May", "May")]

    var body: some View {
        ZStack {
            Theme.stage.ignoresSafeArea()
            Circle().fill(MascotCharacter.clover.palette.tint).frame(width: 300).blur(radius: 65).offset(x: -170, y: -380)
            Circle().fill(MascotCharacter.bloom.palette.tint).frame(width: 300).blur(radius: 65).offset(x: 175, y: -390)
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    title
                    searchField
                    monthChips
                    if model.filteredHistory.isEmpty { emptyState }
                    else { historyGroups }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 32)
            }
            .scrollIndicators(.hidden)
            .scrollEdgeEffectStyle(.soft, for: .top)
        }
        .safeAreaInset(edge: .top, spacing: 0) {
            header
                .padding(.horizontal, 16)
        }
    }

    private var header: some View {
        HStack {
            GlassIconButton(systemName: "chevron.left", label: "Back to tasks") { model.mode = .tasks }
            Spacer()
            MascotView(character: .sprout, mood: .idle, style: .head).frame(width: 42, height: 42)
        }
        .padding(.top, 8)
    }

    private var title: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("History")
                .sproutFont(32, weight: .bold)
                .tracking(-0.8)
                .foregroundStyle(Theme.ink)
            if model.historyQuery.isEmpty {
                Text("\(model.archivedTasks.count) tasks · last 6 months")
            } else {
                Text("\(model.filteredHistory.count) results for \"\(model.historyQuery)\"")
            }
        }
        .sproutFont(14)
        .foregroundStyle(Theme.textMuted)
    }

    private var searchField: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass").sproutFont(18, weight: .medium).foregroundStyle(Theme.textMuted)
            TextField(
                text: Binding(get: { model.historyQuery }, set: { model.historyQuery = $0 }),
                prompt: Text("Search past tasks").foregroundStyle(Theme.textMuted)
            ) { EmptyView() }
                .sproutFont(16)
            if !model.historyQuery.isEmpty {
                Button { model.historyQuery = "" } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(Theme.textFaint)
                        .minimumTouchTarget()
                }.accessibilityLabel("Clear search")
            }
        }
        .padding(.horizontal, 16)
        .frame(minHeight: 50)
        .padding(.vertical, dynamicTypeSize.isAccessibilitySize ? 5 : 0)
        .glassEffect(.regular.interactive(), in: .capsule)
    }

    private var monthChips: some View {
        ScrollView(.horizontal) {
            GlassEffectContainer(spacing: 7) {
                HStack(spacing: 7) {
                    ForEach(months, id: \.0) { label, month in
                        MonthChip(label: label, month: month, isSelected: model.historyMonth == month) {
                            withAnimation(.easeInOut(duration: 0.2)) { model.historyMonth = month }
                        }
                    }
                }
            }
        }
        .scrollIndicators(.hidden)
    }

    private var historyGroups: some View {
        VStack(spacing: 24) {
            ForEach(model.historyGroups, id: \.0) { month, tasks in
                VStack(spacing: 9) {
                    HStack {
                        Text(month).sproutFont(20, weight: .bold)
                        Spacer()
                        Text("\(tasks.count) tasks").sproutFont(12, weight: .medium).foregroundStyle(Theme.textMuted)
                    }
                    VStack(spacing: 0) {
                        ForEach(Array(tasks.enumerated()), id: \.element.id) { index, task in
                            if index > 0 { Divider().overlay(Theme.hairline).padding(.leading, 62) }
                            HistoryRow(task: task, model: model)
                        }
                    }
                    .background(.white.opacity(0.64), in: RoundedRectangle(cornerRadius: Theme.Radius.platter, style: .continuous))
                    .overlay(RoundedRectangle(cornerRadius: Theme.Radius.platter, style: .continuous).stroke(.white.opacity(0.85)))
                }
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            FullMascotView(character: .sprout, mood: .needs, width: 130)
            Text("Nothing matches \"\(model.historyQuery)\"").sproutFont(21, weight: .semibold).multilineTextAlignment(.center)
            Text("Sprout can look further back, or in places search doesn't reach.")
                .sproutFont(14).foregroundStyle(Theme.textMuted).multilineTextAlignment(.center)
            Button("Ask Sprout") { model.askAboutEmptyHistory() }
                .sproutFont(15, weight: .semibold).foregroundStyle(.white)
                .padding(.horizontal, 28).frame(height: 48).background(Theme.ink, in: Capsule())
                .buttonStyle(.plain)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 32)
    }
}

private struct MonthChip: View {
    let label: String
    let month: String?
    let isSelected: Bool
    let action: () -> Void
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        Button(action: action) {
            Group {
                if isSelected {
                    labelView
                        .foregroundStyle(.white)
                        .background(Theme.ink, in: Capsule())
                } else {
                    labelView
                        .foregroundStyle(Theme.ink)
                        .glassEffect(.regular.interactive(), in: .capsule)
                }
            }
            .minimumTouchTarget()
        }
        .buttonStyle(.plain)
        .padding(.vertical, (Theme.Size.compactControlHeight - Theme.Size.minTouchTarget) / 2)
    }

    private var labelView: some View {
        Text(label)
            .sproutFont(13, weight: .semibold)
            .padding(.horizontal, 16)
            .padding(.vertical, dynamicTypeSize.isAccessibilitySize ? 6 : 0)
            .frame(minHeight: Theme.Size.compactControlHeight)
    }
}

private struct HistoryRow: View {
    let task: AgentTask
    let model: AppModel
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        Button { model.showTask(task.id) } label: {
            HStack(spacing: 12) {
                MascotView(character: task.character, mood: .asleep, style: .head)
                    .padding(5).frame(width: Theme.Size.historyHeadTile, height: Theme.Size.historyHeadTile)
                    .background(task.character.palette.tint, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                VStack(alignment: .leading, spacing: 3) {
                    Text(task.title)
                        .sproutFont(15, weight: .semibold)
                        .foregroundStyle(Theme.ink)
                        .lineLimit(dynamicTypeSize.isAccessibilitySize ? 2 : 1)
                    Text(task.line)
                        .sproutFont(13)
                        .foregroundStyle(Theme.textMuted)
                        .lineLimit(dynamicTypeSize.isAccessibilitySize ? 2 : 1)
                }
                Spacer(minLength: 6)
                VStack(alignment: .trailing, spacing: 5) {
                    Text(task.dateLabel ?? "").sproutFont(12).foregroundStyle(Theme.textMuted)
                    Text(task.category ?? "Task")
                        .sproutFont(11, weight: .semibold).foregroundStyle(Theme.inkSecondary)
                        .padding(.horizontal, 8).padding(.vertical, 3)
                        .background(task.character.palette.tint, in: Capsule())
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, dynamicTypeSize.isAccessibilitySize ? 8 : 0)
            .frame(minHeight: dynamicTypeSize.isAccessibilitySize ? 80 : Theme.Size.historyRowHeight)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(task.title), \(task.dateLabel ?? ""), \(task.category ?? "Task")")
        .accessibilityValue(task.line)
        .accessibilityHint("Opens task details")
    }
}

#Preview("12 History") {
    HistoryView(model: AppModel())
}
