package com.elmahdi.travelsuite.ui.theme

import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Shapes
import androidx.compose.material3.Typography
import androidx.compose.material3.lightColorScheme
import androidx.compose.runtime.Composable
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp

// ألوان واضحة ومريحة: أزرق سماوي للأساس، أخضر للمكسب، أحمر للمتبقي/الخطر
val Primary = Color(0xFF0B5C8C)
val PrimaryContainer = Color(0xFFD3E9F7)
val Secondary = Color(0xFF0E7C61)
val SecondaryContainer = Color(0xFFD2F2E8)
val Background = Color(0xFFF6F8FA)
val SurfaceColor = Color(0xFFFFFFFF)
val ErrorColor = Color(0xFFB3261E)
val ProfitGreen = Color(0xFF1B7F4D)
val DebtRed = Color(0xFFC0392B)
val WarningOrange = Color(0xFFB9770E)

private val LightColors = lightColorScheme(
    primary = Primary,
    primaryContainer = PrimaryContainer,
    onPrimaryContainer = Color(0xFF06334E),
    secondary = Secondary,
    secondaryContainer = SecondaryContainer,
    background = Background,
    surface = SurfaceColor,
    error = ErrorColor,
)

// خط أكبر قليلًا من الافتراضي لسهولة القراءة على الموبايل
private val AppTypography = Typography(
    titleLarge = Typography().titleLarge.copy(fontWeight = FontWeight.Bold, fontSize = 22.sp),
    titleMedium = Typography().titleMedium.copy(fontWeight = FontWeight.Bold, fontSize = 18.sp),
    bodyLarge = Typography().bodyLarge.copy(fontSize = 17.sp),
    bodyMedium = Typography().bodyMedium.copy(fontSize = 15.sp),
    labelLarge = Typography().labelLarge.copy(fontSize = 16.sp, fontWeight = FontWeight.SemiBold),
)

private val AppShapes = Shapes(
    small = RoundedCornerShape(10.dp),
    medium = RoundedCornerShape(14.dp),
    large = RoundedCornerShape(20.dp),
)

@Composable
fun TravelSuiteTheme(content: @Composable () -> Unit) {
    MaterialTheme(
        colorScheme = LightColors,
        typography = AppTypography,
        shapes = AppShapes,
        content = content,
    )
}
