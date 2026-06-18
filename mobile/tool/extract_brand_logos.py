from pathlib import Path

from PIL import Image

SRC = Path(
    r"C:\Users\nawar\.cursor\projects\c-xampp-htdocs-car-iq\assets"
    r"\c__Users_nawar_AppData_Roaming_Cursor_User_workspaceStorage_d609c8dbc5fb20f133ab5d49c356737e_images_famous-car-taglines-of-all-time-Cover-200620220100-AR-4122022-f2731c3a-748e-4e8a-9b32-2fca160d115b.png"
)
OUT = Path(r"c:\xampp\htdocs\car iq\mobile\assets\brands\png")
OUT.mkdir(parents=True, exist_ok=True)

# (left, top, right, bottom) tuned on the 1024x444 collage.
BOXES = {
    "land_rover": (302, 8, 378, 86),
    "bmw": (286, 90, 382, 182),
    "chevrolet": (510, 110, 564, 158),
    "nissan": (572, 184, 678, 262),
    "mercedes": (346, 184, 452, 268),
    "kia": (30, 268, 170, 326),
    "toyota": (442, 276, 532, 352),
    "hyundai": (624, 366, 726, 442),
}


def trim_white(image: Image.Image, threshold: int = 240) -> Image.Image:
    rgba = image.convert("RGBA")
    pixels = rgba.load()
    width, height = rgba.size

    for y in range(height):
        for x in range(width):
            r, g, b, _ = pixels[x, y]
            if r >= threshold and g >= threshold and b >= threshold:
                pixels[x, y] = (255, 255, 255, 0)

    bbox = rgba.getbbox()
    return rgba.crop(bbox) if bbox else rgba


def normalize(image: Image.Image, target: int = 256) -> Image.Image:
    canvas = Image.new("RGBA", (target, target), (0, 0, 0, 0))
    max_side = target - 12
    copy = image.copy()
    copy.thumbnail((max_side, max_side), Image.Resampling.LANCZOS)
    offset = ((target - copy.width) // 2, (target - copy.height) // 2)
    canvas.paste(copy, offset, copy)
    return canvas


def main() -> None:
    img = Image.open(SRC)
    for name, box in BOXES.items():
        crop = trim_white(img.crop(box))
        normalize(crop).save(OUT / f"{name}.png", "PNG")
        print(name, crop.size)


if __name__ == "__main__":
    main()
