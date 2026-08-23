# NSS5 Object Model

Recovered from the BlitzMax reflection (`BBDebugScope` / `BBDebugDecl`) tables inside `NSS5.exe`. These are the **original source's own** Type names, field names, method names and type signatures - not inferred, not guessed.

## Record format

```
BBDebugScope: [uint32 kind=2] [char* typeName] [BBDebugDecl...] [kind=0 terminator]
BBDebugDecl : [uint32 kind] [char* name] [char* signature] [uint32 offset]   // 16 bytes

kind 3 = Field    offset = byte offset within the object
kind 6 = Method   offset = vtable slot
kind 7 = Function (Type function / static)
kind 2 = Global   kind 4 = Const
```

Object header occupies offsets 0 (class/vtable pointer) and 4 (GC word); user fields start at **offset 8**.

## Signature encoding

| Tag | Type |
|---|---|
| `b` | Byte |
| `s` | Short |
| `i` | Int |
| `l` | Long |
| `f` | Float |
| `d` | Double |
| `$` | String |
| `z` | CString |
| `:TFoo` | object of Type TFoo |
| `[]X` | array of X |
| `*X` | pointer to X |
| `(a,b)r` | function taking a,b returning r |

**Totals: 349 Types, 2780 fields, 2862 methods/functions (133 game Types).**

---

## z_My_1a09b2da_7c75_4a81_b2c3_6774c843be3d

_0 fields, 2 methods, 0 functions_

### Methods

| Slot | Name | Signature |
|---:|---|---|
| 16 | `New` | `()i` |
| 20 | `Delete` | `()i` |

## TBase_Team

_22 fields, 8 methods, 0 functions_

### Fields - exact object layout

| Offset | Name | Type |
|---:|---|---|
| 8 | `randno` | `i` |
| 12 | `id` | `i` |
| 16 | `name` | `$` |
| 20 | `shortname` | `$` |
| 24 | `tla` | `$` |
| 28 | `labelname` | `$` |
| 32 | `labelshortname` | `$` |
| 36 | `strength` | `i` |
| 40 | `rivalid1` | `i` |
| 44 | `rivalid2` | `i` |
| 48 | `rivalid3` | `i` |
| 52 | `stadiumname` | `$` |
| 56 | `stadiumcapacity` | `i` |
| 60 | `stadiumlongitude` | `f` |
| 64 | `stadiumlatitude` | `f` |
| 68 | `kitcolsHome` | `:TKitStrings` |
| 72 | `kitcolsAway` | `:TKitStrings` |
| 76 | `kitcolsThird` | `:TKitStrings` |
| 80 | `kitcolsKeeper` | `:TKitStrings` |
| 84 | `formation` | `i` |
| 88 | `imgFlag` | `:TImage` |
| 92 | `imgFlagSmall` | `:TImage` |

### Methods

| Slot | Name | Signature |
|---:|---|---|
| 16 | `New` | `()i` |
| 20 | `Delete` | `()i` |
| 48 | `GetFixtureList` | `(i,i):TList` |
| 52 | `GetStringArrayFixtureList` | `(i):TList` |
| 56 | `GetNextFixture` | `(i):TFixture` |
| 60 | `GetPrimaryColour` | `()$` |
| 64 | `CheckManagerChangeFormation` | `()i` |
| 28 | `Compare` | `(:Object)i` |

## TNation

_5 fields, 5 methods, 13 functions_

### Fields - exact object layout

| Offset | Name | Type |
|---:|---|---|
| 96 | `nationality` | `$` |
| 100 | `continent` | `i` |
| 104 | `climate` | `i` |
| 108 | `primaryskin` | `i` |
| 112 | `secondaryskin` | `i` |

### Methods

| Slot | Name | Signature |
|---:|---|---|
| 16 | `New` | `()i` |
| 20 | `Delete` | `()i` |
| 116 | `HasLeagues` | `()i` |
| 48 | `GetFixtureList` | `(i,i):TList` |
| 28 | `Compare` | `(:Object)i` |

### Functions

| Slot | Name | Signature |
|---:|---|---|
| 68 | `CreateNation` | `($)i` |
| 72 | `LoadData` | `(:TStream)i` |
| 76 | `WriteData` | `(:TStream)i` |
| 80 | `WriteDataMobile` | `(:TStream)i` |
| 84 | `SaveMaster` | `(i,i)i` |
| 88 | `SelectById` | `(i):TNation` |
| 92 | `SelectByTLA` | `($):TNation` |
| 96 | `SelectRandomNation` | `(i):TNation` |
| 100 | `SelectListByStartLetter` | `($):TList` |
| 104 | `SelectListByContinent` | `(i):TList` |
| 108 | `ReorderNations` | `()i` |
| 112 | `ButtonizeFlag` | `(:TImage,i)i` |
| 120 | `SortListBy` | `(i,i)i` |

## TClub

_5 fields, 8 methods, 17 functions_

### Fields - exact object layout

| Offset | Name | Type |
|---:|---|---|
| 96 | `nickname` | `$` |
| 100 | `nationid` | `i` |
| 104 | `leagueid` | `i` |
| 108 | `continentalcompid` | `i` |
| 112 | `bteamofid` | `i` |

### Methods

| Slot | Name | Signature |
|---:|---|---|
| 16 | `New` | `()i` |
| 20 | `Delete` | `()i` |
| 68 | `Destroy` | `()i` |
| 104 | `GetActualLeagueId` | `()i` |
| 48 | `GetFixtureList` | `(i,i):TList` |
| 128 | `CountFixturesRemaining` | `()i` |
| 132 | `GetStringArray` | `()[]$` |
| 28 | `Compare` | `(:Object)i` |

### Functions

| Slot | Name | Signature |
|---:|---|---|
| 72 | `CreateClub` | `($)i` |
| 76 | `NewClub` | `():TClub` |
| 80 | `LoadData` | `(:TStream)i` |
| 84 | `WriteData` | `(:TStream)i` |
| 88 | `WriteDataMobile` | `(:TStream)i` |
| 92 | `SaveMaster` | `(i,i)i` |
| 96 | `SelectById` | `(i):TClub` |
| 100 | `SelectRandomClub` | `(i):TClub` |
| 108 | `SelectListByLeagueId` | `(i):TList` |
| 112 | `SelectListByNationId` | `(i):TList` |
| 116 | `CountTeamsInDivision` | `(i)i` |
| 120 | `CountTeamsInContinentalComps` | `(i)i` |
| 124 | `CountTeamsNotInContinentalComps` | `(i)i` |
| 136 | `ReorderClubs` | `()i` |
| 140 | `AverageOutStrengthAll` | `()i` |
| 144 | `CheckStadiumSizeAll` | `()i` |
| 148 | `SortListBy` | `(i,i)i` |

## TFixture

_15 fields, 19 methods, 3 functions_

### Fields - exact object layout

| Offset | Name | Type |
|---:|---|---|
| 8 | `sdate` | `i` |
| 12 | `matchtype` | `i` |
| 16 | `round` | `i` |
| 20 | `groupno` | `i` |
| 24 | `leg` | `i` |
| 28 | `hometeam` | `i` |
| 32 | `awayteam` | `i` |
| 36 | `result` | `i` |
| 40 | `resulttype` | `i` |
| 44 | `score1` | `i` |
| 48 | `score2` | `i` |
| 52 | `penscore1` | `i` |
| 56 | `penscore2` | `i` |
| 60 | `level` | `i` |
| 64 | `compid` | `i` |

### Methods

| Slot | Name | Signature |
|---:|---|---|
| 16 | `New` | `()i` |
| 20 | `Delete` | `()i` |
| 56 | `WriteData` | `(:TStream)i` |
| 60 | `GetStringHomeTeam` | `()$` |
| 64 | `GetStringAwayTeam` | `()$` |
| 68 | `GetStringArray` | `(i)[]$` |
| 72 | `GetStringArrayForLeague` | `()[]$` |
| 76 | `GetStringArrayForTeamId` | `(i)[]$` |
| 80 | `GetFirstLegScore` | `(*i,*i)i` |
| 84 | `PlayFixture` | `()i` |
| 88 | `UpdatePoints` | `(:TTableData,:TTableData)i` |
| 96 | `GetWinningTeamTableId` | `()i` |
| 100 | `GetLosingTeamTableId` | `()i` |
| 104 | `GetWinningTeamId` | `()i` |
| 108 | `GetLosingTeamId` | `()i` |
| 112 | `GetHomeTeamId` | `()i` |
| 116 | `GetAwayTeamId` | `()i` |
| 120 | `CreateReplayFixture` | `()i` |
| 28 | `Compare` | `(:Object)i` |

### Functions

| Slot | Name | Signature |
|---:|---|---|
| 48 | `CreateFixture` | `(i,i,i,i,i,i,i,i,i):TFixture` |
| 52 | `CreateFromString` | `($):TFixture` |
| 92 | `GetRandomGoal` | `()i` |

## TLocale

_0 fields, 2 methods, 4 functions_

### Methods

| Slot | Name | Signature |
|---:|---|---|
| 16 | `New` | `()i` |
| 20 | `Delete` | `()i` |

### Functions

| Slot | Name | Signature |
|---:|---|---|
| 48 | `SetUp` | `()i` |
| 52 | `SetCurrentLanguage` | `($)i` |
| 56 | `GetLocaleText` | `($)$` |
| 60 | `SetUpKeyStrings` | `()i` |

## TNames

_0 fields, 2 methods, 1 functions_

### Methods

| Slot | Name | Signature |
|---:|---|---|
| 16 | `New` | `()i` |
| 20 | `Delete` | `()i` |

### Functions

| Slot | Name | Signature |
|---:|---|---|
| 48 | `SetUp` | `(i)i` |

## TBall

_42 fields, 32 methods, 12 functions_

### Fields - exact object layout

| Offset | Name | Type |
|---:|---|---|
| 8 | `id` | `i` |
| 12 | `active` | `i` |
| 16 | `alph` | `f` |
| 20 | `colour` | `$` |
| 24 | `x` | `f` |
| 28 | `y` | `f` |
| 32 | `z` | `f` |
| 36 | `oldx` | `f` |
| 40 | `oldy` | `f` |
| 44 | `oldz` | `f` |
| 48 | `metax` | `f` |
| 52 | `metay` | `f` |
| 56 | `jumpx` | `f` |
| 60 | `jumpy` | `f` |
| 64 | `divex` | `f` |
| 68 | `divey` | `f` |
| 72 | `setpiecex` | `i` |
| 76 | `setpiecey` | `i` |
| 80 | `ingoal` | `i` |
| 84 | `velocity` | `f` |
| 88 | `zvelocity` | `f` |
| 92 | `direction` | `f` |
| 96 | `teaminpossession` | `i` |
| 100 | `kicktime` | `i` |
| 104 | `lastkicktype` | `i` |
| 108 | `lastkickmatchstate` | `i` |
| 112 | `controlledby` | `:TPlayer` |
| 116 | `lastkickedby` | `:TPlayer` |
| 120 | `lasttouchedby` | `:TPlayer` |
| 124 | `assistedby` | `:TPlayer` |
| 128 | `setpiecetaker` | `:TPlayer` |
| 132 | `setpiecebuddy` | `:TPlayer` |
| 136 | `backpass` | `i` |
| 140 | `slidekick` | `i` |
| 144 | `posthit` | `i` |
| 148 | `disttoreciever` | `f` |
| 152 | `curlamount` | `f` |
| 156 | `passtoid` | `i` |
| 160 | `frame` | `i` |
| 164 | `lastframetime` | `i` |
| 168 | `hideball` | `i` |
| 172 | `replayframes` | `:TList` |

### Methods

| Slot | Name | Signature |
|---:|---|---|
| 16 | `New` | `()i` |
| 20 | `Delete` | `()i` |
| 76 | `Update` | `()i` |
| 84 | `Render` | `(f)i` |
| 88 | `UpdateAlpha` | `()i` |
| 92 | `UpdateMovement` | `()i` |
| 96 | `UpdateMetaBall` | `()i` |
| 100 | `UpdateAnimation` | `()i` |
| 104 | `Kick` | `(:TPlayer,f,f,i,i)i` |
| 108 | `CheckAfterTouch` | `()i` |
| 112 | `CheckGoals` | `()i` |
| 116 | `CheckSideLines` | `()i` |
| 120 | `CheckAdHoardings` | `()i` |
| 124 | `HitPost` | `(f)i` |
| 128 | `HitNet` | `(i)i` |
| 132 | `NewController` | `(:TPlayer)i` |
| 136 | `KeeperHolding` | `()i` |
| 140 | `KeeperImageHolding` | `()i` |
| 144 | `Deflect` | `(:TPlayer)i` |
| 148 | `Parry` | `(:TPlayer)i` |
| 152 | `SetUpSetPieceBall` | `(i,i,i)i` |
| 156 | `ResetPosition` | `(i,i,i)i` |
| 160 | `ResetControllers` | `()i` |
| 164 | `Crossing` | `(f)i` |
| 172 | `RecordReplayFrame` | `(i)i` |
| 180 | `UpdateReplay` | `(i)i` |
| 188 | `RenderReplay` | `(f)i` |
| 192 | `GetHeightScale` | `(i)f` |
| 196 | `CanSeePlayer` | `(:TPlayer)i` |
| 204 | `CheckForPlayerRatings` | `(:TPlayer)i` |
| 208 | `CheckLongShotRating` | `()i` |
| 28 | `Compare` | `(:Object)i` |

### Functions

| Slot | Name | Signature |
|---:|---|---|
| 48 | `ClearAll` | `()i` |
| 52 | `SetUp` | `()i` |
| 56 | `CreateBall` | `(i,i,i):TBall` |
| 60 | `CreateReplayBalls` | `(:TReplay)i` |
| 64 | `SetActive` | `(:TBall)i` |
| 68 | `GetActiveBall` | `():TBall` |
| 72 | `UpdateAll` | `()i` |
| 80 | `RenderAll` | `(f)i` |
| 168 | `RecordReplayFramesAll` | `(i)i` |
| 176 | `UpdateReplayAll` | `(i)i` |
| 184 | `RenderReplayAll` | `(f)i` |
| 200 | `GetStringKickType` | `(i)$` |

## TDrawOb

_17 fields, 3 methods, 4 functions_

### Fields - exact object layout

| Offset | Name | Type |
|---:|---|---|
| 8 | `x` | `f` |
| 12 | `y` | `f` |
| 16 | `z` | `f` |
| 20 | `z2` | `f` |
| 24 | `img` | `:TImage` |
| 28 | `frame` | `i` |
| 32 | `level` | `i` |
| 36 | `alph` | `f` |
| 40 | `rot` | `i` |
| 44 | `col` | `$` |
| 48 | `sclx` | `f` |
| 52 | `scly` | `f` |
| 56 | `blend` | `i` |
| 60 | `txt` | `$` |
| 64 | `txt2` | `$` |
| 68 | `imgrectw` | `f` |
| 72 | `imgrecth` | `f` |

### Methods

| Slot | Name | Signature |
|---:|---|---|
| 16 | `New` | `()i` |
| 20 | `Delete` | `()i` |
| 28 | `Compare` | `(:Object)i` |

### Functions

| Slot | Name | Signature |
|---:|---|---|
| 48 | `ClearAll` | `()i` |
| 52 | `AddDrawOb` | `(:TImage,f,f,f,i,i,f,i,$,f,f,i,f,$,i,i)i` |
| 56 | `RenderAll` | `(f,f,f)i` |
| 60 | `Sort` | `()i` |

## TEngine

_0 fields, 2 methods, 54 functions_

### Methods

| Slot | Name | Signature |
|---:|---|---|
| 16 | `New` | `()i` |
| 20 | `Delete` | `()i` |

### Functions

| Slot | Name | Signature |
|---:|---|---|
| 48 | `SetUp` | `()i` |
| 52 | `SetUpChannels` | `()i` |
| 56 | `StopChannels` | `()i` |
| 60 | `SetUpMatch` | `(:TFixture,:TTeam,:TTeam,()i)i` |
| 64 | `SetUpReplay` | `(:TReplay,()i)i` |
| 68 | `SetUpRadarColours` | `()i` |
| 72 | `SetUpWeatherConditions` | `()i` |
| 76 | `MatchLoop` | `()i` |
| 80 | `RenderGameEngine` | `(f)i` |
| 84 | `Update` | `()i` |
| 88 | `UpdateOffset` | `(f)i` |
| 92 | `Render` | `(f)i` |
| 96 | `RenderRadar` | `()i` |
| 100 | `RenderScoreboard` | `()i` |
| 104 | `DrawScores` | `()i` |
| 108 | `CheckInput` | `()i` |
| 112 | `SetUpSetPiece` | `(i,i,i,i)i` |
| 116 | `SetPiece` | `()i` |
| 120 | `WaitForSetpiece` | `()i` |
| 124 | `UpdateSetPieceReady` | `()i` |
| 128 | `ResetClubLastChange` | `()i` |
| 132 | `GoalScored` | `(:TBall)i` |
| 136 | `UpdateMatchTime` | `()i` |
| 140 | `DoHalfEnds` | `()i` |
| 144 | `CreateReplayFrames` | `(:TReplay)i` |
| 148 | `RecordReplayFrame` | `(i)i` |
| 152 | `UpdateReplayFrame` | `(i)i` |
| 156 | `StartReplay` | `()i` |
| 160 | `EndReplay` | `()i` |
| 164 | `UpdateReplay` | `()i` |
| 168 | `CheckReplayInput` | `()i` |
| 172 | `UpdateOffsetReplay` | `(f)i` |
| 176 | `RenderReplay` | `(f)i` |
| 180 | `RenderReplayGUI` | `()i` |
| 184 | `RenderReplayRadar` | `()i` |
| 188 | `SaveReplay` | `()i` |
| 192 | `UpdateSounds` | `()i` |
| 196 | `UpdateSoundsReplay` | `()i` |
| 200 | `PauseSounds` | `()i` |
| 204 | `ResumeSounds` | `()i` |
| 208 | `DoYourSubstitutionOn` | `()i` |
| 212 | `DoYourSubstitutionOff` | `(i)i` |
| 216 | `MatchOver` | `()i` |
| 220 | `SkipMatchTime` | `()i` |
| 224 | `EndMatch` | `()i` |
| 228 | `SkipTime` | `()i` |
| 232 | `ForcePositionResetAll` | `()i` |
| 236 | `DoShootOut` | `()i` |
| 240 | `CheckShootOutComplete` | `()i` |
| 244 | `GetStringMatchState` | `()$` |
| 248 | `GetWinningClub` | `():TTeam` |
| 252 | `ResetStats` | `()i` |
| 256 | `PauseEngine` | `()i` |
| 260 | `DrawMyText` | `($,f,f,i,i,f,f,$,i)i` |

## TFormation

_8 fields, 14 methods, 6 functions_

### Fields - exact object layout

| Offset | Name | Type |
|---:|---|---|
| 8 | `name` | `$` |
| 12 | `m_Defenders` | `i` |
| 16 | `m_DefensiveMidfielders` | `i` |
| 20 | `m_Midfielders` | `i` |
| 24 | `m_AttackingMidfielders` | `i` |
| 28 | `m_Attackers` | `i` |
| 32 | `m_TacPos` | `[]i` |
| 36 | `m_TacLabel` | `[]$` |

### Methods

| Slot | Name | Signature |
|---:|---|---|
| 16 | `New` | `()i` |
| 20 | `Delete` | `()i` |
| 56 | `UpdateLabels` | `()i` |
| 60 | `LoadTactics` | `($)i` |
| 64 | `SaveTactics` | `()i` |
| 68 | `GetSelectionNoFromSeg` | `(i,i)i` |
| 72 | `GetCol` | `(i)i` |
| 76 | `GetRow` | `(i)i` |
| 80 | `GetRowFromSelectionNo` | `(i)i` |
| 84 | `GetColFromSelectionNo` | `(i)i` |
| 88 | `GetPlayerXY` | `(i,f,f,f,f,i,i,*f,*f,f,f)f` |
| 92 | `GetPosFromSelectionNo` | `(i)i` |
| 96 | `GetSideFromSelectionNo` | `(i)i` |
| 108 | `GetStringLabelFromSelectionNo` | `(i)$` |

