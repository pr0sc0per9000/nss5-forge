' ============================================================
' NSS5 Type skeletons, generated from the reflection metadata
' inside NSS5.exe. Field order and byte offsets are the ORIGINAL
' layout. Do not reorder fields.
' ============================================================

SuperStrict

Type z_My_1a09b2da_7c75_4a81_b2c3_6774c843be3d
	Method New:Int()
	End Method

	Method Delete:Int()
	End Method

End Type

Type TBase_Team
	Field randno:Int	' +8
	Field id:Int	' +12
	Field name:String	' +16
	Field shortname:String	' +20
	Field tla:String	' +24
	Field labelname:String	' +28
	Field labelshortname:String	' +32
	Field strength:Int	' +36
	Field rivalid1:Int	' +40
	Field rivalid2:Int	' +44
	Field rivalid3:Int	' +48
	Field stadiumname:String	' +52
	Field stadiumcapacity:Int	' +56
	Field stadiumlongitude:Float	' +60
	Field stadiumlatitude:Float	' +64
	Field kitcolsHome:TKitStrings	' +68
	Field kitcolsAway:TKitStrings	' +72
	Field kitcolsThird:TKitStrings	' +76
	Field kitcolsKeeper:TKitStrings	' +80
	Field formation:Int	' +84
	Field imgFlag:TImage	' +88
	Field imgFlagSmall:TImage	' +92

	Method New:Int()
	End Method

	Method Delete:Int()
	End Method

	Method GetFixtureList:TList(_0:Int, _1:Int)
	End Method

	Method GetStringArrayFixtureList:TList(_0:Int)
	End Method

	Method GetNextFixture:TFixture(_0:Int)
	End Method

	Method GetPrimaryColour:String()
	End Method

	Method CheckManagerChangeFormation:Int()
	End Method

	Method Compare:Int(_0:Object)
	End Method

End Type

Type TNation
	Field nationality:String	' +96
	Field continent:Int	' +100
	Field climate:Int	' +104
	Field primaryskin:Int	' +108
	Field secondaryskin:Int	' +112

	Method New:Int()
	End Method

	Method Delete:Int()
	End Method

	Function CreateNation:Int(_0:String)
	End Function

	Function LoadData:Int(_0:TStream)
	End Function

	Function WriteData:Int(_0:TStream)
	End Function

	Function WriteDataMobile:Int(_0:TStream)
	End Function

	Function SaveMaster:Int(_0:Int, _1:Int)
	End Function

	Function SelectById:TNation(_0:Int)
	End Function

	Function SelectByTLA:TNation(_0:String)
	End Function

	Function SelectRandomNation:TNation(_0:Int)
	End Function

	Function SelectListByStartLetter:TList(_0:String)
	End Function

	Function SelectListByContinent:TList(_0:Int)
	End Function

	Function ReorderNations:Int()
	End Function

	Function ButtonizeFlag:Int(_0:TImage, _1:Int)
	End Function

	Method HasLeagues:Int()
	End Method

	Method GetFixtureList:TList(_0:Int, _1:Int)
	End Method

	Function SortListBy:Int(_0:Int, _1:Int)
	End Function

	Method Compare:Int(_0:Object)
	End Method

End Type

Type TClub
	Field nickname:String	' +96
	Field nationid:Int	' +100
	Field leagueid:Int	' +104
	Field continentalcompid:Int	' +108
	Field bteamofid:Int	' +112

	Method New:Int()
	End Method

	Method Delete:Int()
	End Method

	Method Destroy:Int()
	End Method

	Function CreateClub:Int(_0:String)
	End Function

	Function NewClub:TClub()
	End Function

	Function LoadData:Int(_0:TStream)
	End Function

	Function WriteData:Int(_0:TStream)
	End Function

	Function WriteDataMobile:Int(_0:TStream)
	End Function

	Function SaveMaster:Int(_0:Int, _1:Int)
	End Function

	Function SelectById:TClub(_0:Int)
	End Function

	Function SelectRandomClub:TClub(_0:Int)
	End Function

	Method GetActualLeagueId:Int()
	End Method

	Function SelectListByLeagueId:TList(_0:Int)
	End Function

	Function SelectListByNationId:TList(_0:Int)
	End Function

	Function CountTeamsInDivision:Int(_0:Int)
	End Function

	Function CountTeamsInContinentalComps:Int(_0:Int)
	End Function

	Function CountTeamsNotInContinentalComps:Int(_0:Int)
	End Function

	Method GetFixtureList:TList(_0:Int, _1:Int)
	End Method

	Method CountFixturesRemaining:Int()
	End Method

	Method GetStringArray:String[]()
	End Method

	Function ReorderClubs:Int()
	End Function

	Function AverageOutStrengthAll:Int()
	End Function

	Function CheckStadiumSizeAll:Int()
	End Function

	Function SortListBy:Int(_0:Int, _1:Int)
	End Function

	Method Compare:Int(_0:Object)
	End Method

End Type

Type TFixture
	Field sdate:Int	' +8
	Field matchtype:Int	' +12
	Field round:Int	' +16
	Field groupno:Int	' +20
	Field leg:Int	' +24
	Field hometeam:Int	' +28
	Field awayteam:Int	' +32
	Field result:Int	' +36
	Field resulttype:Int	' +40
	Field score1:Int	' +44
	Field score2:Int	' +48
	Field penscore1:Int	' +52
	Field penscore2:Int	' +56
	Field level:Int	' +60
	Field compid:Int	' +64

	Method New:Int()
	End Method

	Method Delete:Int()
	End Method

	Function CreateFixture:TFixture(_0:Int, _1:Int, _2:Int, _3:Int, _4:Int, _5:Int, _6:Int, _7:Int, _8:Int)
	End Function

	Function CreateFromString:TFixture(_0:String)
	End Function

	Method WriteData:Int(_0:TStream)
	End Method

	Method GetStringHomeTeam:String()
	End Method

	Method GetStringAwayTeam:String()
	End Method

	Method GetStringArray:String[](_0:Int)
	End Method

	Method GetStringArrayForLeague:String[]()
	End Method

	Method GetStringArrayForTeamId:String[](_0:Int)
	End Method

	Method GetFirstLegScore:Int(_0:*i, _1:*i)
	End Method

	Method PlayFixture:Int()
	End Method

	Method UpdatePoints:Int(_0:TTableData, _1:TTableData)
	End Method

	Function GetRandomGoal:Int()
	End Function

	Method GetWinningTeamTableId:Int()
	End Method

	Method GetLosingTeamTableId:Int()
	End Method

	Method GetWinningTeamId:Int()
	End Method

	Method GetLosingTeamId:Int()
	End Method

	Method GetHomeTeamId:Int()
	End Method

	Method GetAwayTeamId:Int()
	End Method

	Method CreateReplayFixture:Int()
	End Method

	Method Compare:Int(_0:Object)
	End Method

End Type

Type TLocale
	Method New:Int()
	End Method

	Method Delete:Int()
	End Method

	Function SetUp:Int()
	End Function

	Function SetCurrentLanguage:Int(_0:String)
	End Function

	Function GetLocaleText:String(_0:String)
	End Function

	Function SetUpKeyStrings:Int()
	End Function

End Type

Type TNames
	Method New:Int()
	End Method

	Method Delete:Int()
	End Method

	Function SetUp:Int(_0:Int)
	End Function

End Type

Type TBall
	Field id:Int	' +8
	Field active:Int	' +12
	Field alph:Float	' +16
	Field colour:String	' +20
	Field x:Float	' +24
	Field y:Float	' +28
	Field z:Float	' +32
	Field oldx:Float	' +36
	Field oldy:Float	' +40
	Field oldz:Float	' +44
	Field metax:Float	' +48
	Field metay:Float	' +52
	Field jumpx:Float	' +56
	Field jumpy:Float	' +60
	Field divex:Float	' +64
	Field divey:Float	' +68
	Field setpiecex:Int	' +72
	Field setpiecey:Int	' +76
	Field ingoal:Int	' +80
	Field velocity:Float	' +84
	Field zvelocity:Float	' +88
	Field direction:Float	' +92
	Field teaminpossession:Int	' +96
	Field kicktime:Int	' +100
	Field lastkicktype:Int	' +104
	Field lastkickmatchstate:Int	' +108
	Field controlledby:TPlayer	' +112
	Field lastkickedby:TPlayer	' +116
	Field lasttouchedby:TPlayer	' +120
	Field assistedby:TPlayer	' +124
	Field setpiecetaker:TPlayer	' +128
	Field setpiecebuddy:TPlayer	' +132
	Field backpass:Int	' +136
	Field slidekick:Int	' +140
	Field posthit:Int	' +144
	Field disttoreciever:Float	' +148
	Field curlamount:Float	' +152
	Field passtoid:Int	' +156
	Field frame:Int	' +160
	Field lastframetime:Int	' +164
	Field hideball:Int	' +168
	Field replayframes:TList	' +172

	Method New:Int()
	End Method

	Method Delete:Int()
	End Method

	Function ClearAll:Int()
	End Function

	Function SetUp:Int()
	End Function

	Function CreateBall:TBall(_0:Int, _1:Int, _2:Int)
	End Function

	Function CreateReplayBalls:Int(_0:TReplay)
	End Function

	Function SetActive:Int(_0:TBall)
	End Function

	Function GetActiveBall:TBall()
	End Function

	Function UpdateAll:Int()
	End Function

	Method Update:Int()
	End Method

	Function RenderAll:Int(_0:Float)
	End Function

	Method Render:Int(_0:Float)
	End Method

	Method UpdateAlpha:Int()
	End Method

	Method UpdateMovement:Int()
	End Method

	Method UpdateMetaBall:Int()
	End Method

	Method UpdateAnimation:Int()
	End Method

	Method Kick:Int(_0:TPlayer, _1:Float, _2:Float, _3:Int, _4:Int)
	End Method

	Method CheckAfterTouch:Int()
	End Method

	Method CheckGoals:Int()
	End Method

	Method CheckSideLines:Int()
	End Method

	Method CheckAdHoardings:Int()
	End Method

	Method HitPost:Int(_0:Float)
	End Method

	Method HitNet:Int(_0:Int)
	End Method

	Method NewController:Int(_0:TPlayer)
	End Method

	Method KeeperHolding:Int()
	End Method

	Method KeeperImageHolding:Int()
	End Method

	Method Deflect:Int(_0:TPlayer)
	End Method

	Method Parry:Int(_0:TPlayer)
	End Method

	Method SetUpSetPieceBall:Int(_0:Int, _1:Int, _2:Int)
	End Method

	Method ResetPosition:Int(_0:Int, _1:Int, _2:Int)
	End Method

	Method ResetControllers:Int()
	End Method

	Method Crossing:Int(_0:Float)
	End Method

	Function RecordReplayFramesAll:Int(_0:Int)
	End Function

	Method RecordReplayFrame:Int(_0:Int)
	End Method

	Function UpdateReplayAll:Int(_0:Int)
	End Function

	Method UpdateReplay:Int(_0:Int)
	End Method

	Function RenderReplayAll:Int(_0:Float)
	End Function

	Method RenderReplay:Int(_0:Float)
	End Method

	Method GetHeightScale:Float(_0:Int)
	End Method

	Method CanSeePlayer:Int(_0:TPlayer)
	End Method

	Function GetStringKickType:String(_0:Int)
	End Function

	Method CheckForPlayerRatings:Int(_0:TPlayer)
	End Method

	Method CheckLongShotRating:Int()
	End Method

	Method Compare:Int(_0:Object)
	End Method

End Type

Type TDrawOb
	Field x:Float	' +8
	Field y:Float	' +12
	Field z:Float	' +16
	Field z2:Float	' +20
	Field img:TImage	' +24
	Field frame:Int	' +28
	Field level:Int	' +32
	Field alph:Float	' +36
	Field rot:Int	' +40
	Field col:String	' +44
	Field sclx:Float	' +48
	Field scly:Float	' +52
	Field blend:Int	' +56
	Field txt:String	' +60
	Field txt2:String	' +64
	Field imgrectw:Float	' +68
	Field imgrecth:Float	' +72

	Method New:Int()
	End Method

	Method Delete:Int()
	End Method

	Function ClearAll:Int()
	End Function

	Function AddDrawOb:Int(_0:TImage, _1:Float, _2:Float, _3:Float, _4:Int, _5:Int, _6:Float, _7:Int, _8:String, _9:Float, _10:Float, _11:Int, _12:Float, _13:String, _14:Int, _15:Int)
	End Function

	Function RenderAll:Int(_0:Float, _1:Float, _2:Float)
	End Function

	Function Sort:Int()
	End Function

	Method Compare:Int(_0:Object)
	End Method

End Type

Type TEngine
	Method New:Int()
	End Method

	Method Delete:Int()
	End Method

	Function SetUp:Int()
	End Function

	Function SetUpChannels:Int()
	End Function

	Function StopChannels:Int()
	End Function

	Function SetUpMatch:Int(_0:TFixture, _1:TTeam, _2:TTeam, _3:()i)
	End Function

	Function SetUpReplay:Int(_0:TReplay, _1:()i)
	End Function

	Function SetUpRadarColours:Int()
	End Function

	Function SetUpWeatherConditions:Int()
	End Function

	Function MatchLoop:Int()
	End Function

	Function RenderGameEngine:Int(_0:Float)
	End Function

	Function Update:Int()
	End Function

	Function UpdateOffset:Int(_0:Float)
	End Function

	Function Render:Int(_0:Float)
	End Function

	Function RenderRadar:Int()
	End Function

	Function RenderScoreboard:Int()
	End Function

	Function DrawScores:Int()
	End Function

	Function CheckInput:Int()
	End Function

	Function SetUpSetPiece:Int(_0:Int, _1:Int, _2:Int, _3:Int)
	End Function

	Function SetPiece:Int()
	End Function

	Function WaitForSetpiece:Int()
	End Function

	Function UpdateSetPieceReady:Int()
	End Function

	Function ResetClubLastChange:Int()
	End Function

	Function GoalScored:Int(_0:TBall)
	End Function

	Function UpdateMatchTime:Int()
	End Function

	Function DoHalfEnds:Int()
	End Function

	Function CreateReplayFrames:Int(_0:TReplay)
	End Function

	Function RecordReplayFrame:Int(_0:Int)
	End Function

	Function UpdateReplayFrame:Int(_0:Int)
	End Function

	Function StartReplay:Int()
	End Function

	Function EndReplay:Int()
	End Function

	Function UpdateReplay:Int()
	End Function

	Function CheckReplayInput:Int()
	End Function

	Function UpdateOffsetReplay:Int(_0:Float)
	End Function

	Function RenderReplay:Int(_0:Float)
	End Function

	Function RenderReplayGUI:Int()
	End Function

	Function RenderReplayRadar:Int()
	End Function

	Function SaveReplay:Int()
	End Function

	Function UpdateSounds:Int()
	End Function

	Function UpdateSoundsReplay:Int()
	End Function

	Function PauseSounds:Int()
	End Function

	Function ResumeSounds:Int()
	End Function

	Function DoYourSubstitutionOn:Int()
	End Function

	Function DoYourSubstitutionOff:Int(_0:Int)
	End Function

	Function MatchOver:Int()
	End Function

	Function SkipMatchTime:Int()
	End Function

	Function EndMatch:Int()
	End Function

	Function SkipTime:Int()
	End Function

	Function ForcePositionResetAll:Int()
	End Function

	Function DoShootOut:Int()
	End Function

	Function CheckShootOutComplete:Int()
	End Function

	Function GetStringMatchState:String()
	End Function

	Function GetWinningClub:TTeam()
	End Function

	Function ResetStats:Int()
	End Function

	Function PauseEngine:Int()
	End Function

	Function DrawMyText:Int(_0:String, _1:Float, _2:Float, _3:Int, _4:Int, _5:Float, _6:Float, _7:String, _8:Int)
	End Function

End Type

