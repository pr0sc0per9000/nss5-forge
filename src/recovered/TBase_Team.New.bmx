' TBase_Team.New  -- KIND=Method (Self = param_1)
' VA 0x004BCEBF   404 bytes   sig ()i   slot 0x10
' byte-identical vs NSS5.exe (404/404, original length from Ghidra's inventory, mode=reloc,
' reloc_masked=27)
'
' ASSUMPTIONS / RESOLUTIONS
'  * No Globals used.
'  * Everything before the Rand call in the decompilation is compiler-generated default field
'    init (bbObjectCtor at 0x004A8E50, the class-table store, the ""-init of the six String
'    fields via &PTR_PTR_005C7D40, and the Null-init of the six object fields via
'    &DAT_005C9C84). None of it is source. See guide 3d/10.6.
'  * 0x0059F089 = _brl_random_Rand; the (9999,1) argument pair is Rand's default
'    max_value=1, i.e. the source is the one-argument `Rand(9999)`.
'  * 0x004A8F20 with ClassTable_TKitStrings => `New TKitStrings`; the surrounding
'    retain / release / conditional-bbGCFree around each store is inlined BBRELEASE.
	Method New()
		Self.randno = Rand(9999)
		Self.kitcolsHome = New TKitStrings
		Self.kitcolsAway = New TKitStrings
		Self.kitcolsThird = New TKitStrings
		Self.kitcolsKeeper = New TKitStrings
	End Method
