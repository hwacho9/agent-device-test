package com.example.agentdevicee2edemo

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.compose.runtime.*
import com.example.agentdevicee2edemo.shared.DemoSession

class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContent { DemoTheme { DemoRoute() } }
    }
}

@Composable
fun DemoRoute() {
    val session = remember { DemoSession() }
    var screen by remember { mutableStateOf("login") }
    var email by remember { mutableStateOf("") }
    var password by remember { mutableStateOf("") }
    var error by remember { mutableStateOf<String?>(null) }
    var profile by remember { mutableStateOf(session.profile) }
    when (screen) {
        "login" -> LoginScreen(email, password, error, { email = it }, { password = it }) {
            if (session.login(email, password)) screen = "home"
            error = session.loginError
        }
        "home" -> HomeScreen { screen = "profile" }
        "profile" -> ProfileScreen(profile, {
            session.setReminders(it); profile = session.profile
        }, {
            session.saveProfile(); profile = session.profile
        })
    }
}