### Functions

| Slot | Name | Signature |
|---:|---|---|
| 48 | `SetUp` | `()i` |
| 52 | `Create` | `(i):TFormation` |
| 100 | `GetStringTacticName` | `(i)$` |
| 104 | `GetTacticIdByName` | `($)i` |
| 112 | `GetStringPosition` | `(i,i)$` |
| 116 | `PickRandomFormation` | `()i` |

## TJoy

_8 fields, 5 methods, 1 functions_

### Fields - exact object layout

| Offset | Name | Type |
|---:|---|---|
| 8 | `axis_x` | `f` |
| 12 | `axis_y` | `f` |
| 16 | `force` | `f` |
| 20 | `direction` | `f` |
| 24 | `kickenabled` | `i` |
| 28 | `kickbuttondown` | `i` |
| 32 | `kickbuttonhits` | `i` |
| 36 | `activebutton` | `i` |

### Methods

| Slot | Name | Signature |
|---:|---|---|
| 16 | `New` | `()i` |
| 20 | `Delete` | `()i` |
| 52 | `Update` | `(i,i,i)i` |
| 56 | `GetActualDirection` | `()f` |
| 60 | `Clear` | `()i` |

### Functions

| Slot | Name | Signature |
|---:|---|---|
| 48 | `CreateJoy` | `():TJoy` |

## TKit

_3 fields, 5 methods, 13 functions_

### Fields - exact object layout

| Offset | Name | Type |
|---:|---|---|
| 8 | `pixmap` | `:TPixmap` |
| 12 | `style` | `$` |
| 16 | `newcol` | `[]$` |

### Methods

| Slot | Name | Signature |
|---:|---|---|
| 16 | `New` | `()i` |
| 20 | `Delete` | `()i` |
| 52 | `Clear` | `()i` |
| 60 | `GetPaintedPlayer` | `($,i,i,$):TPixmap` |
| 64 | `GetPaintedFan` | `(i,i):TPixmap` |

### Functions

| Slot | Name | Signature |
|---:|---|---|
| 48 | `SetUp` | `()i` |
| 56 | `CreateKit` | `(:TKitStrings,$):TKit` |
| 68 | `GetRandHexHairColour` | `(i)$` |
| 72 | `GetHexHairCol` | `(i)$` |
| 76 | `GetHexSkinColour` | `(i)$` |
| 80 | `CheckBlack` | `(*$)i` |
| 84 | `ColorInt` | `(i,i,i,i)i` |
| 88 | `GetBootColour` | `(i)$` |
| 92 | `GetBootColourInt` | `($)i` |
| 96 | `GetGloveColour` | `(i)$` |
| 100 | `GetGloveColourInt` | `($)i` |
| 104 | `GetStringHairCol` | `(i)$` |
| 108 | `GetStringSkinCol` | `(i)$` |

## TKitStrings

_5 fields, 6 methods, 2 functions_

### Fields - exact object layout

| Offset | Name | Type |
|---:|---|---|
| 8 | `style` | `$` |
| 12 | `shirt1` | `$` |
| 16 | `shirt2` | `$` |
| 20 | `shorts` | `$` |
| 24 | `socks` | `$` |

### Methods

| Slot | Name | Signature |
|---:|---|---|
| 16 | `New` | `()i` |
| 20 | `Delete` | `()i` |
| 52 | `Copy` | `(:TKitStrings)i` |
| 56 | `CheckKitColours` | `()i` |
| 64 | `GetFileName` | `()$` |
| 68 | `GetStyleId_Mobile` | `()i` |

### Functions

| Slot | Name | Signature |
|---:|---|---|
| 48 | `CreateKitStrings` | `($,$,$,$,$):TKitStrings` |
| 60 | `ConvertNSS4ColourIndexToHex` | `(i)$` |

## TPlayerColours

_3 fields, 4 methods, 0 functions_

### Fields - exact object layout

| Offset | Name | Type |
|---:|---|---|
| 8 | `skin` | `i` |
| 12 | `hair` | `i` |
| 16 | `boots` | `$` |

### Methods

| Slot | Name | Signature |
|---:|---|---|
| 16 | `New` | `()i` |
| 20 | `Delete` | `()i` |
| 48 | `SetSkin` | `(i)i` |
| 52 | `SetHair` | `(i)i` |

## TTeam

_14 fields, 28 methods, 2 functions_

### Fields - exact object layout

| Offset | Name | Type |
|---:|---|---|
| 8 | `id` | `i` |
| 12 | `name` | `$` |
| 16 | `tla` | `$` |
| 20 | `rating` | `i` |
| 24 | `controller` | `i` |
| 28 | `squad` | `:TList` |
| 32 | `lastchangeplayer` | `i` |
| 36 | `formation` | `:TFormation` |
| 40 | `cornerformation` | `:TList` |
| 44 | `kitplayer` | `:TKit` |
| 48 | `kitkeeper` | `:TKit` |
| 52 | `skin1` | `i` |
| 56 | `skin2` | `i` |
| 60 | `newstarselno` | `i` |

### Methods

| Slot | Name | Signature |
|---:|---|---|
| 16 | `New` | `()i` |
| 20 | `Delete` | `()i` |
| 48 | `Getkitplayer` | `():TKit` |
| 52 | `Setkitplayer` | `(:TKit)i` |
| 56 | `Getkitkeeper` | `():TKit` |
| 60 | `Setkitkeeper` | `(:TKit)i` |
| 64 | `Clear` | `()i` |
| 72 | `CreateSquadSimple` | `()i` |
| 80 | `CreateReplaySquad` | `(:TReplay)i` |
| 84 | `PaintSquad` | `(i)i` |
| 88 | `UpdateNewStarPosition` | `(i)i` |
| 92 | `ChangeFormation` | `(i,i)i` |
| 96 | `ResetCornerFormation` | `()i` |
| 100 | `Update` | `()i` |
| 104 | `UpdateLocalPlayer` | `()i` |
| 108 | `NewLocalPlayer` | `(:TPlayer)i` |
| 112 | `UpdatePlayerDestinations` | `()i` |
| 116 | `GetTunnelPositions` | `(i)i` |
| 120 | `GetShootoutPositions` | `()i` |
| 124 | `GetMatchOverPositions` | `()i` |
| 128 | `GetWallLocation` | `(i,i,i,*f,*f)i` |
| 132 | `ForcePositionReset` | `()i` |
| 136 | `GetSetPieceTakers` | `(i,:TBall)i` |
| 140 | `GetShootingDirection` | `()i` |
| 144 | `GetPlayerNearestToXY` | `(i,i,i,:TPlayer,i):TPlayer` |
| 148 | `CheckComManagement` | `()i` |
| 152 | `GetLosingBy` | `()i` |
| 156 | `SelectRandomPlayer` | `(i,i,i,i):TPlayer` |

### Functions

| Slot | Name | Signature |
|---:|---|---|
| 68 | `CreateTeamSimple` | `(i,$,$,i,i,:TKit,:TKit,i,i,i,:TFixture):TTeam` |
| 76 | `CreateReplayTeam` | `(:TReplay,i,$,$,:TKit,:TKit,i):TTeam` |

## TMyVector

_3 fields, 25 methods, 1 functions_

### Fields - exact object layout

| Offset | Name | Type |
|---:|---|---|
| 8 | `X` | `d` |
| 16 | `Y` | `d` |
| 24 | `Z` | `d` |

### Methods

| Slot | Name | Signature |
|---:|---|---|
| 16 | `New` | `()i` |
| 20 | `Delete` | `()i` |
| 52 | `SetXYZ` | `(d,d,d):TMyVector` |
| 56 | `Set` | `(:TMyVector):TMyVector` |
| 60 | `Add` | `(:TMyVector):TMyVector` |
| 64 | `Sub` | `(:TMyVector):TMyVector` |
| 68 | `SubXYZ` | `(d,d,d):TMyVector` |
| 72 | `GetDotPV` | `(:TMyVector)d` |
| 76 | `CrossPV` | `(:TMyVector):TMyVector` |
| 80 | `Mul` | `(d):TMyVector` |
| 84 | `Div` | `(d):TMyVector` |
| 88 | `Normalize` | `():TMyVector` |
| 92 | `RotateAroundX` | `(d):TMyVector` |
| 96 | `RotateAroundY` | `(d):TMyVector` |
| 100 | `RotateAroundZ` | `(d):TMyVector` |
| 104 | `RotateAroundV` | `(:TMyVector,d):TMyVector` |
| 108 | `Copy2Vec` | `():TMyVector` |
| 112 | `GetX` | `()d` |
| 116 | `GetY` | `()d` |
| 120 | `GetZ` | `()d` |
| 124 | `GetLength` | `()d` |
| 128 | `GetLengthSqr` | `()d` |
| 132 | `SetX` | `(d):TMyVector` |
| 136 | `SetY` | `(d):TMyVector` |
| 140 | `SetZ` | `(d):TMyVector` |

### Functions

| Slot | Name | Signature |
|---:|---|---|
| 48 | `Create` | `(d,d,d):TMyVector` |

## TOptions

_0 fields, 2 methods, 19 functions_

### Methods

| Slot | Name | Signature |
|---:|---|---|
| 16 | `New` | `()i` |
| 20 | `Delete` | `()i` |

### Functions

| Slot | Name | Signature |
|---:|---|---|
| 48 | `SetUp` | `()i` |
| 52 | `GetButtonLabel` | `(i)$` |
| 56 | `GetButtonIcon` | `(i,i):TImage` |
| 60 | `GetNewControl` | `()i` |
| 64 | `WaitForJoyRelease` | `()i` |
| 68 | `WriteNewOptionsIni` | `()i` |
| 72 | `SaveOptions` | `()i` |
| 76 | `LoadOptions` | `()i` |
| 80 | `FindRes800600` | `()i` |
| 84 | `NewButtonUp` | `()i` |
| 88 | `NewButtonDown` | `()i` |
| 92 | `NewButtonLeft` | `()i` |
| 96 | `NewButtonRight` | `()i` |
| 100 | `NewButtonKick` | `()i` |
| 104 | `NewButtonKick2` | `()i` |
| 108 | `NewButtonKick3` | `()i` |
| 112 | `NewButtonKick4` | `()i` |
| 116 | `NewButtonPause` | `()i` |
| 120 | `NewButtonReplay` | `()i` |

## TPitch

_0 fields, 2 methods, 20 functions_

### Methods

| Slot | Name | Signature |
|---:|---|---|
| 16 | `New` | `()i` |
| 20 | `Delete` | `()i` |

### Functions

| Slot | Name | Signature |
|---:|---|---|
| 48 | `SetUp` | `()i` |
| 52 | `RandomPitchType` | `()i` |
| 56 | `SetStadiumSize` | `(i,i)i` |
| 60 | `SetUpFans` | `(:TTeam,:TTeam,i)i` |
| 64 | `Update` | `()i` |
| 68 | `Render` | `(f,f,f)i` |
| 72 | `DrawStadium` | `(f,f,f)i` |
| 76 | `DrawFans` | `(i,f,f,f,i)i` |
| 80 | `DrawBosses` | `()i` |
| 84 | `DoLineUpImage` | `()i` |
| 88 | `IsOnPitch` | `(i,i)i` |
| 92 | `InsidePenaltyBox` | `(i,i,i)i` |
| 96 | `InsideCrossZone` | `(i,i,i)i` |
| 100 | `PixelsToYards` | `(f)f` |
| 104 | `PixelsToMetres` | `(f)f` |
| 108 | `YardsToPixels` | `(f)f` |
| 112 | `MetresToPixels` | `(f)f` |
| 116 | `YardsToMetres` | `(f)f` |
| 120 | `MetresToYards` | `(f)f` |
| 124 | `ValidateOnPitch` | `(*f,*f)i` |

## TPitchMark

_6 fields, 2 methods, 5 functions_

### Fields - exact object layout

| Offset | Name | Type |
|---:|---|---|
| 8 | `x` | `i` |
| 12 | `y` | `i` |
| 16 | `a` | `f` |
| 20 | `rot` | `i` |
| 24 | `frm` | `i` |
| 28 | `frametime` | `i` |

### Methods

| Slot | Name | Signature |
|---:|---|---|
| 16 | `New` | `()i` |
| 20 | `Delete` | `()i` |

### Functions

| Slot | Name | Signature |
|---:|---|---|
| 48 | `SetUp` | `()i` |
| 52 | `ResetPitchMarks` | `()i` |
| 56 | `AddPitchMark` | `(i,i,i,i,f)i` |
| 60 | `Render` | `()i` |
| 64 | `RenderReplay` | `()i` |

## TPhotographer

_5 fields, 3 methods, 5 functions_

### Fields - exact object layout

| Offset | Name | Type |
|---:|---|---|
| 8 | `x` | `f` |
| 12 | `y` | `f` |
| 16 | `facing` | `i` |
| 20 | `pose` | `i` |
| 24 | `flashmod` | `i` |

### Methods

| Slot | Name | Signature |
|---:|---|---|
| 16 | `New` | `()i` |
| 20 | `Delete` | `()i` |
| 64 | `Render` | `()i` |

### Functions

| Slot | Name | Signature |
|---:|---|---|
| 48 | `SetUp` | `()i` |
| 52 | `Create` | `(f,f,i,i)i` |
| 56 | `SetUpPositions` | `()i` |
| 60 | `RenderAll` | `()i` |
| 68 | `ClearAll` | `()i` |

## TCameraMan

_4 fields, 4 methods, 6 functions_

### Fields - exact object layout

| Offset | Name | Type |
|---:|---|---|
| 8 | `x` | `f` |
| 12 | `y` | `f` |
| 16 | `facing` | `i` |
| 20 | `rot` | `f` |

### Methods

| Slot | Name | Signature |
|---:|---|---|
| 16 | `New` | `()i` |
| 20 | `Delete` | `()i` |
| 64 | `Update` | `()i` |
| 72 | `Render` | `()i` |

### Functions

| Slot | Name | Signature |
|---:|---|---|
| 48 | `SetUp` | `()i` |
| 52 | `Create` | `(f,f)i` |
| 56 | `SetUpPositions` | `()i` |
| 60 | `UpdateAll` | `()i` |
| 68 | `RenderAll` | `()i` |
| 76 | `ClearAll` | `()i` |

## TPlayer

_97 fields, 110 methods, 24 functions_

### Fields - exact object layout

| Offset | Name | Type |
|---:|---|---|
| 8 | `newstar` | `i` |
| 12 | `imgPlayer` | `:TImage` |
| 16 | `id` | `i` |
| 20 | `teamid` | `i` |
| 24 | `controller` | `i` |
| 28 | `name` | `$` |
| 32 | `initials` | `$` |
| 36 | `age` | `i` |
| 40 | `value` | `$` |
| 44 | `preferredposition` | `$` |
| 48 | `happiness` | `i` |
| 52 | `boozedup` | `i` |
| 56 | `nrgsickness` | `i` |
| 60 | `unhappiness` | `i` |
| 64 | `tiredness` | `i` |
| 68 | `boozecount` | `i` |
| 72 | `nrgcount` | `i` |
| 76 | `x` | `f` |
| 80 | `y` | `f` |
| 84 | `z` | `f` |
| 88 | `oldx` | `f` |
| 92 | `oldy` | `f` |
| 96 | `oldz` | `f` |
| 100 | `xvel` | `f` |
| 104 | `yvel` | `f` |
| 108 | `zvel` | `f` |
| 112 | `runtime` | `i` |
| 116 | `speed` | `f` |
| 120 | `direction` | `f` |
| 124 | `desx` | `f` |
| 128 | `desy` | `f` |
| 132 | `metax` | `f` |
| 136 | `metay` | `f` |
| 140 | `goalside` | `i` |
| 144 | `keepercatchtime` | `i` |
| 148 | `kickx` | `i` |
| 152 | `kicky` | `i` |
| 156 | `receivex` | `i` |
| 160 | `receivey` | `i` |
| 164 | `posxwhenkicked` | `i` |
| 168 | `posywhenkicked` | `i` |
| 172 | `offside` | `i` |
| 176 | `offsidewhenkicked` | `i` |
| 180 | `offsidealpha` | `f` |
| 184 | `offsidetime` | `i` |
| 188 | `selectionno` | `i` |
| 192 | `kickpower` | `f` |
| 196 | `kickdirection` | `f` |
| 200 | `lastkickdirection` | `f` |
| 204 | `directiontoball` | `i` |
| 208 | `distancetoball` | `f` |
| 212 | `directiontometaball` | `i` |
| 216 | `distancetometaball` | `f` |
| 220 | `jumpspotgood` | `i` |
| 224 | `directiontogoal_opp` | `i` |
| 228 | `directiontogoal_own` | `i` |
| 232 | `distancetogoal_opp` | `i` |
| 236 | `distancetogoal_own` | `i` |
| 240 | `teammateid` | `i` |
| 244 | `lastchangedteammateid` | `i` |
| 248 | `directiontoteammate` | `i` |
| 252 | `distancetoteammate` | `f` |
| 256 | `opponentid` | `i` |
| 260 | `directiontoopponent` | `i` |
| 264 | `distancetoopponent` | `f` |
| 268 | `passpotential` | `i` |
| 272 | `passison` | `i` |
| 276 | `calling` | `i` |
| 280 | `calltype` | `i` |
| 284 | `bonus` | `i` |
| 288 | `icalledforball` | `i` |
| 292 | `ihadashot` | `i` |
| 296 | `facing` | `i` |
| 300 | `spriterotation` | `f` |
| 304 | `currentanim` | `[]i` |
| 308 | `frame` | `i` |
| 312 | `lastframetime` | `i` |
| 316 | `imageframenumber` | `i` |
| 320 | `skincol` | `i` |
| 324 | `haircol` | `i` |
| 328 | `bootcolint` | `i` |
| 332 | `glovecolint` | `i` |
| 336 | `bootcol` | `$` |
| 340 | `glovecol` | `$` |
| 344 | `joy` | `:TJoy` |
| 348 | `obtext` | `$` |
| 352 | `replayframes` | `:TList` |
| 356 | `pace` | `f` |
| 360 | `dribbling` | `f` |
| 364 | `tackling` | `f` |
| 368 | `passing` | `f` |
| 372 | `heading` | `f` |
| 376 | `shooting` | `f` |
| 380 | `flair` | `f` |
| 384 | `slide_start` | `i` |
| 388 | `slide_delay` | `i` |
| 392 | `matchstats` | `:TStats_Match` |

### Globals / Consts

| Name | Type |
|---|---|
| `CLEFT` | `i` |
| `CRIGHT` | `i` |
| `CUP` | `i` |
| `CDOWN` | `i` |

### Methods

