package com.easysync.expensetracker.repository

import com.google.firebase.auth.AuthCredential
import com.google.firebase.auth.AuthResult
import com.google.firebase.auth.FirebaseAuth
import com.google.firebase.auth.FirebaseUser
import kotlinx.coroutines.tasks.await

class AuthRepository {

    private val auth: FirebaseAuth = FirebaseAuth.getInstance()

    fun getCurrentUser(): FirebaseUser? {
        return auth.currentUser
    }

    suspend fun signInWithEmail(email: String, password: String): AuthResult {
        return auth.signInWithEmailAndPassword(email, password).await()
    }

    suspend fun createUserWithEmail(email: String, password: String): AuthResult {
        return auth.createUserWithEmailAndPassword(email, password).await()
    }

    suspend fun sendEmailVerification() {
        auth.currentUser?.sendEmailVerification()?.await()
    }

    suspend fun signInWithGoogle(credential: AuthCredential): AuthResult {
        return auth.signInWithCredential(credential).await()
    }

    fun signOut() {
        auth.signOut()
    }
} 