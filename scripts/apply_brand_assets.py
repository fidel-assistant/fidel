from pathlib import Path
from PIL import Image

root = Path(r"C:\Users\USER\Documents\projet\fidel-assistant")
src = root / "docs" / "logo"
assets = root / "mobile" / "assets" / "images"
android_res = root / "mobile" / "android" / "app" / "src" / "main" / "res"
ios_icons = (
    root
    / "mobile"
    / "ios"
    / "Runner"
    / "Assets.xcassets"
    / "AppIcon.appiconset"
)

assets.mkdir(parents=True, exist_ok=True)

copies = {
    "logo_mark.svg": "logo_mark.svg",
    "logo_mark_white.svg": "logo_mark_white.svg",
    "logo_mark_mono.svg": "logo_mark_mono.svg",
    "logo_wordmark.svg": "logo_wordmark.svg",
    "brand_header.png": "brand_header.png",
    "brand_header_v2.png": "brand_header_v2.png",
    "brand_header_black.png": "brand_header_black.png",
    "brand_header_white.png": "brand_header_white.png",
    "favicon.svg": "favicon.svg",
    "favicon-512.png": "favicon-512.png",
    "fidel_logo_master.svg": "fidel_logo_master.svg",
}
for a, b in copies.items():
    (assets / b).write_bytes((src / a).read_bytes())
(assets / "head.png").write_bytes((src / "brand_header_v2.png").read_bytes())
print("flutter assets ok")


def fit_square(im: Image.Image, size: int, bg=(4, 148, 208, 255)) -> Image.Image:
    im = im.convert("RGBA")
    im.thumbnail((size, size), Image.Resampling.LANCZOS)
    canvas = Image.new("RGBA", (size, size), bg)
    x = (size - im.width) // 2
    y = (size - im.height) // 2
    canvas.paste(im, (x, y), im)
    return canvas


def fit_transparent(im: Image.Image, size: int) -> Image.Image:
    im = im.convert("RGBA")
    im.thumbnail((size, size), Image.Resampling.LANCZOS)
    canvas = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    x = (size - im.width) // 2
    y = (size - im.height) // 2
    canvas.paste(im, (x, y), im)
    return canvas


densities = {
    "mipmap-mdpi": 48,
    "mipmap-hdpi": 72,
    "mipmap-xhdpi": 96,
    "mipmap-xxhdpi": 144,
    "mipmap-xxxhdpi": 192,
}
# Source officielle launcher Android (docs/logo/AppIcon-Android.png).
android_icon = Image.open(src / "AppIcon-Android.png")

for folder, size in densities.items():
    d = android_res / folder
    d.mkdir(parents=True, exist_ok=True)
    fit_square(android_icon, size).save(d / "ic_launcher.png", optimize=True)

adaptive = {
    "mipmap-mdpi": 108,
    "mipmap-hdpi": 162,
    "mipmap-xhdpi": 216,
    "mipmap-xxhdpi": 324,
    "mipmap-xxxhdpi": 432,
}
for folder, size in adaptive.items():
    d = android_res / folder
    d.mkdir(parents=True, exist_ok=True)
    # Icône complète sur fond marque — le bg adaptive reprend #0494D0.
    fit_square(android_icon, size).save(d / "ic_launcher_foreground.png", optimize=True)
    Image.new("RGB", (size, size), (4, 148, 208)).save(
        d / "ic_launcher_background.png", optimize=True
    )

launch = Image.open(src / "launch_image.png")
for folder, size in densities.items():
    d = android_res / folder
    fit_transparent(launch, size * 2).save(d / "launch_image.png", optimize=True)

drawable = android_res / "drawable"
drawable.mkdir(parents=True, exist_ok=True)
(drawable / "splash_background.png").write_bytes(
    (src / "splash_background.png").read_bytes()
)

stat_names = [
    "ic_stat_fidel",
    "ic_stat_rappel",
    "ic_stat_checkin",
    "ic_stat_sos",
    "ic_stat_observance",
]
stat_densities = {
    "drawable-mdpi": 24,
    "drawable-hdpi": 36,
    "drawable-xhdpi": 48,
    "drawable-xxhdpi": 72,
    "drawable-xxxhdpi": 96,
}
for name in stat_names:
    im = Image.open(src / f"{name}.png")
    fit_transparent(im, 96).save(drawable / f"{name}.png", optimize=True)
    for folder, size in stat_densities.items():
        d = android_res / folder
        d.mkdir(parents=True, exist_ok=True)
        fit_transparent(im, size).save(d / f"{name}.png", optimize=True)

large = Image.open(src / "ic_notif_large.png")
fit_transparent(large, 256).save(drawable / "ic_notif_large.png", optimize=True)
print("android assets ok")

ios_sizes = {
    "Icon-App-20x20@1x.png": 20,
    "Icon-App-20x20@2x.png": 40,
    "Icon-App-20x20@3x.png": 60,
    "Icon-App-29x29@1x.png": 29,
    "Icon-App-29x29@2x.png": 58,
    "Icon-App-29x29@3x.png": 87,
    "Icon-App-40x40@1x.png": 40,
    "Icon-App-40x40@2x.png": 80,
    "Icon-App-40x40@3x.png": 120,
    "Icon-App-60x60@2x.png": 120,
    "Icon-App-60x60@3x.png": 180,
    "Icon-App-76x76@1x.png": 76,
    "Icon-App-76x76@2x.png": 152,
    "Icon-App-83.5x83.5@2x.png": 167,
    "Icon-App-1024x1024@1x.png": 1024,
}
app = Image.open(src / "AppIcon-1024.png").convert("RGBA")
for name, size in ios_sizes.items():
    out = fit_square(app, size, bg=(4, 148, 208, 255))
    if size == 1024:
        out = out.convert("RGB")
    out.save(ios_icons / name, optimize=True)
print("ios icons ok")
print("done")
