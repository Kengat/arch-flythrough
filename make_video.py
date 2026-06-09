"""Собирает кадры облёта (orbit_frames/frame_*.png) в видео.
Использование:  python make_video.py [fps]
Результат:      video/flythrough.mp4
"""
import sys, glob, os
import imageio.v2 as imageio

FPS    = int(sys.argv[1]) if len(sys.argv) > 1 else 30
FRAMES = "orbit_frames"
OUT    = os.path.join("video", "flythrough.mp4")

files = sorted(glob.glob(os.path.join(FRAMES, "frame_*.png")))
if not files:
    print("Нет кадров в", FRAMES, "— сначала запусти sketchup_orbit.rb в SketchUp.")
    sys.exit(1)

os.makedirs("video", exist_ok=True)
# H.264, высокое качество, совместимо с браузерами/телефонами
writer = imageio.get_writer(
    OUT, fps=FPS, codec="libx264", quality=8,
    macro_block_size=None,
    ffmpeg_params=["-pix_fmt", "yuv420p", "-movflags", "+faststart"],
)
for i, f in enumerate(files, 1):
    writer.append_data(imageio.imread(f))
    print(f"\r  {i}/{len(files)}", end="")
writer.close()

mb = os.path.getsize(OUT) / 1024 / 1024
print(f"\nГотово: {OUT}  ({mb:.1f} МБ, {len(files)} кадров @ {FPS} fps)")
