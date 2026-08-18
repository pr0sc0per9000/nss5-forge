' TScreen_SeasonReview.CreateScreen  -- KIND=Function, sig ()i, slot 0x30
' VA 0x0055F51E   968 bytes
' byte-identical vs NSS5.exe (968/968, original length from Ghidra's inventory, mode=reloc,
' reloc_masked=96)
'
' ASSUMPTIONS
'   Globals (names ours; addresses are the load-bearing fact):
'     g_seasonreview_screen:TScreen   0x00C687C4
'     g_screenwidth:Int   0x00C6EFDC   g_screenheight:Int   0x00C6EFE0   (established names,
'         same addresses TScreen.CreateScreen/DoMessage/DoHelp etc. already use)
'     g_img_play:TImage   0x00C6F274   (established name, same address TScreen.DoMessage uses
'         for its own accept icon -- shared across screens)
'     g_shared_panel1:TPanel   0x00C66F18   -- UNCERTAIN semantics: TScreen_Leagues.CreateScreen
'         writes its OWN "pan_table" object to this exact address (named g_leagues_panTable
'         there). This function only READS it (never constructs it), so whatever object last
'         populated that slot is what gets added to the Season Review screen. The address and
'         the fact that it is read-only here are the load-bearing facts for codegen; the
'         cross-Type coincidence is preserved faithfully, not resolved.
'     g_sr_panStats:TPanel      0x00C687C8   g_sr_tblSeason:TTable       0x00C687CC
'     g_sr_panTournaments:TPanel 0x00C687D0  g_sr_tblTournaments:TTable  0x00C687D4
'   Class-table slots: 0x00C61C64 TScreen+0x38 CreateScreen; 0x00C63294 TPanel+0x88
'     CreatePanel; 0x00C623CC TButton+0x88 CreateButton; 0x00C62BAC TTable+0x88 CreateTable;
'     TScreen+0x40 = AddGadget; TGadget+0x74 = AddChild; TTable+0x90 = AddColumn.
'     0x00C688D4 = TScreen_SeasonReview+0x40 = ButtonPlay (already recovered separately;
'     referenced here bare, same-Type callback convention as every other CreateScreen/
'     ButtonXxx pair in the corpus).
'   0x005B95D0 = the empty function = source-level Null for an ()i callback/image slot.
'   Empty strings are the pooled literal (0x00C5D284), so `""`, not `Null`.
'   Literals: 1.0 = 0x3F800000. Every other numeric literal (60, 130, 50, 120, 40, 410, 70,
'     380, 30, 138, 170, 220, 280, 310) is read directly out of the immediate operands.
'
' CODEGEN NOTES
'   The first four AddGadget calls (pan_title, pan_nav, btn_play, g_shared_panel1) each
'   RE-READ g_seasonreview_screen fresh from the Global immediately before their own call --
'   there is no cached Local for the screen anywhere in this function, confirmed by the
'   original re-loading it into ebx (then eax) before every single call. Do not "clean up"
'   by introducing a Local here; it costs exactly 6 bytes per call removed (measured).
'   `Local x:Int = 410`, `Local y:Int = 70`, `Local w:Int = 380` ARE real (guide 16.3): the
'   prologue's `sub esp,4` plus three saved registers materialises them with explicit stores
'   right after the fourth AddGadget call, and `y` is then genuinely MUTATED in place with
'   three separate `:+` steps between the panel/table constructions (+30, +180, +30) rather
'   than four independent literals -- 70, 100, 280, 310. `x` (410) and `w` (380) are reused
'   unchanged throughout. Placing the `y :+ N` step BEFORE the following AddGadget/AddChild
'   call (not after) is also load-bearing; the increment's basic block sits between the
'   panel's construction and its use as an argument.
'!Global g_seasonreview_screen:TScreen
'!Global g_screenwidth:Int
'!Global g_screenheight:Int
'!Global g_img_play:TImage
'!Global g_shared_panel1:TPanel
'!Global g_sr_panStats:TPanel
'!Global g_sr_tblSeason:TTable
'!Global g_sr_panTournaments:TPanel
'!Global g_sr_tblTournaments:TTable
	Function CreateScreen:Int()
		g_seasonreview_screen = TScreen.CreateScreen("seasonreview", Null, Null, Null)
		g_seasonreview_screen.AddGadget(TPanel.CreatePanel("pan_title", GetText("Season Review"), 0, 0, g_screenwidth, 60, "FFFFFF", "FFFFFF", 4, 1.0, 0, 0, 1))
		g_seasonreview_screen.AddGadget(TPanel.CreatePanel("pan_nav", "", 0, g_screenheight - 60, g_screenwidth, 60, "FFFFFF", "FFFFFF", 3, 1.0, 0, 0, 0))
		g_seasonreview_screen.AddGadget(TButton.CreateButton("btn_play", "", g_screenwidth - 130, g_screenheight - 50, 120, 40, 1, 3, "FFFFFF", "FFFFFF", g_img_play, ButtonPlay, 1.0, 1, ""))
		g_seasonreview_screen.AddGadget(g_shared_panel1)
		Local x:Int = 410
		Local y:Int = 70
		Local w:Int = 380
		g_sr_panStats = TPanel.CreatePanel("pan_SeasonStats", GetText("Season Stats"), x, y, w, 30, "FFFFFF", "FFFFFF", 3, 1.0, 1, 170, 0)
		y :+ 30
		g_seasonreview_screen.AddGadget(g_sr_panStats)
		g_sr_tblSeason = TTable.CreateTable("tbl_SeasonTable", x, y, 7, 0, 0, 2, "00FF00", 1.0, 1, Null)
		g_sr_tblSeason.AddColumn(138, "", "000000", "FFFFFF", 2)
		g_sr_tblSeason.AddColumn(120, GetText("Club"), "000000", "EEEEEE", 1)
		g_sr_tblSeason.AddColumn(120, GetText("International"), "000000", "DDDDDD", 1)
		g_sr_panStats.AddChild(g_sr_tblSeason)
		y :+ 180
		g_sr_panTournaments = TPanel.CreatePanel("pan_SeasonTournaments", GetText("Tournaments and Awards"), x, y, w, 30, "FFFFFF", "FFFFFF", 3, 1.0, 1, 220, 0)
		y :+ 30
		g_seasonreview_screen.AddGadget(g_sr_panTournaments)
		g_sr_tblTournaments = TTable.CreateTable("tbl_SeasonTournaments", x, y, 7, 0, 0, 2, "00FF00", 1.0, 0, Null)
		g_sr_tblTournaments.AddColumn(380, GetText("Stats"), "000000", "FFFFFF", 0)
		g_sr_panTournaments.AddChild(g_sr_tblTournaments)
	End Function
