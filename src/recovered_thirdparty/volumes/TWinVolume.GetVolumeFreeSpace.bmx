' TWinVolume.GetVolumeFreeSpace
' VA 0x00598687   53 bytes   vtable slot 0x38   sig ($)l
' THIRD-PARTY MODULE (volumes): BaH.Volumes 1.06, MIT
' byte-identical vs NSS5.exe (53/53, mode=reloc, harness.try_method under NSS5_NO_LEARN=1)
' Parameter names: a0.. as the harness emits them (1.06 source name in the note)
'
' a0 is `vol`. call [0x00C9AFE4] = TVolSpace class 0x00C9AFB4 + 0x30 (GetDiskSpace),
' returns fb (+0x20/+0x24) through the hidden Long result pointer [ebp+0xC].
	Method GetVolumeFreeSpace:Long(a0:String)

		Local _vs:TVolSpace = TVolSpace.GetDiskSpace(a0)

		Return _vs.fb
	End Method
