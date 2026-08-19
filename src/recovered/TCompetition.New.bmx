' TCompetition.New  ()i   slot 0x10
' VA 0x00508fb1   414 bytes   vtable slot 0x10   sig ()i
' byte-identical vs NSS5.exe (414/414, original length from Ghidra's inventory)
' VA 0x00508FB1   length 414   oracle: MATCH mode=reloc 414/414 reloc_masked=22
'
' Assumptions:
'   '!Global g_lcompetitions:TList   at 0x00C6099C -- the module list of all competitions.
'       Declared type TList is load-bearing: AddLast is slot 0x44 on TList.
'   FUN_005B40BF is the alias set CreateList|CreateMap|TGNetHost.Create; CreateList is the
'       member here (confirmed by the following TList.AddLast at slot 0x44, per guide 10.8).
'   The whole run of `Self.<field> = 0 / ""` at the top of the decompilation is bcc's own
'       field-default init inside the Type declaration -- NOT source. All TCompetition
'       defaults are zero/empty, so no '!Field pragma is needed.
'   The null test is the `If Not x` form (setne al / movzx / cmp 0 / jne, guide 10.3):
'       `If g = Null` is 9 bytes shorter and gives 405.
Method New()
	'!Global g_lcompetitions:TList
	If Not g_lcompetitions Then g_lcompetitions = CreateList()
	Self.lfixturelist = CreateList()
	Self.lpromotionplaces = CreateList()
	Self.lplacesthatpromotetome = CreateList()
	g_lcompetitions.AddLast(Self)
End Method
