import SwiftUI

struct StatusPill: View {
    let text: String
    let color: Color
    var symbol: String? = nil

    var body: some View {
        HStack(spacing: 4) {
            if let symbol {
                Image(systemName: symbol).font(.caption2.weight(.bold))
            }
            Text(text)
                .font(.caption.weight(.bold))
                .textCase(.uppercase)
                .tracking(0.5)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .foregroundStyle(color)
        .background(color.opacity(0.16))
        .clipShape(.capsule)
        .overlay(Capsule().stroke(color.opacity(0.4), lineWidth: 1))
    }
}

extension EquipmentStatus {
    var color: Color {
        switch self {
        case .running: return Theme.success
        case .down: return Theme.danger
        case .maintenance: return Theme.primary
        }
    }
    var symbol: String {
        switch self {
        case .running: return "checkmark.circle.fill"
        case .down: return "exclamationmark.triangle.fill"
        case .maintenance: return "wrench.adjustable.fill"
        }
    }
}

struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline.weight(.bold))
            .foregroundStyle(Theme.onPrimary)
            .frame(maxWidth: .infinity)
            .frame(minHeight: 56)
            .background(Theme.primary)
            .clipShape(.rect(cornerRadius: 14))
            .opacity(configuration.isPressed ? 0.85 : 1)
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(.spring(response: 0.25, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline.weight(.semibold))
            .foregroundStyle(Theme.textPrimary)
            .frame(maxWidth: .infinity)
            .frame(minHeight: 52)
            .background(Theme.surfaceElevated)
            .clipShape(.rect(cornerRadius: 14))
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(Theme.strokeStrong, lineWidth: 1))
            .opacity(configuration.isPressed ? 0.85 : 1)
    }
}

struct HazardStripeBanner: View {
    let title: String

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.title3.weight(.black))
            Text(title)
                .font(.subheadline.weight(.heavy))
                .textCase(.uppercase)
                .tracking(1)
            Spacer()
        }
        .foregroundStyle(.black)
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(
            ZStack {
                Theme.primary
                StripePattern()
                    .fill(Color.black.opacity(0.18))
            }
        )
        .clipShape(.rect(cornerRadius: 10))
    }
}

struct StripePattern: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let stripeWidth: CGFloat = 14
        let spacing: CGFloat = 14
        var x: CGFloat = -rect.height
        while x < rect.width + rect.height {
            path.move(to: CGPoint(x: x, y: 0))
            path.addLine(to: CGPoint(x: x + stripeWidth, y: 0))
            path.addLine(to: CGPoint(x: x + stripeWidth + rect.height, y: rect.height))
            path.addLine(to: CGPoint(x: x + rect.height, y: rect.height))
            path.closeSubpath()
            x += stripeWidth + spacing
        }
        return path
    }
}

struct AIModeBadge: View {
    let mode: AIMode

    var color: Color {
        switch mode {
        case .online: return Theme.info
        case .offline: return Theme.primary
        case .auto: return Theme.textSecondary
        }
    }

    var symbol: String {
        switch mode {
        case .online: return "cloud.fill"
        case .offline: return "iphone.gen3"
        case .auto: return "antenna.radiowaves.left.and.right"
        }
    }

    var label: String {
        switch mode {
        case .online: return "Cloud AI"
        case .offline: return "On-Device"
        case .auto: return "Auto"
        }
    }

    var body: some View {
        StatusPill(text: label, color: color, symbol: symbol)
    }
}

struct SectionHeader: View {
    let number: String
    let title: String
    let symbol: String

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Theme.primary)
                    .frame(width: 32, height: 32)
                Image(systemName: symbol)
                    .font(.system(size: 16, weight: .black))
                    .foregroundStyle(Theme.onPrimary)
            }
            VStack(alignment: .leading, spacing: 0) {
                Text(number)
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(Theme.textTertiary)
                    .tracking(1)
                Text(title)
                    .font(.headline.weight(.heavy))
                    .foregroundStyle(Theme.textPrimary)
                    .textCase(.uppercase)
                    .tracking(0.5)
            }
            Spacer()
        }
    }
}

struct EmptyStateView: View {
    let symbol: String
    let title: String
    let message: String

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: symbol)
                .font(.system(size: 44, weight: .light))
                .foregroundStyle(Theme.textTertiary)
            Text(title)
                .font(.headline.weight(.bold))
                .foregroundStyle(Theme.textPrimary)
            Text(message)
                .font(.subheadline)
                .foregroundStyle(Theme.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }
}
