' TTeam.GetPlayerNearestToXY  -- Method (i,i,i,:TPlayer,i):TPlayer   slot 0x90
' VA 0x004E19D8   404 bytes
' byte-identical vs NSS5.exe (404/404, original length from Ghidra's inventory, mode=reloc,
' reloc_masked=8)
'
' ASSUMPTIONS
'  * No module Globals are used.
'  * Slot 0x1A0 on TPlayer resolved from vtable_map.tsv = TPlayer.PlayerOnFeet ()i
'    (0x004FC83A).
'  * FUN_00505DA2 = module Function Dist2D (src/recovered_module/Dist2D.bmx); Ghidra prints
'    it with three arguments, the real arity is four -- confirmed from the four pushes at
'    0x004E1AD5..0x004E1ADB, which also fix the order as (p.x, p.y, a0, a1).
'  * 0x00C75D38 is the Float literal 2.0 read out of NSS5.exe .rdata (raw 00000040).
'  * Field offsets from object_model.json: TTeam.squad 0x1C, TPlayer.x 0x4C, .y 0x50,
'    .goalside 0x8C, .selectionno 0xBC, .matchstats 0x188, TStats_Match.reds 0x10.
'  * Boolean shapes taken from the bytes, not from Ghidra:
'      `je next / jmp loopend` pairs at 0x004E1A51, 0x004E1AA6, 0x004E1AB0 are `Continue`.
'      `cmp 0xa / setg` is `> 10`; `cmp 0xb / setl` is `< 11` (guide 10.1 -- match the
'      setcc and its immediate, not the meaning).
'      `p.matchstats.reds` and `a4` are bare truth tests (plain cmp 0), while `a2 = 0` and
'      `p.selectionno = 0` carry a sete.
'  * `Local d:Float` stays on the x87 stack, so `d = d * 2.0` is a single fmul (guide 6).
	Method GetPlayerNearestToXY:TPlayer(a0:Int, a1:Int, a2:Int, a3:TPlayer, a4:Int)
		Local best:TPlayer = Null
		Local bestd:Int = 0
		For Local p:TPlayer = EachIn Self.squad
			If p.matchstats.reds Or p.selectionno > 10 Then Continue
			If p.selectionno < 11 And p.PlayerOnFeet()
				If a2 = 0 And p.selectionno = 0 Then Continue
				If p = a3 Then Continue
				Local d:Float = Dist2D(p.x, p.y, a0, a1)
				If a4 And p.goalside = 0 Then d = d * 2.0
				If d < bestd Or best = Null
					bestd = Int(d)
					best = p
				EndIf
			EndIf
		Next
		Return best
	End Method
