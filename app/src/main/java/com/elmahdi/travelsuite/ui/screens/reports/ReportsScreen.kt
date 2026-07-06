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
import androidx.compose.material3.Card
import androidx.compose.material3.FilterChip
import androidx.compose.material3.MaterialTheme
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
import com.elmahdi.travelsuite.data.repository.CustomerBalance
import com.elmahdi.travelsuite.data.repository.ProfitReport
import com.elmahdi.travelsuite.data.repository.ReportsRepository
import com.elmahdi.travelsuite.data.local.entity.BookingEntity
import com.elmahdi.travelsuite.data.local.entity.DebtEntity
import com.elmahdi.travelsuite.data.local.entity.PaymentEntity
import com.elmahdi.travelsuite.domain.model.Permission
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
    BY_DATE("حسب التاريخ"),
}

data class ReportsUiState(
    val kind: ReportKind = ReportKind.DAILY_PROFIT,
    val date: LocalDate = LocalDate.now(),
    val from: LocalDate = LocalDate.now().withDayOfMonth(1),
    val to: LocalDate = LocalDate.now(),
    val profit: ProfitReport? = null,
    val balances: List<CustomerBalance> = emptyList(),
    val bookings: List<BookingEntity> = emptyList(),
    val debts: List<DebtEntity> = emptyList(),
    val payments: List<PaymentEntity> = emptyList(),
)

@HiltViewModel
class ReportsViewModel @Inject constructor(
    private val repository: ReportsRepository,
    session: SessionManager,
) : ViewModel() {
    private val _state = MutableStateFlow(ReportsUiState())
    val state = _state.asStateFlow()
    val permissions = session.permissions
        .stateIn(viewModelScope, SharingStarted.WhileSubscribed(5000), emptySet())

    fun select(kind: ReportKind) { _state.value = _state.value.copy(kind = kind); refresh() }
    fun setDate(d: LocalDate) { _state.value = _state.value.copy(date = d); refresh() }
    fun setFrom(d: LocalDate) { _state.value = _state.value.copy(from = d); refresh() }
    fun setTo(d: LocalDate) { _state.value = _state.value.copy(to = d); refresh() }

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
                ReportKind.BY_DATE -> {
                    val r = repository.byDateRange(s.from, s.to)
                    s.copy(bookings = r.bookings, debts = r.debts, payments = r.payments)
                }
            }
        }
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
    val canSeeProfits = Permission.VIEW_PROFITS in permissions

    LaunchedEffect(Unit) { viewModel.refresh() }

    Column(Modifier.fillMaxSize()) {
        Text("التقارير", style = MaterialTheme.typography.titleLarge, modifier = Modifier.padding(16.dp))
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
                        item { Text("الحجوزات (${state.bookings.size})",
                            style = MaterialTheme.typography.titleMedium) }
                        items(state.bookings, key = { "b${it.id}" }) { b ->
                            Card(Modifier.fillMaxWidth()) {
                                Column(Modifier.padding(12.dp)) {
                                    Text(b.customerName, fontWeight = FontWeight.Bold)
                                    InfoRow("${b.fromAirport} ← ${b.toAirport}", formatDate(b.departAt))
                                }
                            }
                        }
                    }
                    item { Text("المدفوعات (${state.payments.size})",
                        style = MaterialTheme.typography.titleMedium) }
                    items(state.payments, key = { "p${it.id}" }) { p ->
                        Card(Modifier.fillMaxWidth()) {
                            Column(Modifier.padding(12.dp)) {
                                Text(p.payeeName, fontWeight = FontWeight.Bold)
                                InfoRow(p.category.arabic,
                                    "${formatDate(p.date)} • ${formatMoney(p.amountEgp)}")
                            }
                        }
                    }
                    if (state.kind == ReportKind.BY_DATE) {
                        item { Text("المديونيات (${state.debts.size})",
                            style = MaterialTheme.typography.titleMedium) }
                        items(state.debts, key = { "d${it.id}" }) { d ->
                            Card(Modifier.fillMaxWidth()) {
                                Column(Modifier.padding(12.dp)) {
                                    Text(d.partyName, fontWeight = FontWeight.Bold)
                                    InfoRow(d.status.arabic, formatMoney(d.remaining))
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
