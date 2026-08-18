' TProfile.CheckSponsorExpiry  -- KIND=Method, sig ()i, slot 0x124
' VA 0x0056BFE2   374 bytes
' byte-identical vs NSS5.exe (374/374, original length from Ghidra's inventory, mode=reloc,
' reloc_masked=15)
'
' ASSUMPTIONS
'   No module Globals are needed by this body.
'   Fields from object_model.json: date:TMyDate @0x10, sponsor_amount:Int[] @0xFC,
'     sponsor_expires:Int[] @0x100, relationsponsors:Int @0x118; TMyDate.sdate:Int @0x8.
'   Slot 0x120 = TProfile.GotSponsor()i  (vtable_map.tsv).
'   PTR_FUN_00C61CC0 = TScreen classtable (0x00C61C2C) + 0x94 = DoMessage($,i,i)i, written
'     with the Type prefix because TProfile extends Object, not TScreen.
'   0x00508131 = the module Function recovered as SponsorName(i)$ (src/recovered_module).
'     Ghidra prints FUN_00508131(i+1,0,0); the disassembly is `push eax / call 0x508131 /
'     add esp,4` -- ONE argument, the other two pushes are DoMessage's.
'     Likewise FUN_004C5549 (GetText) takes one argument, not three.
'   Runtime helpers: 0x004A7410 _brl_retro_Lower -> Lower(), 0x004A75B0 _bbStringReplace,
'     0x0059F089 _brl_random_Rand -> Rand(0,8).
'   String literals from .rdata: "CMESSAGE_SPONSOREXPIRED", "CMESSAGE_SPONSORCANCEL",
'     "$sponsor".
'   Comparison operand order taken from the `cmp` itself, not from Ghidra:
'     `cmp edx,[eax+ebx*4+0x18] / setge` with edx = date.sdate  =>  date.sdate >= expires[i].
'
' CODEGEN NOTE (cost 3 probe rounds, may be new): the loop counter MUST be declared as a
' block-scoped `For Local i:Int = 0 To 8`, and the Rand result as its own block-scoped
' `Local i:Int` inside the If. With one function-scoped `Local i:Int` reused by both, the
' body is otherwise byte-for-byte identical but bcc allocates ebx to Self and esi to i --
' the original is the other way round (esi=Self, ebx=i), which costs `mov eax,esi / push
' eax` (3 bytes) instead of `push ebx` (1) at each of the two GotSponsor() call sites and
' comes out 370 instead of 374. Declaration POSITION of a function-scoped Local makes no
' difference; only block scoping does. Dropping the `Self.` prefixes made no difference
' either (guide 6 holds).
	If GotSponsor() = 0 Then Return 0
	For Local i:Int = 0 To 8
		If sponsor_amount[i] > 0 And date.sdate >= sponsor_expires[i]
			TScreen.DoMessage(GetText("CMESSAGE_SPONSOREXPIRED").Replace("$sponsor", Lower(SponsorName(i + 1))), 0, 0)
			sponsor_amount[i] = 0
			sponsor_expires[i] = 0
		EndIf
	Next
	If relationsponsors < 20
		Local i:Int = Rand(0, 8)
		If sponsor_amount[i] > 0
			TScreen.DoMessage(GetText("CMESSAGE_SPONSORCANCEL").Replace("$sponsor", Lower(SponsorName(i + 1))), 0, 0)
			sponsor_amount[i] = 0
			sponsor_expires[i] = 0
		EndIf
	EndIf
	If GotSponsor() = 0
		relationsponsors = 0
	EndIf
	Return 0
