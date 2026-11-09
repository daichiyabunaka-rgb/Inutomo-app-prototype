"""ランチャーアイコン（1024px）を生成するワンオフスクリプト。
犬とも！: ブラウンのグラデーション背景 + 白い肉球（爪4本+メインパッド）。
「顔ではなくワンちゃん」のコンセプト。
"""
from PIL import Image, ImageDraw

SIZE = 1024
img = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
d = ImageDraw.Draw(img)

bg = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
bd = ImageDraw.Draw(bg)
# 上→下のグラデーション (#BCAAA4 -> #6D4C41 相当)
top = (188, 170, 164)
bottom = (109, 76, 65)
for y in range(SIZE):
    t = y / (SIZE - 1)
    r = int(top[0] + (bottom[0] - top[0]) * t)
    g = int(top[1] + (bottom[1] - top[1]) * t)
    b = int(top[2] + (bottom[2] - top[2]) * t)
    bd.line([(0, y), (SIZE, y)], fill=(r, g, b, 255))
# 角丸マスク
mask = Image.new("L", (SIZE, SIZE), 0)
md = ImageDraw.Draw(mask)
md.rounded_rectangle([0, 0, SIZE - 1, SIZE - 1], radius=210, fill=255)
img.paste(bg, (0, 0), mask)

white = (255, 255, 255, 255)

# メインパッド（下に大きい、やや縦長の楕円）
d.ellipse([262, 480, 762, 872], fill=white)

# 上の爪4本（円弧上に配置）
toes = [
    (362, 380),  # 左外
    (462, 316),  # 左内
    (562, 316),  # 右内
    (662, 380),  # 右外
]
sizes = [(116, 132), (100, 118), (100, 118), (116, 132)]
for (cx, cy), (w, h) in zip(toes, sizes):
    d.ellipse([cx - w // 2, cy - h // 2, cx + w // 2, cy + h // 2], fill=white)

img.save("app_icon.png")
print("saved app_icon.png")