| Slot | Name | Signature |
|---:|---|---|
| 16 | `New` | `()i` |
| 20 | `Delete` | `()i` |
| 64 | `PaintPlayer` | `(:TKit)i` |
| 72 | `Update` | `()i` |
| 80 | `Render` | `(f)i` |
| 84 | `GetShadowOffsetAndRot` | `(i,*i,*i)i` |
| 92 | `RenderGUI` | `(f,f)i` |
| 96 | `UpdateCalling` | `()i` |
| 100 | `UpdateFundamentals` | `()i` |
| 104 | `UpdateTeamMateId` | `()i` |
| 108 | `UpdateTeamMateId_Human` | `()i` |
| 112 | `UpdateTeamMateId_CPU` | `()i` |
| 116 | `UpdateOpponent` | `()i` |
| 124 | `UpdatePassPotential` | `()i` |
| 128 | `UpdateMovement` | `()i` |
| 132 | `ForceControlCPU` | `()i` |
| 136 | `UpdateJoy` | `()i` |
| 140 | `UpdateJoyAI_TouchControls` | `()i` |
| 144 | `UpdateJoyAI` | `()i` |
| 148 | `DoHeadingAI` | `()i` |
| 152 | `DoKickingAI` | `()i` |
| 156 | `ShootAI` | `()i` |
| 160 | `PassAI` | `()i` |
| 164 | `DoTacklingAI` | `()i` |
| 172 | `ResetKick` | `()i` |
| 180 | `UpdateKeeperPosition` | `()i` |
| 184 | `DoKeeperDiveAI` | `()i` |
| 188 | `KeeperDive` | `(:TInterceptPoint,i)i` |
| 192 | `KeeperCatchLow` | `()i` |
| 196 | `KeeperCatchHigh` | `()i` |
| 200 | `KeeperJump` | `()i` |
| 204 | `BackPass` | `()i` |
| 216 | `CheckFoul` | `(:TPlayer)i` |
| 220 | `YellowCard` | `()i` |
| 224 | `RedCard` | `()i` |
| 228 | `CleanThrough` | `()i` |
| 232 | `CheckBallContact` | `()i` |
| 236 | `CheckKeeperSave` | `()i` |
| 240 | `CheckHoldingKick` | `()i` |
| 244 | `CheckKick` | `()i` |
| 248 | `Call` | `()i` |
| 252 | `TapKick` | `()i` |
| 256 | `TapKickAdvanced` | `()i` |
| 260 | `HoldKick` | `()i` |
| 264 | `HoldKickAdvanced` | `()i` |
| 268 | `SlideBall` | `()i` |
| 272 | `BlockTackle` | `()i` |
| 276 | `BlockSave` | `()i` |
| 280 | `HeadBall` | `()i` |
| 284 | `HeadBallAdvanced` | `()i` |
| 288 | `DiveHeadBall` | `()i` |
| 292 | `InterceptBall` | `(:TBall)i` |
| 296 | `ChaseBall` | `(f,f,:TPlayer)i` |
| 300 | `GetCoveringLocation` | `(f,f)i` |
| 304 | `DoDribbling` | `()i` |
| 308 | `DoRepulsion` | `(f,f,*f,*f,d)i` |
| 312 | `pow` | `(i,i)i` |
| 316 | `MoveYardsClear` | `(f,i,i)i` |
| 324 | `GetTunnelPosition` | `(i)i` |
| 328 | `GetHuddlePosition` | `(*i,*i)i` |
| 332 | `GetShootOutPosition` | `()i` |
| 336 | `GetMatchOverPosition` | `()i` |
| 344 | `PlayerReady` | `()i` |
| 348 | `ResetPosition` | `()i` |
| 352 | `GetShootingDirection` | `()i` |
| 364 | `GetFacingDirection` | `(f)i` |
| 368 | `GetDistanceToByLine` | `(i)f` |
| 372 | `GetMyTeam` | `():TTeam` |
| 376 | `GetOppTeam` | `():TTeam` |
| 380 | `GetHumanNumber` | `()i` |
| 384 | `GetStringAnim` | `([]i)$` |
| 388 | `CheckJoyAngle` | `()i` |
| 392 | `GetOppKeeper` | `():TPlayer` |
| 396 | `GetMouseDirection` | `()i` |
| 400 | `UpdateAnimation` | `()i` |
| 404 | `GetAnimFrame` | `(i)i` |
| 408 | `ValidateAnimDirection` | `()i` |
| 412 | `ValidateKeeperAnim` | `()i` |
| 416 | `PlayerOnFeet` | `()i` |
| 420 | `ImageJumping` | `()i` |
| 424 | `ImageFalling` | `()i` |
| 428 | `ImageHoldingBall` | `(i)i` |
| 432 | `PlayerSliding` | `()i` |
| 436 | `PlayerDiving` | `()i` |
| 440 | `PlayerFalling` | `()i` |
| 444 | `PlayerKicking` | `()i` |
| 448 | `KeeperHoldingBall` | `()i` |
| 452 | `KeeperDiving` | `()i` |
| 456 | `KeeperJumping` | `()i` |
| 460 | `GetKeeperHandHeight` | `()f` |
| 464 | `GetPlayerRunningHandHeight` | `(*f)i` |
| 468 | `DoAnimJump` | `()i` |
| 472 | `DoAnimDive` | `()i` |
| 476 | `DoAnimSlide` | `()i` |
| 480 | `DoAnimFall` | `()i` |
| 484 | `DoAnimKick` | `(i)i` |
| 488 | `DoCelebrations` | `()i` |
| 492 | `PlayerCelebrating` | `()i` |
| 496 | `DoAnimCelebrate` | `(i)i` |
| 500 | `DoAnimCommiserate` | `(i)i` |
| 508 | `GoalScorer` | `()i` |
| 516 | `RecordReplayFrame` | `(i)i` |
| 524 | `UpdateReplay` | `(i)i` |
| 532 | `RenderReplay` | `(f)i` |
| 536 | `UpdateOffside` | `()i` |
| 548 | `CheckOffside` | `()i` |
| 552 | `AddStat` | `(i,f,f,f,f)i` |
| 564 | `AddPlayerRating` | `(i,i,$)i` |
| 568 | `BossPositive` | `()i` |
| 28 | `Compare` | `(:Object)i` |

### Functions

| Slot | Name | Signature |
|---:|---|---|
| 48 | `SetUp` | `()i` |
| 52 | `ClearAll` | `()i` |
| 56 | `CreatePlayerSimple` | `(i,i,i,i,i,i):TPlayer` |
| 60 | `CreateReplayPlayer` | `(:TReplayFrame):TPlayer` |
| 68 | `UpdateAll` | `()i` |
| 76 | `RenderAll` | `(f)i` |
| 88 | `RenderGUIAll` | `(f,f)i` |
| 120 | `UpdatePassPotentialAll` | `()i` |
| 168 | `ResetKickAll` | `()i` |
| 176 | `JoyClearAll` | `()i` |
| 208 | `CheckPlayerContactAll` | `()i` |
| 212 | `DoCollision` | `(:TPlayer,:TPlayer)i` |
| 320 | `SetTunnelPositionAll` | `()i` |
| 340 | `AllPlayersReady` | `()i` |
| 356 | `GetHumanPlayer` | `():TPlayer` |
| 360 | `GetPlayerById` | `(i):TPlayer` |
| 504 | `ResetAnimationsAll` | `()i` |
| 512 | `RecordReplayFramesAll` | `(i)i` |
| 520 | `UpdateReplayAll` | `(i)i` |
| 528 | `RenderReplayAll` | `(f)i` |
| 540 | `UpdatePositionWhenKickedAll` | `(i)i` |
| 544 | `ResetOffsideAll` | `()i` |
| 556 | `UpdateMatchRatingAll` | `()i` |
| 560 | `RecordPlayerStats` | `()i` |

## TReplay

_20 fields, 4 methods, 2 functions_

### Fields - exact object layout

| Offset | Name | Type |
|---:|---|---|
| 8 | `name` | `$` |
| 12 | `teamid1` | `i` |
| 16 | `teamid2` | `i` |
| 20 | `teamname1` | `$` |
| 24 | `teamname2` | `$` |
| 28 | `score1` | `i` |
| 32 | `score2` | `i` |
| 36 | `pitchtype` | `i` |
| 40 | `mowtype` | `i` |
| 44 | `doingweather` | `i` |
| 48 | `weathertype` | `i` |
| 52 | `kit1cols` | `:TKitStrings` |
| 56 | `kit2cols` | `:TKitStrings` |
| 60 | `keeperkit1cols` | `:TKitStrings` |
| 64 | `keeperkit2cols` | `:TKitStrings` |
| 68 | `fixlevel` | `i` |
| 72 | `stadiumsize` | `i` |
| 76 | `ballframes` | `:TList` |
| 80 | `playerframes` | `:TList` |
| 84 | `matchstateframes` | `:TList` |

### Methods

| Slot | Name | Signature |
|---:|---|---|
| 16 | `New` | `()i` |
| 20 | `Delete` | `()i` |
| 56 | `WriteHeader` | `(:TStream)i` |
| 60 | `ReadHeader` | `(:TStream)i` |

### Functions

| Slot | Name | Signature |
|---:|---|---|
| 48 | `CreateReplay` | `(:TTeam,:TTeam,i,i,i,i,i,i,i)$` |
| 52 | `LoadReplayFile` | `($):TReplay` |

## TReplayFrame

_21 fields, 3 methods, 1 functions_

### Fields - exact object layout

| Offset | Name | Type |
|---:|---|---|
| 8 | `frametime` | `i` |
| 12 | `obtext` | `$` |
| 16 | `obtype` | `i` |
| 20 | `id` | `i` |
| 24 | `selno` | `i` |
| 28 | `clubid` | `i` |
| 32 | `skincol` | `i` |
| 36 | `haircol` | `i` |
| 40 | `bootcol` | `i` |
| 44 | `glovecol` | `i` |
| 48 | `x` | `f` |
| 52 | `y` | `f` |
| 56 | `z` | `f` |
| 60 | `xvel` | `f` |
| 64 | `yvel` | `f` |
| 68 | `zvel` | `f` |
| 72 | `frame` | `i` |
| 76 | `facing` | `i` |
| 80 | `rotation` | `f` |
| 84 | `alph` | `f` |
| 88 | `active` | `i` |

### Methods

| Slot | Name | Signature |
|---:|---|---|
| 16 | `New` | `()i` |
| 20 | `Delete` | `()i` |
| 48 | `SaveFrame` | `(:TStream)i` |

### Functions

| Slot | Name | Signature |
|---:|---|---|
| 52 | `LoadFrame` | `(:TStream):TReplayFrame` |

## TWeather

_0 fields, 2 methods, 7 functions_

### Methods

| Slot | Name | Signature |
|---:|---|---|
| 16 | `New` | `()i` |
| 20 | `Delete` | `()i` |

### Functions

| Slot | Name | Signature |
|---:|---|---|
| 48 | `SetUp` | `()i` |
| 52 | `SetWeatherTimes` | `(i,i,i)i` |
| 56 | `Update` | `(i)i` |
| 60 | `UpdateRain` | `()i` |
| 64 | `UpdateReplay` | `(f,i)i` |
| 68 | `UpdateReplayRain` | `(f,i)i` |
| 72 | `Render` | `(i)i` |

## TSnowFlake

_12 fields, 4 methods, 5 functions_

### Fields - exact object layout

| Offset | Name | Type |
|---:|---|---|
| 8 | `x` | `f` |
| 12 | `y` | `f` |
| 16 | `g` | `f` |
| 20 | `rot` | `i` |
| 24 | `a` | `f` |
| 28 | `s` | `f` |
| 32 | `t` | `b` |
| 36 | `w` | `i` |
| 40 | `iner` | `f` |
| 44 | `inerD` | `f` |
| 48 | `d` | `i` |
| 52 | `scl` | `f` |

### Methods

| Slot | Name | Signature |
|---:|---|---|
| 16 | `New` | `()i` |
| 20 | `Delete` | `()i` |
| 60 | `Update` | `()i` |
| 72 | `Render` | `()i` |

### Functions

| Slot | Name | Signature |
|---:|---|---|
| 48 | `SetUp` | `()i` |
| 52 | `Create` | `():TSnowFlake` |
| 56 | `UpdateAll` | `(i)i` |
| 64 | `ResetAll` | `()i` |
| 68 | `RenderAll` | `()i` |

## TInterceptPoint

_5 fields, 2 methods, 0 functions_

### Fields - exact object layout

| Offset | Name | Type |
|---:|---|---|
| 8 | `x` | `f` |
| 12 | `y` | `f` |
| 16 | `intercept_AB` | `f` |
| 20 | `intercept_CD` | `f` |
| 24 | `intercept` | `i` |

### Methods

| Slot | Name | Signature |
|---:|---|---|
| 16 | `New` | `()i` |
| 20 | `Delete` | `()i` |

## TMyGfxModes

_2 fields, 3 methods, 2 functions_

### Fields - exact object layout

| Offset | Name | Type |
|---:|---|---|
| 8 | `w` | `i` |
| 12 | `h` | `i` |

### Methods

| Slot | Name | Signature |
|---:|---|---|
| 16 | `New` | `()i` |
| 20 | `Delete` | `()i` |
| 28 | `Compare` | `(:Object)i` |

### Functions

| Slot | Name | Signature |
|---:|---|---|
| 48 | `Create` | `(i,i)i` |
| 52 | `OnListAlready` | `(i,i)i` |

## TMyBankStream

_0 fields, 3 methods, 1 functions_

### Methods

| Slot | Name | Signature |
|---:|---|---|
| 16 | `New` | `()i` |
| 20 | `Delete` | `()i` |
| 144 | `WriteLine` | `($)i` |

### Functions

| Slot | Name | Signature |
|---:|---|---|
| 164 | `Create` | `(:TBank):TMyBankStream` |

## TMyStream

_1 fields, 3 methods, 0 functions_

### Fields - exact object layout

| Offset | Name | Type |
|---:|---|---|
| 12 | `oldversion` | `i` |

### Methods

| Slot | Name | Signature |
|---:|---|---|
| 16 | `New` | `()i` |
| 20 | `Delete` | `()i` |
| 140 | `ReadLine` | `()$` |

## TContinent

_7 fields, 2 methods, 5 functions_

### Fields - exact object layout

| Offset | Name | Type |
|---:|---|---|
| 8 | `id` | `i` |
| 12 | `name` | `$` |
| 16 | `tla` | `$` |
| 20 | `continentality` | `$` |
| 24 | `federationname` | `$` |
| 28 | `federationshortname` | `$` |
| 32 | `strength` | `i` |

### Methods

| Slot | Name | Signature |
|---:|---|---|
| 16 | `New` | `()i` |
| 20 | `Delete` | `()i` |

### Functions

| Slot | Name | Signature |
|---:|---|---|
| 48 | `CreateContinent` | `($)i` |
| 52 | `LoadData` | `(:TStream)i` |
| 56 | `WriteData` | `(:TStream)i` |
| 60 | `SaveMaster` | `(i,i)i` |
| 64 | `SelectById` | `(i):TContinent` |

## TCompetition

_27 fields, 43 methods, 27 functions_

### Fields - exact object layout

| Offset | Name | Type |
|---:|---|---|
| 8 | `id` | `i` |
| 12 | `name` | `$` |
| 16 | `tla` | `$` |
| 20 | `labelname` | `$` |
| 24 | `locale` | `i` |
| 28 | `level` | `i` |
| 32 | `based` | `i` |
| 36 | `comptype` | `i` |
| 40 | `startyear` | `i` |
| 44 | `startweek` | `i` |
| 48 | `duration` | `i` |
| 52 | `recurring` | `i` |
| 56 | `primarymatchday` | `i` |
| 60 | `secondarymatchday` | `i` |
| 64 | `groups` | `i` |
| 68 | `rounds` | `i` |
| 72 | `legs` | `i` |
| 76 | `townregion` | `i` |
| 80 | `compstatus` | `i` |
| 84 | `priority` | `i` |
| 88 | `minstrength` | `i` |
| 92 | `maxstrength` | `i` |
| 96 | `lfixturelist` | `:TList` |
| 100 | `lpromotionplaces` | `:TList` |
| 104 | `lplacesthatpromotetome` | `:TList` |
| 108 | `teampool` | `[]:TTeamPool` |
| 112 | `tempNoofTeams` | `i` |

### Methods

| Slot | Name | Signature |
|---:|---|---|
| 16 | `New` | `()i` |
| 20 | `Delete` | `()i` |
| 48 | `Destroy` | `()i` |
| 92 | `SetUpCompetition` | `()i` |
| 96 | `CreateTeamPool` | `()i` |
| 100 | `PopulateTeamPool` | `()i` |
| 104 | `CreateFixtureListLeague` | `()i` |
| 108 | `CreateFixtureListKO` | `()i` |
| 116 | `CheckFixtureClash` | `(:TMyDate)i` |
| 120 | `CheckCupQualifyingCompetitions` | `(i)i` |
| 124 | `CheckFixtureClashAfterClubCupRound` | `()i` |
| 128 | `GetMyContinentId` | `()i` |
| 132 | `GetStringArray` | `()[]$` |
| 156 | `GetStringTeamPosition` | `(i)$` |
| 160 | `GetNoofQualifiers` | `()i` |
| 164 | `GetNoofTeamsInRound` | `()i` |
| 168 | `IsComplete` | `(i)i` |
| 180 | `ChangeId` | `(i)i` |
| 184 | `SetPriority` | `()i` |
| 188 | `GetHighestClubNotInContinentalComp` | `():TClub` |
| 192 | `GetFixtureDate` | `(i):TMyDate` |
| 196 | `GetNoofRounds` | `()i` |
| 200 | `GetPrevRound` | `()i` |
| 204 | `GetNextRound` | `()i` |
| 208 | `AllFixturesPlayed` | `()i` |
| 212 | `AllFixturesPopulated` | `()i` |
| 216 | `IsThisCurrentCupRound` | `()i` |
| 220 | `GetCupFirstRound` | `():TCompetition` |
| 224 | `GetCupPreviousRound` | `():TCompetition` |
| 228 | `GetCupNextRound` | `():TCompetition` |
| 232 | `GetCupLastRound` | `():TCompetition` |
| 236 | `PaintPromotionPlaces` | `(:TTable)i` |
| 240 | `PaintPromotedClubs` | `(:TTable)i` |
| 244 | `GetBasedNationId` | `(i)i` |
| 248 | `IsCupFinal` | `()i` |
| 252 | `CountAllocatedContinentalClubsByNation` | `(i)i` |
| 260 | `IsTopDivision` | `()i` |
| 276 | `SortPromotionPlaces` | `()i` |
| 280 | `SortFixtureList` | `()i` |
| 28 | `Compare` | `(:Object)i` |
| 292 | `DoPromotionPlaces` | `()i` |
| 296 | `PromoteToMe` | `(:TTableData,:TCompetition)i` |
| 312 | `ValidatePromotionPlaces` | `()i` |

### Functions

| Slot | Name | Signature |
|---:|---|---|
| 52 | `CreateCompetition` | `($,:TStream)i` |
| 56 | `NewCompetition` | `(i):TCompetition` |
| 60 | `LoadData` | `(:TStream)i` |
| 64 | `WriteData` | `(:TStream,i)i` |
| 68 | `WriteDataMobile` | `(:TStream,i)i` |
| 72 | `SaveMaster` | `(i,i)i` |
| 76 | `SelectById` | `(i):TCompetition` |
| 80 | `SelectByBasedAndName` | `(i,$):TCompetition` |
| 84 | `SelectByTLA` | `($):TCompetition` |
| 88 | `SetUpCompetitionsAll` | `()i` |
| 112 | `GetHomeAndAwayTeam` | `(*i,*i,i,i)i` |
| 136 | `GetStringLocale` | `(i)$` |
| 140 | `GetStringLevel` | `(i)$` |
| 144 | `GetStringBased` | `(i,i)$` |
| 148 | `GetStringCompType` | `(i)$` |
| 152 | `GetStringRegion` | `(i)$` |
| 172 | `InflateIds` | `()i` |
| 176 | `CompressIds` | `()i` |
| 256 | `ResetCompStatusAll` | `()i` |
| 264 | `ReorderCompetitions` | `()i` |
| 268 | `VerifyCupDates` | `()i` |
| 272 | `SortPromotionPlacesAll` | `()i` |
| 284 | `SortListBy` | `(i,i)i` |
| 288 | `PlayFixtures` | `()i` |
| 300 | `Test_UpdateNoofTeamsInLeagues` | `()i` |
| 304 | `Test_CheckNoofTeamsInLeagues` | `()i` |
| 308 | `ValidatePromotionPlacesAll` | `()i` |

