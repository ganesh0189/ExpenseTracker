package com.easysync.expensetracker.ui.viewmodel

import android.app.Activity
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.easysync.expensetracker.repository.AuthRepository
import com.google.firebase.auth.AuthCredential
import com.google.firebase.auth.FirebaseAuth
import com.google.firebase.auth.PhoneAuthCredential
import com.google.firebase.auth.PhoneAuthProvider
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.launch

class AuthViewModel : ViewModel() {

    private val repository = AuthRepository()

    private val _user = MutableStateFlow(repository.getCurrentUser())
    val user: StateFlow<com.google.firebase.auth.FirebaseUser?> = _user

    private val _verificationId = MutableStateFlow<String?>(null)

    fun signInWithEmail(email: String, password: String, onSuccess: () -> Unit, onError: (String) -> Unit) {
        viewModelScope.launch {
            try {
                repository.signInWithEmail(email, password)
                _user.value = repository.getCurrentUser()
                
                if (_user.value?.isEmailVerified == true) {
                    onSuccess()
                } else {
                    onError("Please verify your email before signing in.")
                }
            } catch (e: Exception) {
                onError(e.message ?: "Login failed")
            }
        }
    }

    fun createUserWithEmail(email: String, password: String, onSuccess: () -> Unit, onError: (String) -> Unit) {
        viewModelScope.launch {
            try {
                repository.createUserWithEmail(email, password)
                repository.sendEmailVerification()
                onSuccess()
            } catch (e: Exception) {
                onError(e.message ?: "Sign up failed")
            }
        }
    }

    fun signInWithGoogle(credential: AuthCredential, onSuccess: () -> Unit, onError: (String) -> Unit) {
        viewModelScope.launch {
            try {
                repository.signInWithGoogle(credential)
                _user.value = repository.getCurrentUser()
                onSuccess()
            } catch (e: Exception) {
                onError(e.message ?: "Google sign-in failed")
            }
        }
    }
    
    fun startPhoneNumberVerification(activity: Activity, phoneNumber: String, callbacks: PhoneAuthProvider.OnVerificationStateChangedCallbacks) {
        val options = com.google.firebase.auth.PhoneAuthOptions.newBuilder(FirebaseAuth.getInstance())
            .setPhoneNumber(phoneNumber)
            .setTimeout(60L, java.util.concurrent.TimeUnit.SECONDS)
            .setActivity(activity)
            .setCallbacks(callbacks)
            .build()
        PhoneAuthProvider.verifyPhoneNumber(options)
    }

    fun signInWithPhoneCredential(credential: PhoneAuthCredential, onSuccess: () -> Unit, onError: (String) -> Unit) {
        viewModelScope.launch {
            try {
                FirebaseAuth.getInstance().signInWithCredential(credential).await()
                _user.value = repository.getCurrentUser()
                onSuccess()
            } catch (e: Exception) {
                onError(e.message ?: "Phone sign-in failed")
            }
        }
    }

    fun setVerificationId(verificationId: String) {
        _verificationId.value = verificationId
    }

    fun signOut() {
        repository.signOut()
        _user.value = null
    }
}
