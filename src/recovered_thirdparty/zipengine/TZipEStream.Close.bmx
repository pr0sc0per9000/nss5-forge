' TZipEStream.Close -- VA 0x0058FA9B, 70 bytes   vtable slot 0x44   sig ()i
' byte-identical vs NSS5.exe (70/70, mode=reloc, 3 absolute-address slots masked)
' ZipReader slot 0x58 is CloseZip. Everything after it is the ordinary object-field
' release sequence for `reader = Null`, not source-level code.
	Method Close:Int()
		If reader <> Null
			reader.CloseZip()
			reader = Null
		EndIf
	End Method
