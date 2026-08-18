' TProfile.GetNextFixture
' VA 0x00566519   219 bytes   vtable slot 0x58   sig (i):TFixture
' byte-identical vs NSS5.exe (219/219, original length from Ghidra's inventory)
' No Globals. TClub.SelectById is TClub+0x60; GetNextFixture on TNation/TClub is the
' inherited TBase_Team slot 0x38. Every Null test here is an operand of And, so it uses
' the setne/movzx form (21 bytes), not the compact cmp/je -- writing them as early
' returns gives 171 bytes instead of 219. Operand order is `Self.date.sdate >
' Self.loanexpires` (setg) and `cf.sdate <= nf.sdate` (cmp [cf+8],eax / jg).
	Method GetNextFixture:TFixture(a0:Int)
		LogLine("GetNextFixture")
		Local nf:TFixture = Self.mynation.GetNextFixture(a0)
		Local cf:TFixture
		If Self.transferlisted = 4 And Self.date.sdate > Self.loanexpires
			cf = TClub.SelectById(Self.onloanfrom).GetNextFixture(a0)
		Else
			cf = Self.myclub.GetNextFixture(a0)
		EndIf
		If cf <> Null And nf <> Null
			If cf.sdate <= nf.sdate Then Return cf
			Return nf
		Else
			If cf <> Null
				Return cf
			Else
				If nf <> Null
					Return nf
				Else
					Return Null
				EndIf
			EndIf
		EndIf
	End Method
