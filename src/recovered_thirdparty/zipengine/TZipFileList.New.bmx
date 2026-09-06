' TZipFileList.New -- VA 0x0058E8D1, 110 bytes   vtable slot 0x10   sig ()i
' byte-identical vs NSS5.exe (110/110, mode=reloc, 7 absolute-address slots masked --
' the class tables for TZipFileList and TList and the Null object)
' zipFile (offset 8) and FileList (0xC) get the usual Null-object init, IgnoreCase (0x10)
' and IgnorePaths (0x14) zero, then FileList is replaced by a fresh TList: the
' push 0xCB0824 / call bbObjectNew pair at 0x0058E90C.
Method New()
	FileList = New TList
End Method
