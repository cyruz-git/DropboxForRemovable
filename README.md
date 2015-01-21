# DropboxForRemovable

**PLEASE NOTE THAT THIS IS BETA SOFTWARE. I'M IN NO WAY RESPONSIBLE FOR ANY DATA LOSS.**

*DropboxForRemovable* is a small app that will control the **Dropbox** executable according to the presence of a specific **removable drive**. I created it because Dropbox is not friendly when it comes to syncing removable drives. Mounting the removable drive on a NTFS folder or creating a junction to it is possible to enable the sync, but there is still a big problem to face: Dropbox will think that the files have been deleted if the removable drive is suddenly unplugged.

*DropboxForRemovable* tries to fix this behaviour **freezing** the Dropbox executable when the drive is unplugged, **unfreezing** it when the drive is plugged back again.

The requirements are:

1. A local installation of [Dropbox](https://www.dropbox.com/).

2. A removable drive to synchronize with Dropbox.

### Download

The build archive is [here on GitHub](https://github.com/cyruz-git/DropboxForRemovable/releases).

### How it works

*DropboxForRemovable* creates a configuration for the existing setup, flagging the desired removable drive (that must be plugged in) as the designated one and setting the tool to run on system access through the **task scheduler**.

On next run, *DropboxForRemovable* will start monitoring for drive removal. If the drive is removed, the Dropbox process will be **SUSPENDED** (the app icon will turn red and the Dropbox icon will be hidden). When the drive is plugged back the Dropbox process will be **RESUMED** (the app icon will turn blue and the Dropbox icon will be restored).

### Remarks

Because of the Dropbox client being closed source and not scriptable, this app cannot react to the events in a clean way. In particular, the sync cannot be simply paused/resumed, so the process itself will be suspended/resumed. The Dropbox setup is not changed in any way.

If the Dropbox executable is not running *DropboxForRemovable* will start polling the system in a relaxed way (3 seconds) until it is found running again. If Dropbox is stopped and the drive is unplugged during the polling interval, when Dropbox will be catched again it will be suspended. There is indeed a latency, with the polling frequency as the upper limit.

### Files

Name | Description
-----|------------
docs\ | Folder containing the documentation, built with MkDocs.
COPYING | GNU General Public License.
COPYING.LESSER | GNU Lesser General Public License.
DropboxForRemovable.ahk | Main and only source file.
DropboxForRemovable.ico | Icon file.
LibSetup.ahk | Libraries setup script.
README.md | This document.

### How to compile

*DropboxForRemovable* should be compiled with the **Ahk2Exe** compiler, that can be downloaded from the [AHKscript download page](http://ahkscript.org/download/).

Run the `LibSetup.ahk` script in advance to retrieve the required libraries from GitHub.

Browse to the files so that the fields are filled as follows:

    Source:      path\to\DropboxForRemovable.ahk
    Destination: path\to\DropboxForRemovable.exe
    Custom Icon: path\to\DropboxForRemovable.ico

Select a **Base File** indicating your desired build and click on the **> Convert <** button.

The documentation site is built with [MkDocs](http://www.mkdocs.org/).

### License

*DropboxForRemovable* is released under the terms of the [GNU Lesser General Public License](http://www.gnu.org/licenses/). The tray icons are part of [Kayamoon's IcoMoon set](https://www.iconfinder.com/iconsets/Keyamoon-IcoMoon--limited), so their hex code is relesead under the [CC terms](http://creativecommons.org/licenses/by-sa/3.0/). The DropboxForRemovable executable icon is part of [Ampeross's Perqui set](https://www.iconfinder.com/iconsets/perqui).

### Contact

For hints, bug reports or anything else, you can contact me at [focabresm@gmail.com](mailto:focabresm@gmail.com), open a issue on the dedicated [GitHub repo](https://github.com/cyruz-git/DropboxForRemovable) or use the [AHKscript development thread](http://ahkscript.org/boards/viewtopic.php?f=6&t=1173).