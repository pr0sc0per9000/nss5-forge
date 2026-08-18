' TTrainingZone.Create
' VA 0x00583cf6   227 bytes   vtable slot 0x48   sig (i,i,f,$,$):TTrainingZone
' byte-identical vs NSS5.exe (227/227, original length from Ghidra's inventory)
' ASSUMPTIONS: module Global 0x00c6d9f4 declared TImage (globals_final.tsv has it as bare
' Object). FUN_004bc372 is the recovered module Function LoadImageChecked($,i):TImage;
' FUN_005ae38d = _brl_max2d_MidHandleImage. Fields colour/txt are TTrainingZone's own
' (+0x24/+0x28); img/x/y/scl are inherited from TTrainingObject. The image filename literal
' is a masked address; its VALUE is not proven.
'
' NOTE: the lazy-load guard is the "If Not x" emission (setne al / movzx / cmp / jne,
' 21 bytes), NOT "If x = Null" (12 bytes) -- the "= Null" form comes out 218.
' All the inc/dec [x+4] pairs in the decompilation are inlined retain/release around the
' String and TImage field stores, not source. harness mode=reloc, 15 addresses masked.
	Function Create:TTrainingZone(a0:Int, a1:Int, a2:Float, a3:String, a4:String)
		'!Global g_zoneimg:TImage
		If Not g_zoneimg
			g_zoneimg = LoadImageChecked("EngineMedia/Match/Pitch/Zone.png", -1)
			MidHandleImage(g_zoneimg)
		End If
		Local z:TTrainingZone = New TTrainingZone
		z.img = g_zoneimg
		z.x = a0
		z.y = a1
		z.scl = a2
		z.colour = a3
		z.txt = a4
		Return z
	End Function
