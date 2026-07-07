package com.elmahdi.travelsuite.ui.screens.reports

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
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.PictureAsPdf
import androidx.compose.material3.Card
import androidx.compose.material3.FilterChip
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.lifecycle.ViewModel
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import androidx.lifecycle.viewModelScope
import com.elmahdi.travelsuite.data.auth.SessionManager
import com.elmahdi.travelsuite.data.local.entity.BookingEntity
import com.elmahdi.travelsuite.data.local.entity.CustomerEntity
import com.elmahdi.travelsuite.data.local.entity.DebtEntity
import com.elmahdi.travelsuite.data.local.entity.PaymentEntity
import com.elmahdi.travelsuite.data.local.entity.TasaheelEntity
import com.elmahdi.travelsuite.data.repository.CustomerBalance
import com.elmahdi.travelsuite.data.repository.CustomerRepository
import com.elmahdi.travelsuite.data.repository.ProfitReport
import com.elmahdi.travelsuite.data.repository.ReportsRepository
import com.elmahdi.travelsuite.domain.model.Permission
import com.elmahdi.travelsuite.ui.common.AppDropdown
import com.elmahdi.travelsuite.ui.common.DateField
import com.elmahdi.travelsuite.ui.common.EmptyState
import com.elmahdi.travelsuite.ui.common.InfoRow
import com.elmahdi.travelsuite.ui.common.formatDate
import com.elmahdi.travelsuite.ui.common.formatMoney
import com.elmahdi.travelsuite.ui.theme.DebtRed
import com.elmahdi.travelsuite.ui.theme.ProfitGreen
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.SharingStarted
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.stateIn
import kotlinx.coroutines.launch
import java.time.Instant
import java.time.LocalDate
import java.time.YearMonth
import java.time.ZoneId
import javax.inject.Inject

enum class ReportKind(val arabic: String) {
    DAILY_PROFIT("أرباح اليوم"),
    MONTHLY_PROFIT("أرباح الشهر"),
    CUSTOMER_BALANCES("المتبقي على العملاء"),
    UPCOMING_BOOKINGS("الحجوزات القادمة"),
    OPEN_DEBTS("المديونيات المفتوحة"),
    PAYMENTS("المدفوعات"),
    BY_CUSTOMER("حسب العميل"),
    BY_DATE("حسب التاريخ"),
}

data class ReportsUiState(
    val kind: ReportKind = ReportKind.DAILY_PROFIT,
    val date: LocalDate = LocalDate.now(),
    val from: LocalDate = LocalDate.now().withDayOfMonth(1),
    val to: LocalDate = LocalDate.now(),
    val customerId: String = "",
    val profit: ProfitReport? = null,
    val balances: List<CustomerBalance> = emptyList(),
    val bookings: List<BookingEntity> = emptyList(),
    val tasaheel: List<TasaheelEntity> = emptyList(),
    val debts: List<DebtEntity> = emptyList(),
    val payments: List<PaymentEntity> = emptyList(),
)

