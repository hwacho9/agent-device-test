package com.example.agentdevicee2edemo.shared
import kotlin.test.*

class DemoSessionTest {
    @Test fun initialStateIsDeterministic() {
        val session = DemoSession()
        assertFalse(session.loggedIn)
        assertNull(session.loginError)
        assertEquals(ProfileState("Demo User", false, false), session.profile)
    }
    @Test fun invalidLoginDoesNotCreateSession() {
        for ((email, password) in listOf("" to "", DemoFixture.EMAIL to "wrong", "wrong@example.com" to DemoFixture.PASSWORD)) {
            val session = DemoSession()
            assertFalse(session.login(email, password))
            assertFalse(session.loggedIn)
            assertEquals("Invalid email or password", session.loginError)
        }
    }
    @Test fun validLoginClearsPreviousError() {
        val session = DemoSession()
        session.login("wrong", "wrong")
        assertTrue(session.login(DemoFixture.EMAIL, DemoFixture.PASSWORD))
        assertTrue(session.loggedIn)
        assertNull(session.loginError)
    }
    @Test fun profileSavePreservesNameReminderAndPersistentStatus() {
        val session = DemoSession()
        session.login(DemoFixture.EMAIL, DemoFixture.PASSWORD)
        session.setReminders(true)
        assertFalse(session.profile.saved)
        session.saveProfile()
        assertEquals(ProfileState("Demo User", true, true), session.profile)
        session.saveProfile()
        assertEquals(ProfileState("Demo User", true, true), session.profile)
    }
    @Test fun loggedOutCannotMutateProfile() {
        val session = DemoSession()
        assertFailsWith<IllegalStateException> { session.saveProfile() }
        assertFailsWith<IllegalStateException> { session.setReminders(true) }
    }
    @Test fun resetRestoresFixtureAfterSavedSession() {
        val session = DemoSession()
        session.login(DemoFixture.EMAIL, DemoFixture.PASSWORD)
        session.setReminders(true)
        session.saveProfile()
        session.reset()
        assertFalse(session.loggedIn)
        assertNull(session.loginError)
        assertEquals(ProfileState(), session.profile)
    }
}
