' TCompetition.CheckCupQualifyingCompetitions  -- KIND=Method, sig (i)i, slot 0x78
' VA 0x0050C1EE   147 bytes
' byte-identical vs NSS5.exe (147/147, original length from Ghidra's inventory, mode=reloc,
' reloc_masked=4)
'
' ASSUMPTIONS
'   Fields from object_model.json: TCompetition.lplacesthatpromotetome @0x68 (:TList),
'     TCompetition.comptype @0x24. TPromotionPlace.parentid @0x8.
'   Calls: TCompetition.SelectById (ct slot 0x4c, 0x00C6160C), Self-type recursive call
'     through slot 0x78 (this same method) on the TCompetition returned by SelectById,
'     TListEnum.HasNext (slot 0x30), TListEnum.NextObject (slot 0x34), _bbObjectDowncast
'     (0x004A8F60) to TPromotionPlace (classtable 0x00580340 in this build; masked).
'   Param a0 is the competition id being tested for cup-qualification into Self.
'
' CODEGEN NOTE (cost ~10 probe rounds, register colour only -- length matched on the first
' correct control-flow shape, all further rounds were register-allocator archaeology):
'   The original assigns a0's copy to esi, the list-field temporary to ebx, and the
'   enumerator to edi. A naive transcription (comparing directly against a0, computing a0
'   only where the recursive call needs it) puts the enumerator in the right place but
'   swaps which of {a0-copy, field-temp} gets ebx vs esi. The exact original register
'   colouring is reproduced only when:
'     (1) the equality test against the loop variable's parentid uses a0 DIRECTLY, and
'     (2) a separate `Local qid:Int = a0` is declared AFTER that test (and after nothing
'         else), used only for the recursive call argument.
'   Declaring qid before the test, or folding it into a single `Local qid = a0` used for
'   both purposes, both cost either length (+2 bytes, matched drops to ~16-20/149) or land
'   qid and the field-temp on the wrong physical registers (matched 127-130/147). This is
'   an instance of guide 18.2's rank/declaration-order tie-break: qid's single narrow-scope
'   use (declared right before its only remaining use) evidently outranks the field temp's
'   very short earlier live range once the graph is coloured, where declaring it any
'   earlier does not.
'   ORIGINAL BUG: none noted -- straightforward recursive cup-qualification walk up the
'   chain of promotion places.
For Local pp:TPromotionPlace = EachIn lplacesthatpromotetome
	If pp.parentid = a0 Then Return 1
	Local qid:Int = a0
	Local comp:TCompetition = TCompetition.SelectById(pp.parentid)
	If comp.comptype = 1
		If comp.CheckCupQualifyingCompetitions(qid) <> 0 Then Return 1
	EndIf
Next
Return 0
