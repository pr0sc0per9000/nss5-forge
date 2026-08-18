' TProfile.OfferSponsorship
' VA 0x0056C158   527 bytes  mode=reloc  byte-identical vs NSS5.exe (527/527, length from Ghidra)
' KIND=Method (implicit Self at [ebp+8]), SIG (i)i, class-table slot 0x128
' ASSUMPTIONS
'  * No module Globals are touched.
'  * Class-table slots: 0x00C61CC0 = TScreen+0x94 DoMessage ($,i,i)i;
'    0x00C68224 = TScreen_Finances+0x34 SetUpScreen ()i.
'    Own-Type virtual slots: 0xF4 GetLifestyle, 0xF8 GetFame, 0x150 CheckAchievement.
'  * String literals read out of NSS5.exe with harness.read_string; the oracle masks a
'    literal's ADDRESS, so their contents are not certified by the MATCH.
'
' CODEGEN NOTES (each byte-observable)
'  * The money expression is FOUR statements, not one. A single expression makes bcc
'    accumulate straight into the destination register (`mov ebx,esi / imul ebx,ebx,K`)
'    and pre-cache Self for both calls; the original's `mov eax,edi / imul eax,eax,K /
'    mov esi,eax` then three `add esi,eax` is the accumulate-with-:+ shape, and it is also
'    what puts a0 in edi and cash in esi rather than the other way round.
'  * The last `:+` mixes types: cash is Int and the RHS is Float, so bcc round-trips
'    through [ebp-8] (fild scratch) and [ebp-4] (float temp) -- that is the whole of
'    `sub esp,8`, there is no Float Local in the source.
'  * The four accept messages are a `Select` with a `Default`, not If/ElseIf: the three
'    `cmp/je` are consecutive and every target is past the last compare (section 10.2).
'  * The sponsorship term is 364 days, not 365 (`add ecx,0x16C`).

	Method OfferSponsorship:Int(a0:Int)
		Local cash:Int = a0 * 15000
		cash :+ Self.relationsponsors * 2500
		cash :+ Self.GetLifestyle() * 1500
		cash :+ Self.GetFame() * 1500.0
		Local s:String = GetText("CMESSAGE_SPONSOROFFER")
		s = s.Replace("$sponsor", Lower(SponsorName(a0)))
		s = s.Replace("$cash", FormatMoney(cash, 0))
		If TScreen.DoMessage(s, 1, 0)
			Self.sponsor_amount[a0 - 1] = cash
			Self.sponsor_expires[a0 - 1] = Self.date.sdate + 364
			Select a0
			Case 1
				TScreen.DoMessage(GetText("CMESSAGE_SPONSORSHIPACCEPTBOOTS"), 0, 0)
			Case 2
				TScreen.DoMessage(GetText("CMESSAGE_SPONSORSHIPACCEPTDRINK"), 0, 0)
			Case 3
				TScreen.DoMessage(GetText("CMESSAGE_SPONSORSHIPACCEPTSHINPADS"), 0, 0)
			Default
				TScreen.DoMessage(GetText("CMESSAGE_SPONSORSHIPACCEPT"), 0, 0)
			End Select
			If Self.relationsponsors = 0
				Self.relationsponsors = 50
			End If
			Self.CheckAchievement(52)
			Local count:Int = 0
			For Local i:Int = 0 To 8
				If Self.sponsor_amount[i] > 0
					count :+ 1
				End If
			Next
			If count = 9
				Self.CheckAchievement(53)
			End If
			TScreen_Finances.SetUpScreen()
		End If
	End Method
