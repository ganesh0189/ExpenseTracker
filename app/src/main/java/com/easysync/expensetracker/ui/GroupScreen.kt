package com.easysync.expensetracker.ui

import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Add
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import androidx.lifecycle.viewmodel.compose.viewModel
import androidx.navigation.NavController
import com.easysync.expensetracker.data.ExpenseGroup
import com.easysync.expensetracker.ui.viewmodel.GroupViewModel

@Composable
fun GroupScreen(
    groupViewModel: GroupViewModel = viewModel(),
    navController: NavController
) {
    val groups by groupViewModel.groups.collectAsState()
    var showCreateGroupDialog by remember { mutableStateOf(false) }

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("Expense Groups") },
                colors = TopAppBarDefaults.topAppBarColors(
                    containerColor = MaterialTheme.colorScheme.surface,
                    titleContentColor = MaterialTheme.colorScheme.onSurface,
                )
            )
        },
        floatingActionButton = {
            FloatingActionButton(onClick = { showCreateGroupDialog = true }) {
                Icon(Icons.Default.Add, contentDescription = "Create Group")
            }
        }
    ) { padding ->
        Column(modifier = Modifier.padding(padding)) {
            if (showCreateGroupDialog) {
                CreateGroupDialog(
                    onCreateGroup = { groupName, members ->
                        groupViewModel.createGroup(groupName, members)
                        showCreateGroupDialog = false
                    },
                    onDismiss = { showCreateGroupDialog = false }
                )
            }
            GroupList(groups = groups, onGroupClick = { groupId ->
                navController.navigate("groupDetail/$groupId")
            })
        }
    }
}

@Composable
fun GroupList(groups: List<ExpenseGroup>, onGroupClick: (String) -> Unit) {
    LazyColumn {
        items(groups) { group ->
            GroupItem(group, onGroupClick = { onGroupClick(group.id) })
        }
    }
}

@Composable
fun GroupItem(group: ExpenseGroup, onGroupClick: () -> Unit) {
    Card(
        modifier = Modifier
            .fillMaxWidth()
            .padding(8.dp)
            .clickable(onClick = onGroupClick)
    ) {
        Column(modifier = Modifier.padding(16.dp)) {
            Text(text = group.name, style = MaterialTheme.typography.titleLarge)
            Text(text = "Members: ${group.members.size}", style = MaterialTheme.typography.bodyMedium)
        }
    }
}

@Composable
fun CreateGroupDialog(onCreateGroup: (String, List<String>) -> Unit, onDismiss: () -> Unit) {
    var groupName by remember { mutableStateOf("") }
    var members by remember { mutableStateOf("") }

    AlertDialog(
        onDismissRequest = onDismiss,
        title = { Text("Create Group") },
        text = {
            Column {
                OutlinedTextField(value = groupName, onValueChange = { groupName = it }, label = { Text("Group Name") })
                OutlinedTextField(value = members, onValueChange = { members = it }, label = { Text("Member Emails (comma-separated)") })
            }
        },
        confirmButton = {
            Button(
                onClick = {
                    val memberList = members.split(",").map { it.trim() }
                    onCreateGroup(groupName, memberList)
                }
            ) {
                Text("Create")
            }
        },
        dismissButton = {
            Button(onClick = onDismiss) {
                Text("Cancel")
            }
        }
    )
} 