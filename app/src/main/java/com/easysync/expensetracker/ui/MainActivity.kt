package com.easysync.expensetracker.ui

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.viewModels
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Add
import androidx.compose.material.icons.filled.ExitToApp
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.input.TextFieldValue
import androidx.compose.ui.tooling.preview.Preview
import androidx.compose.ui.unit.dp
import androidx.lifecycle.viewmodel.compose.viewModel
import com.easysync.expensetracker.data.Expense
import com.easysync.expensetracker.ui.theme.ExpenseTrackerTheme
import com.easysync.expensetracker.ui.viewmodel.AuthViewModel
import com.easysync.expensetracker.ui.viewmodel.ExpenseViewModel
import java.text.SimpleDateFormat
import java.util.*

class MainActivity : ComponentActivity() {
    private val expenseViewModel: ExpenseViewModel by viewModels()
    private val authViewModel: AuthViewModel by viewModels()

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContent {
            ExpenseTrackerTheme {
                Surface(
                    modifier = Modifier.fillMaxSize(),
                    color = MaterialTheme.colorScheme.background
                ) {
                    val user by authViewModel.user.collectAsState()
                    if (user == null) {
                        LoginScreen(authViewModel = authViewModel, onLoginSuccess = {
                            // Recomposition will handle the screen change
                        })
                    } else {
                        HomeScreen(expenseViewModel, authViewModel)
                    }
                }
            }
        }
    }
}

@Composable
fun HomeScreen(expenseViewModel: ExpenseViewModel, authViewModel: AuthViewModel) {
    val expenses by expenseViewModel.expenses.collectAsState()
    var showAddExpenseDialog by remember { mutableStateOf(false) }

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("Expense Tracker") },
                colors = TopAppBarDefaults.topAppBarColors(
                    containerColor = MaterialTheme.colorScheme.primaryContainer,
                    titleContentColor = MaterialTheme.colorScheme.primary,
                ),
                actions = {
                    IconButton(onClick = { authViewModel.signOut() }) {
                        Icon(Icons.Default.ExitToApp, contentDescription = "Sign Out")
                    }
                }
            )
        },
        floatingActionButton = {
            FloatingActionButton(onClick = { showAddExpenseDialog = true }) {
                Icon(Icons.Default.Add, contentDescription = "Add Expense")
            }
        }
    ) { padding ->
        Column(modifier = Modifier.padding(padding)) {
            if (showAddExpenseDialog) {
                AddExpenseDialog(
                    onAddExpense = { expense ->
                        expenseViewModel.addExpense(expense)
                        showAddExpenseDialog = false
                    },
                    onDismiss = { showAddExpenseDialog = false }
                )
            }
            ExpenseList(expenses = expenses)
        }
    }
}

@Composable
fun ExpenseList(expenses: List<Expense>) {
    LazyColumn {
        items(expenses) { expense ->
            ExpenseItem(expense)
        }
    }
}

@Composable
fun ExpenseItem(expense: Expense) {
    Card(
        modifier = Modifier
            .fillMaxWidth()
            .padding(8.dp)
    ) {
        Column(modifier = Modifier.padding(16.dp)) {
            Text(text = expense.title, style = MaterialTheme.typography.titleLarge)
            Text(text = "Amount: $${expense.amount}", style = MaterialTheme.typography.bodyMedium)
            Text(text = "Payer: ${expense.payer}", style = MaterialTheme.typography.bodyMedium)
            Text(text = "Shared with: ${expense.sharedWith.joinToString()}", style = MaterialTheme.typography.bodyMedium)
            expense.date?.let {
                Text(
                    text = "Date: ${SimpleDateFormat("yyyy-MM-dd", Locale.getDefault()).format(it)}",
                    style = MaterialTheme.typography.bodySmall
                )
            }
        }
    }
}

@Composable
fun AddExpenseDialog(onAddExpense: (Expense) -> Unit, onDismiss: () -> Unit) {
    var title by remember { mutableStateOf(TextFieldValue("")) }
    var amount by remember { mutableStateOf(TextFieldValue("")) }
    var payer by remember { mutableStateOf(TextFieldValue("")) }
    var sharedWith by remember { mutableStateOf(TextFieldValue("")) }

    AlertDialog(
        onDismissRequest = onDismiss,
        title = { Text("Add Expense") },
        text = {
            Column {
                TextField(value = title, onValueChange = { title = it }, label = { Text("Title") })
                TextField(value = amount, onValueChange = { amount = it }, label = { Text("Amount") })
                TextField(value = payer, onValueChange = { payer = it }, label = { Text("Payer") })
                TextField(value = sharedWith, onValueChange = { sharedWith = it }, label = { Text("Shared with (comma-separated)") })
            }
        },
        confirmButton = {
            Button(
                onClick = {
                    val expense = Expense(
                        title = title.text,
                        amount = amount.text.toDoubleOrNull() ?: 0.0,
                        payer = payer.text,
                        sharedWith = sharedWith.text.split(",").map { it.trim() }
                    )
                    onAddExpense(expense)
                }
            ) {
                Text("Add")
            }
        },
        dismissButton = {
            Button(onClick = onDismiss) {
                Text("Cancel")
            }
        }
    )
}

@Preview(showBackground = true)
@Composable
fun DefaultPreview() {
    ExpenseTrackerTheme {
        // You can create a mock view model for preview if needed
        // HomeScreen(mockViewModel)
    }
}
