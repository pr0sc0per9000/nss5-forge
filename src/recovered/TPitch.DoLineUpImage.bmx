' TPitch.DoLineUpImage
' VA 0x004E9ACE   804 bytes   mode=reloc   byte-identical vs NSS5.exe (804/804,
' original length from Ghidra's inventory, reloc_masked=35)
' KIND=Function, SIG ()i, class-table slot 0x54
'
' ASSUMPTIONS
'   0x00C596F0 g_nations:TList (established name, see TNation.SelectById.bmx)
'   0x00C596F4 g_nation_int01:Int -- set to 1 right after `New TPlayer[64]`; original
'     writes it via a bare 10-byte `mov dword [addr],1` with no refcount traffic, so
'     it is a plain flag, not the object globals_final.tsv guesses it might be near.
'   0x00C6EFE4 g_engine_int162:Int, 0x00C6EFE8 g_engine_int163:Int -- screen width/
'     height read straight into DrawRect(0,0,w,h), matching their usage elsewhere
'     (e.g. TCombo.DrawItems.bmx).
'   `s__TPlayer_00c78854` (the array's element-type descriptor) is simply
'   `New TPlayer[64]` -- a local lineup array, one slot per nation id (1..64).
'
' SHAPE NOTES
'   * Both `For n:TNation = EachIn g_nations` loops terminate with an explicit
'     `If n.id = 63 Then Exit` INSIDE the loop body rather than running until
'     HasNext() is exhausted. Ghidra folds this into the loop's own back-edge test
'     (`do { ... } while (id != 0x3f)`) because the Exit target and the natural
'     loop-exit target coincide; the true source shape is the If/Exit form.
'   * TList.Sort() -- second loop's TNation.Compare-based comparator is bcc filling
'     in Sort's default `compareFunc` argument; written with no arguments here.
'   * First loop uses `n.id - 1` fresh at every array-index site (five of them) --
'     bcc does no CSE (codegen-patterns 6), and the byte count only matches when
'     each occurrence re-derives the field rather than being hoisted to a Local.
'   * Second loop DOES cache `n.id` into `Local id:Int` and reuses it across all
'     four coordinate expressions (but NOT for the trailing `If n.id = 63` exit
'     test, which re-reads the field fresh) -- the tell is the original caching
'     the value in a register (`mov ebx,[esi+0xc]` once) instead of re-loading it;
'     omitting this Local costs exactly one stack slot (missing from `sub esp,N`)
'     and 4 bytes (one `mov eax,[esi+0xc]` vs `mov eax,ebx` per use).
'   * `n.id / 2` is the sign-safe halving idiom bcc emits for signed `/2`
'     (same idiom as TScreen.DoMessageGetText's `g_screenheight / 2`).
'   * The trailing `Flip(-1)` + escape check is `Repeat ... Until KeyHit(27)`, NOT
'     `If KeyHit(27) Then Return 0` followed by `Forever` -- both are semantically
'     identical (KeyHit(27) precedes fresh iterations either way) but `Until`
'     lets bcc fold the false-branch into a single near `je` straight back to the
'     loop top; the `If/Forever` phrasing costs 1 extra byte (a short je into a
'     landing pad holding a separate unconditional near jmp).
' Body-only format: statements only.
	Function DoLineUpImage:Int()
		'!Global g_nations:TList
		'!Global g_nation_int01:Int
		'!Global g_engine_int162:Int
		'!Global g_engine_int163:Int
		Local players:TPlayer[64]
		g_nation_int01 = 1
		g_nations.Sort()
		For Local n:TNation = EachIn g_nations
			LogLine(String(n.id - 1))
			players[n.id - 1] = New TPlayer
			players[n.id - 1].skincol = n.primaryskin
			players[n.id - 1].bootcol = KitColour(-1)
			players[n.id - 1].PaintPlayer(TKit.CreateKit(n.kitcolsHome, "EngineMedia\Match\Player\Player.png"))
			If n.id = 63 Then Exit
		Next
		SetScale(1.0, 1.0)
		SetBlend(3)
		SetAlpha(1.0)
		Repeat
			Cls()
			SetColor(0, 100, 0)
			DrawRect(0, 0, g_engine_int162, g_engine_int163)
			SetColor(255, 255, 255)
			For Local n:TNation = EachIn g_nations
				Local id:Int = n.id
				DrawImage(players[id - 1].imgPlayer, (id / 2) * 64 + 64, (id Mod 2 + 1) * 200, 128)
				DrawImage(n.imgFlagSmall, (id / 2) * 64 + 32, (id Mod 2 + 1) * 230, 0)
				If n.id = 63 Then Exit
			Next
			Flip(-1)
		Until KeyHit(27)
	End Function
