' TTraining.ResetTraining
' VA 0x005826B1   828 bytes   vtable slot 0xb4   KIND=Function (static)   sig ()i
' byte-identical vs NSS5.exe (828/828, original length from Ghidra's inventory)
' harness mode=reloc, reloc_masked=47, NSS5_NO_LEARN=1, no learned helpers.
'
' ASSUMPTIONS
'  * g_training_int03 selects the training drill mode; only modes 3, 6 and 10 have any
'    code. Modes 1,2,4,5,7,8,9 are each an EXPLICIT empty `Case` -- confirmed because the
'    original tests all ten values individually (cmp eax,1 .. cmp eax,0xA) each with its
'    OWN trailing `jmp` to the shared exit; grouping them onto one comma Case (`Case 1, 2`)
'    collapses those into a single shared jmp and is 2 bytes short per value collapsed.
'  * Case 3 (ladder-of-poles drill): `yacc` is declared FIRST (before `linesp`/`cx`), from
'    g_training_float04 (0x00C6D00C). It is NOT dead: it is the actual distance argument
'    passed to YardsToPixels for the pole spread each iteration (`TPitch.YardsToPixels
'    (yacc)`), and widens/narrows by 0.25 every iteration via `yacc :+ 0.25` -- confirmed
'    by the original pushing `[ebp-0x1c]` (yacc's slot), not the literal 5.0, at both call
'    sites inside the loop. The literal 5.0 (0x40A00000) is used only ONCE, for `linesp`
'    (the row-to-row Y spacing in pixels), computed before the loop.
'  * TPole.Create(x:Int, y:Int, colour:String) and TTrainingLine.Create(x1,y1,x2,y2,
'    colour:String) -- argument order read off the push sequence (section 8/16.2), both
'    poles/the line share colour "FFFF00"/"0000FF" literals read from the exe.
'  * Case 6: `g_Object813` (0x00C6D568) is typed TList here, not the Object
'    globals_final.tsv gives it -- it is used at slot 0x8C (TList.ObjectEnumerator), the
'    section-10.7/16.7 tell. `EachIn` downcasts to TCone (class table 0x00C6D770). Fields
'    written are TTrainingObject.alive (+0x18), TTrainingObject.frame (+0xC) and
'    TCone.fallen (+0x24), in that order (alive, frame, fallen) -- matches the store order
'    in the original, not field-declaration order.
'  * Case 10: `ang` (Int) is computed once (`r + 90`) and reused for both Cos and Sin, since
'    bcc has no CSE and the original visibly shares one register (esi) across both calls.
'    The Cos expression is written `Cos(ang) * Float(px)` and the Sin expression
'    `Float(-g_player_int17) + Sin(ang) * Float(px)` -- in BOTH cases the trig call is
'    evaluated (and its result multiplied by px) BEFORE the px fild, matching the original's
'    instruction order (call bbCos/bbSin precedes the px fild in each case); getting Sin's
'    operand order backwards (`Float(px) * Sin(ang)`) cost an extra fild/fstp round-trip
'    (+9 bytes) because it forced px to be converted and spilled before the call instead of
'    after.
'  * TPitch.YardsToPixels, TPole.Create, TTrainingLine.Create, TTrainingObject.ClearAll,
'    TDummy.ResetDummies, TDummy.UpdateWallLocations are all static Functions on their Type
'    (class-table + slot direct calls, no Self).

	Function ResetTraining:Int()
		'!Global g_training_int03:Int
		'!Global g_training_int11:Int
		'!Global g_training_int12:Int
		'!Global g_training_int13:Int
		'!Global g_training_int14:Int
		'!Global g_training_int15:Int
		'!Global g_training_int16:Int
		'!Global g_training_int20:Int
		' Original data-section values 0.25/5.0, read directly from NSS5.exe.
		' See codegen-patterns 21.1/21.3.
		'!Global g_training_float03:Float = 0.25
		'!Global g_training_float04:Float = 5.0
		'!Global g_Object813:TList
		'!Global g_player_int17:Int
		Select g_training_int03
			Case 1
			Case 2
			Case 3
				TTrainingObject.ClearAll()
				Local yacc:Float = g_training_float04
				Local linesp:Int = Int(TPitch.YardsToPixels(5.0))
				Local cx:Int = g_training_int11
				For Local i:Int = 1 To g_training_int20
					Local x1:Int = Int(Float(cx) - TPitch.YardsToPixels(yacc))
					Local x2:Int = Int(Float(cx) + TPitch.YardsToPixels(yacc))
					Local ly:Int = g_training_int12 - linesp * i
					TPole.Create(x1, ly, "FFFF00")
					TPole.Create(x2, ly, "FFFF00")
					TTrainingLine.Create(x1, ly, x2, ly, "0000FF")
					cx = Int(Float(cx) + Float(i) * TPitch.YardsToPixels(g_training_float03))
					yacc :+ 0.25
				Next
			Case 4
			Case 5
			Case 6
				For Local c:TCone = EachIn g_Object813
					c.alive = 1
					c.frame = 1
					c.fallen = 0
				Next
			Case 7
			Case 8
			Case 9
			Case 10
				Local r:Int = Rand(-g_training_int16, g_training_int16)
				Local ang:Int = r + 90
				Local px:Int = Int(TPitch.YardsToPixels(Float(g_training_int15)))
				g_training_int13 = Int(Cos(ang) * Float(px))
				g_training_int14 = Int(Float(-g_player_int17) + Sin(ang) * Float(px))
				TDummy.UpdateWallLocations(g_training_int13, g_training_int14)
				TDummy.ResetDummies()
				g_training_int11 = g_training_int13
				g_training_int12 = g_training_int14
		End Select
		Return 0
	End Function
