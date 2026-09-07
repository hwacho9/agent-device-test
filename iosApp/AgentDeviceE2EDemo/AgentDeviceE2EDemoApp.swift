import SwiftUI
import Shared

@main
struct AgentDeviceE2EDemoApp: App {
    @StateObject private var model = DemoModel()
    var body: some Scene {
        WindowGroup {
            Group {
                switch model.screen {
                case .login:
                    LoginScreen(email: $model.email, password: $model.password, error: model.error, onLogin: model.login)
                case .home:
                    HomeScreen { model.screen = .profile }
                case .profile:
                    ProfileScreen(name: model.name, reminders: Binding(get: { model.reminders }, set: model.setReminders), saved: model.saved, onSave: model.save)
                }
            }
            .tint(Color(red: 0, green: 0.42, blue: 0.37))
            .environment(\.locale, Locale(identifier: "en_US_POSIX"))
            .transaction { $0.disablesAnimations = true }
        }
    }
}

@MainActor
final class DemoModel: ObservableObject {
    enum Screen { case login, home, profile }
    private let session = DemoSession()
    @Published var screen: Screen = .login
    @Published var email = ""
    @Published var password = ""
    @Published var error: String?
    @Published private(set) var name = ""
    @Published private(set) var reminders = false
    @Published private(set) var saved = false
    init() { refreshProfile() }
    func login() {
        if session.login(email: email, password: password) { screen = .home }
        error = session.loginError
    }
    func setReminders(_ enabled: Bool) {
        session.setReminders(enabled: enabled)
        refreshProfile()
    }
    func save() { session.saveProfile(); refreshProfile() }
    private func refreshProfile() {
        name = session.profile.name
        reminders = session.profile.remindersEnabled
        saved = session.profile.saved
    }
}
