' Fn_005980CE  --  volumes module Function (BaH.Volumes 1.06 name: GetVolumeInfo)
' VA 0x005980CE   27 bytes   sig ($):TVolume
' THIRD-PARTY MODULE (volumes): BaH.Volumes 1.06, MIT
' byte-identical vs NSS5.exe (27/27, mode=reloc, harness.try_function under NSS5_NO_LEARN=1)
'
' Real name in 1.06 main.bmx: GetVolumeInfo.
' mov eax|edx,[0x00C9ABC0] (volume_driver) and a virtual call through TVolume slot
' 0x40 GetVolumeInfo; nothing else. a0 is `vol` in 1.06.
' Named by VA, not by its 1.06 name: helper_map.orig_functions() names a
' recovered_thirdparty VA after the file stem, and thirdparty_functions() only
' takes dotless stems, so the declared identifier has to be the stem.
' Uses '!Global volume_driver from Fn_00598051.bmx.

Function Fn_005980CE:TVolume(a0:String)
	Return volume_driver.GetVolumeInfo(a0)
End Function
