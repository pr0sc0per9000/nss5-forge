' TScreen_ReportBoss.CreateScreen
' VA 0x00561930   1231 bytes   mode=reloc   byte-identical vs NSS5.exe
' KIND=Function, SIG ()i, class-table slot 0x30
' (1231/1231, original length from Ghidra's inventory; verified under NSS5_NO_LEARN=1,
'  reloc_masked=119)
'
' ASSUMPTIONS -- Global NAMES are ours, the declared TYPES are load-bearing.
'   0x00C68ADC g_reportboss_screen:TScreen     0x00C68AE4 g_reportboss_pan_nav:TPanel
'   0x00C68AE8 g_reportboss_pan_report:TPanel  0x00C68B04 g_reportboss_btn_play:TButton
'   0x00C68AEC g_reportboss_lbl_boss:TLabel    0x00C68AF0 ..._lbl_coachboss:TLabel
'   0x00C68AF4 ..._lbl_coachteam:TLabel        0x00C68AF8 ..._lbl_coachfans:TLabel
'   0x00C68AFC ..._lbl_coachsponsors:TLabel    0x00C68B00 ..._lbl_coachfame:TLabel
'   0x00C66768 g_pan_background:TPanel  (shared backdrop panel, many screens use it)
'   0x00C6EFDC g_screenwidth:Int   0x00C6EFE0 g_screenheight:Int  (as in TScreen.DoMessage)
'   0x00C6F274 g_img_play:TImage
'   Draw and ButtonPlay are siblings of TScreen_ReportBoss (class table +0x3C, +0x38),
'     both KIND=Function, so they are written unprefixed and passed as ()i callbacks.
'   TScreen slot 0x40 = AddGadget; TGadget slot 0x74 = AddChild.
' SHAPE NOTES
'   * `Local y:Int = 110` is REQUIRED and is the whole story of the 2-byte error.  The
'     original keeps a running y in ebx (`mov ebx,0x6E` / `add ebx,0x136` / two
'     `add ebx,0x28`) and pushes it as the y argument of all six labels.  Written with
'     the six literal y values (110/420/420/460/460/500) the body is 1233 bytes and
'     localise_diff splits it into 12 gaps summing to exactly +2 -- and the original
'     saves esi as well as ebx, which the literal form does not need.
'   * the y statements sit exactly where the original's `add ebx` instructions do:
'     `y :+ 310` after the lbl_ReportBoss store, `y :+ 40` after lbl_ReportCoachTeam and
'     again after lbl_ReportCoachSponsors.  `y :+ N` and `y = y + N` are byte-identical
'     for a register-allocated Local (section 6), so only the placement is load-bearing.
'   * the six AddChild calls come after ALL six labels are built, not interleaved.
' Body-only format: statements only, parameters are a0, a1, ...
'!Global g_screenwidth:Int
'!Global g_screenheight:Int
'!Global g_img_play:TImage
'!Global g_pan_background:TPanel
'!Global g_reportboss_screen:TScreen
'!Global g_reportboss_pan_nav:TPanel
'!Global g_reportboss_pan_report:TPanel
'!Global g_reportboss_lbl_boss:TLabel
'!Global g_reportboss_lbl_coachboss:TLabel
'!Global g_reportboss_lbl_coachteam:TLabel
'!Global g_reportboss_lbl_coachfans:TLabel
'!Global g_reportboss_lbl_coachsponsors:TLabel
'!Global g_reportboss_lbl_coachfame:TLabel
'!Global g_reportboss_btn_play:TButton
g_reportboss_screen = TScreen.CreateScreen("reportboss", Null, Draw, Null)
g_reportboss_screen.AddGadget(g_pan_background)
g_reportboss_pan_nav = TPanel.CreatePanel("pan_Nav", "", 0, g_screenheight - 60, g_screenwidth, 60, "FFFFFF", "FFFFFF", 3, 1.0, 0, 0, 1)
g_reportboss_screen.AddGadget(g_reportboss_pan_nav)
g_reportboss_btn_play = TButton.CreateButton("btn_play", "", g_screenwidth - 130, g_screenheight - 50, 120, 40, 1, 2, "FFFFFF", "FFFFFF", g_img_play, ButtonPlay, 1.0, 1, "")
g_reportboss_pan_nav.AddChild(g_reportboss_btn_play)
g_reportboss_pan_report = TPanel.CreatePanel("pan_Report", "", 400, 60, 400, 40, "FFFFFF", "FFFFFF", 3, 1.0, 0, 440, 0)
g_reportboss_screen.AddGadget(g_reportboss_pan_report)
Local y:Int = 110
g_reportboss_lbl_boss = TLabel.CreateLabel("lbl_ReportBoss", "", 410, y, 380, 300, 3, "888888", "FFFFFF", 1.0, 1, 0, 1, 1, Null, 1, 0, 0, 0, "", 0)
y :+ 310
g_reportboss_lbl_coachboss = TLabel.CreateLabel("lbl_ReportCoachBoss", "", 410, y, 185, 30, 3, "888888", "FFFFFF", 1.0, 1, 0, 1, 1, Null, 1, 0, 0, 0, "", 0)
g_reportboss_lbl_coachteam = TLabel.CreateLabel("lbl_ReportCoachTeam", "", 605, y, 185, 30, 3, "888888", "FFFFFF", 1.0, 1, 0, 1, 1, Null, 1, 0, 0, 0, "", 0)
y :+ 40
g_reportboss_lbl_coachfans = TLabel.CreateLabel("lbl_ReportCoachFans", "", 410, y, 185, 30, 3, "888888", "FFFFFF", 1.0, 1, 0, 1, 1, Null, 1, 0, 0, 0, "", 0)
g_reportboss_lbl_coachsponsors = TLabel.CreateLabel("lbl_ReportCoachSponsors", "", 605, y, 185, 30, 3, "888888", "FFFFFF", 1.0, 1, 0, 1, 1, Null, 1, 0, 0, 0, "", 0)
y :+ 40
g_reportboss_lbl_coachfame = TLabel.CreateLabel("lbl_ReportCoachFame", "", 410, y, 380, 30, 3, "888888", "FFFFFF", 1.0, 1, 0, 1, 1, Null, 1, 0, 0, 0, "", 0)
g_reportboss_pan_report.AddChild(g_reportboss_lbl_boss)
g_reportboss_pan_report.AddChild(g_reportboss_lbl_coachboss)
g_reportboss_pan_report.AddChild(g_reportboss_lbl_coachteam)
g_reportboss_pan_report.AddChild(g_reportboss_lbl_coachfans)
g_reportboss_pan_report.AddChild(g_reportboss_lbl_coachsponsors)
g_reportboss_pan_report.AddChild(g_reportboss_lbl_coachfame)
