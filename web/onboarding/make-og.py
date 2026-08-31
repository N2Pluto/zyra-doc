"""Generate 1200x630 Open Graph cards for the Zyra onboarding site.

Palette matches zyra-app: bg #2B3540, card #242B32, accent #58D68D, purple #A77EFC.
Latin-only text — PIL has no raqm here, so Thai shaping would break.
"""

from PIL import Image, ImageDraw, ImageFont

W, H = 1200, 630
BG = (43, 53, 64)
CARD = (36, 43, 50)
LINE = (58, 68, 78)
GREEN = (88, 214, 141)
PURPLE = (167, 126, 252)
BLUE = (45, 182, 255)
YELLOW = (255, 212, 0)
WHITE = (255, 255, 255)
MUTED = (140, 153, 166)
MUTED_2 = (99, 109, 118)

F_BOLD = "/System/Library/Fonts/Supplemental/Arial Bold.ttf"
F_REG = "/System/Library/Fonts/Supplemental/Arial.ttf"
F_BLACK = "/System/Library/Fonts/Supplemental/Arial Black.ttf"


def font(path, size):
    return ImageFont.truetype(path, size)


def glow(accent):
    """Soft radial accent glow in the top-left, rendered small then upscaled."""
    sw, sh = 120, 63
    small = Image.new("RGB", (sw, sh), BG)
    px = small.load()
    for y in range(sh):
        for x in range(sw):
            # normalised distance from the top-left corner
            dx = x / (sw * 0.85)
            dy = y / (sh * 0.95)
            d = (dx * dx + dy * dy) ** 0.5
            t = max(0.0, 1.0 - d) ** 2 * 0.30
            px[x, y] = tuple(
                int(BG[i] + (accent[i] - BG[i]) * t) for i in range(3)
            )
    return small.resize((W, H), Image.BICUBIC)


def tracked_text(draw, xy, text, fnt, fill, tracking):
    """Draw text with manual letter-spacing (PIL has no tracking option)."""
    x, y = xy
    for ch in text:
        draw.text((x, y), ch, font=fnt, fill=fill)
        x += draw.textlength(ch, font=fnt) + tracking
    return x


def card(out_path, accent, kicker, title_lines, subtitle, chips):
    img = glow(accent)
    d = ImageDraw.Draw(img, "RGBA")

    # panel
    pad = 44
    d.rounded_rectangle(
        [pad, pad, W - pad, H - pad], radius=28, fill=CARD, outline=LINE, width=2
    )

    left = pad + 56
    y = pad + 54

    # wordmark: green dot + ZYRA
    r = 9
    cy = y + 16
    d.ellipse([left, cy - r, left + 2 * r, cy + r], fill=accent)
    d.ellipse(
        [left - 6, cy - r - 6, left + 2 * r + 6, cy + r + 6],
        outline=accent + (60,),
        width=6,
    )
    tracked_text(d, (left + 34, y), "ZYRA", font(F_BOLD, 30), WHITE, 5)

    # kicker
    kf = font(F_BOLD, 20)
    kx = left + 34
    kw = 0
    for ch in kicker:
        kw += d.textlength(ch, font=kf) + 3
    d.rounded_rectangle(
        [kx, y + 56, kx + kw + 28, y + 56 + 38],
        radius=19,
        fill=accent + (30,),
        outline=accent + (110,),
        width=2,
    )
    tracked_text(d, (kx + 14, y + 64), kicker, kf, accent, 3)

    # title
    ty = y + 126
    tf = font(F_BLACK, 64)
    for line in title_lines:
        d.text((left, ty), line, font=tf, fill=WHITE)
        ty += 78

    # subtitle
    d.text((left, ty + 14), subtitle, font=font(F_REG, 26), fill=MUTED)

    # chips along the bottom
    cx = left
    cf = font(F_BOLD, 19)
    for i, chip in enumerate(chips):
        cw = d.textlength(chip, font=cf)
        col = accent if i == 0 else MUTED
        d.rounded_rectangle(
            [cx, H - pad - 92, cx + cw + 34, H - pad - 46],
            radius=10,
            fill=(255, 255, 255, 12),
            outline=(255, 255, 255, 26),
            width=2,
        )
        d.text((cx + 17, H - pad - 82), chip, font=cf, fill=col)
        cx += cw + 34 + 12

    # bilingual hint, bottom right
    hint = "TH / EN"
    hf = font(F_BOLD, 20)
    hw = d.textlength(hint, font=hf)
    d.text((W - pad - 56 - hw, H - pad - 78), hint, font=hf, fill=MUTED_2)

    img.save(out_path, "PNG", optimize=True)
    print("wrote", out_path)


card(
    "og-index.png",
    GREEN,
    "ONBOARDING",
    ["Get started with Zyra"],
    "Four guides for everyone joining — pick yours",
    ["User", "Developer", "Process", "Glossary"],
)

card(
    "og-workflow.png",
    BLUE,
    "PROCESS",
    ["ClickUp & Figma"],
    "13 statuses, who moves them, and how to pull a Figma spec",
    ["9 sections", "ClickUp + Figma"],
)

card(
    "og-glossary.png",
    YELLOW,
    "REFERENCE",
    ["Zyra glossary"],
    "One word, one meaning — across specs, PRs and UI copy",
    ["12 sections", "Searchable"],
)

card(
    "og-user.png",
    GREEN,
    "FOR NEW USERS",
    ["New user guide"],
    "Sign up, pick an avatar, walk in, meet and share your screen",
    ["11 sections", "~10 min read"],
)

card(
    "og-developer.png",
    PURPLE,
    "FOR NEW DEVELOPERS",
    ["Developer", "onboarding"],
    "Service map, local setup, house rules, git workflow",
    ["10 sections", "Day one"],
)
