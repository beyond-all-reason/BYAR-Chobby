local scenariodata = {
	index			= 10, --  integer, sort order, MUST BE EQUAL TO FILENAME NUMBER
	scenarioid		= "damgamsscenariotestplayground01", -- no spaces, lowercase, this will be used to save the score and can be used gadget side
    version         = "1", -- increment this to reset the score when changing a mission, as scores are keyed by (scenarioid,version,difficulty)
	title			= "Damgam's Scenario Test Playground 01", -- can be anything
	
	author			= "Damgam", -- your name here
	imagepath		= "scriptedscenariotest1.jpg", -- placed next to lua file, should be 3:1 ratio banner style
	imageflavor		= "Totally Unplayable, I rate it 1/10.", -- This text will be drawn over image
    summary         = [[Short Description]],
	briefing 		= [[Long Description]],

	mapfilename		= "comet_catcher_remake_1.8", -- the name of the map to be displayed here, and which to play on, no .smf ending needed
	playerstartx	= "10%", -- X position of where player comm icon should be drawn, from top left of the map
	playerstarty	= "50%", -- Y position of where player comm icon should be drawn, from top left of the map
	partime 		= 3000, -- par time in seconds (time a mission is expected to take on average)
	parresources	= 1000000, -- par resource amount (amount of metal one is expected to spend on mission)
	difficulty		= 1, -- Percieved difficulty at 'normal' level: integer 1-10
    defaultdifficulty = "Normal", -- an entry of the difficulty table
    difficulties    = { -- Array for sortedness, Keys are text that appears in selector (as well as in scoring!), values are handicap levels
    -- handicap values range [-100 - +100], with 0 being regular resources
    -- Currently difficulty modifier only affects the resource bonuses
        {name = "Beginner", playerhandicap = 50, enemyhandicap=-50},
        {name = "Novice"  , playerhandicap = 25, enemyhandicap=-25},
        {name = "Normal"  , playerhandicap = 0, enemyhandicap=0},
        {name = "Hard"    , playerhandicap = 0,  enemyhandicap=50},
        {name = "Brutal" , playerhandicap = 0,  enemyhandicap=100},
    },
    allowedsides     = {"Armada"}, --these are the permitted factions for this mission, ch0ose from {"Armada", "Cortex", "Random"}
	victorycondition= "Kill the Cortex Commander", -- This is plaintext, but should be reflected in startscript
	losscondition	= "Death of your Commander",  -- This is plaintext, but should be reflected in startscript
    unitlimits   = { -- table of unitdefname : maxnumberofthese units, 0 means disable it
        -- dont use the one in startscript, put the disabled stuff here so we can show it in scenario window!
        --armavp = 0,
        --coravp = 0,
    } ,

    scenariooptions = { -- this will get lua->json->base64 and passed to scenariooptions in game
        myoption = "dostuff", -- blank
        scenarioid = "damgamsscenariotestplayground01", -- this MUST be present and identical to the one defined at start
		disablefactionpicker = true, -- this is needed to prevent faction picking outside of the allowedsides

        unitloadout = { 
			-- You can specify units that you wish to spawn here, they only show up once game starts,
			-- You can create these lists easily using the feature/unit dumper by using dbg_feature_dumper.lua widget pinned to the #challenges channel on discord
			-- Set up a skirmish like your scenario, so the team ID's will be correct
			-- Then using /globallos and cheats, add as many units as you wish 
			-- The type /luaui dumpunits
			-- Fish out the dumped units from your infolog.txt and add them here
			-- Note: If you have ANY units in loadout, then there will be no initial units spawned for anyone, so you have to take care of that
			-- so you must spawn the initial commanders then!

			
			--{name = 'corcom', x = 6930, y = 534, z = 7623, rot = -7963 , team = 0},
			
		},
		featureloadout = {
			-- Similarly to units, but these can also be resurrectable!
            -- You can /give corcom_dead with cheats when making your scenario, but it might not contain the 'resurrectas' tag, so be careful to add it if needed
			 -- {name = 'corcom_dead', x = 1125,y = 237, z = 734, rot = "0" , scale = 1.0, resurrectas = "corcom"}, -- there is no need for this dead comm here, just an example
            -- {name = 'armack_dead',  x = 1320,  y = 89,  z = 460,  rot = -928 , resurrectas = 'armack',  team = 0},

		}
    },
    -- Full Documentation for start script here: 
    -- https://github.com/spring/spring/blob/105.0/doc/StartScriptFormat.txt

    -- HOW TO MAKE THE START SCRIPT: Use Chobby's single player mode to set up your start script. When you launch a single player game, the start script is dumped into infolog.txt
    -- ModOptions: You can also set modoptions in chobby, and they will get dumped into the infolog's start script too, or just set then in chobby and copy paste them into the [modoptions] tag. as below
    -- The following keys MUST be present in startscript below 
    --  scenariooptions = __SCENARIOOPTIONS__; 
    -- Name = __PLAYERNAME__;
    -- myplayername = __PLAYERNAME__;
    -- gametype = __BARVERSION__;
    -- mapname =__MAPNAME__;

    -- Optional keys: 
    -- __ENEMYHANDICAP__
    -- __PLAYERSIDE__
    -- __PLAYERHANDICAP__
    -- __NUMRESTRICTIONS__
    -- __RESTRICTEDUNITS__

	startscript		= [[[GAME]
{
	[allyTeam0]
	{
		numallies = 0;
	}

	[team1]
	{
		Side = Cortex;
        Handicap = __ENEMYHANDICAP__;
		RgbColor = 0.3758504 0.75682863 0.91179775;
		AllyTeam = 1;
		TeamLeader = 0;
        StartPosX = 1000;
        StartPosZ = 1000;
	}

	[team0]
	{
        Side = __PLAYERSIDE__;
		Handicap = __PLAYERHANDICAP__;
		RgbColor = 0.79311622 0.1523652 0.04604363;
		AllyTeam = 0;
		TeamLeader = 0;
        StartPosX = 7000;
        StartPosZ = 7000;
	}

	[modoptions]
	{
        scenariooptions = __SCENARIOOPTIONS__;
        ruins = enabled;
	}

	[allyTeam1]
	{
		numallies = 0;
	}

	[ai0]
	{
		Host = 0;
		IsFromDemo = 0;
		Name = Enemy;
		ShortName = BARb;
		Team = 1;
        Version = stable;
	}

	[player0]
	{
		IsFromDemo = 0;
        Name = __PLAYERNAME__;
		Team = 0;
		rank = 0;
	}

	NumRestrictions=__NUMRESTRICTIONS__;

	[RESTRICT]
	{
        __RESTRICTEDUNITS__
	}

	hostip = 127.0.0.1;
	hostport = 0;
	numplayers = 1;
	startpostype = 3; // 0 fixed, 1 random, 2 choose in game, 3 choose before game (see StartPosX)
	mapname = Stronghold V4;
	ishost = 1; // 
	//numusers = 2;
    gametype = __BARVERSION__;
    GameStartDelay = 10;  // seconds before game starts after loading/placement
    myplayername = __PLAYERNAME__;
	nohelperais = 0;
}
	]],
	
}

