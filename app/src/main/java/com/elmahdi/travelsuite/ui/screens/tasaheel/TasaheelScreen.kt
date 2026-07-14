package com.elmahdi.travelsuite.ui.screens.tasaheel

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
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Add
import androidx.compose.material.icons.filled.Delete
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.Card
import androidx.compose.material3.ExtendedFloatingActionButton
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Scaffold
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
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.lifecycle.ViewModel
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import androidx.lifecycle.viewModelScope
import com.elmahdi.travelsuite.data.auth.SessionManager
import com.elmahdi.travelsuite.data.local.entity.TasaheelEntity
import com.elmahdi.travelsuite.data.repository.TasaheelRepository
import com.elmahdi.travelsuite.domain.model.Permission
import com.elmahdi.travelsuite.ui.common.ConfirmDeleteDialog
import com.elmahdi.travelsuite.ui.common.DateField
import com.elmahdi.travelsuite.ui.common.EmptyState
import com.elmahdi.travelsuite.ui.common.InfoRow
import com.elmahdi.travelsuite.ui.common.SearchField
import com.elmahdi.travelsuite.ui.common.formatDate
import com.elmahdi.travelsuite.ui.common.formatMoney
import com.elmahdi.travelsuite.ui.screens.bookings.MoneyField
import com.elmahdi.travelsuite.ui.theme.DebtRed
import com.elmahdi.travelsuite.ui.theme.ProfitGreen
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.ExperimentalCoroutinesApi
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.SharingStarted
import kotlinx.coroutines.flow.flatMapLatest
import kotlinx.coroutines.flow.stateIn
import kotlinx.coroutines.launch
import javax.inject.Inject

@OptIn(ExperimentalCoroutinesApi::class)
@HiltViewModel
class TasaheelViewModel @Inject constructor(
    private val repository: TasaheelRepository,
    session: SessionManager,
) : ViewModel() {
    val query = MutableStateFlow("")
    val items = query.flatMapLatest { repository.observeAll(it) }
        .stateIn(viewModelScope, SharingStarted.WhileSubscribed(5000), emptyList())
    val permissions = session.permissions
        .stateIn(viewModelScope, SharingStarted.WhileSubscribed(5000), emptySet())

    fun save(item: TasaheelEntity) = viewModelScope.launch { repository.save(item) }
    fun delete(id: String) = viewModelScope.launch { repository.delete(id) }
}

@Composable
fun TasaheelScreen(viewModel: TasaheelViewModel = hiltViewModel()) {
    val items by viewModel.items.collectAsStateWithLifecycle()
    val query by viewModel.query.collectAsStateWithLifecycle()
    val permissions by viewModel.permissions.collectAsStateWithLifecycle()
    var editTarget by remember { mutableStateOf<TasaheelEntity?>(null) }
    var showAdd by remember { mutableStateOf(false) }
    var deleteTarget by remember { mutableStateOf<TasaheelEntity?>(null) }
    val canSeeProfit = Permission.VIEW_PROFITS in permissions

    Scaffold(
        floatingActionButton = {
            if (Permission.ADD_DATA in permissions) {
                ExtendedFloatingActionButton(
                    onClick = { showAdd = true },
                    icon = { Icon(Icons.Default.Add, contentDescription = null) },
                    text = { Text("عملية جديدة") },
                )
            }
        },
    ) { padding ->
        Column(Modifier.fillMaxSize().padding(padding)) {
            Text("تساهيل", style = MaterialTheme.typography.titleLarge, modifier = Modifier.padding(16.dp))
            SearchField(query, { viewModel.query.value = it })
            if (items.isEmpty()) {
                EmptyState("لا توجد عمليات تساهيل")
            } else {
                LazyColumn(
                    contentPadding = PaddingValues(16.dp),
                    verticalArrangement = Arrangement.spacedBy(10.dp),
                ) {
                    items(items, key = { it.id }) { item ->
                        Card(
                            Modifier.fillMaxWidth().clickable(
                                enabled = Permission.EDIT_DATA in permissions,
                            ) { editTarget = item },
                        ) {
                            Column(Modifier.padding(14.dp), verticalArrangement = Arrangement.spacedBy(4.dp)) {
                                Row(
                                    Modifier.fillMaxWidth(),
                                    horizontalArrangement = Arrangement.SpaceBetween,
                                    verticalAlignment = Alignment.CenterVertically,
                                ) {
                                    Text(item.name, fontWeight = FontWeight.Bold,
                                        style = MaterialTheme.typography.titleMedium)
                                    if (Permission.DELETE_DATA in permissions) {
                                        IconButton(onClick = { deleteTarget = item }) {
                                            Icon(Icons.Default.Delete, "حذف",
                                                tint = MaterialTheme.colorScheme.error)
                                        }
                                    }
                                }
                                InfoRow("${item.consulate} • عدد ${item.count}", formatDate(item.date))
                                InfoRow("المتبقي", formatMoney(item.remaining), DebtRed)
                                if (canSeeProfit) InfoRow("الربح", formatMoney(item.profit), ProfitGreen)
                            }
                        }
                    }
                }
            }
        }
    }

    if (showAdd) {
        TasaheelEditDialog(null, { viewModel.save(it); showAdd = false }, { showAdd = false })
    }
    editTarget?.let { item ->
        TasaheelEditDialog(item, { viewModel.save(it); editTarget = null }, { editTarget = null })
    }
    deleteTarget?.let { item ->
        ConfirmDeleteDialog(
            message = "هل تريد حذف عملية ${item.name}؟",
            onConfirm = { viewModel.delete(item.id); deleteTarget = null },
            onDismiss = { deleteTarget = null },
        )
    }
}