Type TFormation
	Field name:String	' +8
	Field m_Defenders:Int	' +12
	Field m_DefensiveMidfielders:Int	' +16
	Field m_Midfielders:Int	' +20
	Field m_AttackingMidfielders:Int	' +24
	Field m_Attackers:Int	' +28
	Field m_TacPos:Int[]	' +32
	Field m_TacLabel:String[]	' +36

	Method New:Int()
	End Method

	Method Delete:Int()
	End Method

	Function SetUp:Int()
	End Function

	Function Create:TFormation(_0:Int)
	End Function

	Method UpdateLabels:Int()
	End Method

	Method LoadTactics:Int(_0:String)
	End Method

	Method SaveTactics:Int()
	End Method

	Method GetSelectionNoFromSeg:Int(_0:Int, _1:Int)
	End Method

	Method GetCol:Int(_0:Int)
	End Method

	Method GetRow:Int(_0:Int)
	End Method

	Method GetRowFromSelectionNo:Int(_0:Int)
	End Method

	Method GetColFromSelectionNo:Int(_0:Int)
	End Method

	Method GetPlayerXY:Float(_0:Int, _1:Float, _2:Float, _3:Float, _4:Float, _5:Int, _6:Int, _7:*f, _8:*f, _9:Float, _10:Float)
	End Method

	Method GetPosFromSelectionNo:Int(_0:Int)
	End Method

	Method GetSideFromSelectionNo:Int(_0:Int)
	End Method

	Function GetStringTacticName:String(_0:Int)
	End Function

	Function GetTacticIdByName:Int(_0:String)
	End Function

	Method GetStringLabelFromSelectionNo:String(_0:Int)
	End Method

	Function GetStringPosition:String(_0:Int, _1:Int)
	End Function

	Function PickRandomFormation:Int()
	End Function

End Type

Type TJoy
	Field axis_x:Float	' +8
	Field axis_y:Float	' +12
	Field force:Float	' +16
	Field direction:Float	' +20
	Field kickenabled:Int	' +24
	Field kickbuttondown:Int	' +28
	Field kickbuttonhits:Int	' +32
	Field activebutton:Int	' +36

	Method New:Int()
	End Method

	Method Delete:Int()
	End Method

	Function CreateJoy:TJoy()
	End Function

	Method Update:Int(_0:Int, _1:Int, _2:Int)
	End Method

	Method GetActualDirection:Float()
	End Method

	Method Clear:Int()
	End Method

End Type

Type TKit
	Field pixmap:TPixmap	' +8
	Field style:String	' +12
	Field newcol:String[]	' +16

	Method New:Int()
	End Method

	Method Delete:Int()
	End Method

	Function SetUp:Int()
	End Function

	Method Clear:Int()
	End Method

	Function CreateKit:TKit(_0:TKitStrings, _1:String)
	End Function

	Method GetPaintedPlayer:TPixmap(_0:String, _1:Int, _2:Int, _3:String)
	End Method

	Method GetPaintedFan:TPixmap(_0:Int, _1:Int)
	End Method

	Function GetRandHexHairColour:String(_0:Int)
	End Function

	Function GetHexHairCol:String(_0:Int)
	End Function

	Function GetHexSkinColour:String(_0:Int)
	End Function

	Function CheckBlack:Int(_0:*$)
	End Function

	Function ColorInt:Int(_0:Int, _1:Int, _2:Int, _3:Int)
	End Function

	Function GetBootColour:String(_0:Int)
	End Function

	Function GetBootColourInt:Int(_0:String)
	End Function

	Function GetGloveColour:String(_0:Int)
	End Function

	Function GetGloveColourInt:Int(_0:String)
	End Function

	Function GetStringHairCol:String(_0:Int)
	End Function

	Function GetStringSkinCol:String(_0:Int)
	End Function

End Type

Type TKitStrings
	Field style:String	' +8
	Field shirt1:String	' +12
	Field shirt2:String	' +16
	Field shorts:String	' +20
	Field socks:String	' +24

	Method New:Int()
	End Method

	Method Delete:Int()
	End Method

	Function CreateKitStrings:TKitStrings(_0:String, _1:String, _2:String, _3:String, _4:String)
	End Function

	Method Copy:Int(_0:TKitStrings)
	End Method

	Method CheckKitColours:Int()
	End Method

	Function ConvertNSS4ColourIndexToHex:String(_0:Int)
	End Function

	Method GetFileName:String()
	End Method

	Method GetStyleId_Mobile:Int()
	End Method

End Type

Type TPlayerColours
	Field skin:Int	' +8
	Field hair:Int	' +12
	Field boots:String	' +16

	Method New:Int()
	End Method

	Method Delete:Int()
	End Method

	Method SetSkin:Int(_0:Int)
	End Method

	Method SetHair:Int(_0:Int)
	End Method

End Type

Type TTeam
	Field id:Int	' +8
	Field name:String	' +12
	Field tla:String	' +16
	Field rating:Int	' +20
	Field controller:Int	' +24
	Field squad:TList	' +28
	Field lastchangeplayer:Int	' +32
	Field formation:TFormation	' +36
	Field cornerformation:TList	' +40
	Field kitplayer:TKit	' +44
	Field kitkeeper:TKit	' +48
	Field skin1:Int	' +52
	Field skin2:Int	' +56
	Field newstarselno:Int	' +60

	Method New:Int()
	End Method

	Method Delete:Int()
	End Method

	Method Getkitplayer:TKit()
	End Method

	Method Setkitplayer:Int(_0:TKit)
	End Method

	Method Getkitkeeper:TKit()
	End Method

	Method Setkitkeeper:Int(_0:TKit)
	End Method

	Method Clear:Int()
	End Method

	Function CreateTeamSimple:TTeam(_0:Int, _1:String, _2:String, _3:Int, _4:Int, _5:TKit, _6:TKit, _7:Int, _8:Int, _9:Int, _10:TFixture)
	End Function

	Method CreateSquadSimple:Int()
	End Method

	Function CreateReplayTeam:TTeam(_0:TReplay, _1:Int, _2:String, _3:String, _4:TKit, _5:TKit, _6:Int)
	End Function

	Method CreateReplaySquad:Int(_0:TReplay)
	End Method

	Method PaintSquad:Int(_0:Int)
	End Method

	Method UpdateNewStarPosition:Int(_0:Int)
	End Method

	Method ChangeFormation:Int(_0:Int, _1:Int)
	End Method

	Method ResetCornerFormation:Int()
	End Method

	Method Update:Int()
	End Method

	Method UpdateLocalPlayer:Int()
	End Method

	Method NewLocalPlayer:Int(_0:TPlayer)
	End Method

	Method UpdatePlayerDestinations:Int()
	End Method

	Method GetTunnelPositions:Int(_0:Int)
	End Method

	Method GetShootoutPositions:Int()
	End Method

	Method GetMatchOverPositions:Int()
	End Method

	Method GetWallLocation:Int(_0:Int, _1:Int, _2:Int, _3:*f, _4:*f)
	End Method

	Method ForcePositionReset:Int()
	End Method

	Method GetSetPieceTakers:Int(_0:Int, _1:TBall)
	End Method

	Method GetShootingDirection:Int()
	End Method

	Method GetPlayerNearestToXY:TPlayer(_0:Int, _1:Int, _2:Int, _3:TPlayer, _4:Int)
	End Method

	Method CheckComManagement:Int()
	End Method

	Method GetLosingBy:Int()
	End Method

	Method SelectRandomPlayer:TPlayer(_0:Int, _1:Int, _2:Int, _3:Int)
	End Method

End Type

Type TMyVector
	Field X:Double	' +8
	Field Y:Double	' +16
	Field Z:Double	' +24

	Method New:Int()
	End Method

	Method Delete:Int()
	End Method

	Function Create:TMyVector(_0:Double, _1:Double, _2:Double)
	End Function

	Method SetXYZ:TMyVector(_0:Double, _1:Double, _2:Double)
	End Method

	Method Set:TMyVector(_0:TMyVector)
	End Method

	Method Add:TMyVector(_0:TMyVector)
	End Method

	Method Sub:TMyVector(_0:TMyVector)
	End Method

	Method SubXYZ:TMyVector(_0:Double, _1:Double, _2:Double)
	End Method

	Method GetDotPV:Double(_0:TMyVector)
	End Method

	Method CrossPV:TMyVector(_0:TMyVector)
	End Method

	Method Mul:TMyVector(_0:Double)
	End Method

	Method Div:TMyVector(_0:Double)
	End Method

	Method Normalize:TMyVector()
	End Method

	Method RotateAroundX:TMyVector(_0:Double)
	End Method

	Method RotateAroundY:TMyVector(_0:Double)
	End Method

	Method RotateAroundZ:TMyVector(_0:Double)
	End Method

	Method RotateAroundV:TMyVector(_0:TMyVector, _1:Double)
	End Method

	Method Copy2Vec:TMyVector()
	End Method

	Method GetX:Double()
	End Method

	Method GetY:Double()
	End Method

	Method GetZ:Double()
	End Method

	Method GetLength:Double()
	End Method

	Method GetLengthSqr:Double()
	End Method

	Method SetX:TMyVector(_0:Double)
	End Method

	Method SetY:TMyVector(_0:Double)
	End Method

	Method SetZ:TMyVector(_0:Double)
	End Method

End Type

Type TOptions
	Method New:Int()
	End Method

	Method Delete:Int()
	End Method

	Function SetUp:Int()
	End Function

	Function GetButtonLabel:String(_0:Int)
	End Function

	Function GetButtonIcon:TImage(_0:Int, _1:Int)
	End Function

	Function GetNewControl:Int()
	End Function

	Function WaitForJoyRelease:Int()
	End Function

	Function WriteNewOptionsIni:Int()
	End Function

	Function SaveOptions:Int()
	End Function

	Function LoadOptions:Int()
	End Function

	Function FindRes800600:Int()
	End Function

	Function NewButtonUp:Int()
	End Function

	Function NewButtonDown:Int()
	End Function

	Function NewButtonLeft:Int()
	End Function

	Function NewButtonRight:Int()
	End Function

	Function NewButtonKick:Int()
	End Function

	Function NewButtonKick2:Int()
	End Function

	Function NewButtonKick3:Int()
	End Function

	Function NewButtonKick4:Int()
	End Function

	Function NewButtonPause:Int()
	End Function

	Function NewButtonReplay:Int()
	End Function

End Type

Type TPitch
	Method New:Int()
	End Method

	Method Delete:Int()
	End Method

	Function SetUp:Int()
	End Function

	Function RandomPitchType:Int()
	End Function

	Function SetStadiumSize:Int(_0:Int, _1:Int)
	End Function

	Function SetUpFans:Int(_0:TTeam, _1:TTeam, _2:Int)
	End Function

	Function Update:Int()
	End Function

	Function Render:Int(_0:Float, _1:Float, _2:Float)
	End Function

	Function DrawStadium:Int(_0:Float, _1:Float, _2:Float)
	End Function

	Function DrawFans:Int(_0:Int, _1:Float, _2:Float, _3:Float, _4:Int)
	End Function

	Function DrawBosses:Int()
	End Function

	Function DoLineUpImage:Int()
	End Function

	Function IsOnPitch:Int(_0:Int, _1:Int)
	End Function

	Function InsidePenaltyBox:Int(_0:Int, _1:Int, _2:Int)
	End Function

	Function InsideCrossZone:Int(_0:Int, _1:Int, _2:Int)
	End Function

	Function PixelsToYards:Float(_0:Float)
	End Function

	Function PixelsToMetres:Float(_0:Float)
	End Function

	Function YardsToPixels:Float(_0:Float)
	End Function

	Function MetresToPixels:Float(_0:Float)
	End Function

	Function YardsToMetres:Float(_0:Float)
	End Function

	Function MetresToYards:Float(_0:Float)
	End Function

	Function ValidateOnPitch:Int(_0:*f, _1:*f)
	End Function

End Type

Type TPitchMark
	Field x:Int	' +8
	Field y:Int	' +12
	Field a:Float	' +16
	Field rot:Int	' +20
	Field frm:Int	' +24
	Field frametime:Int	' +28

	Method New:Int()
	End Method

	Method Delete:Int()
	End Method

	Function SetUp:Int()
	End Function

	Function ResetPitchMarks:Int()
	End Function

	Function AddPitchMark:Int(_0:Int, _1:Int, _2:Int, _3:Int, _4:Float)
	End Function

	Function Render:Int()
	End Function

	Function RenderReplay:Int()
	End Function

End Type

Type TPhotographer
	Field x:Float	' +8
	Field y:Float	' +12
	Field facing:Int	' +16
	Field pose:Int	' +20
	Field flashmod:Int	' +24

	Method New:Int()
	End Method

	Method Delete:Int()
	End Method

	Function SetUp:Int()
	End Function

	Function Create:Int(_0:Float, _1:Float, _2:Int, _3:Int)
	End Function

	Function SetUpPositions:Int()
	End Function

	Function RenderAll:Int()
	End Function

	Method Render:Int()
	End Method

	Function ClearAll:Int()
	End Function

End Type

Type TCameraMan
	Field x:Float	' +8
	Field y:Float	' +12
	Field facing:Int	' +16
	Field rot:Float	' +20

	Method New:Int()
	End Method

	Method Delete:Int()
	End Method

	Function SetUp:Int()
	End Function

	Function Create:Int(_0:Float, _1:Float)
	End Function

	Function SetUpPositions:Int()
	End Function

	Function UpdateAll:Int()
	End Function

	Method Update:Int()
	End Method

	Function RenderAll:Int()
	End Function

	Method Render:Int()
	End Method

	Function ClearAll:Int()
	End Function

End Type