@HiltViewModel
class ReportsViewModel @Inject constructor(
    private val repository: ReportsRepository,
    private val pdfExporter: ReportPdfExporter,
    customerRepository: CustomerRepository,
    session: SessionManager,
) : ViewModel() {
    private val _state = MutableStateFlow(ReportsUiState())
    val state = _state.asStateFlow()
    val permissions = session.permissions
        .stateIn(viewModelScope, SharingStarted.WhileSubscribed(5000), emptySet())
    val customers = customerRepository.observeAll("")
        .stateIn(viewModelScope, SharingStarted.WhileSubscribed(5000), emptyList())

    fun select(kind: ReportKind) { _state.value = _state.value.copy(kind = kind); refresh() }
    fun setDate(d: LocalDate) { _state.value = _state.value.copy(date = d); refresh() }
    fun setFrom(d: LocalDate) { _state.value = _state.value.copy(from = d); refresh() }
    fun setTo(d: LocalDate) { _state.value = _state.value.copy(to = d); refresh() }
    fun setCustomer(id: String) { _state.value = _state.value.copy(customerId = id); refresh() }

    fun refresh() {
        val s = _state.value
        viewModelScope.launch {
            _state.value = when (s.kind) {
                ReportKind.DAILY_PROFIT ->
                    s.copy(profit = repository.dailyProfit(s.date))
                ReportKind.MONTHLY_PROFIT ->
                    s.copy(profit = repository.monthlyProfit(YearMonth.from(s.date)))
                ReportKind.CUSTOMER_BALANCES ->
                    s.copy(balances = repository.customerBalances())
                ReportKind.UPCOMING_BOOKINGS ->
                    s.copy(bookings = repository.upcomingBookings())
                ReportKind.OPEN_DEBTS ->
                    s.copy(debts = repository.openDebts())
                ReportKind.PAYMENTS ->
                    s.copy(payments = repository.payments(s.from, s.to))
                ReportKind.BY_CUSTOMER -> {
                    if (s.customerId.isBlank()) s else {
                        val r = repository.byCustomer(s.customerId)
                        s.copy(bookings = r.bookings, tasaheel = r.tasaheel, debts = r.debts)
                    }
                }
                ReportKind.BY_DATE -> {
                    val r = repository.byDateRange(s.from, s.to)
                    s.copy(bookings = r.bookings, tasaheel = r.tasaheel,
                        debts = r.debts, payments = r.payments)
                }
            }
        }
    }

    /** تصدير التقرير المعروض حاليًا إلى PDF ومشاركته */
    fun exportPdf(customerName: String = "") {
        val s = _state.value
        val lines = buildList {
            when (s.kind) {
                ReportKind.DAILY_PROFIT, ReportKind.MONTHLY_PROFIT -> s.profit?.let { p ->
                    add("أرباح الطيران" to formatMoney(p.bookingsProfit))
                    add("أرباح تساهيل" to formatMoney(p.tasaheelProfit))
                    add("عمولات المدفوعات" to formatMoney(p.paymentsProfit))
                    add("الإجمالي" to formatMoney(p.total))
                }
                ReportKind.CUSTOMER_BALANCES -> s.balances.forEach {
                    add(it.name to formatMoney(it.remaining))
                }
                ReportKind.UPCOMING_BOOKINGS -> s.bookings.forEach {
                    add("${it.customerName} | ${it.fromAirport} - ${it.toAirport}"
                        to "${formatDate(it.departAt)} ${it.departTime}")
                }
                ReportKind.OPEN_DEBTS -> s.debts.forEach {
                    add("${it.partyName} (${it.status.arabic})" to formatMoney(it.remaining))
                }
                ReportKind.PAYMENTS -> s.payments.forEach {
                    add("${it.payeeName} (${it.category.arabic})"
                        to "${formatDate(it.date)} | ${formatMoney(it.amountEgp)}")
                }
                ReportKind.BY_CUSTOMER, ReportKind.BY_DATE -> {
                    s.bookings.forEach {
                        add("حجز: ${it.customerName} ${it.fromAirport}-${it.toAirport}"
                            to "${formatDate(it.departAt)} | متبقي ${formatMoney(it.remaining)}")
                    }
                    s.tasaheel.forEach {
                        add("تساهيل: ${it.name} (${it.consulate})"
                            to "${formatDate(it.date)} | متبقي ${formatMoney(it.remaining)}")
                    }
                    s.payments.forEach {
                        add("دفعة: ${it.payeeName}" to "${formatDate(it.date)} | ${formatMoney(it.amountEgp)}")
                    }
                    s.debts.forEach {
                        add("دين: ${it.partyName}" to "متبقي ${formatMoney(it.remaining)}")
                    }
                }
            }
        }
        val title = when (s.kind) {
            ReportKind.BY_CUSTOMER -> "تقرير ${s.kind.arabic}: $customerName"
            else -> "تقرير ${s.kind.arabic}"
        }
        viewModelScope.launch { pdfExporter.exportAndShare(title, lines) }
    }
}

private fun LocalDate.toEpochMillis(): Long =
    atStartOfDay(ZoneId.systemDefault()).toInstant().toEpochMilli()

private fun Long.toLocalDate(): LocalDate =
    Instant.ofEpochMilli(this).atZone(ZoneId.systemDefault()).toLocalDate()

