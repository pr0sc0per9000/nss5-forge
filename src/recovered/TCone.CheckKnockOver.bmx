' TCone.CheckKnockOver  ()i   slot 0x4c
' VA 0x00582fef   581 bytes   vtable slot 0x4c   sig ()i
' byte-identical vs NSS5.exe (581/581, original length from Ghidra's inventory)
' VA 0x00582FEF   length 581   oracle: MATCH mode=reloc 581/581 reloc_masked=22
'
' TCone Extends TTrainingObject, so img/frame/x/y/alive come from the Super (+0x08..+0x18);
' only `fallen` (+0x24) is TCone's own.
'
' Assumptions:
'   '!Global g_scale:Float    0x00C5DE44  (globals_final: Float, usage/high, x87 dword access;
'                              value in the exe is 0.0). Pushed as both scale arguments of
'                              ImagesCollide2 for BOTH images.
'   '!Global g_sndcone:TSound  0x00C6D6C4 (globals_final: Object/low; PlaySound arg 1 => TSound)
'   '!Global g_chncone:TChannel 0x00C5B344 (globals_final: Object/low; PlaySound arg 2 => TChannel)
'   TBall.GetActiveBall   = classtable TBall  + 0x44  (PTR_FUN_00C5AEDC)
'   TPitch.YardsToPixels  = classtable TPitch + 0x6c  (PTR_FUN_00C5D998)
'   TPlayer.GetHumanPlayer= classtable TPlayer+ 0x164 (PTR_FUN_00C5FAB0)
'   TPlayer.PlayerSliding = slot 0x1b0 on TPlayer
'   FUN_005AE59E = _brl_max2d_ImagesCollide2 (brl_functions.tsv). Ghidra MERGES the
'     _bbFloatToInt pushes into it; the real argument list is the 14 read off the pushes:
'     (image1,x1,y1,frame1,rot1,scalex1,scaley1, image2,x2,y2,frame2,rot2,scalex2,scaley2).
'   FUN_0059F089 = Rand, FUN_0059B25E = PlaySound, FUN_005B9690 = _bbFloatToInt i.e. Int(x).
'   0.6 is the .rdata float at 0x00C92AD8 (0x3F19999A), read out of NSS5.exe. That operand
'     is an absolute address and is MASKED, so the match does not prove the value.
'
' Shape notes (each one was measured, each cost a length):
'   `If Self.alive = 0 Then Return 0` is an EARLY RETURN; as an enclosing If block it is
'     6 bytes short.
'   `If Not b.controlledby` (mov/cmp/setne/movzx/cmp/jne, 19 bytes) NOT `= Null`
'     (cmp mem,imm/jne, 9 bytes) -- this alone was the last 10 bytes.
'   The fallen assignment is `If b.x < Self.x` / `If p.x < Self.x`: Ghidra prints
'     `Self.x <= b.x`, which builds the same setcc from the OTHER operand order
'     (ours setbe on (Self.x,b.x) vs original setae on (b.x,Self.x)) -- same length,
'     different bytes. Guide 10.1.
Method CheckKnockOver()
	'!Global g_scale:Float
	'!Global g_sndcone:TSound
	'!Global g_chncone:TChannel
	If Self.alive = 0 Then Return 0
	Local knocked:Int = 0
	Local b:TBall = TBall.GetActiveBall()
	If b <> Null And Dist2D(Self.x, Self.y, b.x, b.y) < TPitch.YardsToPixels(0.75) And b.z < TPitch.YardsToPixels(1.0)
		knocked = 1
		If b.x < Self.x
			Self.fallen = 135
		Else
			Self.fallen = -135
		EndIf
		If Not b.controlledby
			b.direction = b.direction + Rand(160, 200)
			b.velocity = b.velocity * 0.6
		EndIf
	EndIf
	If Not knocked And Self.frame = 2
		Local p:TPlayer = TPlayer.GetHumanPlayer()
		If p <> Null And p.PlayerSliding() And ImagesCollide2(p.imgPlayer, Int(p.x), Int(p.y), p.frame, p.spriterotation, g_scale, g_scale, Self.img, Int(Self.x), Int(Self.y), 0, 0, g_scale, g_scale)
			knocked = 1
			If p.x < Self.x
				Self.fallen = 135
			Else
				Self.fallen = -135
			EndIf
		EndIf
	EndIf
	If knocked
		Self.frame = 0
		Self.alive = 0
		PlaySound(g_sndcone, g_chncone)
	EndIf
End Method
