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

    private val _expenses = MutableStateFlow<List<Expense>>(emptyList())
    val expenses: StateFlow<List<Expense>> = _expenses

    init {
        loadExpenses()
    }

    private fun loadExpenses() {
        viewModelScope.launch {
            _expenses.value = repository.getExpenses()
        }
    }

    fun addExpense(expense: Expense) {
        viewModelScope.launch {
            repository.saveExpense(expense)
            loadExpenses() // Refresh the list
        }
    }
}
