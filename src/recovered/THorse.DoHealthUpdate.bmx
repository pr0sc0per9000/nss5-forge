' THorse.DoHealthUpdate
' VA 0x0058B9DA   552 bytes   vtable slot 0x7C   sig ()i   KIND=Function (static)
' byte-identical vs NSS5.exe (552/552, original length from Ghidra's inventory, mode=reloc)
' assumptions (module Globals, names ours):
'   0x00C6E294 : TList  -- all horses (same Global as THorse.SelectRunners; TList is forced
'                          by slot 0x8C ObjectEnumerator)
'   0x00C6DF64 : Int    -- bare dword store of 0, no refcount traffic
' slots resolved:
'   [0x00C61CC0] = TScreen classtable + 0x94 = TScreen.DoMessage($,i,i)
' downcast class table 0x00C6E788 = THorse.
' BRL / module functions: 0x0059F048 _brl_random_Rnd, 0x0059F089 _brl_random_Rand,
'   0x00505F90 ClampFloat (recovered module fn), 0x004C5549 GetText (recovered module fn),
'   0x004A75B0 _bbStringReplace, 0x004A8F60 _bbObjectDowncast.
' fields: THorse +0x38 name$, +0x3C energy:Float, +0x40 health:Float,
'         +0x44 strength:Float, +0x50 owned:Int.
' float constants read out of .rdata: 0xC94478/0xC94480 = 5.0/-5.0 (doubles, Rnd),
'   0xC94488/0xC94490 = 0.5/-0.5 (doubles, Rnd), 0xC94498 = 70.0, 0xC9449C = 2.5,
'   0xC944A0 = 50.0, 0xC944E0 = 0.5, and the ClampFloat bounds pushed as immediates
'   0x3F800000 = 1.0, 0x41F00000 = 30.0, 0x42C80000 = 100.0.
' Shape notes: Rand's argument pair really is (5, 1) in the health-decay call -- that is
' what the original pushes, not (1, 5). `Local oldhealth:Float = h.health` is a real Local
' (spilled to [ebp-0x20]) because it is read after h.health has been overwritten.
	Function DoHealthUpdate:Int()
		'!Global g_horses:TList
		'!Global g_horse_flag:Int
		g_horse_flag = 0
		For Local h:THorse = EachIn g_horses
			If h.owned = -1
				h.energy = h.energy + Rnd(-5.0, 5.0)
				h.health = h.health + Rnd(-0.5, 0.5)
			ElseIf h.owned = 1
				Local oldhealth:Float = h.health
				h.energy = h.energy + Rand(50, 75)
				h.health = h.health - Rand(5, 1)
				If h.health < 70.0
					h.strength = h.strength - 2.5
					If oldhealth > 50.0
						TScreen.DoMessage(GetText("CMESSAGE_HORSEBECOMESILL").Replace("$name", h.name), 0, 0)
					EndIf
				EndIf
			Else
				h.energy = h.energy + Rand(50, 80)
				h.health = h.health + 0.5
			EndIf
			ClampFloat(Varptr h.energy, 1.0, 100.0)
			ClampFloat(Varptr h.health, 1.0, 100.0)
			ClampFloat(Varptr h.strength, 30.0, 100.0)
		Next
	End Function
