package com.easysync.expensetracker.data

data class ExpenseGroup(
    var id: String = "",
    val name: String = "",
    val ownerId: String = "",
    val members: List<String> = emptyList()
) 