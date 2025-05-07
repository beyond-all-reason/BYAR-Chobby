--[[ -- example
    {
        Header = "bla",
        Text = "bla",
        Url = "https://www.beyondallreason.info",
        UrlText = "Beyond All Reason Website",
        Image = "LuaMenu/configs/gameConfig/byar/images/bla.png",
        Time = "2023-05-06T14:00:00", -- needs to be in UTC and is converted to user's local timezone, shows the time difference
    }
]]

local welcomePanelItems = {
    {
        Header = "Welcome to Beyond All Reason",
        Text = "Welcome back Commander. We hope you are ready for epic Singleplayer and Multiplayer battles. Check out our Discord and join the community!\n",
    },
    {
        Header = "Code of Conduct Update – May 2025",
        Text = "We've made some important updates to the BAR Code of Conduct to help keep our community welcoming, respectful, and focused." .. " \n" .. " \n" .. "Noteable changes include: clarified expectations, new guidelines on offensive names, and reinforcement on the importance of good faith participation. For details, please read the full changes on GitHub.",
        Url = "https://github.com/beyond-all-reason/code-of-conduct/compare/c935fa6...main?diff=split&w#:~:text=%40%40%20-1%2C13%20%2B1%2C15%20%40%40-,%23%20Overview,-%23%20Overview",
        UrlText = "Read the Full Changes",
    },
    {
        Header = "New Map: Pools of Ilys",
        Text = "Crucial geothermal vents were discovered on the surface of Ilys. Make landfall and secure."  .. " \n" .. " \n" ..  "Vast ponds breakup an icy landscape rich with geothermal power."  .. " \n" .. " \n" ..  "Designed for 1v1 - 3v3, supports up to 5v5. Made by neb_",
        Image = "LuaMenu/images/maps/poolsofilys.png",
    },
    {
        Header = "New Map: Sand Crowns",
        Text = "Corner spawns fight over sand crowns surrounding secluded sharp peaks."  .. " \n" .. " \n" ..  "The pale landscape is dotted with vibrant blue crystals."  .. " \n" .. " \n" ..  "Supports up to 4v4v4v4. Made by Phalange.",
        Image = "LuaMenu/images/maps/sandcrowns.png",
    },
--    {
--        Header = "Get Ready for Faction Wars!",
--        Time = "2025-05-17T15:00:00",
--        Text = "May is the Month of Legion, and Faction Wars is just around the corner. Commanders, it's time to start cooking!" .. " \n" .. " \n" .. "Sign up before May 10th to secure your spot in the biggest 3v3 Tournament of the Summer - Legion is enabled, and we have lots of fun things planned. Stay tuned!",
--        Image = "LuaMenu/images/FactionWars3v3.png",
--        Url = "https://bfn.challonge.com/FWQualifier",
--        UrlText = "Sign Up & Info",
--    },   
    {
        Header = "Upcoming Events:",
    },
    {
        Header = "GERBAR Teamworx Cup",
        Text = "To celebrate their one year anniversary, GERBAR discord is hosting an OS-limited Tournament open to all BAR players, regardless of nationality.",
        Time = "2025-05-10T16:00:00",
        Image = "LuaMenu/images/twitchmisc/Teamwork_Cup_v26.png",
        Url = "https://challonge.com/TeamWorxCup",
        UrlText = "Sign Up",
    },
    {
        Header = "Faction Wars Qualifier",
        Time = "2025-05-17T15:00:00",
        Text = "Sign up before May 15th to secure your spot in the biggest 3v3 Tournament of the Summer - Legion is enabled, and we have lots of fun things planned. Stay tuned!",        
        Image = "LuaMenu/images/FactionWars3v3.png",
        Url = "https://bfn.challonge.com/FWQualifier",
        UrlText = "Sign Up & Info",
    }, 
--    {
--        Header = "Fight Night Open 2v2",
--        Text = "Find a partner and join our 2v2 Legion-enabled tournament! All-welcome.",
--        Time = "2025-05-10T17:00:00",
--        Image = "LuaMenu/images/twitchmisc/FightNight.png",
--        Url = "https://bfn.challonge.com/FN2",
--        UrlText = "Sign Up",
--    },
    {
        Header = "Now Available: BAR Guides",
        Text = "New to Beyond All Reason? Check out these new Guides on Discord written by Zeteo!" .. " \n" .. " \n",
        Url = "https://discord.com/channels/549281623154229250/1303141562120929320/1303141562120929320",
        UrlText = "Read the new Guides",
    },
    {
        Header = "BAR is accepting donations again! ",
        Text = "Dear Commanders, we are delighted to announce the reopening of our donation platform after a longer-than-expected hiatus." .. " \n" .. " \n" .. "As we've been hard at work refining BAR to ensure maximum enjoyment for our ever-expanding community, we repeatedly placed donation efforts on hold to focus on other priorities." .. " \n" .. " \n" .. "Support BAR with our newly reopened donation platform!" .. " \n",
        Image = "LuaMenu/images/donate.png",
        Url = "https://www.beyondallreason.info/news/support-bar-with-our-newly-reopened-donation-platform",
        UrlText = "Read Announcement",
    },

    --{
    --    Header = "Please help us test new engines!",
    --    Text = "Just select [Engine Test] in the launcher dropdown, and then play Skirmish and Multiplayer games. AMD testers especially needed. Report anything out of the ordinary to Discord!\n",
    --    UrlText = "BAR #engine channel on Discord"
    --},

    {
        Header = "Steam release roadmap",
        Url = "https://www.beyondallreason.info/development/steam-release",
        Text = "We've published our Steam Release roadmap, check it out on the website!",
        UrlText = "Roadmap Link"
    },

    --[[
    {
        Header = "New engine release",
        Url = nil, -- should be nil if you dont want a clickable link button
        Time = nil, --"",
        Text = "We've just released a new engine update. Be sure to report any issues to #bugreports on the discord and thank you for bearing with us through any teething problems with it.."
    },
    --]]

    --{
    --    Header = "Code of Conduct",
    --    Url = "https://www.beyondallreason.info/code-of-conduct",
    --    Text = "We recently updated our code of conduct; be sure to check it out. As our community growth we've added the ability to report problems, click a user and select 'report user' to alert the moderator team to an issue. See the full code of conduct at https://www.beyondallreason.info/code-of-conduct",
    --    UrlText = "Code of Conduct Link"
    --},

    {
        Header = "Play with your friends: use our servers!",
        Text = "Join any empty (blue), or waiting (green) battle to start playing, or host your own public or private battle by clicking the Host Game button in the Multiplayer Battle List",
    },

    {
        Header = "Useful commands in Multiplayer!",
        Text = "!boss [nickname] \n" ..
            "Boss someone (or yourself) in your battleroom so that person can set all the settings up without voting. You automatically become a boss of a room that you Host yourself.\n" ..
            " \n" ..
            "!forcestart \n" ..
            "If your game is stuck because of some AFK player that refuses to load or press ready, or you encountered a bug that prevents your game from starting, or you set up weird teams, !forcestart is your savior.\n" ..
            " \n" ..
            "!stop \n" ..
            "If you need to terminate the game you're currently playing for whatever reason, !stop will happily do it for you.\n" ..
            " \n" ..
            "!promote \n"  ..
            "Sends a little message on ingame main chat that your room is waiting for people to join.\n" ..
            " \n" ..
            "$rename [name] \n"  ..
            "Renames the battleroom you're currently in. Requires you to be the !boss of the battleroom to do so.\n" ..
            " \n" ..
            "$setratinglevels [min] [max] \n"  ..
            "Sets minimum and maximum skill rating allowed in the room.\n" ..
            " \n" ..
            "$resetratinglevels\n"  ..
            "Removes skill rating limits from the room.\n" ..
            " \n" ..
            "$explain \n" ..
            "Gives you a nice breakdown of how the autobalance works in your current battleroom.\n" ..
            " \n" ..
            "For a full list of commands, use !help and $help in any multiplayer room." ..
            " \n" ..
            " \b",
    },
}

return welcomePanelItems
