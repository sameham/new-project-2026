package com.elmahdi.travelsuite.ui.screens.bookings

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.Button
import androidx.compose.material3.Card
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.lifecycle.ViewModel
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import androidx.lifecycle.viewModelScope
import com.elmahdi.travelsuite.data.local.entity.BookingEntity
import com.elmahdi.travelsuite.data.local.entity.CustomerEntity
import com.elmahdi.travelsuite.data.repository.BookingRepository
import com.elmahdi.travelsuite.data.repository.CustomerRepository
import com.elmahdi.travelsuite.domain.model.BookingStatus
import com.elmahdi.travelsuite.domain.model.TripType
import com.elmahdi.travelsuite.ui.common.AppDropdown
import com.elmahdi.travelsuite.ui.common.DateField
import com.elmahdi.travelsuite.ui.common.InfoRow
import com.elmahdi.travelsuite.ui.common.TimeField
import com.elmahdi.travelsuite.ui.common.formatMoney
import com.elmahdi.travelsuite.ui.screens.customers.CustomerEditDialog
import com.elmahdi.travelsuite.ui.theme.DebtRed
import com.elmahdi.travelsuite.ui.theme.ProfitGreen
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.SharingStarted
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.stateIn
import kotlinx.coroutines.launch
import javax.inject.Inject

data class BookingEditState(
    val booking: BookingEntity? = null, // null = لم يُحمَّل بعد أو حجز جديد
    val isNew: Boolean = true,
    val saved: Boolean = false,
    val error: String? = null,
)

@HiltViewModel
class BookingEditViewModel @Inject constructor(
    private val bookingRepository: BookingRepository,
    private val customerRepository: CustomerRepository,
) : ViewModel() {
    private val _state = MutableStateFlow(BookingEditState())
    val state = _state.asStateFlow()

    val customers = customerRepository.observeAll("")
        .stateIn(viewModelScope, SharingStarted.WhileSubscribed(5000), emptyList())

    fun load(bookingId: String?) {
        if (bookingId == null) {
            _state.value = BookingEditState(isNew = true)
            return
        }
        viewModelScope.launch {
            val existing = bookingRepository.byId(bookingId)
            _state.value = BookingEditState(booking = existing, isNew = existing == null)
        }
    }

    fun addCustomer(customer: CustomerEntity, onAdded: (CustomerEntity) -> Unit) {
        viewModelScope.launch {
            customerRepository.save(customer)
            onAdded(customer)
        }
    }

    fun save(booking: BookingEntity) {
        if (booking.customerId.isBlank()) {
            _state.value = _state.value.copy(error = "اختر العميل أولًا")
            return
        }
        if (booking.fromAirport.isBlank() || booking.toAirport.isBlank()) {
            _state.value = _state.value.copy(error = "أدخل مطار الذهاب والوصول")
            return
        }
        if (booking.tripType == TripType.ROUND_TRIP && booking.returnAt == null) {
            _state.value = _state.value.copy(error = "أدخل بيانات رحلة العودة")
            return
        }
        viewModelScope.launch {
            bookingRepository.save(booking, isNew = _state.value.isNew)
            _state.value = _state.value.copy(saved = true)
        }
    }
}

