package com.elmahdi.travelsuite.ui.screens.debts

import android.net.Uri
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.LazyRow
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Add
import androidx.compose.material.icons.filled.Delete
import androidx.compose.material.icons.filled.Image
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.Card
import androidx.compose.material3.ExtendedFloatingActionButton
import androidx.compose.material3.FilterChip
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedButton
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
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.lifecycle.ViewModel
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import androidx.lifecycle.viewModelScope
import coil.compose.AsyncImage
import com.elmahdi.travelsuite.data.auth.SessionManager
import com.elmahdi.travelsuite.data.local.entity.DebtEntity
import com.elmahdi.travelsuite.data.repository.CustomerRepository
import com.elmahdi.travelsuite.data.repository.DebtRepository
import com.elmahdi.travelsuite.domain.model.DebtStatus
import com.elmahdi.travelsuite.domain.model.DebtType
import com.elmahdi.travelsuite.domain.model.Permission
import com.elmahdi.travelsuite.ui.common.AppDropdown
import com.elmahdi.travelsuite.ui.common.ConfirmDeleteDialog
import com.elmahdi.travelsuite.ui.common.DateField
import com.elmahdi.travelsuite.ui.common.EmptyState
import com.elmahdi.travelsuite.ui.common.InfoRow
import com.elmahdi.travelsuite.ui.common.SearchField
import com.elmahdi.travelsuite.ui.common.formatDate
import com.elmahdi.travelsuite.ui.common.formatMoney
import com.elmahdi.travelsuite.ui.screens.bookings.MoneyField
import com.elmahdi.travelsuite.ui.theme.DebtRed
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.ExperimentalCoroutinesApi
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.SharingStarted
import kotlinx.coroutines.flow.combine
import kotlinx.coroutines.flow.flatMapLatest
import kotlinx.coroutines.flow.stateIn
import kotlinx.coroutines.launch
import java.io.File
import javax.inject.Inject

@OptIn(ExperimentalCoroutinesApi::class)
@HiltViewModel
class DebtsViewModel @Inject constructor(
    private val repository: DebtRepository,
    customerRepository: CustomerRepository,
    session: SessionManager,
) : ViewModel() {
    val query = MutableStateFlow("")
    val statusFilter = MutableStateFlow<DebtStatus?>(null)

    val debts = combine(query, statusFilter) { q, s -> q to s }
        .flatMapLatest { (q, s) -> repository.observeAll(q, s) }
        .stateIn(viewModelScope, SharingStarted.WhileSubscribed(5000), emptyList())
    val customers = customerRepository.observeAll("")
        .stateIn(viewModelScope, SharingStarted.WhileSubscribed(5000), emptyList())
    val permissions = session.permissions
        .stateIn(viewModelScope, SharingStarted.WhileSubscribed(5000), emptySet())

    fun save(debt: DebtEntity, isNew: Boolean, image: Uri?) =
        viewModelScope.launch { repository.save(debt, isNew, image) }

    fun delete(id: String) = viewModelScope.launch { repository.delete(id) }
}

@Composable
fun DebtsScreen(viewModel: DebtsViewModel = hiltViewModel()) {
    val debts by viewModel.debts.collectAsStateWithLifecycle()
    val customers by viewModel.customers.collectAsStateWithLifecycle()
    val query by viewModel.query.collectAsStateWithLifecycle()
    val statusFilter by viewModel.statusFilter.collectAsStateWithLifecycle()
    val permissions by viewModel.permissions.collectAsStateWithLifecycle()
    var editTarget by remember { mutableStateOf<DebtEntity?>(null) }
    var showAdd by remember { mutableStateOf(false) }
    var deleteTarget by remember { mutableStateOf<DebtEntity?>(null) }

    Scaffold(
        floatingActionButton = {
            if (Permission.ADD_DATA in permissions) {
                ExtendedFloatingActionButton(
                    onClick = { showAdd = true },
                    icon = { Icon(Icons.Default.Add, contentDescription = null) },
                    text = { Text("مديونية جديدة") },
                )
            }
        },
    ) { padding ->
        Column(Modifier.fillMaxSize().padding(padding)) {
            Text("المديونية", style = MaterialTheme.typography.titleLarge, modifier = Modifier.padding(16.dp))
            SearchField(query, { viewModel.query.value = it })
            LazyRow(
                contentPadding = PaddingValues(horizontal = 16.dp, vertical = 8.dp),
                horizontalArrangement = Arrangement.spacedBy(8.dp),
            ) {
                item {
                    FilterChip(
                        selected = statusFilter == null,
                        onClick = { viewModel.statusFilter.value = null },
                        label = { Text("الكل") },
                    )
                }
                items(DebtStatus.entries) { status ->
                    FilterChip(
                        selected = statusFilter == status,
                        onClick = { viewModel.statusFilter.value = status },
                        label = { Text(status.arabic) },
                    )
                }
            }
            if (debts.isEmpty()) {
                EmptyState("لا توجد مديونيات")
            } else {
                LazyColumn(
                    contentPadding = PaddingValues(16.dp),
                    verticalArrangement = Arrangement.spacedBy(10.dp),
                ) {
                    items(debts, key = { it.id }) { debt ->
                        Card(
                            Modifier.fillMaxWidth().clickable(
                                enabled = Permission.EDIT_DATA in permissions,
                            ) { editTarget = debt },
                        ) {
                            Column(Modifier.padding(14.dp), verticalArrangement = Arrangement.spacedBy(4.dp)) {
                                Row(
                                    Modifier.fillMaxWidth(),
                                    horizontalArrangement = Arrangement.SpaceBetween,
                                    verticalAlignment = Alignment.CenterVertically,
                                ) {
                                    Text(debt.partyName, fontWeight = FontWeight.Bold,
                                        style = MaterialTheme.typography.titleMedium)
                                    Row(verticalAlignment = Alignment.CenterVertically) {
                                        if (debt.transferImageLocalPath.isNotBlank() ||
                                            debt.transferImageUrl.isNotBlank()
                                        ) {
                                            Icon(Icons.Default.Image, "صورة تحويل",
                                                tint = MaterialTheme.colorScheme.primary)
                                        }
                                        if (Permission.DELETE_DATA in permissions) {
                                            IconButton(onClick = { deleteTarget = debt }) {
                                                Icon(Icons.Default.Delete, "حذف",
                                                    tint = MaterialTheme.colorScheme.error)
                                            }
                                        }
                                    }
                                }
                                InfoRow("${debt.debtType.arabic} • ${debt.status.arabic}", formatDate(debt.date))
                                InfoRow("قيمة الدين", formatMoney(debt.amount))
                                InfoRow("المتبقي", formatMoney(debt.remaining), DebtRed)
                            }
                        }
                    }
                }
            }
        }
    }

    if (showAdd) {
        DebtEditDialog(
            debt = null,
            customers = customers.map { it.id to it.name },
            onSave = { debt, image -> viewModel.save(debt, isNew = true, image = image); showAdd = false },
            onDismiss = { showAdd = false },
        )
    }
    editTarget?.let { debt ->
        DebtEditDialog(
            debt = debt,
            customers = customers.map { it.id to it.name },
            onSave = { updated, image -> viewModel.save(updated, isNew = false, image = image); editTarget = null },
            onDismiss = { editTarget = null },
        )
    }
    deleteTarget?.let { debt ->
        ConfirmDeleteDialog(
            message = "هل تريد حذف مديونية ${debt.partyName} بقيمة ${formatMoney(debt.amount)}؟",
            onConfirm = { viewModel.delete(debt.id); deleteTarget = null },
            onDismiss = { deleteTarget = null },
        )
    }
}

