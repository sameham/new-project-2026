package com.elmahdi.travelsuite.ui.screens.customers

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material3.Card
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.material3.TopAppBar
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.lifecycle.SavedStateHandle
import androidx.lifecycle.ViewModel
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import androidx.lifecycle.viewModelScope
import com.elmahdi.travelsuite.data.local.entity.BookingEntity
import com.elmahdi.travelsuite.data.local.entity.CustomerEntity
import com.elmahdi.travelsuite.data.local.entity.DebtEntity
import com.elmahdi.travelsuite.data.local.entity.TasaheelEntity
import com.elmahdi.travelsuite.data.repository.BookingRepository
import com.elmahdi.travelsuite.data.repository.CustomerRepository
import com.elmahdi.travelsuite.data.repository.DebtRepository
import com.elmahdi.travelsuite.data.repository.TasaheelRepository
import com.elmahdi.travelsuite.ui.common.InfoRow
import com.elmahdi.travelsuite.ui.common.formatDate
import com.elmahdi.travelsuite.ui.common.formatMoney
import com.elmahdi.travelsuite.ui.theme.DebtRed
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.SharingStarted
import kotlinx.coroutines.flow.stateIn
import javax.inject.Inject

@HiltViewModel
class CustomerDetailViewModel @Inject constructor(
    savedStateHandle: SavedStateHandle,
    customerRepository: CustomerRepository,
    bookingRepository: BookingRepository,
    tasaheelRepository: TasaheelRepository,
    debtRepository: DebtRepository,
) : ViewModel() {
    private val customerId: String = savedStateHandle.get<String>("id").orEmpty()

    val customer = customerRepository.observeById(customerId)
        .stateIn(viewModelScope, SharingStarted.WhileSubscribed(5000), null)
    val bookings = bookingRepository.observeByCustomer(customerId)
        .stateIn(viewModelScope, SharingStarted.WhileSubscribed(5000), emptyList())
    val tasaheel = tasaheelRepository.observeAll("")
        .stateIn(viewModelScope, SharingStarted.WhileSubscribed(5000), emptyList())
    val debts = debtRepository.observeByCustomer(customerId)
        .stateIn(viewModelScope, SharingStarted.WhileSubscribed(5000), emptyList())
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun CustomerDetailScreen(
    customerId: String,
    onBack: () -> Unit,
    viewModel: CustomerDetailViewModel = hiltViewModel(),
) {
    val customer by viewModel.customer.collectAsStateWithLifecycle()
    val bookings by viewModel.bookings.collectAsStateWithLifecycle()
    val allTasaheel by viewModel.tasaheel.collectAsStateWithLifecycle()
    val debts by viewModel.debts.collectAsStateWithLifecycle()
    val tasaheel = allTasaheel.filter { it.customerId == customerId }

    val totalRemaining = bookings.sumOf { it.remaining } +
        tasaheel.sumOf { it.remaining } + debts.sumOf { it.remaining }

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text(customer?.name ?: "سجل العميل") },
                navigationIcon = {
                    IconButton(onClick = onBack) {
                        Icon(Icons.AutoMirrored.Filled.ArrowBack, "رجوع")
                    }
                },
            )
        },
    ) { padding ->
        LazyColumn(
            Modifier.fillMaxSize().padding(padding),
            contentPadding = PaddingValues(16.dp),
            verticalArrangement = Arrangement.spacedBy(12.dp),
        ) {
            item {
                Card(Modifier.fillMaxWidth()) {
                    Column(Modifier.padding(14.dp), verticalArrangement = Arrangement.spacedBy(6.dp)) {
                        customer?.let { c ->
                            InfoRow("النوع", c.type.arabic)
                            if (c.phone.isNotBlank()) InfoRow("الهاتف", c.phone)
                            if (c.notes.isNotBlank()) InfoRow("ملاحظات", c.notes)
                        }
                        InfoRow("إجمالي المتبقي عليه", formatMoney(totalRemaining), DebtRed)
                    }
                }
            }

            item { SectionTitle("الحجوزات (${bookings.size})") }
            items(bookings, key = { "b${it.id}" }) { b -> BookingRow(b) }

            item { SectionTitle("تساهيل (${tasaheel.size})") }
            items(tasaheel, key = { "t${it.id}" }) { t -> TasaheelRow(t) }

            item { SectionTitle("المديونيات (${debts.size})") }
            items(debts, key = { "d${it.id}" }) { d -> DebtRow(d) }
        }
    }
}

@Composable
private fun SectionTitle(text: String) {
    Text(text, style = MaterialTheme.typography.titleMedium, modifier = Modifier.padding(top = 8.dp))
}

@Composable
private fun BookingRow(booking: BookingEntity) {
    Card(Modifier.fillMaxWidth()) {
        Column(Modifier.padding(12.dp), verticalArrangement = Arrangement.spacedBy(4.dp)) {
            Text("${booking.fromAirport} ← ${booking.toAirport}", fontWeight = FontWeight.Bold)
            InfoRow(formatDate(booking.departAt), booking.status.arabic)
            InfoRow("المتبقي", formatMoney(booking.remaining), DebtRed)
        }
    }
}

@Composable
private fun TasaheelRow(item: TasaheelEntity) {
    Card(Modifier.fillMaxWidth()) {
        Column(Modifier.padding(12.dp), verticalArrangement = Arrangement.spacedBy(4.dp)) {
            Text("${item.consulate} (عدد ${item.count})", fontWeight = FontWeight.Bold)
            InfoRow(formatDate(item.date), "المتبقي: ${formatMoney(item.remaining)}")
        }
    }
}

@Composable
private fun DebtRow(debt: DebtEntity) {
    Card(Modifier.fillMaxWidth()) {
        Column(Modifier.padding(12.dp), verticalArrangement = Arrangement.spacedBy(4.dp)) {
            Text("${debt.debtType.arabic} — ${debt.status.arabic}", fontWeight = FontWeight.Bold)
            InfoRow(formatDate(debt.date), "المتبقي: ${formatMoney(debt.remaining)}")
        }
    }
}
