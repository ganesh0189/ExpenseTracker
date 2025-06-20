package com.easysync.expensetracker.data

import com.google.firebase.firestore.ServerTimestamp
import java.util.Date

data class Expense(
    var id: String = "",
    val userId: String = "",
    val title: String = "",
    val amount: Double = 0.0,
    val payer: String = "",
    val sharedWith: List<String> = emptyList(),
    @ServerTimestamp
    val date: Date? = null
)
