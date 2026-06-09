"""QR-код в векторный PDF (для вставки в Archicad).
Использование:  python make_pdf.py [url]
"""
import sys
import qrcode
from reportlab.pdfgen import canvas
from reportlab.lib.units import mm

URL = sys.argv[1] if len(sys.argv) > 1 else "https://kengat.github.io/arch-flythrough/"

# матрица QR
qr = qrcode.QRCode(error_correction=qrcode.constants.ERROR_CORRECT_M, border=4)
qr.add_data(URL)
qr.make(fit=True)
matrix = qr.get_matrix()
n = len(matrix)

# страница = ровно сам QR, сторона 80 мм (удобно тащить/масштабировать в Archicad)
side = 80 * mm
module = side / n

c = canvas.Canvas("qr.pdf", pagesize=(side, side))
c.setFillColorRGB(1, 1, 1)
c.rect(0, 0, side, side, stroke=0, fill=1)          # белый фон
c.setFillColorRGB(0, 0, 0)
for r, row in enumerate(matrix):
    for col, val in enumerate(row):
        if val:
            x = col * module
            y = side - (r + 1) * module            # PDF: ось Y снизу вверх
            c.rect(x, y, module, module, stroke=0, fill=1)
c.showPage()
c.save()
print("PDF создан (векторный, 80x80 мм):  qr.pdf")
print("Ссылка:", URL)
