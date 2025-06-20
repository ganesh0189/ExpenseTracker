package com.easysync.expensetracker.repository

import com.easysync.expensetracker.data.Expense
import com.google.firebase.auth.FirebaseAuth
import com.google.firebase.firestore.FirebaseFirestore
import kotlinx.coroutines.tasks.await
import java.util.Calendar
import java.util.Date

class ExpenseRepository {

    private val db = FirebaseFirestore.getInstance()
    private val expensesCollection = db.collection("expenses")
    private val auth = FirebaseAuth.getInstance()

    suspend fun saveExpense(expense: Expense) {
        val userId = auth.currentUser?.uid ?: return
        expensesCollection.add(expense.copy(userId = userId)).await()
    }

    suspend fun getCurrentMonthExpenses(): List<Expense> {
        val userId = auth.currentUser?.uid ?: return emptyList()
        val calendar = Calendar.getInstance()
        calendar.set(Calendar.DAY_OF_MONTH, 1)
        val startOfMonth = calendar.time

        calendar.add(Calendar.MONTH, 1)
        val startOfNextMonth = calendar.time

        return getExpensesBetweenDates(userId, startOfMonth, startOfNextMonth)
    }

    suspend fun getAllTimeExpenses(): List<Expense> {
        val userId = auth.currentUser?.uid ?: return emptyList()
        val calendar = Calendar.getInstance()
        calendar.add(Calendar.YEAR, -5)
        val fiveYearsAgo = calendar.time
        
        return getExpensesBetweenDates(userId, fiveYearsAgo, Date()) // From 5 years ago until now
    }

    private suspend fun getExpensesBetweenDates(userId: String, startDate: Date, endDate: Date): List<Expense> {
        return try {
            val snapshot = expensesCollection
                .whereEqualTo("userId", userId)
                .whereGreaterThanOrEqualTo("date", startDate)
                .whereLessThan("date", endDate)
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

    suspend fun getExpensesForGroup(groupId: String): List<Expense> {
        return try {
            val snapshot = expensesCollection
                .whereEqualTo("groupId", groupId)
                .orderBy("date", com.google.firebase.firestore.Query.Direction.DESCENDING)
                .get()
                .await()
            snapshot.documents.mapNotNull { document ->
                document.toObject(Expense::class.java)?.apply { id = document.id }
            }
        } catch (e: Exception) {
            emptyList()
        }
    }
}
