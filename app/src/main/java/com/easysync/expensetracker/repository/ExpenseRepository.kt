package com.easysync.expensetracker.repository

import com.easysync.expensetracker.data.Expense
import com.google.firebase.auth.FirebaseAuth
import com.google.firebase.firestore.FirebaseFirestore
import kotlinx.coroutines.tasks.await
import java.util.Calendar

class ExpenseRepository {

    private val db = FirebaseFirestore.getInstance()
    private val expensesCollection = db.collection("expenses")
    private val auth = FirebaseAuth.getInstance()

    suspend fun saveExpense(expense: Expense) {
        val userId = auth.currentUser?.uid ?: return
        expensesCollection.add(expense.copy(userId = userId)).await()
    }

    suspend fun getExpenses(): List<Expense> {
        val userId = auth.currentUser?.uid ?: return emptyList()
        val calendar = Calendar.getInstance()
        calendar.add(Calendar.YEAR, -5)
        val fiveYearsAgo = calendar.time

        return try {
            val snapshot = expensesCollection
                .whereEqualTo("userId", userId)
                .whereGreaterThanOrEqualTo("date", fiveYearsAgo)
                .orderBy("date", com.google.firebase.firestore.Query.Direction.DESCENDING)
                .get()
                .await()
            snapshot.documents.mapNotNull { document ->
                val expense = document.toObject(Expense::class.java)
                expense?.id = document.id
                expense
            }
        } catch (e: Exception) {
            // Handle exception
            emptyList()
        }
    }
}
