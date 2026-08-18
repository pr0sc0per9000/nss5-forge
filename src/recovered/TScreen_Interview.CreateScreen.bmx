' TScreen_Interview.CreateScreen
' VA 0x0057AD87   898 bytes   byte-identical vs NSS5.exe (modulo the four masks)
' KIND=Function (static method on the Type, no implicit Self), SIG=()i, class-table slot 0x30
' ORACLE 898/898 under NSS5_NO_LEARN=1.
'
' ASSUMPTIONS / RESOLUTIONS
'  * Module Globals (names ours; ADDRESS + TYPE are the load-bearing parts):
'      g_iv_bg:TImage      0x00C6CDD0   g_iv_beep:TSound  0x00C6CDD4
'      g_iv_screen:TScreen 0x00C6CDD8   (slot 0x40 = TScreen.AddGadget)
'      g_iv_panel:TPanel   0x00C6CDDC   (slot 0x74 = TGadget.AddChild, INHERITED)
'      g_iv_label:TLabel   0x00C6CDE0   g_iv_btnok:TButton 0x00C6CDE4
'      g_pan_title:TPanel  0x00C66768   g_img_iv:TImage    0x00C6F1B8
'      g_screenwidth:Int   0x00C6EFDC   g_screenheight:Int 0x00C6EFE0
'        (both are bare dword reads with no refcount traffic -> Int, rule 11.2)
'  * Class-table slots: 0x00C61C64 TScreen+0x38 CreateScreen, 0x00C63294 TPanel+0x88
'    CreatePanel(13 args), 0x00C634C0 TLabel+0x88 CreateLabel(21 args), 0x00C623CC
'    TButton+0x88 CreateButton(15 args).  0x00C6CF44/0x00C6CF50/0x00C6CF5C are THIS Type's
'    own table (+0x38 ButtonAddText, +0x44 Update, +0x50 ButtonOk), so those callbacks are
'    written bare with no `TScreen_Interview.` prefix.
'  * Four Locals x/y/w/h are REAL: the prologue is `sub esp,0x14` (5 slots) and the four
'    initialisers are emitted as `mov dword [ebp-0x14],0x87` ... `mov [ebp-4],0x28` before
'    the first CreatePanel.  The fifth slot [ebp-0xC] is the outer For counter; the inner
'    counter and `n` take esi/edi.  `y :+ 50` / `x :+ 10` / `y :+ 90` emit
'    `add dword [ebp-N],imm` -- a memory operand, so the `:+` spelling is load-bearing (6).
'  * Guard is `If Not g_iv_bg` -- the setne/movzx/cmp/jne shape of rule 10.3, not `= Null`.
'  * Empty-string forms are NOT interchangeable in the data section (see
'    TScreen_Continents.CreateScreen): 0x005C7D40 is the runtime's shared bbEmptyString and
'    is what source `Null` lowers to in a `$` parameter; 0x00C5D284 is a bcc-pooled literal
'    and is what `""` lowers to.  Here the label text, both CreatePanel/CreateButton name
'    slots at 0x00C5D284 are `""`, while CreateLabel's 20th argument, CreateButton's 2nd
'    (in the loop) and its 15th are 0x005C7D40 -> `Null`.  The oracle masks both.
'  * `LoadImageChecked(path, -1)` / `LoadSoundChecked(path, 0)` are the recovered module
'    Functions at 0x004BC372 / 0x004BC564 (both take the flags argument explicitly).
'  * The button grid is `y + row*(h+10)` and `x + col*(w+10)`, read straight off the
'    mov/add/imul/add sequences; the `"btn_" + String(n)` first argument is evaluated LAST
'    (16.2), which is why no Local is needed for it.
'  * Literal CONTENT is not certified by the MATCH; all were read with harness.read_string.
'!Global g_iv_bg:TImage
'!Global g_iv_beep:TSound
'!Global g_iv_screen:TScreen
'!Global g_iv_panel:TPanel
'!Global g_iv_label:TLabel
'!Global g_iv_btnok:TButton
'!Global g_pan_title:TPanel
'!Global g_img_iv:TImage
'!Global g_screenwidth:Int
'!Global g_screenheight:Int
	Function CreateScreen()
		If Not g_iv_bg
			g_iv_bg = LoadImageChecked("GameMedia/Images/Backgrounds/Interview.png", -1)
			g_iv_beep = LoadSoundChecked("GameMedia/Sounds/Beep.ogg", 0)
		End If
		g_iv_screen = TScreen.CreateScreen("interview", g_iv_bg, Null, Update)
		g_iv_screen.AddGadget(g_pan_title)
		Local x:Int = 135
		Local y:Int = 110
		Local w:Int = 163
		Local h:Int = 40
		g_iv_panel = TPanel.CreatePanel("pan_Interview", GetText("Interview"), x, y, 530, 40, "FFFFFF", "FFFFFF", 3, 0.8, 1, 350, 0)
		y :+ 50
		g_iv_screen.AddGadget(g_iv_panel)
		x :+ 10
		g_iv_label = TLabel.CreateLabel("lbl_Sentence", "", x, y, 510, 80, 3, "888888", "FFFFFF", 1.0, 1, 0, 1, 1, Null, 1, 0, 0, 0, Null, 0)
		y :+ 90
		g_iv_panel.AddChild(g_iv_label)
		Local n:Int = 1
		For Local row:Int = 0 To 4
			For Local col:Int = 0 To 2
				g_iv_panel.AddChild(TButton.CreateButton("btn_" + String(n), Null, x + col * (w + 10), y + row * (h + 10), w, h, 1, 2, "FFFFFF", "FFFFFF", Null, ButtonAddText, 1.0, 1, Null))
				n :+ 1
			Next
		Next
		g_iv_screen.AddGadget(TPanel.CreatePanel("navpanel", "", 0, g_screenheight - 60, g_screenwidth, 60, "FFFFFF", "FFFFFF", 3, 1.0, 0, 0, 0))
		g_iv_btnok = TButton.CreateButton("btn_ok", "", 670, g_screenheight - 50, 120, 40, 1, 2, "FFFFFF", "FFFFFF", g_img_iv, ButtonOk, 1.0, 1, GetText("tt_Proceed"))
		g_iv_screen.AddGadget(g_iv_btnok)
	End Function
