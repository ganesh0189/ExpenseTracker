package com.easysync.expensetracker.service

import com.easysync.expensetracker.data.Expense
import java.text.SimpleDateFormat
import java.util.*

class ExportService {

    fun generateCsv(expenses: List<Expense>): String {
        val header = "Date,Title,Category,Amount,Payer,Shared With,Group ID"
        val rows = expenses.map { expense ->
            val date = expense.date?.let { SimpleDateFormat("yyyy-MM-dd", Locale.getDefault()).format(it) } ?: ""
            val sharedWith = expense.sharedWith.joinToString(";")
            // Escape commas in title to avoid CSV format issues
            val title = expense.title.replace(",", "")
            
            "$date,${title},${expense.category},${expense.amount},${expense.payer},\"$sharedWith\",${expense.groupId ?: ""}"
        }
        return (listOf(header) + rows).joinToString("\n")
    }
}
