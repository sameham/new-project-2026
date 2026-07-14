package com.elmahdi.travelsuite.ui.screens.reports

import android.content.Context
import android.content.Intent
import android.graphics.Color
import android.graphics.Paint
import android.graphics.Typeface
import android.graphics.pdf.PdfDocument
import androidx.core.content.FileProvider
import dagger.hilt.android.qualifiers.ApplicationContext
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import java.io.File
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale
import javax.inject.Inject
import javax.inject.Singleton

/**
 * تصدير أي تقرير إلى PDF ومشاركته (طباعة/واتساب/حفظ).
 * يعتمد على android.graphics.pdf المدمج — بلا مكتبات خارجية.
 *
 * كل سطر تقرير هو زوج (البيان، القيمة): البيان يُرسم يمينًا (RTL)
 * والقيمة يسارًا في نفس السطر.
 */
@Singleton
class ReportPdfExporter @Inject constructor(
    @ApplicationContext private val context: Context,
) {
    private companion object {
        const val PAGE_WIDTH = 595   // A4 بوحدة النقاط
        const val PAGE_HEIGHT = 842
        const val MARGIN = 40f
        const val LINE_HEIGHT = 26f
    }

    suspend fun exportAndShare(title: String, lines: List<Pair<String, String>>) {
        val file = withContext(Dispatchers.IO) { render(title, lines) }
        share(file)
    }

    private fun render(title: String, lines: List<Pair<String, String>>): File {
        val document = PdfDocument()
        val titlePaint = Paint().apply {
            textSize = 20f
            typeface = Typeface.DEFAULT_BOLD
            textAlign = Paint.Align.CENTER
            color = Color.BLACK
        }
        val labelPaint = Paint().apply {
            textSize = 13f
            textAlign = Paint.Align.RIGHT // عربي: البيان على اليمين
            color = Color.BLACK
        }
        val valuePaint = Paint().apply {
            textSize = 13f
            typeface = Typeface.DEFAULT_BOLD
            textAlign = Paint.Align.LEFT
            color = Color.rgb(11, 92, 140)
        }
        val linePaint = Paint().apply { color = Color.LTGRAY; strokeWidth = 0.5f }

        val linesPerPage = ((PAGE_HEIGHT - 140) / LINE_HEIGHT).toInt()
        val pages = if (lines.isEmpty()) listOf(emptyList()) else lines.chunked(linesPerPage)

        pages.forEachIndexed { pageIndex, pageLines ->
            val page = document.startPage(
                PdfDocument.PageInfo.Builder(PAGE_WIDTH, PAGE_HEIGHT, pageIndex + 1).create()
            )
            val canvas = page.canvas
            canvas.drawText(title, PAGE_WIDTH / 2f, 60f, titlePaint)
            canvas.drawText(
                SimpleDateFormat("yyyy/MM/dd HH:mm", Locale.US).format(Date()),
                PAGE_WIDTH / 2f, 82f,
                Paint().apply { textSize = 11f; textAlign = Paint.Align.CENTER; color = Color.GRAY },
            )

            var y = 120f
            pageLines.forEach { (label, value) ->
                canvas.drawText(label, PAGE_WIDTH - MARGIN, y, labelPaint)
                canvas.drawText(value, MARGIN, y, valuePaint)
                canvas.drawLine(MARGIN, y + 8f, PAGE_WIDTH - MARGIN, y + 8f, linePaint)
                y += LINE_HEIGHT
            }
            document.finishPage(page)
        }

        val dir = File(context.cacheDir, "reports").apply { mkdirs() }
        val file = File(dir, "report_${System.currentTimeMillis()}.pdf")
        file.outputStream().use { document.writeTo(it) }
        document.close()
        return file
    }

    private fun share(file: File) {
        val uri = FileProvider.getUriForFile(context, "${context.packageName}.fileprovider", file)
        val intent = Intent(Intent.ACTION_SEND).apply {
            type = "application/pdf"
            putExtra(Intent.EXTRA_STREAM, uri)
            addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION or Intent.FLAG_ACTIVITY_NEW_TASK)
        }
        context.startActivity(Intent.createChooser(intent, "مشاركة التقرير").apply {
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        })
    }
}
