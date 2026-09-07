package com.example.agentdevicee2edemo.shared

object DemoFixture {
    const val EMAIL = "demo@example.com"
    const val PASSWORD = "demo1234"
    const val NAME = "Demo User"
    const val LOGIN_ERROR = "Invalid email or password"
}

data class ProfileState(val name: String = DemoFixture.NAME, val remindersEnabled: Boolean = false, val saved: Boolean = false)

/** Synchronous, in-memory demo state. Both native UIs use this exact implementation. */
class DemoSession {
    var loggedIn: Boolean = false
        private set
    var loginError: String? = null
        private set
    var profile: ProfileState = ProfileState()
        private set

    fun login(email: String, password: String): Boolean {
        loggedIn = email == DemoFixture.EMAIL && password == DemoFixture.PASSWORD
        loginError = if (loggedIn) null else DemoFixture.LOGIN_ERROR
        return loggedIn
    }
    fun setReminders(enabled: Boolean) {
        check(loggedIn) { "Login required" }
        profile = profile.copy(remindersEnabled = enabled)
    }
    fun saveProfile() {
        check(loggedIn) { "Login required" }
        profile = profile.copy(saved = true)
    }
    fun reset() {
        loggedIn = false
        loginError = null
        profile = ProfileState()
    }
}
