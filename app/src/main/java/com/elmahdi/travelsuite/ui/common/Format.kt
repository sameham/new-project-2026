package com.elmahdi.travelsuite.ui.common

import java.text.NumberFormat
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

private val moneyFormat = NumberFormat.getNumberInstance(Locale.US).apply {
    maximumFractionDigits = 2
    minimumFractionDigits = 0
}

/** عرض المبالغ المالية بفواصل الآلاف وعملة الجنيه */
fun formatMoney(value: Double, currency: String = "ج.م"): String =
    "${moneyFormat.format(value)} $currency"

private val dateFormat = SimpleDateFormat("yyyy/MM/dd", Locale.US)

fun formatDate(epochMillis: Long?): String =
    if (epochMillis == null || epochMillis == 0L) "—" else dateFormat.format(Date(epochMillis))
