"""いただいたアイコン画像（tools/icon_source_1698.jpg）から
配布用アプリアイコン（1024px）を作るワンオフスクリプト。
画像はそのまま（アレンジ不加）。アイコンのベージュ角丸領域を検出して
切り抜き、周囲の背景を透過する。
"""
from PIL import Image, ImageDraw

SRC = "icon_source_1698.jpg"
SIZE = 1024


def detect_iconbbox(im):
    """ベージュ角丸領域の bounding box を検出する。"""
    w, h = im.size
    px = im.load()

    def is_beige(c):
        r, g, b = c
        return r > 235 and g > 225 and 200 < b < 245 and r >= g >= b

    xs, ys = [], []
    for x in range(w):
        for y in range(0, h, 2):
            if is_beige(px[x, y]):
                xs.append(x)
                ys.append(y)
                break
    for y in range(h):
        for x in range(0, w, 2):
            if is_beige(px[x, y]):
                ys.append(y)
                break
    return min(xs), min(ys), max(xs), max(ys)


im = Image.open(SRC).convert("RGB")
x0, y0, x1, y1 = detect_iconbbox(im)
# 検出境界のアンチエイリアス分だけ余白を取り、正方形にする
pad = 2
x0, y0 = max(0, x0 - pad), max(0, y0 - pad)
side = min(max(x1 - x0, y1 - y0) + pad, im.size[0] - x0, im.size[1] - y0)
crop = im.crop((x0, y0, x0 + side, y0 + side))

# 1024px に拡大（そのままの画を使う。補間のみ）
icon = crop.resize((SIZE, SIZE), Image.LANCZOS).convert("RGBA")

# 周囲のグレー背景を透過する（角丸の外側）。
# 背景色は画像の四隅から取得し、色距離で判定する。
corners = [
    icon.getpixel((4, 4)),
    icon.getpixel((SIZE - 5, 4)),
    icon.getpixel((4, SIZE - 5)),
    icon.getpixel((SIZE - 5, SIZE - 5)),
]
bg = tuple(sum(c[i] for c in corners) // 4 for i in range(3))

mask = Image.new("L", (SIZE, SIZE), 255)
mp = mask.load()


def near_bg(c):
    return (
        abs(c[0] - bg[0]) < 18
        and abs(c[1] - bg[1]) < 18
        and abs(c[2] - bg[2]) < 18
    )


# flood fill（外周から到達できる類似色のみ透過するため、
# 内部の同系色を誤って消さない）
from collections import deque

visited = set()
q = deque()
for x in range(SIZE):
    q.append((x, 0))
    q.append((x, SIZE - 1))
for y in range(SIZE):
    q.append((0, y))
    q.append((SIZE - 1, y))
while q:
    x, y = q.popleft()
    if not (0 <= x < SIZE and 0 <= y < SIZE) or (x, y) in visited:
        continue
    visited.add((x, y))
    if near_bg(icon.getpixel((x, y))):
        mp[x, y] = 0
        q.extend([(x + 1, y), (x - 1, y), (x, y + 1), (x, y - 1)])

icon.putalpha(mask)
icon.save("app_icon.png")
print("saved app_icon.png", icon.size, "bg=", bg)
