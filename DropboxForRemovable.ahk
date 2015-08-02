; ----------------------------------------------------------------------------------------------------------------------
; Name .........: DropboxForRemovable
; Description ..: Dropbox helper that controls the process according to the presence of a specific removable drive.
; AHK Version ..: AHK_L 1.1.13.01 x32/64 Unicode
; Author .......: Cyruz - http://ciroprincipe.info
; ..............: Entypo icon set, made by Daniel Bruce: http://danielbruce.se/.
; Changelog ....: Dic. 27, 2013 - v0.1   - First revision.
; ..............: Jan. 02, 2014 - v0.2   - Changed behaviour, keep monitoring Dropbox in the long run.
; ..............: Jul. 21, 2014 - v0.3   - Removed monitoring and management of the Dropbox process. Now using polling
; ..............:                          to get the handle. Autostart through Task Scheduler. Uninstallation feature.
; ..............: Jul. 22, 2014 - v0.3.1 - Tracking of the Dropbox process to limit polling only when it's not running.
; ..............: Aug. 01, 2015 - v0.4   - New icons. Rewrite of the icons and task scheduler code.
; License ......: GNU Lesser General Public License
; ..............: This program is free software: you can redistribute it and/or modify it under the terms of the GNU
; ..............: Lesser General Public License as published by the Free Software Foundation, either version 3 of the
; ..............: License, or (at your option) any later version.
; ..............: This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even
; ..............: the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU Lesser 
; ..............: General Public License for more details.
; ..............: You should have received a copy of the GNU Lesser General Public License along with this program. If 
; ..............: not, see <http://www.gnu.org/licenses/>.
; ----------------------------------------------------------------------------------------------------------------------

#SingleInstance force
#Include <Auth>
#Include <Process>
#Include <UpdRes>
#Include <BinGet>
#Include <TrayIcon>

; ===[ VARIABLES ]======================================================================================================
  DROPBOX_EXE     := "Dropbox.exe"
  SCRIPT_NAME     := "DropboxForRemovable"
  SCRIPT_VERSION  := "0.4.0"
  SCRIPT_ICON     := "RES\ICON.ICO"         ; Main icon.
  SCRIPT_ICON_WHI := "RES\ICON_WHITE.ICO"   ; Dropbox running tray icon.
  SCRIPT_ICON_RED := "RES\ICON_RED.ICO"     ; Dropbox suspended tray icon.
  SCRIPT_ICON_YEL := "RES\ICON_YELLOW.ICO"  ; Dropbox not running tray icon.
  SCRIPT_VOL_FLAG := SCRIPT_NAME
  SCRIPT_SEC_WAIT := 2000
  SCRIPT_ABOUT    := SCRIPT_NAME " - Removable drives Dropbox helper - v." SCRIPT_VERSION "`n"
                  . "Created by Ciro Principe: http://ciroprincipe.info`n"
                  . "License under the terms of the GNU LGPL"
; ======================================================================================================================

; Get icon handles.
If ( A_IsCompiled )
{
    pDataIcon    := UpdRes_LockResource( 0, SCRIPT_ICON,     10, szDataIcon:=""    )
    pDataIconWhi := UpdRes_LockResource( 0, SCRIPT_ICON_WHI, 10, szDataIconWhi:="" )
    pDataIconRed := UpdRes_LockResource( 0, SCRIPT_ICON_RED, 10, szDataIconRed:="" )
    pDataIconYel := UpdRes_LockResource( 0, SCRIPT_ICON_YEL, 10, szDataIconYel:="" )
}
Else
{   ; We make the tray icon work also when running this script with the interpreter.
    FileRead, cDataIcon,    % "*c " A_ScriptDir "\" SCRIPT_ICON
    FileRead, cDataIconWhi, % "*c " A_ScriptDir "\" SCRIPT_ICON_WHI
    FileRead, cDataIconRed, % "*c " A_ScriptDir "\" SCRIPT_ICON_RED
    FileRead, cDataIconYel, % "*c " A_ScriptDir "\" SCRIPT_ICON_YEL
    pDataIcon    := &cDataIcon,    pDataIconWhi := &cDataIconWhi
  , pDataIconRed := &cDataIconRed, pDataIconYel := &cDataIconYel
}
SCRIPT_HICO     := BinGet_Icon( pDataIcon,    48 )
SCRIPT_HICO_WHI := BinGet_Icon( pDataIconWhi, 16 )
SCRIPT_HICO_RED := BinGet_Icon( pDataIconRed, 16 )
SCRIPT_HICO_YEL := BinGet_Icon( pDataIconYel, 16 )
cDataIconWht := cDataIconRed := cDataIconYel := "" ; Free buffers.

