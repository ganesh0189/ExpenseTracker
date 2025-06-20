package com.easysync.expensetracker.ui.viewmodel

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.easysync.expensetracker.data.Expense
import com.easysync.expensetracker.repository.ExpenseRepository
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.launch

class ExpenseViewModel : ViewModel() {

    private val repository = ExpenseRepository()

    private val _currentMonthExpenses = MutableStateFlow<List<Expense>>(emptyList())
    val currentMonthExpenses: StateFlow<List<Expense>> = _currentMonthExpenses

    init {
        loadCurrentMonthExpenses()
    }

    private fun loadCurrentMonthExpenses() {
        viewModelScope.launch {
            _currentMonthExpenses.value = repository.getCurrentMonthExpenses()
        }
    }

    fun addExpense(expense: Expense) {
        viewModelScope.launch {
            repository.saveExpense(expense)
            loadCurrentMonthExpenses() // Refresh the list
        }
    }
}