@Composable
private fun TasaheelEditDialog(
    item: TasaheelEntity?,
    onSave: (TasaheelEntity) -> Unit,
    onDismiss: () -> Unit,
) {
    var form by remember {
        mutableStateOf(item ?: TasaheelEntity(name = "", consulate = "", date = System.currentTimeMillis()))
    }
    AlertDialog(
        onDismissRequest = onDismiss,
        title = { Text(if (item == null) "عملية تساهيل جديدة" else "تعديل عملية") },
        text = {
            Column(
                Modifier.verticalScroll(rememberScrollState()),
                verticalArrangement = Arrangement.spacedBy(12.dp),
            ) {
                OutlinedTextField(
                    value = form.name,
                    onValueChange = { form = form.copy(name = it) },
                    label = { Text("الاسم") },
                    singleLine = true,
                    modifier = Modifier.fillMaxWidth(),
                )
                OutlinedTextField(
                    value = if (form.count == 0) "" else form.count.toString(),
                    onValueChange = { form = form.copy(count = it.toIntOrNull() ?: 0) },
                    label = { Text("العدد") },
                    keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Number),
                    singleLine = true,
                    modifier = Modifier.fillMaxWidth(),
                )
                OutlinedTextField(
                    value = form.consulate,
                    onValueChange = { form = form.copy(consulate = it) },
                    label = { Text("القنصلية") },
                    singleLine = true,
                    modifier = Modifier.fillMaxWidth(),
                )
                DateField("التاريخ", form.date, { form = form.copy(date = it) })
                MoneyField("سعر البيع", form.sellPrice, { form = form.copy(sellPrice = it) }, Modifier.fillMaxWidth())
                MoneyField("سعر الشراء", form.buyPrice, { form = form.copy(buyPrice = it) }, Modifier.fillMaxWidth())
                MoneyField("المدفوع", form.paidAmount, { form = form.copy(paidAmount = it) }, Modifier.fillMaxWidth())
                InfoRow("الربح (تلقائي)", formatMoney(form.profit), ProfitGreen)
                InfoRow("المتبقي (تلقائي)", formatMoney(form.remaining), DebtRed)
                OutlinedTextField(
                    value = form.notes,
                    onValueChange = { form = form.copy(notes = it) },
                    label = { Text("ملاحظات اختيارية") },
                    modifier = Modifier.fillMaxWidth(),
                )
            }
        },
        confirmButton = {
            TextButton(onClick = { if (form.name.isNotBlank()) onSave(form) }) { Text("حفظ") }
        },
        dismissButton = { TextButton(onClick = onDismiss) { Text("إلغاء") } },
    )
}
