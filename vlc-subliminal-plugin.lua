function descriptor()
  return { 
    title = "Subliminal",
    version = "0.2.0",
    author = "adnanyaqoobvirk",
    url = 'https://github.com/adnanyaqoobvirk/vlc-subliminal-plugin/',
    shortdesc = "Subliminal",
    description = "Download subtitles using python subliminal package",
    capabilities = {"menu", "input-listener"}
  }
end

local xml = require "simplexml"

local extensions_directory = nil
local configuration = nil
local settings_dialog = nil
local error_dialog = nil
local environment_status = false

function activate() 
    -- Setting extension directory
    extensions_directory = vlc.config.userdatadir() .. "/lua/extensions"

    -- Loading configuration
    load_configuration()

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

-- Utilities 

function tprint (tbl, indent)
  if not indent then indent = 0 end
  for k, v in pairs(tbl) do
    formatting = string.rep("  ", indent) .. k .. ": "
    if type(v) == "table" then
      print(formatting)
      tprint(v, indent+1)
    elseif type(v) == 'boolean' then
      print(formatting .. tostring(v))      
    else
      print(formatting .. v)
    end
  end
end

-- plugin code

function load_configuration()
  local config = xml.parse_url("file:///" .. extensions_directory .. "/vlc-subliminal-conf.xml")

  if config["name"] == "subliminal" then
    configuration =  {language = config.children[1].children[1], providers = {}}
    
    provider_counter = 1
    while provider_counter <= #config.children[2].children do
      if config.children[2].children[provider_counter].children[1] == "true" then
        configuration.providers[config.children[2].children[provider_counter]["name"]] = true
      else
        configuration.providers[config.children[2].children[provider_counter]["name"]] = false
      end
      provider_counter = provider_counter + 1
    end
  else
    configuration = {language = "eng", providers = {opensubtitles=true, podnapisi=true, addic7ed=true, tvsubtitles=false, thesubdb=false, napiprojekt=false}}
  end
end

function save_configuration()
  local configuration_xml = [[
  <subliminal>
    <language>]] .. configuration.language .. [[</language>
    <providers>
      <opensubtitles>]] .. tostring(configuration.providers["opensubtitles"]) .. [[</opensubtitles>
      <podnapisi>]] .. tostring(configuration.providers["podnapisi"]) .. [[</podnapisi>
      <addic7ed>]] .. tostring(configuration.providers["addic7ed"]) .. [[</addic7ed>
      <tvsubtitles>]] .. tostring(configuration.providers["tvsubtitles"]) .. [[</tvsubtitles>
      <thesubdb>]] .. tostring(configuration.providers["thesubdb"]) .. [[</thesubdb>
      <napiprojekt>]] .. tostring(configuration.providers["napiprojekt"]) .. [[</napiprojekt>
    </providers>
  </subliminal>
  ]]

  local file = io.open(extensions_directory .. "/vlc-subliminal-conf.xml", "w")
  file:write(configuration_xml)
  file:close()
end

function load_library()
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
  lib_loaded = load_library()
  if not lib_loaded then
    environment_status = false
  else
    lib_loaded()

    python.execute("import os")
    python.execute("from babelfish import Language")
    python.execute("from subliminal import download_best_subtitles, save_subtitles, Video, region")
    python.execute("region.configure('dogpile.cache.dbm', arguments={'filename': '" .. extensions_directory .. "/vlc-subliminal-cachefile.dbm'})")
    environment_status = true
  end
end

function get_providers_string()
  local providers_string = ""
  if configuration.providers["opensubtitles"] then
    providers_string = providers_string .. "'opensubtitles',"
  end
  if configuration.providers["podnapisi"] then
    providers_string = providers_string .. "'podnapisi',"
  end
  if configuration.providers["addic7ed"] then
    providers_string = providers_string .. "'addic7ed',"
  end
  if configuration.providers["tvsubtitles"] then
    providers_string = providers_string .. "'tvsubtitles',"
  end
  if configuration.providers["thesubdb"] then
    providers_string = providers_string .. "'thesubdb',"
  end
  if configuration.providers["napiprojekt"] then
    providers_string = providers_string .. "'napiprojekt',"
  end

  return providers_string
end

