package com.easysync.expensetracker

import android.app.Application
import com.google.firebase.FirebaseApp

class ExpenseTrackerApp : Application() {
    override fun onCreate() {
        super.onCreate()
        FirebaseApp.initializeApp(this)
    }
}
