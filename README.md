# vlc-subliminal-plugin
This plugin can be used to automatically download subtitles for currently playing video file in VLC Media Player. It is based on LUA plugin API of [vlc](https://github.com/videolan/vlc) and python subtitles downloading package [subliminal](https://github.com/Diaoul/subliminal)

**Supported Platforms:** Linux, Windows (work in progress)

**Why yet another subtitles plugin:**
Because already available plugins only support subtitles downloading from opensubtitles. Sometimes other subtitles providers have better subtitles or sometimes opensubtitles does not have the subtitles in their database.

### Installation on Linux

1. Install python subliminal package 
``` sudo pip install subliminal ```
2. Clone this repository using git or you can download the zip file by clicking **'Download Zip'** directly and then extract the files.
3. Copy following files to ~/.local/share/vlc/lua/extensions
    * lunatic_python.so
    * vlc-subliminal-conf.xml
    * vlc-subliminal-plugin.lua

After doing above steps you can see the 'Subliminal' option in the View menu of VLC Media Player. When you click thie option, it will automatically download the best subtitle for your currently running video.

### Settings

1. **Subtitle Language Code:**
You can set three character language code which can be obtained from this [link](http://www-01.sil.org/iso639-3/codes.asp).

2. **Subtitle Providers**:
You can select multiple providers and all selected providers will be checked for best available subtitles. 


**Supported Subtitles Providers:**

* OpenSubtitles
* Addic7ed
* Podnapisi
* TvSubtitles
* TheSubDB