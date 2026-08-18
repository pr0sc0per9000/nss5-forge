' TContractOffer.CreateContract  -- KIND=Function (static, no implicit Self)
' VA 0x00571214   541 bytes   sig ($)i   slot 0x38
' byte-identical vs NSS5.exe (541/541, original length from Ghidra's inventory, mode=reloc,
' reloc_masked=33)
'
' ASSUMPTIONS
'   Global (name ours):
'     0x00C6B428 -> g_contractoffers:TList   globals_final says "Object / usage"; the call
'                   goes through slot 0x74, which is TList.Remove(:Object) (guide 10.7),
'                   so TList.
'   0x00C59E0C = TClub+0x60 = SelectById (i):TClub   (class-table interior, not a Global)
'   FUN_00505BCB = NextFieldInt (src/recovered_module/NextFieldInt.bmx), sig
'                  ($ Var,$)i -- the `lea eax,[ebp-4]; push eax` is the String Var.
'   FUN_004A8F20(ClassTable_TContractOffer) = New TContractOffer
'   Separator literal read from the exe at 0x00C6FCC0 = a single TAB -> "~t".
'   Fields from object_model.json: +8 club:TClub, +0xC wage, +0x10 length, +0x14 goalbonus,
'   +0x18 assistbonus, +0x1C cleanbonus, +0x20 signingfee, +0x24 newbossrel,
'   +0x28 negotiationsuccess.
'
' Shape notes: the club test is the bare-truth form `If Not c.club` (cmp Null / setne al /
' movzx / cmp 0 / jne) -- `= Null` is 10 bytes shorter and diverges at that branch.  The
' guard is a real EARLY RETURN, not an If/Else: the original emits `mov eax,0` before the
' single `jmp` to the epilogue, which the Else form does not (536 vs 541).
'!Global g_contractoffers:TList
	Function CreateContract(a0:String)
		Local c:TContractOffer = New TContractOffer
		c.club = TClub.SelectById(NextFieldInt(a0, "~t"))
		If Not c.club
			g_contractoffers.Remove(c)
			Return 0
		End If
		c.wage = NextFieldInt(a0, "~t")
		c.length = NextFieldInt(a0, "~t")
		c.goalbonus = NextFieldInt(a0, "~t")
		c.assistbonus = NextFieldInt(a0, "~t")
		c.cleanbonus = NextFieldInt(a0, "~t")
		c.signingfee = NextFieldInt(a0, "~t")
		c.newbossrel = NextFieldInt(a0, "~t")
		c.negotiationsuccess = NextFieldInt(a0, "~t")
	End Function
