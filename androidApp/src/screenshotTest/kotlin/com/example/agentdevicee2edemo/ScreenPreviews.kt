package com.example.agentdevicee2edemo
import androidx.compose.runtime.Composable
import androidx.compose.ui.tooling.preview.Preview
import android.content.res.Configuration
import com.android.tools.screenshot.PreviewTest
import com.example.agentdevicee2edemo.shared.ProfileState

@PreviewTest
@Preview(name = "LoginDefault", widthDp = 412, heightDp = 850, locale = "en", fontScale = 1.0f, uiMode = Configuration.UI_MODE_NIGHT_NO)
@Composable fun LoginDefault() { DemoTheme(dark = false) { LoginScreen() } }

@PreviewTest
@Preview(name = "LoginError", widthDp = 412, heightDp = 850, locale = "en", fontScale = 1.0f, uiMode = Configuration.UI_MODE_NIGHT_NO)
@Composable fun LoginError() { DemoTheme(dark = false) { LoginScreen(error = "Invalid email or password") } }

@PreviewTest
@Preview(name = "LoginDark", widthDp = 412, heightDp = 850, locale = "en", fontScale = 1.0f, uiMode = Configuration.UI_MODE_NIGHT_YES)
@Composable fun LoginDark() { DemoTheme(dark = true) { LoginScreen() } }

@PreviewTest
@Preview(name = "LoginLargeFont", widthDp = 412, heightDp = 850, locale = "en", fontScale = 1.5f, uiMode = Configuration.UI_MODE_NIGHT_NO)
@Composable fun LoginLargeFont() { DemoTheme(dark = false) { LoginScreen() } }

@PreviewTest
@Preview(name = "HomeDefault", widthDp = 412, heightDp = 850, locale = "en", fontScale = 1.0f, uiMode = Configuration.UI_MODE_NIGHT_NO)
@Composable fun HomeDefault() { DemoTheme(dark = false) { HomeScreen() } }

@PreviewTest
@Preview(name = "HomeDark", widthDp = 412, heightDp = 850, locale = "en", fontScale = 1.0f, uiMode = Configuration.UI_MODE_NIGHT_YES)
@Composable fun HomeDark() { DemoTheme(dark = true) { HomeScreen() } }

@PreviewTest
@Preview(name = "ProfileDefault", widthDp = 412, heightDp = 850, locale = "en", fontScale = 1.0f, uiMode = Configuration.UI_MODE_NIGHT_NO)
@Composable fun ProfileDefault() { DemoTheme(dark = false) { ProfileScreen() } }

@PreviewTest
@Preview(name = "ProfileReminderEnabled", widthDp = 412, heightDp = 850, locale = "en", fontScale = 1.0f, uiMode = Configuration.UI_MODE_NIGHT_NO)
@Composable fun ProfileReminderEnabled() { DemoTheme(dark = false) { ProfileScreen(ProfileState(remindersEnabled = true)) } }

@PreviewTest
@Preview(name = "ProfileSaved", widthDp = 412, heightDp = 850, locale = "en", fontScale = 1.0f, uiMode = Configuration.UI_MODE_NIGHT_NO)
@Composable fun ProfileSaved() { DemoTheme(dark = false) { ProfileScreen(ProfileState(remindersEnabled = true, saved = true)) } }

@PreviewTest
@Preview(name = "ProfileDark", widthDp = 412, heightDp = 850, locale = "en", fontScale = 1.0f, uiMode = Configuration.UI_MODE_NIGHT_YES)
@Composable fun ProfileDark() { DemoTheme(dark = true) { ProfileScreen() } }

@PreviewTest
@Preview(name = "ProfileLargeFont", widthDp = 412, heightDp = 850, locale = "en", fontScale = 1.5f, uiMode = Configuration.UI_MODE_NIGHT_NO)
@Composable fun ProfileLargeFont() { DemoTheme(dark = false) { ProfileScreen() } }

