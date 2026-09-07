package com.example.agentdevicee2edemo

import androidx.compose.foundation.isSystemInDarkTheme
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.material3.*
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.semantics.*
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.text.input.PasswordVisualTransformation
import androidx.compose.ui.unit.dp
import com.example.agentdevicee2edemo.shared.ProfileState

@Composable fun DemoTheme(dark: Boolean = isSystemInDarkTheme(), content: @Composable () -> Unit) {
    MaterialTheme(colorScheme = if (dark) darkColorScheme(primary = Color(0xFF8ADBCB)) else lightColorScheme(primary = Color(0xFF006B5E)), content = content)
}

@Composable private fun Frame(step: String, content: @Composable ColumnScope.() -> Unit) {
    Surface(Modifier.fillMaxSize().semantics { testTagsAsResourceId = true }) {
        Column(Modifier.safeDrawingPadding().imePadding().verticalScroll(rememberScrollState()).padding(28.dp), verticalArrangement = Arrangement.spacedBy(20.dp)) {
            Text("AGENT DEVICE / DEMO", style = MaterialTheme.typography.labelLarge, color = MaterialTheme.colorScheme.primary)
            Text(step, style = MaterialTheme.typography.labelMedium)
            Spacer(Modifier.height(16.dp))
            content()
        }
    }
}

@Composable fun LoginScreen(email: String = "", password: String = "", error: String? = null, onEmail: (String) -> Unit = {}, onPassword: (String) -> Unit = {}, onLogin: () -> Unit = {}) {
    Frame("01 / SIGN IN") {
        Text("Welcome back", style = MaterialTheme.typography.headlineLarge)
        Text("A small app. A complete automation story.", style = MaterialTheme.typography.bodyLarge)
        OutlinedTextField(email, onEmail, Modifier.fillMaxWidth().testTag("login.email"), label = { Text("Email") }, singleLine = true, keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Email))
        OutlinedTextField(password, onPassword, Modifier.fillMaxWidth().testTag("login.password"), label = { Text("Password") }, singleLine = true, visualTransformation = PasswordVisualTransformation(), keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Password))
        if (error != null) Text(error, Modifier.testTag("login.error").semantics { liveRegion = LiveRegionMode.Polite }, color = MaterialTheme.colorScheme.error)
        Button(
            onLogin,
            Modifier.fillMaxWidth().testTag("login.submit"),
            colors = ButtonDefaults.buttonColors(containerColor = Color(0xFF2563EB))
        ) { Text("Login") }
        Text("Demo account: demo@example.com", style = MaterialTheme.typography.bodySmall)
    }
}

@Composable fun HomeScreen(onProfile: () -> Unit = {}) {
    Frame("02 / HOME") {
        Text("Hello, Demo User", Modifier.testTag("home.title").semantics { heading() }, style = MaterialTheme.typography.headlineLarge)
        Text("Your next step starts here.", style = MaterialTheme.typography.bodyLarge)
        Button(onProfile, Modifier.fillMaxWidth().testTag("home.profile")) { Text("Open Profile") }
        HorizontalDivider()
        Text("Powered by Kotlin Multiplatform shared business logic.", style = MaterialTheme.typography.bodySmall)
    }
}

@Composable fun ProfileScreen(profile: ProfileState = ProfileState(), onReminder: (Boolean) -> Unit = {}, onSave: () -> Unit = {}) {
    Frame("03 / PROFILE") {
        Text("Profile", Modifier.testTag("profile.title").semantics { heading() }, style = MaterialTheme.typography.headlineLarge)
        Text(profile.name, Modifier.testTag("profile.name"), style = MaterialTheme.typography.titleLarge)
        Row(Modifier.fillMaxWidth(), verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.SpaceBetween) {
            Text("Workout reminders", Modifier.weight(1f), style = MaterialTheme.typography.bodyLarge)
            Text(if (profile.remindersEnabled) "On" else "Off", Modifier.testTag("profile.reminder.state").padding(end = 12.dp), style = MaterialTheme.typography.labelLarge)
            Switch(profile.remindersEnabled, onReminder, Modifier.testTag("profile.reminder").semantics { contentDescription = "Workout reminders" })
        }
        Button(onSave, Modifier.fillMaxWidth().testTag("profile.save")) { Text("Save") }
        if (profile.saved) Text("Saved", Modifier.testTag("profile.saved").semantics { liveRegion = LiveRegionMode.Polite }, color = MaterialTheme.colorScheme.primary, style = MaterialTheme.typography.titleMedium)
    }
}
