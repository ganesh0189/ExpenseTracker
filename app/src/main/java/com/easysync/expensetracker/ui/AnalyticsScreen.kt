package com.easysync.expensetracker.ui

import androidx.compose.foundation.layout.*
import androidx.compose.material3.*
import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import androidx.lifecycle.viewmodel.compose.viewModel
import com.easysync.expensetracker.ui.viewmodel.AnalyticsViewModel
import com.patrykandpatryk.vico.compose.axis.horizontal.rememberBottomAxis
import com.patrykandpatryk.vico.compose.axis.vertical.rememberStartAxis
import com.patrykandpatryk.vico.compose.chart.Chart
import com.patrykandpatryk.vico.compose.chart.pie.PieChart
import com.patrykandpatryk.vico.core.entry.entryOf

@Composable
fun AnalyticsScreen(analyticsViewModel: AnalyticsViewModel = viewModel()) {
    val analyticsData by analyticsViewModel.analyticsData.collectAsState()

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("Spending Analytics") },
                colors = TopAppBarDefaults.topAppBarColors(
                    containerColor = MaterialTheme.colorScheme.surface,
                    titleContentColor = MaterialTheme.colorScheme.onSurface,
                )
            )
        }
    ) { padding ->
        Column(
            modifier = Modifier
                .padding(padding)
                .padding(16.dp)
                .fillMaxSize(),
            horizontalAlignment = Alignment.CenterHorizontally
        ) {
            Card(
                modifier = Modifier.fillMaxWidth(),
                elevation = CardDefaults.cardElevation(defaultElevation = 4.dp)
            ) {
                Column(modifier = Modifier.padding(16.dp)) {
                    Text("Total Spending", style = MaterialTheme.typography.titleLarge)
                    Text(String.format("$%.2f", analyticsData.totalSpending), style = MaterialTheme.typography.headlineLarge)
                }
            }

            Spacer(modifier = Modifier.height(16.dp))
            
            if (analyticsData.spendingByCategory.isNotEmpty()) {
                val chartEntryModel = analyticsData.spendingByCategory.map { (category, amount) ->
                    entryOf(amount.toFloat(), category)
                }
                Chart(
                    chart = PieChart(),
                    model = com.patrykandpatryk.vico.core.entry.ChartEntryModelProducer(chartEntryModel).getModel(),
                    startAxis = rememberStartAxis(),
                    bottomAxis = rememberBottomAxis(),
                )
            } else {
                Text("No spending data available for chart.")
            }
        }
    }
} 