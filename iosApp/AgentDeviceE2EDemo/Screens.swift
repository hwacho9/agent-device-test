import SwiftUI

private struct ScreenFrame<Content: View>: View {
    let step: String
    @ViewBuilder let content: () -> Content
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                Text("AGENT DEVICE / DEMO").font(.caption.bold()).foregroundStyle(.tint)
                Text(step).font(.caption).foregroundStyle(.secondary)
                Spacer().frame(height: 12)
                content()
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(28)
        }
        .background(Color(uiColor: .systemBackground))
    }
}

struct LoginScreen: View {
    @Binding var email: String
    @Binding var password: String
    var error: String? = nil
    var onLogin: () -> Void = {}
    var body: some View {
        ScreenFrame(step: "01 / SIGN IN") {
            Text("Welcome back").font(.largeTitle.bold())
            Text("A small app. A complete automation story.").foregroundStyle(.secondary)
            TextField("Email", text: $email)
                .keyboardType(.emailAddress).textInputAutocapitalization(.never).autocorrectionDisabled()
                .textFieldStyle(.roundedBorder).accessibilityIdentifier("login.email").accessibilityLabel("Email")
            SecureField("Password", text: $password)
                .textFieldStyle(.roundedBorder).accessibilityIdentifier("login.password").accessibilityLabel("Password")
            if let error { Text(error).foregroundStyle(.red).accessibilityIdentifier("login.error") }
            Button(action: onLogin) { Text("Login").frame(maxWidth: .infinity) }
                .buttonStyle(.borderedProminent).controlSize(.large)
                .tint(Color(red: 37.0 / 255.0, green: 99.0 / 255.0, blue: 235.0 / 255.0))
                .accessibilityIdentifier("login.submit")
            Text("Demo account: demo@example.com").font(.footnote).foregroundStyle(.secondary)
        }
    }
}

struct HomeScreen: View {
    var onProfile: () -> Void = {}
    var body: some View {
        ScreenFrame(step: "02 / HOME") {
            Text("Hello, Demo User").font(.largeTitle.bold()).accessibilityAddTraits(.isHeader).accessibilityIdentifier("home.title")
            Text("Your next step starts here.").foregroundStyle(.secondary)
            Button(action: onProfile) { Text("Open Profile").frame(maxWidth: .infinity) }
                .buttonStyle(.borderedProminent).controlSize(.large).accessibilityIdentifier("home.profile")
            Divider()
            Text("Powered by Kotlin Multiplatform shared business logic.").font(.footnote).foregroundStyle(.secondary)
        }
    }
}

struct ProfileScreen: View {
    var name = "Demo User"
    @Binding var reminders: Bool
    var saved = false
    var onSave: () -> Void = {}
    var body: some View {
        ScreenFrame(step: "03 / PROFILE") {
            Text("Profile").font(.largeTitle.bold()).accessibilityAddTraits(.isHeader).accessibilityIdentifier("profile.title")
            Text(name).font(.title2.bold()).accessibilityIdentifier("profile.name")
            HStack {
                Text("Workout reminders").fixedSize(horizontal: false, vertical: true)
                Spacer(minLength: 12)
                Toggle("Workout reminders", isOn: $reminders)
                    .labelsHidden()
                    .accessibilityIdentifier("profile.reminder")
                    .accessibilityLabel("Workout reminders")
            }
            Button(action: onSave) { Text("Save").frame(maxWidth: .infinity) }
                .buttonStyle(.borderedProminent).controlSize(.large).accessibilityIdentifier("profile.save")
            if saved { Text("Saved").font(.headline).foregroundStyle(.tint).accessibilityIdentifier("profile.saved") }
        }
    }
}

#Preview("Login") { LoginScreen(email: .constant(""), password: .constant("")) }
#Preview("Home") { HomeScreen() }
#Preview("Profile") { ProfileScreen(reminders: .constant(false)) }
