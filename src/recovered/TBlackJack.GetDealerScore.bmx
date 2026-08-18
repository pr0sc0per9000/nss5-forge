' TBlackJack.GetDealerScore
' VA 0x00577573   216 bytes   vtable slot 0x58   sig (*i,*i)i
' byte-identical vs NSS5.exe (216/216, original length from Ghidra's inventory, mode=reloc)
' assumptions (module Globals, names ours):
'   0x00C6C17C : Int    -- the "a hand is in play" flag
'   0x00C6C170 : TList  -- the dealer's cards (typed Object/low in globals_final; TList is
'                          forced by the ObjectEnumerator 0x8C call on it)
' The downcast class table is TCard; TCard.num is +0x10 by reflection.
' Shape is load-bearing: `cmp [g],0 / jne body / mov eax,0 / jmp end` is an EARLY RETURN,
' not an If-block wrapping the rest -- as an If-block it comes out 210 bytes.
' bcc does no CSE: c.num really is loaded twice.
	Function GetDealerScore:Int(a0:Int Ptr, a1:Int Ptr)
		'!Global g_bj_dealing:Int
		'!Global g_bj_dealercards:TList
		a0[0] = 0
		a1[0] = 0
		If g_bj_dealing = 0
			Return 0
		EndIf
		Local ace:Int = 0
		For Local c:TCard = EachIn g_bj_dealercards
			Local v:Int = c.num
			If v > 10
				v = 10
			EndIf
			a0[0] = a0[0] + v
			If c.num = 1
				ace = 1
			EndIf
		Next
		If ace
			a1[0] = a0[0] + 10
		EndIf
		If a1[0] > 21
			a1[0] = 0
		EndIf
	End Function
