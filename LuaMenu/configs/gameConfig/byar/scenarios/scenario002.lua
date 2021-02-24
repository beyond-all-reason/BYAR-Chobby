local scenariodata = {
	index			= 999, --  integer, sort order, MUST BE EQUAL TO FILENAME NUMBER
	scenarioid		= "dguntestscenario", -- no spaces, lowercase, this will be used to save the score
    version         = "1.0", -- increment this to keep the score when changing a mission
	title			= "Dgun The Enemy Commander", -- can be anything
	imagepath		= "scenario002.jpg", -- placed next to lua file, should be 3:1 ratio banner style
	imageflavor		= "This is a test mission to test the interface", -- This text will be drawn over image
    summary         = [[Just dgun the enemy comm to test score saving.]],
	briefing 		= [[Your progress will judged by:
    1. Speed: destroying the enemy Commanders as fast as possible.
    2. Efficiency: using the least amount of total resources to destroy the enemy Commanders.
    ]],

	mapfilename		= "TitanDuel 2.2", -- the name of the map to be displayed here
	playerstartx	= "50%", -- X position of where player comm icon should be drawn, from top left of the map
	playerstarty	= "50%", -- Y position of where player comm icon should be drawn, from top left of the map
	partime 		= 3000, -- par time in seconds
	parresources	= 1000000, -- par resource amount
	difficulty		= 5, -- Percieved difficulty at 'normal' level: integer 1-10
    adjustablediff  = true, -- whether player can change bonus
    defaultdifficulty = "Normal", -- an entry of the difficulty table
    difficulties    = { -- Array for sortedness, Keys are text that appears in selector (as well as in scoring!), values are handicap levels
        {name = "Beginner", playerhandicap = 150, enemyhandicap=100},
        {name = "Novice"  , playerhandicap = 125, enemyhandicap=100},
        {name = "Normal"  , playerhandicap = 100, enemyhandicap=100},
        {name = "Hard"    , playerhandicap = 100,  enemyhandicap=125},
        {name = "Brutal" , playerhandicap = 100,  enemyhandicap=150},
    },
    defaultside     = "Armada", --"Armada", Cortex or Random
	victorycondition= "Kill all enemy Commanders", -- This is plaintext, but should be reflected in startscript
	losscondition	= "Death of your Commander",  -- This is plaintext, but should be reflected in startscript
    unitlimits   = { -- table of unitdefname : maxnumberoftese units, 0 is disable it
        armavp = 0,
        coravp = 0,
    } ,

    scenariooptions = { -- this will get lua->json->base64 and passed to scenariooptions in game
        myoption = "dostuff",
        scenarioid = "supcrossingvsbarbs001",
    },
    -- https://github.com/spring/spring/blob/105.0/doc/StartScriptFormat.txt
	startscript		= [[ [Game]
{
	[allyTeam0]
	{
		startrectright = 0.42066422;
		startrectbottom = 0.50922507;
		startrectleft = 0.34317344;
		numallies = 0;
		startrecttop = 0.39852399;
	}

	[team1]
	{
        Handicap = __ENEMYHANDICAP__;
		RgbColor = 0.28831697 0.75334734 0.74793065;
		AllyTeam = 1;
		TeamLeader = 0;
	}

	[team0]
	{
        Side = __PLAYERSIDE__;
        Handicap = __PLAYERHANDICAP__;
		RgbColor = 0.40995723 0.34172571 0.7648201;
		AllyTeam = 0;
		TeamLeader = 0;
	}

	[modoptions]
	{
        scenariooptions = __SCENARIOOPTIONS__;
	}

	[allyTeam1]
	{
		startrectright = 0.47232476;
		startrectbottom = 0.52767527;
		startrectleft = 0.41697419;
		numallies = 0;
		startrecttop = 0.39114392;
	}

	[ai0]
	{
		Host = 0;
		IsFromDemo = 0;
		Name = SimpleAI(1);
		ShortName = SimpleAI;
		Team = 1;
		Version = <not-versioned>;
	}

	[player0]
	{
		IsFromDemo = 0;
		Name = __PLAYERNAME__;;
		Team = 0;
		rank = 0;
	}

	hostip = 127.0.0.1;
	hostport = 0;
	numplayers = 1;
	startpostype = 2;
	mapname = TitanDuel 2.2;
	ishost = 1;
	numusers = 2;
	gametype = __BARVERSION__;
	GameStartDelay = 5;
	myplayername = __PLAYERNAME__;
	nohelperais = 0;

	NumRestrictions=__NUMRESTRICTIONS__;

	[RESTRICT]
	{
		//Unit0=armah;
		//Limit0=0;       // use 0 for all units that should be completely disabled
		//Unit1=corvp;
		//Limit1=50;      // >0 can be used for limiting, like build restrictions in TA
		//...
        __RESTRICTEDUNITS__
	}
}
	]],
	
}

return scenariodata