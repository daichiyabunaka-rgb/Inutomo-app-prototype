"""ランチャーアイコン（1024px）を生成するワンオフスクリプト。
犬とも！: クリーム色の角丸背景に、犬の肉球（ピンクのパッド＋指）のイラスト。
「犬の肉球 イラスト」で見られる定番のタッチ（丸いパッドにハイライト）で描く。
"""
from PIL import Image, ImageDraw, ImageFilter

SIZE = 1024

def rounded_gradient_bg():
    """クリーム色の縦グラデーション背景（角丸）。角の外は透明。"""
    bg = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    top, bottom = (255, 248, 240), (244, 216, 198)
    for y in range(SIZE):
        t = y / (SIZE - 1)
        c = tuple(int(top[i] + (bottom[i] - top[i]) * t) for i in range(3)) + (255,)
        ImageDraw.Draw(bg).line([(0, y), (SIZE, y)], fill=c)
    mask = Image.new("L", (SIZE, SIZE), 0)
    ImageDraw.Draw(mask).rounded_rectangle([0, 0, SIZE - 1, SIZE - 1], radius=230, fill=255)
    out = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    out.paste(bg, (0, 0), mask)
    return out

def soft_shape(color, circles):
    """複数円の和でシルエットを作り、やわらかい輪郭のイラストにする。"""
    layer = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    d = ImageDraw.Draw(layer)
    for (x, y, r) in circles:
        d.ellipse([x - r, y - r, x + r, y + r], fill=color)
    return layer.filter(ImageFilter.GaussianBlur(3))

img = rounded_gradient_bg()

# ---- パッドの下のやわらかい影
img.alpha_composite(soft_shape((200, 160, 130, 70),
                    [(512, 665, 225), (388, 575, 120), (636, 575, 120)]))

PAD = (240, 132, 118, 255)        # ピンクの肉球
PAD_DARK = (226, 110, 96, 255)    # 影・縁用の濃いピンク

# ---- メインパッド（犬の肉球らしい「上に2つの丸み」のある形）
img.alpha_composite(soft_shape(PAD, [
    (512, 660, 190),   # 中央の大きい丸
    (400, 580, 130),   # 左上の丸み（シルエットを出す）
    (624, 580, 130),   # 右上の丸み
    (430, 690, 90),    # 下をずらして丸みを足す
    (594, 690, 90),
]))

# パッドの下部に濃いピンクを薄く重ねて立体感を出す
bottom_tint = Image.new("L", (SIZE, SIZE), 0)
td = ImageDraw.Draw(bottom_tint)
td.ellipse([512 - 190, 600, 512 + 190, 900], fill=60)
img.alpha_composite(Image.composite(
    soft_shape(PAD_DARK, [(512, 740, 165)]),
    Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0)),
    bottom_tint,
))

# ---- 指（4本。外側の2本は少し外向きに傾ける）
def toe(cx, cy, w, h, angle):
    layer = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    d = ImageDraw.Draw(layer)
    d.ellipse([cx - w // 2, cy - h // 2, cx + w // 2, cy + h // 2], fill=PAD)
    layer = layer.filter(ImageFilter.GaussianBlur(3))
    if angle:
        layer = layer.rotate(angle, center=(cx, cy), resample=Image.BICUBIC)
    return layer

for (cx, cy, w, h, angle) in [
    (348, 388, 118, 140, 12),   # 左外
    (454, 330, 104, 124, 6),    # 左内
    (570, 330, 104, 124, -6),   # 右内
    (676, 388, 118, 140, -12),  # 右外
]:
    img.alpha_composite(toe(cx, cy, w, h, angle))

# ---- ハイライト（イラスト特有のつや）
hl = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
hd = ImageDraw.Draw(hl)
# パッドのつや
hd.ellipse([452, 590, 560, 652], fill=(255, 235, 230, 190))
hd.ellipse([478, 612, 534, 640], fill=(255, 245, 242, 220))
# 指のつや
for (cx, cy, w) in [(348, 362, 40), (454, 312, 36), (570, 312, 36), (676, 362, 40)]:
    hd.ellipse([cx - w // 2, cy, cx + w // 2, cy + 26], fill=(255, 235, 230, 170))
img.alpha_composite(hl.filter(ImageFilter.GaussianBlur(2)))

# ---- キラッ（元気さのアクセント：小さな星2つ）
star_white = (255, 255, 255, 235)
sd = ImageDraw.Draw(img)
for (cx, cy, r) in [(758, 236, 34), (848, 332, 20)]:
    sd.line([(cx - r, cy), (cx + r, cy)], fill=star_white, width=14)
    sd.line([(cx, cy - r), (cx, cy + r)], fill=star_white, width=14)
    # 丸い線端
    for (px, py) in [(cx - r, cy), (cx + r, cy), (cx, cy - r), (cx, cy + r)]:
        sd.ellipse([px - 7, py - 7, px + 7, py + 7], fill=star_white)

img.save("app_icon.png")
print("saved app_icon.png")
