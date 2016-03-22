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
    
    -- preparing python environment
    prepare_environment()

    -- downloading subtitles
    download_subtitles()

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

function menu()
  
  return {    
    "Download Best Subtitles"
  }

end

function prepare_environment()

    if vlc.input.item() then
        lib_loaded = load_library()
        if not lib_loaded then
            assert(false, 'Could not load lunatic_python library.')
        else
            lib_loaded()

            python.execute("import os")
            python.execute("from babelfish import Language")
            python.execute("from subliminal import download_best_subtitles, save_subtitles, Video, region")
            python.execute("my_region = region.configure('dogpile.cache.memory')")
        end
    end

end

function download_subtitles()

    if vlc.input.item() then
        -- downloading subtitles
        vlc.osd.message("Downloading Subtitles...", 8521, "top-right", 2000000)
        local parsed_url = vlc.net.url_parse(vlc.input.item():uri())
        python.execute("video = Video.fromname('" .. vlc.strings.decode_uri(parsed_url["path"]) .. "')")
        python.execute("subtitles = download_best_subtitles([video], {Language('eng')})")
        if python.eval("True if len(subtitles[video]) > 0 else False") then
            python.execute("save_subtitles(video, subtitles[video])")

            -- adding subtitle to video
            local subtitle_path = python.eval("os.path.splitext(video.name)[0] + '.en.srt'")
            vlc.input.add_subtitle(subtitle_path)
            vlc.osd.message("Subtitles Downloaded and Added.", 8522, "top-right", 1000000)
        else
            vlc.osd.message("Subtitles Not Found.", 8522, "top-right", 1000000)
        end
    end

end

function trigger_menu(dlg_id)
  
  if dlg_id == 1 then
    download_subtitles()
  end
  
  collectgarbage()

end 