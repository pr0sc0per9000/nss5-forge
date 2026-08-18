' SZipFileEntry.IsDirectory
' VA 0x0058F51D   50 bytes   vtable slot 0x34
' byte-identical vs NSS5.exe (50/50, original length from Ghidra's inventory)
' byte-identical vs NSS5.exe

	Method IsDirectory:Int()
		Return header.ExternalFileAttributes = 16 And header.DataDescriptor.UncompressedSize = 0
	End Method
