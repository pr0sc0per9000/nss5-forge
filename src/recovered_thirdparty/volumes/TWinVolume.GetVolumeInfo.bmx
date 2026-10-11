' TWinVolume.GetVolumeInfo
' VA 0x005986F1   379 bytes   vtable slot 0x40   sig ($):TVolume
' THIRD-PARTY MODULE (volumes): BaH.Volumes 1.06, MIT
' byte-identical vs NSS5.exe (379/379, mode=reloc, harness.try_method under NSS5_NO_LEARN=1)
' Parameter names: a0.. as the harness emits them (1.06 source name in the note)
'
' a0 is `vol`. 1.06 source; the `..` continuation joined onto one line (no codegen
' effect). PATH_MAX here was already bare in 1.06 (Type Const; module Const in the
' probe). SetErrorMode(1) kept in [ebp-0x18]; volname [ebp-4], filesys [ebp-0x14],
' snum/maxLength/flags [ebp-8]/[ebp-0xC]/[ebp-0x10] passed as Int Var. volumeDevice
' goes through bbStringToWString/bbMemFree (String -> Short Ptr). 0x004A78D0 is
' bbStringFromWString (String.fromWString), unnamed in every table today: see README.
' Needs the module Consts / Extern / Globals declared as pragmas in Fn_00598051.bmx.
	Method GetVolumeInfo:TVolume(a0:String)
		Local mode:Int = SetErrorMode(SEM_FAILCRITICALERRORS)

		Local volume:TWinVolume = New TWinVolume

		volume.volumeDevice = a0

		Local volname:Short[PATH_MAX]
		Local filesys:Short[PATH_MAX]
		Local snum:Int
		Local maxLength:Int
		Local flags:Int

		Local ret:Int = GetVolumeInformation(volume.volumeDevice, volname, PATH_MAX, snum, maxLength, flags, filesys, PATH_MAX)

		If ret Then
			volume.volumeName = String.fromWString(volname)
			volume.volumeType = String.fromWString(filesys)

			volume.vs = TVolSpace.GetDiskSpace(volume.volumeDevice)
			volume.volumeSize = volume.vs.tb
			volume.volumeFree = volume.vs.fb

			volume.available = True
		End If

		SetErrorMode(mode)

		Return volume
	End Method
