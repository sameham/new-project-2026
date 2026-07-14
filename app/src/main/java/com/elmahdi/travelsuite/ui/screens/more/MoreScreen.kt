package com.elmahdi.travelsuite.ui.screens.more

import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.AdminPanelSettings
import androidx.compose.material.icons.filled.Assessment
import androidx.compose.material.icons.filled.Description
import androidx.compose.material.icons.filled.MoneyOff
import androidx.compose.material3.Card
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.lifecycle.ViewModel
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import androidx.lifecycle.viewModelScope
import com.elmahdi.travelsuite.data.auth.SessionManager
import com.elmahdi.travelsuite.domain.model.Permission
import com.elmahdi.travelsuite.domain.model.UserRole
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.SharingStarted
import kotlinx.coroutines.flow.stateIn
import javax.inject.Inject

@HiltViewModel
class MoreViewModel @Inject constructor(session: SessionManager) : ViewModel() {
    val currentUser = session.currentUser
    val permissions = session.permissions
        .stateIn(viewModelScope, SharingStarted.WhileSubscribed(5000), emptySet())
}

@Composable
fun MoreScreen(
    onOpenTasaheel: () -> Unit,
    onOpenDebts: () -> Unit,
    onOpenReports: () -> Unit,
    onOpenAdmin: () -> Unit,
    viewModel: MoreViewModel = hiltViewModel(),
) {
    val user by viewModel.currentUser.collectAsStateWithLifecycle()

    Column(
        Modifier.fillMaxSize().padding(16.dp),
        verticalArrangement = Arrangement.spacedBy(12.dp),
    ) {
        Text("المزيد", style = MaterialTheme.typography.titleLarge)
        user?.let {
            Text(
                "${it.displayName.ifBlank { it.email }} — ${it.role.arabic}",
                color = MaterialTheme.colorScheme.onSurfaceVariant,
            )
        }
        MenuCard("تساهيل", Icons.Default.Description, onOpenTasaheel)
        MenuCard("المديونية", Icons.Default.MoneyOff, onOpenDebts)
        MenuCard("التقارير", Icons.Default.Assessment, onOpenReports)
        if (user?.role == UserRole.ADMIN || Permission.MANAGE_USERS in (user?.permissions() ?: emptySet())) {
            MenuCard("لوحة المدير", Icons.Default.AdminPanelSettings, onOpenAdmin)
        }
    }
}

@Composable
private fun MenuCard(title: String, icon: ImageVector, onClick: () -> Unit) {
    Card(Modifier.fillMaxWidth().clickable(onClick = onClick)) {
        Row(
            Modifier.fillMaxWidth().padding(18.dp),
            horizontalArrangement = Arrangement.spacedBy(14.dp),
            verticalAlignment = Alignment.CenterVertically,
        ) {
            Icon(icon, contentDescription = null, tint = MaterialTheme.colorScheme.primary)
            Text(title, style = MaterialTheme.typography.titleMedium)
        }
    }
}
