import sys
from urllib.parse import urlparse
import qrcode
import qrcode.image.svg
url = sys.argv[1] if len(sys.argv) == 2 else ''
if urlparse(url).scheme != 'https' or not urlparse(url).netloc:
    raise SystemExit('Pass the approved live HTTPS menu URL as the only argument.')
qrcode.make(url, error_correction=qrcode.constants.ERROR_CORRECT_M, box_size=12, border=4).save('Baladi_Chicken_QR.png')
qrcode.make(url, image_factory=qrcode.image.svg.SvgPathImage, error_correction=qrcode.constants.ERROR_CORRECT_M, box_size=12, border=4).save('Baladi_Chicken_QR.svg')
print('Created PNG and SVG QR codes. Scan-test against the live menu before printing.')
