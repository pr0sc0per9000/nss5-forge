' Fn_00598100  --  volumes module Function (BaH.Volumes 1.06 name: GetUserDesktopDir)
' VA 0x00598100   23 bytes   sig ()$
' THIRD-PARTY MODULE (volumes): BaH.Volumes 1.06, MIT
' byte-identical vs NSS5.exe (23/23, mode=reloc, harness.try_function under NSS5_NO_LEARN=1)
'
' Real name in 1.06 main.bmx: GetUserDesktopDir.
' mov eax|edx,[0x00C9ABC0] (volume_driver) and a virtual call through TVolume slot
' 0x48 GetUserDesktopDir; nothing else.
' Named by VA, not by its 1.06 name: helper_map.orig_functions() names a
' recovered_thirdparty VA after the file stem, and thirdparty_functions() only
' takes dotless stems, so the declared identifier has to be the stem.
' Uses '!Global volume_driver from Fn_00598051.bmx.

Function Fn_00598100:String()
	Return volume_driver.GetUserDesktopDir()
End Function
