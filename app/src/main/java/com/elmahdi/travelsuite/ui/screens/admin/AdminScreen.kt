package com.elmahdi.travelsuite.ui.screens.admin

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.Button
import androidx.compose.material3.Card
import androidx.compose.material3.Checkbox
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Switch
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.PasswordVisualTransformation
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.lifecycle.ViewModel
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import androidx.lifecycle.viewModelScope
import com.elmahdi.travelsuite.data.auth.AuthRepository
import com.elmahdi.travelsuite.data.auth.SessionManager
import com.elmahdi.travelsuite.data.backup.BackupRepository
import com.elmahdi.travelsuite.data.local.entity.UserEntity
import com.elmahdi.travelsuite.data.repository.AuditRepository
import com.elmahdi.travelsuite.data.repository.UserAdminRepository
import com.elmahdi.travelsuite.domain.model.Permission
import com.elmahdi.travelsuite.domain.model.UserRole
import com.elmahdi.travelsuite.ui.common.AppDropdown
import com.elmahdi.travelsuite.ui.common.ConfirmDeleteDialog
import com.elmahdi.travelsuite.ui.common.InfoRow
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.SharingStarted
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.stateIn
import kotlinx.coroutines.launch
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale
import javax.inject.Inject

data class AdminUiState(
    val message: String? = null,
    val busy: Boolean = false,
    val backups: List<String> = emptyList(),
    val loggedOut: Boolean = false,
)

@HiltViewModel
class AdminViewModel @Inject constructor(
    private val authRepository: AuthRepository,
    private val userAdmin: UserAdminRepository,
    private val backupRepository: BackupRepository,
    auditRepository: AuditRepository,
    session: SessionManager,
) : ViewModel() {
    private val _state = MutableStateFlow(AdminUiState())
    val state = _state.asStateFlow()

    val users = userAdmin.observeAll()
        .stateIn(viewModelScope, SharingStarted.WhileSubscribed(5000), emptyList())
    val auditLogs = auditRepository.observeRecent()
        .stateIn(viewModelScope, SharingStarted.WhileSubscribed(5000), emptyList())
    val currentUser = session.currentUser

    private fun run(block: suspend () -> String) {
        _state.value = _state.value.copy(busy = true, message = null)
        viewModelScope.launch {
            val message = runCatching { block() }
                .getOrElse { it.message ?: "حدث خطأ غير متوقع" }
            _state.value = _state.value.copy(busy = false, message = message)
        }
    }

    fun changePassword(current: String, new: String) = run {
        authRepository.changePassword(current, new).getOrThrow()
        "تم تغيير كلمة المرور بنجاح"
    }

    fun createUser(email: String, password: String, name: String, role: UserRole) = run {
        userAdmin.createUser(email, password, name, role).getOrThrow()
        "تمت إضافة المستخدم $email"
    }

    fun updateUser(user: UserEntity) = run {
        userAdmin.updateUser(user, "تعديل بيانات ${user.email}")
        "تم حفظ التعديلات"
    }

    fun setActive(user: UserEntity, active: Boolean) = run {
        userAdmin.setActive(user, active)
        if (active) "تم تفعيل ${user.email}" else "تم حظر ${user.email}"
    }

    fun updatePermissions(user: UserEntity, permissions: Set<Permission>) = run {
        userAdmin.updatePermissions(user, permissions)
        "تم تعديل صلاحيات ${user.email}"
    }

    fun deleteUser(user: UserEntity) = run {
        userAdmin.deleteUser(user)
        "تم حذف ${user.email}"
    }

    fun createBackup() = run {
        val name = backupRepository.createBackup().getOrThrow()
        "تم إنشاء النسخة الاحتياطية: $name"
    }

    fun loadBackups() = run {
        val list = backupRepository.listCloudBackups().getOrThrow()
        _state.value = _state.value.copy(backups = list)
        if (list.isEmpty()) "لا توجد نسخ احتياطية" else "تم تحميل ${list.size} نسخة"
    }

    fun restoreBackup(name: String) = run {
        backupRepository.restoreBackup(name).getOrThrow()
        "تم استرجاع النسخة: $name"
    }

    fun wipeDatabase() = run {
        val backup = backupRepository.wipeDatabase().getOrThrow()
        "تم حذف قاعدة البيانات بعد أخذ نسخة: $backup"
    }

    fun logout() {
        viewModelScope.launch {
            authRepository.logout()
            _state.value = _state.value.copy(loggedOut = true)
        }
    }
}

