"""Генерация QR-кода со ссылкой на сайт.
Использование:  python make_qr.py [url]
По умолчанию берёт адрес GitHub Pages этого репозитория.
"""
import sys
import qrcode
import qrcode.image.svg

URL = sys.argv[1] if len(sys.argv) > 1 else "https://kengat.github.io/arch-flythrough/"

qr = qrcode.QRCode(error_correction=qrcode.constants.ERROR_CORRECT_M, box_size=12, border=4)
qr.add_data(URL)
qr.make(fit=True)

# PNG — для печати
qr.make_image(fill_color="black", back_color="white").save("qr.png")

# SVG — векторный, не пикселит при увеличении
svg = qrcode.make(URL, image_factory=qrcode.image.svg.SvgImage)
svg.save("qr.svg")

print("QR создан для:", URL)
print("  -> qr.png")
print("  -> qr.svg")
