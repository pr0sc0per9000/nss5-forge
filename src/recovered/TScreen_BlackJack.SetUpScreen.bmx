' TScreen_BlackJack.SetUpScreen
' VA 0x0057683D   139 bytes   mode=reloc   MATCH 139/139
' KIND=Function (static method on TScreen_BlackJack), SIG=()i, SLOT=0x34
' Body-only format: statements only, parameters are a0, a1, ...
'
' ASSUMPTIONS
'   Globals declared here (names are ours; originals are unrecoverable):
'     0x00C6B858 -> g_bj_panel:TPanel    (globals_final: TPanel, construction, medium)
'     0x00C6C01C -> g_bj_btn1:TButton    (globals_final: TButton, construction, medium)
'     0x00C6C028 -> g_bj_btn2:TButton    (globals_final: TButton, construction, medium)
'     0x00C6C020 -> g_bj_btn3:TButton    (globals_final: TButton, construction, medium)
'     0x00C6C024 -> g_bj_btn4:TButton    (globals_final: TButton, construction, medium)
'     0x00C6C018 -> g_bj_screen:TScreen  (globals_final: TScreen, construction, medium)
'   Slots resolved (inherited slots walked through class_tables.tsv Extends):
'     [0xC61C88] = TScreen+0x5C          -> TScreen.SetActive($,$):TScreen
'     [0xC66914] = TScreen_GameMenu+0x38 -> TScreen_GameMenu.UpdateTitlePanel()i
'     [0xC6BA3C] = TScreen_Casino+0x50   -> TScreen_Casino.ShowTitleButtons()i
'     [0xC6C320] = TBlackJack+0x38       -> TBlackJack.Reset()i
'     slot 0x58 on TPanel/TButton        -> TGadget.Show()i     (inherited)
'     slot 0x54 on TButton               -> TGadget.Hide()i     (inherited)
'     slot 0x60 on TScreen               -> TScreen.SetActiveGadget($)i  (Function, so the
'                                           call site pushes no Self -- matches the original)
'   String literals read out of the exe with harness.read_string:
'     0x00C90C2C = "blackjack"   0x00C5D284 = ""   0x00C81674 = "btn_play"
' byte-identical vs NSS5.exe
'!Global g_bj_panel:TPanel
'!Global g_bj_btn1:TButton
'!Global g_bj_btn2:TButton
'!Global g_bj_btn3:TButton
'!Global g_bj_btn4:TButton
'!Global g_bj_screen:TScreen
TScreen.SetActive("blackjack","")
TScreen_GameMenu.UpdateTitlePanel()
TScreen_Casino.ShowTitleButtons()
g_bj_panel.Show()
g_bj_btn1.Show()
g_bj_btn2.Show()
g_bj_btn3.Hide()
g_bj_btn4.Hide()
g_bj_screen.SetActiveGadget("btn_play")
TBlackJack.Reset()