function download_subtitles()
  if vlc.input.item() then
    if environment_status then
      -- downloading subtitles
      vlc.osd.message("Downloading subtitles...", 8521, "bottom-left", 100000000)
      local parsed_url = vlc.net.url_parse(vlc.input.item():uri())
      python.execute("video = Video.fromname('" .. vlc.strings.decode_uri(parsed_url["path"]) .. "')")
      python.execute(
        "subtitles = download_best_subtitles([video], {Language('" .. configuration.language ..
        "')}, providers=[" .. get_providers_string() .. "])"
      )
      vlc.osd.channel_clear(8521)
      if python.eval("True if len(subtitles[video]) > 0 else False") then
          python.execute("save_subtitles(video, subtitles[video])")

          -- adding subtitle to video
          local subtitle_path = python.eval("os.path.splitext(video.name)[0] + '.' + str(subtitles[video][0].language) + '.srt'")
          vlc.input.add_subtitle(subtitle_path)
          vlc.osd.message("Subtitles downloaded and added.", 8522, "bottom-left", 1000000)
      else
          vlc.osd.message("Subtitles not found.", 8522, "bottom-left", 1000000)
      end
    else
      show_error_dialog()
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

  local subtitles_language_label = settings_dialog:add_label([[
    Subtitles language code (<a target="_blank" rel="nofollow" 
    href="http://www-01.sil.org/iso639-3/codes.asp">See Codes</a>):
    ]], 1, 1, 1, 1)
  subtitles_language_text_input = settings_dialog:add_text_input(configuration.language, 3, 1, 1, 1)

  local subtitles_providers_label = settings_dialog:add_label("Subtitles providers:", 1, 2, 1, 1)
  opensubtitles_check_box = settings_dialog:add_check_box('OpenSubtitles', configuration.providers["opensubtitles"], 1, 3, 1, 1)
  addic7ed_check_box = settings_dialog:add_check_box('Addic7ed', configuration.providers["addic7ed"], 2, 3, 1, 1)
  podnapisi_check_box = settings_dialog:add_check_box('Podnapisi', configuration.providers["podnapisi"], 3, 3, 1, 1)
  tvsubtitles_check_box = settings_dialog:add_check_box('TvSubtitles', configuration.providers["tvsubtitles"], 1, 4, 1, 1)
  thesubdb_check_box = settings_dialog:add_check_box('TheSubDB', configuration.providers["thesubdb"], 2, 4, 1, 1)
  -- napiprojekt_check_box = settings_dialog:add_check_box('NapiProjekt', configuration.providers["napiprojekt"], 3, 4, 1, 1)

  settings_dialog:add_button("save", save_settings, 2, 5, 1, 1)
  settings_dialog:add_button("cancel", hide_settings, 3, 5, 1, 1)
end

function show_settings()
  if settings_dialog == nil then
    create_settings_dialog()
  end
  settings_dialog:show()
end

function save_settings()
  configuration.language = string.sub(string.lower(subtitles_language_text_input:get_text()), 1, 3)
  configuration.providers["opensubtitles"] = opensubtitles_check_box:get_checked()
  configuration.providers["podnapisi"] = podnapisi_check_box:get_checked()
  configuration.providers["addic7ed"] = addic7ed_check_box:get_checked()
  configuration.providers["tvsubtitles"] = tvsubtitles_check_box:get_checked()
  configuration.providers["thesubdb"] = thesubdb_check_box:get_checked()
  -- configuration.providers["napiprojekt"] = napiprojekt_check_box:get_checked()
  save_configuration()
  settings_dialog:hide()
end

function hide_settings()
  settings_dialog:hide()
end

function show_error_dialog()
  if error_dialog == nil then
    error_dialog = vlc.dialog("Subliminal Error")
    error_dialog:add_label("Environment not prepared properly!", 1, 1, 1, 1)
    error_dialog:add_label("Most probably due to not loading of lunatic_python library.", 1, 2, 1, 1)
    error_dialog:add_button("ok", hide_error_dialog, 2, 3, 1, 1)
  end
  error_dialog:show()
end

function hide_error_dialog()
  error_dialog:hide()
end

function meta_changed()
  return false
end

function input_changed()
  collectgarbage()
end