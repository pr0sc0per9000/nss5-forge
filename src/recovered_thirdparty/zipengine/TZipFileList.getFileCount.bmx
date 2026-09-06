' TZipFileList.getFileCount -- VA 0x0058EA03, 24 bytes   vtable slot 0x34   sig ()i
' byte-identical vs NSS5.exe (24/24, mode=exact, reloc=0)
' The whole body is one virtual call on the FileList field (offset 0xC): TList slot 0x70
' is Count (extracted/vtable_map.tsv line 1072).
Method getFileCount:Int()
	Return FileList.Count()
End Method
