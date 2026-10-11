' ZipReader.CloseZip
' VA 0x0058E7BF   66 bytes   vtable slot 0x58   sig ()i
' THIRD-PARTY MODULE (zipengine). Calls minizip 1.01e through extern/minizip.
' byte-identical vs NSS5.exe (66/66, mode=reloc, harness.try_method under NSS5_NO_LEARN=1)
'
' 0x00403020 is unzClose (result discarded). There is NO unzCloseCurrentFile call: the
' only callee in the If is unzClose. m_zipFile cleared at 0x0058E7D7, then setName("")
' (slot 0x3C, literal 0x00C95BE8) and clearFileList() (slot 0x34). Implicit Return 0.
' Same shape as ZipWriter.CloseZip minus the comment argument.
'!Import "<repo>/extern/minizip/minizip.bmx"
	Method CloseZip:Int()
		If m_zipFile
			unzClose(m_zipFile)
			m_zipFile = Null
		EndIf
		setName("")
		clearFileList()
	End Method