## TScreen

_6 fields, 13 methods, 26 functions_

### Fields - exact object layout

| Offset | Name | Type |
|---:|---|---|
| 8 | `name` | `$` |
| 12 | `gadgetlist` | `:TList` |
| 16 | `bg` | `:TImage` |
| 20 | `fDraw` | `()i` |
| 24 | `fUpdate` | `()i` |
| 28 | `lHelp` | `:TList` |

### Methods

| Slot | Name | Signature |
|---:|---|---|
| 16 | `New` | `()i` |
| 20 | `Delete` | `()i` |
| 64 | `AddGadget` | `(:TGadget)i` |
| 68 | `Clear` | `()i` |
| 72 | `ClearGadgetList` | `()i` |
| 76 | `RemoveGadget` | `(:TGadget)i` |
| 80 | `GetGadgetList` | `():TList` |
| 108 | `Draw` | `()i` |
| 124 | `CheckInput` | `()i` |
| 132 | `MoveSelection` | `(i)i` |
| 136 | `MouseSelection` | `()i` |
| 140 | `TabToGadget` | `()i` |
| 144 | `GetGadgetByName` | `($):TGadget` |

### Functions

| Slot | Name | Signature |
|---:|---|---|
| 48 | `SetUp` | `()i` |
| 52 | `SetUpFonts` | `($)i` |
| 56 | `CreateScreen` | `($,:TImage,()i,()i):TScreen` |
| 60 | `ClearAll` | `()i` |
| 84 | `UpdateOffset` | `()i` |
| 88 | `ResetScreens` | `()i` |
| 92 | `SetActive` | `($,$):TScreen` |
| 96 | `SetActiveGadget` | `($)i` |
| 100 | `FindNewActiveGadget` | `()i` |
| 104 | `Render` | `(f)i` |
| 112 | `RenderBorder` | `()i` |
| 116 | `DrawMouse` | `()i` |
| 120 | `Update` | `()i` |
| 128 | `GetInput` | `()i` |
| 148 | `DoMessage` | `($,i,i)i` |
| 152 | `MessageDone` | `()i` |
| 156 | `DoMessageGetText` | `($,i)$` |
| 160 | `TextEntered` | `()i` |
| 164 | `InputDone` | `()i` |
| 168 | `InputCancel` | `()i` |
| 172 | `DoProgressBar` | `(f,$,$,i)i` |
| 176 | `ButtonHelp` | `()i` |
| 180 | `Tutorial` | `()i` |
| 184 | `DoHelp` | `(i)i` |
| 188 | `ButtonHelpOk` | `()i` |
| 192 | `ButtonEndTutorial` | `()i` |

## TGadget

_21 fields, 22 methods, 2 functions_

### Fields - exact object layout

| Offset | Name | Type |
|---:|---|---|
| 8 | `children` | `:TList` |
| 12 | `name` | `$` |
| 16 | `txt` | `$` |
| 20 | `txtalignx` | `i` |
| 24 | `txtlines` | `:TList` |
| 28 | `txtw` | `f` |
| 32 | `x` | `f` |
| 36 | `y` | `f` |
| 40 | `h` | `f` |
| 44 | `w` | `f` |
| 48 | `colour` | `$` |
| 52 | `txtcolour` | `$` |
| 56 | `alive` | `i` |
| 60 | `hidden` | `i` |
| 64 | `fHit` | `()i` |
| 68 | `alph` | `f` |
| 72 | `forcetxtalpha` | `i` |
| 76 | `fntSize` | `i` |
| 80 | `lbl_ToolTip` | `:TLabel` |
| 84 | `desx` | `f` |
| 88 | `desy` | `f` |

### Methods

| Slot | Name | Signature |
|---:|---|---|
| 16 | `New` | `()i` |
| 20 | `Delete` | `()i` |
| 52 | `Update` | `()i` |
| 56 | `UpdateChildren` | `()i` |
| 60 | `UpdateToolTip` | `()i` |
| 64 | `ClearChildren` | `()i` |
| 68 | `Draw` | `()i` |
| 72 | `DrawChildren` | `()i` |
| 76 | `DrawHighlight` | `()i` |
| 80 | `RenderHighlight` | `()i` |
| 84 | `Hide` | `()i` |
| 88 | `Show` | `()i` |
| 92 | `SetFontSize` | `(i)i` |
| 96 | `MouseOver` | `()i` |
| 100 | `SetText` | `($,$,i,i)i` |
| 104 | `DrawGadgetText` | `($,i)i` |
| 108 | `SetColour` | `($,$)i` |
| 112 | `SetAlph` | `(f)i` |
| 116 | `AddChild` | `(:TGadget)i` |
| 120 | `GetChildren` | `():TList` |
| 128 | `CreateToolTip` | `($)i` |
| 132 | `SetPosition` | `(i,i,i)i` |

### Functions

| Slot | Name | Signature |
|---:|---|---|
| 48 | `SetUp` | `()i` |
| 124 | `GetActiveGadgetName` | `()$` |

## TButton

_4 fields, 8 methods, 1 functions_

### Fields - exact object layout

| Offset | Name | Type |
|---:|---|---|
| 92 | `bstyle` | `i` |
| 96 | `image` | `:TImage` |
| 100 | `imageoverride` | `i` |
| 104 | `icon` | `:TImage` |

### Methods

| Slot | Name | Signature |
|---:|---|---|
| 16 | `New` | `()i` |
| 20 | `Delete` | `()i` |
| 52 | `Update` | `()i` |
| 68 | `Draw` | `()i` |
| 140 | `SetImage` | `(:TImage)i` |
| 144 | `SetIcon` | `(:TImage)i` |
| 148 | `SetButtonStyle` | `(i)i` |
| 112 | `SetAlph` | `(f)i` |

### Functions

| Slot | Name | Signature |
|---:|---|---|
| 136 | `CreateButton` | `($,$,i,i,i,i,i,i,$,$,:TImage,()i,f,i,$):TButton` |

## TInputBox

_5 fields, 7 methods, 2 functions_

### Fields - exact object layout

| Offset | Name | Type |
|---:|---|---|
| 92 | `limitchars` | `i` |
| 96 | `gettinginput` | `i` |
| 100 | `fRet` | `()i` |
| 104 | `image` | `:TImage` |
| 108 | `hideinput` | `i` |

### Methods

| Slot | Name | Signature |
|---:|---|---|
| 16 | `New` | `()i` |
| 20 | `Delete` | `()i` |
| 140 | `CreateInputImage` | `()i` |
| 52 | `Update` | `()i` |
| 68 | `Draw` | `()i` |
| 112 | `SetAlph` | `(f)i` |
| 148 | `GetText` | `()$` |

### Functions

| Slot | Name | Signature |
|---:|---|---|
| 136 | `CreateInputBox` | `($,i,i,i,i,i,i,$,$,i,f,()i,i,$):TInputBox` |
| 144 | `GetInputText` | `()i` |

## TTable

_10 fields, 31 methods, 3 functions_

### Fields - exact object layout

| Offset | Name | Type |
|---:|---|---|
| 92 | `columns` | `:TList` |
| 96 | `items` | `:TList` |
| 100 | `numdisplayitems` | `i` |
| 104 | `ih` | `i` |
| 108 | `activated` | `i` |
| 112 | `selecteditem` | `i` |
| 116 | `itemoffset` | `i` |
| 120 | `highlightcol` | `$` |
| 124 | `showheadings` | `i` |
| 128 | `fRet` | `()i` |

### Methods

| Slot | Name | Signature |
|---:|---|---|
| 16 | `New` | `()i` |
| 20 | `Delete` | `()i` |
| 144 | `AddColumn` | `(i,$,$,$,i)i` |
| 148 | `AddItem` | `([]$,$,$)i` |
| 152 | `SetItemIcons` | `(i,[]:TImage)i` |
| 156 | `ClearItems` | `()i` |
| 160 | `SetColumnHeading` | `(i,$)i` |
| 164 | `SetColumnWidth` | `(i,i)i` |
| 168 | `SetRowColoursAll` | `($)i` |
| 172 | `SetRowColour` | `(i,$)i` |
| 176 | `SetHighlightColour` | `($)i` |
| 180 | `SetItemText` | `(i,i,$)i` |
| 184 | `SetItemFields` | `(i,[]$)i` |
| 112 | `SetAlph` | `(f)i` |
| 52 | `Update` | `()i` |
| 188 | `UpdateActivated` | `()i` |
| 192 | `ScrollUp` | `()i` |
| 196 | `ScrollDown` | `()i` |
| 68 | `Draw` | `()i` |
| 200 | `HighlightItem` | `()i` |
| 208 | `SelectCurrentItem` | `()i` |
| 212 | `GetSelectedItem` | `()i` |
| 216 | `GetSelectedText` | `(i)$` |
| 220 | `SelectItemByRow` | `(i)i` |
| 224 | `SelectItemByText` | `($,i)i` |
| 228 | `CheckTableOffset` | `()i` |
| 232 | `ShowItem` | `(i)i` |
| 236 | `CountItems` | `()i` |
| 240 | `GetNoofDisplayItems` | `()i` |
| 244 | `ShowColumnHeadings` | `()i` |
| 248 | `HideColumnHeadings` | `()i` |

### Functions

| Slot | Name | Signature |
|---:|---|---|
| 136 | `CreateTable` | `($,i,i,i,i,i,i,$,f,i,()i):TTable` |
| 140 | `CreateTableImage` | `()i` |
| 204 | `ActivateTable` | `()i` |

## TColumn

_5 fields, 2 methods, 0 functions_

### Fields - exact object layout

| Offset | Name | Type |
|---:|---|---|
| 8 | `w` | `i` |
| 12 | `heading` | `$` |
| 16 | `txtcolour` | `$` |
| 20 | `bgcolour` | `$` |
| 24 | `alignx` | `i` |

### Methods

| Slot | Name | Signature |
|---:|---|---|
| 16 | `New` | `()i` |
| 20 | `Delete` | `()i` |

## TRow

_4 fields, 2 methods, 0 functions_

### Fields - exact object layout

| Offset | Name | Type |
|---:|---|---|
| 8 | `fields` | `[]$` |
| 12 | `icons` | `[]:TImage` |
| 16 | `txtcolour` | `$` |
| 20 | `bgcolour` | `$` |

### Methods

| Slot | Name | Signature |
|---:|---|---|
| 16 | `New` | `()i` |
| 20 | `Delete` | `()i` |

## TCombo

_7 fields, 21 methods, 2 functions_

### Fields - exact object layout

| Offset | Name | Type |
|---:|---|---|
| 92 | `btn_head` | `:TButton` |
| 96 | `buttons` | `:TList` |
| 100 | `activated` | `i` |
| 104 | `selecteditem` | `i` |
| 108 | `fRet` | `()i` |
| 112 | `itemoffset` | `i` |
| 116 | `bstyle` | `i` |

### Methods

| Slot | Name | Signature |
|---:|---|---|
| 16 | `New` | `()i` |
| 20 | `Delete` | `()i` |
| 140 | `ClearItems` | `()i` |
| 144 | `AddItem` | `($,$,$,i)i` |
| 52 | `Update` | `()i` |
| 148 | `ScrollUp` | `()i` |
| 152 | `ScrollDown` | `()i` |
| 156 | `GetNoofDisplayItems` | `()i` |
| 164 | `Deactivate` | `()i` |
| 68 | `Draw` | `()i` |
| 168 | `DrawItems` | `()i` |
| 172 | `SelectItem` | `(i)i` |
| 176 | `SelectItemById` | `(i)i` |
| 180 | `SelectItemByLetter` | `(i)i` |
| 184 | `CountItems` | `()i` |
| 188 | `GetSelectedItem` | `()i` |
| 192 | `GetSelectedItemId` | `()i` |
| 196 | `GetSelectedText` | `()$` |
| 200 | `GetSelectedColour` | `()$` |
| 108 | `SetColour` | `($,$)i` |
| 112 | `SetAlph` | `(f)i` |

### Functions

| Slot | Name | Signature |
|---:|---|---|
| 136 | `CreateCombo` | `($,$,i,i,i,i,i,i,$,$,f,()i,i):TCombo` |
| 160 | `Activate` | `()i` |

## TPanel

_2 fields, 6 methods, 1 functions_

### Fields - exact object layout

| Offset | Name | Type |
|---:|---|---|
| 92 | `image` | `:TImage` |
| 96 | `bodyimage` | `:TImage` |

### Methods

| Slot | Name | Signature |
|---:|---|---|
| 16 | `New` | `()i` |
| 20 | `Delete` | `()i` |
| 140 | `CreateBody` | `(i,i)i` |
| 52 | `Update` | `()i` |
| 68 | `Draw` | `()i` |
| 112 | `SetAlph` | `(f)i` |

### Functions

| Slot | Name | Signature |
|---:|---|---|
| 136 | `CreatePanel` | `($,$,i,i,i,i,$,$,i,f,i,i,i):TPanel` |

## TLabel

_9 fields, 6 methods, 1 functions_

### Fields - exact object layout

| Offset | Name | Type |
|---:|---|---|
| 92 | `image` | `:TImage` |
| 96 | `imgborder` | `:TImage` |
| 100 | `style` | `i` |
| 104 | `icon` | `:TImage` |
| 108 | `pointer` | `i` |
| 112 | `pointerxoff` | `i` |
| 116 | `pointeryoff` | `i` |
| 120 | `scrolltext` | `f` |
| 124 | `scrollx` | `f` |

### Methods

| Slot | Name | Signature |
|---:|---|---|
| 16 | `New` | `()i` |
| 20 | `Delete` | `()i` |
| 52 | `Update` | `()i` |
| 68 | `Draw` | `()i` |
| 112 | `SetAlph` | `(f)i` |
| 140 | `SetIcon` | `(:TImage)i` |

### Functions

| Slot | Name | Signature |
|---:|---|---|
| 136 | `CreateLabel` | `($,$,i,i,i,i,i,$,$,f,i,i,i,i,:TImage,i,i,i,i,$,f):TLabel` |

## TProgressBar

_12 fields, 9 methods, 1 functions_

### Fields - exact object layout

| Offset | Name | Type |
|---:|---|---|
| 92 | `image` | `:TImage` |
| 96 | `fillimage` | `:TImage` |
| 100 | `fillicon` | `:TImage` |
| 104 | `fillcolour` | `$` |
| 108 | `percent` | `f` |
| 112 | `livepercent` | `f` |
| 116 | `oldpercent` | `f` |
| 120 | `oldfillcolour` | `$` |
| 124 | `oldfillalpha` | `f` |
| 128 | `oldfillfade` | `i` |
| 132 | `boosticon` | `:TImage` |
| 136 | `numboost` | `i` |

### Methods

| Slot | Name | Signature |
|---:|---|---|
| 16 | `New` | `()i` |
| 20 | `Delete` | `()i` |
| 52 | `Update` | `()i` |
| 68 | `Draw` | `()i` |
| 108 | `SetColour` | `($,$)i` |
| 140 | `SetPercent` | `(f,i)i` |
| 144 | `SetOldPercent` | `(f,i)i` |
| 148 | `SetBoostIcon` | `(:TImage,i)i` |
| 112 | `SetAlph` | `(f)i` |

### Functions

| Slot | Name | Signature |
|---:|---|---|
| 136 | `CreateProgressBar` | `($,$,i,i,i,i,i,$,$,$,f,i,:TImage):TProgressBar` |

## THelpBox

_4 fields, 2 methods, 1 functions_

### Fields - exact object layout

| Offset | Name | Type |
|---:|---|---|
| 8 | `lbl_Help1` | `:TLabel` |
| 12 | `lbl_Help2` | `:TLabel` |
| 16 | `btn_Ok` | `:TButton` |
| 20 | `btn_EndTutorial` | `:TButton` |

### Methods

| Slot | Name | Signature |
|---:|---|---|
| 16 | `New` | `()i` |
| 20 | `Delete` | `()i` |

### Functions

| Slot | Name | Signature |
|---:|---|---|
| 48 | `Create` | `(:TGadget,i,i,i,i,$,i,i):THelpBox` |

## TScreen_Language

_0 fields, 2 methods, 3 functions_

### Methods

| Slot | Name | Signature |
|---:|---|---|
| 16 | `New` | `()i` |
| 20 | `Delete` | `()i` |

### Functions

| Slot | Name | Signature |
|---:|---|---|
| 48 | `CreateScreen` | `()i` |
| 52 | `SetUpScreen` | `(i)i` |
| 56 | `ButtonLanguage` | `()i` |

## TScreen_MainMenu

_0 fields, 2 methods, 19 functions_

### Methods

| Slot | Name | Signature |
|---:|---|---|
| 16 | `New` | `()i` |
| 20 | `Delete` | `()i` |

### Functions

| Slot | Name | Signature |
|---:|---|---|
| 48 | `CreateScreen` | `()i` |
| 52 | `SetUpScreen` | `()i` |
| 56 | `LoadCredits` | `()i` |
| 60 | `Update` | `()i` |
| 64 | `ButtonQuit` | `()i` |
| 68 | `NewGame` | `()i` |
| 72 | `ButtonLoadGame` | `()i` |
| 76 | `UpdateLoadTable` | `()i` |
| 80 | `ButtonLoadSaveFile` | `()i` |
| 84 | `ButtonDeleteSaveFile` | `()i` |
| 88 | `ButtonReplays` | `()i` |
| 92 | `UpdateReplayTable` | `()i` |
| 96 | `ButtonLoadReplayFile` | `()i` |
| 100 | `ButtonDeleteReplayFile` | `()i` |
| 104 | `UpdateVersionInfo` | `()i` |
| 108 | `ButtonHome` | `()i` |
| 112 | `ButtonFacebook` | `()i` |
| 116 | `ButtonTwitter` | `()i` |
| 120 | `ButtonMobile` | `()i` |

## TScreen_Options

_0 fields, 2 methods, 26 functions_

### Methods

| Slot | Name | Signature |
|---:|---|---|
| 16 | `New` | `()i` |
| 20 | `Delete` | `()i` |

### Functions

| Slot | Name | Signature |
|---:|---|---|
| 48 | `CreateScreen` | `()i` |
| 52 | `SetUpScreen` | `()i` |
| 56 | `RefreshButtons` | `()i` |
| 60 | `ButtonLanguage` | `()i` |
| 64 | `ButtonDifficulty` | `()i` |
| 68 | `ButtonRadar` | `()i` |
| 72 | `ButtonMatchLength` | `()i` |
| 76 | `ButtonMatchSpeed` | `()i` |
| 80 | `ButtonMusic` | `()i` |
| 84 | `ButtonSFX` | `()i` |
| 88 | `ButtonWindow` | `()i` |
| 92 | `ResetScreen` | `()i` |
| 96 | `ButtonCam` | `()i` |
| 100 | `ComboRes` | `()i` |
| 104 | `ButtonMatchFx` | `()i` |
| 108 | `ButtonBossFx` | `()i` |
| 112 | `ButtonDistance` | `()i` |
| 116 | `ButtonToolTips` | `()i` |
| 120 | `ButtonHighlightBall` | `()i` |
| 124 | `ButtonShowEnergy` | `()i` |
| 128 | `ButtonCurrency` | `()i` |
| 132 | `ButtonFreekicks` | `()i` |
| 136 | `ButtonCorners` | `()i` |
| 140 | `ButtonBack` | `()i` |
| 144 | `ButtonTick` | `()i` |
| 148 | `ButtonFixKick` | `()i` |

## TScreen_Controls

_0 fields, 2 methods, 8 functions_

### Methods

