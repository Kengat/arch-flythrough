# ============================================================
#  ARCH ORBIT — панель облёта камеры вокруг вертикальной оси
#
#  Установка (как плагин, грузится сам при старте):
#    положи этот файл в папку Plugins SketchUp, напр.:
#    C:\Users\<ты>\AppData\Roaming\SketchUp\SketchUp 20XX\SketchUp\Plugins
#    перезапусти SketchUp -> меню Extensions -> "Arch Orbit — панель"
#
#  Или разово: Ruby Console ->  load "C:/dev/arch-flythrough/arch_orbit_panel.rb"
#
#  Как снимать: выдели линию, открой панель, Старт, пиши экран (Win+Alt+R / OBS).
# ============================================================
require "sketchup.rb"

module ArchOrbit
  @dialog  = nil
  @anim    = nil
  @speed   = 0.4      # градусов за кадр
  @cw      = false
  @use_end = :start
  @edge    = nil

  class << self
    attr_accessor :speed, :cw, :use_end, :edge

    # центр вертикальной оси = выбранный конец линии (или nil, если линия исчезла)
    def center
      return nil unless @edge && @edge.valid?
      (@use_end == :end) ? @edge.end.position : @edge.start.position
    end

    def running?
      !!(@anim && Sketchup.active_model.active_view.animation)
    end
  end

  # --- сама анимация: SketchUp вызывает nextFrame каждый кадр ---
  class Orbit
    def nextFrame(view)
      c = ArchOrbit.center
      return false unless c
      step = (ArchOrbit.cw ? -ArchOrbit.speed : ArchOrbit.speed).degrees
      tr   = Geom::Transformation.rotation(c, Z_AXIS, step)
      cam  = view.camera
      # крутим и глаз, и цель вокруг ОСИ -> угол наклона камеры сохраняется
      view.camera.set(cam.eye.transform(tr), cam.target.transform(tr), Z_AXIS)
      view.show_frame
      true
    end
    def stop(view = nil); end
  end

  def self.start_orbit
    model = Sketchup.active_model
    edge  = model.selection.grep(Sketchup::Edge).first
    @edge = edge if edge
    unless @edge && @edge.valid?
      status("Сначала выдели линию (Edge) в модели.")
      return
    end
    @anim = Orbit.new
    model.active_view.animation = @anim
    status("Облёт идёт. Пиши экран: Win+Alt+R или OBS.")
  end

  def self.stop_orbit
    Sketchup.active_model.active_view.animation = nil if @anim
    @anim = nil
    status("Остановлено.")
  end

  def self.status(msg)
    @dialog.execute_script("setStatus(#{msg.inspect})") if @dialog && @dialog.visible?
    puts "[ArchOrbit] #{msg}"
  end

  # ---------------- панель (HTML-диалог) ----------------
  def self.show_panel
    if @dialog && @dialog.visible?
      @dialog.bring_to_front
      return
    end

    @dialog = UI::HtmlDialog.new(
      :dialog_title    => "Arch Orbit",
      :preferences_key => "com.archorbit.panel",
      :width           => 300,
      :height          => 380,
      :resizable       => true,
      :style           => UI::HtmlDialog::STYLE_DIALOG
    )
    @dialog.set_html(html)

    @dialog.add_action_callback("start")     { |_c|     start_orbit }
    @dialog.add_action_callback("stop")       { |_c|     stop_orbit }
    @dialog.add_action_callback("set_speed")  { |_c, v|  @speed = v.to_f }
    @dialog.add_action_callback("set_dir")    { |_c, v|  @cw = (v == "cw") }
    @dialog.add_action_callback("set_end")    { |_c, v|  @use_end = v.to_sym }
    @dialog.add_action_callback("ready")      { |_c|     push_state }
    @dialog.set_on_closed { stop_orbit }

    @dialog.show
  end

  # синхронизируем панель с текущими значениями
  def self.push_state
    return unless @dialog
    @dialog.execute_script("initUI(#{@speed}, #{@cw}, #{@use_end.to_s.inspect})")
  end

  def self.html
    <<~HTML
      <!DOCTYPE html><html><head><meta charset="utf-8">
      <style>
        body{font-family:"Segoe UI",sans-serif;background:#1b1d22;color:#eef;margin:0;padding:16px}
        h2{margin:0 0 14px;font-size:16px;font-weight:600}
        .row{margin:14px 0}
        label{display:block;font-size:12px;color:#9aa0aa;margin-bottom:6px}
        input[type=range]{width:100%}
        .val{float:right;color:#5b8def;font-weight:600}
        .seg{display:flex;gap:6px}
        .seg button{flex:1;padding:7px;border:1px solid #333;background:#23262d;color:#cfd4dc;border-radius:7px;cursor:pointer;font-size:12px}
        .seg button.on{background:#5b8def;border-color:#5b8def;color:#fff}
        .go{display:flex;gap:8px;margin-top:18px}
        .go button{flex:1;padding:12px;border:0;border-radius:9px;cursor:pointer;font-size:14px;font-weight:600}
        #play{background:#3ba55d;color:#fff}#stp{background:#d83c3c;color:#fff}
        #status{margin-top:14px;font-size:11px;color:#8a909a;min-height:14px}
        .hint{font-size:11px;color:#6b7079;margin-top:4px}
      </style></head><body>
        <h2>Облёт камеры</h2>

        <div class="row">
          <label>Скорость <span class="val" id="sv">0.40</span> °/кадр</label>
          <input type="range" id="speed" min="0.05" max="2" step="0.05" value="0.4">
        </div>

        <div class="row">
          <label>Направление</label>
          <div class="seg">
            <button id="ccw" onclick="setDir('ccw')">↺ против часовой</button>
            <button id="cw"  onclick="setDir('cw')">по часовой ↻</button>
          </div>
        </div>

        <div class="row">
          <label>Ось вращения — конец выделенной линии</label>
          <div class="seg">
            <button id="estart" onclick="setEnd('start')">начало</button>
            <button id="eend"   onclick="setEnd('end')">конец</button>
          </div>
        </div>

        <div class="go">
          <button id="play" onclick="sketchup.start()">▶ Старт</button>
          <button id="stp"  onclick="sketchup.stop()">■ Стоп</button>
        </div>
        <div class="hint">Выдели линию в модели, потом «Старт». Запись экрана: Win+Alt+R.</div>
        <div id="status"></div>

      <script>
        var dir='ccw', end='start';
        function setStatus(t){document.getElementById('status').textContent=t;}
        function setDir(d){dir=d;
          document.getElementById('cw').className  = d=='cw'?'on':'';
          document.getElementById('ccw').className = d=='ccw'?'on':'';
          sketchup.set_dir(d);}
        function setEnd(e){end=e;
          document.getElementById('eend').className   = e=='end'?'on':'';
          document.getElementById('estart').className = e=='start'?'on':'';
          sketchup.set_end(e);}
        function initUI(speed, cw, useEnd){
          var s=document.getElementById('speed'); s.value=speed;
          document.getElementById('sv').textContent=Number(speed).toFixed(2);
          setDir(cw?'cw':'ccw'); setEnd(useEnd);
        }
        document.getElementById('speed').addEventListener('input',function(){
          document.getElementById('sv').textContent=Number(this.value).toFixed(2);
          sketchup.set_speed(this.value);
        });
        sketchup.ready();
      </script>
      </body></html>
    HTML
  end

  # ---- кнопка на тулбаре + пункт меню (НИЧЕГО не открываем при старте) ----
  unless defined?(@loaded) && @loaded
    dir = File.dirname(__FILE__)
    cmd = UI::Command.new("Arch Orbit") { show_panel }
    cmd.tooltip          = "Arch Orbit — облёт камеры"
    cmd.status_bar_text  = "Открыть панель облёта камеры вокруг оси"
    ic16 = File.join(dir, "arch_orbit_assets", "orbit_16.png")
    ic24 = File.join(dir, "arch_orbit_assets", "orbit_24.png")
    if File.exist?(ic24)
      cmd.small_icon = ic16
      cmd.large_icon = ic24
    end

    tb = UI::Toolbar.new("Arch Orbit")
    tb.add_item(cmd)
    tb.restore   # показать тулбар (запоминает состояние между сессиями)

    UI.menu("Extensions").add_item(cmd)
    @loaded = true
  end
end
# Панель сама НЕ открывается — жми кнопку на тулбаре "Arch Orbit".
