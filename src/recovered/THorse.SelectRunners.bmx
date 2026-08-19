' THorse.SelectRunners
' VA 0x0058B226   487 bytes   vtable slot 0x68   sig (i)i   KIND=Function (static)
' byte-identical vs NSS5.exe (487/487, original length from Ghidra's inventory, mode=reloc)
' assumptions (module Globals, names ours):
'   0x00C6E294 : TList     -- all horses (globals_final: Object/low; TList is forced by
'                             slots 0x8C ObjectEnumerator, 0x70 Count, 0x88 Sort)
'   0x00C6E298 : TList     -- the selected runners (slots 0x34 Clear, 0x44 AddLast, 0x70)
'   0x00C6E29C : Int       -- bare dword store of 5, no refcount traffic
'   0x00C6F028 : TProfile  -- globals_final says TPlayer; that row is wrong for the same
'                             reason as in TScreen_MyContract (its note is the untrustworthy
'                             "only TPlayer has them all"). [g+0x10] then [+8] is
'                             TProfile.date:TMyDate then TMyDate.sdate:Int.
' slots resolved:
'   [0x00C6E7F8] = THorse classtable + 0x70 = ResetRands()  (own type -> bare name)
'   TList.Sort() is written with NO arguments: BlitzMax materialises the defaults at the
'   call site, which is exactly the `push _brl_linkedlist_CompareObjects / push 1` pair the
'   original emits (0x005B3516 = _brl_linkedlist_CompareObjects).
' fields: THorse +0x50 owned, +0x54 lastran, +0x5C raceposition, +0x60 racenum,
'         +0x64 betamount, +0x68 betprice.
' downcast class table 0x00C6E788 = THorse.
' runtime helpers: 0x00505B91 LogLine (recovered module fn), 0x004A7AC0 _bbStringFromInt,
'                  0x004A7C20 _bbStringConcat, 0x004A8F60 _bbObjectDowncast.
' Shape notes: the reset loop stores the four fields in the order betamount, racenum,
' betprice, raceposition -- not in field order. The three-term guard is a chained
' short-circuit And (setl, sete, setne, each followed by cmp eax,0 / je).
	Function SelectRunners:Int(a0:Int)
		'!Global g_horses:TList
		'!Global g_runners:TList
		'!Global g_stable_int26:Int
		'!Global g_profile:TProfile
		LogLine("SelectRunners")
		For Local h:THorse = EachIn g_horses
			h.betamount = 0
			h.racenum = 0
			h.betprice = 0
			h.raceposition = 0
		Next
		LogLine("Horselist = " + g_horses.Count())
		ResetRands()
		g_stable_int26 = 5
		g_horses.Sort()
		g_runners.Clear()
		Local n:Int = 0
		For Local h:THorse = EachIn g_horses
			If n < a0 And h.owned = 0 And h.lastran <> g_profile.date.sdate
				g_runners.AddLast(h)
				n = n + 1
				h.racenum = n
			EndIf
		Next
		LogLine("Total Horses:" + g_horses.Count())
		LogLine("Total Runners:" + g_runners.Count())
	End Function