Type TPlayer
	Field newstar:Int	' +8
	Field imgPlayer:TImage	' +12
	Field id:Int	' +16
	Field teamid:Int	' +20
	Field controller:Int	' +24
	Field name:String	' +28
	Field initials:String	' +32
	Field age:Int	' +36
	Field value:String	' +40
	Field preferredposition:String	' +44
	Field happiness:Int	' +48
	Field boozedup:Int	' +52
	Field nrgsickness:Int	' +56
	Field unhappiness:Int	' +60
	Field tiredness:Int	' +64
	Field boozecount:Int	' +68
	Field nrgcount:Int	' +72
	Field x:Float	' +76
	Field y:Float	' +80
	Field z:Float	' +84
	Field oldx:Float	' +88
	Field oldy:Float	' +92
	Field oldz:Float	' +96
	Field xvel:Float	' +100
	Field yvel:Float	' +104
	Field zvel:Float	' +108
	Field runtime:Int	' +112
	Field speed:Float	' +116
	Field direction:Float	' +120
	Field desx:Float	' +124
	Field desy:Float	' +128
	Field metax:Float	' +132
	Field metay:Float	' +136
	Field goalside:Int	' +140
	Field keepercatchtime:Int	' +144
	Field kickx:Int	' +148
	Field kicky:Int	' +152
	Field receivex:Int	' +156
	Field receivey:Int	' +160
	Field posxwhenkicked:Int	' +164
	Field posywhenkicked:Int	' +168
	Field offside:Int	' +172
	Field offsidewhenkicked:Int	' +176
	Field offsidealpha:Float	' +180
	Field offsidetime:Int	' +184
	Field selectionno:Int	' +188
	Field kickpower:Float	' +192
	Field kickdirection:Float	' +196
	Field lastkickdirection:Float	' +200
	Field directiontoball:Int	' +204
	Field distancetoball:Float	' +208
	Field directiontometaball:Int	' +212
	Field distancetometaball:Float	' +216
	Field jumpspotgood:Int	' +220
	Field directiontogoal_opp:Int	' +224
	Field directiontogoal_own:Int	' +228
	Field distancetogoal_opp:Int	' +232
	Field distancetogoal_own:Int	' +236
	Field teammateid:Int	' +240
	Field lastchangedteammateid:Int	' +244
	Field directiontoteammate:Int	' +248
	Field distancetoteammate:Float	' +252
	Field opponentid:Int	' +256
	Field directiontoopponent:Int	' +260
	Field distancetoopponent:Float	' +264
	Field passpotential:Int	' +268
	Field passison:Int	' +272
	Field calling:Int	' +276
	Field calltype:Int	' +280
	Field bonus:Int	' +284
	Field icalledforball:Int	' +288
	Field ihadashot:Int	' +292
	Field facing:Int	' +296
	Field spriterotation:Float	' +300
	Field currentanim:Int[]	' +304
	Field frame:Int	' +308
	Field lastframetime:Int	' +312
	Field imageframenumber:Int	' +316
	Field skincol:Int	' +320
	Field haircol:Int	' +324
	Field bootcolint:Int	' +328
	Field glovecolint:Int	' +332
	Field bootcol:String	' +336
	Field glovecol:String	' +340
	Field joy:TJoy	' +344
	Field obtext:String	' +348
	Field replayframes:TList	' +352
	Field pace:Float	' +356
	Field dribbling:Float	' +360
	Field tackling:Float	' +364
	Field passing:Float	' +368
	Field heading:Float	' +372
	Field shooting:Float	' +376
	Field flair:Float	' +380
	Field slide_start:Int	' +384
	Field slide_delay:Int	' +388
	Field matchstats:TStats_Match	' +392

	Method New:Int()
	End Method

	Method Delete:Int()
	End Method

	Function SetUp:Int()
	End Function

	Function ClearAll:Int()
	End Function

	Function CreatePlayerSimple:TPlayer(_0:Int, _1:Int, _2:Int, _3:Int, _4:Int, _5:Int)
	End Function

	Function CreateReplayPlayer:TPlayer(_0:TReplayFrame)
	End Function

	Method PaintPlayer:Int(_0:TKit)
	End Method

	Function UpdateAll:Int()
	End Function

	Method Update:Int()
	End Method

	Function RenderAll:Int(_0:Float)
	End Function

	Method Render:Int(_0:Float)
	End Method

	Method GetShadowOffsetAndRot:Int(_0:Int, _1:*i, _2:*i)
	End Method

	Function RenderGUIAll:Int(_0:Float, _1:Float)
	End Function

	Method RenderGUI:Int(_0:Float, _1:Float)
	End Method

	Method UpdateCalling:Int()
	End Method

	Method UpdateFundamentals:Int()
	End Method

	Method UpdateTeamMateId:Int()
	End Method

	Method UpdateTeamMateId_Human:Int()
	End Method

	Method UpdateTeamMateId_CPU:Int()
	End Method

	Method UpdateOpponent:Int()
	End Method

	Function UpdatePassPotentialAll:Int()
	End Function

	Method UpdatePassPotential:Int()
	End Method

	Method UpdateMovement:Int()
	End Method

	Method ForceControlCPU:Int()
	End Method

	Method UpdateJoy:Int()
	End Method

	Method UpdateJoyAI_TouchControls:Int()
	End Method

	Method UpdateJoyAI:Int()
	End Method

	Method DoHeadingAI:Int()
	End Method

	Method DoKickingAI:Int()
	End Method

	Method ShootAI:Int()
	End Method

	Method PassAI:Int()
	End Method

	Method DoTacklingAI:Int()
	End Method

	Function ResetKickAll:Int()
	End Function

	Method ResetKick:Int()
	End Method

	Function JoyClearAll:Int()
	End Function

	Method UpdateKeeperPosition:Int()
	End Method

	Method DoKeeperDiveAI:Int()
	End Method

	Method KeeperDive:Int(_0:TInterceptPoint, _1:Int)
	End Method

	Method KeeperCatchLow:Int()
	End Method

	Method KeeperCatchHigh:Int()
	End Method

	Method KeeperJump:Int()
	End Method

	Method BackPass:Int()
	End Method

	Function CheckPlayerContactAll:Int()
	End Function

	Function DoCollision:Int(_0:TPlayer, _1:TPlayer)
	End Function

	Method CheckFoul:Int(_0:TPlayer)
	End Method

	Method YellowCard:Int()
	End Method

	Method RedCard:Int()
	End Method

	Method CleanThrough:Int()
	End Method

	Method CheckBallContact:Int()
	End Method

	Method CheckKeeperSave:Int()
	End Method

	Method CheckHoldingKick:Int()
	End Method

	Method CheckKick:Int()
	End Method

	Method Call:Int()
	End Method

	Method TapKick:Int()
	End Method

	Method TapKickAdvanced:Int()
	End Method

	Method HoldKick:Int()
	End Method

	Method HoldKickAdvanced:Int()
	End Method

	Method SlideBall:Int()
	End Method

	Method BlockTackle:Int()
	End Method

	Method BlockSave:Int()
	End Method

	Method HeadBall:Int()
	End Method

	Method HeadBallAdvanced:Int()
	End Method

	Method DiveHeadBall:Int()
	End Method

	Method InterceptBall:Int(_0:TBall)
	End Method

	Method ChaseBall:Int(_0:Float, _1:Float, _2:TPlayer)
	End Method

	Method GetCoveringLocation:Int(_0:Float, _1:Float)
	End Method

	Method DoDribbling:Int()
	End Method

	Method DoRepulsion:Int(_0:Float, _1:Float, _2:*f, _3:*f, _4:Double)
	End Method

	Method pow:Int(_0:Int, _1:Int)
	End Method

	Method MoveYardsClear:Int(_0:Float, _1:Int, _2:Int)
	End Method

	Function SetTunnelPositionAll:Int()
	End Function

	Method GetTunnelPosition:Int(_0:Int)
	End Method

	Method GetHuddlePosition:Int(_0:*i, _1:*i)
	End Method

	Method GetShootOutPosition:Int()
	End Method

	Method GetMatchOverPosition:Int()
	End Method

	Function AllPlayersReady:Int()
	End Function

	Method PlayerReady:Int()
	End Method

	Method ResetPosition:Int()
	End Method

	Method GetShootingDirection:Int()
	End Method

	Function GetHumanPlayer:TPlayer()
	End Function

	Function GetPlayerById:TPlayer(_0:Int)
	End Function

	Method GetFacingDirection:Int(_0:Float)
	End Method

	Method GetDistanceToByLine:Float(_0:Int)
	End Method

	Method GetMyTeam:TTeam()
	End Method

	Method GetOppTeam:TTeam()
	End Method

	Method GetHumanNumber:Int()
	End Method

	Method GetStringAnim:String(_0:Int[])
	End Method

	Method CheckJoyAngle:Int()
	End Method

	Method GetOppKeeper:TPlayer()
	End Method

	Method GetMouseDirection:Int()
	End Method

	Method UpdateAnimation:Int()
	End Method

	Method GetAnimFrame:Int(_0:Int)
	End Method

	Method ValidateAnimDirection:Int()
	End Method

	Method ValidateKeeperAnim:Int()
	End Method

	Method PlayerOnFeet:Int()
	End Method

	Method ImageJumping:Int()
	End Method

	Method ImageFalling:Int()
	End Method

	Method ImageHoldingBall:Int(_0:Int)
	End Method

	Method PlayerSliding:Int()
	End Method

	Method PlayerDiving:Int()
	End Method

	Method PlayerFalling:Int()
	End Method

	Method PlayerKicking:Int()
	End Method

	Method KeeperHoldingBall:Int()
	End Method

	Method KeeperDiving:Int()
	End Method

	Method KeeperJumping:Int()
	End Method

	Method GetKeeperHandHeight:Float()
	End Method

	Method GetPlayerRunningHandHeight:Int(_0:*f)
	End Method

	Method DoAnimJump:Int()
	End Method

	Method DoAnimDive:Int()
	End Method

	Method DoAnimSlide:Int()
	End Method

	Method DoAnimFall:Int()
	End Method

	Method DoAnimKick:Int(_0:Int)
	End Method

	Method DoCelebrations:Int()
	End Method

	Method PlayerCelebrating:Int()
	End Method

	Method DoAnimCelebrate:Int(_0:Int)
	End Method

	Method DoAnimCommiserate:Int(_0:Int)
	End Method

	Function ResetAnimationsAll:Int()
	End Function

	Method GoalScorer:Int()
	End Method

	Function RecordReplayFramesAll:Int(_0:Int)
	End Function

	Method RecordReplayFrame:Int(_0:Int)
	End Method

	Function UpdateReplayAll:Int(_0:Int)
	End Function

	Method UpdateReplay:Int(_0:Int)
	End Method

	Function RenderReplayAll:Int(_0:Float)
	End Function

	Method RenderReplay:Int(_0:Float)
	End Method

	Method UpdateOffside:Int()
	End Method

	Function UpdatePositionWhenKickedAll:Int(_0:Int)
	End Function

	Function ResetOffsideAll:Int()
	End Function

	Method CheckOffside:Int()
	End Method

	Method AddStat:Int(_0:Int, _1:Float, _2:Float, _3:Float, _4:Float)
	End Method

	Function UpdateMatchRatingAll:Int()
	End Function

	Function RecordPlayerStats:Int()
	End Function

	Method AddPlayerRating:Int(_0:Int, _1:Int, _2:String)
	End Method

	Method BossPositive:Int()
	End Method

	Method Compare:Int(_0:Object)
	End Method

End Type

Type TReplay
	Field name:String	' +8
	Field teamid1:Int	' +12
	Field teamid2:Int	' +16
	Field teamname1:String	' +20
	Field teamname2:String	' +24
	Field score1:Int	' +28
	Field score2:Int	' +32
	Field pitchtype:Int	' +36
	Field mowtype:Int	' +40
	Field doingweather:Int	' +44
	Field weathertype:Int	' +48
	Field kit1cols:TKitStrings	' +52
	Field kit2cols:TKitStrings	' +56
	Field keeperkit1cols:TKitStrings	' +60
	Field keeperkit2cols:TKitStrings	' +64
	Field fixlevel:Int	' +68
	Field stadiumsize:Int	' +72
	Field ballframes:TList	' +76
	Field playerframes:TList	' +80
	Field matchstateframes:TList	' +84

	Method New:Int()
	End Method

	Method Delete:Int()
	End Method

	Function CreateReplay:String(_0:TTeam, _1:TTeam, _2:Int, _3:Int, _4:Int, _5:Int, _6:Int, _7:Int, _8:Int)
	End Function

	Function LoadReplayFile:TReplay(_0:String)
	End Function

	Method WriteHeader:Int(_0:TStream)
	End Method

	Method ReadHeader:Int(_0:TStream)
	End Method

End Type

Type TReplayFrame
	Field frametime:Int	' +8
	Field obtext:String	' +12
	Field obtype:Int	' +16
	Field id:Int	' +20
	Field selno:Int	' +24
	Field clubid:Int	' +28
	Field skincol:Int	' +32
	Field haircol:Int	' +36
	Field bootcol:Int	' +40
	Field glovecol:Int	' +44
	Field x:Float	' +48
	Field y:Float	' +52
	Field z:Float	' +56
	Field xvel:Float	' +60
	Field yvel:Float	' +64
	Field zvel:Float	' +68
	Field frame:Int	' +72
	Field facing:Int	' +76
	Field rotation:Float	' +80
	Field alph:Float	' +84
	Field active:Int	' +88

	Method New:Int()
	End Method

	Method Delete:Int()
	End Method

	Method SaveFrame:Int(_0:TStream)
	End Method

	Function LoadFrame:TReplayFrame(_0:TStream)
	End Function

End Type

Type TWeather
	Method New:Int()
	End Method

	Method Delete:Int()
	End Method

	Function SetUp:Int()
	End Function

	Function SetWeatherTimes:Int(_0:Int, _1:Int, _2:Int)
	End Function

	Function Update:Int(_0:Int)
	End Function

	Function UpdateRain:Int()
	End Function

	Function UpdateReplay:Int(_0:Float, _1:Int)
	End Function

	Function UpdateReplayRain:Int(_0:Float, _1:Int)
	End Function

	Function Render:Int(_0:Int)
	End Function

End Type

Type TSnowFlake
	Field x:Float	' +8
	Field y:Float	' +12
	Field g:Float	' +16
	Field rot:Int	' +20
	Field a:Float	' +24
	Field s:Float	' +28
	Field t:Byte	' +32
	Field w:Int	' +36
	Field iner:Float	' +40
	Field inerD:Float	' +44
	Field d:Int	' +48
	Field scl:Float	' +52

	Method New:Int()
	End Method

	Method Delete:Int()
	End Method

	Function SetUp:Int()
	End Function

	Function Create:TSnowFlake()
	End Function

	Function UpdateAll:Int(_0:Int)
	End Function

	Method Update:Int()
	End Method

	Function ResetAll:Int()
	End Function

	Function RenderAll:Int()
	End Function

	Method Render:Int()
	End Method

End Type

Type TInterceptPoint
	Field x:Float	' +8
	Field y:Float	' +12
	Field intercept_AB:Float	' +16
	Field intercept_CD:Float	' +20
	Field intercept:Int	' +24

	Method New:Int()
	End Method

	Method Delete:Int()
	End Method

End Type

Type TMyGfxModes
	Field w:Int	' +8
	Field h:Int	' +12

	Method New:Int()
	End Method

	Method Delete:Int()
	End Method

	Function Create:Int(_0:Int, _1:Int)
	End Function

	Function OnListAlready:Int(_0:Int, _1:Int)
	End Function

	Method Compare:Int(_0:Object)
	End Method

End Type

Type TMyBankStream
	Method New:Int()
	End Method

	Method Delete:Int()
	End Method

	Function Create:TMyBankStream(_0:TBank)
	End Function

	Method WriteLine:Int(_0:String)
	End Method

End Type

Type TMyStream
	Field oldversion:Int	' +12

	Method New:Int()
	End Method

	Method Delete:Int()
	End Method

	Method ReadLine:String()
	End Method

End Type

Type TContinent
	Field id:Int	' +8
	Field name:String	' +12
	Field tla:String	' +16
	Field continentality:String	' +20
	Field federationname:String	' +24
	Field federationshortname:String	' +28
	Field strength:Int	' +32

	Method New:Int()
	End Method

	Method Delete:Int()
	End Method

	Function CreateContinent:Int(_0:String)
	End Function

	Function LoadData:Int(_0:TStream)
	End Function

	Function WriteData:Int(_0:TStream)
	End Function

	Function SaveMaster:Int(_0:Int, _1:Int)
	End Function

	Function SelectById:TContinent(_0:Int)
	End Function

End Type

Type TCompetition
	Field id:Int	' +8
	Field name:String	' +12
	Field tla:String	' +16
	Field labelname:String	' +20
	Field locale:Int	' +24
	Field level:Int	' +28
	Field based:Int	' +32
	Field comptype:Int	' +36
	Field startyear:Int	' +40
	Field startweek:Int	' +44
	Field duration:Int	' +48
	Field recurring:Int	' +52
	Field primarymatchday:Int	' +56
	Field secondarymatchday:Int	' +60
	Field groups:Int	' +64
	Field rounds:Int	' +68
	Field legs:Int	' +72
	Field townregion:Int	' +76
	Field compstatus:Int	' +80
	Field priority:Int	' +84
	Field minstrength:Int	' +88
	Field maxstrength:Int	' +92
	Field lfixturelist:TList	' +96
	Field lpromotionplaces:TList	' +100
	Field lplacesthatpromotetome:TList	' +104
	Field teampool:TTeamPool[]	' +108
	Field tempNoofTeams:Int	' +112

	Method New:Int()
	End Method

	Method Delete:Int()
	End Method

	Method Destroy:Int()
	End Method

	Function CreateCompetition:Int(_0:String, _1:TStream)
	End Function

	Function NewCompetition:TCompetition(_0:Int)
	End Function

	Function LoadData:Int(_0:TStream)
	End Function

	Function WriteData:Int(_0:TStream, _1:Int)
	End Function

	Function WriteDataMobile:Int(_0:TStream, _1:Int)
	End Function

	Function SaveMaster:Int(_0:Int, _1:Int)
	End Function

	Function SelectById:TCompetition(_0:Int)
	End Function

	Function SelectByBasedAndName:TCompetition(_0:Int, _1:String)
	End Function

	Function SelectByTLA:TCompetition(_0:String)
	End Function

	Function SetUpCompetitionsAll:Int()
	End Function

	Method SetUpCompetition:Int()
	End Method

	Method CreateTeamPool:Int()
	End Method

	Method PopulateTeamPool:Int()
	End Method

	Method CreateFixtureListLeague:Int()
	End Method

	Method CreateFixtureListKO:Int()
	End Method

	Function GetHomeAndAwayTeam:Int(_0:*i, _1:*i, _2:Int, _3:Int)
	End Function

	Method CheckFixtureClash:Int(_0:TMyDate)
	End Method

	Method CheckCupQualifyingCompetitions:Int(_0:Int)
	End Method

	Method CheckFixtureClashAfterClubCupRound:Int()
	End Method

	Method GetMyContinentId:Int()
	End Method

	Method GetStringArray:String[]()
	End Method

	Function GetStringLocale:String(_0:Int)
	End Function

	Function GetStringLevel:String(_0:Int)
	End Function

	Function GetStringBased:String(_0:Int, _1:Int)
	End Function

	Function GetStringCompType:String(_0:Int)
	End Function

	Function GetStringRegion:String(_0:Int)
	End Function

	Method GetStringTeamPosition:String(_0:Int)
	End Method

	Method GetNoofQualifiers:Int()
	End Method

	Method GetNoofTeamsInRound:Int()
	End Method

	Method IsComplete:Int(_0:Int)
	End Method

	Function InflateIds:Int()
	End Function

	Function CompressIds:Int()
	End Function

	Method ChangeId:Int(_0:Int)
	End Method

	Method SetPriority:Int()
	End Method

	Method GetHighestClubNotInContinentalComp:TClub()
	End Method

	Method GetFixtureDate:TMyDate(_0:Int)
	End Method

	Method GetNoofRounds:Int()
	End Method

	Method GetPrevRound:Int()
	End Method

	Method GetNextRound:Int()
	End Method

	Method AllFixturesPlayed:Int()
	End Method

	Method AllFixturesPopulated:Int()
	End Method

	Method IsThisCurrentCupRound:Int()
	End Method

	Method GetCupFirstRound:TCompetition()
	End Method

	Method GetCupPreviousRound:TCompetition()
	End Method

	Method GetCupNextRound:TCompetition()
	End Method

	Method GetCupLastRound:TCompetition()
	End Method

	Method PaintPromotionPlaces:Int(_0:TTable)
	End Method

	Method PaintPromotedClubs:Int(_0:TTable)
	End Method

	Method GetBasedNationId:Int(_0:Int)
	End Method

	Method IsCupFinal:Int()
	End Method

	Method CountAllocatedContinentalClubsByNation:Int(_0:Int)
	End Method

	Function ResetCompStatusAll:Int()
	End Function

	Method IsTopDivision:Int()
	End Method

	Function ReorderCompetitions:Int()
	End Function

	Function VerifyCupDates:Int()
	End Function

	Function SortPromotionPlacesAll:Int()
	End Function

	Method SortPromotionPlaces:Int()
	End Method

	Method SortFixtureList:Int()
	End Method

	Function SortListBy:Int(_0:Int, _1:Int)
	End Function

	Method Compare:Int(_0:Object)
	End Method

	Function PlayFixtures:Int()
	End Function

	Method DoPromotionPlaces:Int()
	End Method

	Method PromoteToMe:Int(_0:TTableData, _1:TCompetition)
	End Method

	Function Test_UpdateNoofTeamsInLeagues:Int()
	End Function

	Function Test_CheckNoofTeamsInLeagues:Int()
	End Function

	Function ValidatePromotionPlacesAll:Int()
	End Function

	Method ValidatePromotionPlaces:Int()
	End Method

