package com.elmahdi.travelsuite

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import androidx.compose.runtime.CompositionLocalProvider
import androidx.compose.ui.platform.LocalLayoutDirection
import androidx.compose.ui.unit.LayoutDirection
import com.elmahdi.travelsuite.data.auth.AuthRepository
import com.elmahdi.travelsuite.ui.navigation.AppNavigation
import com.elmahdi.travelsuite.ui.theme.TravelSuiteTheme
import dagger.hilt.android.AndroidEntryPoint
import javax.inject.Inject

@AndroidEntryPoint
class MainActivity : ComponentActivity() {

    @Inject lateinit var authRepository: AuthRepository

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        enableEdgeToEdge()
        val startLoggedIn = authRepository.isLoggedIn
        setContent {
            // التطبيق عربي بالكامل: فرض اتجاه RTL على كل الواجهات
            CompositionLocalProvider(LocalLayoutDirection provides LayoutDirection.Rtl) {
                TravelSuiteTheme {
                    AppNavigation(startLoggedIn = startLoggedIn)
                }
            }
        }
    }
}
