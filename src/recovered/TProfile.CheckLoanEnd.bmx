' TProfile.CheckLoanEnd
' VA 0x0056cba8   217 bytes   vtable slot 0x13c   sig ()i
' byte-identical vs NSS5.exe (217/217, original length from Ghidra's inventory, mode=reloc)
' Assumptions: TProfile slot 0x58 = GetNextFixture(i):TFixture, 0x144 = CancelLoan().
'   PTR_FUN_00C61CC0 = TScreen classtable + 0x94 = TScreen.DoMessage($,i,i).
'   FUN_004A75B0 = _bbStringReplace (runtime_helpers, 13 witnesses) -> String.Replace.
'   The ElseIf really does re-test transferlisted = 4 -- that is in the original, not a
'   transcription slip; it emits the sete/movzx boolean form because it is an And operand.
	Method CheckLoanEnd:Int()
		If Self.transferlisted = 4
			Local f:TFixture = Self.GetNextFixture(0)
			If Self.date.sdate > Self.loanexpires Or (f <> Null And f.sdate > Self.loanexpires)
				Self.CancelLoan()
			EndIf
		ElseIf Self.transferlisted = 4 And Self.relationboss < 30
			TScreen.DoMessage(GetText("CMESSAGE_LOANENDBOSSUNHAPPY").Replace("$loanclub",Self.myclub.labelname),0,0)
			Self.CancelLoan()
		EndIf
	End Method
