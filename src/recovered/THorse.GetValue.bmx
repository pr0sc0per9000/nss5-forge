' THorse.GetValue
' VA 0x0058AA59   179 bytes   vtable slot 0x44   sig ()i
' byte-identical vs NSS5.exe (179/179, original length from Ghidra's inventory)
' no assumptions -- no Globals, no indirect calls. Fields 0x44/0x48/0x4c are
' strength:Float / form:Int[] / prize:Int from the object model.
' TWO shapes were needed and both were measured:
'  * the per-form add is a Select, not an If/ElseIf chain (an ElseIf chain reloads the
'    element into a fresh register and comes out short);
'  * `v` MUST be seeded on its own line. Written as `Local v:Int = 250000 + Int(x)*10000`
'    bcc canonicalises to expr-then-`add eax,imm`, `v` never has to survive the
'    bbFloatToInt call, and it lands in EAX -> 165 bytes. Seeding first keeps `v` live
'    across the call, so it takes EBX and Self takes ESI (an extra push/pop and a
'    6-byte `add ebx,imm32` per Case) -> 179.
	Method GetValue:Int()
		Local v:Int = 250000
		v = v + Int(strength) * 10000
		For Local i:Int = 0 To 4
			Select form[i]
				Case 1
					v = v + 100000
				Case 2
					v = v + 80000
				Case 3
					v = v + 60000
				Case 4
					v = v + 40000
				Case 5
					v = v + 20000
				Case 6
					v = v + 10000
			End Select
		Next
		v = v + prize
		If v < 250000 Then v = 250000
		If v > 3000000 Then v = 3000000
		Return v
	End Method
