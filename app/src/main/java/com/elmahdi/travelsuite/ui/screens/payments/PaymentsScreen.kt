package com.elmahdi.travelsuite.ui.screens.payments

import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.LazyRow
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Add
import androidx.compose.material.icons.filled.Delete
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.Card
import androidx.compose.material3.ExtendedFloatingActionButton
import androidx.compose.material3.FilterChip
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
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.lifecycle.ViewModel
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import androidx.lifecycle.viewModelScope
import com.elmahdi.travelsuite.data.auth.SessionManager
import com.elmahdi.travelsuite.data.local.entity.PaymentEntity
import com.elmahdi.travelsuite.data.repository.PaymentRepository
import com.elmahdi.travelsuite.domain.model.PaymentCategory
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
import com.elmahdi.travelsuite.ui.theme.ProfitGreen
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.ExperimentalCoroutinesApi
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.SharingStarted
import kotlinx.coroutines.flow.combine
import kotlinx.coroutines.flow.flatMapLatest
import kotlinx.coroutines.flow.stateIn
import kotlinx.coroutines.launch
import javax.inject.Inject

@OptIn(ExperimentalCoroutinesApi::class)
@HiltViewModel
class PaymentsViewModel @Inject constructor(
    private val repository: PaymentRepository,
    session: SessionManager,
) : ViewModel() {
    val query = MutableStateFlow("")
    val categoryFilter = MutableStateFlow<PaymentCategory?>(null)

    val payments = combine(query, categoryFilter) { q, c -> q to c }
        .flatMapLatest { (q, c) -> repository.observeAll(q, c) }
        .stateIn(viewModelScope, SharingStarted.WhileSubscribed(5000), emptyList())
    val permissions = session.permissions
        .stateIn(viewModelScope, SharingStarted.WhileSubscribed(5000), emptySet())

    fun save(payment: PaymentEntity) = viewModelScope.launch { repository.save(payment) }
    fun delete(id: String) = viewModelScope.launch { repository.delete(id) }
}

