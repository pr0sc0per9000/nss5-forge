' ZipWriter.CloseZip
' VA 0x0058E42A   92 bytes   vtable slot 0x60   sig ($)i
' THIRD-PARTY MODULE (zipengine). Calls minizip 1.01e through extern/minizip.
' byte-identical vs NSS5.exe (92/92, mode=reloc, harness.try_method under NSS5_NO_LEARN=1)
' Parameter names are UNCERTAIN (not recoverable from the binary); a0.. as emitted
'
' a0 is the archive's global comment. 0x00404A40 is minizip's zipClose(file, comment)
' (its first instruction loads ZIP_PARAMERROR -102); the ToCString/MemFree pair around it
' at 0x0058E43C/0x0058E453 is the `$z` parameter. Result discarded. m_zipFile cleared at
' 0x0058E45B. Then setName("") (slot 0x3C, the empty literal at 0x00C95BE8) and
' clearFileList() (slot 0x34) run unconditionally; no explicit Return (mov eax,0 at
' 0x0058E479 is the implicit one).
'!Import "<repo>/extern/minizip/minizip.bmx"
	Method CloseZip:Int(a0:String)
		If m_zipFile
			zipClose(m_zipFile, a0)
			m_zipFile = Null
		EndIf
		setName("")
		clearFileList()
	End Method
