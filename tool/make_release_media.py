"""Compose actual Flutter frame captures; requires Pillow.

Capture each style with the opt-in render test in glass_morph_test.dart.
The GIF is illustrative UI playback, not a measured device FPS result.
"""
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "screenshots" / "v0.3.0"
OUT.mkdir(parents=True, exist_ok=True)
try:
    font = ImageFont.truetype("C:/Windows/Fonts/segoeui.ttf", 11)
except OSError:
    font = ImageFont.load_default()

frames = []
for index in range(0, 121, 2):
    sheet = Image.new("RGB", (1080, 310), "#111827")
    draw = ImageDraw.Draw(sheet)
    for col, motion in enumerate(("droplet", "jelly", "merge")):
        with Image.open(ROOT / "build" / "morph" / motion / f"frame_{index:03}.png") as source:
            sheet.paste(source.convert("RGB"), (col * 360, 30))
        draw.text((col * 360 + 20, 8), motion.upper(), fill="#e7e9f2", font=font)
    frames.append(sheet)

palette_source = Image.new("RGB", (1080, 310 * 5))
for row, index in enumerate((0, 4, 8, 15, 30)):
    palette_source.paste(frames[index], (0, row * 310))
palette = palette_source.quantize(colors=256)
indexed = [frame.quantize(palette=palette, dither=Image.Dither.NONE) for frame in frames]
durations = [40] * len(indexed)
durations[0] = durations[30] = durations[-1] = 500
indexed[0].save(OUT / "morph-styles.gif", save_all=True, append_images=indexed[1:],
                duration=durations, loop=0, optimize=True, disposal=2)
frames[8].save(OUT / "morph-styles.png", optimize=True)
print(f"Wrote {len(frames)} presentation frames to {OUT}")

# The modal scenes use the same actual Flutter capture workflow at 360 x 480.
if (ROOT / 'build/modal/prompt-light/frame_044.png').exists():
    modal_frames = []
    indices = list(range(0, 45, 2))
    for index in indices:
        sheet = Image.new('RGB', (1080, 510), '#111827')
        draw = ImageDraw.Draw(sheet)
        for col, (mode, label) in enumerate([
            ('prompt-light', 'PROMPT / LIGHT'), ('prompt-dark', 'PROMPT / DARK'),
            ('panel', 'BOTTOM PANEL')]):
            with Image.open(ROOT / 'build/modal' / mode / f'frame_{index:03}.png') as source:
                sheet.paste(source.convert('RGB'), (col * 360, 30))
            draw.text((col * 360 + 20, 8), label, fill='#e7e9f2', font=font)
        modal_frames.append(sheet)
    palette_source = Image.new('RGB', (1080, 510 * 3))
    for row, index in enumerate((0, 6, 11)):
        palette_source.paste(modal_frames[index], (0, row * 510))
    palette = palette_source.quantize(colors=256)
    indexed = [f.quantize(palette=palette, dither=Image.Dither.NONE) for f in modal_frames]
    durations = [40] * len(indexed)
    durations[0] = durations[11] = durations[-1] = 700
    indexed[0].save(OUT / 'modal-transitions.gif', save_all=True,
        append_images=indexed[1:], duration=durations, loop=0, optimize=True, disposal=2)
    modal_frames[11].save(OUT / 'modal-transitions.png', optimize=True)
    print('Wrote modal triptych')
