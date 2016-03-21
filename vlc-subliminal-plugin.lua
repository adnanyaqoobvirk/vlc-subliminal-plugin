function descriptor()
  return { 
    title = "Subliminal",
    version = "0.0.3",
    author = "adnanyaqoobvirk",
    url = 'https://github.com/adnanyaqoobvirk/vlc-subliminal-plugin/',
    shortdesc = "Subliminal",
    description = "Download subtitles using python subliminal package",
    capabilities = {"menu", "input-listener"}
  }
end

function activate()
  if vlc.input.item() then
    lib_loaded = load_library()
    if not lib_loaded then
      assert(false, 'Could not load lunatic_python library.')
    else
      lib_loaded()
      -- downloading subtitles
      vlc.osd.message("Downloading Subtitles...", 1, "bottom-left", 2000000)
      local parsed_url = vlc.net.url_parse(vlc.input.item():uri())
      python.execute("import os")
      python.execute("from babelfish import Language")
      python.execute("from subliminal import download_best_subtitles, save_subtitles, Video, region")
      python.execute("my_region = region.configure('dogpile.cache.memory')")
      python.execute("video = Video.fromname('" .. vlc.strings.decode_uri(parsed_url["path"]) .. "')")
      python.execute("subtitles = download_best_subtitles([video], {Language('eng')})")
      python.execute("save_subtitles(video, subtitles[video])")

      -- adding subtitle to video
      local subtitle_path = python.eval("os.path.splitext(video.name)[0] + '.en.srt'")
      vlc.input.add_subtitle(subtitle_path)
      vlc.osd.message("Subtitle Downloaded and Added.", 2, "top-left", 1000000)
    end
  end

  -- finally deactivating the plugin
  close()
end

function close()
  vlc.deactivate()
end

function deactivate()
  vlc.msg.dbg("Subliminal Plugin Deactivated.")
end

function load_library()
  local extensions_directory = debug.getinfo(1).source:match("@(.*)/.*lua$")
  
  local lib_loaded = nil
  local lib_extensions = {'.so', '.dll', '.dylib'}
  for i, extension in ipairs(lib_extensions) do
    lib_loaded = package.loadlib(extensions_directory .. '/lunatic_python' .. extension, 'luaopen_python')
    if lib_loaded then
      break
    end
  end

  return lib_loaded
end