End Type

Type TScreen
	Field name:String	' +8
	Field gadgetlist:TList	' +12
	Field bg:TImage	' +16
	Field fDraw:()i	' +20
	Field fUpdate:()i	' +24
	Field lHelp:TList	' +28

	Method New:Int()
	End Method

	Method Delete:Int()
	End Method

	Function SetUp:Int()
	End Function

	Function SetUpFonts:Int(_0:String)
	End Function

	Function CreateScreen:TScreen(_0:String, _1:TImage, _2:()i, _3:()i)
	End Function

	Function ClearAll:Int()
	End Function

	Method AddGadget:Int(_0:TGadget)
	End Method

	Method Clear:Int()
	End Method

	Method ClearGadgetList:Int()
	End Method

	Method RemoveGadget:Int(_0:TGadget)
	End Method

	Method GetGadgetList:TList()
	End Method

	Function UpdateOffset:Int()
	End Function

	Function ResetScreens:Int()
	End Function

	Function SetActive:TScreen(_0:String, _1:String)
	End Function

	Function SetActiveGadget:Int(_0:String)
	End Function

	Function FindNewActiveGadget:Int()
	End Function

	Function Render:Int(_0:Float)
	End Function

	Method Draw:Int()
	End Method

	Function RenderBorder:Int()
	End Function

	Function DrawMouse:Int()
	End Function

	Function Update:Int()
	End Function

	Method CheckInput:Int()
	End Method

	Function GetInput:Int()
	End Function

	Method MoveSelection:Int(_0:Int)
	End Method

	Method MouseSelection:Int()
	End Method

	Method TabToGadget:Int()
	End Method

	Method GetGadgetByName:TGadget(_0:String)
	End Method

	Function DoMessage:Int(_0:String, _1:Int, _2:Int)
	End Function

	Function MessageDone:Int()
	End Function

	Function DoMessageGetText:String(_0:String, _1:Int)
	End Function

	Function TextEntered:Int()
	End Function

	Function InputDone:Int()
	End Function

	Function InputCancel:Int()
	End Function

	Function DoProgressBar:Int(_0:Float, _1:String, _2:String, _3:Int)
	End Function

	Function ButtonHelp:Int()
	End Function

	Function Tutorial:Int()
	End Function

	Function DoHelp:Int(_0:Int)
	End Function

	Function ButtonHelpOk:Int()
	End Function

	Function ButtonEndTutorial:Int()
	End Function

End Type

Type TGadget
	Field children:TList	' +8
	Field name:String	' +12
	Field txt:String	' +16
	Field txtalignx:Int	' +20
	Field txtlines:TList	' +24
	Field txtw:Float	' +28
	Field x:Float	' +32
	Field y:Float	' +36
	Field h:Float	' +40
	Field w:Float	' +44
	Field colour:String	' +48
	Field txtcolour:String	' +52
	Field alive:Int	' +56
	Field hidden:Int	' +60
	Field fHit:()i	' +64
	Field alph:Float	' +68
	Field forcetxtalpha:Int	' +72
	Field fntSize:Int	' +76
	Field lbl_ToolTip:TLabel	' +80
	Field desx:Float	' +84
	Field desy:Float	' +88

	Method New:Int()
	End Method

	Method Delete:Int()
	End Method

	Function SetUp:Int()
	End Function

	Method Update:Int()
	End Method

	Method UpdateChildren:Int()
	End Method

	Method UpdateToolTip:Int()
	End Method

	Method ClearChildren:Int()
	End Method

	Method Draw:Int()
	End Method

	Method DrawChildren:Int()
	End Method

	Method DrawHighlight:Int()
	End Method

	Method RenderHighlight:Int()
	End Method

	Method Hide:Int()
	End Method

	Method Show:Int()
	End Method

	Method SetFontSize:Int(_0:Int)
	End Method

	Method MouseOver:Int()
	End Method

	Method SetText:Int(_0:String, _1:String, _2:Int, _3:Int)
	End Method

	Method DrawGadgetText:Int(_0:String, _1:Int)
	End Method

	Method SetColour:Int(_0:String, _1:String)
	End Method

	Method SetAlph:Int(_0:Float)
	End Method

	Method AddChild:Int(_0:TGadget)
	End Method

	Method GetChildren:TList()
	End Method

	Function GetActiveGadgetName:String()
	End Function

	Method CreateToolTip:Int(_0:String)
	End Method

	Method SetPosition:Int(_0:Int, _1:Int, _2:Int)
	End Method

End Type

Type TButton
	Field bstyle:Int	' +92
	Field image:TImage	' +96
	Field imageoverride:Int	' +100
	Field icon:TImage	' +104

	Method New:Int()
	End Method

	Method Delete:Int()
	End Method

	Function CreateButton:TButton(_0:String, _1:String, _2:Int, _3:Int, _4:Int, _5:Int, _6:Int, _7:Int, _8:String, _9:String, _10:TImage, _11:()i, _12:Float, _13:Int, _14:String)
	End Function

	Method Update:Int()
	End Method

	Method Draw:Int()
	End Method

	Method SetImage:Int(_0:TImage)
	End Method

	Method SetIcon:Int(_0:TImage)
	End Method

	Method SetButtonStyle:Int(_0:Int)
	End Method

	Method SetAlph:Int(_0:Float)
	End Method

End Type

Type TInputBox
	Field limitchars:Int	' +92
	Field gettinginput:Int	' +96
	Field fRet:()i	' +100
	Field image:TImage	' +104
	Field hideinput:Int	' +108

	Method New:Int()
	End Method

	Method Delete:Int()
	End Method

	Function CreateInputBox:TInputBox(_0:String, _1:Int, _2:Int, _3:Int, _4:Int, _5:Int, _6:Int, _7:String, _8:String, _9:Int, _10:Float, _11:()i, _12:Int, _13:String)
	End Function

	Method CreateInputImage:Int()
	End Method

	Method Update:Int()
	End Method

	Method Draw:Int()
	End Method

	Function GetInputText:Int()
	End Function

	Method SetAlph:Int(_0:Float)
	End Method

	Method GetText:String()
	End Method

End Type

Type TTable
	Field columns:TList	' +92
	Field items:TList	' +96
	Field numdisplayitems:Int	' +100
	Field ih:Int	' +104
	Field activated:Int	' +108
	Field selecteditem:Int	' +112
	Field itemoffset:Int	' +116
	Field highlightcol:String	' +120
	Field showheadings:Int	' +124
	Field fRet:()i	' +128

	Method New:Int()
	End Method

	Method Delete:Int()
	End Method

	Function CreateTable:TTable(_0:String, _1:Int, _2:Int, _3:Int, _4:Int, _5:Int, _6:Int, _7:String, _8:Float, _9:Int, _10:()i)
	End Function

	Function CreateTableImage:Int()
	End Function

	Method AddColumn:Int(_0:Int, _1:String, _2:String, _3:String, _4:Int)
	End Method

	Method AddItem:Int(_0:String[], _1:String, _2:String)
	End Method

	Method SetItemIcons:Int(_0:Int, _1:TImage[])
	End Method

	Method ClearItems:Int()
	End Method

	Method SetColumnHeading:Int(_0:Int, _1:String)
	End Method

	Method SetColumnWidth:Int(_0:Int, _1:Int)
	End Method

	Method SetRowColoursAll:Int(_0:String)
	End Method

	Method SetRowColour:Int(_0:Int, _1:String)
	End Method

	Method SetHighlightColour:Int(_0:String)
	End Method

	Method SetItemText:Int(_0:Int, _1:Int, _2:String)
	End Method

	Method SetItemFields:Int(_0:Int, _1:String[])
	End Method

	Method SetAlph:Int(_0:Float)
	End Method

	Method Update:Int()
	End Method

	Method UpdateActivated:Int()
	End Method

	Method ScrollUp:Int()
	End Method

	Method ScrollDown:Int()
	End Method

	Method Draw:Int()
	End Method

	Method HighlightItem:Int()
	End Method

	Function ActivateTable:Int()
	End Function

	Method SelectCurrentItem:Int()
	End Method

	Method GetSelectedItem:Int()
	End Method

	Method GetSelectedText:String(_0:Int)
	End Method

	Method SelectItemByRow:Int(_0:Int)
	End Method

	Method SelectItemByText:Int(_0:String, _1:Int)
	End Method

	Method CheckTableOffset:Int()
	End Method

	Method ShowItem:Int(_0:Int)
	End Method

	Method CountItems:Int()
	End Method

	Method GetNoofDisplayItems:Int()
	End Method

	Method ShowColumnHeadings:Int()
	End Method

	Method HideColumnHeadings:Int()
	End Method

End Type

Type TColumn
	Field w:Int	' +8
	Field heading:String	' +12
	Field txtcolour:String	' +16
	Field bgcolour:String	' +20
	Field alignx:Int	' +24

	Method New:Int()
	End Method

	Method Delete:Int()
	End Method

End Type

Type TRow
	Field fields:String[]	' +8
	Field icons:TImage[]	' +12
	Field txtcolour:String	' +16
	Field bgcolour:String	' +20

	Method New:Int()
	End Method

	Method Delete:Int()
	End Method

End Type

Type TCombo
	Field btn_head:TButton	' +92
	Field buttons:TList	' +96
	Field activated:Int	' +100
	Field selecteditem:Int	' +104
	Field fRet:()i	' +108
	Field itemoffset:Int	' +112
	Field bstyle:Int	' +116

	Method New:Int()
	End Method

	Method Delete:Int()
	End Method

	Function CreateCombo:TCombo(_0:String, _1:String, _2:Int, _3:Int, _4:Int, _5:Int, _6:Int, _7:Int, _8:String, _9:String, _10:Float, _11:()i, _12:Int)
	End Function

	Method ClearItems:Int()
	End Method

	Method AddItem:Int(_0:String, _1:String, _2:String, _3:Int)
	End Method

	Method Update:Int()
	End Method

	Method ScrollUp:Int()
	End Method

	Method ScrollDown:Int()
	End Method

	Method GetNoofDisplayItems:Int()
	End Method

	Function Activate:Int()
	End Function

	Method Deactivate:Int()
	End Method

	Method Draw:Int()
	End Method

	Method DrawItems:Int()
	End Method

	Method SelectItem:Int(_0:Int)
	End Method

	Method SelectItemById:Int(_0:Int)
	End Method

	Method SelectItemByLetter:Int(_0:Int)
	End Method

	Method CountItems:Int()
	End Method

	Method GetSelectedItem:Int()
	End Method

	Method GetSelectedItemId:Int()
	End Method

	Method GetSelectedText:String()
	End Method

	Method GetSelectedColour:String()
	End Method

	Method SetColour:Int(_0:String, _1:String)
	End Method

	Method SetAlph:Int(_0:Float)
	End Method

End Type

Type TPanel
	Field image:TImage	' +92
	Field bodyimage:TImage	' +96

	Method New:Int()
	End Method

	Method Delete:Int()
	End Method

	Function CreatePanel:TPanel(_0:String, _1:String, _2:Int, _3:Int, _4:Int, _5:Int, _6:String, _7:String, _8:Int, _9:Float, _10:Int, _11:Int, _12:Int)
	End Function

	Method CreateBody:Int(_0:Int, _1:Int)
	End Method

	Method Update:Int()
	End Method

	Method Draw:Int()
	End Method

	Method SetAlph:Int(_0:Float)
	End Method

End Type

Type TLabel
	Field image:TImage	' +92
	Field imgborder:TImage	' +96
	Field style:Int	' +100
	Field icon:TImage	' +104
	Field pointer:Int	' +108
	Field pointerxoff:Int	' +112
	Field pointeryoff:Int	' +116
	Field scrolltext:Float	' +120
	Field scrollx:Float	' +124

	Method New:Int()
	End Method

	Method Delete:Int()
	End Method

	Function CreateLabel:TLabel(_0:String, _1:String, _2:Int, _3:Int, _4:Int, _5:Int, _6:Int, _7:String, _8:String, _9:Float, _10:Int, _11:Int, _12:Int, _13:Int, _14:TImage, _15:Int, _16:Int, _17:Int, _18:Int, _19:String, _20:Float)
	End Function

	Method Update:Int()
	End Method

	Method Draw:Int()
	End Method

	Method SetAlph:Int(_0:Float)
	End Method

	Method SetIcon:Int(_0:TImage)
	End Method

End Type

Type TProgressBar
	Field image:TImage	' +92
	Field fillimage:TImage	' +96
	Field fillicon:TImage	' +100
	Field fillcolour:String	' +104
	Field percent:Float	' +108
	Field livepercent:Float	' +112
	Field oldpercent:Float	' +116
	Field oldfillcolour:String	' +120
	Field oldfillalpha:Float	' +124
	Field oldfillfade:Int	' +128
	Field boosticon:TImage	' +132
	Field numboost:Int	' +136

	Method New:Int()
	End Method

	Method Delete:Int()
	End Method

	Function CreateProgressBar:TProgressBar(_0:String, _1:String, _2:Int, _3:Int, _4:Int, _5:Int, _6:Int, _7:String, _8:String, _9:String, _10:Float, _11:Int, _12:TImage)
	End Function

	Method Update:Int()
	End Method

	Method Draw:Int()
	End Method

	Method SetColour:Int(_0:String, _1:String)
	End Method

	Method SetPercent:Int(_0:Float, _1:Int)
	End Method

	Method SetOldPercent:Int(_0:Float, _1:Int)
	End Method

	Method SetBoostIcon:Int(_0:TImage, _1:Int)
	End Method

	Method SetAlph:Int(_0:Float)
	End Method

End Type