@Composable
fun AdminScreen(onLoggedOut: () -> Unit, viewModel: AdminViewModel = hiltViewModel()) {
    val state by viewModel.state.collectAsStateWithLifecycle()
    val users by viewModel.users.collectAsStateWithLifecycle()
    val auditLogs by viewModel.auditLogs.collectAsStateWithLifecycle()
    val currentUser by viewModel.currentUser.collectAsStateWithLifecycle()

    var showChangePassword by remember { mutableStateOf(false) }
    var showAddUser by remember { mutableStateOf(false) }
    var permissionsTarget by remember { mutableStateOf<UserEntity?>(null) }
    var deleteUserTarget by remember { mutableStateOf<UserEntity?>(null) }
    var showWipeConfirm by remember { mutableStateOf(false) }
    var showRestorePicker by remember { mutableStateOf(false) }

    LaunchedEffect(state.loggedOut) { if (state.loggedOut) onLoggedOut() }

    val isAdmin = currentUser?.role == UserRole.ADMIN
    val perms = currentUser?.permissions() ?: emptySet()

    LazyColumn(
        Modifier.fillMaxSize(),
        contentPadding = PaddingValues(16.dp),
        verticalArrangement = Arrangement.spacedBy(12.dp),
    ) {
        item { Text("لوحة المدير", style = MaterialTheme.typography.titleLarge) }

        state.message?.let { item { Card { Text(it, Modifier.padding(12.dp)) } } }

        item {
            Card(Modifier.fillMaxWidth()) {
                Column(Modifier.padding(14.dp), verticalArrangement = Arrangement.spacedBy(10.dp)) {
                    Text("الحساب", style = MaterialTheme.typography.titleMedium)
                    OutlinedButton(onClick = { showChangePassword = true }, Modifier.fillMaxWidth()) {
                        Text("تغيير كلمة المرور")
                    }
                    OutlinedButton(onClick = viewModel::logout, Modifier.fillMaxWidth()) {
                        Text("تسجيل الخروج")
                    }
                }
            }
        }

        if (isAdmin || Permission.MANAGE_USERS in perms) {
            item {
                Card(Modifier.fillMaxWidth()) {
                    Column(Modifier.padding(14.dp), verticalArrangement = Arrangement.spacedBy(10.dp)) {
                        Text("المستخدمون", style = MaterialTheme.typography.titleMedium)
                        users.forEach { user ->
                            Column(verticalArrangement = Arrangement.spacedBy(4.dp)) {
                                Row(
                                    Modifier.fillMaxWidth(),
                                    horizontalArrangement = Arrangement.SpaceBetween,
                                    verticalAlignment = Alignment.CenterVertically,
                                ) {
                                    Column {
                                        Text(user.displayName.ifBlank { user.email },
                                            fontWeight = FontWeight.Bold)
                                        Text("${user.role.arabic}${if (!user.isActive) " • محظور" else ""}",
                                            color = MaterialTheme.colorScheme.onSurfaceVariant)
                                    }
                                    Switch(
                                        checked = user.isActive,
                                        onCheckedChange = { viewModel.setActive(user, it) },
                                        enabled = user.id != currentUser?.id,
                                    )
                                }
                                Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                                    TextButton(onClick = { permissionsTarget = user }) { Text("الصلاحيات") }
                                    if (user.id != currentUser?.id) {
                                        TextButton(onClick = { deleteUserTarget = user }) {
                                            Text("حذف", color = MaterialTheme.colorScheme.error)
                                        }
                                    }
                                }
                                HorizontalDivider()
                            }
                        }
                        Button(onClick = { showAddUser = true }, Modifier.fillMaxWidth(),
                            enabled = !state.busy) {
                            Text("+ إضافة مستخدم")
                        }
                    }
                }
            }
        }

        if (isAdmin || Permission.CREATE_BACKUP in perms || Permission.WIPE_DATABASE in perms) {
            item {
                Card(Modifier.fillMaxWidth()) {
                    Column(Modifier.padding(14.dp), verticalArrangement = Arrangement.spacedBy(10.dp)) {
                        Text("النسخ الاحتياطي وقاعدة البيانات",
                            style = MaterialTheme.typography.titleMedium)
                        if (isAdmin || Permission.CREATE_BACKUP in perms) {
                            OutlinedButton(onClick = viewModel::createBackup,
                                Modifier.fillMaxWidth(), enabled = !state.busy) {
                                Text("إنشاء نسخة احتياطية الآن")
                            }
                            OutlinedButton(
                                onClick = { viewModel.loadBackups(); showRestorePicker = true },
                                Modifier.fillMaxWidth(), enabled = !state.busy,
                            ) { Text("استرجاع نسخة احتياطية") }
                        }
                        if (isAdmin || Permission.WIPE_DATABASE in perms) {
                            Button(
                                onClick = { showWipeConfirm = true },
                                Modifier.fillMaxWidth(),
                                enabled = !state.busy,
                                colors = androidx.compose.material3.ButtonDefaults.buttonColors(
                                    containerColor = MaterialTheme.colorScheme.error,
                                ),
                            ) { Text("حذف قاعدة البيانات (مع نسخة احتياطية)") }
                        }
                    }
                }
            }
        }

        item { Text("سجل العمليات", style = MaterialTheme.typography.titleMedium) }
        items(auditLogs.size) { i ->
            val log = auditLogs[i]
            Card(Modifier.fillMaxWidth()) {
                Column(Modifier.padding(12.dp), verticalArrangement = Arrangement.spacedBy(2.dp)) {
                    InfoRow(log.action.arabic, SimpleDateFormat("yyyy/MM/dd HH:mm", Locale.US)
                        .format(Date(log.timestamp)))
                    Text(log.userEmail, color = MaterialTheme.colorScheme.onSurfaceVariant,
                        style = MaterialTheme.typography.bodyMedium)
                    if (log.details.isNotBlank()) Text(log.details,
                        style = MaterialTheme.typography.bodyMedium)
                }
            }
        }
    }

    if (showChangePassword) {
        ChangePasswordDialog(
            onConfirm = { current, new ->
                viewModel.changePassword(current, new); showChangePassword = false
            },
            onDismiss = { showChangePassword = false },
        )
    }
    if (showAddUser) {
        AddUserDialog(
            onConfirm = { email, password, name, role ->
                viewModel.createUser(email, password, name, role); showAddUser = false
            },
            onDismiss = { showAddUser = false },
        )
    }
    permissionsTarget?.let { user ->
        PermissionsDialog(
            user = user,
            onConfirm = { viewModel.updatePermissions(user, it); permissionsTarget = null },
            onDismiss = { permissionsTarget = null },
        )
    }
    deleteUserTarget?.let { user ->
        ConfirmDeleteDialog(
            message = "هل تريد حذف المستخدم ${user.email}؟",
            onConfirm = { viewModel.deleteUser(user); deleteUserTarget = null },
            onDismiss = { deleteUserTarget = null },
        )
    }
    if (showWipeConfirm) {
        ConfirmDeleteDialog(
            message = "سيتم أخذ نسخة احتياطية كاملة ثم حذف كل البيانات محليًا وسحابيًا. هل أنت متأكد؟",
            onConfirm = { viewModel.wipeDatabase(); showWipeConfirm = false },
            onDismiss = { showWipeConfirm = false },
        )
    }
    if (showRestorePicker) {
        AlertDialog(
            onDismissRequest = { showRestorePicker = false },
            title = { Text("اختر نسخة للاسترجاع") },
            text = {
                Column(Modifier.verticalScroll(rememberScrollState()),
                    verticalArrangement = Arrangement.spacedBy(8.dp)) {
                    if (state.backups.isEmpty()) Text("جارٍ التحميل… أو لا توجد نسخ")
                    state.backups.forEach { name ->
                        OutlinedButton(
                            onClick = { viewModel.restoreBackup(name); showRestorePicker = false },
                            Modifier.fillMaxWidth(),
                        ) { Text(name) }
                    }
                }
            },
            confirmButton = {},
            dismissButton = { TextButton(onClick = { showRestorePicker = false }) { Text("إغلاق") } },
        )
    }
}

