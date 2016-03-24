function descriptor()
  return { 
    title = "Subliminal",
    version = "0.0.4",
    author = "adnanyaqoobvirk",
    url = 'https://github.com/adnanyaqoobvirk/vlc-subliminal-plugin/',
    shortdesc = "Subliminal",
    description = "Download subtitles using python subliminal package",
    capabilities = {"menu", "input-listener"}
  }
end

local subtitles_languages = {
'alb','ara','arm','baq','ben','bos','bre','bul','bur','cat','chi','hrv','cze','dan','dut','eng',
'epo','est','fin','fra','glg','geo','ger','ell','heb','hin','hun','ice','ind','ita','jpn','kaz',
'khm','kor','lav','lit','ltz','mac','may','mal','mon','nor','oci','per','pol','por','pob','rum',
'rus','scc','sin','slo','slv','spa','swa','swe','syr','tgl','tel','tha','tur','ukr','urd','vie'
}

local subtitles_providers = {
  'opensubtitles', 'podnapisi', 'thesubdb', 'tvsubtitles', 'napiprojekt'
}

local subtitles_language_selected = "'eng'"
local subtitles_providers_selected = "'opensubtitles'"
local settings_dialog = nil
local subtitles_language_dropdown = nil

function activate() 
    -- preparing python environment
    prepare_environment()

    -- downloading subtitles
    download_subtitles()
end

function deactivate()
  vlc.msg.dbg("Subliminal plugin deactivated.")
end

function close()
  vlc.deactivate()
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
    "Download Best Subtitles",
    "Settings"
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
        vlc.osd.message("Downloading subtitles...", 8521, "top-right", 1000000)
        local parsed_url = vlc.net.url_parse(vlc.input.item():uri())
        python.execute("video = Video.fromname('" .. vlc.strings.decode_uri(parsed_url["path"]) .. "')")
        python.execute(
          "subtitles = download_best_subtitles([video], {Language(" .. subtitles_language_selected ..
          ")}, providers=[" .. subtitles_providers_selected .. "])"
        )
        if python.eval("True if len(subtitles[video]) > 0 else False") then
            python.execute("save_subtitles(video, subtitles[video])")

            -- adding subtitle to video
            local subtitle_path = python.eval("os.path.splitext(video.name)[0] + '.' + str(subtitles[video][0].language) + '.srt'")
            vlc.input.add_subtitle(subtitle_path)
            vlc.osd.message("Subtitles downloaded and added.", 8522, "top-right", 1000000)
        else
            vlc.osd.message("Subtitles not found.", 8522, "top-right", 1000000)
        end
    end
end

function trigger_menu(id)
  if id == 1 then
    download_subtitles()
  else
    show_settings()
  end
  
  collectgarbage()
end 

function create_settings_dialog()
  settings_dialog = vlc.dialog("Subliminal Settings")

  subtitles_language_label = settings_dialog:add_label("Subtitles language:", 1, 1, 1, 1)
  subtitles_language_dropdown = settings_dialog:add_dropdown(3, 1, 1, 1)
  for i, value in ipairs(subtitles_languages) do
    subtitles_language_dropdown:add_value(value, i)
  end

  settings_dialog:add_button("save", save_settings, 2, 10, 1, 1)
  settings_dialog:add_button("cancel", hide_settings, 3, 10, 1, 1)
end

function show_settings()
  if settings_dialog ==  nil then
    create_settings_dialog()
  end
  settings_dialog:show()
end

function save_settings()
  subtitles_language_selected = "'" .. subtitles_languages[subtitles_language_dropdown:get_value()] .. "'"
  settings_dialog:hide()
end

function hide_settings()
  settings_dialog:hide()
end

function meta_changed()
  return false
end

function input_changed()
  collectgarbage()
end