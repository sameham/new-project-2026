package com.elmahdi.travelsuite.ui.screens.bookings

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
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Add
import androidx.compose.material.icons.filled.Delete
import androidx.compose.material3.Card
import androidx.compose.material3.ExtendedFloatingActionButton
import androidx.compose.material3.FilterChip
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
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
import com.elmahdi.travelsuite.data.local.entity.BookingEntity
import com.elmahdi.travelsuite.data.repository.BookingRepository
import com.elmahdi.travelsuite.domain.model.BookingStatus
import com.elmahdi.travelsuite.domain.model.Permission
import com.elmahdi.travelsuite.domain.model.TripType
import com.elmahdi.travelsuite.ui.common.ConfirmDeleteDialog
import com.elmahdi.travelsuite.ui.common.EmptyState
import com.elmahdi.travelsuite.ui.common.InfoRow
import com.elmahdi.travelsuite.ui.common.SearchField
import com.elmahdi.travelsuite.ui.common.formatDate
import com.elmahdi.travelsuite.ui.common.formatMoney
import com.elmahdi.travelsuite.ui.theme.DebtRed
import com.elmahdi.travelsuite.ui.theme.ProfitGreen
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.ExperimentalCoroutinesApi
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.SharingStarted
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.combine
import kotlinx.coroutines.flow.flatMapLatest
import kotlinx.coroutines.flow.stateIn
import kotlinx.coroutines.launch
import javax.inject.Inject

@OptIn(ExperimentalCoroutinesApi::class)
@HiltViewModel
class BookingsViewModel @Inject constructor(
    private val repository: BookingRepository,
    session: SessionManager,
) : ViewModel() {
    val query = MutableStateFlow("")
    val statusFilter = MutableStateFlow<BookingStatus?>(null)

    val bookings = combine(query, statusFilter) { q, s -> q to s }
        .flatMapLatest { (q, s) -> repository.observeAll(q, s) }
        .stateIn(viewModelScope, SharingStarted.WhileSubscribed(5000), emptyList())

    val permissions = session.permissions
        .stateIn(viewModelScope, SharingStarted.WhileSubscribed(5000), emptySet())

    fun delete(id: String) = viewModelScope.launch { repository.delete(id) }
}

@Composable
fun BookingsScreen(onEdit: (String?) -> Unit, viewModel: BookingsViewModel = hiltViewModel()) {
    val bookings by viewModel.bookings.collectAsStateWithLifecycle()
    val query by viewModel.query.collectAsStateWithLifecycle()
    val statusFilter by viewModel.statusFilter.collectAsStateWithLifecycle()
    val permissions by viewModel.permissions.collectAsStateWithLifecycle()
    var deleteTarget by remember { mutableStateOf<BookingEntity?>(null) }

    Scaffold(
        floatingActionButton = {
            if (Permission.ADD_DATA in permissions) {
                ExtendedFloatingActionButton(
                    onClick = { onEdit(null) },
                    icon = { Icon(Icons.Default.Add, contentDescription = null) },
                    text = { Text("حجز جديد") },
                )
            }
        },
    ) { padding ->
        Column(Modifier.fillMaxSize().padding(padding)) {
            Text(
                "حجوزات الطيران",
                style = MaterialTheme.typography.titleLarge,
                modifier = Modifier.padding(16.dp),
            )
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
                items(BookingStatus.entries) { status ->
                    FilterChip(
                        selected = statusFilter == status,
                        onClick = { viewModel.statusFilter.value = status },
                        label = { Text(status.arabic) },
                    )
                }
            }
            if (bookings.isEmpty()) {
                EmptyState("لا توجد حجوزات")
            } else {
                LazyColumn(
                    contentPadding = PaddingValues(16.dp),
                    verticalArrangement = Arrangement.spacedBy(12.dp),
                ) {
                    items(bookings, key = { it.id }) { booking ->
                        BookingCard(
                            booking = booking,
                            canEdit = Permission.EDIT_DATA in permissions,
                            canDelete = Permission.DELETE_DATA in permissions,
                            canSeeProfit = Permission.VIEW_PROFITS in permissions,
                            onClick = { if (Permission.EDIT_DATA in permissions) onEdit(booking.id) },
                            onDelete = { deleteTarget = booking },
                        )
                    }
                }
            }
        }
    }

    deleteTarget?.let { booking ->
        ConfirmDeleteDialog(
            message = "هل تريد حذف حجز ${booking.customerName} (${booking.fromAirport} ← ${booking.toAirport})؟",
            onConfirm = { viewModel.delete(booking.id); deleteTarget = null },
            onDismiss = { deleteTarget = null },
        )
    }
}

@Composable
private fun BookingCard(
    booking: BookingEntity,
    canEdit: Boolean,
    canDelete: Boolean,
    canSeeProfit: Boolean,
    onClick: () -> Unit,
    onDelete: () -> Unit,
) {
    Card(Modifier.fillMaxWidth().clickable(enabled = canEdit, onClick = onClick)) {
        Column(Modifier.padding(14.dp), verticalArrangement = Arrangement.spacedBy(6.dp)) {
            Row(
                Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically,
            ) {
                Text(booking.customerName, fontWeight = FontWeight.Bold,
                    style = MaterialTheme.typography.titleMedium)
                Row(verticalAlignment = Alignment.CenterVertically) {
                    Text(booking.status.arabic, color = MaterialTheme.colorScheme.primary)
                    if (canDelete) {
                        IconButton(onClick = onDelete) {
                            Icon(Icons.Default.Delete, "حذف", tint = MaterialTheme.colorScheme.error)
                        }
                    }
                }
            }
            InfoRow(
                "${booking.fromAirport} ← ${booking.toAirport}",
                "${formatDate(booking.departAt)} ${booking.departTime}",
            )
            if (booking.tripType == TripType.ROUND_TRIP) {
                InfoRow(
                    "عودة: ${booking.returnFromAirport} ← ${booking.returnToAirport}",
                    "${formatDate(booking.returnAt)} ${booking.returnTime}",
                )
            }
            InfoRow("المتبقي", formatMoney(booking.remaining), DebtRed)
            if (canSeeProfit) InfoRow("الربح", formatMoney(booking.profit), ProfitGreen)
        }
    }
}