| Slot | Name | Signature |
|---:|---|---|
| 16 | `New` | `()i` |
| 20 | `Delete` | `()i` |

### Functions

| Slot | Name | Signature |
|---:|---|---|
| 48 | `CreateScreen` | `()i` |
| 52 | `SetUpScreen` | `()i` |
| 56 | `ButtonSimple` | `()i` |
| 60 | `ButtonAdvanced` | `()i` |
| 64 | `RefreshButtons` | `()i` |
| 68 | `ButtonBack` | `()i` |
| 72 | `ButtonTick` | `()i` |
| 76 | `ButtonControls` | `()i` |

## TScreen_NewPlayer

_0 fields, 2 methods, 13 functions_

### Methods

| Slot | Name | Signature |
|---:|---|---|
| 16 | `New` | `()i` |
| 20 | `Delete` | `()i` |

### Functions

| Slot | Name | Signature |
|---:|---|---|
| 48 | `CreateScreen` | `()i` |
| 52 | `SetUpScreen` | `()i` |
| 56 | `ComboNation` | `()i` |
| 60 | `ComboClubNation` | `()i` |
| 64 | `ComboClubLeague` | `()i` |
| 68 | `ComboPosition` | `()i` |
| 72 | `ComboSide` | `()i` |
| 76 | `ComboSkin` | `()i` |
| 80 | `ComboHair` | `()i` |
| 84 | `RefreshKit` | `()i` |
| 88 | `ButtonPlay` | `()i` |
| 92 | `DoClubTrial` | `()i` |
| 96 | `ButtonQuit` | `()i` |

## TScreen_CreateAccount

_0 fields, 2 methods, 3 functions_

### Methods

| Slot | Name | Signature |
|---:|---|---|
| 16 | `New` | `()i` |
| 20 | `Delete` | `()i` |

### Functions

| Slot | Name | Signature |
|---:|---|---|
| 48 | `CreateScreen` | `()i` |
| 52 | `SetUpScreen` | `()i` |
| 56 | `ButtonPlay` | `()i` |

## TScreen_Difficulty

_0 fields, 2 methods, 5 functions_

### Methods

| Slot | Name | Signature |
|---:|---|---|
| 16 | `New` | `()i` |
| 20 | `Delete` | `()i` |

### Functions

| Slot | Name | Signature |
|---:|---|---|
| 48 | `CreateScreen` | `()i` |
| 52 | `SetUpScreen` | `()i` |
| 56 | `ButtonEasy` | `()i` |
| 60 | `ButtonNormal` | `()i` |
| 64 | `ButtonHard` | `()i` |

## TPromotionPlace

_3 fields, 5 methods, 5 functions_

### Fields - exact object layout

| Offset | Name | Type |
|---:|---|---|
| 8 | `parentid` | `i` |
| 12 | `place` | `i` |
| 16 | `promotiontoid` | `i` |

### Methods

| Slot | Name | Signature |
|---:|---|---|
| 16 | `New` | `()i` |
| 20 | `Delete` | `()i` |
| 68 | `AddToParentLists` | `()i` |
| 72 | `GetStringPlace` | `()$` |
| 28 | `Compare` | `(:Object)i` |

### Functions

| Slot | Name | Signature |
|---:|---|---|
| 48 | `CreatePromotionPlace` | `($)i` |
| 52 | `NewPromotionPlace` | `(i,i,i)i` |
| 56 | `LoadData` | `(:TStream)i` |
| 60 | `WriteData` | `(:TStream)i` |
| 64 | `SaveMaster` | `(i,i)i` |

## TTeamPool

_1 fields, 14 methods, 0 functions_

### Fields - exact object layout

| Offset | Name | Type |
|---:|---|---|
| 8 | `list` | `:TList` |

### Methods

| Slot | Name | Signature |
|---:|---|---|
| 16 | `New` | `()i` |
| 20 | `Delete` | `()i` |
| 48 | `LoadData` | `(:TStream)i` |
| 52 | `WriteData` | `(:TStream)i` |
| 56 | `AddItem` | `(i,$,i)i` |
| 60 | `AddItemLeagueContinuation` | `(:TTableData)i` |
| 64 | `AddTableDataItem` | `(:TTableData)i` |
| 68 | `Clear` | `()i` |
| 72 | `GetItemById` | `(i):TTableData` |
| 76 | `GetItemByTeamId` | `(i):TTableData` |
| 80 | `GetTeamPosition` | `(i)i` |
| 84 | `GetStringTeamPosition` | `(i)$` |
| 88 | `ShuffleIds` | `()i` |
| 92 | `SortTableBy` | `(i)i` |

## TTableData

_13 fields, 5 methods, 2 functions_

### Fields - exact object layout

| Offset | Name | Type |
|---:|---|---|
| 8 | `id` | `i` |
| 12 | `teamid` | `i` |
| 16 | `teamname` | `$` |
| 20 | `teamstrength` | `i` |
| 24 | `played` | `i` |
| 28 | `won` | `i` |
| 32 | `drawn` | `i` |
| 36 | `lost` | `i` |
| 40 | `goalsf` | `i` |
| 44 | `goalsa` | `i` |
| 48 | `points` | `i` |
| 52 | `randno` | `i` |
| 56 | `longlat` | `f` |

### Methods

| Slot | Name | Signature |
|---:|---|---|
| 16 | `New` | `()i` |
| 20 | `Delete` | `()i` |
| 56 | `WriteData` | `(:TStream)i` |
| 60 | `GetStringArray` | `(i,i)[]$` |
| 28 | `Compare` | `(:Object)i` |

### Functions

| Slot | Name | Signature |
|---:|---|---|
| 48 | `Create` | `(i,i,$,i):TTableData` |
| 52 | `LoadTableData` | `($):TTableData` |

## TStadium

_6 fields, 2 methods, 4 functions_

### Fields - exact object layout

| Offset | Name | Type |
|---:|---|---|
| 8 | `id` | `i` |
| 12 | `name` | `$` |
| 16 | `nation` | `i` |
| 20 | `capacity` | `i` |
| 24 | `longitude` | `f` |
| 28 | `latitude` | `f` |

### Methods

| Slot | Name | Signature |
|---:|---|---|
| 16 | `New` | `()i` |
| 20 | `Delete` | `()i` |

### Functions

| Slot | Name | Signature |
|---:|---|---|
| 48 | `CreateStadium` | `($)i` |
| 52 | `LoadData` | `(:TStream)i` |
| 56 | `WriteData` | `(:TStream)i` |
| 60 | `SelectById` | `(i):TStadium` |

## TScreen_EditMenu

_0 fields, 2 methods, 10 functions_

### Methods

| Slot | Name | Signature |
|---:|---|---|
| 16 | `New` | `()i` |
| 20 | `Delete` | `()i` |

### Functions

| Slot | Name | Signature |
|---:|---|---|
| 48 | `CreateScreen` | `()i` |
| 52 | `SetUpScreen` | `()i` |
| 56 | `ButtonContinents` | `()i` |
| 60 | `ButtonNations` | `()i` |
| 64 | `ButtonTestData` | `()i` |
| 68 | `ButtonSave` | `()i` |
| 72 | `ButtonSaveMobile` | `()i` |
| 76 | `ReorderData` | `()i` |
| 80 | `ButtonQuit` | `()i` |
| 84 | `SaveMasterFiles` | `(i)i` |

## TScreen_EditContinents

_0 fields, 2 methods, 7 functions_

### Methods

| Slot | Name | Signature |
|---:|---|---|
| 16 | `New` | `()i` |
| 20 | `Delete` | `()i` |

### Functions

| Slot | Name | Signature |
|---:|---|---|
| 48 | `CreateScreen` | `()i` |
| 52 | `SetUpScreen` | `(i)i` |
| 56 | `ButtonQuit` | `()i` |
| 60 | `ButtonPrevCont` | `()i` |
| 64 | `ButtonNextCont` | `()i` |
| 68 | `UpdateCont` | `()i` |
| 72 | `GoMember` | `()i` |

## TScreen_EditNations

_0 fields, 2 methods, 10 functions_

### Methods

| Slot | Name | Signature |
|---:|---|---|
| 16 | `New` | `()i` |
| 20 | `Delete` | `()i` |

### Functions

| Slot | Name | Signature |
|---:|---|---|
| 48 | `CreateScreen` | `()i` |
| 52 | `SetUpScreen` | `(i)i` |
| 56 | `ButtonQuit` | `()i` |
| 60 | `ButtonPrevNat` | `()i` |
| 64 | `ButtonNextNat` | `()i` |
| 68 | `UpdateNat` | `()i` |
| 72 | `ComboNation` | `()i` |
| 76 | `GoMember` | `()i` |
| 80 | `RefreshKits` | `()i` |
| 84 | `EditKit` | `()i` |

## TScreen_Clubs

_0 fields, 2 methods, 9 functions_

### Methods

| Slot | Name | Signature |
|---:|---|---|
| 16 | `New` | `()i` |
| 20 | `Delete` | `()i` |

### Functions

| Slot | Name | Signature |
|---:|---|---|
| 48 | `CreateScreen` | `()i` |
| 52 | `SetUpScreen` | `()i` |
| 56 | `ComboLocale` | `()i` |
| 60 | `ComboBased` | `()i` |
| 64 | `ButtonQuit` | `()i` |
| 68 | `ButtonEdit` | `()i` |
| 72 | `ButtonDelete` | `()i` |
| 76 | `ButtonNew` | `()i` |
| 80 | `ButtonSwitchNames` | `()i` |

## TScreen_EditClubs

_0 fields, 2 methods, 8 functions_

### Methods

| Slot | Name | Signature |
|---:|---|---|
| 16 | `New` | `()i` |
| 20 | `Delete` | `()i` |

### Functions

| Slot | Name | Signature |
|---:|---|---|
| 48 | `CreateScreen` | `()i` |
| 52 | `SetUpScreen` | `(i,$)i` |
| 56 | `ButtonQuit` | `()i` |
| 60 | `ButtonPrevClub` | `()i` |
| 64 | `ButtonNextClub` | `()i` |
| 68 | `UpdateClub` | `()i` |
| 72 | `RefreshKits` | `()i` |
| 76 | `EditKit` | `()i` |

## TScreen_Competitions

_0 fields, 2 methods, 11 functions_

### Methods

| Slot | Name | Signature |
|---:|---|---|
| 16 | `New` | `()i` |
| 20 | `Delete` | `()i` |

### Functions

| Slot | Name | Signature |
|---:|---|---|
| 48 | `CreateScreen` | `()i` |
| 52 | `SetUpScreen` | `()i` |
| 56 | `ButtonQuit` | `()i` |
| 60 | `ButtonEdit` | `()i` |
| 64 | `ButtonDelete` | `()i` |
| 68 | `ButtonDuplicate` | `()i` |
| 72 | `ButtonNew` | `()i` |
| 76 | `ButtonInflateIds` | `()i` |
| 80 | `ButtonCompressIds` | `()i` |
| 84 | `ComboLevel` | `()i` |
| 88 | `ComboLocale` | `()i` |

## TScreen_EditCompetition

_0 fields, 2 methods, 8 functions_

### Methods

| Slot | Name | Signature |
|---:|---|---|
| 16 | `New` | `()i` |
| 20 | `Delete` | `()i` |

### Functions

| Slot | Name | Signature |
|---:|---|---|
| 48 | `CreateScreen` | `()i` |
| 52 | `SetUpScreen` | `(i,$)i` |
| 56 | `ButtonQuit` | `()i` |
| 60 | `ButtonAddPlace` | `()i` |
| 64 | `ButtonDeletePlace` | `()i` |
| 68 | `ButtonPrevComp` | `()i` |
| 72 | `ButtonNextComp` | `()i` |
| 76 | `UpdateComp` | `()i` |

## TScreen_Promotions

_0 fields, 2 methods, 6 functions_

### Methods

| Slot | Name | Signature |
|---:|---|---|
| 16 | `New` | `()i` |
| 20 | `Delete` | `()i` |

### Functions

| Slot | Name | Signature |
|---:|---|---|
| 48 | `CreateScreen` | `()i` |
| 52 | `SetUpScreen` | `()i` |
| 56 | `ButtonQuit` | `()i` |
| 60 | `ComboNation` | `()i` |
| 64 | `ButtonPromote` | `()i` |
| 68 | `ButtonRelegate` | `()i` |

## TScreen_ContinentalComps

_0 fields, 2 methods, 13 functions_

### Methods

| Slot | Name | Signature |
|---:|---|---|
| 16 | `New` | `()i` |
| 20 | `Delete` | `()i` |

### Functions

| Slot | Name | Signature |
|---:|---|---|
| 48 | `CreateScreen` | `()i` |
| 52 | `SetUpScreen` | `()i` |
| 56 | `ButtonQuit` | `()i` |
| 60 | `ComboContinent` | `()i` |
| 64 | `ComboComp` | `()i` |
| 68 | `RefreshQualifiers` | `()i` |
| 72 | `ButtonEditComp` | `()i` |
| 76 | `ButtonEditPlaceComp` | `()i` |
| 80 | `ButtonEditClub` | `()i` |
| 84 | `ButtonGoToClubs` | `()i` |
| 88 | `RefreshClubCombo` | `()i` |
| 92 | `ComboSelectClub` | `()i` |
| 96 | `ButtonRemoveClub` | `()i` |

## TScreen_EditKits

_0 fields, 2 methods, 6 functions_

### Methods

| Slot | Name | Signature |
|---:|---|---|
| 16 | `New` | `()i` |
| 20 | `Delete` | `()i` |

### Functions

| Slot | Name | Signature |
|---:|---|---|
| 48 | `CreateScreen` | `()i` |
| 52 | `SetUpScreen` | `(:TBase_Team,i)i` |
| 56 | `ButtonQuit` | `()i` |
| 60 | `RefreshKits` | `()i` |
| 64 | `UpdateKitCmb` | `()i` |
| 68 | `UpdateKitInp` | `()i` |

## TScreen_Calendar

_0 fields, 2 methods, 3 functions_

### Methods

| Slot | Name | Signature |
|---:|---|---|
| 16 | `New` | `()i` |
| 20 | `Delete` | `()i` |

### Functions

| Slot | Name | Signature |
|---:|---|---|
| 48 | `CreateScreen` | `()i` |
| 52 | `SetUpScreen` | `()i` |
| 56 | `ButtonQuit` | `()i` |

## TDate

_1 fields, 13 methods, 5 functions_

### Fields - exact object layout

| Offset | Name | Type |
|---:|---|---|
| 8 | `gDate` | `i` |

### Methods

| Slot | Name | Signature |
|---:|---|---|
| 16 | `New` | `()i` |
| 20 | `Delete` | `()i` |
| 52 | `SetDate` | `(i,i,i)i` |
| 56 | `SetDateStr` | `($)i` |
| 60 | `SetJulian` | `(i)i` |
| 64 | `GetJulian` | `()i` |
| 68 | `GetDate` | `(*i,*i,*i)i` |
| 72 | `GetString` | `(i,i)$` |
| 76 | `ChangeDate` | `(i,i,i)i` |
| 80 | `GetWeekday` | `()i` |
| 100 | `GetDayOfTheMonth` | `()i` |
| 104 | `GetMonth` | `()i` |
| 108 | `GetYear` | `()i` |

### Functions

| Slot | Name | Signature |
|---:|---|---|
| 48 | `Create` | `(i,i,i):TDate` |
| 84 | `Weekday` | `(i)i` |
| 88 | `GetStringWeekday` | `(i,i)$` |
| 92 | `GetStringMonth` | `(i,i)$` |
| 96 | `GetWeekdayDates` | `(:TDate,:TDate,i)[]:TDate` |

## TMyDate

_1 fields, 12 methods, 2 functions_

### Fields - exact object layout

| Offset | Name | Type |
|---:|---|---|
| 8 | `sdate` | `i` |

### Methods

| Slot | Name | Signature |
|---:|---|---|
| 16 | `New` | `()i` |
| 20 | `Delete` | `()i` |
| 56 | `SetDate` | `(i,i,i)i` |
| 60 | `AddDays` | `(i)i` |
| 64 | `AddWeeks` | `(i)i` |
| 68 | `AddYears` | `(i)i` |
| 72 | `SetDateByTraditionalDate` | `(i,i,i)i` |
| 76 | `GetDay` | `()i` |
| 80 | `GetWeek` | `()i` |
| 84 | `GetYear` | `()i` |
| 88 | `GetStringDay` | `(i)$` |
| 92 | `GetString` | `($)$` |

### Functions

| Slot | Name | Signature |
|---:|---|---|
| 48 | `Create` | `(i,i,i):TMyDate` |
| 52 | `CopyDate` | `(:TMyDate):TMyDate` |

## TScreen_TestMenu

_0 fields, 2 methods, 3 functions_

### Methods

| Slot | Name | Signature |
|---:|---|---|
| 16 | `New` | `()i` |
| 20 | `Delete` | `()i` |

### Functions

| Slot | Name | Signature |
|---:|---|---|
| 48 | `CreateScreen` | `()i` |
| 52 | `SetUpScreen` | `()i` |
| 56 | `ButtonQuit` | `()i` |

## TScreen_TestTournaments

_0 fields, 2 methods, 12 functions_

### Methods

| Slot | Name | Signature |
|---:|---|---|
| 16 | `New` | `()i` |
| 20 | `Delete` | `()i` |

### Functions

| Slot | Name | Signature |
|---:|---|---|
| 48 | `CreateScreen` | `()i` |
| 52 | `SetUpScreen` | `()i` |
| 56 | `ComboLevel` | `()i` |
| 60 | `ComboLocale` | `()i` |
| 64 | `ComboBased` | `()i` |
| 68 | `ComboCompetition` | `()i` |
| 72 | `FilterGroup` | `()i` |
| 76 | `FilterRound` | `()i` |
| 80 | `CheckGroups` | `()i` |
| 84 | `CheckRounds` | `()i` |
| 88 | `ButtonQuit` | `()i` |
| 92 | `ButtonPlay` | `()i` |

## TScreen_TestFixtures

_0 fields, 2 methods, 6 functions_

### Methods

| Slot | Name | Signature |
|---:|---|---|
| 16 | `New` | `()i` |
| 20 | `Delete` | `()i` |

### Functions

| Slot | Name | Signature |
|---:|---|---|
| 48 | `CreateScreen` | `()i` |
| 52 | `SetUpScreen` | `()i` |
| 56 | `CheckShowFixtures` | `(:TCompetition)i` |
| 60 | `ButtonQuit` | `()i` |
| 64 | `ButtonPlay` | `()i` |
| 68 | `ComboContinent` | `()i` |

## TScreen_GameMenu

_0 fields, 2 methods, 9 functions_

### Methods

| Slot | Name | Signature |
|---:|---|---|
| 16 | `New` | `()i` |
| 20 | `Delete` | `()i` |

### Functions

| Slot | Name | Signature |
|---:|---|---|
| 48 | `CreateScreen` | `()i` |
| 52 | `SetUpScreen` | `()i` |
| 56 | `UpdateTitlePanel` | `()i` |
| 60 | `UpdateNavPanel` | `()i` |
| 64 | `UpdateMatchRefresh` | `()i` |
| 68 | `ButtonCompetitions` | `()i` |
| 72 | `ButtonQuit` | `()i` |
| 76 | `ButtonPlay` | `()i` |
| 80 | `ButtonRelationships` | `()i` |

## TScreen_Home

_0 fields, 2 methods, 3 functions_

### Methods

| Slot | Name | Signature |
|---:|---|---|
| 16 | `New` | `()i` |
| 20 | `Delete` | `()i` |

### Functions

| Slot | Name | Signature |
|---:|---|---|
| 48 | `CreateScreen` | `()i` |
| 52 | `SetUpScreen` | `()i` |
| 56 | `ButtonHappiness` | `()i` |

