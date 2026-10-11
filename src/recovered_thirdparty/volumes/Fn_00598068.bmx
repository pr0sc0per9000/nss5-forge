' Fn_00598068  --  volumes module Function (BaH.Volumes 1.06 name: GetVolumeFreeSpace)
' VA 0x00598068   51 bytes   sig ($)l
' THIRD-PARTY MODULE (volumes): BaH.Volumes 1.06, MIT
' byte-identical vs NSS5.exe (51/51, mode=reloc, harness.try_function under NSS5_NO_LEARN=1)
'
' Real name in 1.06 main.bmx: GetVolumeFreeSpace.
' mov eax|edx,[0x00C9ABC0] (volume_driver) and a virtual call through TVolume slot
' 0x38 GetVolumeFreeSpace; nothing else. a0 is `vol` in 1.06.
' Long return: hidden result pointer at [ebp+8] (ebx), vol at [ebp+0xC], callee
' writes [ebp-8]/[ebp-4] and the pair is copied out after the jmp.
' Named by VA, not by its 1.06 name: helper_map.orig_functions() names a
' recovered_thirdparty VA after the file stem, and thirdparty_functions() only
' takes dotless stems, so the declared identifier has to be the stem.
' Uses '!Global volume_driver from Fn_00598051.bmx.

Function Fn_00598068:Long(a0:String)
	Return volume_driver.GetVolumeFreeSpace(a0)
End Function
