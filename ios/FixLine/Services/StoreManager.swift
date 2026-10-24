import Foundation
import SwiftUI
import Observation
import RevenueCat

enum SubscriptionTier: Int, Comparable, CaseIterable {
    case free = 0
    case starter = 1
    case basic = 2
    case advanced = 3
    case premium = 4

    static func < (lhs: SubscriptionTier, rhs: SubscriptionTier) -> Bool {
        lhs.rawValue < rhs.rawValue
    }

    var label: String {
        switch self {
        case .free: return "Free"
        case .starter: return "Starter"
        case .basic: return "Basic"
        case .advanced: return "Advanced"
        case .premium: return "Premium"
        }
    }

    var color: Color {
        switch self {
        case .free: return Theme.textSecondary
        case .starter: return Theme.info
        case .basic: return Theme.success
        case .advanced: return Theme.primary
        case .premium: return Theme.danger
        }
    }

    var symbol: String {
        switch self {
        case .free: return "person.crop.circle"
        case .starter: return "bolt.fill"
        case .basic: return "bolt.badge.checkmark"
        case .advanced: return "bolt.shield.fill"
        case .premium: return "bolt.crown.fill"
        }
    }
}

@Observable
@MainActor
final class StoreManager {
    var offerings: Offerings?
    var tier: SubscriptionTier = .free
    var isLoading = false
    var isPurchasing = false
    var errorMessage: String?

    init() {
        Task { await listenForUpdates() }
        Task { await refresh() }
    }

    var isSubscribed: Bool { tier != .free }

    private func listenForUpdates() async {
        for await info in Purchases.shared.customerInfoStream {
            tier = Self.tier(from: info)
        }
    }

    func refresh() async {
        isLoading = true
        defer { isLoading = false }
        do {
            offerings = try await Purchases.shared.offerings()
            let info = try await Purchases.shared.customerInfo()
            tier = Self.tier(from: info)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    nonisolated static func tier(from info: CustomerInfo) -> SubscriptionTier {
        if info.entitlements["premium"]?.isActive == true { return .premium }
        if info.entitlements["advanced"]?.isActive == true { return .advanced }
        if info.entitlements["basic"]?.isActive == true { return .basic }
        if info.entitlements["pro"]?.isActive == true { return .starter }
        if info.entitlements["starter"]?.isActive == true { return .starter }
        return .free
    }

    func purchase(package: Package) async {
        isPurchasing = true
        defer { isPurchasing = false }
        do {
            let result = try await Purchases.shared.purchase(package: package)
            if !result.userCancelled {
                tier = Self.tier(from: result.customerInfo)
                Haptics.success()
            }
        } catch ErrorCode.purchaseCancelledError {
            // user cancelled — not an error
        } catch ErrorCode.paymentPendingError {
            // awaiting approval — not a failure
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func restore() async {
        do {
            let info = try await Purchases.shared.restorePurchases()
            tier = Self.tier(from: info)
            Haptics.success()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
