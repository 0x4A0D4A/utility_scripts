# utility_scripts: a collection of miscellaneous scripts for use on my GNU/Linux laptop

- `autopape.sh`: a simple script to endlessly loop through each image in a directory and set said image as the desktop wallpaper for a specified time period. Both the command used to set the wallpaper and the time interval between wallpaper changes can be specified with optional flags & arguments. Uses `feh --bg-fill` & an interval of `1m` by default.
- `bluetooth-off.sh`: script for disabling Bluetooth with `bluetoothcl` on a system that uses runit as its init system (such as Void GNU/Linux).
- `bluetooth-on.sh`: Same as `bluetooth-off.sh` but for enabling Bluetooth.
- `bluetooth_dmenu.pl`: Perl script that allows the user to select a Bluetooth device to connect to via `dmenu`.
- `bluetooth_info.pl`: Perl script to display information about connected Bluetooth devices. Designed to be used with polybar.
- `bspwm_window_count.sh`: script for listing the number of open windows on the current "desktop" (workspace) with the bspwm window manager. Primarily for use in status bars as indicator that windows may be hidden behind another when in floating or monocle mode.
- `claude.sh`: wrapper for running the official Claude Code CLI binary on Guix System, where its FHS-expecting release binary can't run natively. Launches it inside a `guix shell --container --emulate-fhs` sandbox that merges a base toolchain with the user's own installed packages, shares the host filesystem to mirror the invoking user's own permissions, and forwards `TERM`/`DISPLAY`/session environment variables so color, clipboard, and desktop integration work as normal.
- `clean_files.sh`: script that loops through each file in a directory, opens each file with the `mimeopen` utility, and prompts the user to decide whether or not to delete the image.
- `clean_papes.sh`: loops over files in a directory, setting each the as the desktop wallpaper, and prompts the user to save the file to the wallpapers directory or delete it.
- `defn`: shell script to look up word in dictionary file in the format: `word:\tdefinition\n`.
- `ensure_connected.sh`: script to remedy my broken WiFi, which has an issue of disconnecting unpredictably and then requiring several attempts to reconnect as if the password supplied were incorrect despite it not being changed since the initial connection. This script checks if the WiFi is connected at regular intervals, and if not will keep trying to reconnect until successful. Reads WiFi network name from a `config.env` file and uses the hashed password already store by NetworkManager. `file_previewer.sh`: a script for generating terminal file previews, for use in the terminal file manager `lf`.
  Uses the `mimetype` utility to identify the filetype and generates an appropriate preview (text, ASCII image, etc).
- `fzfplay.sh` script that allows a music file or directory to be selected via `fzf` to be enqueued with `umpv`.
- `hide_bar.sh`: script for hiding & unhiding the polybar bar on the bspwm window manager.
- `hugo_post.sh`: simple script to create a new Hugo post with the directory structure `/content/blog/Post Title/index.md` instead of the default `/content/blog/Post Title.md` created when you run the command `hugo new content`.
- `karaoke.pl`: script that fetches lyrics for music files from the LRCLIB API and saves them to \*.lrc files.
  - If you use [beets](https://docs.beets.io/en/latest/index.html) to manage your music library, you can make this script run automatically on an album once imported by adding the following lines to your beets `config.yaml`:

  ```yaml
  plugins: hook # append to your pre-existing plugin list if using other plugins

  hook:
    hooks:
      - event: album_imported
        command: '/path/to/script/karaoke.pl "{album.path}"'
  ```

- `list_manual_pkgs.sh`: one-line script to list only the names of packages manually installed with the xbps package manager (the default Void package manager).
- `mousshe.sh`: script for controlling the mouse of an Xorg session over SSH.
- `music_dmenu.sh`: script to play a specific artist, album, or track selected with dmenu.
- `play_music.sh`: simple script to play music albums based off the supplied artist & album name.
- `qutebrowser_search.sh`: script that finds all the search engines defined in the qutebrowser `config.py` configuration file and makes them available for searching via dmenu, i.e. allow web searching with qutebrowser without having to wait for it to start up before you start your search.
- `qutebrowser_dmenu.pl`: script that constructs a `dmenu` menu of all search engines defined in the `qutebrowser` configuration file for searching without first launching `qutebrowser`.
- `remote_sudo.sh`: script to run one command as root on a remote host, feeding the sudo password from `pass` over a pipe. Primarily intended to give an agent the ability to run some superuser commands on a remote server once, with prior approval, and not without
- `repos_checker.sh`: script to find all of the Git repositories in the current directory & its sub-directories and display each found repository's `git status`.
- `screenshot.sh`: screenshot script for both Xorg and Wayland with selection that both saves the image file and adds the image to the clipboard, and notifies the user via `notify-send`.
- `stdin_to_notis.sh`: scripts that reads from `stdin` and sends each line as a system notification. Intended for use when a program that outputs to `stdout` is called from a non-terminal or graphical program, making the `stdout` output inaccessible. The output can instead be piped into this script to make it readable as a system notification.
- `stopwatch.sh`: simple stopwatch script that counts the elapsed time in seconds, and displays it in the format HH:MM:SS.
- `shuffle_music.sh`: script to enqueue all the music in a library in a random order.
- `sync_music.sh`: script to sync my Android phone's music library to the contents of my `~/media/music/` directory, i.e. copy my music library from my laptop to my phone.
- `vimshot.sh`: script to take a wait a few seconds before taking a screenshot to the filepath in the clipboard, for use as part of my LaTeX note-taking workflow in Vim: create the figure environment, copy the file name, invoke this script, and select the region in the source material to be screenshotted.
- `webcam.sh`: one-line script that uses the video viewer program `mpv` as a webcam by using `/dev/video0` as its video file source.
- `wifi_dmenu.sh`: script to connect to an available WiFi network with a dmenu prompt of the screenshot via `notify-send`.
