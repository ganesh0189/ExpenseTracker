package com.easysync.expensetracker.repository

import com.easysync.expensetracker.data.ExpenseGroup
import com.google.firebase.auth.FirebaseAuth
import com.google.firebase.firestore.FirebaseFirestore
import kotlinx.coroutines.tasks.await

class GroupRepository {

    private val db = FirebaseFirestore.getInstance()
    private val groupsCollection = db.collection("expenseGroups")
    private val auth = FirebaseAuth.getInstance()

    suspend fun createGroup(groupName: String, members: List<String>) {
        val currentUser = auth.currentUser ?: return
        val group = ExpenseGroup(
            name = groupName,
            ownerId = currentUser.uid,
            members = (members + currentUser.uid).distinct()
        )
        groupsCollection.add(group).await()
    }

    suspend fun getUserGroups(): List<ExpenseGroup> {
        val userId = auth.currentUser?.uid ?: return emptyList()
        return try {
            val snapshot = groupsCollection
                .whereArrayContains("members", userId)
                .get()
                .await()
            snapshot.documents.mapNotNull { document ->
                val group = document.toObject(ExpenseGroup::class.java)
                group?.id = document.id
                group
            }
        } catch (e: Exception) {
            emptyList()
        }
    }
} 