import SwiftUI
import AuthenticationServices

struct LoginView: View {
    @Environment(AuthManager.self) private var auth
    @AppStorage("user.role") private var roleRaw: String = UserRole.technician.rawValue

    @State private var showEmailInfo = false

    private var role: UserRole { UserRole(rawValue: roleRaw) ?? .technician }

    var body: some View {
        @Bindable var auth = auth

        ZStack {
            Theme.bg.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 20) {
                    hero
                    roleCard
                    signInButtons
                    footnote
                }
                .padding(20)
            }
        }
        .preferredColorScheme(.dark)
        .alert("Sign-in error", isPresented: $auth.showError) {
            Button("OK") { }
        } message: {
            Text(auth.errorMessage)
        }
        .alert("Email & phone sign-in", isPresented: $showEmailInfo) {
            Button("OK") { }
        } message: {
            Text("Email and phone-number login need a connected backend for password and OTP security. Google and Apple sign-in are live now — tap either to get started.")
        }
    }

    private var hero: some View {
        VStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(Theme.primary.opacity(0.14))
                    .frame(width: 96, height: 96)
                Image(systemName: "bolt.gearshape.fill")
                    .font(.system(size: 44, weight: .black))
                    .foregroundStyle(Theme.primary)
            }
            .padding(.top, 24)

            Text("FixLine")
                .font(.system(size: 40, weight: .black))
                .foregroundStyle(Theme.textPrimary)

            Text("AI diagnostics for the plant floor.\nReduce MTTR. Stay safe.")
                .font(.subheadline)
                .foregroundStyle(Theme.textSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(.vertical, 24)
        .frame(maxWidth: .infinity)
    }

    private var roleCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("SIGNING IN AS")
                .font(.caption.weight(.heavy))
                .tracking(2)
                .foregroundStyle(Theme.textTertiary)

            ForEach(UserRole.allCases) { r in
                Button {
                    Haptics.tap()
                    roleRaw = r.rawValue
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: r.symbol)
                            .font(.title3.weight(.bold))
                            .foregroundStyle(role == r ? Theme.onPrimary : Theme.primary)
                            .frame(width: 38, height: 38)
                            .background(role == r ? Theme.primary : Theme.surfaceElevated)
                            .clipShape(.rect(cornerRadius: 10))
                        VStack(alignment: .leading, spacing: 2) {
                            Text(r.label)
                                .font(.subheadline.weight(.bold))
                                .foregroundStyle(Theme.textPrimary)
                            Text(r.description)
                                .font(.caption)
                                .foregroundStyle(Theme.textSecondary)
                                .multilineTextAlignment(.leading)
                        }
                        Spacer()
                        Image(systemName: role == r ? "checkmark.circle.fill" : "circle")
                            .font(.title3)
                            .foregroundStyle(role == r ? Theme.primary : Theme.textTertiary)
                    }
                    .padding(12)
                    .background(Theme.surfaceElevated)
                    .clipShape(.rect(cornerRadius: 12))
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(role == r ? Theme.primary.opacity(0.6) : Theme.stroke, lineWidth: 1))
                }
                .buttonStyle(.plain)
            }
        }
        .cardStyle()
    }

    private var signInButtons: some View {
        VStack(spacing: 12) {
            if auth.isSigningIn {
                ProgressView()
                    .controlSize(.large)
                    .tint(Theme.primary)
                    .frame(height: 120)
            } else {
                Button {
                    Haptics.tap()
                    Task { await auth.signIn(provider: "google") }
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: "globe")
                        Text("Continue with Google")
                    }
                }
                .buttonStyle(PrimaryButtonStyle())

                SignInWithAppleButton(.signIn) { request in
                    request.requestedScopes = [.email, .fullName]
                } onCompletion: { _ in
                    Task { await auth.signIn(provider: "apple") }
                }
                .frame(minHeight: 56)
                .clipShape(.rect(cornerRadius: 14))
                .disabled(auth.isSigningIn)

                Button {
                    Haptics.tap()
                    showEmailInfo = true
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: "envelope")
                        Text("Email or phone sign-in")
                    }
                }
                .buttonStyle(SecondaryButtonStyle())
            }
        }
        .padding(.top, 6)
    }

    private var footnote: some View {
        Text("Your role tier is set by your plant. Leads and management can upload equipment manuals for AI-assisted diagnosis.")
            .font(.caption)
            .foregroundStyle(Theme.textTertiary)
            .multilineTextAlignment(.center)
            .padding(.bottom, 24)
    }
}
