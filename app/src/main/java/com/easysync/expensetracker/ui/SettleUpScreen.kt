package com.easysync.expensetracker.ui

import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import androidx.lifecycle.viewmodel.compose.viewModel
import com.easysync.expensetracker.data.Expense
import com.easysync.expensetracker.data.ExpenseGroup
import com.easysync.expensetracker.ui.viewmodel.ExpenseViewModel
import com.easysync.expensetracker.ui.viewmodel.GroupViewModel
import com.easysync.expensetracker.ui.viewmodel.SettleUpViewModel

@Composable
fun SettleUpScreen(
    groupId: String,
    settleUpViewModel: SettleUpViewModel = viewModel(),
    groupViewModel: GroupViewModel = viewModel(),
    expenseViewModel: ExpenseViewModel = viewModel()
) {
    val settlements by settleUpViewModel.settlements.collectAsState()
    val groups by groupViewModel.groups.collectAsState()
    val currentGroup = groups.find { it.id == groupId }
    var showRecordPaymentDialog by remember { mutableStateOf(false) }

    LaunchedEffect(currentGroup) {
        currentGroup?.let {
            settleUpViewModel.calculateBalances(it.id, it.members)
        }
    }

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("Settle Up") },
                colors = TopAppBarDefaults.topAppBarColors(
                    containerColor = MaterialTheme.colorScheme.surface,
                    titleContentColor = MaterialTheme.colorScheme.onSurface,
                )
            )
        }
    ) { padding ->
        Column(
            modifier = Modifier
                .padding(padding)
                .padding(16.dp)
        ) {
            if (settlements.isEmpty()) {
                Text("All settled up!")
            } else {
                LazyColumn {
                    items(settlements) { settlement ->
                        Text("${settlement.from} owes ${settlement.to} $${String.format("%.2f", settlement.amount)}")
                    }
                }
            }
            Spacer(modifier = Modifier.height(16.dp))
            Button(onClick = { showRecordPaymentDialog = true }) {
                Text("Record a Payment")
            }
        }

        if (showRecordPaymentDialog) {
            currentGroup?.let { group ->
                RecordPaymentDialog(
                    group = group,
                    onDismiss = { showRecordPaymentDialog = false },
                    onConfirm = { payment ->
                        expenseViewModel.addExpense(payment)
                        showRecordPaymentDialog = false
                        // Recalculate balances
                        settleUpViewModel.calculateBalances(group.id, group.members)
                    }
                )
            }
        }
    }
}

@Composable
fun RecordPaymentDialog(
    group: ExpenseGroup,
    onDismiss: () -> Unit,
    onConfirm: (Expense) -> Unit
) {
    var fromUser by remember { mutableStateOf<String?>(null) }
    var toUser by remember { mutableStateOf<String?>(null) }
    var amount by remember { mutableStateOf("") }

    AlertDialog(
        onDismissRequest = onDismiss,
        title = { Text("Record a Payment") },
        text = {
            Column {
                // Dropdowns for selecting users
                // This is a simplified implementation. A real app would use a more robust user selection UI.
                Text("From: ${fromUser ?: "Select User"}")
                Text("To: ${toUser ?: "Select User"}")
                TextField(value = amount, onValueChange = { amount = it }, label = { Text("Amount") })
            }
        },
        confirmButton = {
            Button(onClick = {
                val payment = Expense(
                    groupId = group.id,
                    type = "payment",
                    fromUserEmail = fromUser,
                    toUserEmail = toUser,
                    amount = amount.toDoubleOrNull() ?: 0.0
                )
                onConfirm(payment)
            }) { Text("Confirm") }
        },
        dismissButton = {
            Button(onClick = onDismiss) { Text("Cancel") }
        }
    )
} 