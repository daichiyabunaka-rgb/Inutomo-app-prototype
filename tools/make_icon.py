"""ランチャーアイコン（1024px）を生成するワンオフスクリプト。
飯とも！: 深オレンジの丸角背景 + 白い丼と箸、湯気。「顔ではなく趣味」のコンセプト。
"""
import math
from PIL import Image, ImageDraw

SIZE = 1024
img = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
d = ImageDraw.Draw(img)

bg = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
bd = ImageDraw.Draw(bg)
# 上→下のグラデーション (#F76707 -> #C92A0A 相当)
top = (247, 103, 7)
bottom = (201, 42, 10)
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

# 丼（下部半楕円 + 縁）
white = (255, 255, 255, 255)
d.pieslice([128, 330, 896, 930], 0, 180, fill=white)
d.rounded_rectangle([104, 566, 920, 640], radius=37, fill=white)
# 丼の飾り線（中央帯）
d.pieslice([128, 330, 896, 930], 0, 180, outline=(247, 103, 7, 255), width=0)

# 箸（右上へ2本）
chopstick_color = (255, 236, 210, 255)
for dx in (0, 46):
    d.line([(430 + dx, 500), (820 + dx, 130)], fill=chopstick_color, width=34)
    d.ellipse([820 + dx - 17, 113, 820 + dx + 17, 147], fill=chopstick_color)

# 湯気（3本の弧）
steam = (255, 255, 255, 200)
for sx in (300, 420, 540):
    d.arc([sx - 60, 150, sx + 60, 330], start=250, end=8, fill=steam, width=22)

img.save("app_icon.png")
print("saved app_icon.png")
