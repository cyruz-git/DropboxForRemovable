# DropboxForRemovable

**PLEASE NOTE THAT THIS IS BETA SOFTWARE. I'M IN NO WAY RESPONSIBLE FOR ANY DATA LOSS.**

*DropboxForRemovable* is a small app that controls the **Dropbox** executable according to the presence of a specific **removable drive**. I created it because Dropbox is not friendly when it comes to syncing removable drives. Mounting the removable drive on a NTFS folder or creating a junction to it is possible to enable the sync, but there is still a big problem to face: Dropbox will think that the files have been deleted if the removable drive is suddenly unplugged.

*DropboxForRemovable* tries to fix this behaviour **freezing** the Dropbox executable when the drive is unplugged, **unfreezing** it when the drive is plugged back again.

The requirements are:

1. A local installation of [Dropbox](https://www.dropbox.com/).

2. A removable drive to synchronize with Dropbox.

### How it works

*DropboxForRemovable* creates a configuration for the existing setup, flagging the desired removable drive (that must be plugged in) as the designated one and setting the tool to run on system access through the **task scheduler**.

On next run, *DropboxForRemovable* will start monitoring for drive removal. If the drive is removed, the Dropbox process will be **SUSPENDED** (the app icon will turn red and the Dropbox icon will be hidden). When the drive is plugged back the Dropbox process will be **RESUMED** (the app icon will turn blue and the Dropbox icon will be restored).

### Remarks

Because of the Dropbox client being closed source and not scriptable, this app cannot react to the events in a clean way. In particular, the sync cannot be simply paused/resumed, so the process itself will be suspended/resumed. The Dropbox setup is not changed in any way.

If the Dropbox executable is not running *DropboxForRemovable* will start polling the system in a relaxed way (3 seconds) until it is found running again. If Dropbox is stopped and the drive is unplugged during the polling interval, when Dropbox will be catched again it will be suspended. There is indeed a latency, with the polling frequency as the upper limit.

### Setup and usage

*DropboxForRemovable* assumes that we have a removable drive containing a folder synchronized with Dropbox through a NTFS folder mount. To do this follow this procedure:

1. Run the `diskmgmt.msc` console with `Win+R`.

2. Select the removable drive volume and right click it to select the **"Change Drive Letter and Paths..."** menu.

3. Click on the **Add** button.

4. Select **"Mount in the following empty NTFS folder"** and browse to the desired folder.

5. Acknowledge all the modifications we have done.

6. Sync the desired folder in the **Dropbox Account Preferences**.

Now that we have a working synchronization for our removable drive, we will protect it installing *DropboxForRemovable*:

1. Start *DropboxForRemovable* with Dropbox running and the removable drive plugged in.

2. Select the volume to monitor from the dropdown menu and click **Configure**.

3. A configuration file and the scheduler tasks will be created. A hidden system file flagging the removable drive will be created in its root. *DropboxForRemovable* will be started.

To uninstall *DropboxForRemovable*:

1. Right click on the *DropboxForRemovable* tray icon and select **Uninstall**.

### Configuration file

The configuration file presence tells to the program if it's installed or not. It contains only the following options:

Name | Description
-----|------------
VOLUME_TO_MONITOR | The drive letter of the volume to monitor.
DROPBOX_WAIT_TIMER | The frequency of polling to check for the Dropbox state (in milliseconds, default 3000).

### License

*DropboxForRemovable* is released under the terms of the [GNU Lesser General Public License](http://www.gnu.org/licenses/). The tray icons are part of [Kayamoon's IcoMoon set](https://www.iconfinder.com/iconsets/Keyamoon-IcoMoon--limited), so their hex code is relesead under the [CC terms](http://creativecommons.org/licenses/by-sa/3.0/). The DropboxForRemovable executable icon is part of [Ampeross's Perqui set](https://www.iconfinder.com/iconsets/perqui).

### Contact

For hints, bug reports or anything else, you can contact me at [focabresm@gmail.com](mailto:focabresm@gmail.com), open a issue on the dedicated [GitHub repo](https://github.com/cyruz-git/DropboxForRemovable) or use the [AHKscript development thread](http://ahkscript.org/boards/viewtopic.php?f=6&t=1173).