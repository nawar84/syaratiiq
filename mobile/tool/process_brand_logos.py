from __future__ import annotations

from collections import deque
from pathlib import Path

from PIL import Image

ASSETS = Path(
    r"C:\Users\nawar\.cursor\projects\c-xampp-htdocs-car-iq\assets"
)
OUT = Path(r"c:\xampp\htdocs\car iq\mobile\assets\brands\png")
OUT.mkdir(parents=True, exist_ok=True)

# source suffix -> (output name, crop_top_ratio, bg_mode)
# bg_mode: "light" | "dark" | "both"
BRANDS: dict[str, tuple[str, float | None, str]] = {
    "images_1-12e7e637-f8bd-424b-99ed-a5f2cf5d9f0b.png": ("toyota", None, "dark"),
    "images_2-527b53aa-6778-4be3-8816-667dd15e13b3.png": ("land_rover", None, "light"),
    "images_4-717d12a1-9d2a-44b4-96fd-768933524c7b.png": ("bmw", None, "dark"),
    "images_5-1bf7345a-2884-4594-aded-c70eae585cca.png": ("kia", None, "kia"),
    "images_6-bf6cdb30-7b26-40e5-92b8-5e42c5c5c2df.png": ("hyundai", 0.62, "light"),
    "images_7-5f924c78-dc00-49dd-b94a-039984e02145.png": ("cadillac", None, "light"),
    "images_8-b5bf9fa0-1176-4666-90f9-d4f08b73f09d.png": ("changan", 0.68, "dark"),
    "images_9-8f7c9a79-faf8-4fe3-8ffe-5c0268642094.png": ("mercedes", 0.68, "light"),
}


def find_source(name: str) -> Path:
    matches = list(ASSETS.glob(f"c__Users_nawar*{name}"))
    if not matches:
        raise FileNotFoundError(name)
    return matches[0]


def is_light_background(r: int, g: int, b: int, a: int, threshold: int = 228) -> bool:
    if a < 20:
        return True
    return r >= threshold and g >= threshold and b >= threshold


def is_dark_background(r: int, g: int, b: int, a: int, threshold: int = 28) -> bool:
    if a < 20:
        return True
    return r <= threshold and g <= threshold and b <= threshold


def flood_remove_background(
    rgba: Image.Image,
    *,
    light: bool = False,
    dark: bool = False,
) -> None:
    width, height = rgba.size
    pixels = rgba.load()
    visited = [[False] * width for _ in range(height)]
    queue: deque[tuple[int, int]] = deque()

    for x in range(width):
        queue.append((x, 0))
        queue.append((x, height - 1))
    for y in range(height):
        queue.append((0, y))
        queue.append((width - 1, y))

    while queue:
        x, y = queue.popleft()
        if x < 0 or y < 0 or x >= width or y >= height or visited[y][x]:
            continue
        visited[y][x] = True
        r, g, b, a = pixels[x, y]
        match = (light and is_light_background(r, g, b, a)) or (
            dark and is_dark_background(r, g, b, a)
        )
        if not match:
            continue
        pixels[x, y] = (255, 255, 255, 0)
        queue.extend([(x - 1, y), (x + 1, y), (x, y - 1), (x, y + 1)])


def trim_transparent(image: Image.Image, pad: int = 4) -> Image.Image:
    bbox = image.getbbox()
    if not bbox:
        return image
    left, top, right, bottom = bbox
    left = max(left - pad, 0)
    top = max(top - pad, 0)
    right = min(right + pad, image.width)
    bottom = min(bottom + pad, image.height)
    return image.crop((left, top, right, bottom))


def normalize(image: Image.Image, target: int = 256) -> Image.Image:
    canvas = Image.new("RGBA", (target, target), (0, 0, 0, 0))
    max_side = target - 8
    copy = image.copy()
    copy.thumbnail((max_side, max_side), Image.Resampling.LANCZOS)
    offset = ((target - copy.width) // 2, (target - copy.height) // 2)
    canvas.paste(copy, offset, copy)
    return canvas


def remove_all_light_pixels(rgba: Image.Image, threshold: int = 185) -> None:
    pixels = rgba.load()
    width, height = rgba.size
    for y in range(height):
        for x in range(width):
            r, g, b, a = pixels[x, y]
            if r >= threshold and g >= threshold and b >= threshold:
                pixels[x, y] = (255, 255, 255, 0)


def process_source(path: Path, crop_top_ratio: float | None, bg_mode: str) -> Image.Image:
    img = Image.open(path).convert("RGBA")
    if crop_top_ratio is not None:
        cut = max(int(img.height * crop_top_ratio), 1)
        img = img.crop((0, 0, img.width, cut))

    rgba = img.copy()
    if bg_mode == "kia":
        remove_all_light_pixels(rgba, threshold=185)
    else:
        if bg_mode in {"light", "both"}:
            flood_remove_background(rgba, light=True)
        if bg_mode in {"dark", "both"}:
            flood_remove_background(rgba, dark=True)
    return trim_transparent(rgba)


def main() -> None:
    for suffix, (name, crop_ratio, bg_mode) in BRANDS.items():
        src = find_source(suffix)
        logo = process_source(src, crop_ratio, bg_mode)
        normalize(logo).save(OUT / f"{name}.png", "PNG")
        print(f"{name}: {logo.size} <- {src.name}")


if __name__ == "__main__":
    main()
