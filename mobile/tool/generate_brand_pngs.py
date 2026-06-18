from pathlib import Path

try:
    import cairosvg
except ImportError:
    raise SystemExit('Install cairosvg: pip install cairosvg')

ROOT = Path(__file__).resolve().parents[1]
SVG_DIR = ROOT / 'assets' / 'brands'
PNG_DIR = ROOT / 'assets' / 'brands' / 'png'
PNG_DIR.mkdir(parents=True, exist_ok=True)

FILES = [
    'toyota.svg',
    'hyundai.svg',
    'bmw.svg',
    'mercedes.svg',
    'nissan.svg',
    'kia.svg',
    'land_rover.svg',
    'chevrolet.svg',
]

for name in FILES:
    src = SVG_DIR / name
    if not src.exists():
        continue
    dst = PNG_DIR / name.replace('.svg', '.png')
    cairosvg.svg2png(
        url=str(src),
        write_to=str(dst),
        output_width=256,
        output_height=256,
    )
    print('generated', dst.name)