@Composable
fun BookingEditScreen(
    bookingId: String?,
    onDone: () -> Unit,
    viewModel: BookingEditViewModel = hiltViewModel(),
) {
    val state by viewModel.state.collectAsStateWithLifecycle()
    val customers by viewModel.customers.collectAsStateWithLifecycle()

    LaunchedEffect(bookingId) { viewModel.load(bookingId) }
    LaunchedEffect(state.saved) { if (state.saved) onDone() }

    // نسخة عمل محلية للنموذج
    var form by remember(state.booking?.id) {
        mutableStateOf(state.booking ?: BookingEntity(customerId = "", customerName = "",
            fromAirport = "", toAirport = "", departAt = System.currentTimeMillis(), departTime = "12:00"))
    }
    var showNewCustomer by remember { mutableStateOf(false) }

    Column(
        Modifier.fillMaxSize().verticalScroll(rememberScrollState()).padding(16.dp),
        verticalArrangement = Arrangement.spacedBy(14.dp),
    ) {
        Text(
            if (state.isNew) "حجز جديد" else "تعديل حجز",
            style = MaterialTheme.typography.titleLarge,
        )

        // العميل: من المسجلين أو إضافة جديد أثناء الحجز
        AppDropdown(
            label = "اسم العميل",
            options = customers,
            selected = customers.firstOrNull { it.id == form.customerId },
            optionLabel = { it.name },
            onSelect = { form = form.copy(customerId = it.id, customerName = it.name) },
        )
        OutlinedButton(onClick = { showNewCustomer = true }, modifier = Modifier.fillMaxWidth()) {
            Text("+ إضافة عميل جديد")
        }

        Text("بيانات الذهاب", style = MaterialTheme.typography.titleMedium)
        Row(horizontalArrangement = Arrangement.spacedBy(10.dp)) {
            OutlinedTextField(
                value = form.fromAirport,
                onValueChange = { form = form.copy(fromAirport = it) },
                label = { Text("من مطار") },
                modifier = Modifier.weight(1f),
                singleLine = true,
            )
            OutlinedTextField(
                value = form.toAirport,
                onValueChange = { form = form.copy(toAirport = it) },
                label = { Text("إلى مطار") },
                modifier = Modifier.weight(1f),
                singleLine = true,
            )
        }
        Row(horizontalArrangement = Arrangement.spacedBy(10.dp)) {
            DateField("تاريخ الذهاب", form.departAt, { form = form.copy(departAt = it) }, Modifier.weight(1f))
            TimeField("وقت الذهاب", form.departTime, { form = form.copy(departTime = it) }, Modifier.weight(1f))
        }

        AppDropdown(
            label = "نوع الرحلة",
            options = TripType.entries,
            selected = form.tripType,
            optionLabel = { it.arabic },
            onSelect = { form = form.copy(tripType = it) },
        )

        if (form.tripType == TripType.ROUND_TRIP) {
            Text("بيانات العودة", style = MaterialTheme.typography.titleMedium)
            Row(horizontalArrangement = Arrangement.spacedBy(10.dp)) {
                OutlinedTextField(
                    value = form.returnFromAirport,
                    onValueChange = { form = form.copy(returnFromAirport = it) },
                    label = { Text("مطار العودة (من)") },
                    modifier = Modifier.weight(1f),
                    singleLine = true,
                )
                OutlinedTextField(
                    value = form.returnToAirport,
                    onValueChange = { form = form.copy(returnToAirport = it) },
                    label = { Text("مطار العودة (إلى)") },
                    modifier = Modifier.weight(1f),
                    singleLine = true,
                )
            }
            Row(horizontalArrangement = Arrangement.spacedBy(10.dp)) {
                DateField("تاريخ العودة", form.returnAt, { form = form.copy(returnAt = it) }, Modifier.weight(1f))
                TimeField("وقت العودة", form.returnTime, { form = form.copy(returnTime = it) }, Modifier.weight(1f))
            }
        }

        Text("البيانات المالية", style = MaterialTheme.typography.titleMedium)
        Row(horizontalArrangement = Arrangement.spacedBy(10.dp)) {
            MoneyField("سعر الشراء", form.buyPrice, { form = form.copy(buyPrice = it) }, Modifier.weight(1f))
            MoneyField("سعر البيع", form.sellPrice, { form = form.copy(sellPrice = it) }, Modifier.weight(1f))
        }
        MoneyField("المدفوع", form.paidAmount, { form = form.copy(paidAmount = it) }, Modifier.fillMaxWidth())

        // الربح والمتبقي يُحسبان تلقائيًا
        Card(Modifier.fillMaxWidth()) {
            Column(Modifier.padding(14.dp), verticalArrangement = Arrangement.spacedBy(6.dp)) {
                InfoRow("الربح (تلقائي)", formatMoney(form.profit), ProfitGreen)
                InfoRow("المتبقي (تلقائي)", formatMoney(form.remaining), DebtRed)
            }
        }

        AppDropdown(
            label = "حالة الحجز",
            options = BookingStatus.entries,
            selected = form.status,
            optionLabel = { it.arabic },
            onSelect = { form = form.copy(status = it) },
        )
        OutlinedTextField(
            value = form.notes,
            onValueChange = { form = form.copy(notes = it) },
            label = { Text("ملاحظات") },
            modifier = Modifier.fillMaxWidth(),
        )

        state.error?.let { Text(it, color = MaterialTheme.colorScheme.error) }

        Button(
            onClick = { viewModel.save(form) },
            modifier = Modifier.fillMaxWidth().height(54.dp),
        ) { Text("حفظ الحجز") }
    }

    if (showNewCustomer) {
        CustomerEditDialog(
            customer = null,
            onSave = { customer ->
                viewModel.addCustomer(customer) {
                    form = form.copy(customerId = it.id, customerName = it.name)
                }
                showNewCustomer = false
            },
            onDismiss = { showNewCustomer = false },
        )
    }
}

/** حقل إدخال مبلغ مالي رقمي */
@Composable
fun MoneyField(label: String, value: Double, onChange: (Double) -> Unit, modifier: Modifier = Modifier) {
    var text by remember { mutableStateOf(if (value == 0.0) "" else value.toString().removeSuffix(".0")) }
    OutlinedTextField(
        value = text,
        onValueChange = {
            text = it
            onChange(it.toDoubleOrNull() ?: 0.0)
        },
        label = { Text(label) },
        keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Decimal),
        singleLine = true,
        modifier = modifier,
    )
}
