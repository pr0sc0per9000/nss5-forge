' TDummy.CheckHit  -- Method, slot 0x50, sig ()i
' VA 0x005834FD   269 bytes   (original length from Ghidra's inventory)
' ORACLE: MATCH mode=reloc  269/269  reloc_masked=11
'
' ASSUMPTIONS / RESOLUTIONS
'   PTR_FUN_00C5AEDC = TBall classtable (0x00C5AE98) + 0x44  -> TBall.GetActiveBall():TBall
'   PTR_FUN_00C5D998 = TPitch classtable + 0x6C              -> TPitch.YardsToPixels(f):f
'   FUN_00505DA2 = Dist2D  (src/recovered_module/Dist2D.bmx)
'   FUN_0059F089 = _brl_random_Rand   -> Rand(160,200)
'   FUN_0059B25E = _brl_audio_PlaySound
'   _DAT_00C92B44 = 0.6 (float constant, read out of NSS5.exe .data)
'   Globals (names ours, types load-bearing):
'     0x00C6D7C4 -> g_snd_dummyhit:TSound     (first  PlaySound arg)
'     0x00C5B344 -> g_channel_sfx:TChannel    (second PlaySound arg)
'     globals_final.tsv types both as bare 'Object'; TSound/TChannel are forced by
'     PlaySound's BRL signature and both are pushed with no refcount traffic at the
'     call site, consistent with plain Global reads.
'   Fields via TTrainingObject (TDummy Extends TTrainingObject, TDummy adds none):
'     frame +0x0C, x +0x10, y +0x14, alive +0x18
'   `If Self.alive = 0 Then Return 0` is the early-return guard shape of §3f
'   (cmp dword [esi+0x18],0 / jne / mov eax,0 / jmp end), not an If-block.
'   `If b And ... And ...` short-circuits through the setne/movzx truth-test form (§10.3);
'   the two [ebp-8]/[ebp-0xc] float spills are compiler temps, not source Locals.
	Method CheckHit:Int()
		'!Global g_snd_dummyhit:TSound
		'!Global g_channel_sfx:TChannel
		If Self.alive = 0 Then Return 0
		Local b:TBall = TBall.GetActiveBall()
		If b And Dist2D(Self.x, Self.y, b.x, b.y) < TPitch.YardsToPixels(1.0) And b.z < TPitch.YardsToPixels(3.75) Then
			Self.alive = 0
			Self.frame = 1
			If Not b.controlledby Then
				b.direction = b.direction + Rand(160, 200)
				b.velocity = b.velocity * 0.6
			EndIf
			PlaySound(g_snd_dummyhit, g_channel_sfx)
		EndIf
		Return 0
	End Method
