' TZipFileList.Delete
' VA 0x0058E93F   53 bytes   vtable slot 0x14   sig ()i
' THIRD-PARTY MODULE (zipengine). Calls minizip 1.01e through extern/minizip.
' byte-identical vs NSS5.exe (53/53, mode=reloc, harness.try_method under NSS5_NO_LEARN=1)
'
' Nothing but the compiler's field release: FileList (+0xC) then zipFile (+0x8), each a
' dec [obj+4] / jne / bbGCFree, then mov eax,0. The 53 bytes are identical, rel32 aside,
' to the already-MATCHed empty ZipFile.Delete at 0x0058DC2B (both are in the
' __brl_max2d_TImageFont_Delete alias row of brl_functions.tsv).
'!Import "<repo>/extern/minizip/minizip.bmx"
	Method Delete()

	End Method
