; ----------------------------------------------------------------------------------------------------------------------
; Name .........: DropboxForRemovable
; Description ..: Dropbox helper that checks for a volume presence during Dropbox running.
; AHK Version ..: AHK_L 1.1.13.01 x32/64 Unicode
; Author .......: Cyruz - http://ciroprincipe.info
; ..............: Tray icons from Kayamoon IcoMoon set: https://www.iconfinder.com/iconsets/Keyamoon-IcoMoon--limited
; ..............: The hex icons code is released under CC terms: http://creativecommons.org/licenses/by-sa/3.0/
; Changelog ....: Dic. 27, 2013 - v0.1   - First revision.
; ..............: Jan. 02, 2014 - v0.2   - Changed behaviour, keep monitoring Dropbox in the long run.
; ..............: Jul. 21, 2014 - v0.3   - Removed monitoring and management of the Dropbox process. Now using polling
; ..............:                          to get the handle. Autostart through task scheduler. Uninstallation feature.
; ..............: Jul. 22, 2014 - v0.3.1 - Tracking of the Dropbox process to limit polling only when it's not running.
; License ......: GNU General Public License
; ..............: DropboxForRemovable is free software: you can redistribute it and/or modify it under the terms of the
; ..............: GNU General Public License as published by the Free Software Foundation, either version 3 of the
; ..............: License, or (at your option) any later version.
; ..............: DropboxForRemovable is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
; ..............: without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
; ..............: General Public License for more details.
; ..............: You should have received a copy of the GNU General Public License along with DropboxForRemovable. If
; ..............: not, see <http://www.gnu.org/licenses/>.
; ----------------------------------------------------------------------------------------------------------------------

#SingleInstance force
#Include <IconData>
#Include <TrayIcon>

; ===[ VARIABLES ]======================================================================================================
  DROPBOX_INI_CONF := "DropboxForRemovable.ini"
  DROPBOX_VOL_FLAG := "DropboxForRemovable"
  DROPBOX_SEC_WAIT := 3000
; ======================================================================================================================

; Configure Tray menu.
Menu, Tray, NoStandard
Menu, Tray, Add, About, ABOUT
Menu, Tray, Add, Uninstall, UNINSTALL
Menu, Tray, Add
Menu, Tray, Add, Quit, EXIT
Menu, Tray, Tip, DropboxForRemovable

; Set script icon for the first time.
UpdateScriptIcon(0)