## TScreen_Abilities

_0 fields, 2 methods, 3 functions_

### Methods

| Slot | Name | Signature |
|---:|---|---|
| 16 | `New` | `()i` |
| 20 | `Delete` | `()i` |

### Functions

| Slot | Name | Signature |
|---:|---|---|
| 48 | `CreateScreen` | `()i` |
| 52 | `SetUpScreen` | `()i` |
| 56 | `ButtonTraining` | `()i` |

## TScreen_Relationships

_0 fields, 2 methods, 6 functions_

### Methods

| Slot | Name | Signature |
|---:|---|---|
| 16 | `New` | `()i` |
| 20 | `Delete` | `()i` |

### Functions

| Slot | Name | Signature |
|---:|---|---|
| 48 | `CreateScreen` | `()i` |
| 52 | `SetUpScreen` | `(i)i` |
| 56 | `ButtonRelationship` | `()i` |
| 60 | `ButtonGirlEnd` | `()i` |
| 64 | `ButtonTeamCasino` | `()i` |
| 68 | `ButtonFriendsRacing` | `()i` |

## TScreen_Shop

_0 fields, 2 methods, 4 functions_

### Methods

| Slot | Name | Signature |
|---:|---|---|
| 16 | `New` | `()i` |
| 20 | `Delete` | `()i` |

### Functions

| Slot | Name | Signature |
|---:|---|---|
| 48 | `CreateScreen` | `()i` |
| 52 | `SetUpScreen` | `()i` |
| 56 | `ButtonBuy` | `()i` |
| 60 | `HidePanels` | `()i` |

## TScreen_BootShop

_0 fields, 2 methods, 4 functions_

### Methods

| Slot | Name | Signature |
|---:|---|---|
| 16 | `New` | `()i` |
| 20 | `Delete` | `()i` |

### Functions

| Slot | Name | Signature |
|---:|---|---|
| 48 | `CreateScreen` | `()i` |
| 52 | `SetUpScreen` | `()i` |
| 56 | `ButtonBuy` | `()i` |
| 60 | `ButtonPlay` | `()i` |

## TScreen_Leagues

_0 fields, 2 methods, 16 functions_

### Methods

| Slot | Name | Signature |
|---:|---|---|
| 16 | `New` | `()i` |
| 20 | `Delete` | `()i` |

### Functions

| Slot | Name | Signature |
|---:|---|---|
| 48 | `CreateScreen` | `()i` |
| 52 | `SetUpScreen` | `(i)i` |
| 56 | `ButtonQuit` | `()i` |
| 60 | `ComboContinent` | `()i` |
| 64 | `ComboNation` | `()i` |
| 68 | `ComboLeague` | `()i` |
| 72 | `ComboClub` | `()i` |
| 76 | `SetUpLeagueTable` | `()i` |
| 80 | `SetUpLeagueFixtures` | `(i)i` |
| 84 | `ButtonFixturesFirst` | `()i` |
| 88 | `ButtonFixturesLeft` | `()i` |
| 92 | `ButtonRound` | `()i` |
| 96 | `ButtonFixturesRight` | `()i` |
| 100 | `ButtonFixturesLast` | `()i` |
| 104 | `ButtonLevel` | `()i` |
| 108 | `RefreshComboColours` | `()i` |

## TScreen_Continents

_0 fields, 2 methods, 21 functions_

### Methods

| Slot | Name | Signature |
|---:|---|---|
| 16 | `New` | `()i` |
| 20 | `Delete` | `()i` |

### Functions

| Slot | Name | Signature |
|---:|---|---|
| 48 | `CreateScreen` | `()i` |
| 52 | `SetUpScreen` | `(i,i,i)i` |
| 56 | `ButtonQuit` | `()i` |
| 60 | `SelectLevel` | `(i)i` |
| 64 | `ComboContinent` | `()i` |
| 68 | `ComboCompetition` | `()i` |
| 72 | `ComboTeam` | `()i` |
| 76 | `SetUpFixturesTable` | `(i)i` |
| 80 | `ButtonFixturesFirst` | `()i` |
| 84 | `ButtonFixturesLeft` | `()i` |
| 88 | `ButtonRound` | `()i` |
| 92 | `ButtonFixturesRight` | `()i` |
| 96 | `ButtonFixturesLast` | `()i` |
| 100 | `SetUpLeagueTable` | `()i` |
| 104 | `ButtonGroupsFirst` | `()i` |
| 108 | `ButtonGroupsLeft` | `()i` |
| 112 | `ButtonGroup` | `()i` |
| 116 | `ButtonGroupsRight` | `()i` |
| 120 | `ButtonGroupsLast` | `()i` |
| 124 | `ButtonLevel` | `()i` |
| 128 | `RefreshComboColours` | `()i` |

## TScreen_Kits

_0 fields, 2 methods, 8 functions_

### Methods

| Slot | Name | Signature |
|---:|---|---|
| 16 | `New` | `()i` |
| 20 | `Delete` | `()i` |

### Functions

| Slot | Name | Signature |
|---:|---|---|
| 48 | `CreateScreen` | `()i` |
| 52 | `SetUpScreen` | `(:TFixture,()i,()i)i` |
| 56 | `ButtonChangeKits` | `()i` |
| 60 | `RefreshKits` | `()i` |
| 64 | `CreateKits` | `($)i` |
| 68 | `ButtonPlay` | `()i` |
| 72 | `Draw` | `()i` |
| 76 | `ButtonQuit` | `()i` |

## TScreen_MatchPaused

_0 fields, 2 methods, 7 functions_

### Methods

| Slot | Name | Signature |
|---:|---|---|
| 16 | `New` | `()i` |
| 20 | `Delete` | `()i` |

### Functions

| Slot | Name | Signature |
|---:|---|---|
| 48 | `CreateScreen` | `()i` |
| 52 | `SetUpScreen` | `(:TImage)i` |
| 56 | `ButtonContinue` | `()i` |
| 60 | `ButtonReplay` | `()i` |
| 64 | `ButtonTactics` | `()i` |
| 68 | `ButtonOptions` | `()i` |
| 72 | `ButtonSkipTime` | `()i` |

## TScreen_Formation

_0 fields, 2 methods, 12 functions_

### Methods

| Slot | Name | Signature |
|---:|---|---|
| 16 | `New` | `()i` |
| 20 | `Delete` | `()i` |

### Functions

| Slot | Name | Signature |
|---:|---|---|
| 48 | `CreateScreen` | `()i` |
| 52 | `SetUpScreen` | `(i)i` |
| 56 | `ButtonFormation` | `()i` |
| 60 | `RefreshButtons` | `()i` |
| 64 | `Draw` | `()i` |
| 68 | `CheckPosition` | `()i` |
| 72 | `ChangePosition` | `()i` |
| 76 | `CancelRequest` | `()i` |
| 80 | `AskBoss` | `()i` |
| 84 | `UpdatePosition` | `(i)i` |
| 88 | `ButtonPlay` | `()i` |
| 92 | `ButtonViewOpponent` | `()i` |

## TScreen_Stats

_0 fields, 2 methods, 7 functions_

### Methods

| Slot | Name | Signature |
|---:|---|---|
| 16 | `New` | `()i` |
| 20 | `Delete` | `()i` |

### Functions

| Slot | Name | Signature |
|---:|---|---|
| 48 | `CreateScreen` | `()i` |
| 52 | `SetUpScreen` | `()i` |
| 56 | `ComboClub` | `()i` |
| 60 | `UpdateStatTable` | `()i` |
| 64 | `UpdateHistoryTable` | `()i` |
| 68 | `ButtonMyHistory` | `()i` |
| 72 | `ButtonMyStats` | `()i` |

## TScreen_ContractOffer

_0 fields, 2 methods, 10 functions_

### Methods

| Slot | Name | Signature |
|---:|---|---|
| 16 | `New` | `()i` |
| 20 | `Delete` | `()i` |

### Functions

| Slot | Name | Signature |
|---:|---|---|
| 48 | `CreateScreen` | `()i` |
| 52 | `SetUpScreen` | `(:TContractOffer,()i,()i)i` |
| 56 | `UpdateCurrentContractDetails` | `()i` |
| 60 | `UpdateOfferDetails` | `(i,i)i` |
| 64 | `HideCurrentContract` | `()i` |
| 68 | `ShowCurrentContract` | `()i` |
| 72 | `HideNewContract` | `()i` |
| 76 | `ButtonReject` | `()i` |
| 80 | `ButtonNegotiate` | `()i` |
| 84 | `ButtonAccept` | `()i` |

## TScreen_MyContract

_0 fields, 2 methods, 16 functions_

### Methods

| Slot | Name | Signature |
|---:|---|---|
| 16 | `New` | `()i` |
| 20 | `Delete` | `()i` |

### Functions

| Slot | Name | Signature |
|---:|---|---|
| 48 | `CreateScreen` | `()i` |
| 52 | `SetUpScreen` | `()i` |
| 56 | `ButtonPlay` | `()i` |
| 60 | `UpdateClubsInterestedLabel` | `()i` |
| 64 | `UpdateClubsInterestedLabelForLoan` | `()i` |
| 68 | `UpdateTransferStatus` | `()i` |
| 72 | `UpdateDesiredCombos` | `()i` |
| 76 | `ButtonRequestTransfer` | `()i` |
| 80 | `ButtonRequestLoan` | `()i` |
| 84 | `ComboContinent` | `()i` |
| 88 | `ComboNation` | `()i` |
| 92 | `ComboDivision` | `()i` |
| 96 | `ComboClub` | `()i` |
| 100 | `ButtonRenewContract` | `()i` |
| 104 | `UpdateOfferButtons` | `()i` |
| 108 | `ButtonOffer` | `()i` |

## TScreen_Dilemma

_0 fields, 2 methods, 4 functions_

### Methods

| Slot | Name | Signature |
|---:|---|---|
| 16 | `New` | `()i` |
| 20 | `Delete` | `()i` |

### Functions

| Slot | Name | Signature |
|---:|---|---|
| 48 | `CreateScreen` | `()i` |
| 52 | `SetUpScreen` | `()i` |
| 56 | `ButtonRelationship` | `()i` |
| 60 | `Draw` | `()i` |

## TScreen_Finances

_0 fields, 2 methods, 3 functions_

### Methods

| Slot | Name | Signature |
|---:|---|---|
| 16 | `New` | `()i` |
| 20 | `Delete` | `()i` |

### Functions

| Slot | Name | Signature |
|---:|---|---|
| 48 | `CreateScreen` | `()i` |
| 52 | `SetUpScreen` | `()i` |
| 56 | `ButtonSell` | `()i` |

## TScreen_Newspaper

_0 fields, 2 methods, 4 functions_

### Methods

| Slot | Name | Signature |
|---:|---|---|
| 16 | `New` | `()i` |
| 20 | `Delete` | `()i` |

### Functions

| Slot | Name | Signature |
|---:|---|---|
| 48 | `CreateScreen` | `()i` |
| 52 | `SetUpScreen` | `()i` |
| 56 | `Play` | `()i` |
| 60 | `Draw` | `()i` |

## TScreen_Achievements

_0 fields, 2 methods, 2 functions_

### Methods

| Slot | Name | Signature |
|---:|---|---|
| 16 | `New` | `()i` |
| 20 | `Delete` | `()i` |

### Functions

| Slot | Name | Signature |
|---:|---|---|
| 48 | `CreateScreen` | `()i` |
| 52 | `SetUpScreen` | `()i` |

## TScreen_WorldMap

_0 fields, 2 methods, 7 functions_

### Methods

| Slot | Name | Signature |
|---:|---|---|
| 16 | `New` | `()i` |
| 20 | `Delete` | `()i` |

### Functions

| Slot | Name | Signature |
|---:|---|---|
| 48 | `CreateScreen` | `()i` |
| 52 | `SetUpScreen` | `()i` |
| 56 | `Draw` | `()i` |
| 60 | `ButtonGame` | `()i` |
| 64 | `ButtonMusic` | `()i` |
| 68 | `ButtonFilm` | `()i` |
| 72 | `UpdateTravelTime` | `()i` |

## TScreen_MatchPrep

_0 fields, 2 methods, 10 functions_

### Methods

| Slot | Name | Signature |
|---:|---|---|
| 16 | `New` | `()i` |
| 20 | `Delete` | `()i` |

### Functions

| Slot | Name | Signature |
|---:|---|---|
| 48 | `CreateScreen` | `()i` |
| 52 | `SetUpScreen` | `()i` |
| 56 | `ButtonDrugs` | `()i` |
| 60 | `ButtonNRG` | `()i` |
| 64 | `ButtonPainKillers` | `()i` |
| 68 | `ButtonBooze` | `()i` |
| 72 | `ButtonShinPads` | `()i` |
| 76 | `ButtonSkipMatch` | `()i` |
| 80 | `ButtonPlay` | `()i` |
| 84 | `NextFixture` | `(i)i` |

## TScreen_SeasonReview

_0 fields, 2 methods, 5 functions_

### Methods

| Slot | Name | Signature |
|---:|---|---|
| 16 | `New` | `()i` |
| 20 | `Delete` | `()i` |

### Functions

| Slot | Name | Signature |
|---:|---|---|
| 48 | `CreateScreen` | `()i` |
| 52 | `SetUpScreen` | `()i` |
| 56 | `UpdateSeasonStats` | `()i` |
| 60 | `UpdateSeasonTournaments` | `()i` |
| 64 | `ButtonPlay` | `()i` |

## TScreen_WebPage

_0 fields, 2 methods, 6 functions_

### Methods

| Slot | Name | Signature |
|---:|---|---|
| 16 | `New` | `()i` |
| 20 | `Delete` | `()i` |

### Functions

| Slot | Name | Signature |
|---:|---|---|
| 48 | `CreateScreen` | `()i` |
| 52 | `SetUpScreen` | `($,$)i` |
| 56 | `ButtonPlay` | `()i` |
| 60 | `ButtonTwitter` | `()i` |
| 64 | `ButtonFacebook` | `()i` |
| 68 | `GetSocialMessage` | `(i)$` |

## TScreen_ReportPhysio

_0 fields, 2 methods, 4 functions_

### Methods

| Slot | Name | Signature |
|---:|---|---|
| 16 | `New` | `()i` |
| 20 | `Delete` | `()i` |

### Functions

| Slot | Name | Signature |
|---:|---|---|
| 48 | `CreateScreen` | `()i` |
| 52 | `SetUpScreen` | `()i` |
| 56 | `ButtonPlay` | `()i` |
| 60 | `Draw` | `()i` |

## TScreen_ReportBoss

_0 fields, 2 methods, 4 functions_

### Methods

| Slot | Name | Signature |
|---:|---|---|
| 16 | `New` | `()i` |
| 20 | `Delete` | `()i` |

### Functions

| Slot | Name | Signature |
|---:|---|---|
| 48 | `CreateScreen` | `()i` |
| 52 | `SetUpScreen` | `()i` |
| 56 | `ButtonPlay` | `()i` |
| 60 | `Draw` | `()i` |

## TProfile

_134 fields, 75 methods, 5 functions_

### Fields - exact object layout

| Offset | Name | Type |
|---:|---|---|
| 8 | `gNetStatus` | `i` |
| 12 | `saveversion` | `$` |
| 16 | `date` | `:TMyDate` |
| 20 | `name` | `$` |
| 24 | `dbName` | `$` |
| 28 | `nationid` | `i` |
| 32 | `clubid` | `i` |
| 36 | `playercols` | `:TPlayerColours` |
| 40 | `bank` | `i` |
| 44 | `newstarselno` | `i` |
| 48 | `position` | `i` |
| 52 | `side` | `i` |
| 56 | `internationalselno` | `i` |
| 60 | `retired` | `i` |
| 64 | `careerstats` | `:TList` |
| 68 | `newsheadline` | `$` |
| 72 | `newsrating` | `i` |
| 76 | `newsmotm` | `i` |
| 80 | `webheadline` | `$` |
| 84 | `bossreport` | `$` |
| 88 | `physioreport` | `$` |
| 92 | `coachreport` | `$` |
| 96 | `coachrep_boss` | `i` |
| 100 | `coachrep_team` | `i` |
| 104 | `coachrep_fans` | `i` |
| 108 | `coachrep_sponsors` | `i` |
| 112 | `coachrep_fame` | `i` |
| 116 | `contractexpires` | `i` |
| 120 | `contractwage` | `i` |
| 124 | `contractgoalbonus` | `i` |
| 128 | `contractassistbonus` | `i` |
| 132 | `contractcleanbonus` | `i` |
| 136 | `lastweeksgoalbonus` | `i` |
| 140 | `lastweeksassistbonus` | `i` |
| 144 | `lastweekscleanbonus` | `i` |
| 148 | `thisweeksgoalbonus` | `i` |
| 152 | `thisweeksassistbonus` | `i` |
| 156 | `thisweekscleanbonus` | `i` |
| 160 | `lastweeksshirtsales` | `i` |
| 164 | `pace` | `i` |
| 168 | `shooting` | `i` |
| 172 | `passing` | `i` |
| 176 | `tackling` | `i` |
| 180 | `heading` | `i` |
| 184 | `dribbling` | `i` |
| 188 | `flair` | `i` |
| 192 | `interviewskill` | `i` |
| 196 | `crossing` | `i` |
| 200 | `freekicks` | `i` |
| 204 | `corners` | `i` |
| 208 | `positioning` | `i` |
| 212 | `shortpassing` | `i` |
| 216 | `longpassing` | `i` |
| 220 | `aggression` | `i` |
| 224 | `longshots` | `i` |
| 228 | `finishing` | `i` |
| 232 | `penalties` | `i` |
| 236 | `boots` | `[]i` |
| 240 | `items` | `[]i` |
| 244 | `vehicles` | `[]i` |
| 248 | `property` | `[]i` |
| 252 | `sponsor_amount` | `[]i` |
| 256 | `sponsor_expires` | `[]i` |
| 260 | `relationboss` | `i` |
| 264 | `relationteam` | `i` |
| 268 | `relationfans` | `i` |
| 272 | `relationfriends` | `i` |
| 276 | `relationgirlfriend` | `i` |
| 280 | `relationsponsors` | `i` |
| 284 | `relationfame` | `i` |
| 288 | `captain` | `i` |
| 292 | `girlscandalrating` | `i` |
| 296 | `lastspendtimefriends` | `i` |
| 300 | `lastspendtimegirlfriend` | `i` |
| 304 | `playbuttontype` | `i` |
| 308 | `transferlisted` | `i` |
| 312 | `desiredcontinentid` | `i` |
| 316 | `desirednationid` | `i` |
| 320 | `desiredleagueid` | `i` |
| 324 | `desiredclubid` | `i` |
| 328 | `onloanfrom` | `i` |
| 332 | `loanexpires` | `i` |
| 336 | `oldbossrel` | `i` |
| 340 | `oldteamrel` | `i` |
| 344 | `oldfansrel` | `i` |
| 348 | `energy` | `f` |
| 352 | `NRG` | `i` |
| 356 | `booze` | `i` |
| 360 | `gambling` | `i` |
| 364 | `injury` | `i` |
| 368 | `freetime` | `i` |
| 372 | `takenpainkillers` | `i` |
| 376 | `shinpads` | `i` |
| 380 | `boughtmusic` | `i` |
| 384 | `boughtgame` | `i` |
| 388 | `boughtfilm` | `i` |
| 392 | `drugs` | `i` |
| 396 | `currentyellowsclub` | `i` |
| 400 | `currentyellowscontinent` | `i` |
| 404 | `currentyellowsinternational` | `i` |
| 408 | `banclub` | `i` |
| 412 | `bancontinent` | `i` |
| 416 | `baninternational` | `i` |
| 420 | `interestedclubs` | `[]i` |
| 424 | `lasttransferdate` | `i` |
| 428 | `skillshash` | `$` |
| 432 | `passhash` | `$` |
| 436 | `premiumhash` | `$` |
| 440 | `lastconnecthash` | `$` |
| 444 | `achievements` | `[]i` |
| 448 | `history` | `:TList` |
| 452 | `tipcount` | `i` |
| 456 | `helppages` | `[]i` |
| 460 | `mynation` | `:TNation` |
| 464 | `myclub` | `:TClub` |
| 468 | `mylastfixture` | `:TFixture` |
| 472 | `selectedformatch` | `i` |
| 476 | `matchskipped` | `i` |
| 480 | `interviewchance` | `i` |
| 484 | `formationchanged` | `i` |
| 488 | `matchesleft` | `i` |
| 492 | `matcheswait` | `i` |
| 496 | `timecheck` | `i` |
| 500 | `temp_crossing` | `i` |
| 504 | `temp_freekicks` | `i` |
| 508 | `temp_corners` | `i` |
| 512 | `temp_positioning` | `i` |
| 516 | `temp_shortpassing` | `i` |
| 520 | `temp_longpassing` | `i` |
| 524 | `temp_aggression` | `i` |
| 528 | `temp_longshots` | `i` |
| 532 | `temp_finishing` | `i` |
| 536 | `temp_penalties` | `i` |
| 540 | `prematchsaved` | `i` |