Type THelpBox
	Field lbl_Help1:TLabel	' +8
	Field lbl_Help2:TLabel	' +12
	Field btn_Ok:TButton	' +16
	Field btn_EndTutorial:TButton	' +20

	Method New:Int()
	End Method

	Method Delete:Int()
	End Method

	Function Create:THelpBox(_0:TGadget, _1:Int, _2:Int, _3:Int, _4:Int, _5:String, _6:Int, _7:Int)
	End Function

End Type

Type TScreen_Language
	Method New:Int()
	End Method

	Method Delete:Int()
	End Method

	Function CreateScreen:Int()
	End Function

	Function SetUpScreen:Int(_0:Int)
	End Function

	Function ButtonLanguage:Int()
	End Function

End Type

Type TScreen_MainMenu
	Method New:Int()
	End Method

	Method Delete:Int()
	End Method

	Function CreateScreen:Int()
	End Function

	Function SetUpScreen:Int()
	End Function

	Function LoadCredits:Int()
	End Function

	Function Update:Int()
	End Function

	Function ButtonQuit:Int()
	End Function

	Function NewGame:Int()
	End Function

	Function ButtonLoadGame:Int()
	End Function

	Function UpdateLoadTable:Int()
	End Function

	Function ButtonLoadSaveFile:Int()
	End Function

	Function ButtonDeleteSaveFile:Int()
	End Function

	Function ButtonReplays:Int()
	End Function

	Function UpdateReplayTable:Int()
	End Function

	Function ButtonLoadReplayFile:Int()
	End Function

	Function ButtonDeleteReplayFile:Int()
	End Function

	Function UpdateVersionInfo:Int()
	End Function

	Function ButtonHome:Int()
	End Function

	Function ButtonFacebook:Int()
	End Function

	Function ButtonTwitter:Int()
	End Function

	Function ButtonMobile:Int()
	End Function

End Type

Type TScreen_Options
	Method New:Int()
	End Method

	Method Delete:Int()
	End Method

	Function CreateScreen:Int()
	End Function

	Function SetUpScreen:Int()
	End Function

	Function RefreshButtons:Int()
	End Function

	Function ButtonLanguage:Int()
	End Function

	Function ButtonDifficulty:Int()
	End Function

	Function ButtonRadar:Int()
	End Function

	Function ButtonMatchLength:Int()
	End Function

	Function ButtonMatchSpeed:Int()
	End Function

	Function ButtonMusic:Int()
	End Function

	Function ButtonSFX:Int()
	End Function

	Function ButtonWindow:Int()
	End Function

	Function ResetScreen:Int()
	End Function

	Function ButtonCam:Int()
	End Function

	Function ComboRes:Int()
	End Function

	Function ButtonMatchFx:Int()
	End Function

	Function ButtonBossFx:Int()
	End Function

	Function ButtonDistance:Int()
	End Function

	Function ButtonToolTips:Int()
	End Function

	Function ButtonHighlightBall:Int()
	End Function

	Function ButtonShowEnergy:Int()
	End Function

	Function ButtonCurrency:Int()
	End Function

	Function ButtonFreekicks:Int()
	End Function

	Function ButtonCorners:Int()
	End Function

	Function ButtonBack:Int()
	End Function

	Function ButtonTick:Int()
	End Function

	Function ButtonFixKick:Int()
	End Function

End Type

Type TScreen_Controls
	Method New:Int()
	End Method

	Method Delete:Int()
	End Method

	Function CreateScreen:Int()
	End Function

	Function SetUpScreen:Int()
	End Function

	Function ButtonSimple:Int()
	End Function

	Function ButtonAdvanced:Int()
	End Function

	Function RefreshButtons:Int()
	End Function

	Function ButtonBack:Int()
	End Function

	Function ButtonTick:Int()
	End Function

	Function ButtonControls:Int()
	End Function

End Type

Type TScreen_NewPlayer
	Method New:Int()
	End Method

	Method Delete:Int()
	End Method

	Function CreateScreen:Int()
	End Function

	Function SetUpScreen:Int()
	End Function

	Function ComboNation:Int()
	End Function

	Function ComboClubNation:Int()
	End Function

	Function ComboClubLeague:Int()
	End Function

	Function ComboPosition:Int()
	End Function

	Function ComboSide:Int()
	End Function

	Function ComboSkin:Int()
	End Function

	Function ComboHair:Int()
	End Function

	Function RefreshKit:Int()
	End Function

	Function ButtonPlay:Int()
	End Function

	Function DoClubTrial:Int()
	End Function

	Function ButtonQuit:Int()
	End Function

End Type

Type TScreen_CreateAccount
	Method New:Int()
	End Method

	Method Delete:Int()
	End Method

	Function CreateScreen:Int()
	End Function

	Function SetUpScreen:Int()
	End Function

	Function ButtonPlay:Int()
	End Function

End Type

Type TScreen_Difficulty
	Method New:Int()
	End Method

	Method Delete:Int()
	End Method

	Function CreateScreen:Int()
	End Function

	Function SetUpScreen:Int()
	End Function

	Function ButtonEasy:Int()
	End Function

	Function ButtonNormal:Int()
	End Function

	Function ButtonHard:Int()
	End Function

End Type

Type TPromotionPlace
	Field parentid:Int	' +8
	Field place:Int	' +12
	Field promotiontoid:Int	' +16

	Method New:Int()
	End Method

	Method Delete:Int()
	End Method

	Function CreatePromotionPlace:Int(_0:String)
	End Function

	Function NewPromotionPlace:Int(_0:Int, _1:Int, _2:Int)
	End Function

	Function LoadData:Int(_0:TStream)
	End Function

	Function WriteData:Int(_0:TStream)
	End Function

	Function SaveMaster:Int(_0:Int, _1:Int)
	End Function

	Method AddToParentLists:Int()
	End Method

	Method GetStringPlace:String()
	End Method

	Method Compare:Int(_0:Object)
	End Method

End Type

Type TTeamPool
	Field list:TList	' +8

	Method New:Int()
	End Method

	Method Delete:Int()
	End Method

	Method LoadData:Int(_0:TStream)
	End Method

	Method WriteData:Int(_0:TStream)
	End Method

	Method AddItem:Int(_0:Int, _1:String, _2:Int)
	End Method

	Method AddItemLeagueContinuation:Int(_0:TTableData)
	End Method

	Method AddTableDataItem:Int(_0:TTableData)
	End Method

	Method Clear:Int()
	End Method

	Method GetItemById:TTableData(_0:Int)
	End Method

	Method GetItemByTeamId:TTableData(_0:Int)
	End Method

	Method GetTeamPosition:Int(_0:Int)
	End Method

	Method GetStringTeamPosition:String(_0:Int)
	End Method

	Method ShuffleIds:Int()
	End Method

	Method SortTableBy:Int(_0:Int)
	End Method

End Type

Type TTableData
	Field id:Int	' +8
	Field teamid:Int	' +12
	Field teamname:String	' +16
	Field teamstrength:Int	' +20
	Field played:Int	' +24
	Field won:Int	' +28
	Field drawn:Int	' +32
	Field lost:Int	' +36
	Field goalsf:Int	' +40
	Field goalsa:Int	' +44
	Field points:Int	' +48
	Field randno:Int	' +52
	Field longlat:Float	' +56

	Method New:Int()
	End Method

	Method Delete:Int()
	End Method

	Function Create:TTableData(_0:Int, _1:Int, _2:String, _3:Int)
	End Function

	Function LoadTableData:TTableData(_0:String)
	End Function

	Method WriteData:Int(_0:TStream)
	End Method

	Method GetStringArray:String[](_0:Int, _1:Int)
	End Method

	Method Compare:Int(_0:Object)
	End Method

End Type

Type TStadium
	Field id:Int	' +8
	Field name:String	' +12
	Field nation:Int	' +16
	Field capacity:Int	' +20
	Field longitude:Float	' +24
	Field latitude:Float	' +28

	Method New:Int()
	End Method

	Method Delete:Int()
	End Method

	Function CreateStadium:Int(_0:String)
	End Function

	Function LoadData:Int(_0:TStream)
	End Function

	Function WriteData:Int(_0:TStream)
	End Function

	Function SelectById:TStadium(_0:Int)
	End Function

End Type

Type TScreen_EditMenu
	Method New:Int()
	End Method

	Method Delete:Int()
	End Method

	Function CreateScreen:Int()
	End Function

	Function SetUpScreen:Int()
	End Function

	Function ButtonContinents:Int()
	End Function

	Function ButtonNations:Int()
	End Function

	Function ButtonTestData:Int()
	End Function

	Function ButtonSave:Int()
	End Function

	Function ButtonSaveMobile:Int()
	End Function

	Function ReorderData:Int()
	End Function

	Function ButtonQuit:Int()
	End Function

	Function SaveMasterFiles:Int(_0:Int)
	End Function

End Type

Type TScreen_EditContinents
	Method New:Int()
	End Method

	Method Delete:Int()
	End Method

	Function CreateScreen:Int()
	End Function

	Function SetUpScreen:Int(_0:Int)
	End Function

	Function ButtonQuit:Int()
	End Function

	Function ButtonPrevCont:Int()
	End Function

	Function ButtonNextCont:Int()
	End Function

	Function UpdateCont:Int()
	End Function

	Function GoMember:Int()
	End Function

End Type

Type TScreen_EditNations
	Method New:Int()
	End Method

	Method Delete:Int()
	End Method

	Function CreateScreen:Int()
	End Function

	Function SetUpScreen:Int(_0:Int)
	End Function

	Function ButtonQuit:Int()
	End Function

	Function ButtonPrevNat:Int()
	End Function

	Function ButtonNextNat:Int()
	End Function

	Function UpdateNat:Int()
	End Function

	Function ComboNation:Int()
	End Function

	Function GoMember:Int()
	End Function

	Function RefreshKits:Int()
	End Function

	Function EditKit:Int()
	End Function

End Type

Type TScreen_Clubs
	Method New:Int()
	End Method

	Method Delete:Int()
	End Method

	Function CreateScreen:Int()
	End Function

	Function SetUpScreen:Int()
	End Function

	Function ComboLocale:Int()
	End Function

	Function ComboBased:Int()
	End Function

	Function ButtonQuit:Int()
	End Function

	Function ButtonEdit:Int()
	End Function

	Function ButtonDelete:Int()
	End Function

	Function ButtonNew:Int()
	End Function

	Function ButtonSwitchNames:Int()
	End Function

End Type

Type TScreen_EditClubs
	Method New:Int()
	End Method

	Method Delete:Int()
	End Method

	Function CreateScreen:Int()
	End Function

	Function SetUpScreen:Int(_0:Int, _1:String)
	End Function

	Function ButtonQuit:Int()
	End Function

	Function ButtonPrevClub:Int()
	End Function

	Function ButtonNextClub:Int()
	End Function

	Function UpdateClub:Int()
	End Function

	Function RefreshKits:Int()
	End Function

	Function EditKit:Int()
	End Function

End Type

Type TScreen_Competitions
	Method New:Int()
	End Method

	Method Delete:Int()
	End Method

	Function CreateScreen:Int()
	End Function

	Function SetUpScreen:Int()
	End Function

	Function ButtonQuit:Int()
	End Function

	Function ButtonEdit:Int()
	End Function

	Function ButtonDelete:Int()
	End Function

	Function ButtonDuplicate:Int()
	End Function

	Function ButtonNew:Int()
	End Function

	Function ButtonInflateIds:Int()
	End Function

	Function ButtonCompressIds:Int()
	End Function

	Function ComboLevel:Int()
	End Function

	Function ComboLocale:Int()
	End Function

End Type

Type TScreen_EditCompetition
	Method New:Int()
	End Method

	Method Delete:Int()
	End Method

	Function CreateScreen:Int()
	End Function

	Function SetUpScreen:Int(_0:Int, _1:String)
	End Function

	Function ButtonQuit:Int()
	End Function

	Function ButtonAddPlace:Int()
	End Function

	Function ButtonDeletePlace:Int()
	End Function

	Function ButtonPrevComp:Int()
	End Function

	Function ButtonNextComp:Int()
	End Function

	Function UpdateComp:Int()
	End Function

End Type

Type TScreen_Promotions
	Method New:Int()
	End Method

	Method Delete:Int()
	End Method

	Function CreateScreen:Int()
	End Function

	Function SetUpScreen:Int()
	End Function

	Function ButtonQuit:Int()
	End Function

	Function ComboNation:Int()
	End Function

	Function ButtonPromote:Int()
	End Function

	Function ButtonRelegate:Int()
	End Function

End Type

Type TScreen_ContinentalComps
	Method New:Int()
	End Method

	Method Delete:Int()
	End Method

	Function CreateScreen:Int()
	End Function

	Function SetUpScreen:Int()
	End Function

	Function ButtonQuit:Int()
	End Function

	Function ComboContinent:Int()
	End Function

	Function ComboComp:Int()
	End Function

	Function RefreshQualifiers:Int()
	End Function

	Function ButtonEditComp:Int()
	End Function

	Function ButtonEditPlaceComp:Int()
	End Function

	Function ButtonEditClub:Int()
	End Function

	Function ButtonGoToClubs:Int()
	End Function

	Function RefreshClubCombo:Int()
	End Function

	Function ComboSelectClub:Int()
	End Function

	Function ButtonRemoveClub:Int()
	End Function

End Type

Type TScreen_EditKits
	Method New:Int()
	End Method

	Method Delete:Int()
	End Method

	Function CreateScreen:Int()
	End Function

	Function SetUpScreen:Int(_0:TBase_Team, _1:Int)
	End Function

	Function ButtonQuit:Int()
	End Function

	Function RefreshKits:Int()
	End Function

	Function UpdateKitCmb:Int()
	End Function

	Function UpdateKitInp:Int()
	End Function

End Type

Type TScreen_Calendar
	Method New:Int()
	End Method

	Method Delete:Int()
	End Method

	Function CreateScreen:Int()
	End Function

	Function SetUpScreen:Int()
	End Function

	Function ButtonQuit:Int()
	End Function

End Type

Type TDate
	Field gDate:Int	' +8

	Method New:Int()
	End Method

	Method Delete:Int()
	End Method

	Function Create:TDate(_0:Int, _1:Int, _2:Int)
	End Function

	Method SetDate:Int(_0:Int, _1:Int, _2:Int)
	End Method

	Method SetDateStr:Int(_0:String)
	End Method

	Method SetJulian:Int(_0:Int)
	End Method

	Method GetJulian:Int()
	End Method

	Method GetDate:Int(_0:*i, _1:*i, _2:*i)
	End Method

	Method GetString:String(_0:Int, _1:Int)
	End Method

	Method ChangeDate:Int(_0:Int, _1:Int, _2:Int)
	End Method

	Method GetWeekday:Int()
	End Method

	Function Weekday:Int(_0:Int)
	End Function

	Function GetStringWeekday:String(_0:Int, _1:Int)
	End Function

	Function GetStringMonth:String(_0:Int, _1:Int)
	End Function

	Function GetWeekdayDates:TDate[](_0:TDate, _1:TDate, _2:Int)
	End Function

	Method GetDayOfTheMonth:Int()
	End Method

	Method GetMonth:Int()
	End Method

	Method GetYear:Int()
	End Method

End Type

Type TMyDate
	Field sdate:Int	' +8

	Method New:Int()
	End Method

	Method Delete:Int()
	End Method

	Function Create:TMyDate(_0:Int, _1:Int, _2:Int)
	End Function

	Function CopyDate:TMyDate(_0:TMyDate)
	End Function

	Method SetDate:Int(_0:Int, _1:Int, _2:Int)
	End Method

	Method AddDays:Int(_0:Int)
	End Method

	Method AddWeeks:Int(_0:Int)
	End Method

	Method AddYears:Int(_0:Int)
	End Method

	Method SetDateByTraditionalDate:Int(_0:Int, _1:Int, _2:Int)
	End Method

	Method GetDay:Int()
	End Method

	Method GetWeek:Int()
	End Method

	Method GetYear:Int()
	End Method

	Method GetStringDay:String(_0:Int)
	End Method

	Method GetString:String(_0:String)
	End Method

End Type

Type TScreen_TestMenu
	Method New:Int()
	End Method

	Method Delete:Int()
	End Method

	Function CreateScreen:Int()
	End Function

	Function SetUpScreen:Int()
	End Function

	Function ButtonQuit:Int()
	End Function

End Type

