' TBall.Deflect  -- Method (:TPlayer)i   slot 0x90
' VA 0x004CB5EC   217 bytes
' byte-identical vs NSS5.exe (217/217, original length from Ghidra's inventory, mode=reloc,
' reloc_masked=7)
'
' ASSUMPTIONS
'  * Global 0x00C6EFD4 declared Int, named g_player_int50 (globals_final.tsv type_source=
'    'verified', subsystem TPlayer). Names are ours; the TYPE is load-bearing and is Int.
'  * 0x00C728D0 is the Float literal 0.25 read out of NSS5.exe .rdata (raw 0000803E).
'  * FUN_0059F089 = _brl_random_Rand -> Rand(360) (second push is the default max_value=1).
'  * FUN_00506184 = module Function WrapAngle (src/recovered_module/WrapAngle.bmx),
'    Float Var parameter, so the field is passed by reference.
'  * a0.CheckOffside() is TPlayer's own slot as resolved by annotate.
'  * The DAT_005C9C84 increment and the two release-if-zero sequences in the decompilation
'    are inlined refcount traffic for `Self.controlledby = Null` and
'    `Self.lasttouchedby = a0`; they are not written in source.
	Method Deflect:Int(a0:TPlayer)
		'!Global g_player_int50:Int
		Self.controlledby = Null
		a0.calling = 0
		Self.teaminpossession = a0.teamid
		Self.lasttouchedby = a0
		Self.passtoid = -1
		Self.velocity = Self.velocity * 0.25
		Self.kicktime = g_player_int50
		Self.backpass = 0
		Self.curlamount = 0
		Self.direction = Self.direction + Rand(360)
		WrapAngle(Self.direction)
		a0.CheckOffside()
	End Method
