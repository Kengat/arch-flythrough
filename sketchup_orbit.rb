# ============================================================
#  ОБЛЁТ ВОКРУГ ТОЧКИ — рендер кадров для видео
#  SketchUp Ruby Console:  выдели линию, вставь этот файл,
#  Enter. Камера облетит конец линии на 360° и сохранит кадры.
# ============================================================

module ArchOrbit
  # -------- НАСТРОЙКИ --------
  FRAMES   = 180                                   # кадров на полный круг (180 = 6 c при 30 fps)
  WIDTH    = 1920
  HEIGHT   = 1080
  OUT_DIR  = "C:/dev/arch-flythrough/orbit_frames" # куда складывать PNG
  USE_END  = :start                                # какой конец линии — :start или :end
  CW       = false                                 # направление: false = против часовой
  # ---------------------------

  def self.run
    model = Sketchup.active_model
    view  = model.active_view
    sel   = model.selection

    edge = sel.grep(Sketchup::Edge).first
    unless edge
      UI.messagebox("Выдели линию (Edge) и запусти снова.")
      return
    end

    center = (USE_END == :end) ? edge.end.position : edge.start.position

    require "fileutils"
    FileUtils.mkdir_p(OUT_DIR)

    cam = view.camera
    # вектор от центра вращения к текущей позиции камеры — сохраняем радиус и высоту
    vec = cam.eye - center
    up  = Z_AXIS

    sign = CW ? -1.0 : 1.0
    digits = (FRAMES - 1).to_s.length

    puts "Облёт: #{FRAMES} кадров вокруг #{center.inspect}"
    FRAMES.times do |i|
      angle = sign * (2 * Math::PI) * i / FRAMES
      tr    = Geom::Transformation.rotation(center, Z_AXIS, angle)
      eye   = center + vec.transform(tr)

      view.camera.set(eye, center, up)
      view.refresh

      fname = File.join(OUT_DIR, "frame_%0#{digits}d.png" % i)
      view.write_image(
        :filename    => fname,
        :width       => WIDTH,
        :height      => HEIGHT,
        :antialias   => true,
        :transparent => false,
        :compression => 0.9
      )
      print "\r  кадр #{i + 1}/#{FRAMES}"
    end

    # вернём камеру в исходное положение
    view.camera.set(center + vec, center, up)
    puts "\nГотово. Кадры тут: #{OUT_DIR}"
    UI.messagebox("Снято #{FRAMES} кадров.\n#{OUT_DIR}\n\nДальше собери их в видео скриптом make_video.py")
  end
end

ArchOrbit.run
