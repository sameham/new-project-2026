package com.elmahdi.travelsuite.ui.screens.login

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.Button
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.text.input.PasswordVisualTransformation
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.lifecycle.ViewModel
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import androidx.lifecycle.viewModelScope
import com.elmahdi.travelsuite.data.auth.AuthRepository
import com.elmahdi.travelsuite.data.repository.AuditRepository
import com.elmahdi.travelsuite.domain.model.AuditAction
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch
import javax.inject.Inject

data class LoginUiState(
    val email: String = "",
    val password: String = "",
    val loading: Boolean = false,
    val error: String? = null,
    val success: Boolean = false,
)

@HiltViewModel
class LoginViewModel @Inject constructor(
    private val authRepository: AuthRepository,
    private val audit: AuditRepository,
) : ViewModel() {
    private val _state = MutableStateFlow(LoginUiState())
    val state = _state.asStateFlow()

    fun onEmail(v: String) = _state.value.let { _state.value = it.copy(email = v, error = null) }
    fun onPassword(v: String) = _state.value.let { _state.value = it.copy(password = v, error = null) }

    fun login() {
        val s = _state.value
        if (s.email.isBlank() || s.password.isBlank()) {
            _state.value = s.copy(error = "أدخل البريد الإلكتروني وكلمة المرور")
            return
        }
        _state.value = s.copy(loading = true, error = null)
        viewModelScope.launch {
            authRepository.login(s.email, s.password).fold(
                onSuccess = {
                    audit.log(AuditAction.LOGIN)
                    _state.value = _state.value.copy(loading = false, success = true)
                },
                onFailure = { e ->
                    // بدون إنترنت: إن كانت هناك جلسة سابقة صالحة ندخل محليًا
                    if (authRepository.canWorkOffline()) {
                        _state.value = _state.value.copy(loading = false, success = true)
                    } else {
                        _state.value = _state.value.copy(
                            loading = false,
                            error = e.message ?: "تعذر تسجيل الدخول. تحقق من البيانات أو الاتصال.",
                        )
                    }
                },
            )
        }
    }
}

@Composable
fun LoginScreen(onLoggedIn: () -> Unit, viewModel: LoginViewModel = hiltViewModel()) {
    val state by viewModel.state.collectAsStateWithLifecycle()

    LaunchedEffect(state.success) { if (state.success) onLoggedIn() }

    Column(
        modifier = Modifier.fillMaxSize().verticalScroll(rememberScrollState()).padding(24.dp),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.Center,
    ) {
        Text("وكالة المهدي للسفر", style = MaterialTheme.typography.titleLarge)
        Text(
            "إدارة الحسابات والحجوزات",
            style = MaterialTheme.typography.bodyMedium,
            color = MaterialTheme.colorScheme.onSurfaceVariant,
        )
        Column(Modifier.padding(top = 32.dp), verticalArrangement = Arrangement.spacedBy(16.dp)) {
            OutlinedTextField(
                value = state.email,
                onValueChange = viewModel::onEmail,
                label = { Text("البريد الإلكتروني") },
                keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Email),
                singleLine = true,
                modifier = Modifier.fillMaxWidth(),
            )
            OutlinedTextField(
                value = state.password,
                onValueChange = viewModel::onPassword,
                label = { Text("كلمة المرور") },
                visualTransformation = PasswordVisualTransformation(),
                keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Password),
                singleLine = true,
                modifier = Modifier.fillMaxWidth(),
            )
            state.error?.let {
                Text(it, color = MaterialTheme.colorScheme.error, style = MaterialTheme.typography.bodyMedium)
            }
            Button(
                onClick = viewModel::login,
                enabled = !state.loading,
                modifier = Modifier.fillMaxWidth().height(54.dp),
            ) {
                if (state.loading) CircularProgressIndicator(Modifier.height(24.dp))
                else Text("تسجيل الدخول")
            }
        }
    }
}
