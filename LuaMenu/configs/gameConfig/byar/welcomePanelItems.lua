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
        Header = "New Official Trailer released, help us making it big!",
        Text = "We've just deployed a brand-new cinematic trailer, and we need your help to spread the word! We believe the strongest community is built through word-of-mouth, so we're counting on you to take Beyond All Reason to new heights. " .. " \n" .. " \n" .. "Watch the trailer, share it with your friends, and let’s make this a massive success together! \n",
        Image = "LuaMenu/images/trailer.png",
        Url = "https://www.beyondallreason.info/news/bar-trailer-2024",
        UrlText = "Watch the trailer",
    },	

    {
        Header = "Small Team Games split!",
        Text = "This Tuesday, the Team Games rating is getting split between Small (up to 5v5) and Large (6v6-8v8) team games! We're increasing support for small team games, as they play vastly different from 8v8 - give them a try!" .. " \n" .. " \n" .. "Both modes will use your old Team Games rating as a starting point, and your Small Team rating will be reset to a minimum of 5." .. " \n" .. " \n" .. "$minratinglevel will also use rating for your chosen mode, based on the team size set in your lobby. That includes Duel - the long-standing bug where rating limits would always use team rating was fixed!" .. " \n",
    },

    {
        Header = "Season 1 has launched!",
        Text = "On Wednesday, 7AM GMT a new season has officially commenced! Climb to the top of the leaderboards now!" .. " \n" .. " \n" .. "Your rating uncertainty has been bumped up to 5 to speed up the progress. Additionally an uncertainty floor has been added to make sure players don't get stuck with their progression after many games played." .. " \n",
    },

    {
        Header = "BAR is accepting donations again! ",
        Text = "Dear Commanders, we are delighted to announce the reopening of our donation platform after a longer-than-expected hiatus." .. " \n" .. " \n" .. "As we've been hard at work refining BAR to ensure maximum enjoyment for our ever-expanding community, we repeatedly placed donation efforts on hold to focus on other priorities." .. " \n" .. " \n" .. "Support BAR with our newly reopened donation platform!" .. " \n",
        Image = "LuaMenu/images/donate.png",
        Url = "https://www.beyondallreason.info/news/support-bar-with-our-newly-reopened-donation-platform",
        UrlText = "Read Announcement",
    },

    {
        Header = "New Map: Hera Planum",
        Text = " \n" .. "Ancient eroded craters leave narrow paths on a vast plateau. Some geothermal activity remains in this barren environment. By Phalange.",
        Image = "LuaMenu/configs/gameConfig/byar/minimapOverride/Hera_Planum_0.91.jpg",
    },

    {
        Header = "New Map: Feast of Hades",
        Text = " \n" .. "3v3-6v6 map, up to 8v8 with left vs right starting boxes. By Phalange.",
        Image = "LuaMenu/configs/gameConfig/byar/minimapOverride/Feast_of_Hades_0.9.jpg",
    },

    {
        Header = "Guides for new players",
        Url = "https://www.youtube.com/channel/UCAByJ5NKeMmQ95EIWgBtbEw",
        Text = "Requiem has created some guides for new players. If you're new to the game and want to learn the basics via video we highly recommend you check them out.\n",
        UrlText = "Link to video guides"
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
