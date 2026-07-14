package com.elmahdi.travelsuite.ui.screens.customers

import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Add
import androidx.compose.material.icons.filled.Delete
import androidx.compose.material.icons.filled.Edit
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.Card
import androidx.compose.material3.ExtendedFloatingActionButton
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Scaffold
import androidx.compose.material3.SnackbarHost
import androidx.compose.material3.SnackbarHostState
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.lifecycle.ViewModel
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import androidx.lifecycle.viewModelScope
import com.elmahdi.travelsuite.data.auth.SessionManager
import com.elmahdi.travelsuite.data.local.entity.CustomerEntity
import com.elmahdi.travelsuite.data.repository.CustomerRepository
import com.elmahdi.travelsuite.domain.model.CustomerType
import com.elmahdi.travelsuite.domain.model.Permission
import com.elmahdi.travelsuite.ui.common.AppDropdown
import com.elmahdi.travelsuite.ui.common.ConfirmDeleteDialog
import com.elmahdi.travelsuite.ui.common.EmptyState
import com.elmahdi.travelsuite.ui.common.SearchField
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.ExperimentalCoroutinesApi
import kotlinx.coroutines.flow.MutableSharedFlow
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.SharingStarted
import kotlinx.coroutines.flow.asSharedFlow
import kotlinx.coroutines.flow.flatMapLatest
import kotlinx.coroutines.flow.stateIn
import kotlinx.coroutines.launch
import javax.inject.Inject

@OptIn(ExperimentalCoroutinesApi::class)
@HiltViewModel
class CustomersViewModel @Inject constructor(
    private val repository: CustomerRepository,
    session: SessionManager,
) : ViewModel() {
    val query = MutableStateFlow("")
    val customers = query.flatMapLatest { repository.observeAll(it) }
        .stateIn(viewModelScope, SharingStarted.WhileSubscribed(5000), emptyList())
    val permissions = session.permissions
        .stateIn(viewModelScope, SharingStarted.WhileSubscribed(5000), emptySet())

    private val _messages = MutableSharedFlow<String>()
    val messages = _messages.asSharedFlow()

    fun save(customer: CustomerEntity) = viewModelScope.launch { repository.save(customer) }

    fun delete(id: String) = viewModelScope.launch {
        repository.delete(id).onFailure { _messages.emit(it.message ?: "تعذر الحذف") }
    }
}

