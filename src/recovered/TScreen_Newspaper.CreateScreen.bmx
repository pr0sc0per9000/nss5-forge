' TScreen_Newspaper.CreateScreen
' VA 0x00558C66   596 bytes   mode=reloc   byte-identical vs NSS5.exe
' KIND=Function (static, no implicit Self), SIG ()i, class-table slot 0x30
'
' ASSUMPTIONS  (module Global names are ours; the declared TYPES are load-bearing)
'   0x00C6822C g_screen_newspaper:TScreen  (construction site = TScreen.CreateScreen)
'   0x00C68230 g_np_bg1:TImage             ) same names as TScreen_Newspaper.Draw.bmx
'   0x00C68234 g_np_bg2:TImage             )
'   0x00C68240 g_np_heads:TImage[]         )
'   0x00C68248 g_np_star:TImage            )
'   0x00C6824C g_snd_newspaper:TSound      (assigned from LoadSoundChecked)
'   0x00C66768 g_pan_stable:TPanel         (same name/type as TScreen_Abilities.CreateScreen)
'   0x00C6EFDC g_screen_x:Int   0x00C6EFE0 g_screen_y:Int   (bare dword reads, no refcounts)
'   0x00C6F274 g_img_play:TImage           (passed as TButton.CreateButton's :TImage arg)
'   Class-table slots: 0x00C61C64 TScreen+0x38 CreateScreen, 0x00C63294 TPanel+0x88
'   CreatePanel, 0x00C623CC TButton+0x88 CreateButton, 0x00C6830C/0x00C68310 are this
'   Type's own Play/Draw so they are written bare.  Slot 0x40 on a TScreen = AddGadget.
'   E8: 0x004BC372 LoadImageChecked, 0x004BC564 LoadSoundChecked, 0x005AE38D
'   MidHandleImage, 0x004A7C20 bbStringConcat, 0x004A7AC0 bbStringFromInt,
'   0x004A8590 bbGCFree (inlined BBRELEASE, never written in source).
'
' MEASURED: the Hands_ loop is `To 4`, not `Until 5` (orig `cmp ebx,4 / jle`); that was the
' only byte wrong on the first attempt (first_diff 282).  The 4th CreateScreen argument is
' the empty function 0x005B95D0, i.e. a source Null.
'!Global g_screen_newspaper:TScreen
'!Global g_np_bg1:TImage
'!Global g_np_bg2:TImage
'!Global g_np_heads:TImage[]
'!Global g_np_star:TImage
'!Global g_snd_newspaper:TSound
'!Global g_pan_stable:TPanel
'!Global g_screen_x:Int
'!Global g_screen_y:Int
'!Global g_img_play:TImage
g_screen_newspaper = TScreen.CreateScreen("newspaper", Null, Draw, Null)
If Not g_np_bg1
	g_np_bg1 = LoadImageChecked("GameMedia/Images/Backgrounds/Newspaper.png", -1)
	g_np_bg2 = LoadImageChecked("GameMedia/Images/Backgrounds/NewspaperPhoto.png", -1)
	For Local i:Int = 0 To 4
		g_np_heads[i] = LoadImageChecked("GameMedia/Images/Backgrounds/Hands_" + (i + 1) + ".png", -1)
	Next
	g_np_star = LoadImageChecked("GameMedia/Images/Interface/Star128.png", -1)
	MidHandleImage(g_np_star)
	g_snd_newspaper = LoadSoundChecked("GameMedia/Sounds/Newspaper.ogg", 0)
End If
g_screen_newspaper.AddGadget(g_pan_stable)
g_screen_newspaper.AddGadget(TPanel.CreatePanel("pan_nav", "", 0, g_screen_y - 60, g_screen_x, 60, "FFFFFF", "FFFFFF", 3, 1.0, 0, 0, 1))
g_screen_newspaper.AddGadget(TButton.CreateButton("btn_play", "", g_screen_x - 130, g_screen_y - 50, 120, 40, 1, 3, "FFFFFF", "FFFFFF", g_img_play, Play, 1.0, 1, ""))
