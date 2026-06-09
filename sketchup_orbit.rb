# ============================================================
#  ОБЛЁТ ВОКРУГ ВЕРТИКАЛЬНОЙ ОСИ  (плавно, в реальном времени)
#
#  1) Выдели линию (камера будет крутиться вокруг вертикальной
#     оси через её конец, сохраняя текущий угол наклона).
#  2) Поставь камеру как хочешь видеть здание (угол/высота/зум).
#  3) Window -> Ruby Console, вставь этот файл, Enter.
#  4) Снимай экран рекордером:  Win+Alt+R (Xbox Game Bar)  или OBS.
#
#  ОСТАНОВИТЬ в любой момент — впиши в консоль:
#     ArchOrbit.stop
#  (или просто крутни сцену мышью / нажми другой инструмент)
# ============================================================

module ArchOrbit
  # -------- НАСТРОЙКИ --------
  SPEED_DEG = 0.4    # градусов за кадр (меньше = медленнее и плавнее)
  TURNS     = 0      # сколько полных кругов; 0 = бесконечно (стоп вручную)
  USE_END   = :start # центр оси: конец линии :start или :end
  CW        = false  # true = по часовой
  # ---------------------------

  class Orbit
    def initialize(center, step)
      @center = center
      @step   = step
      @done   = 0.0
    end

    # SketchUp вызывает это каждый кадр сам, с максимальной плавностью
    def nextFrame(view)
      cam = view.camera
      tr  = Geom::Transformation.rotation(@center, Z_AXIS, @step)
      # поворачиваем и глаз, и цель вокруг ОСИ -> наклон камеры сохраняется
      view.camera.set(cam.eye.transform(tr), cam.target.transform(tr), Z_AXIS)
      view.show_frame
      @done += @step.abs
      if TURNS > 0 && @done >= TURNS * 360.degrees
        ArchOrbit.stop
        return false
      end
      true
    end

    def stop(view = nil); end
  end

  def self.run
    model = Sketchup.active_model
    sel   = model.selection
    edge  = sel.grep(Sketchup::Edge).first
    unless edge
      UI.messagebox("Выдели линию (Edge) и запусти снова.")
      return
    end
    center = (USE_END == :end) ? edge.end.position : edge.start.position
    step   = (CW ? -SPEED_DEG : SPEED_DEG).degrees
    model.active_view.animation = Orbit.new(center, step)
    puts "Облёт пошёл. Снимай экран. Стоп:  ArchOrbit.stop"
  end

  def self.stop
    Sketchup.active_model.active_view.animation = nil
    puts "Остановлено."
  end
end

ArchOrbit.run
