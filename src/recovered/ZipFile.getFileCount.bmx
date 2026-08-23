' ZipFile.getFileCount
' VA 0x0058DD25   40 bytes   vtable slot 0x38   sig ()i
' byte-identical vs NSS5.exe (40/40, original length from Ghidra's inventory)
' 1 absolute-address slot relocation-masked: the `cmp dword[eax+0Ch],005c9c80` Null test.
'
' The container method is TZipFileList.getFileCount (slot 0x34, VA 0x0058EA03), NOT a
' method called `getCount`. Earlier headers on this body recorded that TZipFileList had
' no rows in the reflection data and blamed a harness placeholder gap; that was wrong.
' extracted/vtable_map.tsv lines 2783-2791 and extracted/object_model.json both carry the
' full TZipFileList member set, and harness.py emits it as a real stub with the correct
' slots. The only defect was the invented method name.
' Parameter names are not recoverable from the binary and do not affect codegen.
	Method getFileCount:Int()
		If m_zipFileList <> Null Then Return m_zipFileList.getFileCount()
		Return 0
	End Method
