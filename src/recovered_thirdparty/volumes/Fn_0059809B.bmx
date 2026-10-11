' Fn_0059809B  --  volumes module Function (BaH.Volumes 1.06 name: GetVolumeSize)
' VA 0x0059809B   51 bytes   sig ($)l
' THIRD-PARTY MODULE (volumes): BaH.Volumes 1.06, MIT
' byte-identical vs NSS5.exe (51/51, mode=reloc, harness.try_function under NSS5_NO_LEARN=1)
'
' Real name in 1.06 main.bmx: GetVolumeSize.
' mov eax|edx,[0x00C9ABC0] (volume_driver) and a virtual call through TVolume slot
' 0x3C GetVolumeSize; nothing else. a0 is `vol` in 1.06.
' Long return: hidden result pointer at [ebp+8] (ebx), vol at [ebp+0xC], callee
' writes [ebp-8]/[ebp-4] and the pair is copied out after the jmp.
' Named by VA, not by its 1.06 name: helper_map.orig_functions() names a
' recovered_thirdparty VA after the file stem, and thirdparty_functions() only
' takes dotless stems, so the declared identifier has to be the stem.
' Uses '!Global volume_driver from Fn_00598051.bmx.

Function Fn_0059809B:Long(a0:String)
	Return volume_driver.GetVolumeSize(a0)
End Function
