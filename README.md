# DropboxForRemovable

**PLEASE NOTE THAT THIS IS BETA SOFTWARE. I'M IN NO WAY RESPONSIBLE FOR ANY DATA LOSS.**

*DropboxForRemovable* is a small app that will control the **Dropbox** executable according to the presence of a specific **removable drive**. I created it because Dropbox is not friendly when it comes to syncing removable drives. Mounting the removable drive on a NTFS folder or creating a junction to it is possible to enable the sync, but there is still a big problem to face: Dropbox will think that the files have been deleted if the removable drive is suddenly unplugged.

*DropboxForRemovable* tries to fix this behaviour **freezing** the Dropbox executable when the drive is unplugged, **unfreezing** it when the drive is plugged back again.

The requirements are:

1. A local installation of [Dropbox](https://www.dropbox.com/).

2. A removable drive to synchronize with Dropbox.

### Download

The build archive is [here on GitHub](https://github.com/cyruz-git/DropboxForRemovable/releases).

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

### Full README available [here](docs/docs/index.md)
