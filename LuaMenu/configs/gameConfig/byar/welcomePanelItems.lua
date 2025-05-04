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
        Header = "New Map: Prismatic Anomaly",
        Text = "Anomalous light signatures were detected on a moon orbiting an Astral Compound." .. " \n" .. " \n" .. "Preliminary scans have revealed structures of unknown orgin. Further investigation is necessary."  .. " \n" .. " \n" ..  "Designed for 3v3, supports 1v1 to 5v5. Made by Zagupi.",
        Image = "LuaMenu/images/prismaticanomaly.png",
    },
    {
        Header = "Get Ready for Faction Wars!",
        Time = "2025-05-17T15:00:00",
        Text = "May is the Month of Legion, and Faction Wars is just around the corner. Commanders, it's time to start cooking!" .. " \n" .. " \n" .. "Sign up before May 10th to secure your spot in the biggest 3v3 Tournament of the Summer - Legion is enabled, and we have lots of fun things planned. Stay tuned!",
        Image = "LuaMenu/images/FactionWars3v3.png",
        Url = "https://bfn.challonge.com/FWQualifier",
        UrlText = "Sign Up & Info",
    },   
    {
        Header = "Alpha Cup V Finals are on YouTube!",
        Text =" \n" .. "Congratulations to our new 1v1 Champion! In case you missed it, you can still rewatch the Alpha Cup madness on YouTube." .. " \n" .. " \n" .. "Thank you to everyone in the community for making this event happen! At 87 players, this was the biggest Alpha Cup yet.",
        Image = "LuaMenu/images/AlphaCupV.png",
        Url = "https://www.youtube.com/watch?v=DCPU8qOLiSQ",
        UrlText = "Watch the Finals",
    },
    {
        Header = "Upcoming Events:",
    },
    {
        Header = "King of The Hill",
        Text = "Join the AllReasonNoLogic crew for some free-for-all chaos in their weekly King of The Hill cast!",
        Time = "2025-05-04T11:00:00",
        Image = "LuaMenu/images/twitchmisc/KOTH.png",
        Url = "https://twitch.tv/BeyondAllReasonOfficial",
        UrlText = "Watch on Twitch",
    },
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
