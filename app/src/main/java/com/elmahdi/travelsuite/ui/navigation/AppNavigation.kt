package com.elmahdi.travelsuite.ui.navigation

import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.AccountBalanceWallet
import androidx.compose.material.icons.filled.Dashboard
import androidx.compose.material.icons.filled.Flight
import androidx.compose.material.icons.filled.MoreHoriz
import androidx.compose.material.icons.filled.People
import androidx.compose.material3.Icon
import androidx.compose.material3.NavigationBar
import androidx.compose.material3.NavigationBarItem
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.foundation.layout.padding
import androidx.navigation.NavHostController
import androidx.navigation.compose.NavHost
import androidx.navigation.compose.composable
import androidx.navigation.compose.currentBackStackEntryAsState
import androidx.navigation.compose.rememberNavController
import com.elmahdi.travelsuite.ui.screens.admin.AdminScreen
import com.elmahdi.travelsuite.ui.screens.bookings.BookingEditScreen
import com.elmahdi.travelsuite.ui.screens.bookings.BookingsScreen
import com.elmahdi.travelsuite.ui.screens.customers.CustomerDetailScreen
import com.elmahdi.travelsuite.ui.screens.customers.CustomersScreen
import com.elmahdi.travelsuite.ui.screens.dashboard.DashboardScreen
import com.elmahdi.travelsuite.ui.screens.debts.DebtsScreen
import com.elmahdi.travelsuite.ui.screens.login.LoginScreen
import com.elmahdi.travelsuite.ui.screens.more.MoreScreen
import com.elmahdi.travelsuite.ui.screens.payments.PaymentsScreen
import com.elmahdi.travelsuite.ui.screens.reports.ReportsScreen
import com.elmahdi.travelsuite.ui.screens.tasaheel.TasaheelScreen

object Routes {
    const val LOGIN = "login"
    const val DASHBOARD = "dashboard"
    const val BOOKINGS = "bookings"
    const val BOOKING_EDIT = "booking_edit?id={id}"
    const val TASAHEEL = "tasaheel"
    const val PAYMENTS = "payments"
    const val DEBTS = "debts"
    const val CUSTOMERS = "customers"
    const val CUSTOMER_DETAIL = "customer_detail/{id}"
    const val REPORTS = "reports"
    const val ADMIN = "admin"
    const val MORE = "more"

    fun bookingEdit(id: String?) = "booking_edit?id=${id.orEmpty()}"
    fun customerDetail(id: String) = "customer_detail/$id"
}

private data class BottomItem(val route: String, val label: String, val icon: ImageVector)

private val bottomItems = listOf(
    BottomItem(Routes.DASHBOARD, "الرئيسية", Icons.Default.Dashboard),
    BottomItem(Routes.BOOKINGS, "الحجوزات", Icons.Default.Flight),
    BottomItem(Routes.CUSTOMERS, "العملاء", Icons.Default.People),
    BottomItem(Routes.PAYMENTS, "المدفوعات", Icons.Default.AccountBalanceWallet),
    BottomItem(Routes.MORE, "المزيد", Icons.Default.MoreHoriz),
)

@Composable
fun AppNavigation(startLoggedIn: Boolean) {
    val navController = rememberNavController()
    val backStack by navController.currentBackStackEntryAsState()
    val currentRoute = backStack?.destination?.route

    val showBottomBar = currentRoute in bottomItems.map { it.route } ||
        currentRoute in listOf(Routes.TASAHEEL, Routes.DEBTS, Routes.REPORTS, Routes.ADMIN)

    Scaffold(
        bottomBar = {
            if (showBottomBar) BottomBar(navController, currentRoute)
        },
    ) { padding ->
        NavHost(
            navController = navController,
            startDestination = if (startLoggedIn) Routes.DASHBOARD else Routes.LOGIN,
            modifier = Modifier.padding(padding),
        ) {
            composable(Routes.LOGIN) {
                LoginScreen(onLoggedIn = {
                    navController.navigate(Routes.DASHBOARD) {
                        popUpTo(Routes.LOGIN) { inclusive = true }
                    }
                })
            }
            composable(Routes.DASHBOARD) {
                DashboardScreen(
                    onOpenBookings = { navController.navigate(Routes.BOOKINGS) },
                    onOpenDebts = { navController.navigate(Routes.DEBTS) },
                )
            }
            composable(Routes.BOOKINGS) {
                BookingsScreen(onEdit = { id -> navController.navigate(Routes.bookingEdit(id)) })
            }
            composable(Routes.BOOKING_EDIT) { entry ->
                BookingEditScreen(
                    bookingId = entry.arguments?.getString("id").orEmpty().ifBlank { null },
                    onDone = { navController.popBackStack() },
                )
            }
            composable(Routes.TASAHEEL) { TasaheelScreen() }
            composable(Routes.PAYMENTS) { PaymentsScreen() }
            composable(Routes.DEBTS) { DebtsScreen() }
            composable(Routes.CUSTOMERS) {
                CustomersScreen(onOpenCustomer = { id -> navController.navigate(Routes.customerDetail(id)) })
            }
            composable(Routes.CUSTOMER_DETAIL) { entry ->
                CustomerDetailScreen(
                    customerId = entry.arguments?.getString("id").orEmpty(),
                    onBack = { navController.popBackStack() },
                )
            }
            composable(Routes.REPORTS) { ReportsScreen() }
            composable(Routes.ADMIN) {
                AdminScreen(onLoggedOut = {
                    navController.navigate(Routes.LOGIN) { popUpTo(0) { inclusive = true } }
                })
            }
            composable(Routes.MORE) {
                MoreScreen(
                    onOpenTasaheel = { navController.navigate(Routes.TASAHEEL) },
                    onOpenDebts = { navController.navigate(Routes.DEBTS) },
                    onOpenReports = { navController.navigate(Routes.REPORTS) },
                    onOpenAdmin = { navController.navigate(Routes.ADMIN) },
                )
            }
        }
    }
}

@Composable
private fun BottomBar(navController: NavHostController, currentRoute: String?) {
    NavigationBar {
        bottomItems.forEach { item ->
            val selected = currentRoute == item.route ||
                (item.route == Routes.MORE && currentRoute in
                    listOf(Routes.TASAHEEL, Routes.DEBTS, Routes.REPORTS, Routes.ADMIN))
            NavigationBarItem(
                selected = selected,
                onClick = {
                    navController.navigate(item.route) {
                        popUpTo(Routes.DASHBOARD) { saveState = true }
                        launchSingleTop = true
                        restoreState = true
                    }
                },
                icon = { Icon(item.icon, contentDescription = item.label) },
                label = { Text(item.label) },
            )
        }
    }
}
