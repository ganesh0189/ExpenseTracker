package com.easysync.expensetracker.ui

import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material3.*
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import androidx.lifecycle.viewmodel.compose.viewModel
import androidx.navigation.NavController
import com.easysync.expensetracker.ui.viewmodel.ExpenseViewModel

@Composable
fun GroupDetailScreen(
    groupId: String,
    navController: NavController,
    expenseViewModel: ExpenseViewModel = viewModel()
) {
    // This is a simplified approach. Ideally, you would have a dedicated function
    // in your ViewModel to fetch expenses for a specific group.
    val expenses by expenseViewModel.currentMonthExpenses.collectAsState()
    val groupExpenses = expenses.filter { it.groupId == groupId }

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("Group Expenses") },
                colors = TopAppBarDefaults.topAppBarColors(
                    containerColor = MaterialTheme.colorScheme.surface,
                    titleContentColor = MaterialTheme.colorScheme.onSurface,
                )
            )
        },
        floatingActionButton = {
            Button(onClick = { navController.navigate("settleUp/$groupId") }) {
                Text("Settle Up")
            }
        }
    ) { padding ->
        Column(modifier = Modifier.padding(padding)) {
            ExpenseList(expenses = groupExpenses)
        }
    }
} 