@Composable
private fun ChangePasswordDialog(
    onConfirm: (current: String, new: String) -> Unit,
    onDismiss: () -> Unit,
) {
    var current by remember { mutableStateOf("") }
    var newPass by remember { mutableStateOf("") }
    AlertDialog(
        onDismissRequest = onDismiss,
        title = { Text("تغيير كلمة المرور") },
        text = {
            Column(verticalArrangement = Arrangement.spacedBy(12.dp)) {
                OutlinedTextField(current, { current = it }, label = { Text("كلمة المرور الحالية") },
                    visualTransformation = PasswordVisualTransformation(), singleLine = true)
                OutlinedTextField(newPass, { newPass = it }, label = { Text("كلمة المرور الجديدة") },
                    visualTransformation = PasswordVisualTransformation(), singleLine = true)
            }
        },
        confirmButton = {
            TextButton(onClick = {
                if (current.isNotBlank() && newPass.length >= 6) onConfirm(current, newPass)
            }) { Text("تغيير") }
        },
        dismissButton = { TextButton(onClick = onDismiss) { Text("إلغاء") } },
    )
}

@Composable
private fun AddUserDialog(
    onConfirm: (email: String, password: String, name: String, role: UserRole) -> Unit,
    onDismiss: () -> Unit,
) {
    var email by remember { mutableStateOf("") }
    var password by remember { mutableStateOf("") }
    var name by remember { mutableStateOf("") }
    var role by remember { mutableStateOf(UserRole.STAFF) }
    AlertDialog(
        onDismissRequest = onDismiss,
        title = { Text("إضافة مستخدم") },
        text = {
            Column(verticalArrangement = Arrangement.spacedBy(12.dp)) {
                OutlinedTextField(name, { name = it }, label = { Text("الاسم") }, singleLine = true)
                OutlinedTextField(email, { email = it }, label = { Text("البريد الإلكتروني") }, singleLine = true)
                OutlinedTextField(password, { password = it }, label = { Text("كلمة المرور (6 أحرف على الأقل)") },
                    visualTransformation = PasswordVisualTransformation(), singleLine = true)
                AppDropdown(
                    label = "الدور",
                    options = UserRole.entries,
                    selected = role,
                    optionLabel = { it.arabic },
                    onSelect = { role = it },
                )
                Text("يتطلب اتصالًا بالإنترنت",
                    color = MaterialTheme.colorScheme.onSurfaceVariant,
                    style = MaterialTheme.typography.bodyMedium)
            }
        },
        confirmButton = {
            TextButton(onClick = {
                if (email.isNotBlank() && password.length >= 6) onConfirm(email, password, name, role)
            }) { Text("إضافة") }
        },
        dismissButton = { TextButton(onClick = onDismiss) { Text("إلغاء") } },
    )
}

@Composable
private fun PermissionsDialog(
    user: UserEntity,
    onConfirm: (Set<Permission>) -> Unit,
    onDismiss: () -> Unit,
) {
    var selected by remember { mutableStateOf(user.permissions()) }
    AlertDialog(
        onDismissRequest = onDismiss,
        title = { Text("صلاحيات ${user.displayName.ifBlank { user.email }}") },
        text = {
            Column(Modifier.verticalScroll(rememberScrollState())) {
                Permission.entries.forEach { permission ->
                    Row(
                        Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.SpaceBetween,
                        verticalAlignment = Alignment.CenterVertically,
                    ) {
                        Text(permission.arabic)
                        Checkbox(
                            checked = permission in selected,
                            onCheckedChange = { checked ->
                                selected = if (checked) selected + permission else selected - permission
                            },
                        )
                    }
                }
            }
        },
        confirmButton = { TextButton(onClick = { onConfirm(selected) }) { Text("حفظ") } },
        dismissButton = { TextButton(onClick = onDismiss) { Text("إلغاء") } },
    )
}
