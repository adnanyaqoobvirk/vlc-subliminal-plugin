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

local subtitles_language_selected = "eng"
local subtitles_providers_selected = "'opensubtitles', 'podnapisi', 'addic7ed'"
local settings_dialog = nil
local subtitles_language_text_input = nil

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
          "subtitles = download_best_subtitles([video], {Language('" .. subtitles_language_selected ..
          "')}, providers=[" .. subtitles_providers_selected .. "])"
        )
        vlc.osd.channel_clear(8521)
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

  subtitles_language_label = settings_dialog:add_label([[
    Subtitles language code (<a target="_blank" rel="nofollow" 
    href="http://www-01.sil.org/iso639-3/codes.asp">See Codes</a>):
    ]], 1, 1, 1, 1)
  subtitles_language_text_input = settings_dialog:add_text_input(subtitles_language_selected, 3, 1, 1, 1)

  subtitles_providers_label = settings_dialog:add_label("Subtitles providers:", 1, 2, 1, 1)
  opensubtitles_check_box = settings_dialog:add_check_box('OpenSubtitles', true, 1, 3, 1, 1)
  addic7ed_check_box = settings_dialog:add_check_box('Addic7ed', true, 2, 3, 1, 1)
  podnapisi_check_box = settings_dialog:add_check_box('Podnapisi', true, 3, 3, 1, 1)
  tvsubtitles_check_box = settings_dialog:add_check_box('TvSubtitles', false, 1, 4, 1, 1)
  thesubdb_check_box = settings_dialog:add_check_box('TheSubDB', false, 2, 4, 1, 1)
  napiprojekt_check_box = settings_dialog:add_check_box('NapiProjekt', false, 3, 4, 1, 1)

  settings_dialog:add_button("save", save_settings, 2, 5, 1, 1)
  settings_dialog:add_button("cancel", hide_settings, 3, 5, 1, 1)
end

function show_settings()
  if settings_dialog ==  nil then
    create_settings_dialog()
  end
  settings_dialog:show()
end

function save_settings()
  subtitles_language_selected = string.sub(string.lower(subtitles_language_text_input:get_text()), 1, 3)
  subtitles_providers_selected = ""
  if opensubtitles_check_box:get_checked() then
    subtitles_providers_selected = subtitles_providers_selected .. "'opensubtitles',"
  end
  if addic7ed_check_box:get_checked() then
    subtitles_providers_selected = subtitles_providers_selected .. "'addic7ed',"
  end
  if podnapisi_check_box:get_checked() then
    subtitles_providers_selected = subtitles_providers_selected .. "'podnapisi',"
  end
  if tvsubtitles_check_box:get_checked() then
    subtitles_providers_selected = subtitles_providers_selected .. "'tvsubtitles',"
  end
  if thesubdb_check_box:get_checked() then
    subtitles_providers_selected = subtitles_providers_selected .. "'thesubdb',"
  end
  if napiprojekt_check_box:get_checked() then
      subtitles_providers_selected = subtitles_providers_selected .. "'napiprojekt',"
  end
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