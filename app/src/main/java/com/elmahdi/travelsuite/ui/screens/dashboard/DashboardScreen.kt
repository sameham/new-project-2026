package com.elmahdi.travelsuite.ui.screens.dashboard

import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.material3.Card
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.lifecycle.ViewModel
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import androidx.lifecycle.viewModelScope
import com.elmahdi.travelsuite.data.auth.SessionManager
import com.elmahdi.travelsuite.data.repository.DashboardRepository
import com.elmahdi.travelsuite.data.repository.DashboardSummary
import com.elmahdi.travelsuite.domain.model.Permission
import com.elmahdi.travelsuite.ui.common.InfoRow
import com.elmahdi.travelsuite.ui.common.StatCard
import com.elmahdi.travelsuite.ui.common.formatDate
import com.elmahdi.travelsuite.ui.common.formatMoney
import com.elmahdi.travelsuite.ui.theme.DebtRed
import com.elmahdi.travelsuite.ui.theme.Primary
import com.elmahdi.travelsuite.ui.theme.ProfitGreen
import com.elmahdi.travelsuite.ui.theme.WarningOrange
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.SharingStarted
import kotlinx.coroutines.flow.stateIn
import javax.inject.Inject

@HiltViewModel
class DashboardViewModel @Inject constructor(
    repository: DashboardRepository,
    session: SessionManager,
) : ViewModel() {
    val summary = repository.observeSummary()
        .stateIn(viewModelScope, SharingStarted.WhileSubscribed(5000), DashboardSummary())
    val permissions = session.permissions
        .stateIn(viewModelScope, SharingStarted.WhileSubscribed(5000), emptySet())
}

@Composable
fun DashboardScreen(
    onOpenBookings: () -> Unit,
    onOpenDebts: () -> Unit,
    viewModel: DashboardViewModel = hiltViewModel(),
) {
    val summary by viewModel.summary.collectAsStateWithLifecycle()
    val permissions by viewModel.permissions.collectAsStateWithLifecycle()
    val canSeeProfits = Permission.VIEW_PROFITS in permissions

    LazyColumn(
        modifier = Modifier.fillMaxSize(),
        contentPadding = androidx.compose.foundation.layout.PaddingValues(16.dp),
        verticalArrangement = Arrangement.spacedBy(12.dp),
    ) {
        item {
            Text("لوحة التحكم", style = MaterialTheme.typography.titleLarge)
        }
        item {
            Row(horizontalArrangement = Arrangement.spacedBy(12.dp)) {
                StatCard(
                    "المتبقي على العملاء",
                    formatMoney(summary.totalRemainingOnCustomers),
                    DebtRed,
                    Modifier.weight(1f),
                )
                StatCard(
                    "إجمالي الأرباح",
                    if (canSeeProfits) formatMoney(summary.totalProfit) else "•••",
                    ProfitGreen,
                    Modifier.weight(1f),
                )
            }
        }
        item {
            Row(horizontalArrangement = Arrangement.spacedBy(12.dp)) {
                StatCard(
                    "إجمالي الاستردادات",
                    formatMoney(summary.totalRefunds),
                    WarningOrange,
                    Modifier.weight(1f),
                )
                StatCard(
                    "رصيد المحفظة",
                    formatMoney(summary.walletBalance),
                    Primary,
                    Modifier.weight(1f),
                )
            }
        }

        // تنبيهات مختصرة
        if (summary.upcoming24h.isNotEmpty() || summary.postponed.isNotEmpty() ||
            summary.totalRemainingOnCustomers > 0
        ) {
            item {
                Card(Modifier.fillMaxWidth()) {
                    Column(Modifier.padding(14.dp), verticalArrangement = Arrangement.spacedBy(6.dp)) {
                        Text("تنبيهات", style = MaterialTheme.typography.titleMedium, color = WarningOrange)
                        if (summary.upcoming24h.isNotEmpty())
                            Text("• ${summary.upcoming24h.size} رحلة خلال 24 ساعة")
                        if (summary.postponed.isNotEmpty())
                            Text("• ${summary.postponed.size} رحلة مؤجلة تحتاج متابعة")
                        if (summary.totalRemainingOnCustomers > 0)
                            Text("• مديونيات قائمة بإجمالي ${formatMoney(summary.totalRemainingOnCustomers)}")
                    }
                }
            }
        }

        item {
            Text(
                "الرحلات القادمة خلال 24 ساعة",
                style = MaterialTheme.typography.titleMedium,
                modifier = Modifier.padding(top = 8.dp),
            )
        }
        if (summary.upcoming24h.isEmpty()) {
            item { Text("لا توجد رحلات خلال 24 ساعة", color = MaterialTheme.colorScheme.onSurfaceVariant) }
        } else {
            items(summary.upcoming24h.size) { i ->
                val booking = summary.upcoming24h[i]
                Card(Modifier.fillMaxWidth().clickable(onClick = onOpenBookings)) {
                    Column(Modifier.padding(14.dp), verticalArrangement = Arrangement.spacedBy(4.dp)) {
                        Text(booking.customerName, fontWeight = FontWeight.Bold)
                        InfoRow("${booking.fromAirport} ← ${booking.toAirport}",
                            "${formatDate(booking.departAt)} ${booking.departTime}")
                    }
                }
            }
        }

        item {
            Text(
                "الرحلات المؤجلة",
                style = MaterialTheme.typography.titleMedium,
                modifier = Modifier.padding(top = 8.dp),
            )
        }
        if (summary.postponed.isEmpty()) {
            item { Text("لا توجد رحلات مؤجلة", color = MaterialTheme.colorScheme.onSurfaceVariant) }
        } else {
            items(summary.postponed.size) { i ->
                val booking = summary.postponed[i]
                Card(Modifier.fillMaxWidth().clickable(onClick = onOpenBookings)) {
                    Column(Modifier.padding(14.dp), verticalArrangement = Arrangement.spacedBy(4.dp)) {
                        Text(booking.customerName, fontWeight = FontWeight.Bold)
                        InfoRow("${booking.fromAirport} ← ${booking.toAirport}", formatDate(booking.departAt))
                    }
                }
            }
        }
    }
}
