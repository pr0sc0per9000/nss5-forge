' ZipWriter.OpenZip
' VA 0x0058DE13   147 bytes   vtable slot 0x4C   sig ($,i)i
' THIRD-PARTY MODULE (zipengine). Calls minizip 1.01e through extern/minizip.
' byte-identical vs NSS5.exe (147/147, mode=reloc, harness.try_method under NSS5_NO_LEARN=1)
' Parameter names are UNCERTAIN (not recoverable from the binary); a0.. as emitted
'
' a1 is minizip's append mode, folded to two constants: a1<>0 -> zipOpen(a0, 2)
' (APPEND_STATUS_ADDINZIP, 0x0058DE31), else zipOpen(a0, 0) (APPEND_STATUS_CREATE,
' 0x0058DE59). Each arm is a ToCString/MemFree pair around the call, the `$z` shape. Both
' arms store to m_zipFile (+0x10); the then-arm ends `jmp 0x0058DE72`, so a real If/Else.
' 0x00403C90 is zipOpen. Slot 0x3C is ZipFile.setName, 0x30 readFileList. The single
' trailing `mov eax,0` at 0x0058DE98 is the failure return (TCombo.GetSelectedText shows
' an If/Else that returns in both arms compiles to the same layout, so either spelling).
'!Import "<repo>/extern/minizip/minizip.bmx"
	Method OpenZip:Int(a0:String, a1:Int)
		If a1
			m_zipFile = zipOpen(a0, 2)
		Else
			m_zipFile = zipOpen(a0, 0)
		EndIf
		If m_zipFile
			setName(a0)
			readFileList()
			Return True
		EndIf
		Return False
	End Method