@Composable
fun CustomersScreen(
    onOpenCustomer: (String) -> Unit,
    viewModel: CustomersViewModel = hiltViewModel(),
) {
    val customers by viewModel.customers.collectAsStateWithLifecycle()
    val query by viewModel.query.collectAsStateWithLifecycle()
    val permissions by viewModel.permissions.collectAsStateWithLifecycle()
    var editTarget by remember { mutableStateOf<CustomerEntity?>(null) }
    var showAdd by remember { mutableStateOf(false) }
    var deleteTarget by remember { mutableStateOf<CustomerEntity?>(null) }
    val snackbar = remember { SnackbarHostState() }

    androidx.compose.runtime.LaunchedEffect(Unit) {
        viewModel.messages.collect { snackbar.showSnackbar(it) }
    }

    Scaffold(
        snackbarHost = { SnackbarHost(snackbar) },
        floatingActionButton = {
            if (Permission.ADD_DATA in permissions) {
                ExtendedFloatingActionButton(
                    onClick = { showAdd = true },
                    icon = { Icon(Icons.Default.Add, contentDescription = null) },
                    text = { Text("عميل جديد") },
                )
            }
        },
    ) { padding ->
        Column(Modifier.fillMaxSize().padding(padding)) {
            Text("العملاء", style = MaterialTheme.typography.titleLarge, modifier = Modifier.padding(16.dp))
            SearchField(query, { viewModel.query.value = it })
            if (customers.isEmpty()) {
                EmptyState("لا يوجد عملاء")
            } else {
                LazyColumn(
                    contentPadding = PaddingValues(16.dp),
                    verticalArrangement = Arrangement.spacedBy(10.dp),
                ) {
                    items(customers, key = { it.id }) { customer ->
                        Card(Modifier.fillMaxWidth().clickable { onOpenCustomer(customer.id) }) {
                            Row(
                                Modifier.fillMaxWidth().padding(14.dp),
                                horizontalArrangement = Arrangement.SpaceBetween,
                                verticalAlignment = Alignment.CenterVertically,
                            ) {
                                Column {
                                    Text(customer.name, fontWeight = FontWeight.Bold,
                                        style = MaterialTheme.typography.titleMedium)
                                    Text(
                                        "${customer.type.arabic}${if (customer.phone.isNotBlank()) " • ${customer.phone}" else ""}",
                                        color = MaterialTheme.colorScheme.onSurfaceVariant,
                                    )
                                }
                                Row {
                                    if (Permission.EDIT_DATA in permissions) {
                                        IconButton(onClick = { editTarget = customer }) {
                                            Icon(Icons.Default.Edit, "تعديل")
                                        }
                                    }
                                    if (Permission.DELETE_DATA in permissions) {
                                        IconButton(onClick = { deleteTarget = customer }) {
                                            Icon(Icons.Default.Delete, "حذف",
                                                tint = MaterialTheme.colorScheme.error)
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    if (showAdd) {
        CustomerEditDialog(
            customer = null,
            onSave = { viewModel.save(it); showAdd = false },
            onDismiss = { showAdd = false },
        )
    }
    editTarget?.let { customer ->
        CustomerEditDialog(
            customer = customer,
            onSave = { viewModel.save(it); editTarget = null },
            onDismiss = { editTarget = null },
        )
    }
    deleteTarget?.let { customer ->
        ConfirmDeleteDialog(
            message = "هل تريد حذف العميل ${customer.name}؟ لن يُحذف إذا كان مرتبطًا بعمليات.",
            onConfirm = { viewModel.delete(customer.id); deleteTarget = null },
            onDismiss = { deleteTarget = null },
        )
    }
}

/** نافذة إضافة/تعديل عميل — تُستخدم أيضًا من شاشة الحجز الجديد */
@Composable
fun CustomerEditDialog(
    customer: CustomerEntity?,
    onSave: (CustomerEntity) -> Unit,
    onDismiss: () -> Unit,
) {
    var form by remember { mutableStateOf(customer ?: CustomerEntity(name = "")) }
    AlertDialog(
        onDismissRequest = onDismiss,
        title = { Text(if (customer == null) "عميل جديد" else "تعديل عميل") },
        text = {
            Column(verticalArrangement = Arrangement.spacedBy(12.dp)) {
                OutlinedTextField(
                    value = form.name,
                    onValueChange = { form = form.copy(name = it) },
                    label = { Text("الاسم") },
                    singleLine = true,
                    modifier = Modifier.fillMaxWidth(),
                )
                OutlinedTextField(
                    value = form.phone,
                    onValueChange = { form = form.copy(phone = it) },
                    label = { Text("رقم الهاتف") },
                    singleLine = true,
                    modifier = Modifier.fillMaxWidth(),
                )
                AppDropdown(
                    label = "نوع العميل",
                    options = CustomerType.entries,
                    selected = form.type,
                    optionLabel = { it.arabic },
                    onSelect = { form = form.copy(type = it) },
                )
                OutlinedTextField(
                    value = form.notes,
                    onValueChange = { form = form.copy(notes = it) },
                    label = { Text("ملاحظات") },
                    modifier = Modifier.fillMaxWidth(),
                )
            }
        },
        confirmButton = {
            TextButton(
                onClick = { if (form.name.isNotBlank()) onSave(form) },
            ) { Text("حفظ") }
        },
        dismissButton = { TextButton(onClick = onDismiss) { Text("إلغاء") } },
    )
}
