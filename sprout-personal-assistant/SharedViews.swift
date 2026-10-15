import SwiftUI

enum MascotStyle { case full, head }

private struct SproutScaledFontModifier: ViewModifier {
    @ScaledMetric private var scaledSize: CGFloat
    let weight: Font.Weight

    init(size: CGFloat, weight: Font.Weight, relativeTo textStyle: Font.TextStyle) {
        _scaledSize = ScaledMetric(wrappedValue: size, relativeTo: textStyle)
        self.weight = weight
    }

    func body(content: Content) -> some View {
        content.font(.system(size: scaledSize, weight: weight))
    }
}

extension View {
    func sproutFont(
        _ size: CGFloat,
        weight: Font.Weight = .regular,
        relativeTo textStyle: Font.TextStyle = .body
    ) -> some View {
        modifier(SproutScaledFontModifier(size: size, weight: weight, relativeTo: textStyle))
    }

    func minimumTouchTarget() -> some View {
        frame(minWidth: Theme.Size.minTouchTarget, minHeight: Theme.Size.minTouchTarget)
            .contentShape(Rectangle())
    }
}

struct FullMascotView: View {
    let character: MascotCharacter
    let mood: Mood
    let width: CGFloat

    var body: some View {
        MascotView(character: character, mood: mood)
            .frame(width: width, height: width * 1.25)
    }
}

struct MascotView: View {
    let character: MascotCharacter
    let mood: Mood
    var style: MascotStyle = .full
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var breathing = false

    private var assetName: String {
        "\(character.rawValue)-\(mood.rawValue)\(style == .head ? "-head" : "")"
    }

    var body: some View {
        ZStack {
            Image(assetName)
                .resizable()
                .scaledToFit()
                .id(assetName)
                .transition(.opacity)
        }
            .scaleEffect(!reduceMotion && (mood == .idle || mood == .working) && breathing ? 1.02 : 1)
            .animation(
                reduceMotion || (mood != .idle && mood != .working)
                    ? nil
                    : .easeInOut(duration: mood == .working ? 2 : 3).repeatForever(autoreverses: true),
                value: breathing
            )
            .animation(reduceMotion ? nil : .easeInOut(duration: 0.22), value: assetName)
            .accessibilityLabel("\(character.displayName), \(mood == .needs ? "needs you" : mood.rawValue)")
            .onAppear { breathing = true }
    }
}

struct StatusPill: View {
    let status: TaskStatus
    let character: MascotCharacter

    var body: some View {
        Group {
            if status == .needs {
                label
                    .foregroundStyle(.white)
                    .background(character.palette.accent, in: Capsule())
            } else {
                label
                    .foregroundStyle(Theme.ink)
                    .glassEffect(.regular, in: .capsule)
            }
        }
        .accessibilityElement(children: .combine)
    }

    private var label: some View {
        HStack(spacing: 7) {
            Circle()
                .fill(status == .needs ? .white : dotColor)
                .frame(width: 7, height: 7)
            Text(status.label)
                .sproutFont(12, weight: .semibold)
        }
        .padding(.horizontal, 14)
        .frame(height: Theme.Size.statusPillHeight)
    }

    private var dotColor: Color {
        switch status {
        case .ready: Theme.ready
        case .working: Color(hex: "2F7CF6")
        case .scheduled, .done: Color(hex: "B0AAA3")
        case .needs: .white
        }
    }
}

struct GlassIconButton: View {
    let systemName: String
    let label: String
    var size: CGFloat = Theme.Size.minTouchTarget
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: size * 0.42, weight: .semibold))
                .foregroundStyle(Theme.ink)
                .frame(width: size, height: size)
        }
        .buttonStyle(.glass)
        .buttonBorderShape(.circle)
        .accessibilityLabel(label)
    }
}

struct FilledCapsuleButton: View {
    let title: String
    let color: Color
    var height: CGFloat = Theme.Size.primaryButtonHeight
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .sproutFont(height > 50 ? 17 : 15, weight: .semibold)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: height)
        }
        .buttonStyle(.glassProminent)
        .buttonBorderShape(.capsule)
        .tint(color)
        .frame(height: height)
        .shadow(color: color.opacity(0.22), radius: 12, y: 6)
    }
}

struct GlassCapsuleButton: View {
    let title: String
    var foreground: Color = Theme.ink
    var height: CGFloat = 48
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .sproutFont(15, weight: .semibold)
                .foregroundStyle(foreground)
                .frame(maxWidth: .infinity)
                .frame(height: height)
        }
        .buttonStyle(.glass)
        .buttonBorderShape(.capsule)
        .frame(height: height)
    }
}

struct Platter<Content: View>: View {
    @ViewBuilder var content: Content

    var body: some View {
        content
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.white.opacity(0.66), in: RoundedRectangle(cornerRadius: Theme.Radius.platter, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: Theme.Radius.platter, style: .continuous).stroke(.white.opacity(0.85), lineWidth: 1))
    }
}

struct CakeIllustration: View {
    let choice: Choice

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 13, style: .continuous)
                .fill(Color(hex: choice.backgroundHex))
            VStack(spacing: -2) {
                Capsule().fill(Color(hex: "FFB03B")).frame(width: 5, height: 15)
                    .overlay(alignment: .top) { Circle().fill(Color(hex: "FFB03B")).frame(width: 8, height: 8).offset(y: -3) }
                RoundedRectangle(cornerRadius: 6).fill(Color(hex: choice.topHex)).frame(width: 34, height: 17)
                RoundedRectangle(cornerRadius: 5).fill(Color(hex: choice.baseHex)).frame(width: 49, height: 18)
            }
        }
        .frame(width: 58, height: 58)
        .accessibilityHidden(true)
    }
}

struct TaskSceneBackground: View {
    let character: MascotCharacter

    var body: some View {
        RoundedRectangle(cornerRadius: Theme.Radius.taskCard, style: .continuous)
            .fill(LinearGradient(colors: [character.palette.tint, character.palette.mid], startPoint: .top, endPoint: .bottom))
            .overlay(alignment: .top) {
                Circle()
                    .fill(.white.opacity(0.78))
                    .frame(width: 230, height: 180)
                    .blur(radius: 42)
                    .offset(y: -55)
            }
            .overlay(alignment: .bottomLeading) {
                Circle().fill(character.palette.accent.opacity(0.35)).frame(width: 190).blur(radius: 42).offset(x: -60, y: 65)
            }
            .overlay(alignment: .bottomTrailing) {
                Circle().fill(character.palette.accent.opacity(0.3)).frame(width: 180).blur(radius: 38).offset(x: 70, y: 55)
            }
            .overlay(alignment: .center) {
                Ellipse()
                    .fill(.white.opacity(0.62))
                    .frame(width: 165, height: 34)
                    .blur(radius: 16)
                    .offset(y: 112)
            }
    }
}

extension View {
    @ViewBuilder
    func glassPanel(cornerRadius: CGFloat, interactive: Bool = false) -> some View {
        if interactive {
            self.glassEffect(.regular.interactive(), in: .rect(cornerRadius: cornerRadius))
        } else {
            self.glassEffect(.regular, in: .rect(cornerRadius: cornerRadius))
        }
    }
}
