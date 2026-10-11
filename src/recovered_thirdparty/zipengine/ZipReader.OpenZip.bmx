' ZipReader.OpenZip
' VA 0x0058E4CF   103 bytes   vtable slot 0x4C   sig ($)i
' THIRD-PARTY MODULE (zipengine). Calls minizip 1.01e through extern/minizip.
' byte-identical vs NSS5.exe (103/103, mode=reloc, harness.try_method under NSS5_NO_LEARN=1)
' Parameter names are UNCERTAIN (not recoverable from the binary); a0.. as emitted
'
' 0x004022B0 is unzOpen; ToCString/MemFree around it is the `$z` parameter. The result is
' parked in [ebp-4] across the MemFree (ebx holds the C string, esi Self, edi a0), which
' is the allocator's spill for the call value, not a source Local. Stored to m_zipFile
' (+0x10) at 0x0058E501, then the same tail as ZipWriter.OpenZip: setName(a0) slot 0x3C,
' readFileList() slot 0x30, 1 / 0.
'!Import "<repo>/extern/minizip/minizip.bmx"
	Method OpenZip:Int(a0:String)
		m_zipFile = unzOpen(a0)
		If m_zipFile
			setName(a0)
			readFileList()
			Return True
		EndIf
		Return False
	End Method
