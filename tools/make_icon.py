"""ランチャーアイコン（1024px）を生成するワンオフスクリプト。
犬とも！: ベージュの角丸背景 + 茶色の肉球（かかとに白いハート）+
手書き風の文字（UDデジタル教科書体）。
"""
import math

from PIL import Image, ImageDraw, ImageFont, ImageFilter

SIZE = 1024

BEIGE_TOP = (247, 239, 230)
BEIGE_BOTTOM = (233, 220, 204)
PAW_BROWN = (110, 79, 58)
TEXT_BROWN = (110, 79, 58)
HEART_WHITE = (255, 253, 250)

FONT_PATH = r"C:\Windows\Fonts\UDDigiKyokashoN-R.ttc"


def rounded_bg():
    bg = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    for y in range(SIZE):
        t = y / (SIZE - 1)
        c = tuple(
            int(BEIGE_TOP[i] + (BEIGE_BOTTOM[i] - BEIGE_TOP[i]) * t)
            for i in range(3)
        ) + (255,)
        ImageDraw.Draw(bg).line([(0, y), (SIZE, y)], fill=c)
    mask = Image.new("L", (SIZE, SIZE), 0)
    ImageDraw.Draw(mask).rounded_rectangle(
        [0, 0, SIZE - 1, SIZE - 1], radius=230, fill=255
    )
    out = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    out.paste(bg, (0, 0), mask)
    return out


def heart_points(cx, cy, size):
    """上向きのハートの輪郭点を返す（size は横幅の目安）。"""
    pts = []
    for i in range(120):
        t = i / 120 * 2 * math.pi
        x = 16 * math.sin(t) ** 3
        y = (
            13 * math.cos(t)
            - 5 * math.cos(2 * t)
            - 2 * math.cos(3 * t)
            - math.cos(4 * t)
        )
        pts.append((cx + x * size / 32.0, cy - y * size / 32.0))
    return pts


img = rounded_bg()
draw = ImageDraw.Draw(img)

# ---- 肉球の下のやわらかい影
shadow = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
ImageDraw.Draw(shadow).ellipse(
    [512 - 190, 330, 512 + 190, 650], fill=(170, 140, 110, 60)
)
img.alpha_composite(shadow.filter(ImageFilter.GaussianBlur(12)))

# ---- 指（4本。外側は少し外向きに傾ける）
def toe(cx, cy, w, h, angle, fills):
    layer = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    ImageDraw.Draw(layer).ellipse(
        [cx - w // 2, cy - h // 2, cx + w // 2, cy + h // 2], fill=fills
    )
    layer = layer.rotate(angle, center=(cx, cy), resample=Image.BICUBIC)
    return layer

for (cx, cy, w, h, angle) in [
    (372, 470, 116, 138, 10),   # 左外
    (466, 428, 106, 128, 6),    # 左内
    (558, 428, 106, 128, -6),   # 右内
    (652, 470, 116, 138, -10),  # 右外
]:
    img.alpha_composite(toe(cx, cy, w, h, angle, PAW_BROWN + (255,)))

# ---- かかと（大きめのパッド）
draw.ellipse([512 - 160, 470, 512 + 160, 790], fill=PAW_BROWN + (255,))

# ---- かかとの中に白いハート
draw.polygon(
    heart_points(512, 628, 120), fill=HEART_WHITE + (255,)
)

# ---- 手書き風の文字
font = ImageFont.truetype(FONT_PATH, 138, index=0)
text = "いぬとも!"
bbox = draw.textbbox((0, 0), text, font=font)
tw = bbox[2] - bbox[0]
th = bbox[3] - bbox[1]
draw.text(
    (512 - tw // 2 - bbox[0], 840 - th // 2 - bbox[1]),
    text,
    font=font,
    fill=TEXT_BROWN + (255,),
)

img.save("app_icon.png")
print("saved app_icon.png")
