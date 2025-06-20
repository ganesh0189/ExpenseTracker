package com.easysync.expensetracker.ui.viewmodel

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.easysync.expensetracker.data.Expense
import com.easysync.expensetracker.repository.ExpenseRepository
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.launch
import kotlin.math.abs

data class Balance(
    val userEmail: String,
    val amount: Double // Positive if the user is owed money, negative if they owe money
)

data class Settlement(
    val from: String,
    val to: String,
    val amount: Double
)

class SettleUpViewModel : ViewModel() {

    private val expenseRepository = ExpenseRepository()

    private val _balances = MutableStateFlow<List<Balance>>(emptyList())
    val balances: StateFlow<List<Balance>> = _balances

    private val _settlements = MutableStateFlow<List<Settlement>>(emptyList())
    val settlements: StateFlow<List<Settlement>> = _settlements

    fun calculateBalances(groupId: String, members: List<String>) {
        viewModelScope.launch {
            val allExpenses = expenseRepository.getExpensesForGroup(groupId)

            val totalPaid = members.associateWith { email ->
                allExpenses.filter { it.payer == email && it.type == "expense" }.sumOf { it.amount } -
                allExpenses.filter { it.fromUserEmail == email && it.type == "payment" }.sumOf { it.amount } +
                allExpenses.filter { it.toUserEmail == email && it.type == "payment" }.sumOf { it.amount }
            }.toMutableMap()

            val totalOwed = members.associateWith { email ->
                allExpenses.filter { it.type == "expense" && it.sharedWith.contains(email) }
                    .sumOf { it.amount / it.sharedWith.size }
            }

            val finalBalances = members.map { email ->
                val paid = totalPaid[email] ?: 0.0
                val owed = totalOwed[email] ?: 0.0
                Balance(email, paid - owed)
            }
            _balances.value = finalBalances
            
            calculateSettlements(finalBalances)
        }
    }

    private fun calculateSettlements(balances: List<Balance>) {
        val debtors = balances.filter { it.amount < 0 }.toMutableList()
        val creditors = balances.filter { it.amount > 0 }.toMutableList()
        val settlements = mutableListOf<Settlement>()

        while (debtors.isNotEmpty() && creditors.isNotEmpty()) {
            val debtor = debtors.first()
            val creditor = creditors.first()
            
            val amountToTransfer = minOf(abs(debtor.amount), creditor.amount)

            settlements.add(Settlement(debtor.userEmail, creditor.userEmail, amountToTransfer))

            val newDebtorAmount = debtor.amount + amountToTransfer
            val newCreditorAmount = creditor.amount - amountToTransfer

            if (newDebtorAmount > -0.01) { // Use a small tolerance for float precision
                debtors.removeAt(0)
            } else {
                debtors[0] = debtor.copy(amount = newDebtorAmount)
            }

            if (newCreditorAmount < 0.01) {
                creditors.removeAt(0)
            } else {
                creditors[0] = creditor.copy(amount = newCreditorAmount)
            }
        }
        _settlements.value = settlements
    }
} 