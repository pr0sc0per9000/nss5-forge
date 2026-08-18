' TScreen_MyContract.UpdateClubsInterestedLabelForLoan
' VA 0x00555023   370 bytes   vtable slot 0x40   sig ()i   KIND=Function (static)
' byte-identical vs NSS5.exe (370/370, original length from Ghidra's inventory, mode=reloc)
' assumptions (module Globals, names ours):
'   0x00C6F028 : TProfile  -- globals_final says TPlayer, and that row is WRONG. Its note
'                            reads "only TPlayer has them all", exactly the untrustworthy
'                            shape called out in codegen-patterns 11.2. The code loads
'                            [g+0x1D0] and then [+0x64]; TPlayer has no field at 0x1D0,
'                            TProfile.myclub:TClub is at +0x1D0 and TClub.nationid at +0x64.
'   0x00C67D9C : TGadget   -- globals_final: Object/low. Typed TGadget because the only use
'                            is the vcall at slot 0x64 = TGadget.SetText($,$,i,i). A TLabel
'                            (or any TGadget subclass) would select the same slot; TGadget
'                            is the weakest assumption that resolves it.
' slots resolved:
'   [0x00C6B818] = TContractOffer classtable + 0x60 = GetClubsInterestedInLoan():TList
'   [0x00C59A20] = TNation classtable + 0x58 = TNation.SelectById(i):TNation
'   [0x00C6160C] = TCompetition classtable + 0x4C = TCompetition.SelectById(i):TCompetition
'   g_mycontract_label vcall +0x64 = TGadget.SetText($,$,i,i)  (Self IS pushed; 5 args)
' fields: TClub +0x64 nationid, +0x68 leagueid, +0x20 labelshortname (TBase_Team),
'         +0x0C id (TBase_Team), +0x18 tla (TBase_Team); TCompetition +0x10 tla.
' runtime helpers: 0x004A8F60 _bbObjectDowncast, 0x004A6A30 _bbStringCompare,
'                  0x004A7C20 _bbStringConcat, 0x004C5549 GetText (recovered module fn).
' Shape notes: the concatenation really is PARENTHESISED -- the original concatenates the
' club fragment first and only then appends it to the accumulator, so a flat left-assoc
' `s + a + " (" + tla + ")"` would emit the concats in the wrong order.
' The `If s = ""`/`If s <> ""` tests are bbStringCompare + `cmp eax,0` branched directly.
' The EachIn null-skip (cmp esi,bbNullObject / je) is emitted by the loop itself.
	Function UpdateClubsInterestedLabelForLoan:Int()
		'!Global g_mycontract_profile:TProfile
		'!Global g_mycontract_label:TGadget
		Local s:String = ""
		For Local c:TClub = EachIn TContractOffer.GetClubsInterestedInLoan()
			If s <> ""
				s = s + ", "
			EndIf
			Local nat:TNation = TNation.SelectById(c.nationid)
			Local comp:TCompetition = TCompetition.SelectById(c.leagueid)
			If nat.id = g_mycontract_profile.myclub.nationid
				s = s + (c.labelshortname + " (" + comp.tla + ")")
			Else
				s = s + (c.labelshortname + " (" + nat.tla + ")")
			EndIf
		Next
		If s = ""
			s = GetText("None")
		EndIf
		g_mycontract_label.SetText(s, "", -1, -1)
	End Function
