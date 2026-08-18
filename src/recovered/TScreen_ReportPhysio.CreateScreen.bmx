' TScreen_ReportPhysio.CreateScreen
' VA 0x00561507   578 bytes  mode=reloc  byte-identical vs NSS5.exe (578/578, length from Ghidra)
' KIND=Function (static, no implicit Self), SIG ()i, class-table slot 0x30
' ASSUMPTIONS (addresses are fact, NAMES are ours -- module Globals have no debug record)
'  * 0x00C68A00 g_screen_reportphysio:TScreen  (construction site = TScreen.CreateScreen)
'  * 0x00C66768 g_pan_stable:TPanel   (same name/type as TScreen_Abilities.CreateScreen)
'  * 0x00C68A08 g_pan_physionav:TPanel     0x00C68A0C g_pan_physioreport:TPanel
'  * 0x00C68A10 g_lbl_physioreport:TLabel  0x00C68A14 g_btn_physioplay:TButton
'  * 0x00C6F274 g_img_play:TImage   (name already established elsewhere in the corpus)
'  * 0x00C6EFDC g_screenwidth:Int   0x00C6EFE0 g_screenheight:Int  (bare dword reads)
'  * Class-table slots: 0x00C61C64 TScreen+0x38 CreateScreen; 0x00C63294 TPanel+0x88
'    CreatePanel; 0x00C623CC TButton+0x88 CreateButton; 0x00C634C0 TLabel+0x88 CreateLabel;
'    0x00C68AD4/0x00C68AD8 are this Type's own ButtonPlay/Draw -> bare names.
'    slot 0x40 on a TScreen = TScreen.AddGadget; slot 0x74 on a TPanel = TGadget.AddChild.
'  * The 4th CreateScreen argument and the trailing Null image are both the empty-function /
'    null constant bcc emits (0x005B95D0 / 0x00C5D284); source is Null either way.
'  * String literals read out of NSS5.exe with harness.read_string; the oracle masks a
'    literal's ADDRESS, so their contents are not certified by the MATCH.

	Function CreateScreen()
		'!Global g_screen_reportphysio:TScreen
		'!Global g_pan_stable:TPanel
		'!Global g_pan_physionav:TPanel
		'!Global g_pan_physioreport:TPanel
		'!Global g_lbl_physioreport:TLabel
		'!Global g_btn_physioplay:TButton
		'!Global g_img_play:TImage
		'!Global g_screenwidth:Int
		'!Global g_screenheight:Int
		g_screen_reportphysio = TScreen.CreateScreen("reportphysio", Null, Draw, Null)
		g_screen_reportphysio.AddGadget(g_pan_stable)
		g_pan_physionav = TPanel.CreatePanel("pan_Nav", "", 0, g_screenheight - 60, g_screenwidth, 60, "FFFFFF", "FFFFFF", 3, 1.0, 0, 0, 1)
		g_screen_reportphysio.AddGadget(g_pan_physionav)
		g_btn_physioplay = TButton.CreateButton("btn_play", "", g_screenwidth - 130, g_screenheight - 50, 120, 40, 1, 2, "FFFFFF", "FFFFFF", g_img_play, ButtonPlay, 1.0, 1, "")
		g_pan_physionav.AddChild(g_btn_physioplay)
		g_pan_physioreport = TPanel.CreatePanel("pan_Report", "", 400, 60, 400, 40, "FFFFFF", "FFFFFF", 3, 1.0, 0, 440, 0)
		g_screen_reportphysio.AddGadget(g_pan_physioreport)
		g_lbl_physioreport = TLabel.CreateLabel("lbl_Report", "", 410, 110, 380, 420, 4, "888888", "FFFFFF", 1.0, 1, 0, 1, 1, Null, 1, 0, 0, 0, "", 0)
		g_screen_reportphysio.AddGadget(g_lbl_physioreport)
	End Function
