' Fn_00598051  --  volumes module Function (BaH.Volumes 1.06 name: ListVolumes)
' VA 0x00598051   23 bytes   sig ():brl.linkedlist.TList
' THIRD-PARTY MODULE (volumes): BaH.Volumes 1.06, MIT
' byte-identical vs NSS5.exe (23/23, mode=reloc, harness.try_function under NSS5_NO_LEARN=1)
'
' Real name in 1.06 main.bmx: ListVolumes.
' mov eax|edx,[0x00C9ABC0] (volume_driver) and a virtual call through TVolume slot
' 0x34 ListVolumes; nothing else.
' brl_functions.tsv also lists this VA as _maxgui_maxgui_ComputerName (same
' 23-byte driver-forwarder shape). Harmless: no caller (brute E8 scan).
' Named by VA, not by its 1.06 name: helper_map.orig_functions() names a
' recovered_thirdparty VA after the file stem, and thirdparty_functions() only
' takes dotless stems, so the declared identifier has to be the stem.
'
' SHARED DECLARATIONS FOR THE WHOLE volumes/ TREE. Every pragma below is lifted to module
' scope by harness.thirdparty_functions() into EVERY probe and by assemble.py into
' nss5_external.bmx, which is how the Type-member bodies here see them (the harness emits
' no Type Consts and no Extern of its own). Do not delete one because this body does not
' use it: users are listed per line.
'   Globals: volume_driver 0x00C9ABC0 (main.bmx; written by TWinVolumeDriver.New, read by
'   the 9 forwarders); winVolume_driver 0x00C9AFF0 (vol_win.bmx). NO initialiser on
'   winVolume_driver here on purpose: `= New TWinVolumeDriver` is non-constant, would take
'   an init-guard bit in every probe in the project (harness GLOBALINIT note) and
'   assemble.py drops TP Global initialisers anyway. The real initialiser lives in the
'   vol_win.bmx unit source, where the unit oracle checks it (0x005982E0..0x00598308).
'   Consts: main.bmx DT_* and vol_win.bmx CSIDL_* / SHGFP_TYPE_CURRENT /
'   SEM_FAILCRITICALERRORS verbatim. PATH_MAX is TWinVolume's own Type Const ($104) lifted
'   to module scope; it also stands in for Pub.Win32's MAX_PATH (260, same value) in
'   _getFolderPath, because the probe does not import Pub.Win32.
'   Extern "c" strlen_: verbatim from main.bmx, used by Fn_00598160. cdecl (add esp,4 after
'   the call at 0x00598176); 0x004B4500 is msvcrt strlen (dll_imports.tsv) and masks as
'   "_strlen" on both sides.
'   Extern "win32": verbatim from vol_win.bmx, explicit "@N" aliases as in the source. All
'   nine thunks (0x004A9A10, 0x004A9C00..0x004A9C38) have callers ONLY inside 0x005983DE..
'   0x00598ADB (brute E8 scan), so recording their decorated names cannot move any other
'   verdict. The End Extern lines carry distinct trailing comments because assemble.py's
'   tp_lines dedupe keys '!Raw lines on their stripped text and would otherwise drop the
'   second `End Extern` from nss5_external.bmx.
'!Global volume_driver:TVolume
'!Raw Const DT_SHAREDUSERDATA:Int = $0001
'!Raw Const DT_USERPICTURES:Int = $0002
'!Raw Const DT_USERMUSIC:Int = $0003
'!Raw Const DT_USERMOVIES:Int = $0004
'!Raw Const CSIDL_APPDATA:Int = $001A
'!Raw Const CSIDL_DESKTOPDIRECTORY:Int = $0010
'!Raw Const CSIDL_PERSONAL:Int = $0005
'!Raw Const CSIDL_PROFILE:Int = $0028
'!Raw Const CSIDL_MYPICTURES:Int = $0027
'!Raw Const CSIDL_MYMUSIC:Int = $000D
'!Raw Const CSIDL_MYVIDEO:Int = $000E
'!Raw Const SHGFP_TYPE_CURRENT:Int = 0
'!Raw Const SEM_FAILCRITICALERRORS:Int = 1
'!Raw Const PATH_MAX:Int = $104
'!Raw Extern "c" ' volumes main.bmx
'!Raw Function strlen_( str:Byte Ptr )="strlen"
'!Raw End Extern ' volumes main.bmx
'!Raw Extern "win32" ' volumes vol_win.bmx
'!Raw Function GetDiskFreeSpaceEx:Int(lpDirectoryName:Short Ptr, lpFreeBytesAvailableToCaller:Long Var, lpTotalNumberOfBytes:Long Var, lpTotalNumberOfFreeBytes:Long Var) = "GetDiskFreeSpaceExW@16"
'!Raw Function GetVolumeInformation:Int(lpRootPathName:Short Ptr, lpVolumeNameBuffer:Short Ptr, nVolumeNameSize:Int, lpVolumeSerialNumber:Int Var, lpMaximumComponentLength:Int Var, lpFileSystemFlags:Int Var, lpFileSystemNameBuffer:Short Ptr, nFileSystemNameSize:Int) = "GetVolumeInformationW@32"
'!Raw Function GetLogicalDrives:Int() = "GetLogicalDrives@0"
'!Raw Function SetErrorMode:Int(mode:Int) = "SetErrorMode@4"
'!Raw Function FindFirstVolume:Int(volumeName:Short Ptr, bufferSize:Int) = "FindFirstVolumeW@8"
'!Raw Function FindNextVolume:Int(handle:Int, volumeName:Short Ptr, bufferSize:Int) = "FindNextVolumeW@12"
'!Raw Function FindVolumeClose:Int(handle:Int) = "FindVolumeClose@4"
'!Raw Function GetVolumePathNamesForVolumeName:Int(volumeName:Short Ptr, volumePaths:Short Ptr, bufferSize:Int, copiedSize:Int Ptr) = "GetVolumePathNamesForVolumeNameW@16"
'!Raw Function SHGetFolderPath:Int(hwndOwner:Byte Ptr, nFolder:Int, hToken:Byte Ptr, dwFlags:Int, pszPath:Short Ptr) = "SHGetFolderPathW@20"
'!Raw End Extern ' volumes vol_win.bmx
Function Fn_00598051:TList()
	Return volume_driver.ListVolumes()
End Function
