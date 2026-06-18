from __future__ import annotations

from collections import deque
from pathlib import Path

from PIL import Image

SRC = next(
    Path(
        r"C:\Users\nawar\.cursor\projects\c-xampp-htdocs-car-iq\assets"
    ).glob("c__Users_nawar*images_5-*.png")
)
OUT = Path(r"c:\xampp\htdocs\car iq\mobile\assets\brands\png\kia.png")


def is_light(r: int, g: int, b: int, threshold: int = 215) -> bool:
    return r >= threshold and g >= threshold and b >= threshold


def remove_light_edges(rgba: Image.Image) -> None:
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
        if a < 20 or is_light(r, g, b):
            pixels[x, y] = (255, 255, 255, 0)
            queue.extend([(x - 1, y), (x + 1, y), (x, y - 1), (x, y + 1)])


def recolor_logo_white(rgba: Image.Image) -> None:
    pixels = rgba.load()
    width, height = rgba.size
    for y in range(height):
        for x in range(width):
            r, g, b, a = pixels[x, y]
            if a < 10:
                continue
            luminance = 0.299 * r + 0.587 * g + 0.114 * b
            if luminance >= 150:
                pixels[x, y] = (255, 255, 255, 0)
                continue
            strength = max(0.0, min(1.0, (150 - luminance) / 150))
            alpha = int(255 * strength)
            pixels[x, y] = (236, 240, 255, alpha)


def trim_transparent(image: Image.Image, pad: int = 6) -> Image.Image:
    bbox = image.getbbox()
    if not bbox:
        return image
    left, top, right, bottom = bbox
    return image.crop(
        (
            max(left - pad, 0),
            max(top - pad, 0),
            min(right + pad, image.width),
            min(bottom + pad, image.height),
        )
    )


def normalize(image: Image.Image, target: int = 256) -> Image.Image:
    canvas = Image.new("RGBA", (target, target), (0, 0, 0, 0))
    max_side = target - 10
    copy = image.copy()
    copy.thumbnail((max_side, max_side), Image.Resampling.LANCZOS)
    offset = ((target - copy.width) // 2, (target - copy.height) // 2)
    canvas.paste(copy, offset, copy)
    return canvas


def main() -> None:
    rgba = Image.open(SRC).convert("RGBA")
    remove_light_edges(rgba)
    recolor_logo_white(rgba)
    logo = trim_transparent(rgba)
    normalize(logo).save(OUT, "PNG")
    print(f"kia: {logo.size} <- {SRC.name}")


if __name__ == "__main__":
    main()
