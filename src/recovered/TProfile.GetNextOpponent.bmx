' TProfile.GetNextOpponent
' VA 0x005665F4   312 bytes   vtable slot 0x5C   sig (*i,*i):TBase_Team   KIND=Method
' byte-identical vs NSS5.exe (312/312, mode=reloc, reloc_masked=9)
'
' No module Globals. The two Var-style outputs are Int Ptr in the reflection signature.
'
' CODEGEN NOTE: the first test is `Not natfix`, NOT `natfix = Null`. The original emits
' setne/movzx/cmp/sete/movzx/cmp -- a DOUBLE negation, i.e. truth-of-object then logical
' Not. `natfix = Null` emits a single sete and comes out 9 bytes short (303/312).

	Method GetNextOpponent:TBase_Team(a0:Int Ptr, a1:Int Ptr)
		Local natfix:TFixture = Self.mynation.GetNextFixture(0)
		Local clubfix:TFixture = Self.myclub.GetNextFixture(0)
		If Not natfix Or (clubfix <> Null And clubfix.sdate <= natfix.sdate)
			a1[0] = 0
			If clubfix <> Null
				Local h:Int = clubfix.GetHomeTeamId()
				Local w:Int = clubfix.GetAwayTeamId()
				If h = Self.clubid
					a0[0] = 1
					Return TClub.SelectById(w)
				EndIf
				If w = Self.clubid
					a0[0] = 0
					Return TClub.SelectById(h)
				EndIf
			EndIf
		ElseIf natfix <> Null
			a1[0] = 1
			Local h:Int = natfix.GetHomeTeamId()
			Local w:Int = natfix.GetAwayTeamId()
			If h = Self.nationid
				a0[0] = 1
				Return TNation.SelectById(w)
			EndIf
			If w = Self.nationid
				a0[0] = 0
				Return TNation.SelectById(h)
			EndIf
		EndIf
		Return Null
	End Method
