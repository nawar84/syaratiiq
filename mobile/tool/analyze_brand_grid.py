from pathlib import Path

from PIL import Image

SRC = Path(
    r"C:\Users\nawar\.cursor\projects\c-xampp-htdocs-car-iq\assets"
    r"\c__Users_nawar_AppData_Roaming_Cursor_User_workspaceStorage_d609c8dbc5fb20f133ab5d49c356737e_images_famous-car-taglines-of-all-time-Cover-200620220100-AR-4122022-f2731c3a-748e-4e8a-9b32-2fca160d115b.png"
)

img = Image.open(SRC).convert("RGB")
w, h = img.size

rows = [(0, 90), (90, 178), (178, 266), (266, 354), (354, h)]

for ri, (y1, y2) in enumerate(rows):
    cols = 8 if ri != 4 else 11
    cell_w = w / cols
    print(f"row {ri} cols={cols}")
    for ci in range(cols):
        x1 = int(ci * cell_w)
        x2 = int((ci + 1) * cell_w)
        count = 0
        for y in range(y1, y2):
            for x in range(x1, x2):
                r, g, b = img.getpixel((x, y))
                if r < 235 or g < 235 or b < 235:
                    count += 1
        if count > 200:
            print(f"  col {ci}: x={x1}-{x2}, pixels={count}")
