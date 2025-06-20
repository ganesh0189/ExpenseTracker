package com.easysync.expensetracker.ui

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.viewModels
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Add
import androidx.compose.material.icons.filled.ExitToApp
import androidx.compose.material.icons.filled.Home
import androidx.compose.material.icons.filled.List
import androidx.compose.material.icons.filled.Person
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.input.TextFieldValue
import androidx.compose.ui.tooling.preview.Preview
import androidx.compose.ui.unit.dp
import androidx.lifecycle.viewmodel.compose.viewModel
import androidx.navigation.compose.NavHost
import androidx.navigation.compose.composable
import androidx.navigation.compose.rememberNavController
import com.easysync.expensetracker.data.Expense
import com.easysync.expensetracker.ui.theme.ExpenseTrackerTheme
import com.easysync.expensetracker.ui.viewmodel.AuthViewModel
import com.easysync.expensetracker.ui.viewmodel.ExpenseViewModel
import com.easysync.expensetracker.ui.viewmodel.GroupViewModel
import com.easysync.expensetracker.ui.viewmodel.AnalyticsViewModel
import java.text.SimpleDateFormat
import java.util.*

class MainActivity : ComponentActivity() {
    private val authViewModel: AuthViewModel by viewModels()
    private val expenseViewModel: ExpenseViewModel by viewModels()
    private val groupViewModel: GroupViewModel by viewModels()
    private val analyticsViewModel: AnalyticsViewModel by viewModels()

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
                        LoginScreen(authViewModel = authViewModel, onLoginSuccess = { /* ... */ })
                    } else {
                        AppMainScreen(
                            expenseViewModel = expenseViewModel,
                            authViewModel = authViewModel,
                            groupViewModel = groupViewModel,
                            analyticsViewModel = analyticsViewModel
                        )
                    }
                }
            }
        }
    }
}

@Composable
fun AppMainScreen(
    expenseViewModel: ExpenseViewModel,
    authViewModel: AuthViewModel,
    groupViewModel: GroupViewModel,
    analyticsViewModel: AnalyticsViewModel
) {
    val navController = rememberNavController()
    Scaffold(
        bottomBar = {
            NavigationBar {
                NavigationBarItem(
                    icon = { Icon(Icons.Default.Home, contentDescription = "Home") },
                    label = { Text("Home") },
                    selected = true, // Simplified for now
                    onClick = { navController.navigate("home") }
                )
                NavigationBarItem(
                    icon = { Icon(Icons.Default.List, contentDescription = "Groups") },
                    label = { Text("Groups") },
                    selected = false, // Simplified for now
                    onClick = { navController.navigate("groups") }
                )
                NavigationBarItem(
                    icon = { Icon(Icons.Default.Person, contentDescription = "Analytics") },
                    label = { Text("Analytics") },
                    selected = false, // Simplified for now
                    onClick = { navController.navigate("analytics") }
                )
            }
        }
    ) { padding ->
        NavHost(navController = navController, startDestination = "home", modifier = Modifier.padding(padding)) {
            composable("home") { HomeScreen(expenseViewModel, authViewModel) }
            composable("groups") { GroupScreen(groupViewModel, navController) }
            composable("analytics") { AnalyticsScreen(analyticsViewModel) }
            composable("groupDetail/{groupId}") { backStackEntry ->
                val groupId = backStackEntry.arguments?.getString("groupId")
                if (groupId != null) {
                    GroupDetailScreen(groupId = groupId, navController = navController)
                }
            }
            composable("settleUp/{groupId}") { backStackEntry ->
                val groupId = backStackEntry.arguments?.getString("groupId")
                if (groupId != null) {
                    SettleUpScreen(groupId = groupId)
                }
            }
        }
    }
}

@Composable
fun HomeScreen(expenseViewModel: ExpenseViewModel, authViewModel: AuthViewModel) {
    val expenses by expenseViewModel.currentMonthExpenses.collectAsState()
    var showAddExpenseDialog by remember { mutableStateOf(false) }

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("This Month's Expenses") },
                colors = TopAppBarDefaults.topAppBarColors(
                    containerColor = MaterialTheme.colorScheme.surface,
                    titleContentColor = MaterialTheme.colorScheme.onSurface,
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
                    groups = emptyList(),
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
fun AddExpenseDialog(
    groups: List<ExpenseGroup>,
    onAddExpense: (Expense) -> Unit,
    onDismiss: () -> Unit
) {
    var title by remember { mutableStateOf(TextFieldValue("")) }
    var amount by remember { mutableStateOf(TextFieldValue("")) }
    var payer by remember { mutableStateOf(TextFieldValue("")) }
    var sharedWith by remember { mutableStateOf(TextFieldValue("")) }
    var category by remember { mutableStateOf(TextFieldValue("")) }
    var selectedGroup by remember { mutableStateOf<ExpenseGroup?>(null) }
    var expanded by remember { mutableStateOf(false) }

    AlertDialog(
        onDismissRequest = onDismiss,
        title = { Text("Add Expense") },
        text = {
            Column {
                TextField(value = title, onValueChange = { title = it }, label = { Text("Title") })
                TextField(value = amount, onValueChange = { amount = it }, label = { Text("Amount") })
                TextField(value = category, onValueChange = { category = it }, label = { Text("Category") })
                TextField(value = payer, onValueChange = { payer = it }, label = { Text("Payer") })
                TextField(value = sharedWith, onValueChange = { sharedWith = it }, label = { Text("Shared with (comma-separated)") })
                
                ExposedDropdownMenuBox(
                    expanded = expanded,
                    onExpandedChange = { expanded = !expanded }
                ) {
                    TextField(
                        readOnly = true,
                        value = selectedGroup?.name ?: "Select Group (Optional)",
                        onValueChange = { },
                        label = { Text("Group") },
                        trailingIcon = {
                            ExposedDropdownMenuDefaults.TrailingIcon(expanded = expanded)
                        },
                        modifier = Modifier.menuAnchor()
                    )
                    ExposedDropdownMenu(
                        expanded = expanded,
                        onDismissRequest = { expanded = false }
                    ) {
                        groups.forEach { group ->
                            DropdownMenuItem(
                                text = { Text(group.name) },
                                onClick = {
                                    selectedGroup = group
                                    expanded = false
                                }
                            )
                        }
                    }
                }
            }
        },
        confirmButton = {
            Button(
                onClick = {
                    val expense = Expense(
                        title = title.text,
                        amount = amount.text.toDoubleOrNull() ?: 0.0,
                        payer = payer.text,
                        sharedWith = sharedWith.text.split(",").map { it.trim() },
                        groupId = selectedGroup?.id,
                        category = category.text.ifBlank { "Default" }
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
