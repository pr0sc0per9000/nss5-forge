' Fn_0059812E  --  volumes module Function (BaH.Volumes 1.06 name: GetUserDocumentsDir)
' VA 0x0059812E   23 bytes   sig ()$
' THIRD-PARTY MODULE (volumes): BaH.Volumes 1.06, MIT
' byte-identical vs NSS5.exe (23/23, mode=reloc, harness.try_function under NSS5_NO_LEARN=1)
'
' Real name in 1.06 main.bmx: GetUserDocumentsDir.
' mov eax|edx,[0x00C9ABC0] (volume_driver) and a virtual call through TVolume slot
' 0x50 GetUserDocumentsDir; nothing else.
' The only forwarder with a caller: the game's module body at 0x004BB6ED
' (src/module_body/tail.bmx calls SHGetFolderPathW in its place today).
' Named by VA, not by its 1.06 name: helper_map.orig_functions() names a
' recovered_thirdparty VA after the file stem, and thirdparty_functions() only
' takes dotless stems, so the declared identifier has to be the stem.
' Uses '!Global volume_driver from Fn_00598051.bmx.

Function Fn_0059812E:String()
	Return volume_driver.GetUserDocumentsDir()
End Function
