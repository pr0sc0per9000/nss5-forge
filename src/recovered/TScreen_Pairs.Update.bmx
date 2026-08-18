' TScreen_Pairs.Update
' VA 0x00579419   485 bytes   class-table slot 0x48   sig ()i   KIND=Function (static)
' byte-identical vs NSS5.exe (485/485, original length from Ghidra's inventory, mode=reloc,
' reloc_masked=32)
' Body-only format: statements only, no parameters.
' assumptions (module Globals, names ours):
'   0x00C6C82C : Int    -- the mini-game state machine (-2 / -1 / 0 / 2)
'   0x00C6C834 : Int    -- the timestamp of the last state change. globals_final.tsv types
'                          this TScreen from ONE construction site; the code only ever does
'                          `add eax,0x7d0 / cmp` on it with no refcount traffic, so Int (11.2).
'   0x00C6C830 : Int    -- how many cards have been turned over this attempt
'   0x00C6EFD4 : Int    -- the shared MilliSecs() snapshot (same Global as TSlotStrip.Spin)
'   0x00C6C9E0 : TList  -- the TPair_Icon tiles. globals_final.tsv has bare Object /
'                          usage / low; TList is forced by the 0x8C ObjectEnumerator call
'                          and the loop downcasts to 0x00C6CAEC = TPair_Icon.
' slots resolved (all TScreen_Pairs' own class table, so written as bare sibling calls per 3d):
'   0x00C6C9C0 = +0x3C TScreen_Pairs.NewButtonPositions()
'   0x00C6C9C8 = +0x44 TScreen_Pairs.UpdateFaces()
'   0x00C6C9D4 = +0x50 TScreen_Pairs.EnableAll()
'   0x00C6C9D8 = +0x54 TScreen_Pairs.Success(i)
'   0x00C6C9DC = +0x58 TScreen_Pairs.Fail()
' fields: TPair_Icon.imgId +0x0C, TPair_Icon.picked +0x1C.
' load-bearing shape: `cmp edx,eax / setg` with edx = the time Global fixes the comparison
' as `g_time > g_pairs_time + N`, not the reverse (10.1). The two `mov eax,0 / jmp epilogue`
' tails after Success and Fail are real `Return 0` statements -- without them the body is
' 475 bytes.
	Function Update:Int()
		'!Global g_pairs_state:Int
		'!Global g_time:Int
		'!Global g_pairs_time:Int
		'!Global g_pairs_tries:Int
		'!Global g_pairs_icons:TList
		If g_pairs_state = -2 And g_time > g_pairs_time + 2000
			g_pairs_state = -1
			g_pairs_time = g_time
			UpdateFaces()
		ElseIf g_pairs_state = -1 And g_time > g_pairs_time + 1000
			g_pairs_state = 0
			g_pairs_time = g_time
			NewButtonPositions()
		ElseIf g_pairs_state = 2 And g_time > g_pairs_time + 1200
			g_pairs_tries = g_pairs_tries + 1
			Local first:Int = 0
			Local second:Int = 0
			For Local ic:TPair_Icon = EachIn g_pairs_icons
				If ic.picked <> 0
					If first = 0
						first = ic.imgId
					Else
						second = ic.imgId
					EndIf
				EndIf
			Next
			If first = second
				Success(first)
				Return 0
			ElseIf g_pairs_tries = 2
				Fail()
				Return 0
			Else
				g_pairs_state = 0
				For Local ic:TPair_Icon = EachIn g_pairs_icons
					ic.picked = 0
				Next
				UpdateFaces()
				EnableAll()
			EndIf
		EndIf
	End Function