@Composable
fun ReportsScreen(viewModel: ReportsViewModel = hiltViewModel()) {
    val state by viewModel.state.collectAsStateWithLifecycle()
    val permissions by viewModel.permissions.collectAsStateWithLifecycle()
    val customers by viewModel.customers.collectAsStateWithLifecycle()
    val canSeeProfits = Permission.VIEW_PROFITS in permissions
    val selectedCustomer = customers.firstOrNull { it.id == state.customerId }

    LaunchedEffect(Unit) { viewModel.refresh() }

    Column(Modifier.fillMaxSize()) {
        Row(
            Modifier.fillMaxWidth().padding(horizontal = 16.dp, vertical = 8.dp),
            horizontalArrangement = Arrangement.SpaceBetween,
        ) {
            Text("التقارير", style = MaterialTheme.typography.titleLarge)
            OutlinedButton(onClick = { viewModel.exportPdf(selectedCustomer?.name.orEmpty()) }) {
                Icon(Icons.Default.PictureAsPdf, contentDescription = null)
                Text("  PDF")
            }
        }
        LazyRow(
            contentPadding = PaddingValues(horizontal = 16.dp),
            horizontalArrangement = Arrangement.spacedBy(8.dp),
        ) {
            items(ReportKind.entries) { kind ->
                if (kind in listOf(ReportKind.DAILY_PROFIT, ReportKind.MONTHLY_PROFIT) && !canSeeProfits) {
                    return@items
                }
                FilterChip(
                    selected = state.kind == kind,
                    onClick = { viewModel.select(kind) },
                    label = { Text(kind.arabic) },
                )
            }
        }

        LazyColumn(
            contentPadding = PaddingValues(16.dp),
            verticalArrangement = Arrangement.spacedBy(10.dp),
        ) {
            when (state.kind) {
                ReportKind.DAILY_PROFIT, ReportKind.MONTHLY_PROFIT -> {
                    item {
                        DateField(
                            if (state.kind == ReportKind.DAILY_PROFIT) "اليوم" else "أي يوم من الشهر",
                            state.date.toEpochMillis(),
                            { viewModel.setDate(it.toLocalDate()) },
                        )
                    }
                    state.profit?.let { p ->
                        item {
                            Card(Modifier.fillMaxWidth()) {
                                Column(Modifier.padding(14.dp), verticalArrangement = Arrangement.spacedBy(6.dp)) {
                                    InfoRow("أرباح الطيران", formatMoney(p.bookingsProfit), ProfitGreen)
                                    InfoRow("أرباح تساهيل", formatMoney(p.tasaheelProfit), ProfitGreen)
                                    InfoRow("عمولات المدفوعات", formatMoney(p.paymentsProfit), ProfitGreen)
                                    InfoRow("الإجمالي", formatMoney(p.total), ProfitGreen)
                                }
                            }
                        }
                    }
                }
                ReportKind.CUSTOMER_BALANCES -> {
                    if (state.balances.isEmpty()) item { EmptyState("لا يوجد متبقٍ على العملاء") }
                    items(state.balances, key = { it.customerId }) { balance ->
                        Card(Modifier.fillMaxWidth()) {
                            Row(Modifier.fillMaxWidth().padding(14.dp)) {
                                InfoRow(balance.name, formatMoney(balance.remaining), DebtRed)
                            }
                        }
                    }
                }
                ReportKind.UPCOMING_BOOKINGS -> {
                    if (state.bookings.isEmpty()) item { EmptyState("لا توجد حجوزات قادمة") }
                    items(state.bookings, key = { it.id }) { b ->
                        Card(Modifier.fillMaxWidth()) {
                            Column(Modifier.padding(14.dp), verticalArrangement = Arrangement.spacedBy(4.dp)) {
                                Text(b.customerName, fontWeight = FontWeight.Bold)
                                InfoRow("${b.fromAirport} ← ${b.toAirport}",
                                    "${formatDate(b.departAt)} ${b.departTime}")
                            }
                        }
                    }
                }
                ReportKind.OPEN_DEBTS -> {
                    if (state.debts.isEmpty()) item { EmptyState("لا توجد مديونيات مفتوحة") }
                    items(state.debts, key = { it.id }) { d ->
                        Card(Modifier.fillMaxWidth()) {
                            Column(Modifier.padding(14.dp), verticalArrangement = Arrangement.spacedBy(4.dp)) {
                                Text(d.partyName, fontWeight = FontWeight.Bold)
                                InfoRow(d.status.arabic, "المتبقي: ${formatMoney(d.remaining)}")
                            }
                        }
                    }
                }
                ReportKind.BY_CUSTOMER -> {
                    item {
                        AppDropdown(
                            label = "اختر العميل",
                            options = customers,
                            selected = selectedCustomer,
                            optionLabel = { it.name },
                            onSelect = { viewModel.setCustomer(it.id) },
                        )
                    }
                    if (state.customerId.isBlank()) {
                        item { EmptyState("اختر عميلًا لعرض تقريره الكامل") }
                    } else {
                        item {
                            val total = state.bookings.sumOf { it.remaining } +
                                state.tasaheel.sumOf { it.remaining } +
                                state.debts.sumOf { it.remaining }
                            Card(Modifier.fillMaxWidth()) {
                                Row(Modifier.fillMaxWidth().padding(14.dp)) {
                                    InfoRow("إجمالي المتبقي عليه", formatMoney(total), DebtRed)
                                }
                            }
                        }
                        mixedOperations(state)
                    }
                }
                ReportKind.PAYMENTS, ReportKind.BY_DATE -> {
                    item {
                        Row(horizontalArrangement = Arrangement.spacedBy(10.dp)) {
                            DateField("من", state.from.toEpochMillis(),
                                { viewModel.setFrom(it.toLocalDate()) }, Modifier.weight(1f))
                            DateField("إلى", state.to.toEpochMillis(),
                                { viewModel.setTo(it.toLocalDate()) }, Modifier.weight(1f))
                        }
                    }
                    if (state.kind == ReportKind.BY_DATE) {
                        mixedOperations(state)
                    } else {
                        if (state.payments.isEmpty()) item { EmptyState("لا توجد مدفوعات في الفترة") }
                        items(state.payments, key = { "p${it.id}" }) { p ->
                            Card(Modifier.fillMaxWidth()) {
                                Column(Modifier.padding(12.dp)) {
                                    Text(p.payeeName, fontWeight = FontWeight.Bold)
                                    InfoRow(p.category.arabic,
                                        "${formatDate(p.date)} • ${formatMoney(p.amountEgp)}")
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}

/** أقسام الحجوزات/تساهيل/المدفوعات/الديون المشتركة بين تقريري العميل والتاريخ */
private fun androidx.compose.foundation.lazy.LazyListScope.mixedOperations(state: ReportsUiState) {
    item { Text("الحجوزات (${state.bookings.size})",
        style = androidx.compose.material3.MaterialTheme.typography.titleMedium) }
    items(state.bookings, key = { "b${it.id}" }) { b ->
        Card(Modifier.fillMaxWidth()) {
            Column(Modifier.padding(12.dp)) {
                Text(b.customerName, fontWeight = FontWeight.Bold)
                InfoRow("${b.fromAirport} ← ${b.toAirport}",
                    "${formatDate(b.departAt)} • متبقي ${formatMoney(b.remaining)}")
            }
        }
    }
    item { Text("تساهيل (${state.tasaheel.size})",
        style = androidx.compose.material3.MaterialTheme.typography.titleMedium) }
    items(state.tasaheel, key = { "t${it.id}" }) { t ->
        Card(Modifier.fillMaxWidth()) {
            Column(Modifier.padding(12.dp)) {
                Text(t.name, fontWeight = FontWeight.Bold)
                InfoRow(t.consulate, "${formatDate(t.date)} • متبقي ${formatMoney(t.remaining)}")
            }
        }
    }
    if (state.payments.isNotEmpty()) {
        item { Text("المدفوعات (${state.payments.size})",
            style = androidx.compose.material3.MaterialTheme.typography.titleMedium) }
        items(state.payments, key = { "p${it.id}" }) { p ->
            Card(Modifier.fillMaxWidth()) {
                Column(Modifier.padding(12.dp)) {
                    Text(p.payeeName, fontWeight = FontWeight.Bold)
                    InfoRow(p.category.arabic, "${formatDate(p.date)} • ${formatMoney(p.amountEgp)}")
                }
            }
        }
    }
    item { Text("المديونيات (${state.debts.size})",
        style = androidx.compose.material3.MaterialTheme.typography.titleMedium) }
    items(state.debts, key = { "d${it.id}" }) { d ->
        Card(Modifier.fillMaxWidth()) {
            Column(Modifier.padding(12.dp)) {
                Text(d.partyName, fontWeight = FontWeight.Bold)
                InfoRow(d.status.arabic, "متبقي ${formatMoney(d.remaining)}")
            }
        }
    }
}
