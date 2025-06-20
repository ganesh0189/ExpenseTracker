package com.easysync.expensetracker

import androidx.compose.ui.test.*
import androidx.compose.ui.test.junit4.createAndroidComposeRule
import androidx.test.ext.junit.runners.AndroidJUnit4
import com.easysync.expensetracker.ui.MainActivity
import org.junit.Rule
import org.junit.Test
import org.junit.runner.RunWith
import java.util.UUID

@RunWith(AndroidJUnit4::class)
class AppFlowTest {

    @get:Rule
    val composeTestRule = createAndroidComposeRule<MainActivity>()

    @Test
    fun testAppEndToEndFlow() {
        // Use a unique email for each test run to avoid conflicts
        val uniqueEmail = "testuser_${UUID.randomUUID()}@example.com"
        val password = "password123"
        val expenseTitle = "Team Lunch"
        val expenseAmount = "150.50"

        // 1. Sign Up
        // Find and interact with the email, password fields and sign-up button
        composeTestRule.onNodeWithText("Email").performTextInput(uniqueEmail)
        composeTestRule.onNodeWithText("Password").performTextInput(password)
        composeTestRule.onNodeWithText("Sign Up").performClick()

        // After sign up, the user needs to be "logged in" to proceed.
        // In a real test, you might need to handle email verification or mock the login state.
        // For this flow, we'll manually sign in after the registration to simulate a verified user.
        // A short delay to allow the sign-up process to complete.
        Thread.sleep(2000)
        composeTestRule.onNodeWithText("Sign In").performClick()
        
        // A delay to wait for login and data loading
        Thread.sleep(5000)

        // 2. Add an Expense
        // Look for the "Add Expense" FAB and click it
        composeTestRule.onNodeWithContentDescription("Add Expense").performClick()

        // Fill in the expense details
        composeTestRule.onNodeWithText("Title").performTextInput(expenseTitle)
        composeTestRule.onNodeWithText("Amount").performTextInput(expenseAmount)
        composeTestRule.onNodeWithText("Payer").performTextInput("Me")
        composeTestRule.onNodeWithText("Shared with (comma-separated)").performTextInput("John, Jane")

        // Click the "Add" button on the dialog
        composeTestRule.onNodeWithText("Add").performClick()

        // 3. Verify Expense is Displayed
        // Check if the expense with the given title and amount is now visible on the screen
        composeTestRule.onNodeWithText(expenseTitle).assertIsDisplayed()
        composeTestRule.onNodeWithText("Amount: $$expenseAmount").assertIsDisplayed()

        // 4. Sign Out
        composeTestRule.onNodeWithContentDescription("Sign Out").performClick()

        // 5. Verify user is back on the Login Screen
        composeTestRule.onNodeWithText("Sign In").assertIsDisplayed()
    }
} 