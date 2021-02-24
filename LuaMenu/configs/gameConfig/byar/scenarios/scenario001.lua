local scenariodata = {
	index			= 1, --  integer, sort order, MUST BE EQUAL TO FILENAME NUMBER
	scenarioid		= "supcrossingvsbarbs001", -- no spaces, lowercase, this will be used to save the score
    version         = "1", -- increment this to keep the score when changing a mission
	title			= "Outsmart the Barbarians", -- can be anything
	imagepath		= "scenario001.jpg", -- placed next to lua file, should be 3:1 ratio banner style
	imageflavor		= "Rocks can contain a lot of metal...", -- This text will be drawn over image
    summary         = [[Three aggressive barbarians have landed in the top right corner of the map. Neutralize them.]],
	briefing 		= [[Supreme Crossing is focused around the central shallows passage between the two archipelagos. Every single unit can pass there, with the notable exception of Fleas, as they cannot operate even in shallow water. This should give you some safety from the earliest of raids. The seas, accessible from most areas of the map are thus connected, and control over the vast amount of metal they hold is key to victory. Fortify your side of the crossing as soon as possible, before the hordes start moving across. There are rocks stashed around the map, containing a sizeable amount of metal for a quick transition to higher tech tiers. 
    
Your progress will judged by:
    1. Speed: destroying the enemy Commanders as fast as possible.
    2. Efficiency: using the least amount of total resources to destroy the enemy Commanders.
    ]],

	mapfilename		= "Supreme_Crossing_V1", -- the name of the map to be displayed here
	playerstartx	= "25%", -- X position of where player comm icon should be drawn, from top left of the map
	playerstarty	= "75%", -- Y position of where player comm icon should be drawn, from top left of the map
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
	startscript		= [[[Game]
{
    [allyTeam0]
    {
        startrectright = 0.36900368;
        startrectbottom = 0.84132844;
        startrectleft = 0.2509225;
        numallies = 0;
        startrecttop = 0.70479703;
    }

    [ai1]
    {
        Host = 0;
        IsFromDemo = 0;
        Name = BARbarIAnstable(2);
        ShortName = BARbarIAn;
        Team = 2;
        Version = stable;
    }

    [team1]
    {
        Handicap = __ENEMYHANDICAP__;
        RgbColor = 0.89999998 0.1 0.28999999;
        AllyTeam = 1;
        TeamLeader = 0;
    }

    [allyTeam1]
    {
        startrectright = 0.99631;
        startrectbottom = 0.34686348;
        startrectleft = 0.62730628;
        numallies = 0;
        startrecttop = 0;
    }

    [team3]
    {
        Handicap = __ENEMYHANDICAP__;
        RgbColor = 0.95999998 0.50999999 0.19;
        AllyTeam = 1;
        TeamLeader = 0;
    }

    [team0]
    {
        Side = __PLAYERSIDE__;
        Handicap = __PLAYERHANDICAP__;
        RgbColor = 0 0.50999999 0.77999997;
        AllyTeam = 0;
        TeamLeader = 0;
    }

    [team2]
    {
        Handicap = __ENEMYHANDICAP__;
        RgbColor = 1 0.88 0.1;
        AllyTeam = 1;
        TeamLeader = 0;
    }

    [modoptions]
    {
        scenariooptions = __SCENARIOOPTIONS__;
    }

    [ai2]
    {
        Host = 0;
        IsFromDemo = 0;
        Name = BARbarIAnstable(3);
        ShortName = BARbarIAn;
        Team = 3;
        Version = stable;
    }

    [ai0]
    {
        Host = 0;
        IsFromDemo = 0;
        Name = BARbarIAnstable(1);
        ShortName = BARbarIAn;
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

    hostip = 127.0.0.1;
    hostport = 0;
    numplayers = 1;
    startpostype = 2;
    mapname = Supreme_Crossing_V1;
    ishost = 1;
    numusers = 4;
    gametype = __BARVERSION__;
    GameStartDelay = 10;
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