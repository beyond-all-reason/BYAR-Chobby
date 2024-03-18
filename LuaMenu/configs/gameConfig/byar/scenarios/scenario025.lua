local scenariodata = {
	index			= 25, --  integer, sort order, MUST BE EQUAL TO FILENAME NUMBER
	scenarioid		= "rcrmexrace", -- no spaces, lowercase, this will be used to save the score
    version         = "0.4", -- increment this to keep the score when changing a mission
	title			= "Rich Resource Race", -- can be anything
	author			= "kroIya", -- your name here
	imagepath		= "scenario024.jpg", -- placed next to lua file, should be 3:1 ratio banner style
	imageflavor		= "", -- This text will be drawn over image
    summary         = [[Expand your economy faster than the enemy can.]],
	briefing 		= [[The atmosphere of this resource-rich asteroid can not be withstood by unprotected units. Only your commander, the construction bots, and the specially insulated Welders can operate in these conditions. Welders are expensive and require access to Tier 2 technology. Extract more metal than your opponent and secure a crushing technological advantage!
 
	 
	Tips:
	 
	‣ Wind is not efficient on this map due to the atmospheric conditions. Use solar energy.
	‣ The Commander does not have access to the D-Gun in this scenario, so it is much more vulnerable to other units.
	‣ You need a Tier 2 Lab to produce any combat units. A Tier 2 Lab can be built by a Tier 1 Construction Bot.
	‣ Your opponent has the same restrictions, so you do not have to worry about early aggression.
	‣ Send out many Construction Bots to build Metal Extractors all across the map.
	‣ The Area Mex command allows you to draw a cirle, and your constructors will capture every Extractor within it.
	‣ Do not stop the expansion once you start building combat units. You will also need many solar collectors to sustain production.
	‣ A good start is building 2-3 Metal Extractors, followed by 2 Solar Collectors, then a Bot Lab to build more constructors.
 
			 
	The difficulty modifier will change the amount of resources the enemy receives from metal and energy production structures:
	‣ Beginner: Regular resources for you, -50% for the enemy
	‣ Novice: Regular resources for you, -25% for the enemy
	‣ Normal: Regular resources for both sides
	‣ Hard: Regular resources for you, +50% for the enemy
	‣ Brutal: Regular resources for you, +100% for the enemy
    ]],

	mapfilename		= "Red Comet Remake 1.8", -- the name of the map to be displayed here
	playerstartx	= "10%", -- X position of where player comm icon should be drawn, from top left of the map
	playerstarty	= "65%", -- Y position of where player comm icon should be drawn, from top left of the map
	partime 		= 1200, -- par time in seconds
	parresources	= 10000, -- par resource amount
	difficulty		= 1, -- Percieved difficulty at 'normal' level: integer 1-10
    defaultdifficulty = "Normal", -- an entry of the difficulty table
    difficulties    = { -- Array for sortedness, Keys are text that appears in selector (as well as in scoring!), values are handicap levels
    -- handicap values range [-100 - +100], with 0 being regular resources
        {name = "Beginner", playerhandicap = 0, enemyhandicap=-50},
        {name = "Novice"  , playerhandicap = 0, enemyhandicap=-25},
        {name = "Normal"  , playerhandicap = 0, enemyhandicap=0},
        {name = "Hard"    , playerhandicap = 0,  enemyhandicap=25},
        {name = "Brutal" , playerhandicap = 0,  enemyhandicap=50},
    },
    allowedsides     = {"Armada"}, --these are the permitted factions for this mission
	victorycondition= "Kill all enemy Commanders", -- This is plaintext, but should be reflected in startscript
	losscondition	= "Death of your Commander",  -- This is plaintext, but should be reflected in startscript
    unitlimits   = { -- table of unitdefname : maxnumberoftese units, 0 is disable it
		armsy = 0,
		armvp = 0,
		armap = 0,
		armfhp = 0,
		armhp = 0,
		armflea = 0,
		armpw = 0,
		armrectr = 0,
		armrock = 0,
		armjeth = 0,
		armham = 0,
		armwar = 0,
		armvader = 0,
		armaser = 0,
		armmark = 0,
		armspy = 0,
		armfast = 0,
		armfark = 0,
		armspid = 0,
		armamph = 0,
		armfido = 0,
		armsptk = 0,
		armack = 0,
		armaak = 0,
		armmav = 0,
		armsnipe = 0,
		armdecom = 0,
		armscab = 0,
		armfboy = 0,
    } ,

    scenariooptions = { -- this will get lua->json->base64 and passed to scenariooptions in game
        myoption = "dostuff",
        scenarioid = "rcrmexrace",
		disablefactionpicker = true, -- this is needed to prevent faction picking outside of the allowedsides
    },
    -- https://github.com/spring/spring/blob/105.0/doc/StartScriptFormat.txt
	startscript		= [[
[Game]
{
	[allyTeam0]
	{
		startrectright = 0.12;
		startrectbottom = 1;
		startrectleft = 0;
		numallies = 0;
		startrecttop = 0;
	}

	[team1]
	{
		Side = Arm;
		Handicap = __ENEMYHANDICAP__;
		RgbColor = 0.88436127 0.07208818 0.09521562;
		AllyTeam = 1;
		TeamLeader = 0;
	}

	[allyTeam1]
	{
		startrectright = 1;
		startrectbottom = 1;
		startrectleft = 0.88;
		numallies = 0;
		startrecttop = 0;
	}


	[team0]
	{
		Side = __PLAYERSIDE__;
		Handicap = __PLAYERHANDICAP__;
		RgbColor = 0 0.50999999 0.77999997;
		AllyTeam = 0;
		TeamLeader = 0;
	}


    [modoptions]
    {
        scenariooptions = __SCENARIOOPTIONS__;
		tweakunits = e2FybWNvbT17d2VhcG9uZGVmcz17ZGlzaW50ZWdyYXRvcj17cmFuZ2U9MSx9LH0sfSxhcm1obHQ9e3dlYXBvbmRlZnM9e2FybV9sYXNlcmgxPXtkYW1hZ2U9e2RlZmF1bHQ9MTUwLH0sfSx9LH0sfQ;
    }



	[ai0]
	{
		Host = 0;
		IsFromDemo = 0;
		Name = BARbarIAnstable(1);
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

	hostip = 127.0.0.1;
	hostport = 0;
	numplayers = 1;
	startpostype = 2;
	mapname = __MAPNAME__;
	ishost = 1;
	numusers = 4;
	gametype = __BARVERSION__;
	GameStartDelay = 5;
	myplayername = __PLAYERNAME__;
	nohelperais = 0;


	NumRestrictions=__NUMRESTRICTIONS__;

	[RESTRICT]
	{
		__RESTRICTEDUNITS__
	}
	

}
	]],
}

return scenariodata