return scenariodata

--[[
 [Game]
{
	[allyTeam0]
	{
		startrectright = 0.98892993;
		startrectbottom = 1;
		startrectleft = 0.7896679;
		numallies = 0;
		startrecttop = 0.80811805;
	}

	[team1]
	{
		Side = Armada;
		Handicap = 0;
		RgbColor = 0.59871912 0.25364691 0.36091965;
		AllyTeam = 1;
		TeamLeader = 0;
	}

	[team0]
	{
		Side = Cortex;
		Handicap = 0;
		RgbColor = 0.65360999 0.77162737 0.15025288;
		AllyTeam = 0;
		TeamLeader = 0;
	}

	[modoptions]
	{
	}

	[allyTeam1]
	{
		startrectright = 0.22509223;
		startrectbottom = 0.23247233;
		startrectleft = 0.02583026;
		numallies = 0;
		startrecttop = 0.03321033;
	}

	[ai0]
	{
		Host = 0;
		IsFromDemo = 0;
		Name = BARbstable(1);
		ShortName = BARb;
		Team = 1;
		Version = stable;
	}

	[player0]
	{
		IsFromDemo = 0;
		Name = [teh]Behe_Chobby3;
		Team = 0;
		rank = 0;
	}

	hostip = 127.0.0.1;
	hostport = 0;
	numplayers = 1;
	startpostype = 2;
	mapname = Stronghold V4;
	ishost = 1;
	numusers = 2;
	gametype = Beyond All Reason test-15839-d0c313f;
	GameStartDelay = 5;
	myplayername = [teh]Behe_Chobby3;
	nohelperais = 0;
}

]]--