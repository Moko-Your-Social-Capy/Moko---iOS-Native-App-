"""Prepare the supplied artwork for asset catalogs without redrawing it."""
from collections import deque
from pathlib import Path
from PIL import Image, ImageChops, ImageOps

ROOT = Path(__file__).resolve().parents[1] / "Moko/Assets.xcassets"
REFERENCES = Path("/Users/user42/Library/Application Support/Qoder/SharedClientCache/cache/images/7906293a")

# Remove only the green backdrop; the warm mascot colors and dark outline remain.
mascot = Image.open(REFERENCES / "gemini-2.5-flash-image_Using_the_attached_capybara_mascot_as_the_exact_reference_create_a_clean_charact-0-6b331cc0.jpg").convert("RGBA")
pixels = []
for r, g, b, _ in mascot.getdata():
    dominance = g - max(r, b)
    alpha = round(255 * max(0, min(1, (14 - dominance) / 14)))
    pixels.append((r, min(g, r) if alpha < 255 else g, b, alpha))
mascot.putdata(pixels)
bounds = mascot.getchannel("A").point(lambda a: 255 if a > 24 else 0).getbbox()
mascot = mascot.crop(bounds)
mascot = ImageOps.expand(mascot, border=12)
mascot_dir = ROOT / "MocoMascot.imageset"
mascot_dir.mkdir(parents=True, exist_ok=True)
mascot.save(mascot_dir / "mascot.png", optimize=True)

# Strip the screenshot's black surround and extend corner colors to a full square.
# iOS applies its own icon mask; app-icon source images must remain opaque.
logo = Image.open(REFERENCES / "21iouix4-b95d5eda.png").convert("RGB")
channels = logo.split()
mask = ImageChops.lighter(ImageChops.lighter(channels[0], channels[1]), channels[2])
mask = mask.point(lambda value: 255 if value > 38 else 0)
box = mask.getbbox()
logo, mask = logo.crop(box), mask.crop(box)
width, height = logo.size
rgb, dark = logo.load(), mask.load()
exterior = set()
queue = deque((x, y) for y in range(height) for x in range(width)
              if (x in (0, width - 1) or y in (0, height - 1)) and not dark[x, y])
while queue:
    x, y = queue.popleft()
    if (x, y) in exterior:
        continue
    exterior.add((x, y))
    for nx, ny in ((x-1, y), (x+1, y), (x, y-1), (x, y+1)):
        if 0 <= nx < width and 0 <= ny < height and not dark[nx, ny] and (nx, ny) not in exterior:
            queue.append((nx, ny))
# Only black connected to the outside is replaced; eyes and ink remain untouched.
for x, y in exterior:
    sx, sy = float(x), float(y)
    while (round(sx), round(sy)) in exterior:
        sx += (width / 2 - sx) * 0.02
        sy += (height / 2 - sy) * 0.02
    sx += (width / 2 - sx) * 0.06
    sy += (height / 2 - sy) * 0.06
    rgb[x, y] = rgb[round(sx), round(sy)]
logo = logo.resize((1024, 1024), Image.Resampling.LANCZOS)
logo_dir = ROOT / "MocoLogo.imageset"
logo_dir.mkdir(parents=True, exist_ok=True)
logo.resize((256, 256), Image.Resampling.LANCZOS).save(logo_dir / "logo.png", optimize=True)
icon_dir = ROOT / "AppIcon.appiconset"
logo.save(icon_dir / "AppIcon-1024.png", optimize=True)
logo.save(icon_dir / "AppIcon-Dark.png", optimize=True)
ImageOps.grayscale(logo).convert("RGB").save(icon_dir / "AppIcon-Tinted.png", optimize=True)
print(f"Mascot: {mascot.size}, RGBA; icons: {logo.size}, RGB")
