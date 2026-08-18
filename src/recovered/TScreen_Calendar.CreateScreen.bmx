' TScreen_Calendar.CreateScreen
' VA 0x0053631C   836 bytes   byte-identical vs NSS5.exe (modulo the four masks)
' KIND=Function (static method on the Type, no implicit Self), SIG=()i, class-table slot 0x30
' ORACLE 836/836 under NSS5_NO_LEARN=1.
'
' ASSUMPTIONS / RESOLUTIONS
'  * Module Globals (names ours; the ADDRESS and the TYPE are the load-bearing parts):
'      g_calendar_screen:TScreen at 0x00C65E2C  (slot 0x40 = TScreen.AddGadget)
'      g_calendar_table:TTable   at 0x00C65E34  (slot 0x90 = TTable.AddColumn(i,$,$,$,i))
'      g_pathPrefix:String       at 0x00C6E950  (the shared install-path prefix; the same
'                                Global src/recovered_module/LoadImageChecked.bmx declares)
'  * Class-table slots: 0x00C61C64 = TScreen+0x38 CreateScreen($,:TImage,()i,()i),
'    0x00C623CC = TButton+0x88 CreateButton (15 args), 0x00C62BAC = TTable+0x88 CreateTable
'    (11 args).  0x00C65EE0 is THIS Type's own table (+0x38 = ButtonQuit), so the callback
'    is written bare, with no `TScreen_Calendar.` prefix.
'  * `Local w:Int = 100` is REAL, not an artefact: the original emits `mov esi,0x64` once,
'    between the second AddGadget and the CreateTable, and passes esi as the width of all
'    seven day columns.  bcc does no constant CSE, so a repeated literal 100 would emit
'    seven `push 0x64`s -- the register means a Local, and its position in the emission
'    order pins the declaration to just before the CreateTable statement.
'  * Empty-string form: the pushed BBString is 0x005C7D40 (the runtime's shared
'    bbEmptyString), which per TScreen_Continents.CreateScreen is what source-level `Null`
'    lowers to in a `$` parameter -- so CreateButton's 15th argument is `Null`, not `""`.
'    The oracle masks the address either way; this preserves the data-section reference.
'  * `LoadImage(...)` emits `push -1` for its default `flags` argument; `TScreen.CreateScreen`
'    and `TTable.CreateTable`'s `()i` Null is 0x005B95D0, the empty function.
'  * 0x004C5549 = GetText (module Function, ONE argument -- Ghidra merges the following
'    pushes into it), 0x004A7C20 = _bbStringConcat, 0x004A7C90 = _bbStringSlice
'    (`GetText(k)[..3]`), 0x004A8590 = _bbGCFree (the inlined BBRELEASE of each Global's
'    old value, never written in source), 0x005AE256 = LoadImage.
'  * String literal CONTENT is not certified by the MATCH (the addresses are masked); all
'    23 literals below were read out of NSS5.exe with harness.read_string.
'!Global g_calendar_screen:TScreen
'!Global g_calendar_table:TTable
'!Global g_pathPrefix:String
	Function CreateScreen()
		g_calendar_screen = TScreen.CreateScreen("calendar", LoadImage(g_pathPrefix + "GameMedia/Images/Backgrounds/Grass.png"), Null, Null)
		g_calendar_screen.AddGadget(TButton.CreateButton("pan_title", GetText("Calendar"), 0, 0, 800, 40, 0, 3, "EEEEEE", "FFFFFF", Null, Null, 1.0, 0, Null))
		g_calendar_screen.AddGadget(TButton.CreateButton("quit", GetText("Back"), 690, 10, 100, 20, 1, 2, "FF0000", "000000", Null, ButtonQuit, 1.0, 1, Null))
		Local w:Int = 100
		g_calendar_table = TTable.CreateTable("tbl_Calendar", 10, 70, 11, 40, 1, 3, "0000FF", 1.0, 1, Null)
		g_calendar_table.AddColumn(66, GetText("Week"), "000000", "AAAAAA", 1)
		g_calendar_table.AddColumn(w, GetText("date_Monday")[..3], "000000", "CCCCCC", 1)
		g_calendar_table.AddColumn(w, GetText("date_Tuesday")[..3], "000000", "DDDDDD", 1)
		g_calendar_table.AddColumn(w, GetText("date_Wednesday")[..3], "000000", "CCCCCC", 1)
		g_calendar_table.AddColumn(w, GetText("date_Thursday")[..3], "000000", "DDDDDD", 1)
		g_calendar_table.AddColumn(w, GetText("date_Friday")[..3], "000000", "CCCCCC", 1)
		g_calendar_table.AddColumn(w, GetText("date_Saturday")[..3], "000000", "DDDDDD", 1)
		g_calendar_table.AddColumn(w, GetText("date_Sunday")[..3], "000000", "CCCCCC", 1)
		g_calendar_screen.AddGadget(g_calendar_table)
	End Function
