# Expense Tracker App

This is an Android application built with Kotlin and Jetpack Compose that allows users to track their expenses. It uses Firebase Firestore for data storage and Firebase Authentication for user management.

## Features

*   **User Authentication**:
    *   Sign in with Email/Password.
    *   Sign up with Email/Password (with email verification).
    *   Sign in with Google.
    *   Sign in with Phone Number (OTP verification).
*   **Expense Management**:
    *   Add new expenses with title, amount, payer, and shared members.
    *   View a list of recent expenses.
    *   Expenses are stored securely in Firebase Firestore and linked to the user's account.

## Project Structure

Here's a breakdown of the key files and directories in the project:

*   `app/build.gradle.kts`: The app-level Gradle file containing all dependencies for the project, including Jetpack Compose, Firebase, and ViewModel.
*   `app/google-services.json`: The Firebase configuration file. **You need to replace this with your own.**
*   `app/src/main/AndroidManifest.xml`: The main configuration file for the app, including permissions and component declarations.
*   `app/src/main/java/com/easysync/expensetracker/`: The main package for the application source code.
    *   **`data/Expense.kt`**: Defines the `Expense` data class, which represents a single expense with fields like `id`, `userId`, `title`, `amount`, `payer`, `sharedWith`, and `date`.
    *   **`repository/`**: Contains the repositories that handle data operations.
        *   **`AuthRepository.kt`**: Manages all Firebase Authentication operations, such as sign-in, sign-up, and sign-out.
        *   **`ExpenseRepository.kt`**: Handles all data operations with Firebase Firestore, including saving and retrieving expenses. It ensures that expenses are associated with the correct user.
    *   **`ui/`**: Contains all the UI-related code.
        *   **`MainActivity.kt`**: The main entry point of the app. It handles the navigation between the `LoginScreen` and the `HomeScreen` based on the user's authentication state.
        *   **`LoginScreen.kt`**: The UI for user authentication, providing options for email/password, Google, and phone number sign-in.
        *   **`theme/`**: Contains the Jetpack Compose theme files (`Color.kt`, `Theme.kt`, `Type.kt`).
        *   **`viewmodel/`**: Contains the ViewModels that manage the UI state and logic.
            *   **`AuthViewModel.kt`**: Manages the authentication state and handles all user authentication logic.
            *   **`ExpenseViewModel.kt`**: Manages the state of the expenses, including fetching and adding expenses.
    *   **`ExpenseTrackerApp.kt`**: The main application class where Firebase is initialized.
*   `app/src/main/res/`: Contains all the resource files for the app.
    *   `values/strings.xml`: Contains all the string resources, including the app name and the `default_web_client_id` for Google Sign-In.
    *   `values/colors.xml`: Defines the color palette for the app.
    *   `values/themes.xml`: Defines the app's theme.

## Setup

To run this project, you'll need to do the following:

1.  **Clone the repository**.
2.  **Set up Firebase**:
    *   Go to the [Firebase console](https://console.firebase.google.com/) and create a new project.
    *   Add an Android app to your project with the package name `com.easysync.expensetracker`.
    *   Download the `google-services.json` file and place it in the `app/` directory.
    *   Enable the following sign-in providers in the Firebase console:
        *   Email/Password
        *   Google
        *   Phone
    *   For Google Sign-In, you'll need to get your **Web client ID** from the Firebase console (Project Settings > General > Your apps > Web client ID). Then, replace the placeholder value in `app/src/main/res/values/strings.xml` with your actual ID.
    *   For Google Sign-In and Phone Authentication to work correctly, you need to add your app's **SHA-1 fingerprint** to the Firebase project settings.
3.  **Build and run the app**. 