; Remove tray menu, set traytip and script icon on startup.
; * Notice that the traytip setting must precede the icon
; * changing because it will restore the original one.
Menu, Tray, NoStandard
Menu, Tray, Tip, %SCRIPT_NAME%
TrayIcon_Set( A_ScriptHwnd, 1028, SCRIPT_HICO_WHI, SCRIPT_HICO_WHI, SCRIPT_HICO )

; Connect to the Task Scheduler and get the root folder.
objServ := ComObjCreate( "Schedule.Service" )
objServ.Connect(), objFold := objServ.GetFolder( "\" )

try ; * Check if the task exists, otherwise configure the software.
    ; * The following method throws an exception in case of errors.
    objFold.GetTask( "\" SCRIPT_NAME )
catch
{
    If ( !A_IsAdmin )
        Auth_RunAsAdmin()
    GoSub, SHOWCONFIG
    Return
}

; Exit if it is not started from the Task Scheduler.
nParIfn := Process_GetImageFileName( Process_GetParentPid( DllCall( "GetCurrentProcessId" ) ) )
If ( !InStr( nParIfn, "taskeng.exe" ) )
{
    MsgBox, 0x10, %SCRIPT_NAME%, DropboxForRemovable must be started from the appropriate scheduled task!
    ExitApp
}

; Configure Tray menu.
Menu, Tray, Add, About, ABOUT
Menu, Tray, Add, Uninstall, UNINSTALL
Menu, Tray, Add
Menu, Tray, Add, Quit, EXIT

; The volume to be monitored is passed as parameter by the Task Scheduler.
VOL_TO_MONITOR = %1%

; Check volume presence.
IS_VOL_READY := ( FileExist( VOL_TO_MONITOR ":\" SCRIPT_VOL_FLAG ) ) ? 1 : 0

; Monitor WM_DEVICECHANGE (0x0219) to catch device plugging and unplugging.
OnMessage( 0x0219, "VolumeHandler" )

; Register callback to wait for Dropbox.
aCallback := RegisterCallback( "TermNotifier", "Fast" )

; Set timer to check for the Dropbox process.
SetTimer, WAITDROPBOX, %SCRIPT_SEC_WAIT%

Return

; ======================================================================================================================
; ===[ LABELS ]=========================================================================================================
; ======================================================================================================================

ABOUT:
    MsgBox, 0x40, %SCRIPT_NAME%, %SCRIPT_ABOUT%
    Return
;ABOUT

WAITDROPBOX:
    ; * If the Dropbox process is found running, a thread will be started to wait for its termination.
    ; * This label is called only as a timer, so it will be shut off. If the monitored drive has been 
    ; * unplugged during the time that Dropbox was not running, Dropbox will be suspended when it will
    ; * be catched. This strictly depends from the frequency of the polling.
    Critical
    Process, Exist, %DROPBOX_EXE%
    If ( ErrorLevel )
    {
        ; Get a handle to the Dropbox process and wait for its termination.
        ; PROCESS_ALL_ACCESS = 0x0001F0FFF.
        hDropbox := DllCall( "OpenProcess", UInt,0x0001F0FFF, Int,0, Ptr,ErrorLevel )
        ; INFINITE = 0xFFFFFFFF, WT_EXECUTEONLYONCE = 0x00000008.
        DllCall( "RegisterWaitForSingleObject", PtrP,hWait, Ptr,hDropbox, Ptr,aCallback
                                              , Ptr,0, UInt,0xFFFFFFFF, UInt,0x00000008 )
        DllCall( "CloseHandle", Ptr,hDropbox )
        
        ; Update Dropbox tray info object.
        While ( !IsObject( DROPBOX_TRAY_OBJ := TrayIcon_GetInfo( DROPBOX_EXE ) ) )
            Sleep, 1000 ; This while/sleep is required because Dropbox tray isn't updated quickly.
            
        If ( !IS_VOL_READY )
            DropboxToggle( 0, "Dropbox found and suspended..." )
        Else
        {
            TrayIcon_Set( A_ScriptHwnd, 1028, SCRIPT_HICO_WHI )
            TrayTip, %SCRIPT_NAME%, Dropbox found..., 10, 1
        }
        
        IS_DROPBOX_RUNNING := 1
        SetTimer, %A_ThisLabel%, Off
    }
    Return
;WAITDROPBOX

CONFIGURE:
    Gui, +OwnDialogs
    Gui, Submit, NoHide
    If ( !DDLIST_1 )
    {
        MsgBox, 0x10, %SCRIPT_NAME%, No volume selected.
        Return
    }
    
    ; Get the volume label and create the flag file inside it.
    VOL_TO_MONITOR := DDLIST_1
    FileAppend,, %VOL_TO_MONITOR%:\%SCRIPT_VOL_FLAG%
    FileSetAttrib, +RSH, %VOL_TO_MONITOR%:\%SCRIPT_VOL_FLAG%
    
    ; Create a new task definition object.
    objTask := objServ.NewTask( 0 )
    ; Get the RegistrationInfo object to change task information.
    objInfo := objTask.RegistrationInfo
    objInfo.Description := "DropboxForRemovable starter task"
    objInfo.Author := A_UserName
    
    ; Get the Principal object to change credential related information.
    objPrin := objTask.Principal
    objPrin.LogonType := 3 ; TASK_LOGON_INTERACTIVE_TOKEN
    objPrin.RunLevel  := 1 ; TASK_RUNLEVEL_HIGHEST
    
    ; Get the TaskSettings object to change all task settings.
    objSett := objTask.Settings
    objSett.Enabled := 1                     ; Enable the task.
    objSett.DisallowStartIfOnBatteries := 0  ; Unflag "Start the task only if the computer is on AC power".
    objSett.StopIfGoingOnBatteries := 0      ; Unflag "Stop if the computer switches to battery power".
    objSett.AllowDemandStart := 1            ; Allow task to be run on demand.
    objSett.StartWhenAvailable := 1          ; Run the task as soon as possible after a scheduled start is missed.
    objSett.RestartInterval := "PT1M"        ; If the task fails, restart every 1 minutes.
    objSett.RestartCount := 3                ; Attempt to restart up to 3 times.
    objSett.ExecutionTimeLimit := "PT0S"     ; Stop the task if it runs longer than 1 hour.
    
    ; Get the Trigger object to add a trigger to the task.
    colTrig := objTask.Triggers
    objTrig := colTrig.Create(9) ; Logon type trigger = 2
    objTrig.Enabled := 1         ; Enable the trigger.
    
    ; Get the Action object to add an action to the task.
    colActi := objTask.Actions
    objActi := colActi.Create(0) ; TASK_ACTION_EXEC
    objActi.Path := ( A_IsCompiled ) ? """" A_ScriptFullPath """" : """" A_AhkPath """"
    objActi.Arguments := ( A_IsCompiled ) ? VOL_TO_MONITOR : """" A_ScriptFullPath """ " VOL_TO_MONITOR
    
    ; Register the task. TASK_CREATE_OR_UPDATE = 6, TASK_LOGON_INTERACTIVE_TOKEN = 3
    objFold.RegisterTaskDefinition( SCRIPT_NAME, objTask, 6, "", "", 3 )
    
    MsgBox, 0x40, %SCRIPT_NAME%, Task configured. Starting it...
    objTask := objFold.GetTask( "\" SCRIPT_NAME )
    objTask.Run( 0 )
    
    ExitApp
;CONFIG

DUMMY:
    FileInstall, RES\ICON.ICO, DUMMY
    FileInstall, RES\ICON_WHITE.ICO, DUMMY
    FileInstall, RES\ICON_RED.ICO, DUMMY
    FileInstall, RES\ICON_YELLOW.ICO, DUMMY
;DUMMY

EXIT:
    Gui, +OwnDialogs ; Avoid showing the AutoHotkey icon on the taskbar.
    MsgBox, 0x24, %SCRIPT_NAME%, Are you sure you want to quit?
    IfMsgBox, No
        Return
    ; Unregister the waiting thread and stop the task.
    DllCall( "UnregisterWait", Ptr,hWait )
    objTask.Stop( 0 )
GUICLOSE:
    ExitApp
;GUICLOSE
;EXIT

NOTIFYDROPBOX:
    TrayIcon_Set( A_ScriptHwnd, 1028, SCRIPT_HICO_YEL )
    TrayTip, %SCRIPT_NAME%, Dropbox terminated. Waiting for it..., 10, 1
    IS_DROPBOX_RUNNING := 0
    SetTimer, WAITDROPBOX, %SCRIPT_SEC_WAIT%
    Return
;NOTIFYDROPBOX

REFRESH:
    DriveGet, sDrive, List, REMOVABLE
    sDriveList := RegExReplace( sDrive, "([\w])(?=[\w])", "$1|" )
    GuiControl,, DDLIST_1, |%sDriveList%
    Return
;REFRESH

SHOWCONFIG:
    DriveGet, sDrive, List, REMOVABLE
    sDriveList := RegExReplace( sDrive, "([\w])(?=[\w])", "$1|" )
    
    Gui, +HwndhGui
    Gui, Margin, 20, 20
    Gui, Add, Text,                              w120,             Volume to monitor:
    Gui, Add, DropDownList, vDDLIST_1            w250        y+10, %sDriveList%
    Gui, Add, Button,       vBUTTON_1 gREFRESH   w80  x+5,         Refresh
    Gui, Add, Button,       vBUTTON_3 gCONFIGURE w80  x+-165 y+20, Configure
    Gui, Add, Button,       vBUTTON_4 gGUICLOSE  w80  x+5,         Exit
    Gui, Show, AutoSize, %SCRIPT_NAME%
    
    SendMessage, 0x80, 0, SCRIPT_HICO,, ahk_id %hGui%
    SendMessage, 0x80, 1, SCRIPT_HICO,, ahk_id %hGui%
    Return
;SHOWCONFIG

UNINSTALL:
    Gui, +OwnDialogs ; Avoid showing the AutoHotkey icon on the taskbar.
    MsgBox, 0x24, %SCRIPT_NAME%, Are you sure you want to uninstall?
    IfMsgBox, No
        Return
    
    ; Unregister the waiting thread, stop the task and delete it.
    DllCall( "UnregisterWait", Ptr,hWait )
    objTask.Stop( 0 )
    objFold.DeleteTask( "\" SCRIPT_NAME, 0 )
    
    MsgBox, 0x40, %SCRIPT_NAME%, Uninstalled!
    ExitApp
;UNINSTALL

; ======================================================================================================================
; ===[ FUNCTIONS ]======================================================================================================
; ======================================================================================================================

DropboxToggle(bStatus, sMsg)
{
    Global SCRIPT_NAME, SCRIPT_HICO_WHI, SCRIPT_HICO_RED, DROPBOX_EXE, DROPBOX_TRAY_OBJ
    
    Process, Exist, %DROPBOX_EXE%
    If ( !ErrorLevel )
        Return
        
    hDropbox := DllCall( "OpenProcess", UInt,0x0001F0FFF, Int,0, Ptr,ErrorLevel )
    DllCall( "ntdll.dll\Nt" ( bStatus ? "Resume" : "Suspend" ) "Process", Ptr,hDropbox )
    DllCall( "CloseHandle", Ptr,hDropbox )
    
    TrayIcon_Hide( DROPBOX_TRAY_OBJ[1].idcmd, DROPBOX_TRAY_OBJ[1].place, !bStatus )
    TrayIcon_Set( A_ScriptHwnd, 1028, ( bStatus ? SCRIPT_HICO_WHI : SCRIPT_HICO_RED ) )
    TrayTip, %SCRIPT_NAME%, %sMsg%, 10, 1
}

TermNotifier()
{ 
    ; * Get notified of Dropbox termination and give back control 
    ; * to the primary thread to wait for the new Dropbox process.
    SetTimer, NOTIFYDROPBOX, -1
    Return
}

VolumeHandler(wParam, lParam, uMsg, hWnd)
{
    Critical
    Global IS_DROPBOX_RUNNING, IS_VOL_READY, VOL_TO_MONITOR, SCRIPT_VOL_FLAG, DROPBOX_TRAY_OBJ
    ; * It's better to wait for DBT_DEVNODES_CHANGED (0x0007) events and check if
    ; * the volume is still present, because the DBT_DEVICEREMOVECOMPLETE will not
    ; * be sent when unplugging the device with the "remove device" feature. So we 
    ; * will return quickly if the event is not DBT_DEVNODES_CHANGED.
    If ( wParam != 0x0007 )
        Return
    If ( IS_VOL_READY && !FileExist( VOL_TO_MONITOR ":\" SCRIPT_VOL_FLAG ) )
    {
        If ( IS_DROPBOX_RUNNING )
            DropboxToggle( 0, "Dropbox suspended..." )
        IS_VOL_READY := 0
    }
    Else If ( !IS_VOL_READY && FileExist( VOL_TO_MONITOR ":\" SCRIPT_VOL_FLAG ) )
    {
        If ( IS_DROPBOX_RUNNING )
            DropboxToggle( 1, "Dropbox resumed..." )
        IS_VOL_READY := 1
    }
    Return
}