@Composable
fun PaymentsScreen(viewModel: PaymentsViewModel = hiltViewModel()) {
    val payments by viewModel.payments.collectAsStateWithLifecycle()
    val query by viewModel.query.collectAsStateWithLifecycle()
    val categoryFilter by viewModel.categoryFilter.collectAsStateWithLifecycle()
    val permissions by viewModel.permissions.collectAsStateWithLifecycle()
    var editTarget by remember { mutableStateOf<PaymentEntity?>(null) }
    var showAdd by remember { mutableStateOf(false) }
    var deleteTarget by remember { mutableStateOf<PaymentEntity?>(null) }

    Scaffold(
        floatingActionButton = {
            if (Permission.ADD_DATA in permissions) {
                ExtendedFloatingActionButton(
                    onClick = { showAdd = true },
                    icon = { Icon(Icons.Default.Add, contentDescription = null) },
                    text = { Text("دفعة جديدة") },
                )
            }
        },
    ) { padding ->
        Column(Modifier.fillMaxSize().padding(padding)) {
            Text("المدفوعات", style = MaterialTheme.typography.titleLarge, modifier = Modifier.padding(16.dp))
            SearchField(query, { viewModel.query.value = it })
            LazyRow(
                contentPadding = PaddingValues(horizontal = 16.dp, vertical = 8.dp),
                horizontalArrangement = Arrangement.spacedBy(8.dp),
            ) {
                item {
                    FilterChip(
                        selected = categoryFilter == null,
                        onClick = { viewModel.categoryFilter.value = null },
                        label = { Text("الكل") },
                    )
                }
                items(PaymentCategory.entries) { category ->
                    FilterChip(
                        selected = categoryFilter == category,
                        onClick = { viewModel.categoryFilter.value = category },
                        label = { Text(category.arabic) },
                    )
                }
            }
            if (payments.isEmpty()) {
                EmptyState("لا توجد مدفوعات")
            } else {
                LazyColumn(
                    contentPadding = PaddingValues(16.dp),
                    verticalArrangement = Arrangement.spacedBy(10.dp),
                ) {
                    items(payments, key = { it.id }) { payment ->
                        Card(
                            Modifier.fillMaxWidth().clickable(
                                enabled = Permission.EDIT_DATA in permissions,
                            ) { editTarget = payment },
                        ) {
                            Column(Modifier.padding(14.dp), verticalArrangement = Arrangement.spacedBy(4.dp)) {
                                Row(
                                    Modifier.fillMaxWidth(),
                                    horizontalArrangement = Arrangement.SpaceBetween,
                                    verticalAlignment = Alignment.CenterVertically,
                                ) {
                                    Text(payment.payeeName, fontWeight = FontWeight.Bold,
                                        style = MaterialTheme.typography.titleMedium)
                                    if (Permission.DELETE_DATA in permissions) {
                                        IconButton(onClick = { deleteTarget = payment }) {
                                            Icon(Icons.Default.Delete, "حذف",
                                                tint = MaterialTheme.colorScheme.error)
                                        }
                                    }
                                }
                                InfoRow(payment.category.arabic, formatDate(payment.date))
                                InfoRow(
                                    "المبلغ (${payment.currency})",
                                    "${formatMoney(payment.amount, payment.currency)} = ${formatMoney(payment.amountEgp)}",
                                )
                                if (payment.profit != 0.0) {
                                    InfoRow("الربح/العمولة", formatMoney(payment.profit), ProfitGreen)
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    if (showAdd) {
        PaymentEditDialog(null, { viewModel.save(it); showAdd = false }, { showAdd = false })
    }
    editTarget?.let { payment ->
        PaymentEditDialog(payment, { viewModel.save(it); editTarget = null }, { editTarget = null })
    }
    deleteTarget?.let { payment ->
        ConfirmDeleteDialog(
            message = "هل تريد حذف دفعة ${payment.payeeName} بقيمة ${formatMoney(payment.amount, payment.currency)}؟",
            onConfirm = { viewModel.delete(payment.id); deleteTarget = null },
            onDismiss = { deleteTarget = null },
        )
    }
}

@Composable
private fun PaymentEditDialog(
    payment: PaymentEntity?,
    onSave: (PaymentEntity) -> Unit,
    onDismiss: () -> Unit,
) {
    var form by remember {
        mutableStateOf(payment ?: PaymentEntity(payeeName = "", date = System.currentTimeMillis()))
    }
    AlertDialog(
        onDismissRequest = onDismiss,
        title = { Text(if (payment == null) "دفعة جديدة" else "تعديل دفعة") },
        text = {
            Column(
                Modifier.verticalScroll(rememberScrollState()),
                verticalArrangement = Arrangement.spacedBy(12.dp),
            ) {
                OutlinedTextField(
                    value = form.payeeName,
                    onValueChange = { form = form.copy(payeeName = it) },
                    label = { Text("اسم الجهة المدفوع لها") },
                    singleLine = true,
                    modifier = Modifier.fillMaxWidth(),
                )
                AppDropdown(
                    label = "التصنيف",
                    options = PaymentCategory.entries,
                    selected = form.category,
                    optionLabel = { it.arabic },
                    onSelect = { form = form.copy(category = it) },
                )
                OutlinedTextField(
                    value = form.currency,
                    onValueChange = { form = form.copy(currency = it) },
                    label = { Text("نوع العملة") },
                    singleLine = true,
                    modifier = Modifier.fillMaxWidth(),
                )
                MoneyField("قيمة العملة بالمصري", form.currencyRateEgp,
                    { form = form.copy(currencyRateEgp = it) }, Modifier.fillMaxWidth())
                MoneyField("المبلغ المدفوع", form.amount,
                    { form = form.copy(amount = it) }, Modifier.fillMaxWidth())
                MoneyField("الربح أو العمولة", form.profit,
                    { form = form.copy(profit = it) }, Modifier.fillMaxWidth())
                InfoRow("بالمصري (تلقائي)", formatMoney(form.amountEgp))
                DateField("التاريخ", form.date, { form = form.copy(date = it) })
                OutlinedTextField(
                    value = form.notes,
                    onValueChange = { form = form.copy(notes = it) },
                    label = { Text("ملاحظات") },
                    modifier = Modifier.fillMaxWidth(),
                )
            }
        },
        confirmButton = {
            TextButton(onClick = { if (form.payeeName.isNotBlank()) onSave(form) }) { Text("حفظ") }
        },
        dismissButton = { TextButton(onClick = onDismiss) { Text("إلغاء") } },
    )
}
