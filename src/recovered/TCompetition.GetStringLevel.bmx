' TCompetition.GetStringLevel
' VA 0x0050C97D   67 bytes   vtable slot 0x8C   sig (i)$
' byte-identical vs NSS5.exe (67/67, original length from Ghidra's inventory), harness mode=reloc
' Assumptions:
'   * the three string literals were read out of the .rdata BBString objects the original
'     pushes: 0x00C7CE5C='Club', 0x00C7D048='International', 0x00C7CF74='None'.
'   * GetText is the recovered module Function at 0x004C5549.
' SHAPE (measured): a Select with NO Default, followed by a trailing Return. bcc emits
'   `cmp/je body0; cmp/je body1; jmp fallthrough` for that. The If/ElseIf/Else spelling
'   emits the inline `cmp/jne next` form instead and comes out 2 bytes short (65/67).
	Function GetStringLevel:String(a0:Int)
		Select a0
			Case 0
				Return GetText("Club")
			Case 1
				Return GetText("International")
		End Select
		Return GetText("None")
	End Function