Type TScreen_TestTournaments
	Method New:Int()
	End Method

	Method Delete:Int()
	End Method

	Function CreateScreen:Int()
	End Function

	Function SetUpScreen:Int()
	End Function

	Function ComboLevel:Int()
	End Function

	Function ComboLocale:Int()
	End Function

	Function ComboBased:Int()
	End Function

	Function ComboCompetition:Int()
	End Function

	Function FilterGroup:Int()
	End Function

	Function FilterRound:Int()
	End Function

	Function CheckGroups:Int()
	End Function

	Function CheckRounds:Int()
	End Function

	Function ButtonQuit:Int()
	End Function

	Function ButtonPlay:Int()
	End Function

End Type

Type TScreen_TestFixtures
	Method New:Int()
	End Method

	Method Delete:Int()
	End Method

	Function CreateScreen:Int()
	End Function

	Function SetUpScreen:Int()
	End Function

	Function CheckShowFixtures:Int(_0:TCompetition)
	End Function

	Function ButtonQuit:Int()
	End Function

	Function ButtonPlay:Int()
	End Function

	Function ComboContinent:Int()
	End Function

End Type

Type TScreen_GameMenu
	Method New:Int()
	End Method

	Method Delete:Int()
	End Method

	Function CreateScreen:Int()
	End Function

	Function SetUpScreen:Int()
	End Function

	Function UpdateTitlePanel:Int()
	End Function

	Function UpdateNavPanel:Int()
	End Function

	Function UpdateMatchRefresh:Int()
	End Function

	Function ButtonCompetitions:Int()
	End Function

	Function ButtonQuit:Int()
	End Function

	Function ButtonPlay:Int()
	End Function

	Function ButtonRelationships:Int()
	End Function

End Type

Type TScreen_Home
	Method New:Int()
	End Method

	Method Delete:Int()
	End Method

	Function CreateScreen:Int()
	End Function

	Function SetUpScreen:Int()
	End Function

	Function ButtonHappiness:Int()
	End Function

End Type

Type TScreen_Abilities
	Method New:Int()
	End Method

	Method Delete:Int()
	End Method

	Function CreateScreen:Int()
	End Function

	Function SetUpScreen:Int()
	End Function

	Function ButtonTraining:Int()
	End Function

End Type

Type TScreen_Relationships
	Method New:Int()
	End Method

	Method Delete:Int()
	End Method

	Function CreateScreen:Int()
	End Function

	Function SetUpScreen:Int(_0:Int)
	End Function

	Function ButtonRelationship:Int()
	End Function

	Function ButtonGirlEnd:Int()
	End Function

	Function ButtonTeamCasino:Int()
	End Function

	Function ButtonFriendsRacing:Int()
	End Function

End Type

Type TScreen_Shop
	Method New:Int()
	End Method

	Method Delete:Int()
	End Method

	Function CreateScreen:Int()
	End Function

	Function SetUpScreen:Int()
	End Function

	Function ButtonBuy:Int()
	End Function

	Function HidePanels:Int()
	End Function

End Type

Type TScreen_BootShop
	Method New:Int()
	End Method

	Method Delete:Int()
	End Method

	Function CreateScreen:Int()
	End Function

	Function SetUpScreen:Int()
	End Function

	Function ButtonBuy:Int()
	End Function

	Function ButtonPlay:Int()
	End Function

End Type

Type TScreen_Leagues
	Method New:Int()
	End Method

	Method Delete:Int()
	End Method

	Function CreateScreen:Int()
	End Function

	Function SetUpScreen:Int(_0:Int)
	End Function

	Function ButtonQuit:Int()
	End Function

	Function ComboContinent:Int()
	End Function

	Function ComboNation:Int()
	End Function

	Function ComboLeague:Int()
	End Function

	Function ComboClub:Int()
	End Function

	Function SetUpLeagueTable:Int()
	End Function

	Function SetUpLeagueFixtures:Int(_0:Int)
	End Function

	Function ButtonFixturesFirst:Int()
	End Function

	Function ButtonFixturesLeft:Int()
	End Function

	Function ButtonRound:Int()
	End Function

	Function ButtonFixturesRight:Int()
	End Function

	Function ButtonFixturesLast:Int()
	End Function

	Function ButtonLevel:Int()
	End Function

	Function RefreshComboColours:Int()
	End Function

End Type

Type TScreen_Continents
	Method New:Int()
	End Method

	Method Delete:Int()
	End Method

	Function CreateScreen:Int()
	End Function

	Function SetUpScreen:Int(_0:Int, _1:Int, _2:Int)
	End Function

	Function ButtonQuit:Int()
	End Function

	Function SelectLevel:Int(_0:Int)
	End Function

	Function ComboContinent:Int()
	End Function

	Function ComboCompetition:Int()
	End Function

	Function ComboTeam:Int()
	End Function

	Function SetUpFixturesTable:Int(_0:Int)
	End Function

	Function ButtonFixturesFirst:Int()
	End Function

	Function ButtonFixturesLeft:Int()
	End Function

	Function ButtonRound:Int()
	End Function

	Function ButtonFixturesRight:Int()
	End Function

	Function ButtonFixturesLast:Int()
	End Function

	Function SetUpLeagueTable:Int()
	End Function

	Function ButtonGroupsFirst:Int()
	End Function

	Function ButtonGroupsLeft:Int()
	End Function

	Function ButtonGroup:Int()
	End Function

	Function ButtonGroupsRight:Int()
	End Function

	Function ButtonGroupsLast:Int()
	End Function

	Function ButtonLevel:Int()
	End Function

	Function RefreshComboColours:Int()
	End Function

End Type

Type TScreen_Kits
	Method New:Int()
	End Method

	Method Delete:Int()
	End Method

	Function CreateScreen:Int()
	End Function

	Function SetUpScreen:Int(_0:TFixture, _1:()i, _2:()i)
	End Function

	Function ButtonChangeKits:Int()
	End Function

	Function RefreshKits:Int()
	End Function

	Function CreateKits:Int(_0:String)
	End Function

	Function ButtonPlay:Int()
	End Function

	Function Draw:Int()
	End Function

	Function ButtonQuit:Int()
	End Function

End Type

Type TScreen_MatchPaused
	Method New:Int()
	End Method

	Method Delete:Int()
	End Method

	Function CreateScreen:Int()
	End Function

	Function SetUpScreen:Int(_0:TImage)
	End Function

	Function ButtonContinue:Int()
	End Function

	Function ButtonReplay:Int()
	End Function

	Function ButtonTactics:Int()
	End Function

	Function ButtonOptions:Int()
	End Function

	Function ButtonSkipTime:Int()
	End Function

End Type

Type TScreen_Formation
	Method New:Int()
	End Method

	Method Delete:Int()
	End Method

	Function CreateScreen:Int()
	End Function

	Function SetUpScreen:Int(_0:Int)
	End Function

	Function ButtonFormation:Int()
	End Function

	Function RefreshButtons:Int()
	End Function

	Function Draw:Int()
	End Function

	Function CheckPosition:Int()
	End Function

	Function ChangePosition:Int()
	End Function

	Function CancelRequest:Int()
	End Function

	Function AskBoss:Int()
	End Function

	Function UpdatePosition:Int(_0:Int)
	End Function

	Function ButtonPlay:Int()
	End Function

	Function ButtonViewOpponent:Int()
	End Function

End Type

Type TScreen_Stats
	Method New:Int()
	End Method

	Method Delete:Int()
	End Method

	Function CreateScreen:Int()
	End Function

	Function SetUpScreen:Int()
	End Function

	Function ComboClub:Int()
	End Function

	Function UpdateStatTable:Int()
	End Function

	Function UpdateHistoryTable:Int()
	End Function

	Function ButtonMyHistory:Int()
	End Function

	Function ButtonMyStats:Int()
	End Function

End Type

Type TScreen_ContractOffer
	Method New:Int()
	End Method

	Method Delete:Int()
	End Method

	Function CreateScreen:Int()
	End Function

	Function SetUpScreen:Int(_0:TContractOffer, _1:()i, _2:()i)
	End Function

	Function UpdateCurrentContractDetails:Int()
	End Function

	Function UpdateOfferDetails:Int(_0:Int, _1:Int)
	End Function

	Function HideCurrentContract:Int()
	End Function

	Function ShowCurrentContract:Int()
	End Function

	Function HideNewContract:Int()
	End Function

	Function ButtonReject:Int()
	End Function

	Function ButtonNegotiate:Int()
	End Function

	Function ButtonAccept:Int()
	End Function

End Type

Type TScreen_MyContract
	Method New:Int()
	End Method

	Method Delete:Int()
	End Method

	Function CreateScreen:Int()
	End Function

	Function SetUpScreen:Int()
	End Function

	Function ButtonPlay:Int()
	End Function

	Function UpdateClubsInterestedLabel:Int()
	End Function

	Function UpdateClubsInterestedLabelForLoan:Int()
	End Function

	Function UpdateTransferStatus:Int()
	End Function

	Function UpdateDesiredCombos:Int()
	End Function

	Function ButtonRequestTransfer:Int()
	End Function

	Function ButtonRequestLoan:Int()
	End Function

	Function ComboContinent:Int()
	End Function

	Function ComboNation:Int()
	End Function

	Function ComboDivision:Int()
	End Function

	Function ComboClub:Int()
	End Function

	Function ButtonRenewContract:Int()
	End Function

	Function UpdateOfferButtons:Int()
	End Function

	Function ButtonOffer:Int()
	End Function

End Type

Type TScreen_Dilemma
	Method New:Int()
	End Method

	Method Delete:Int()
	End Method

	Function CreateScreen:Int()
	End Function

	Function SetUpScreen:Int()
	End Function

	Function ButtonRelationship:Int()
	End Function

	Function Draw:Int()
	End Function

End Type

Type TScreen_Finances
	Method New:Int()
	End Method

	Method Delete:Int()
	End Method

	Function CreateScreen:Int()
	End Function

	Function SetUpScreen:Int()
	End Function

	Function ButtonSell:Int()
	End Function

End Type

Type TScreen_Newspaper
	Method New:Int()
	End Method

	Method Delete:Int()
	End Method

	Function CreateScreen:Int()
	End Function

	Function SetUpScreen:Int()
	End Function

	Function Play:Int()
	End Function

	Function Draw:Int()
	End Function

End Type

Type TScreen_Achievements
	Method New:Int()
	End Method

	Method Delete:Int()
	End Method

	Function CreateScreen:Int()
	End Function

	Function SetUpScreen:Int()
	End Function

End Type

Type TScreen_WorldMap
	Method New:Int()
	End Method

	Method Delete:Int()
	End Method

	Function CreateScreen:Int()
	End Function

	Function SetUpScreen:Int()
	End Function

	Function Draw:Int()
	End Function

	Function ButtonGame:Int()
	End Function

	Function ButtonMusic:Int()
	End Function

	Function ButtonFilm:Int()
	End Function

	Function UpdateTravelTime:Int()
	End Function

End Type

Type TScreen_MatchPrep
	Method New:Int()
	End Method

	Method Delete:Int()
	End Method

	Function CreateScreen:Int()
	End Function

	Function SetUpScreen:Int()
	End Function

	Function ButtonDrugs:Int()
	End Function

	Function ButtonNRG:Int()
	End Function

	Function ButtonPainKillers:Int()
	End Function

	Function ButtonBooze:Int()
	End Function

	Function ButtonShinPads:Int()
	End Function

	Function ButtonSkipMatch:Int()
	End Function

	Function ButtonPlay:Int()
	End Function

	Function NextFixture:Int(_0:Int)
	End Function

End Type

Type TScreen_SeasonReview
	Method New:Int()
	End Method

	Method Delete:Int()
	End Method

	Function CreateScreen:Int()
	End Function

	Function SetUpScreen:Int()
	End Function

	Function UpdateSeasonStats:Int()
	End Function

	Function UpdateSeasonTournaments:Int()
	End Function

	Function ButtonPlay:Int()
	End Function

End Type

Type TScreen_WebPage
	Method New:Int()
	End Method

	Method Delete:Int()
	End Method

	Function CreateScreen:Int()
	End Function

	Function SetUpScreen:Int(_0:String, _1:String)
	End Function

	Function ButtonPlay:Int()
	End Function

	Function ButtonTwitter:Int()
	End Function

	Function ButtonFacebook:Int()
	End Function

	Function GetSocialMessage:String(_0:Int)
	End Function

End Type

Type TScreen_ReportPhysio
	Method New:Int()
	End Method

	Method Delete:Int()
	End Method

	Function CreateScreen:Int()
	End Function

	Function SetUpScreen:Int()
	End Function

	Function ButtonPlay:Int()
	End Function

	Function Draw:Int()
	End Function

End Type

Type TScreen_ReportBoss
	Method New:Int()
	End Method

	Method Delete:Int()
	End Method

	Function CreateScreen:Int()
	End Function

	Function SetUpScreen:Int()
	End Function

	Function ButtonPlay:Int()
	End Function

	Function Draw:Int()
	End Function

End Type

