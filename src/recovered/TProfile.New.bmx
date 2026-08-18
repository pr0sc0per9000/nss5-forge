' TProfile.New
' VA 0x0056244B   1776 bytes   vtable slot 0x10   sig ()i   KIND=Method
' byte-identical vs NSS5.exe (1776/1776, original length from Ghidra's inventory, mode=reloc)
'
' All 134 TProfile Fields carry explicit `= value` defaults in the original (every field,
' including pure-zero/""/Null ones, gets a real store -- this is not implicit GC-zero init,
' it is source-level default initialisers compiled in field-declaration order, exactly the
' same convention already banked in THorse.New). The hand-written Method New() body below
' then overrides nine of them with their real starting values, matching the decompiled
' two-block shape byte for byte (each override re-does the refcount release of the
' just-defaulted value before storing the real one -- that refcounting is bcc's own and
' needs no extra source).
'
' Array fields are Int[] of the sizes read directly from the _bbArrayNew1D call arguments
' (boots/items/vehicles/property=10, sponsor_amount/sponsor_expires=9, interestedclubs=5,
' achievements=100, helppages=30); each array's element-type descriptor begins with 'i'.
'
' lastconnecthash's real value "47a5bc5742ca47828de0374c8ce31bdea" is read directly from the
' exe (harness.read_string) -- an install/anti-piracy placeholder hash, not a real MD5/SHA
' output (33 hex chars, one too many for either).
	Method New()
		'!Field gNetStatus :Int = 2
		'!Field saveversion :String = ""
		'!Field date :TMyDate = Null
		'!Field name :String = ""
		'!Field dbName :String = "#"
		'!Field nationid :Int = 62
		'!Field clubid :Int = 0
		'!Field playercols :TPlayerColours = Null
		'!Field bank :Int = 0
		'!Field newstarselno :Int = 9
		'!Field position :Int = 0
		'!Field side :Int = 0
		'!Field internationalselno :Int = 9
		'!Field retired :Int = 0
		'!Field careerstats :TList = Null
		'!Field newsheadline :String = ""
		'!Field newsrating :Int = 0
		'!Field newsmotm :Int = 0
		'!Field webheadline :String = ""
		'!Field bossreport :String = ""
		'!Field physioreport :String = ""
		'!Field coachreport :String = ""
		'!Field coachrep_boss :Int = 0
		'!Field coachrep_team :Int = 0
		'!Field coachrep_fans :Int = 0
		'!Field coachrep_sponsors :Int = 0
		'!Field coachrep_fame :Int = 0
		'!Field contractexpires :Int = 0
		'!Field contractwage :Int = 0
		'!Field contractgoalbonus :Int = 0
		'!Field contractassistbonus :Int = 0
		'!Field contractcleanbonus :Int = 0
		'!Field lastweeksgoalbonus :Int = 0
		'!Field lastweeksassistbonus :Int = 0
		'!Field lastweekscleanbonus :Int = 0
		'!Field thisweeksgoalbonus :Int = 0
		'!Field thisweeksassistbonus :Int = 0
		'!Field thisweekscleanbonus :Int = 0
		'!Field lastweeksshirtsales :Int = 0
		'!Field pace :Int = 0
		'!Field shooting :Int = 0
		'!Field passing :Int = 0
		'!Field tackling :Int = 0
		'!Field heading :Int = 0
		'!Field dribbling :Int = 0
		'!Field flair :Int = 0
		'!Field interviewskill :Int = 0
		'!Field crossing :Int = 0
		'!Field freekicks :Int = 0
		'!Field corners :Int = 0
		'!Field positioning :Int = 0
		'!Field shortpassing :Int = 0
		'!Field longpassing :Int = 0
		'!Field aggression :Int = 0
		'!Field longshots :Int = 0
		'!Field finishing :Int = 0
		'!Field penalties :Int = 0
		'!Field boots :Int[] = New Int[10]
		'!Field items :Int[] = New Int[10]
		'!Field vehicles :Int[] = New Int[10]
		'!Field property :Int[] = New Int[10]
		'!Field sponsor_amount :Int[] = New Int[9]
		'!Field sponsor_expires :Int[] = New Int[9]
		'!Field relationboss :Int = 50
		'!Field relationteam :Int = 50
		'!Field relationfans :Int = 50
		'!Field relationfriends :Int = 50
		'!Field relationgirlfriend :Int = 0
		'!Field relationsponsors :Int = 0
		'!Field relationfame :Int = 0
		'!Field captain :Int = 0
		'!Field girlscandalrating :Int = 0
		'!Field lastspendtimefriends :Int = 0
		'!Field lastspendtimegirlfriend :Int = 0
		'!Field playbuttontype :Int = 1
		'!Field transferlisted :Int = 0
		'!Field desiredcontinentid :Int = 0
		'!Field desirednationid :Int = 0
		'!Field desiredleagueid :Int = 0
		'!Field desiredclubid :Int = 0
		'!Field onloanfrom :Int = 0
		'!Field loanexpires :Int = 0
		'!Field oldbossrel :Int = 0
		'!Field oldteamrel :Int = 0
		'!Field oldfansrel :Int = 0
		'!Field energy :Float = 0
		'!Field NRG :Int = 0
		'!Field booze :Int = 0
		'!Field gambling :Int = 0
		'!Field injury :Int = 0
		'!Field freetime :Int = 0
		'!Field takenpainkillers :Int = 0
		'!Field shinpads :Int = 0
		'!Field boughtmusic :Int = 0
		'!Field boughtgame :Int = 0
		'!Field boughtfilm :Int = 0
		'!Field drugs :Int = 0
		'!Field currentyellowsclub :Int = 0
		'!Field currentyellowscontinent :Int = 0
		'!Field currentyellowsinternational :Int = 0
		'!Field banclub :Int = 0
		'!Field bancontinent :Int = 0
		'!Field baninternational :Int = 0
		'!Field interestedclubs :Int[] = New Int[5]
		'!Field lasttransferdate :Int = 0
		'!Field skillshash :String = ""
		'!Field passhash :String = ""
		'!Field premiumhash :String = ""
		'!Field lastconnecthash :String = ""
		'!Field achievements :Int[] = New Int[100]
		'!Field history :TList = Null
		'!Field tipcount :Int = 0
		'!Field helppages :Int[] = New Int[30]
		'!Field mynation :TNation = Null
		'!Field myclub :TClub = Null
		'!Field mylastfixture :TFixture = Null
		'!Field selectedformatch :Int = 0
		'!Field matchskipped :Int = 0
		'!Field interviewchance :Int = 0
		'!Field formationchanged :Int = 0
		'!Field matchesleft :Int = 0
		'!Field matcheswait :Int = 0
		'!Field timecheck :Int = 0
		'!Field temp_crossing :Int = 0
		'!Field temp_freekicks :Int = 0
		'!Field temp_corners :Int = 0
		'!Field temp_positioning :Int = 0
		'!Field temp_shortpassing :Int = 0
		'!Field temp_longpassing :Int = 0
		'!Field temp_aggression :Int = 0
		'!Field temp_longshots :Int = 0
		'!Field temp_finishing :Int = 0
		'!Field temp_penalties :Int = 0
		'!Field prematchsaved :Int = 0
		date = TMyDate.Create(1,1,1)
		playercols = New TPlayerColours
		careerstats = CreateList()
		history = CreateList()
		tipcount = 0
		skillshash = ""
		passhash = ""
		premiumhash = ""
		lastconnecthash = "47a5bc5742ca47828de0374c8ce31bdea"
	End Method
