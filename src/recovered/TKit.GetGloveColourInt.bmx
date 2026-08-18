' TKit.GetGloveColourInt
' VA 0x004dc21a   125 bytes   vtable slot 0x64   sig ($)i
' byte-identical vs NSS5.exe (125/125, original length from Ghidra's inventory)
' Select over String compiles to one bbStringCompare per case. The fallback Return is AFTER End Select, not a Default clause.
' Parameter names are not recoverable from the binary; a0/a1/... as emitted by the harness.
	Function GetGloveColourInt:Int(a0:String)
		Select a0
			Case "404040"
				Return 1
			Case "FFFFFF"
				Return 2
			Case "2D00EA"
				Return 3
			Case "EA0005"
				Return 4
		End Select
		Return 1
	End Function
