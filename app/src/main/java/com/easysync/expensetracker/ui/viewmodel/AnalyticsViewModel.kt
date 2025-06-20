package com.easysync.expensetracker.ui.viewmodel

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.easysync.expensetracker.data.Expense
import com.easysync.expensetracker.repository.ExpenseRepository
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.launch

data class AnalyticsData(
    val totalSpending: Double = 0.0,
    val spendingByCategory: Map<String, Double> = emptyMap()
)

class AnalyticsViewModel : ViewModel() {

    private val repository = ExpenseRepository()

    private val _analyticsData = MutableStateFlow(AnalyticsData())
    val analyticsData: StateFlow<AnalyticsData> = _analyticsData

    init {
        loadAnalytics()
    }

    private fun loadAnalytics() {
        viewModelScope.launch {
            val allExpenses = repository.getAllTimeExpenses()
            val totalSpending = allExpenses.sumOf { it.amount }
            val spendingByCategory = allExpenses
                .groupBy { it.category }
                .mapValues { (_, expenses) -> expenses.sumOf { it.amount } }

            _analyticsData.value = AnalyticsData(
                totalSpending = totalSpending,
                spendingByCategory = spendingByCategory
            )
        }
    }
} 