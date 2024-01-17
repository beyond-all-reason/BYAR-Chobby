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
        Text = "Welcome back Commander. We hope you are ready for epic single player and multiplayer battles. Check out our Discord and join the community!\n",
    },

    {
        Header = "PRO 2v2 Tournament #3 is set to explode on January 27th!",
        Text = "\nWith 48 teams vying for qualification, the PRO 2v2 BAR Tournament #3 is geared up to showcase the absolute pinnacle of duo performances. Get ready for an electrifying display of skill and top-tier gameplay as our leading players take center stage in this official annual event.",
        Url = "https://www.beyondallreason.info/news/pro-2v2-tournament-3-january-27th",
        UrlText = "Official Announcement",
        Image = "LuaMenu/images/welcomepanel/2v2_2024.png",
        Time = "2024-01-27T14:00:00",
    },

    {
        Header = nil,
        Text = "Register your team by Jan 18th 14:00 UTC!\n",
        Url = "https://forms.gle/FHgKfh47D4WYJw7AA",
        UrlText = "Register Now!",
    },

    {
        Header = "New Map: Hyperion Shale",
        Text = " \nA new map by Moose is now available. Electric blue lava surrounds the Hyperion Shale; a 22x22 sized 5-way FFA for 5-10 players, or up to 12 players North vs South.",
        Image = "LuaMenu/configs/gameConfig/byar/minimapOverride/Hyperion_Shale_1.0.jpg",
    },

    {
        Header = "Guides for new players",
        Url = "https://www.youtube.com/channel/UCAByJ5NKeMmQ95EIWgBtbEw",
        Text = "Requiem has created some guides for new players. If you're new to the game and want to learn the basics via video we highly recommend you check them out.\n",
        UrlText = "Link to video guides"
    },

    {
        Header = "Please help us test new engines!",
        Text = "Just select [Engine Test] in the launcher dropdown, and then play Skirmish and Multiplayer games. AMD testers especially needed. Report anything out of the ordinary to Discord!\n",
        UrlText = "BAR #engine channel on Discord"
    },

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
            " \n",
    },
}

return welcomePanelItems