### Methods

| Slot | Name | Signature |
|---:|---|---|
| 16 | `New` | `()i` |
| 20 | `Delete` | `()i` |
| 52 | `LoadProfile` | `(:TStream)i` |
| 56 | `SaveProfile` | `(:TStream)i` |
| 64 | `SaveGame` | `($)i` |
| 72 | `StartCareer` | `()i` |
| 76 | `CreateNewClubStats` | `(i)i` |
| 80 | `CreateNewInternationalStats` | `()i` |
| 84 | `Play` | `(i)i` |
| 88 | `GetNextFixture` | `(i):TFixture` |
| 92 | `GetNextOpponent` | `(*i,*i):TBase_Team` |
| 96 | `PlayNextFixture` | `(i)i` |
| 104 | `UpdateSelectedForMatch` | `(f)i` |
| 108 | `NextPlayButton` | `()i` |
| 112 | `SetPlayButtonIcon` | `()i` |
| 116 | `RandomIncident` | `()i` |
| 120 | `GetNewTip` | `()$` |
| 124 | `GetCurrentTip` | `()$` |
| 128 | `DoNews` | `($,:TBase_Team,:TBase_Team,i,i)$` |
| 132 | `GetStringContractExpires` | `()$` |
| 136 | `GetStat` | `(i,i,i,i)f` |
| 140 | `GetStringStat` | `(i,i,i,i,i)$` |
| 144 | `GetStats` | `(i,i,i):TList` |
| 148 | `GetCurrentStats` | `(i):TStats_Team` |
| 152 | `GetAverageForm` | `(i,i,i)f` |
| 156 | `GetLastMatchRating` | `(i)i` |
| 160 | `GetAge` | `()i` |
| 164 | `GetSkillRating` | `()i` |
| 168 | `UpdateAbility` | `(i,i)i` |
| 172 | `SetAbility` | `(i,i)i` |
| 176 | `CheckSkillHash` | `()i` |
| 180 | `WearBoots` | `()i` |
| 184 | `GetValue` | `()i` |
| 188 | `GetStatus` | `()f` |
| 192 | `UpdateRelationship` | `(i,i)i` |
| 196 | `GetHappiness` | `()i` |
| 200 | `GetSponsorshipAmount` | `()i` |
| 204 | `GetRentCosts` | `()i` |
| 208 | `GetPropertyCosts` | `()i` |
| 212 | `GetLastWeeksShirtSales` | `()i` |
| 216 | `GetVehicleCosts` | `()i` |
| 220 | `GetTotalSponsorship` | `()i` |
| 224 | `GetStringArraySponsor` | `(i)[]$` |
| 228 | `GetStringArrayItemsOwned` | `(i)[]$` |
| 232 | `GetStringArrayVehiclesOwned` | `(i)[]$` |
| 236 | `SellItemByName` | `($)i` |
| 240 | `GetStringArrayPropertyOwned` | `(i)[]$` |
| 244 | `GetLifestyle` | `()i` |
| 248 | `GetFame` | `()f` |
| 252 | `UpdateBank` | `(i)i` |
| 256 | `UpdateEnergy` | `(f)i` |
| 260 | `Bet` | `(i)i` |
| 264 | `UpdateFinances` | `()i` |
| 268 | `GetStableSize` | `()i` |
| 272 | `UpdateHealth` | `()i` |
| 276 | `DoInjury` | `()i` |
| 280 | `LoseRandomSkillPoint` | `(i)$` |
| 284 | `GetPropertyCount` | `()i` |
| 288 | `GotSponsor` | `()i` |
| 292 | `CheckSponsorExpiry` | `()i` |
| 296 | `OfferSponsorship` | `(i)i` |
| 300 | `BuyBoots` | `(i)i` |
| 304 | `GetPaceCap` | `()i` |
| 308 | `UpdateMyRatings` | `()i` |
| 312 | `ShowRatingChanges` | `()i` |
| 316 | `CheckLoanEnd` | `()i` |
| 320 | `GoOnLoan` | `(i)i` |
| 324 | `CancelLoan` | `()i` |
| 328 | `TooSoonSinceLastContract` | `()i` |
| 332 | `GetAchievements` | `()i` |
| 336 | `CheckAchievement` | `(i)i` |
| 340 | `CheckPurchaseAchievements` | `()i` |
| 344 | `ResetTutorial` | `(i)i` |
| 348 | `GetHashtaglessName` | `()$` |
| 352 | `GetOriginalName` | `()$` |

### Functions

| Slot | Name | Signature |
|---:|---|---|
| 48 | `SetUp` | `()i` |
| 60 | `LoadSavedGame` | `($)i` |
| 68 | `StartNewGame` | `()i` |
| 100 | `FixturePlayed` | `()i` |
| 356 | `DeleteCorruptKoreanData` | `()i` |

## TStats_Match

_9 fields, 9 methods, 1 functions_

### Fields - exact object layout

| Offset | Name | Type |
|---:|---|---|
| 8 | `list` | `:TList` |
| 12 | `yellows` | `i` |
| 16 | `reds` | `i` |
| 20 | `distance` | `f` |
| 24 | `lastdistancetime` | `i` |
| 28 | `subbedontime` | `i` |
| 32 | `subbedofftime` | `i` |
| 36 | `motm` | `i` |
| 40 | `rating` | `i` |

### Methods

| Slot | Name | Signature |
|---:|---|---|
| 16 | `New` | `()i` |
| 20 | `Delete` | `()i` |
| 48 | `Clear` | `()i` |
| 56 | `AddStat` | `(i,i,i,i,f,i)i` |
| 60 | `CountStat` | `(i)i` |
| 64 | `DrawPitch` | `(i,i)i` |
| 68 | `SortListBy` | `(i)i` |
| 72 | `UpdateRating` | `(i,i,i,i,i,i)i` |
| 76 | `GetPlayTime` | `(i)i` |

### Functions

| Slot | Name | Signature |
|---:|---|---|
| 52 | `Create` | `():TStats_Match` |

## TStat

_6 fields, 3 methods, 1 functions_

### Fields - exact object layout

| Offset | Name | Type |
|---:|---|---|
| 8 | `stype` | `i` |
| 12 | `minute` | `i` |
| 16 | `x` | `i` |
| 20 | `y` | `i` |
| 24 | `direction` | `f` |
| 28 | `distance` | `f` |

### Methods

| Slot | Name | Signature |
|---:|---|---|
| 16 | `New` | `()i` |
| 20 | `Delete` | `()i` |
| 28 | `Compare` | `(:Object)i` |

### Functions

| Slot | Name | Signature |
|---:|---|---|
| 48 | `Create` | `(i,i,i,i,f,f):TStat` |

## TStats_Team

_18 fields, 4 methods, 2 functions_

### Fields - exact object layout

| Offset | Name | Type |
|---:|---|---|
| 8 | `statlevel` | `i` |
| 12 | `teamid` | `i` |
| 16 | `year` | `i` |
| 20 | `appearances` | `i` |
| 24 | `subs` | `i` |
| 28 | `shots` | `i` |
| 32 | `goals` | `i` |
| 36 | `hattricks` | `i` |
| 40 | `passes` | `i` |
| 44 | `assists` | `i` |
| 48 | `headers` | `i` |
| 52 | `tackles` | `i` |
| 56 | `fouls` | `i` |
| 60 | `yellowcards` | `i` |
| 64 | `redcards` | `i` |
| 68 | `distance` | `i` |
| 72 | `manofthematch` | `i` |
| 76 | `form` | `[]i` |

### Methods

| Slot | Name | Signature |
|---:|---|---|
| 16 | `New` | `()i` |
| 20 | `Delete` | `()i` |
| 52 | `UpdateStats` | `(:TStats_Match)i` |
| 56 | `WriteData` | `(:TStream)i` |

### Functions

| Slot | Name | Signature |
|---:|---|---|
| 48 | `Create` | `(i,i,i):TStats_Team` |
| 60 | `CreateFromString` | `($):TStats_Team` |

## THistory

_6 fields, 3 methods, 2 functions_

### Fields - exact object layout

| Offset | Name | Type |
|---:|---|---|
| 8 | `year` | `i` |
| 12 | `clubid` | `i` |
| 16 | `nationid` | `i` |
| 20 | `text` | `$` |
| 24 | `compid` | `i` |
| 28 | `winner` | `i` |

### Methods

| Slot | Name | Signature |
|---:|---|---|
| 16 | `New` | `()i` |
| 20 | `Delete` | `()i` |
| 48 | `WriteData` | `(:TStream)i` |

### Functions

| Slot | Name | Signature |
|---:|---|---|
| 52 | `CreateFromString` | `($):THistory` |
| 56 | `Create` | `(i,i,i,$,i,i):THistory` |

## TParticle

_11 fields, 4 methods, 7 functions_

### Fields - exact object layout

| Offset | Name | Type |
|---:|---|---|
| 8 | `x` | `f` |
| 12 | `y` | `f` |
| 16 | `dir` | `f` |
| 20 | `vel` | `f` |
| 24 | `scale` | `f` |
| 28 | `alph` | `f` |
| 32 | `rot` | `f` |
| 36 | `grav` | `f` |
| 40 | `inflate` | `f` |
| 44 | `colour` | `$` |
| 48 | `txt` | `$` |

### Methods

| Slot | Name | Signature |
|---:|---|---|
| 16 | `New` | `()i` |
| 20 | `Delete` | `()i` |
| 68 | `Update` | `()i` |
| 76 | `Render` | `(f,f,f)i` |

### Functions

| Slot | Name | Signature |
|---:|---|---|
| 48 | `ClearAll` | `()i` |
| 52 | `SetUp` | `()i` |
| 56 | `StarShower` | `(i,i,$,$)i` |
| 60 | `CreateParticle` | `(f,f,f,f,f,f,f,f,f,$,$)i` |
| 64 | `UpdateParticlesAll` | `()i` |
| 72 | `RenderParticlesAll` | `(f,f,f)i` |
| 80 | `Count` | `()i` |

## TScreenMessage

_13 fields, 3 methods, 7 functions_

### Fields - exact object layout

| Offset | Name | Type |
|---:|---|---|
| 8 | `x` | `i` |
| 12 | `y` | `i` |
| 16 | `message` | `$` |
| 20 | `starttime` | `i` |
| 24 | `delaytime` | `i` |
| 28 | `finishtime` | `i` |
| 32 | `delaystart` | `i` |
| 36 | `alfa` | `f` |
| 40 | `bmfnt` | `:TBitmapFont` |
| 44 | `img` | `:TImage` |
| 48 | `imgScale` | `f` |
| 52 | `colour` | `$` |
| 56 | `lbl` | `:TLabel` |

### Methods

| Slot | Name | Signature |
|---:|---|---|
| 16 | `New` | `()i` |
| 20 | `Delete` | `()i` |
| 60 | `Draw` | `()i` |

### Functions

| Slot | Name | Signature |
|---:|---|---|
| 48 | `Create` | `(i,i,$,i,:TBitmapFont,:TImage,f,$)i` |
| 52 | `Count` | `()i` |
| 56 | `DrawAll` | `()i` |
| 64 | `ClearAll` | `(i)i` |
| 68 | `ClearAlerts` | `()i` |
| 72 | `CreateAlert` | `(i,i,$,i,$,$,:TImage,i,i,i,i,i)i` |
| 76 | `RemoveFirst` | `()i` |

## TBossMessage

_11 fields, 3 methods, 4 functions_

### Fields - exact object layout

| Offset | Name | Type |
|---:|---|---|
| 8 | `homeboss` | `i` |
| 12 | `x` | `f` |
| 16 | `y` | `f` |
| 20 | `message` | `$` |
| 24 | `starttime` | `i` |
| 28 | `delaytime` | `i` |
| 32 | `finishtime` | `i` |
| 36 | `delaystart` | `i` |
| 40 | `alfa` | `f` |
| 44 | `colour` | `$` |
| 48 | `flipit` | `i` |

### Methods

| Slot | Name | Signature |
|---:|---|---|
| 16 | `New` | `()i` |
| 20 | `Delete` | `()i` |
| 60 | `Draw` | `(f,f,f)i` |

### Functions

| Slot | Name | Signature |
|---:|---|---|
| 48 | `SetUp` | `()i` |
| 52 | `Create` | `(i,$,$)i` |
| 56 | `DrawAll` | `(f,f,f)i` |
| 64 | `ClearAll` | `()i` |

## TContractOffer

_9 fields, 6 methods, 14 functions_

### Fields - exact object layout

| Offset | Name | Type |
|---:|---|---|
| 8 | `club` | `:TClub` |
| 12 | `wage` | `i` |
| 16 | `length` | `i` |
| 20 | `goalbonus` | `i` |
| 24 | `assistbonus` | `i` |
| 28 | `cleanbonus` | `i` |
| 32 | `signingfee` | `i` |
| 36 | `newbossrel` | `i` |
| 40 | `negotiationsuccess` | `i` |

### Methods

| Slot | Name | Signature |
|---:|---|---|
| 16 | `New` | `()i` |
| 20 | `Delete` | `()i` |
| 64 | `DoNegotiation` | `()i` |
| 68 | `IncreaseOffer` | `(i)i` |
| 72 | `GetStringLength` | `()$` |
| 108 | `SignForNewClub` | `()i` |

### Functions

| Slot | Name | Signature |
|---:|---|---|
| 48 | `LoadData` | `(:TStream)i` |
| 52 | `WriteData` | `(:TStream)i` |
| 56 | `CreateContract` | `($)i` |
| 60 | `GetOffer` | `(:TClub):TContractOffer` |
| 76 | `EraseInterestedClubs` | `()i` |
| 80 | `TransferWindowOpen` | `()i` |
| 84 | `CheckTransferWindow` | `()i` |
| 88 | `GetInitialClub` | `(i):TClub` |
| 92 | `UpdateInterestedClubs` | `()i` |
| 96 | `GetClubsInterestedInLoan` | `():TList` |
| 100 | `GetPlayerValueStatus` | `()i` |
| 104 | `CheckClubCanAffordPlayer` | `(:TClub)i` |
| 112 | `CheckPromoteFromBTeam` | `()i` |
| 116 | `DoTransferRumour` | `()i` |

## TScreen_Casino

_0 fields, 2 methods, 11 functions_

### Methods

| Slot | Name | Signature |
|---:|---|---|
| 16 | `New` | `()i` |
| 20 | `Delete` | `()i` |

### Functions

| Slot | Name | Signature |
|---:|---|---|
| 48 | `CreateScreen` | `()i` |
| 52 | `UpdateStakeCurrency` | `()i` |
| 56 | `SetUpScreen` | `()i` |
| 60 | `SetStake` | `()i` |
| 64 | `GetChipImage` | `(i):TImage` |
| 68 | `ButtonBlackJack` | `()i` |
| 72 | `ButtonRoulette` | `()i` |
| 76 | `ButtonSlots` | `()i` |
| 80 | `ShowTitleButtons` | `()i` |
| 84 | `HideTitleButtons` | `()i` |
| 88 | `ButtonRelationships` | `()i` |

## TScreen_Roulette

_0 fields, 2 methods, 8 functions_

### Methods

| Slot | Name | Signature |
|---:|---|---|
| 16 | `New` | `()i` |
| 20 | `Delete` | `()i` |

### Functions

| Slot | Name | Signature |
|---:|---|---|
| 48 | `CreateScreen` | `()i` |
| 52 | `SetUpScreen` | `(i)i` |
| 56 | `ButtonPlay` | `()i` |
| 60 | `PlaceBet` | `()i` |
| 64 | `IncreaseBet` | `(*i)i` |
| 68 | `ClearBets` | `()i` |
| 72 | `UpdateBetLabels` | `()i` |
| 76 | `GetBetTotal` | `()i` |

## TRoulette

_0 fields, 2 methods, 5 functions_

### Methods

| Slot | Name | Signature |
|---:|---|---|
| 16 | `New` | `()i` |
| 20 | `Delete` | `()i` |

### Functions

| Slot | Name | Signature |
|---:|---|---|
| 48 | `SetUp` | `()i` |
| 52 | `Spin` | `()i` |
| 56 | `Update` | `()i` |
| 60 | `Draw` | `()i` |
| 64 | `GetResult` | `()i` |

## TRouletteWheel

_7 fields, 5 methods, 2 functions_

### Fields - exact object layout

| Offset | Name | Type |
|---:|---|---|
| 8 | `iWheelSize` | `i` |
| 12 | `iRimSize` | `i` |
| 16 | `fX` | `f` |
| 20 | `fY` | `f` |
| 24 | `fRot` | `f` |
| 28 | `oldfRot` | `f` |
| 32 | `fSpeed` | `f` |

### Methods

| Slot | Name | Signature |
|---:|---|---|
| 16 | `New` | `()i` |
| 20 | `Delete` | `()i` |
| 52 | `Reset` | `()i` |
| 56 | `Update` | `()i` |
| 60 | `Draw` | `(f)i` |

### Functions

| Slot | Name | Signature |
|---:|---|---|
| 48 | `Create` | `():TRouletteWheel` |
| 64 | `GetColour` | `(i)i` |

## TRouletteBall

_10 fields, 5 methods, 1 functions_

### Fields - exact object layout

| Offset | Name | Type |
|---:|---|---|
| 8 | `fLineRot` | `f` |
| 12 | `fSpeed` | `f` |
| 16 | `fDist` | `f` |
| 20 | `fVel` | `f` |
| 24 | `fX` | `f` |
| 28 | `fY` | `f` |
| 32 | `oldfX` | `f` |
| 36 | `oldfY` | `f` |
| 40 | `fPocket` | `f` |
| 44 | `bStopped` | `i` |

### Methods

| Slot | Name | Signature |
|---:|---|---|
| 16 | `New` | `()i` |
| 20 | `Delete` | `()i` |
| 52 | `Reset` | `(:TRouletteWheel)i` |
| 56 | `Update` | `(:TRouletteWheel)i` |
| 60 | `Draw` | `(f)i` |

### Functions

| Slot | Name | Signature |
|---:|---|---|
| 48 | `Create` | `():TRouletteBall` |

## TScreen_BlackJack

_0 fields, 2 methods, 8 functions_

### Methods

| Slot | Name | Signature |
|---:|---|---|
| 16 | `New` | `()i` |
| 20 | `Delete` | `()i` |

### Functions

