' TTraining.UpdatePassing
' VA 0x00580C44   553 bytes   mode=reloc   byte-identical vs NSS5.exe
' KIND=Function (static, no implicit Self), SIG ()i, class-table slot 0x74
'
' ASSUMPTIONS  (module Global names are ours; the declared TYPES are load-bearing)
'   0x00C6CFFC g_training_state:Int     (bare dword, compared to -1 and stored 0)
'   0x00C6EFD4 g_ticks:Int              (the millisecond clock; globals_final says TScreen
'                                        with a flagged conflict -- bare dword, so Int)
'   0x00C92920 g_training_dist:Float    (loaded with fld, stored to a Float local)
'   0x00C6D568 g_trainobjs:TList        (ObjectEnumerator at slot 0x8C)
'   0x00C6CFD8 g_training_setpiecex:Int 0x00C6CFDC g_training_setpiecey:Int
'   Loop element types come from the class table pushed into bbObjectDowncast:
'     0x00C6D770 = TCone, 0x00C6DC1C = TTrainingLine.  Both inherit x/y/alive from
'     TTrainingObject (+0x10/+0x14/+0x18).
'   Class-table slots: 0x00C6D538 TTraining+0x94 Fail, 0x00C6D53C TTraining+0x98 Success
'   (same Type -> bare names), 0x00C5FAB0 TPlayer+0x164 GetHumanPlayer, 0x00C5AEDC
'   TBall+0x44 GetActiveBall, 0x00C5BAA0 TEngine+0x70 SetUpSetPiece.
'   0x00C92924 is the Float constant 20.0.  E8 0x00505DA2 = Dist2D (recovered module Fn).
'
' MEASURED SHAPE: the -1 guard is a real early Return 0 (mov eax,0 / jmp epilogue).
' `d` is a Float Local that never gets a stack slot -- it stays on the x87 stack, which is
' what makes `If d > maxd` come out as fld/fxch/fucom/setbe.
'!Global g_training_state:Int
'!Global g_ticks:Int
'!Global g_training_dist:Float
'!Global g_trainobjs:TList
'!Global g_training_setpiecex:Int
'!Global g_training_setpiecey:Int
If g_training_state = -1
	g_training_state = 0
	Fail()
	Return 0
End If
Local p:TPlayer = TPlayer.GetHumanPlayer()
Local b:TBall = TBall.GetActiveBall()
If b <> Null
	Local restart:Int = 0
	If b.kicktime > 0 And g_ticks > b.kicktime + 250
		If b.controlledby = p Then restart = 1
		If g_ticks > b.kicktime + 3500 Then restart = 1
	End If
	Local maxd:Float = g_training_dist
	For Local c:TCone = EachIn g_trainobjs
		If c.alive = 0 Then restart = 1
		Local d:Float = Dist2D(p.x, p.y, c.x, c.y)
		If d > maxd Then maxd = d
	Next
	If Dist2D(p.x, p.y, b.x, b.y) > maxd + 20.0 Then restart = 1
	If b.y > 0.0 Then restart = 1
	If restart Then TEngine.SetUpSetPiece(4, 1, g_training_setpiecex, g_training_setpiecey)
End If
Local n:Int = 0
For Local l:TTrainingLine = EachIn g_trainobjs
	If l.alive <> 0 Then n = n + 1
Next
If n = 0 Then Success()
