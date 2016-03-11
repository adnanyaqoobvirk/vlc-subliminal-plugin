url = require "net.url"

function descriptor()
  return { 
    title = "Subliminal Plugin",
    version = "0.0.1",
    author = "adnanyaqoobvirk",
    url = 'https://github.com/adnanyaqoobvirk/vlc-subliminal-plugin/',
    shortdesc = "Subliminal";
    description = "Download subtitles using python subliminal package",
    capabilities = {"menu", "input-listener" }
  }
end

function activate()
  vlc.msg.dbg("Activating Subliminal Plugin!")

  local current_directory = debug.getinfo(1).source:match("@(.*)/.*lua$") 
  assert(package.loadlib(current_directory .. '/lunatic_python.so', 'luaopen_python'))()

  python.execute("import os")
  python.execute("from babelfish import Language")
  python.execute("from subliminal import download_best_subtitles, region, save_subtitles, scan_video")
  python.execute("region.configure('dogpile.cache.dbm', arguments={'filename': '" .. current_directory .. "/subliminal_cachefile.dbm'})")

  vlc.osd.message("Subliminal Plugin Activated.", 1, "bottom-left", 1000000)
end

function close()
  vlc.deactivate()
end

function deactivate()
  vlc.msg.dbg("Deactivating Subliminal Plugin!")
end

function menu()
  return {    
    'Download Subtitles',
    'Settings'
  }
end

function trigger_menu(dlg_id)
  if dlg_id == 1 then
    download()
  elseif dlg_id == 2 then
    vlc.osd.message("Settings are still in development phase...", 1, "bottom-left", 1000000)
  end
  collectgarbage()
end 

function download()
  if vlc.input.item() then
    vlc.osd.message("Downloading Subtitles...", 1, "bottom-left", 2000000)
    local video_path = url.parse(vlc.input.item():uri()).path
    python.execute("videos = [scan_video('" .. video_path .. "')]")
    python.execute("subtitles = download_best_subtitles(videos, {Language('eng')})")
    python.execute("save_subtitles(videos[0], subtitles[videos[0]])")
    local subtitle_path = python.eval("os.path.splitext(videos[0].name)[0] + '.en.srt'")
    vlc.input.add_subtitle(subtitle_path)
    vlc.osd.message("Subtitle Downloaded and Added.", 2, "top-left", 1000000)
    vlc.msg.dbg("Subtitle download successful.")
  else
    vlc.osd.message("Please play a file before downloading subtitles.", 1, "bottom-left", 1000000)
  end
end