Type TProfile
	Field gNetStatus:Int	' +8
	Field saveversion:String	' +12
	Field date:TMyDate	' +16
	Field name:String	' +20
	Field dbName:String	' +24
	Field nationid:Int	' +28
	Field clubid:Int	' +32
	Field playercols:TPlayerColours	' +36
	Field bank:Int	' +40
	Field newstarselno:Int	' +44
	Field position:Int	' +48
	Field side:Int	' +52
	Field internationalselno:Int	' +56
	Field retired:Int	' +60
	Field careerstats:TList	' +64
	Field newsheadline:String	' +68
	Field newsrating:Int	' +72
	Field newsmotm:Int	' +76
	Field webheadline:String	' +80
	Field bossreport:String	' +84
	Field physioreport:String	' +88
	Field coachreport:String	' +92
	Field coachrep_boss:Int	' +96
	Field coachrep_team:Int	' +100
	Field coachrep_fans:Int	' +104
	Field coachrep_sponsors:Int	' +108
	Field coachrep_fame:Int	' +112
	Field contractexpires:Int	' +116
	Field contractwage:Int	' +120
	Field contractgoalbonus:Int	' +124
	Field contractassistbonus:Int	' +128
	Field contractcleanbonus:Int	' +132
	Field lastweeksgoalbonus:Int	' +136
	Field lastweeksassistbonus:Int	' +140
	Field lastweekscleanbonus:Int	' +144
	Field thisweeksgoalbonus:Int	' +148
	Field thisweeksassistbonus:Int	' +152
	Field thisweekscleanbonus:Int	' +156
	Field lastweeksshirtsales:Int	' +160
	Field pace:Int	' +164
	Field shooting:Int	' +168
	Field passing:Int	' +172
	Field tackling:Int	' +176
	Field heading:Int	' +180
	Field dribbling:Int	' +184
	Field flair:Int	' +188
	Field interviewskill:Int	' +192
	Field crossing:Int	' +196
	Field freekicks:Int	' +200
	Field corners:Int	' +204
	Field positioning:Int	' +208
	Field shortpassing:Int	' +212
	Field longpassing:Int	' +216
	Field aggression:Int	' +220
	Field longshots:Int	' +224
	Field finishing:Int	' +228
	Field penalties:Int	' +232
	Field boots:Int[]	' +236
	Field items:Int[]	' +240
	Field vehicles:Int[]	' +244
	Field property:Int[]	' +248
	Field sponsor_amount:Int[]	' +252
	Field sponsor_expires:Int[]	' +256
	Field relationboss:Int	' +260
	Field relationteam:Int	' +264
	Field relationfans:Int	' +268
	Field relationfriends:Int	' +272
	Field relationgirlfriend:Int	' +276
	Field relationsponsors:Int	' +280
	Field relationfame:Int	' +284
	Field captain:Int	' +288
	Field girlscandalrating:Int	' +292
	Field lastspendtimefriends:Int	' +296
	Field lastspendtimegirlfriend:Int	' +300
	Field playbuttontype:Int	' +304
	Field transferlisted:Int	' +308
	Field desiredcontinentid:Int	' +312
	Field desirednationid:Int	' +316
	Field desiredleagueid:Int	' +320
	Field desiredclubid:Int	' +324
	Field onloanfrom:Int	' +328
	Field loanexpires:Int	' +332
	Field oldbossrel:Int	' +336
	Field oldteamrel:Int	' +340
	Field oldfansrel:Int	' +344
	Field energy:Float	' +348
	Field NRG:Int	' +352
	Field booze:Int	' +356
	Field gambling:Int	' +360
	Field injury:Int	' +364
	Field freetime:Int	' +368
	Field takenpainkillers:Int	' +372
	Field shinpads:Int	' +376
	Field boughtmusic:Int	' +380
	Field boughtgame:Int	' +384
	Field boughtfilm:Int	' +388
	Field drugs:Int	' +392
	Field currentyellowsclub:Int	' +396
	Field currentyellowscontinent:Int	' +400
	Field currentyellowsinternational:Int	' +404
	Field banclub:Int	' +408
	Field bancontinent:Int	' +412
	Field baninternational:Int	' +416
	Field interestedclubs:Int[]	' +420
	Field lasttransferdate:Int	' +424
	Field skillshash:String	' +428
	Field passhash:String	' +432
	Field premiumhash:String	' +436
	Field lastconnecthash:String	' +440
	Field achievements:Int[]	' +444
	Field history:TList	' +448
	Field tipcount:Int	' +452
	Field helppages:Int[]	' +456
	Field mynation:TNation	' +460
	Field myclub:TClub	' +464
	Field mylastfixture:TFixture	' +468
	Field selectedformatch:Int	' +472
	Field matchskipped:Int	' +476
	Field interviewchance:Int	' +480
	Field formationchanged:Int	' +484
	Field matchesleft:Int	' +488
	Field matcheswait:Int	' +492
	Field timecheck:Int	' +496
	Field temp_crossing:Int	' +500
	Field temp_freekicks:Int	' +504
	Field temp_corners:Int	' +508
	Field temp_positioning:Int	' +512
	Field temp_shortpassing:Int	' +516
	Field temp_longpassing:Int	' +520
	Field temp_aggression:Int	' +524
	Field temp_longshots:Int	' +528
	Field temp_finishing:Int	' +532
	Field temp_penalties:Int	' +536
	Field prematchsaved:Int	' +540

	Method New:Int()
	End Method

	Method Delete:Int()
	End Method

	Function SetUp:Int()
	End Function

	Method LoadProfile:Int(_0:TStream)
	End Method

	Method SaveProfile:Int(_0:TStream)
	End Method

	Function LoadSavedGame:Int(_0:String)
	End Function

	Method SaveGame:Int(_0:String)
	End Method

	Function StartNewGame:Int()
	End Function

	Method StartCareer:Int()
	End Method

	Method CreateNewClubStats:Int(_0:Int)
	End Method

	Method CreateNewInternationalStats:Int()
	End Method

	Method Play:Int(_0:Int)
	End Method

	Method GetNextFixture:TFixture(_0:Int)
	End Method

	Method GetNextOpponent:TBase_Team(_0:*i, _1:*i)
	End Method

	Method PlayNextFixture:Int(_0:Int)
	End Method

	Function FixturePlayed:Int()
	End Function

	Method UpdateSelectedForMatch:Int(_0:Float)
	End Method

	Method NextPlayButton:Int()
	End Method

	Method SetPlayButtonIcon:Int()
	End Method

	Method RandomIncident:Int()
	End Method

	Method GetNewTip:String()
	End Method

	Method GetCurrentTip:String()
	End Method

	Method DoNews:String(_0:String, _1:TBase_Team, _2:TBase_Team, _3:Int, _4:Int)
	End Method

	Method GetStringContractExpires:String()
	End Method

	Method GetStat:Float(_0:Int, _1:Int, _2:Int, _3:Int)
	End Method

	Method GetStringStat:String(_0:Int, _1:Int, _2:Int, _3:Int, _4:Int)
	End Method

	Method GetStats:TList(_0:Int, _1:Int, _2:Int)
	End Method

	Method GetCurrentStats:TStats_Team(_0:Int)
	End Method

	Method GetAverageForm:Float(_0:Int, _1:Int, _2:Int)
	End Method

	Method GetLastMatchRating:Int(_0:Int)
	End Method

	Method GetAge:Int()
	End Method

	Method GetSkillRating:Int()
	End Method

	Method UpdateAbility:Int(_0:Int, _1:Int)
	End Method

	Method SetAbility:Int(_0:Int, _1:Int)
	End Method

	Method CheckSkillHash:Int()
	End Method

	Method WearBoots:Int()
	End Method

	Method GetValue:Int()
	End Method

	Method GetStatus:Float()
	End Method

	Method UpdateRelationship:Int(_0:Int, _1:Int)
	End Method

	Method GetHappiness:Int()
	End Method

	Method GetSponsorshipAmount:Int()
	End Method

	Method GetRentCosts:Int()
	End Method

	Method GetPropertyCosts:Int()
	End Method

	Method GetLastWeeksShirtSales:Int()
	End Method

	Method GetVehicleCosts:Int()
	End Method

	Method GetTotalSponsorship:Int()
	End Method

	Method GetStringArraySponsor:String[](_0:Int)
	End Method

	Method GetStringArrayItemsOwned:String[](_0:Int)
	End Method

	Method GetStringArrayVehiclesOwned:String[](_0:Int)
	End Method

	Method SellItemByName:Int(_0:String)
	End Method

	Method GetStringArrayPropertyOwned:String[](_0:Int)
	End Method

	Method GetLifestyle:Int()
	End Method

	Method GetFame:Float()
	End Method

	Method UpdateBank:Int(_0:Int)
	End Method

	Method UpdateEnergy:Int(_0:Float)
	End Method

	Method Bet:Int(_0:Int)
	End Method

	Method UpdateFinances:Int()
	End Method

	Method GetStableSize:Int()
	End Method

	Method UpdateHealth:Int()
	End Method

	Method DoInjury:Int()
	End Method

	Method LoseRandomSkillPoint:String(_0:Int)
	End Method

	Method GetPropertyCount:Int()
	End Method

	Method GotSponsor:Int()
	End Method

	Method CheckSponsorExpiry:Int()
	End Method

	Method OfferSponsorship:Int(_0:Int)
	End Method

	Method BuyBoots:Int(_0:Int)
	End Method

	Method GetPaceCap:Int()
	End Method

	Method UpdateMyRatings:Int()
	End Method

	Method ShowRatingChanges:Int()
	End Method

	Method CheckLoanEnd:Int()
	End Method

	Method GoOnLoan:Int(_0:Int)
	End Method

	Method CancelLoan:Int()
	End Method

	Method TooSoonSinceLastContract:Int()
	End Method

	Method GetAchievements:Int()
	End Method

	Method CheckAchievement:Int(_0:Int)
	End Method

	Method CheckPurchaseAchievements:Int()
	End Method

	Method ResetTutorial:Int(_0:Int)
	End Method

	Method GetHashtaglessName:String()
	End Method

	Method GetOriginalName:String()
	End Method

	Function DeleteCorruptKoreanData:Int()
	End Function

End Type

Type TStats_Match
	Field list:TList	' +8
	Field yellows:Int	' +12
	Field reds:Int	' +16
	Field distance:Float	' +20
	Field lastdistancetime:Int	' +24
	Field subbedontime:Int	' +28
	Field subbedofftime:Int	' +32
	Field motm:Int	' +36
	Field rating:Int	' +40

	Method New:Int()
	End Method

	Method Delete:Int()
	End Method

	Method Clear:Int()
	End Method

	Function Create:TStats_Match()
	End Function

	Method AddStat:Int(_0:Int, _1:Int, _2:Int, _3:Int, _4:Float, _5:Int)
	End Method

	Method CountStat:Int(_0:Int)
	End Method

	Method DrawPitch:Int(_0:Int, _1:Int)
	End Method

	Method SortListBy:Int(_0:Int)
	End Method

	Method UpdateRating:Int(_0:Int, _1:Int, _2:Int, _3:Int, _4:Int, _5:Int)
	End Method

	Method GetPlayTime:Int(_0:Int)
	End Method

End Type

Type TStat
	Field stype:Int	' +8
	Field minute:Int	' +12
	Field x:Int	' +16
	Field y:Int	' +20
	Field direction:Float	' +24
	Field distance:Float	' +28

	Method New:Int()
	End Method

	Method Delete:Int()
	End Method

	Function Create:TStat(_0:Int, _1:Int, _2:Int, _3:Int, _4:Float, _5:Float)
	End Function

	Method Compare:Int(_0:Object)
	End Method

End Type

Type TStats_Team
	Field statlevel:Int	' +8
	Field teamid:Int	' +12
	Field year:Int	' +16
	Field appearances:Int	' +20
	Field subs:Int	' +24
	Field shots:Int	' +28
	Field goals:Int	' +32
	Field hattricks:Int	' +36
	Field passes:Int	' +40
	Field assists:Int	' +44
	Field headers:Int	' +48
	Field tackles:Int	' +52
	Field fouls:Int	' +56
	Field yellowcards:Int	' +60
	Field redcards:Int	' +64
	Field distance:Int	' +68
	Field manofthematch:Int	' +72
	Field form:Int[]	' +76

	Method New:Int()
	End Method

	Method Delete:Int()
	End Method

	Function Create:TStats_Team(_0:Int, _1:Int, _2:Int)
	End Function

	Method UpdateStats:Int(_0:TStats_Match)
	End Method

	Method WriteData:Int(_0:TStream)
	End Method

	Function CreateFromString:TStats_Team(_0:String)
	End Function

End Type

Type THistory
	Field year:Int	' +8
	Field clubid:Int	' +12
	Field nationid:Int	' +16
	Field text:String	' +20
	Field compid:Int	' +24
	Field winner:Int	' +28

	Method New:Int()
	End Method

	Method Delete:Int()
	End Method

	Method WriteData:Int(_0:TStream)
	End Method

	Function CreateFromString:THistory(_0:String)
	End Function

	Function Create:THistory(_0:Int, _1:Int, _2:Int, _3:String, _4:Int, _5:Int)
	End Function

End Type

Type TParticle
	Field x:Float	' +8
	Field y:Float	' +12
	Field dir:Float	' +16
	Field vel:Float	' +20
	Field scale:Float	' +24
	Field alph:Float	' +28
	Field rot:Float	' +32
	Field grav:Float	' +36
	Field inflate:Float	' +40
	Field colour:String	' +44
	Field txt:String	' +48

	Method New:Int()
	End Method

	Method Delete:Int()
	End Method

	Function ClearAll:Int()
	End Function

	Function SetUp:Int()
	End Function

	Function StarShower:Int(_0:Int, _1:Int, _2:String, _3:String)
	End Function

	Function CreateParticle:Int(_0:Float, _1:Float, _2:Float, _3:Float, _4:Float, _5:Float, _6:Float, _7:Float, _8:Float, _9:String, _10:String)
	End Function

	Function UpdateParticlesAll:Int()
	End Function

	Method Update:Int()
	End Method

	Function RenderParticlesAll:Int(_0:Float, _1:Float, _2:Float)
	End Function

	Method Render:Int(_0:Float, _1:Float, _2:Float)
	End Method

	Function Count:Int()
	End Function

End Type

Type TScreenMessage
	Field x:Int	' +8
	Field y:Int	' +12
	Field message:String	' +16
	Field starttime:Int	' +20
	Field delaytime:Int	' +24
	Field finishtime:Int	' +28
	Field delaystart:Int	' +32
	Field alfa:Float	' +36
	Field bmfnt:TBitmapFont	' +40
	Field img:TImage	' +44
	Field imgScale:Float	' +48
	Field colour:String	' +52
	Field lbl:TLabel	' +56

	Method New:Int()
	End Method

	Method Delete:Int()
	End Method

	Function Create:Int(_0:Int, _1:Int, _2:String, _3:Int, _4:TBitmapFont, _5:TImage, _6:Float, _7:String)
	End Function

	Function Count:Int()
	End Function

	Function DrawAll:Int()
	End Function

	Method Draw:Int()
	End Method

	Function ClearAll:Int(_0:Int)
	End Function

	Function ClearAlerts:Int()
	End Function

	Function CreateAlert:Int(_0:Int, _1:Int, _2:String, _3:Int, _4:String, _5:String, _6:TImage, _7:Int, _8:Int, _9:Int, _10:Int, _11:Int)
	End Function

	Function RemoveFirst:Int()
	End Function

End Type

Type TBossMessage
	Field homeboss:Int	' +8
	Field x:Float	' +12
	Field y:Float	' +16
	Field message:String	' +20
	Field starttime:Int	' +24
	Field delaytime:Int	' +28
	Field finishtime:Int	' +32
	Field delaystart:Int	' +36
	Field alfa:Float	' +40
	Field colour:String	' +44
	Field flipit:Int	' +48

	Method New:Int()
	End Method

	Method Delete:Int()
	End Method

	Function SetUp:Int()
	End Function

	Function Create:Int(_0:Int, _1:String, _2:String)
	End Function

	Function DrawAll:Int(_0:Float, _1:Float, _2:Float)
	End Function

	Method Draw:Int(_0:Float, _1:Float, _2:Float)
	End Method

	Function ClearAll:Int()
	End Function

End Type

Type TContractOffer
	Field club:TClub	' +8
	Field wage:Int	' +12
	Field length:Int	' +16
	Field goalbonus:Int	' +20
	Field assistbonus:Int	' +24
	Field cleanbonus:Int	' +28
	Field signingfee:Int	' +32
	Field newbossrel:Int	' +36
	Field negotiationsuccess:Int	' +40

	Method New:Int()
	End Method

	Method Delete:Int()
	End Method

	Function LoadData:Int(_0:TStream)
	End Function

	Function WriteData:Int(_0:TStream)
	End Function

	Function CreateContract:Int(_0:String)
	End Function

	Function GetOffer:TContractOffer(_0:TClub)
	End Function

	Method DoNegotiation:Int()
	End Method

	Method IncreaseOffer:Int(_0:Int)
	End Method

	Method GetStringLength:String()
	End Method

	Function EraseInterestedClubs:Int()
	End Function

	Function TransferWindowOpen:Int()
	End Function

	Function CheckTransferWindow:Int()
	End Function

	Function GetInitialClub:TClub(_0:Int)
	End Function

	Function UpdateInterestedClubs:Int()
	End Function

	Function GetClubsInterestedInLoan:TList()
	End Function

	Function GetPlayerValueStatus:Int()
	End Function

	Function CheckClubCanAffordPlayer:Int(_0:TClub)
	End Function

	Method SignForNewClub:Int()
	End Method

	Function CheckPromoteFromBTeam:Int()
	End Function

	Function DoTransferRumour:Int()
	End Function

End Type

Type TScreen_Casino
	Method New:Int()
	End Method

	Method Delete:Int()
	End Method

	Function CreateScreen:Int()
	End Function

	Function UpdateStakeCurrency:Int()
	End Function

	Function SetUpScreen:Int()
	End Function

	Function SetStake:Int()
	End Function

	Function GetChipImage:TImage(_0:Int)
	End Function

	Function ButtonBlackJack:Int()
	End Function

	Function ButtonRoulette:Int()
	End Function

	Function ButtonSlots:Int()
	End Function

	Function ShowTitleButtons:Int()
	End Function

	Function HideTitleButtons:Int()
	End Function

	Function ButtonRelationships:Int()
	End Function

End Type

Type TScreen_Roulette
	Method New:Int()
	End Method

	Method Delete:Int()
	End Method

	Function CreateScreen:Int()
	End Function

	Function SetUpScreen:Int(_0:Int)
	End Function

	Function ButtonPlay:Int()
	End Function

	Function PlaceBet:Int()
	End Function

	Function IncreaseBet:Int(_0:*i)
	End Function

	Function ClearBets:Int()
	End Function

	Function UpdateBetLabels:Int()
	End Function

	Function GetBetTotal:Int()
	End Function

End Type

Type TRoulette
	Method New:Int()
	End Method

	Method Delete:Int()
	End Method

	Function SetUp:Int()
	End Function

	Function Spin:Int()
	End Function

	Function Update:Int()
	End Function

	Function Draw:Int()
	End Function

	Function GetResult:Int()
	End Function

End Type

Type TRouletteWheel
	Field iWheelSize:Int	' +8
	Field iRimSize:Int	' +12
	Field fX:Float	' +16
	Field fY:Float	' +20
	Field fRot:Float	' +24
	Field oldfRot:Float	' +28
	Field fSpeed:Float	' +32

	Method New:Int()
	End Method

	Method Delete:Int()
	End Method

	Function Create:TRouletteWheel()
	End Function

	Method Reset:Int()
	End Method

	Method Update:Int()
	End Method

	Method Draw:Int(_0:Float)
	End Method

	Function GetColour:Int(_0:Int)
	End Function

