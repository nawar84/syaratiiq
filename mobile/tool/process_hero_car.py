from __future__ import annotations

from collections import deque
from pathlib import Path

from PIL import Image

SOURCE = Path(
    r"C:\Users\nawar\.cursor\projects\c-xampp-htdocs-car-iq\assets"
    r"\c__Users_nawar_AppData_Roaming_Cursor_User_workspaceStorage_d609c8dbc5fb20f133ab5d49c356737e_images_1-feccc030-bebe-44a8-bb7d-70c9323e92c6.png"
)
OUT = Path(r"c:\xampp\htdocs\car iq\mobile\assets\images\hero_toyota_land_cruiser.png")


def is_light_border(r: int, g: int, b: int) -> bool:
    neutral = max(abs(r - g), abs(g - b), abs(r - b))
    brightness = (r + g + b) / 3
    return neutral <= 10 and brightness >= 198


def is_dark_border(r: int, g: int, b: int) -> bool:
    neutral = max(abs(r - g), abs(g - b), abs(r - b))
    brightness = (r + g + b) / 3
    return neutral <= 18 and brightness <= 55


def flood_remove_tone(
    rgba: Image.Image,
    *,
    light: bool = False,
    dark: bool = False,
) -> None:
    width, height = rgba.size
    pixels = rgba.load()
    visited = [[False] * width for _ in range(height)]
    queue: deque[tuple[int, int]] = deque()

    for y in range(height):
        queue.append((0, y))
        queue.append((width - 1, y))

    while queue:
        x, y = queue.popleft()
        if x < 0 or y < 0 or x >= width or y >= height or visited[y][x]:
            continue
        visited[y][x] = True
        r, g, b, a = pixels[x, y]
        if a < 20:
            continue
        match = (light and is_light_border(r, g, b)) or (dark and is_dark_border(r, g, b))
        if not match:
            continue
        pixels[x, y] = (255, 255, 255, 0)
        queue.extend([(x - 1, y), (x + 1, y), (x, y - 1), (x, y + 1)])


def trim_uniform_side_columns(rgba: Image.Image) -> Image.Image:
    width, height = rgba.size
    pixels = rgba.load()

    def column_is_side_bar(x: int) -> bool:
        dark_count = 0
        light_count = 0
        visible = 0
        for y in range(height):
            r, g, b, a = pixels[x, y]
            if a < 20:
                continue
            visible += 1
            brightness = (r + g + b) / 3
            if brightness <= 55:
                dark_count += 1
            if is_light_border(r, g, b):
                light_count += 1
        if visible == 0:
            return True
        return dark_count / visible > 0.82 or light_count / visible > 0.82

    left = 0
    while left < width and column_is_side_bar(left):
        left += 1

    right = width - 1
    while right >= left and column_is_side_bar(right):
        right -= 1

    return rgba.crop((left, 0, right + 1, height))


def main() -> None:
    img = Image.open(SOURCE).convert("RGBA")
    cropped = img.crop((150, 175, 825, 610))
    flood_remove_tone(cropped, light=True, dark=True)
    cropped = trim_uniform_side_columns(cropped)

    max_width = 900
    if cropped.width > max_width:
        ratio = max_width / cropped.width
        cropped = cropped.resize(
            (max_width, int(cropped.height * ratio)),
            Image.Resampling.LANCZOS,
        )

    OUT.parent.mkdir(parents=True, exist_ok=True)
    cropped.save(OUT, "PNG")
    print(f"saved hero car: {OUT} ({cropped.size})")


if __name__ == "__main__":
    main()
