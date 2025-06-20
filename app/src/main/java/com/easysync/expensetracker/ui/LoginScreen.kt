package com.easysync.expensetracker.ui

import android.app.Activity
import android.widget.Toast
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.foundation.layout.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.input.PasswordVisualTransformation
import androidx.compose.ui.unit.dp
import androidx.lifecycle.viewmodel.compose.viewModel
import com.easysync.expensetracker.R
import com.easysync.expensetracker.ui.viewmodel.AuthViewModel
import com.google.android.gms.auth.api.signin.GoogleSignIn
import com.google.android.gms.auth.api.signin.GoogleSignInOptions
import com.google.android.gms.common.api.ApiException
import com.google.firebase.auth.GoogleAuthProvider
import com.google.firebase.auth.PhoneAuthCredential
import com.google.firebase.auth.PhoneAuthProvider

@Composable
fun LoginScreen(authViewModel: AuthViewModel = viewModel(), onLoginSuccess: () -> Unit) {
    var email by remember { mutableStateOf("") }
    var password by remember { mutableStateOf("") }
    var phoneNumber by remember { mutableStateOf("") }
    var otp by remember { mutableStateOf("") }
    var showOtpField by remember { mutableStateOf(false) }
    val context = LocalContext.current
    val activity = context as Activity

    val googleSignInLauncher = rememberLauncherForActivityResult(
        contract = ActivityResultContracts.StartActivityForResult()
    ) { result ->
        val task = GoogleSignIn.getSignedInAccountFromIntent(result.data)
        try {
            val account = task.getResult(ApiException::class.java)!!
            val credential = GoogleAuthProvider.getCredential(account.idToken!!, null)
            authViewModel.signInWithGoogle(credential, onSuccess = onLoginSuccess, onError = {
                Toast.makeText(context, it, Toast.LENGTH_SHORT).show()
            })
        } catch (e: ApiException) {
            Toast.makeText(context, "Google sign in failed: ${e.message}", Toast.LENGTH_SHORT).show()
        }
    }

    val callbacks = object : PhoneAuthProvider.OnVerificationStateChangedCallbacks() {
        override fun onVerificationCompleted(credential: PhoneAuthCredential) {
            authViewModel.signInWithPhoneCredential(credential, onLoginSuccess) {
                Toast.makeText(context, it, Toast.LENGTH_SHORT).show()
            }
        }

        override fun onVerificationFailed(e: com.google.firebase.FirebaseException) {
            Toast.makeText(context, "Verification failed: ${e.message}", Toast.LENGTH_SHORT).show()
        }

        override fun onCodeSent(verificationId: String, token: PhoneAuthProvider.ForceResendingToken) {
            authViewModel.setVerificationId(verificationId)
            showOtpField = true
        }
    }

    Column(
        modifier = Modifier
            .fillMaxSize()
            .padding(16.dp),
        verticalArrangement = Arrangement.Center,
        horizontalAlignment = Alignment.CenterHorizontally
    ) {
        OutlinedTextField(value = email, onValueChange = { email = it }, label = { Text("Email") })
        Spacer(modifier = Modifier.height(8.dp))
        OutlinedTextField(
            value = password,
            onValueChange = { password = it },
            label = { Text("Password") },
            visualTransformation = PasswordVisualTransformation()
        )
        Spacer(modifier = Modifier.height(16.dp))
        Row {
            Button(onClick = {
                authViewModel.signInWithEmail(email, password, onLoginSuccess) {
                    Toast.makeText(context, it, Toast.LENGTH_SHORT).show()
                }
            }) { Text("Sign In") }
            Spacer(modifier = Modifier.width(8.dp))
            Button(onClick = {
                authViewModel.createUserWithEmail(email, password, {
                    Toast.makeText(context, "Verification email sent.", Toast.LENGTH_SHORT).show()
                }) {
                    Toast.makeText(context, it, Toast.LENGTH_SHORT).show()
                }
            }) { Text("Sign Up") }
        }

        Spacer(modifier = Modifier.height(16.dp))

        Button(onClick = {
            val gso = GoogleSignInOptions.Builder(GoogleSignInOptions.DEFAULT_SIGN_IN)
                .requestIdToken(context.getString(R.string.default_web_client_id))
                .requestEmail()
                .build()
            val googleSignInClient = GoogleSignIn.getClient(context, gso)
            googleSignInLauncher.launch(googleSignInClient.signInIntent)
        }) { Text("Sign in with Google") }
        
        Spacer(modifier = Modifier.height(16.dp))

        OutlinedTextField(value = phoneNumber, onValueChange = { phoneNumber = it }, label = { Text("Phone Number") })
        Button(onClick = {
            authViewModel.startPhoneNumberVerification(activity, phoneNumber, callbacks)
        }) { Text("Send OTP") }

        if (showOtpField) {
            Spacer(modifier = Modifier.height(8.dp))
            OutlinedTextField(value = otp, onValueChange = { otp = it }, label = { Text("OTP") })
            Button(onClick = {
                authViewModel.verificationId.value?.let { verificationId ->
                    val credential = PhoneAuthProvider.getCredential(verificationId, otp)
                    authViewModel.signInWithPhoneCredential(credential, onLoginSuccess) {
                        Toast.makeText(context, it, Toast.LENGTH_SHORT).show()
                    }
                }
            }) { Text("Verify OTP") }
        }
    }
} 