End Type

Type TRouletteBall
	Field fLineRot:Float	' +8
	Field fSpeed:Float	' +12
	Field fDist:Float	' +16
	Field fVel:Float	' +20
	Field fX:Float	' +24
	Field fY:Float	' +28
	Field oldfX:Float	' +32
	Field oldfY:Float	' +36
	Field fPocket:Float	' +40
	Field bStopped:Int	' +44

	Method New:Int()
	End Method

	Method Delete:Int()
	End Method

	Function Create:TRouletteBall()
	End Function

	Method Reset:Int(_0:TRouletteWheel)
	End Method

	Method Update:Int(_0:TRouletteWheel)
	End Method

	Method Draw:Int(_0:Float)
	End Method

End Type

Type TScreen_BlackJack
	Method New:Int()
	End Method

	Method Delete:Int()
	End Method

	Function CreateScreen:Int()
	End Function

	Function SetUpScreen:Int()
	End Function

	Function ButtonPlay:Int()
	End Function

	Function ButtonQuit:Int()
	End Function

	Function UpdateScoreLabels:Int()
	End Function

	Function Win:Int()
	End Function

	Function Tie:Int()
	End Function

	Function Lose:Int()
	End Function

End Type

Type TBlackJack
	Method New:Int()
	End Method

	Method Delete:Int()
	End Method

	Function SetUp:Int()
	End Function

	Function Update:Int()
	End Function

	Function Reset:Int()
	End Function

	Function Deal:Int()
	End Function

	Function Play:Int()
	End Function

	Function CheckPlayerScore:Int()
	End Function

	Function DealersTurn:Int()
	End Function

	Function Hit:Int(_0:TList)
	End Function

	Function Hold:Int()
	End Function

	Function Draw:Int()
	End Function

	Function GetDealerScore:Int(_0:*i, _1:*i)
	End Function

	Function GetPlayerScore:Int(_0:*i, _1:*i)
	End Function

	Function ShowResult:Int()
	End Function

End Type

Type TCard
	Field img:TImage	' +8
	Field randno:Int	' +12
	Field num:Int	' +16
	Field suit:String	' +20

	Method New:Int()
	End Method

	Method Delete:Int()
	End Method

	Function SetUp:Int()
	End Function

	Function CreateCard:TCard(_0:Int, _1:String)
	End Function

	Function Shuffle:Int()
	End Function

	Function Pull:TCard()
	End Function

	Method Compare:Int(_0:Object)
	End Method

End Type

Type TScreen_Slots
	Method New:Int()
	End Method

	Method Delete:Int()
	End Method

	Function CreateScreen:Int()
	End Function

	Function SetUpScreen:Int()
	End Function

	Function ButtonPlay:Int()
	End Function

End Type

Type TSlotMachine
	Method New:Int()
	End Method

	Method Delete:Int()
	End Method

	Function SetUp:Int()
	End Function

	Function Reset:Int()
	End Function

	Function Update:Int()
	End Function

	Function Draw:Int()
	End Function

	Function Spin:Int()
	End Function

	Function DoPrize:Int()
	End Function

End Type

Type TSlotStrip
	Field reelH:Int	' +8
	Field fruitCount:Int	' +12
	Field xPos:Int	' +16
	Field yPos1:Float	' +20
	Field yPos2:Float	' +24
	Field yVel:Float	' +28
	Field spintime:Int	' +32
	Field spinlength:Int	' +36
	Field reelstopped:Int	' +40
	Field fruit:Int	' +44

	Method New:Int()
	End Method

	Method Delete:Int()
	End Method

	Method SetUp:Int(_0:Int, _1:Int)
	End Method

	Method Update:Int()
	End Method

	Method Spin:Int(_0:Int)
	End Method

	Method Draw:Int()
	End Method

End Type

Type TScreen_Pairs
	Method New:Int()
	End Method

	Method Delete:Int()
	End Method

	Function CreateScreen:Int()
	End Function

	Function SetUpScreen:Int(_0:Int)
	End Function

	Function ResetButtonPositions:Int()
	End Function

	Function NewButtonPositions:Int()
	End Function

	Function ClickCard:Int()
	End Function

	Function UpdateFaces:Int()
	End Function

	Function Update:Int()
	End Function

	Function DisableAll:Int()
	End Function

	Function EnableAll:Int()
	End Function

	Function Success:Int(_0:Int)
	End Function

	Function Fail:Int()
	End Function

End Type

Type TPair_Icon
	Field id:Int	' +8
	Field imgId:Int	' +12
	Field randno:Int	' +16
	Field back:TImage	' +20
	Field front:TImage	' +24
	Field picked:Int	' +28

	Method New:Int()
	End Method

	Method Delete:Int()
	End Method

	Function CreateAll:Int()
	End Function

	Function SetUp:Int(_0:Int)
	End Function

	Method Compare:Int(_0:Object)
	End Method

End Type

Type TButtonPos
	Field randno:Int	' +8
	Field x:Float	' +12
	Field y:Float	' +16

	Method New:Int()
	End Method

	Method Delete:Int()
	End Method

	Function Create:TButtonPos(_0:Float, _1:Float)
	End Function

	Method Compare:Int(_0:Object)
	End Method

End Type

Type TScreen_Negotiate
	Method New:Int()
	End Method

	Method Delete:Int()
	End Method

	Function CreateScreen:Int()
	End Function

	Function SetUpScreen:Int(_0:TContractOffer)
	End Function

	Function ButtonLower:Int()
	End Function

	Function ButtonHigher:Int()
	End Function

	Function Update:Int()
	End Function

	Function Success:Int()
	End Function

	Function Fail:Int()
	End Function

	Function UpdateInstrucs:Int()
	End Function

	Function ButtonOk:Int()
	End Function

	Function ButtonAccept:Int()
	End Function

End Type

Type TScreen_Interview
	Method New:Int()
	End Method

	Method Delete:Int()
	End Method

	Function CreateScreen:Int()
	End Function

	Function SetUpScreen:Int()
	End Function

	Function ButtonAddText:Int()
	End Function

	Function EnableAllButtons:Int()
	End Function

	Function DisableAllButtons:Int()
	End Function

	Function Update:Int()
	End Function

	Function Success:Int()
	End Function

	Function Fail:Int()
	End Function

	Function ButtonOk:Int()
	End Function

End Type

Type TTraining
	Method New:Int()
	End Method

	Method Delete:Int()
	End Method

	Function SetUpTraining:Int(_0:Int)
	End Function

	Function IsPlayerNeededForTraining:Int(_0:Int, _1:Int)
	End Function

	Function SetUpTraining_Pace:Int()
	End Function

	Function SetUpTraining_Dribbling:Int()
	End Function

	Function SetUpTraining_Passing:Int()
	End Function

	Function SetUpTraining_Shooting:Int()
	End Function

	Function SetUpTraining_Heading:Int()
	End Function

	Function SetUpTraining_Flair:Int()
	End Function

	Function SetUpTraining_Tackling:Int()
	End Function

	Function StartChallenge:Int()
	End Function

	Function Update:Int()
	End Function

	Function UpdateSounds:Int()
	End Function

	Function UpdatePace:Int()
	End Function

	Function UpdateDribbling:Int()
	End Function

	Function UpdateFlair:Int()
	End Function

	Function UpdateTackling1:Int()
	End Function

	Function UpdateTackling2:Int()
	End Function

	Function UpdatePassing:Int()
	End Function

	Function UpdateHeading1:Int()
	End Function

	Function UpdateHeading2:Int()
	End Function

	Function UpdateShooting1:Int()
	End Function

	Function UpdateShooting2:Int()
	End Function

	Function Render:Int()
	End Function

	Function RenderScoreboard:Int(_0:Float)
	End Function

	Function TimeUp:Int()
	End Function

	Function Fail:Int()
	End Function

	Function Success:Int()
	End Function

	Function ClearUpTraining:Int()
	End Function

	Function CanCallForBall:Int()
	End Function

	Function Call:Int(_0:TPlayer)
	End Function

	Function GetFocus:Int(_0:TPlayer, _1:*f, _2:*f)
	End Function

	Function GoalScored:Int(_0:TBall)
	End Function

	Function GetMatchState:Int(_0:*i, _1:*i, _2:*i)
	End Function

	Function ResetTraining:Int()
	End Function

	Function PlayerCanMove:Int(_0:TPlayer)
	End Function

	Function TrainingSetPiece:Int(_0:TPlayer)
	End Function

	Function GetPiggyInTheMiddlePosition:Int(_0:TTeam)
	End Function

End Type

Type TTrainingObject
	Field img:TImage	' +8
	Field frame:Int	' +12
	Field x:Float	' +16
	Field y:Float	' +20
	Field alive:Int	' +24
	Field alph:Float	' +28
	Field scl:Float	' +32

	Method New:Int()
	End Method

	Method Delete:Int()
	End Method

	Function UpdateAll:Int()
	End Function

	Function RenderAll:Int()
	End Function

	Method Update:Int()
	End Method

	Method Render:Int()
	End Method

	Function ClearAll:Int()
	End Function

	Method Clear:Int()
	End Method

End Type

Type TCone
	Field fallen:Int	' +36

	Method New:Int()
	End Method

	Method Delete:Int()
	End Method

	Function Create:Int(_0:Int, _1:Int, _2:Int)
	End Function

	Method Update:Int()
	End Method

	Method CheckKnockOver:Int()
	End Method

	Method Clear:Int()
	End Method

	Method Render:Int()
	End Method

End Type

Type TDummy
	Method New:Int()
	End Method

	Method Delete:Int()
	End Method

	Function Create:Int(_0:Int, _1:Int)
	End Function

	Function ResetDummies:Int()
	End Function

	Method Update:Int()
	End Method

	Method CheckHit:Int()
	End Method

	Method Render:Int()
	End Method

	Method Clear:Int()
	End Method

	Function UpdateWallLocations:Int(_0:Int, _1:Int)
	End Function

End Type

Type TPole
	Field colour:String	' +36
	Field wobbling:Int	' +40

	Method New:Int()
	End Method

	Method Delete:Int()
	End Method

	Function Create:Int(_0:Int, _1:Int, _2:String)
	End Function

	Method Update:Int()
	End Method

	Method CheckHit:Int()
	End Method

	Method Render:Int()
	End Method

	Method Clear:Int()
	End Method

End Type

Type TTrainingZone
	Field colour:String	' +36
	Field txt:String	' +40

	Method New:Int()
	End Method

	Method Delete:Int()
	End Method

	Function Create:TTrainingZone(_0:Int, _1:Int, _2:Float, _3:String, _4:String)
	End Function

	Method Clear:Int()
	End Method

	Method Update:Int()
	End Method

	Method Render:Int()
	End Method

End Type

Type TTrainingLine
	Field colour:String	' +36
	Field x2:Int	' +40
	Field y2:Int	' +44

	Method New:Int()
	End Method

	Method Delete:Int()
	End Method

	Function Create:TTrainingLine(_0:Int, _1:Int, _2:Int, _3:Int, _4:String)
	End Function

	Method Clear:Int()
	End Method

	Method Update:Int()
	End Method

	Method Render:Int()
	End Method

	Method CheckSplit:Int()
	End Method

	Function ActivateNextLine:Int()
	End Function

	Method KillMe:Int()
	End Method

End Type

Type TTarget
	Method New:Int()
	End Method

	Method Delete:Int()
	End Method

	Function Create:Int(_0:Int, _1:Int)
	End Function

	Method Update:Int()
	End Method

	Method CheckHit:Int()
	End Method

	Method Render:Int()
	End Method

	Method Clear:Int()
	End Method

End Type

Type TPanel_Controls
	Method New:Int()
	End Method

	Method Delete:Int()
	End Method

	Function SetUp:Int()
	End Function

	Function RenderTraining:Int(_0:Float, _1:Float)
	End Function

	Function RenderReplay:Int(_0:Int, _1:Int)
	End Function

	Function RenderPauseReplay:Int(_0:Int, _1:Int)
	End Function

	Function RenderPauseSkipTime:Int(_0:Int, _1:Int)
	End Function

	Function RenderKickToContinue:Int()
	End Function

End Type

Type TScreen_Stable
	Method New:Int()
	End Method

	Method Delete:Int()
	End Method

	Function CreateScreen:Int()
	End Function

	Function SetUpScreen:Int(_0:Int)
	End Function

	Function LoadData:Int(_0:TStream)
	End Function

	Function WriteData:Int(_0:TStream)
	End Function

	Function SetUpHorsesForSale:Int()
	End Function

	Function ButtonQuit:Int()
	End Function

	Function ButtonStable:Int()
	End Function

	Function ButtonRace:Int()
	End Function

	Function SetUpNextRace:Int()
	End Function

	Function SetStake:Int()
	End Function

	Function ButtonHorse:Int()
	End Function

	Function RefreshRunners:Int(_0:Int)
	End Function

	Function DoRace:Int()
	End Function

	Function Update:Int()
	End Function

	Function Draw:Int()
	End Function

	Function FinishRace:Int()
	End Function

	Function RefreshTableForSale:Int()
	End Function

	Function ButtonBuyHorse:Int()
	End Function

	Function RefreshTableOwned:Int()
	End Function

	Function GetSelectedHorse:THorse(_0:String)
	End Function

	Function ButtonSellHorse:Int()
	End Function

	Function ButtonTreatHorse:Int()
	End Function

	Function ButtonRaceHorse:Int()
	End Function

End Type

Type THorse
	Field image:TImage	' +8
	Field img_myjockey:TImage	' +12
	Field framecounter:Int	' +16
	Field frame:Int	' +20
	Field x:Float	' +24
	Field y:Float	' +28
	Field oldx:Float	' +32
	Field oldy:Float	' +36
	Field xvel:Float	' +40
	Field yvel:Float	' +44
	Field randno:Int	' +48
	Field id:Int	' +52
	Field name:String	' +56
	Field energy:Float	' +60
	Field health:Float	' +64
	Field strength:Float	' +68
	Field form:Int[]	' +72
	Field prize:Int	' +76
	Field owned:Int	' +80
	Field lastran:Int	' +84
	Field colour:Int	' +88
	Field raceposition:Int	' +92
	Field racenum:Int	' +96
	Field betamount:Int	' +100
	Field betprice:Int	' +104
	Field betwinnings:Int	' +108
	Field textpos:Float	' +112

	Method New:Int()
	End Method

	Method Delete:Int()
	End Method

	Function Create:THorse(_0:Int, _1:String, _2:Float, _3:Float, _4:Float, _5:Int[], _6:Int, _7:Int, _8:Int, _9:Int)
	End Function

	Function GetHorseByName:THorse(_0:String)
	End Function

	Method GetStringEnergy:String()
	End Method

	Method GetStringHealth:String()
	End Method

	Method GetStringForm:String()
	End Method

	Method GetValue:Int()
	End Method

	Method GetStringPrice:String()
	End Method

	Method GetStringracenum:String()
	End Method

	Function UpdateAllRunners:Int()
	End Function

	Method Update:Int()
	End Method

	Function RenderAllRunners:Int(_0:Float, _1:Float, _2:Float)
	End Function

	Method Render:Int(_0:Float, _1:Float, _2:Float)
	End Method

	Function GetLeadingHorse:THorse()
	End Function

	Method PostRaceUpdate:Int(_0:Int)
	End Method

	Function SelectRunners:Int(_0:Int)
	End Function

	Function SetRaceOdds:Int()
	End Function

	Function ResetRands:Int()
	End Function

	Method Compare:Int(_0:Object)
	End Method

	Function GetHorseColour:String(_0:Int)
	End Function

	Function CountHorsesOwned:Int()
	End Function

	Function DoHealthUpdate:Int()
	End Function

End Type

Type TAchievement
	Field id:Int	' +8
	Field index:Int	' +12
	Field txt:String	' +16

	Method New:Int()
	End Method

	Method Delete:Int()
	End Method

	Function LoadData:Int(_0:TStream)
	End Function

	Function WriteData:Int(_0:TStream)
	End Function

	Method Compare:Int(_0:Object)
	End Method

End Type

