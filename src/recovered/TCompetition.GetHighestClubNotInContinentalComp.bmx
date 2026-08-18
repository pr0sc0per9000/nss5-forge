' TCompetition.GetHighestClubNotInContinentalComp
' VA 0x0050D54B   110 bytes   vtable slot 0xbc   sig ():TClub
' byte-identical vs NSS5.exe (110/110, original length from Ghidra's inventory, mode=reloc)
' Verified 110/110 under NSS5_NO_LEARN=1. The header must spell the address as
' "VA 0x...": coverage.py's HEADER_VA regex (`VA\s+0x`) does not match "VA=0x...",
' and a body whose header uses that form is invisible to the coverage number.
'
' ASSUMPTIONS / RESOLUTIONS
'   Self.teampool is TCompetition field 0x6c, declared []:TTeamPool (an ARRAY).
'     The original does `mov eax,[Self+0x6c] / mov eax,[eax+0x18] / mov esi,[eax+8]`,
'     i.e. BBArray data at +0x18 index 0, then TTeamPool.list at +0x08 -> teampool[0].list
'   slot 0x8c/0x30/0x34 on that list = TList.ObjectEnumerator / TListEnum.HasNext /
'     NextObject  -> plain `For ... EachIn`; the `cmp eax,0x5C9C80 / je` is the
'     loop's own built-in null skip, not source.
'   ClassTable_TTableData (0x00C64B80) is the downcast target -> loop var is :TTableData
'   PTR_FUN_00C59E0C = TClub class table + slot 0x60 = TClub.SelectById(i):TClub
'   [eax+0x6c] on the returned TClub = TClub.continentalcompid
'   No module Globals are referenced by this body.

For Local td:TTableData = EachIn Self.teampool[0].list
	Local c:TClub = TClub.SelectById(td.teamid)
	If c.continentalcompid = 0 Then Return c
Next
Return Null