@Composable
private fun DebtEditDialog(
    debt: DebtEntity?,
    customers: List<Pair<String, String>>,
    onSave: (DebtEntity, Uri?) -> Unit,
    onDismiss: () -> Unit,
) {
    var form by remember {
        mutableStateOf(debt ?: DebtEntity(partyName = "", date = System.currentTimeMillis()))
    }
    var pickedImage by remember { mutableStateOf<Uri?>(null) }
    val imagePicker = rememberLauncherForActivityResult(
        ActivityResultContracts.PickVisualMedia()
    ) { uri -> pickedImage = uri }

    AlertDialog(
        onDismissRequest = onDismiss,
        title = { Text(if (debt == null) "مديونية جديدة" else "تعديل مديونية") },
        text = {
            Column(
                Modifier.verticalScroll(rememberScrollState()),
                verticalArrangement = Arrangement.spacedBy(12.dp),
            ) {
                OutlinedTextField(
                    value = form.partyName,
                    onValueChange = { form = form.copy(partyName = it) },
                    label = { Text("اسم الشركة أو العميل") },
                    singleLine = true,
                    modifier = Modifier.fillMaxWidth(),
                )
                AppDropdown(
                    label = "ربط بعميل مسجل (اختياري)",
                    options = customers,
                    selected = customers.firstOrNull { it.first == form.customerId },
                    optionLabel = { it.second },
                    onSelect = { form = form.copy(customerId = it.first,
                        partyName = form.partyName.ifBlank { it.second }) },
                )
                AppDropdown(
                    label = "نوع الدين",
                    options = DebtType.entries,
                    selected = form.debtType,
                    optionLabel = { it.arabic },
                    onSelect = { form = form.copy(debtType = it) },
                )
                DateField("التاريخ", form.date, { form = form.copy(date = it) })
                MoneyField("قيمة الدين", form.amount, { form = form.copy(amount = it) }, Modifier.fillMaxWidth())
                MoneyField("المدفوع", form.paidAmount, { form = form.copy(paidAmount = it) }, Modifier.fillMaxWidth())
                InfoRow("المتبقي (تلقائي)", formatMoney(form.amount - form.paidAmount), DebtRed)
                InfoRow("الحالة (تلقائي)", DebtStatus.from(form.amount, form.paidAmount).arabic)

                OutlinedButton(
                    onClick = {
                        imagePicker.launch(
                            androidx.activity.result.PickVisualMediaRequest(
                                ActivityResultContracts.PickVisualMedia.ImageOnly
                            )
                        )
                    },
                    modifier = Modifier.fillMaxWidth(),
                ) {
                    Icon(Icons.Default.Image, contentDescription = null)
                    Text("  صورة من التحويل")
                }
                val preview: Any? = pickedImage
                    ?: form.transferImageLocalPath.takeIf { it.isNotBlank() }?.let { File(it) }
                    ?: form.transferImageUrl.takeIf { it.isNotBlank() }
                if (preview != null) {
                    AsyncImage(
                        model = preview,
                        contentDescription = "صورة التحويل",
                        contentScale = ContentScale.Crop,
                        modifier = Modifier.fillMaxWidth().height(140.dp),
                    )
                }

                OutlinedTextField(
                    value = form.notes,
                    onValueChange = { form = form.copy(notes = it) },
                    label = { Text("ملاحظات") },
                    modifier = Modifier.fillMaxWidth(),
                )
            }
        },
        confirmButton = {
            TextButton(onClick = {
                if (form.partyName.isNotBlank()) onSave(form, pickedImage)
            }) { Text("حفظ") }
        },
        dismissButton = { TextButton(onClick = onDismiss) { Text("إلغاء") } },
    )
}
