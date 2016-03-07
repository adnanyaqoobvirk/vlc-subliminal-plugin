url = require "net.url"

function descriptor()
  return { 
    title = "Download Subtitles",
    version = "0.0.1",
    author = "adnanyaqoobvirk",
    url = 'https://github.com/adnanyaqoobvirk/vlc-subliminal-plugin/',
    shortdesc = "vlc-subliminal-plugin";
    description = "Download subtitles using python subliminal package",
    capabilities = {"menu", "input-listener" }
  }
end

function activate()
  vlc.msg.dbg("[VSP] Welcome")

  local current_directory = debug.getinfo(1).source:match("@(.*)/.*lua$") 
  assert(package.loadlib(current_directory .. '/lunatic_python.so', 'luaopen_python'))()

  if vlc.input.item() then
    local video_path = url.parse(vlc.input.item():uri()).path
    python.execute("import os")
    python.execute("from babelfish import Language")
    python.execute("from subliminal import download_best_subtitles, save_subtitles, scan_video")
    python.execute("videos = [scan_video('" .. video_path .. "')]")
    python.execute("subtitles = download_best_subtitles(videos, {Language('eng')})")
    python.execute("save_subtitles(videos[0], subtitles[videos[0]])")
    local subtitle_path = python.eval("os.path.splitext(videos[0].name)[0] + '.en.srt'")
    vlc.input.add_subtitle(subtitle_path)
    vlc.osd.message("Subtitle Downloaded and Added.", 1234, "top-right", 1000000)
    vlc.msg.dbg("[VSP] Subtitle download successful.")
  end

  vlc.deactivate()
end

function deactivate()
  vlc.msg.dbg("[VSP] Bye bye!")
end