| Slot | Name | Signature |
|---:|---|---|
| 48 | `CreateScreen` | `()i` |
| 52 | `SetUpScreen` | `()i` |
| 56 | `ButtonPlay` | `()i` |
| 60 | `ButtonQuit` | `()i` |
| 64 | `UpdateScoreLabels` | `()i` |
| 68 | `Win` | `()i` |
| 72 | `Tie` | `()i` |
| 76 | `Lose` | `()i` |

## TBlackJack

_0 fields, 2 methods, 13 functions_

### Methods

| Slot | Name | Signature |
|---:|---|---|
| 16 | `New` | `()i` |
| 20 | `Delete` | `()i` |

### Functions

| Slot | Name | Signature |
|---:|---|---|
| 48 | `SetUp` | `()i` |
| 52 | `Update` | `()i` |
| 56 | `Reset` | `()i` |
| 60 | `Deal` | `()i` |
| 64 | `Play` | `()i` |
| 68 | `CheckPlayerScore` | `()i` |
| 72 | `DealersTurn` | `()i` |
| 76 | `Hit` | `(:TList)i` |
| 80 | `Hold` | `()i` |
| 84 | `Draw` | `()i` |
| 88 | `GetDealerScore` | `(*i,*i)i` |
| 92 | `GetPlayerScore` | `(*i,*i)i` |
| 96 | `ShowResult` | `()i` |

## TCard

_4 fields, 3 methods, 4 functions_

### Fields - exact object layout

| Offset | Name | Type |
|---:|---|---|
| 8 | `img` | `:TImage` |
| 12 | `randno` | `i` |
| 16 | `num` | `i` |
| 20 | `suit` | `$` |

### Methods

| Slot | Name | Signature |
|---:|---|---|
| 16 | `New` | `()i` |
| 20 | `Delete` | `()i` |
| 28 | `Compare` | `(:Object)i` |

### Functions

| Slot | Name | Signature |
|---:|---|---|
| 48 | `SetUp` | `()i` |
| 52 | `CreateCard` | `(i,$):TCard` |
| 56 | `Shuffle` | `()i` |
| 60 | `Pull` | `():TCard` |

## TScreen_Slots

_0 fields, 2 methods, 3 functions_

### Methods

| Slot | Name | Signature |
|---:|---|---|
| 16 | `New` | `()i` |
| 20 | `Delete` | `()i` |

### Functions

| Slot | Name | Signature |
|---:|---|---|
| 48 | `CreateScreen` | `()i` |
| 52 | `SetUpScreen` | `()i` |
| 56 | `ButtonPlay` | `()i` |

## TSlotMachine

_0 fields, 2 methods, 6 functions_

### Methods

| Slot | Name | Signature |
|---:|---|---|
| 16 | `New` | `()i` |
| 20 | `Delete` | `()i` |

### Functions

| Slot | Name | Signature |
|---:|---|---|
| 48 | `SetUp` | `()i` |
| 52 | `Reset` | `()i` |
| 56 | `Update` | `()i` |
| 60 | `Draw` | `()i` |
| 64 | `Spin` | `()i` |
| 68 | `DoPrize` | `()i` |

## TSlotStrip

_10 fields, 6 methods, 0 functions_

### Fields - exact object layout

| Offset | Name | Type |
|---:|---|---|
| 8 | `reelH` | `i` |
| 12 | `fruitCount` | `i` |
| 16 | `xPos` | `i` |
| 20 | `yPos1` | `f` |
| 24 | `yPos2` | `f` |
| 28 | `yVel` | `f` |
| 32 | `spintime` | `i` |
| 36 | `spinlength` | `i` |
| 40 | `reelstopped` | `i` |
| 44 | `fruit` | `i` |

### Methods

| Slot | Name | Signature |
|---:|---|---|
| 16 | `New` | `()i` |
| 20 | `Delete` | `()i` |
| 48 | `SetUp` | `(i,i)i` |
| 52 | `Update` | `()i` |
| 56 | `Spin` | `(i)i` |
| 60 | `Draw` | `()i` |

## TScreen_Pairs

_0 fields, 2 methods, 11 functions_

### Methods

| Slot | Name | Signature |
|---:|---|---|
| 16 | `New` | `()i` |
| 20 | `Delete` | `()i` |

### Functions

| Slot | Name | Signature |
|---:|---|---|
| 48 | `CreateScreen` | `()i` |
| 52 | `SetUpScreen` | `(i)i` |
| 56 | `ResetButtonPositions` | `()i` |
| 60 | `NewButtonPositions` | `()i` |
| 64 | `ClickCard` | `()i` |
| 68 | `UpdateFaces` | `()i` |
| 72 | `Update` | `()i` |
| 76 | `DisableAll` | `()i` |
| 80 | `EnableAll` | `()i` |
| 84 | `Success` | `(i)i` |
| 88 | `Fail` | `()i` |

## TPair_Icon

_6 fields, 3 methods, 2 functions_

### Fields - exact object layout

| Offset | Name | Type |
|---:|---|---|
| 8 | `id` | `i` |
| 12 | `imgId` | `i` |
| 16 | `randno` | `i` |
| 20 | `back` | `:TImage` |
| 24 | `front` | `:TImage` |
| 28 | `picked` | `i` |

### Methods

| Slot | Name | Signature |
|---:|---|---|
| 16 | `New` | `()i` |
| 20 | `Delete` | `()i` |
| 28 | `Compare` | `(:Object)i` |

### Functions

| Slot | Name | Signature |
|---:|---|---|
| 48 | `CreateAll` | `()i` |
| 52 | `SetUp` | `(i)i` |

## TButtonPos

_3 fields, 3 methods, 1 functions_

### Fields - exact object layout

| Offset | Name | Type |
|---:|---|---|
| 8 | `randno` | `i` |
| 12 | `x` | `f` |
| 16 | `y` | `f` |

### Methods

| Slot | Name | Signature |
|---:|---|---|
| 16 | `New` | `()i` |
| 20 | `Delete` | `()i` |
| 28 | `Compare` | `(:Object)i` |

### Functions

| Slot | Name | Signature |
|---:|---|---|
| 48 | `Create` | `(f,f):TButtonPos` |

## TScreen_Negotiate

_0 fields, 2 methods, 10 functions_

### Methods

| Slot | Name | Signature |
|---:|---|---|
| 16 | `New` | `()i` |
| 20 | `Delete` | `()i` |

### Functions

| Slot | Name | Signature |
|---:|---|---|
| 48 | `CreateScreen` | `()i` |
| 52 | `SetUpScreen` | `(:TContractOffer)i` |
| 56 | `ButtonLower` | `()i` |
| 60 | `ButtonHigher` | `()i` |
| 64 | `Update` | `()i` |
| 68 | `Success` | `()i` |
| 72 | `Fail` | `()i` |
| 76 | `UpdateInstrucs` | `()i` |
| 80 | `ButtonOk` | `()i` |
| 84 | `ButtonAccept` | `()i` |

## TScreen_Interview

_0 fields, 2 methods, 9 functions_

### Methods

| Slot | Name | Signature |
|---:|---|---|
| 16 | `New` | `()i` |
| 20 | `Delete` | `()i` |

### Functions

| Slot | Name | Signature |
|---:|---|---|
| 48 | `CreateScreen` | `()i` |
| 52 | `SetUpScreen` | `()i` |
| 56 | `ButtonAddText` | `()i` |
| 60 | `EnableAllButtons` | `()i` |
| 64 | `DisableAllButtons` | `()i` |
| 68 | `Update` | `()i` |
| 72 | `Success` | `()i` |
| 76 | `Fail` | `()i` |
| 80 | `ButtonOk` | `()i` |

## TTraining

_0 fields, 2 methods, 37 functions_

### Methods

| Slot | Name | Signature |
|---:|---|---|
| 16 | `New` | `()i` |
| 20 | `Delete` | `()i` |

### Functions

| Slot | Name | Signature |
|---:|---|---|
| 48 | `SetUpTraining` | `(i)i` |
| 52 | `IsPlayerNeededForTraining` | `(i,i)i` |
| 56 | `SetUpTraining_Pace` | `()i` |
| 60 | `SetUpTraining_Dribbling` | `()i` |
| 64 | `SetUpTraining_Passing` | `()i` |
| 68 | `SetUpTraining_Shooting` | `()i` |
| 72 | `SetUpTraining_Heading` | `()i` |
| 76 | `SetUpTraining_Flair` | `()i` |
| 80 | `SetUpTraining_Tackling` | `()i` |
| 84 | `StartChallenge` | `()i` |
| 88 | `Update` | `()i` |
| 92 | `UpdateSounds` | `()i` |
| 96 | `UpdatePace` | `()i` |
| 100 | `UpdateDribbling` | `()i` |
| 104 | `UpdateFlair` | `()i` |
| 108 | `UpdateTackling1` | `()i` |
| 112 | `UpdateTackling2` | `()i` |
| 116 | `UpdatePassing` | `()i` |
| 120 | `UpdateHeading1` | `()i` |
| 124 | `UpdateHeading2` | `()i` |
| 128 | `UpdateShooting1` | `()i` |
| 132 | `UpdateShooting2` | `()i` |
| 136 | `Render` | `()i` |
| 140 | `RenderScoreboard` | `(f)i` |
| 144 | `TimeUp` | `()i` |
| 148 | `Fail` | `()i` |
| 152 | `Success` | `()i` |
| 156 | `ClearUpTraining` | `()i` |
| 160 | `CanCallForBall` | `()i` |
| 164 | `Call` | `(:TPlayer)i` |
| 168 | `GetFocus` | `(:TPlayer,*f,*f)i` |
| 172 | `GoalScored` | `(:TBall)i` |
| 176 | `GetMatchState` | `(*i,*i,*i)i` |
| 180 | `ResetTraining` | `()i` |
| 184 | `PlayerCanMove` | `(:TPlayer)i` |
| 188 | `TrainingSetPiece` | `(:TPlayer)i` |
| 192 | `GetPiggyInTheMiddlePosition` | `(:TTeam)i` |

## TTrainingObject

_7 fields, 5 methods, 3 functions_

### Fields - exact object layout

| Offset | Name | Type |
|---:|---|---|
| 8 | `img` | `:TImage` |
| 12 | `frame` | `i` |
| 16 | `x` | `f` |
| 20 | `y` | `f` |
| 24 | `alive` | `i` |
| 28 | `alph` | `f` |
| 32 | `scl` | `f` |

### Methods

| Slot | Name | Signature |
|---:|---|---|
| 16 | `New` | `()i` |
| 20 | `Delete` | `()i` |
| 56 | `Update` | `()i` |
| 60 | `Render` | `()i` |
| 68 | `Clear` | `()i` |

### Functions

| Slot | Name | Signature |
|---:|---|---|
| 48 | `UpdateAll` | `()i` |
| 52 | `RenderAll` | `()i` |
| 64 | `ClearAll` | `()i` |

## TCone

_1 fields, 6 methods, 1 functions_

### Fields - exact object layout

| Offset | Name | Type |
|---:|---|---|
| 36 | `fallen` | `i` |

### Methods

| Slot | Name | Signature |
|---:|---|---|
| 16 | `New` | `()i` |
| 20 | `Delete` | `()i` |
| 56 | `Update` | `()i` |
| 76 | `CheckKnockOver` | `()i` |
| 68 | `Clear` | `()i` |
| 60 | `Render` | `()i` |

### Functions

| Slot | Name | Signature |
|---:|---|---|
| 72 | `Create` | `(i,i,i)i` |

## TDummy

_0 fields, 6 methods, 3 functions_

### Methods

| Slot | Name | Signature |
|---:|---|---|
| 16 | `New` | `()i` |
| 20 | `Delete` | `()i` |
| 56 | `Update` | `()i` |
| 80 | `CheckHit` | `()i` |
| 60 | `Render` | `()i` |
| 68 | `Clear` | `()i` |

### Functions

| Slot | Name | Signature |
|---:|---|---|
| 72 | `Create` | `(i,i)i` |
| 76 | `ResetDummies` | `()i` |
| 84 | `UpdateWallLocations` | `(i,i)i` |

## TPole

_2 fields, 6 methods, 1 functions_

### Fields - exact object layout

| Offset | Name | Type |
|---:|---|---|
| 36 | `colour` | `$` |
| 40 | `wobbling` | `i` |

### Methods

| Slot | Name | Signature |
|---:|---|---|
| 16 | `New` | `()i` |
| 20 | `Delete` | `()i` |
| 56 | `Update` | `()i` |
| 76 | `CheckHit` | `()i` |
| 60 | `Render` | `()i` |
| 68 | `Clear` | `()i` |

### Functions

| Slot | Name | Signature |
|---:|---|---|
| 72 | `Create` | `(i,i,$)i` |

## TTrainingZone

_2 fields, 5 methods, 1 functions_

### Fields - exact object layout

| Offset | Name | Type |
|---:|---|---|
| 36 | `colour` | `$` |
| 40 | `txt` | `$` |

### Methods

| Slot | Name | Signature |
|---:|---|---|
| 16 | `New` | `()i` |
| 20 | `Delete` | `()i` |
| 68 | `Clear` | `()i` |
| 56 | `Update` | `()i` |
| 60 | `Render` | `()i` |

### Functions

| Slot | Name | Signature |
|---:|---|---|
| 72 | `Create` | `(i,i,f,$,$):TTrainingZone` |

## TTrainingLine

_3 fields, 7 methods, 2 functions_

### Fields - exact object layout

| Offset | Name | Type |
|---:|---|---|
| 36 | `colour` | `$` |
| 40 | `x2` | `i` |
| 44 | `y2` | `i` |

### Methods

| Slot | Name | Signature |
|---:|---|---|
| 16 | `New` | `()i` |
| 20 | `Delete` | `()i` |
| 68 | `Clear` | `()i` |
| 56 | `Update` | `()i` |
| 60 | `Render` | `()i` |
| 76 | `CheckSplit` | `()i` |
| 84 | `KillMe` | `()i` |

### Functions

| Slot | Name | Signature |
|---:|---|---|
| 72 | `Create` | `(i,i,i,i,$):TTrainingLine` |
| 80 | `ActivateNextLine` | `()i` |

## TTarget

_0 fields, 6 methods, 1 functions_

### Methods

| Slot | Name | Signature |
|---:|---|---|
| 16 | `New` | `()i` |
| 20 | `Delete` | `()i` |
| 56 | `Update` | `()i` |
| 76 | `CheckHit` | `()i` |
| 60 | `Render` | `()i` |
| 68 | `Clear` | `()i` |

### Functions

| Slot | Name | Signature |
|---:|---|---|
| 72 | `Create` | `(i,i)i` |

## TPanel_Controls

_0 fields, 2 methods, 6 functions_

### Methods

| Slot | Name | Signature |
|---:|---|---|
| 16 | `New` | `()i` |
| 20 | `Delete` | `()i` |

### Functions

| Slot | Name | Signature |
|---:|---|---|
| 48 | `SetUp` | `()i` |
| 52 | `RenderTraining` | `(f,f)i` |
| 56 | `RenderReplay` | `(i,i)i` |
| 60 | `RenderPauseReplay` | `(i,i)i` |
| 64 | `RenderPauseSkipTime` | `(i,i)i` |
| 68 | `RenderKickToContinue` | `()i` |

## TScreen_Stable

_0 fields, 2 methods, 23 functions_

### Methods

| Slot | Name | Signature |
|---:|---|---|
| 16 | `New` | `()i` |
| 20 | `Delete` | `()i` |

### Functions

| Slot | Name | Signature |
|---:|---|---|
| 48 | `CreateScreen` | `()i` |
| 52 | `SetUpScreen` | `(i)i` |
| 56 | `LoadData` | `(:TStream)i` |
| 60 | `WriteData` | `(:TStream)i` |
| 64 | `SetUpHorsesForSale` | `()i` |
| 68 | `ButtonQuit` | `()i` |
| 72 | `ButtonStable` | `()i` |
| 76 | `ButtonRace` | `()i` |
| 80 | `SetUpNextRace` | `()i` |
| 84 | `SetStake` | `()i` |
| 88 | `ButtonHorse` | `()i` |
| 92 | `RefreshRunners` | `(i)i` |
| 96 | `DoRace` | `()i` |
| 100 | `Update` | `()i` |
| 104 | `Draw` | `()i` |
| 108 | `FinishRace` | `()i` |
| 112 | `RefreshTableForSale` | `()i` |
| 116 | `ButtonBuyHorse` | `()i` |
| 120 | `RefreshTableOwned` | `()i` |
| 124 | `GetSelectedHorse` | `($):THorse` |
| 128 | `ButtonSellHorse` | `()i` |
| 132 | `ButtonTreatHorse` | `()i` |
| 136 | `ButtonRaceHorse` | `()i` |

## THorse

_27 fields, 12 methods, 11 functions_

### Fields - exact object layout

| Offset | Name | Type |
|---:|---|---|
| 8 | `image` | `:TImage` |
| 12 | `img_myjockey` | `:TImage` |
| 16 | `framecounter` | `i` |
| 20 | `frame` | `i` |
| 24 | `x` | `f` |
| 28 | `y` | `f` |
| 32 | `oldx` | `f` |
| 36 | `oldy` | `f` |
| 40 | `xvel` | `f` |
| 44 | `yvel` | `f` |
| 48 | `randno` | `i` |
| 52 | `id` | `i` |
| 56 | `name` | `$` |
| 60 | `energy` | `f` |
| 64 | `health` | `f` |
| 68 | `strength` | `f` |
| 72 | `form` | `[]i` |
| 76 | `prize` | `i` |
| 80 | `owned` | `i` |
| 84 | `lastran` | `i` |
| 88 | `colour` | `i` |
| 92 | `raceposition` | `i` |
| 96 | `racenum` | `i` |
| 100 | `betamount` | `i` |
| 104 | `betprice` | `i` |
| 108 | `betwinnings` | `i` |
| 112 | `textpos` | `f` |

### Methods

| Slot | Name | Signature |
|---:|---|---|
| 16 | `New` | `()i` |
| 20 | `Delete` | `()i` |
| 56 | `GetStringEnergy` | `()$` |
| 60 | `GetStringHealth` | `()$` |
| 64 | `GetStringForm` | `()$` |
| 68 | `GetValue` | `()i` |
| 72 | `GetStringPrice` | `()$` |
| 76 | `GetStringracenum` | `()$` |
| 84 | `Update` | `()i` |
| 92 | `Render` | `(f,f,f)i` |
| 100 | `PostRaceUpdate` | `(i)i` |
| 28 | `Compare` | `(:Object)i` |

### Functions

| Slot | Name | Signature |
|---:|---|---|
| 48 | `Create` | `(i,$,f,f,f,[]i,i,i,i,i):THorse` |
| 52 | `GetHorseByName` | `($):THorse` |
| 80 | `UpdateAllRunners` | `()i` |
| 88 | `RenderAllRunners` | `(f,f,f)i` |
| 96 | `GetLeadingHorse` | `():THorse` |
| 104 | `SelectRunners` | `(i)i` |
| 108 | `SetRaceOdds` | `()i` |
| 112 | `ResetRands` | `()i` |
| 116 | `GetHorseColour` | `(i)$` |
| 120 | `CountHorsesOwned` | `()i` |
| 124 | `DoHealthUpdate` | `()i` |

## TAchievement

_3 fields, 3 methods, 2 functions_

### Fields - exact object layout

| Offset | Name | Type |
|---:|---|---|
| 8 | `id` | `i` |
| 12 | `index` | `i` |
| 16 | `txt` | `$` |

### Methods

| Slot | Name | Signature |
|---:|---|---|
| 16 | `New` | `()i` |
| 20 | `Delete` | `()i` |
| 28 | `Compare` | `(:Object)i` |

### Functions

| Slot | Name | Signature |
|---:|---|---|
| 48 | `LoadData` | `(:TStream)i` |
| 52 | `WriteData` | `(:TStream)i` |