; Configuration starting if the .ini file is not present.
If ( !FileExist(A_ScriptDir "\" DROPBOX_INI_CONF) ) {
    ShellExecute := (A_IsUnicode) ? "Shell32.dll\ShellExecute" : "Shell32.dll\ShellExecuteA"
    If ( !A_IsAdmin ) {
        A_IsCompiled
        ? DllCall( ShellExecute, UInt,0, Str,"RunAs", Str,"""" A_ScriptFullPath """", Ptr,0 , Str,A_WorkingDir, Int,1 )
        : DllCall( ShellExecute, UInt,0, Str,"RunAs", Str,"""" A_AhkPath """", Str,"""" A_ScriptFullPath """"
                               , Str,A_WorkingDir, Int,1 )
        ExitApp
    }
    GoSub, SHOWCONFIG
}
Else {
    ; Exit if it is not started from the Task Scheduler.
    sParam = %1%
    If ( sParam  != "/task" ) {
        MsgBox, 0x10, DropboxForRemovable, DropboxForRemovable must be started from the appropriate scheduled task!
        ExitApp
    }
    
    ; Read and check settings.
    IniRead, S_VOL,            %A_ScriptDir%\%DROPBOX_INI_CONF%, SETTINGS, VOLUME_TO_MONITOR
    IniRead, DROPBOX_SEC_WAIT, %A_ScriptDir%\%DROPBOX_INI_CONF%, SETTINGS, DROPBOX_WAIT_TIMER
    If ( StrLen(S_VOL) != 1 ) {
        MsgBox, 0x10, DropboxForRemovable, Volume not configured correctly!
        ExitApp
    }

    ; Check volume presence.
    B_VOL_READY := (FileExist(S_VOL ":\" DROPBOX_VOL_FLAG)) ? 1 : 0
    
    ; Monitor WM_DEVICECHANGE to catch device plug and unplug.
    OnMessage(0x0219, "VolumeHandler") ; WM_DEVICECHANGE = 0x0219
    
    ; Register callback to wait for Dropbox.
    A_CALLBACK := RegisterCallback("TermNotifier")
    
    ; Set timer to check for the Dropbox process.
    SetTimer, CHECKDROPBOX, %DROPBOX_SEC_WAIT%
}

Return

; ======================================================================================================================
; ===[ LABELS ]=========================================================================================================
; ======================================================================================================================

 CHECKDROPBOX:
    Critical
    Process, Exist, Dropbox.exe
    If ( ErrorLevel ) {
        ; * If the Dropbox process is found running, a thread will be started to wait for 
        ; * its termination. This label is called only as a timer, so it will be shut off.
        H_DROPBOX := DllCall( "OpenProcess", UInt,0x0001F0FFF, Int,0, UInt,ErrorLevel )
        If ( !B_VOL_READY ) {
            ; * If the monitored drive has been unplugged during the time that Dropbox
            ; * was not running, Dropbox will be suspended only when it will be catched.
            ; * This strictly depends from the frequency of the polling.
            DllCall( "ntdll.dll\NtSuspendProcess", Ptr,H_DROPBOX )     ; Suspend Dropbox process.
            OBJ_TRAY := TrayIcon_GetInfo("Dropbox.exe")
            TrayIcon_Hide(OBJ_TRAY[1].idcmd, OBJ_TRAY[1].place, True)  ; Hide Dropbox icon.
            TrayTip, DropboxForRemovable, Dropbox found and suspended..., 10, 1
        } Else
            TrayTip, DropboxForRemovable, Dropbox found..., 10, 1
        DllCall( "RegisterWaitForSingleObject", PtrP,hWait, Ptr,H_DROPBOX, Ptr,A_CALLBACK, Ptr,0, UInt,0xFFFFFFFF
                                              , UInt,0x00000004|0x00000008 )
        B_DROPBOX_RUNNING := 1
        SetTimer, %A_ThisLabel%, Off
    }
    Return
;CHECKDROPBOX

 WAITDROPBOX:
    TrayTip, DropboxForRemovable, Dropbox terminated. Waiting for it..., 10, 1
    B_DROPBOX_RUNNING := 0
    SetTimer, CHECKDROPBOX, %DROPBOX_SEC_WAIT%
    Return
;WAITDROPBOX

 SHOWCONFIG:
    DriveGet, S_DRIVE, List, REMOVABLE
    S_DRIVE_LIST := RegExReplace(S_DRIVE, "([\w])(?=[\w])", "$1|")
    Gui, Margin, 20, 20
    Gui, Add, Text,                              w120,             Volume to monitor:
    Gui, Add, DropDownList, vDDLIST_1            w250        y+10, %S_DRIVE_LIST%
    Gui, Add, Button,       vBUTTON_1 gREFRESH   w80  x+5,         Refresh
    Gui, Add, Button,       vBUTTON_3 gCONFIGURE w80  x+-165 y+20, Configure
    Gui, Add, Button,       vBUTTON_4 gGUICLOSE  w80  x+5,         Exit
    Gui, Show, AutoSize, DropboxForRemovable
    Return
;SHOWCONFIG

 REFRESH:
    DriveGet, S_DRIVE, List, REMOVABLE
    S_DRIVE_LIST := RegExReplace(S_DRIVE, "([\w])(?=[\w])", "$1|")
    GuiControl,, DDLIST_1, |%S_DRIVE_LIST%
    Return
;REFRESH

 CONFIGURE:
    Gui, Submit, NoHide
    If ( !DDLIST_1 ) {
        MsgBox, 0x10, DropboxForRemovable, No volume to monitor selected.
        Return
    }
    IniWrite, %DDLIST_1%,         %A_ScriptDir%\%DROPBOX_INI_CONF%, SETTINGS, VOLUME_TO_MONITOR
    IniWrite, %DROPBOX_SEC_WAIT%, %A_ScriptDir%\%DROPBOX_INI_CONF%, SETTINGS, DROPBOX_WAIT_TIMER
    FileAppend,, %DDLIST_1%:\%DROPBOX_VOL_FLAG%
    FileSetAttrib, +RSH, %DDLIST_1%:\%DROPBOX_VOL_FLAG%
    ; Create a task scheduler item to automatically start the program on boot.
    S_COMMAND  := ( A_IsCompiled ) ? A_ScriptFullPath : A_AhkPath
    S_ARGUMENT := ( A_IsCompiled ) ? "/task" : """" A_ScriptFullPath """ /task"
    FileAppend,
    (
    <?xml version="1.0" encoding="UTF-16"?>
    <Task version="1.2" xmlns="http://schemas.microsoft.com/windows/2004/02/mit/task">
      <RegistrationInfo>
        <Date>%A_YYYY%-%A_MM%-%A_DD%T%A_Hour%:%A_Min%:%A_Sec%.%A_MSec%</Date>
        <Author>%A_ComputerName%\%A_UserName%</Author>
      </RegistrationInfo>
      <Triggers>
        <LogonTrigger>
          <Enabled>true</Enabled>
          <UserId>%A_ComputerName%\%A_UserName%</UserId>
        </LogonTrigger>
      </Triggers>
      <Principals>
        <Principal id="Author">
          <UserId>%A_ComputerName%\%A_UserName%</UserId>
          <LogonType>InteractiveToken</LogonType>
          <RunLevel>HighestAvailable</RunLevel>
        </Principal>
      </Principals>
      <Settings>
        <MultipleInstancesPolicy>IgnoreNew</MultipleInstancesPolicy>
        <DisallowStartIfOnBatteries>false</DisallowStartIfOnBatteries>
        <StopIfGoingOnBatteries>false</StopIfGoingOnBatteries>
        <AllowHardTerminate>false</AllowHardTerminate>
        <StartWhenAvailable>true</StartWhenAvailable>
        <RunOnlyIfNetworkAvailable>false</RunOnlyIfNetworkAvailable>
        <IdleSettings>
          <StopOnIdleEnd>false</StopOnIdleEnd>
          <RestartOnIdle>false</RestartOnIdle>
        </IdleSettings>
        <AllowStartOnDemand>true</AllowStartOnDemand>
        <Enabled>true</Enabled>
        <Hidden>false</Hidden>
        <RunOnlyIfIdle>false</RunOnlyIfIdle>
        <WakeToRun>false</WakeToRun>
        <ExecutionTimeLimit>PT0S</ExecutionTimeLimit>
        <Priority>7</Priority>
        <RestartOnFailure>
          <Interval>PT1M</Interval>
          <Count>3</Count>
        </RestartOnFailure>
      </Settings>
      <Actions Context="Author">
        <Exec>
          <Command>%S_COMMAND%</Command>
          <Arguments>%S_ARGUMENT%</Arguments>
        </Exec>
      </Actions>
    </Task>
    ), temp.xml
    S_CMD := "schtasks /Create /XML """ A_ScriptDir "\temp.xml"" /TN ""DropboxForRemovable"""
    RunWait, % COMSPEC " /c """ S_CMD """",, Hide
    FileDelete, temp.xml
    MsgBox, 0x40, DropboxForRemovable, Task configured. Starting it...
    S_CMD := "schtasks /Run /TN ""DropboxForRemovable"""
    RunWait, % COMSPEC " /c """ S_CMD """",, Hide
    ExitApp
;CONFIG

 UNINSTALL:
    MsgBox, 0x24, DropboxForRemovable, Are you sure you want to uninstall?
    IfMsgBox, No
        Return
    FileDelete, %A_ScriptDir%\%DROPBOX_INI_CONF%
    S_CMD := "schtasks /Delete /TN ""DropboxForRemovable"" /F"
    RunWait, % COMSPEC " /c """ S_CMD """",, Hide
    MsgBox, 0x40, DropboxForRemovable, Uninstalled!
    ExitApp
;UNINSTALL

 ABOUT:
    MsgBox, 0x40, DropboxForRemovable, % "DropboxForRemovable - Removable drives Dropbox helper`n"
                                       . "Created by Ciro Principe: http://ciroprincipe.info`n"
                                       . "License under the terms of the GNU GPL"
    Return
;ABOUT

 EXIT:
    MsgBox, 0x24, DropboxForRemovable, Are you sure you want to quit?
    IfMsgBox, Yes
 GUICLOSE:
    ExitApp
;GUICLOSE
;EXIT

; ======================================================================================================================
; ===[ FUNCTIONS ]======================================================================================================
; ======================================================================================================================

VolumeHandler(wParam, lParam, uMsg, hWnd) {
    Critical
    Global B_VOL_READY, S_VOL, DROPBOX_VOL_FLAG, B_DROPBOX_RUNNING, H_DROPBOX
    ; * It's better to wait for DBT_DEVNODES_CHANGED (0x0007) events and check if
    ; * the volume is still present, because the DBT_DEVICEREMOVECOMPLETE will not
    ; * be sent when unplugging the device with the "remove device" feature. So we 
    ; * will return quickly if the event is not DBT_DEVNODES_CHANGED.
    If ( wParam != 0x0007 )
        Return
    If ( B_VOL_READY && !FileExist(S_VOL ":\" DROPBOX_VOL_FLAG) ) {
        If ( B_DROPBOX_RUNNING ) {
            DllCall( "ntdll.dll\NtSuspendProcess", Ptr,H_DROPBOX )     ; Suspend Dropbox process.
          , OBJ_TRAY := TrayIcon_GetInfo("Dropbox.exe")
          , TrayIcon_Hide(OBJ_TRAY[1].idcmd, OBJ_TRAY[1].place, True)  ; Hide Dropbox icon.
            TrayTip, DropboxForRemovable, Dropbox suspended..., 10, 1
        }
        B_VOL_READY := 0
      , UpdateScriptIcon(1)                                            ; Set script suspended icon.
    }
    Else If ( !B_VOL_READY && FileExist(S_VOL ":\" DROPBOX_VOL_FLAG) ) {
        If ( B_DROPBOX_RUNNING ) {
            DllCall( "ntdll.dll\NtResumeProcess", Ptr,H_DROPBOX )      ; Resume Dropbox process.
          , OBJ_TRAY := TrayIcon_GetInfo("Dropbox.exe")
          , TrayIcon_Hide(OBJ_TRAY[1].idcmd, OBJ_TRAY[1].place, False) ; Unhide Dropbox icon.
            TrayTip, DropboxForRemovable, Dropbox resumed..., 10, 1
        }
        B_VOL_READY := 1
      , UpdateScriptIcon(0)                                            ; Set script normal icon.
    }
    OBJ_TRAY := ""
    Return
}

TermNotifier() { 
    ; * Get notified of Dropbox termination and give back control 
    ; * to the primary thread to wait for the new Dropbox process.
    SetTimer, WAITDROPBOX, -1
    Return
}

UpdateScriptIcon(bSuspended) {
    Static hNormalIcon := IconData_Create(""
    . "0000010001001010000001002000680400001600000028000000100000002000000001002000000000000000000000000000000000000000"
    . "0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000"
    . "0000000000000000000000000000ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff"
    . "ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff"
    . "ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff"
    . "ffffffffff9fffffff9fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff"
    . "ffffffffffffffffff600000000000000000ffffff60ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff"
    . "ffffffffffffffffffefffffff3000000000000000000000000000000000ffffff30ffffffefffffffffffffffffffffffffffffffffffff"
    . "ffffffffffffffffffffffffffafffffff10000000000000000000000000000000000000000000000000ffffff10ffffffcfffffffffffff"
    . "ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff00000000000000000000000000000000ffffffffffffffffffff"
    . "ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff00000000000000000000000000000000ffff"
    . "ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff00000000000000000000"
    . "000000000000ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff"
    . "ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff"
    . "ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff9fffffffffffff"
    . "ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff9f0000"
    . "0000ffffff9fffffffefffffff300000000000000000000000000000000000000000000000000000000000000000ffffff30ffffffefffff"
    . "ff9f000000000000000000000000ffffff9fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff"
    . "ffffffffff9f0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000"
    . "00000000000000000000000000000000000000000000ffffac410000ac410000ac410000ac410180ac4103c0ac4107e0ac4103c0ac4103c0"
    . "ac4103c0ac410000ac410000ac410000ac418ff1ac41c003ac41ffffac4")
    , hSuspendedIcon := IconData_Create(""
    . "0000010001001010000001002000680400001600000028000000100000002000000001002000000000000000000000000000000000000000"
    . "0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000"
    . "00000000000000000000000000000000FFFF0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF0000"
    . "FFFF0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF0000"
    . "FFFF0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF0000"
    . "FFFF0000FF9F0000FF9F0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF0000"
    . "FFFF0000FFFF0000FF6000000000000000000000FF600000FFFF0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF0000"
    . "FFFF0000FFFF0000FFEF0000FF30000000000000000000000000000000000000FF300000FFEF0000FFFF0000FFFF0000FFFF0000FFFF0000"
    . "FFFF0000FFFF0000FFFF0000FFAF0000FF100000000000000000000000000000000000000000000000000000FF100000FFCF0000FFFF0000"
    . "FFFF0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF000000000000000000000000000000000000FFFF0000FFFF0000"
    . "FFFF0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF000000000000000000000000000000000000"
    . "FFFF0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF00000000000000000000"
    . "0000000000000000FFFF0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF0000"
    . "FFFF0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF0000"
    . "FFFF0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF0000FF9F0000FFFF0000"
    . "FFFF0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF0000FF9F0000"
    . "00000000FF9F0000FFEF0000FF3000000000000000000000000000000000000000000000000000000000000000000000FF300000FFEF0000"
    . "FF9F0000000000000000000000000000FF9F0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF0000"
    . "FFFF0000FF9F0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000"
    . "00000000000000000000000000000000000000000000FFFFAC410000AC410000AC410000AC410180AC4103C0AC4107E0AC4103C0AC4103C0"
    . "AC4103C0AC410000AC410000AC410000AC418FF1AC41C003AC41FFFFAC4")
    (bSuspended) ? IconData_Set(hSuspendedIcon) : IconData_Set(hNormalIcon)
}