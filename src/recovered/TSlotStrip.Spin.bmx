' TSlotStrip.Spin
' VA 0x00578B21   263 bytes   mode=reloc
' Driven through the oracle from scratch with helper_map.record stubbed; MATCH over the
' full Ghidra-authoritative length, every byte.
' Body-only format: statements only, parameters are a0, a1, ...
'!Global g_slotSpinTime:Int
Self.spintime = g_slotSpinTime
Select a0
	Case 1
		Self.yVel = Rnd(22.0, 24.0)
		Self.spinlength = Rand(250) + 1500
	Case 2
		Self.yVel = Rnd(24.0, 26.0)
		Self.spinlength = Rand(250) + 2000
	Case 3
		Self.yVel = Rnd(26.0, 28.0)
		Self.spinlength = Rand(250) + 2500
End Select
If Self.fruitCount = 6
	Self.yVel :- 4.0
	Self.spinlength :- 750
End If
Self.reelstopped = 0
