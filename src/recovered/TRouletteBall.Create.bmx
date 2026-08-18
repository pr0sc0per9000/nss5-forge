' TRouletteBall.Create
' VA 0x00575e64   110 bytes   vtable slot 0x30   sig ():TRouletteBall
' byte-identical vs NSS5.exe (110/110, original length from Ghidra's inventory, mode=reloc)
' Assumptions: Global 0x00C6BE58 declared TImage -- globals_final.tsv calls it TRouletteBall,
'   but the code passes it to MidHandleImage and assigns it from LoadImageChecked, so it is
'   the ball sprite, not a ball object (see codegen-patterns 10.7: trust the code).
'   FUN_004BC372 = recovered module Function LoadImageChecked($,i):TImage.
'   Guard is the `If Not x` emission (mov/cmp/setne/movzx/cmp/jne), not `If x = Null`.
'!Global g_roulette_ballimage:TImage
	Function Create:TRouletteBall()
		Local b:TRouletteBall = New TRouletteBall
		If Not g_roulette_ballimage
			g_roulette_ballimage = LoadImageChecked("GameMedia/Images/Casino/Roulette/Ball.png", -1)
			MidHandleImage(g_roulette_ballimage)
		End If
		Return b
	End Function
