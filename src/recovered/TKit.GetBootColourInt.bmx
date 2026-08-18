' Every string literal in this file was read out of NSS5.exe with
' harness.read_string and checked against the address the ORIGINAL pushes at the
' same code offset. The oracle masks a literal's ADDRESS, so a MATCH never
' certifies the text -- see docs/reference/codegen-patterns.md 13.2.
' TKit.GetBootColourInt
' VA 0x004DC0AE   297 bytes   vtable slot 0x5c   sig ($)i
' byte-identical vs NSS5.exe (297/297, original length from Ghidra's inventory)
' Each of the ten string literals is a pointer into .data that the oracle masks as
' a relocation, so only their COUNT and ORDER are load-bearing to the byte match.
' They are listed in the order the original tests them (literal addresses
' 0x00C6FC70, 0x00C725B8, 0x00C753EC, 0x00C75404, 0x00C7541C, 0x00C72868,
' 0x00C75434, 0x00C6E904, 0x00C725EC, 0x00C5D680). Substituting the real
' strings will not change a single emitted byte.
' Select with NO Default arm, followed by a bare 'Return 1' after End Select --
' a 'Default / Return 1' arm builds 2 bytes long.
	Function GetBootColourInt:Int(a0:String)
		Select a0
			Case "666666"
				Return 1
			Case "FFFF00"
				Return 2
			Case "4BD998"
				Return 3
			Case "9900DE"
				Return 4
			Case "FF9933"
				Return 5
			Case "0000FF"
				Return 6
			Case "00FFFF"
				Return 7
			Case "00FF00"
				Return 8
			Case "FF0000"
				Return 9
			Case "FFFFFF"
				Return 10
		End Select
		Return 1
	End Function
