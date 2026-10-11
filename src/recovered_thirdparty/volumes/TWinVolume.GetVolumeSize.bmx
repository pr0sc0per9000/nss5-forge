' TWinVolume.GetVolumeSize
' VA 0x005986BC   53 bytes   vtable slot 0x3C   sig ($)l
' THIRD-PARTY MODULE (volumes): BaH.Volumes 1.06, MIT
' byte-identical vs NSS5.exe (53/53, mode=reloc, harness.try_method under NSS5_NO_LEARN=1)
' Parameter names: a0.. as the harness emits them (1.06 source name in the note)
'
' a0 is `vol`. Same as GetVolumeFreeSpace but returns tb (+0x18/+0x1C).
	Method GetVolumeSize:Long(a0:String)

		Local _vs:TVolSpace = TVolSpace.GetDiskSpace(a0)

		Return _vs.tb
	End Method
