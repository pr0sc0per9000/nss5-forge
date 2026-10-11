' Fn_00598145  --  volumes module Function (BaH.Volumes 1.06 name: GetCustomDir)
' VA 0x00598145   27 bytes   sig (i)$
' THIRD-PARTY MODULE (volumes): BaH.Volumes 1.06, MIT
' byte-identical vs NSS5.exe (27/27, mode=reloc, harness.try_function under NSS5_NO_LEARN=1)
'
' Real name in 1.06 main.bmx: GetCustomDir.
' mov eax|edx,[0x00C9ABC0] (volume_driver) and a virtual call through TVolume slot
' 0x54 GetCustomDir; nothing else. a0 is `dirType` in 1.06.
' Named by VA, not by its 1.06 name: helper_map.orig_functions() names a
' recovered_thirdparty VA after the file stem, and thirdparty_functions() only
' takes dotless stems, so the declared identifier has to be the stem.
' Uses '!Global volume_driver from Fn_00598051.bmx.

Function Fn_00598145:String(a0:Int)
	Return volume_driver.GetCustomDir(a0)
End Function
