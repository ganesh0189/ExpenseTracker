package com.easysync.expensetracker.ui.viewmodel

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.easysync.expensetracker.data.ExpenseGroup
import com.easysync.expensetracker.repository.GroupRepository
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.launch

class GroupViewModel : ViewModel() {

    private val repository = GroupRepository()

    private val _groups = MutableStateFlow<List<ExpenseGroup>>(emptyList())
    val groups: StateFlow<List<ExpenseGroup>> = _groups

    init {
        loadGroups()
    }

    private fun loadGroups() {
        viewModelScope.launch {
            _groups.value = repository.getUserGroups()
        }
    }

    fun createGroup(groupName: String, members: List<String>) {
        viewModelScope.launch {
            repository.createGroup(groupName, members)
            loadGroups() // Refresh the list
        }
    }
} 