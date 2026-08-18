' TClub.AverageOutStrengthAll
' VA 0x004C215F   434 bytes   class-table slot 0x8C   sig ()i   KIND=Function (static)
' byte-identical vs NSS5.exe (434/434, original length from Ghidra's inventory, mode=reloc,
' reloc_masked=15)
' Body-only format: statements only, no parameters.
' assumptions (module Globals, names ours):
'   0x00C596F0 : TList  -- every TNation. globals_final.tsv has it as bare Object with
'                          type_source=usage/low; TList is forced by the ObjectEnumerator
'                          (slot 0x8C) call on it, and the loop downcasts to class table
'                          0x00C599C8 = TNation.
'   0x00C59A48 : Int    -- the sort-mode selector TClub.Compare reads; set to 34 right
'                          before the Sort. Bare `mov dword [0xc59a48],0x22`, no refcount
'                          traffic, so Int (11.2).
' slots resolved: 0x00C59E1C = TClub classtable + 0x70 = TClub.SelectListByNationId(i):TList,
'   so per 3d it is written as a bare sibling call with no `TClub.` prefix.
'   TList 0x8C=ObjectEnumerator, 0x30=HasNext, 0x34=NextObject, 0x88=Sort, 0x70=Count.
'   The Sort call site pushes 0x005B3516 as well as the 1: that is BRL's default
'   compareFunc argument being materialised, i.e. the source is plain `Sort(1)`.
' fields: strength is TBase_Team +0x24, id is TBase_Team +0x0C (both inherited).
' load-bearing shape notes:
'   * `cmp [eax+0x24],edx / jle` fixes the operand order as `c.strength > maxs`, not
'     `maxs < c.strength` (10.1).
'   * The division really is a separate Float Local: the original spills Float(maxs-mins)
'     to a temp across the Count() call, then copies the quotient into `stp`.
'   * `Local cur:Float = maxs` is an Int->Float convert (fild/fstp), not a reload.
	Function AverageOutStrengthAll:Int()
		'!Global g_nations:TList
		'!Global g_club_sortmode:Int
		For Local n:TNation = EachIn g_nations
			Local clubs:TList = SelectListByNationId(n.id)
			If clubs <> Null
				Local maxs:Int = 0
				Local mins:Int = 0
				For Local c:TClub = EachIn clubs
					If c.strength > maxs
						maxs = c.strength
					EndIf
					If c.strength < mins
						mins = c.strength
					EndIf
				Next
				If mins < 15
					mins = 15
				EndIf
				g_club_sortmode = 34
				clubs.Sort(1)
				Local stp:Float = Float(maxs - mins) / clubs.Count()
				Local cur:Float = maxs
				For Local c:TClub = EachIn clubs
					c.strength = Int(cur)
					cur = cur - stp
				Next
			EndIf
		Next
	End Function
