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
        NoPulse = true,
    },

    {
        Header = "Nation Wars 2026 – Registration Open",
        Text = "The 2026 edition of our friendly competition to find out which nation is the best at BAR is coming in hot this May!\nWill Germany defend its title, or will YOU claim it and bolster your flag's pride?".." \n".." \n".."Join the Nation Wars Discord, rally your fellows, and represent your nation!".." \n".." \n".."You have until April 26 to sign up, before battling it out in 4v4 against the other nations on the weekends of May 16/17 and May 23/24.\nFull rules available on the Nation Wars Discord.",
        Image = "LuaMenu/images/nation_wars.png",
        Url = "https://discord.gg/qurXWcjmNN",
        UrlText = "Nation Wars Discord",
    },

    {
        Header = "Unit Stats 2.0 is Live!",
        Text = "The Website Unit Library just got a massive upgrade! All weapons per unit are now listed with individual stats across all factions including Legion. Fire every weapon directly in the browser with accurate range, speed, duration and firing sounds." .. " \n" .. " \n" .. "New features include DOT tracking, paralyzer PPS, target category indicators, fixed animations, new 3D unit renders, and mobile-optimised performance. Use 1-9 to fire weapons and 0 to pause the scene!" .. " \n" .. " \n",
        Image = "LuaMenu/images/welcomepanel/unit_stats_2.png",
        Url = "https://www.beyondallreason.info/units/armada-bots",
        UrlText = "Browse the Unit Library",
    },

    {
        Header = "The Lore is here!",
        Text = "Time to dive in, Commanders.  \n" .. " \n" .. "Step Beyond Human Reach, uncover the stories of Armada and Cortex, and navigate the vastness of BAR universe.",
        Image = "LuaMenu/images/welcomepanel/lore.png",
        Url = "https://www.beyondallreason.info/news/the-lore-is-here",
        UrlText = "Read the Announcement",
    },

    {
        Header = "Star BAR on GitHub!",
        Text = "BAR is built by the community, for the community. One easy way to support us: star our GitHub repository! " .. " \n" .. " \n" .. "It signals the project is alive and helps us access developer programs that give us better tools to build with." .. " \n" .. " \n" .. "(Star button in top right corner of the linked page)" .. " \n" .. " \n",
        Image = "LuaMenu/images/welcomepanel/github_star.png",
        Url = "https://github.com/beyond-all-reason/Beyond-All-Reason",
        UrlText = "Star us on GitHub",
    },

    {
        Header = "Help Keep BAR Clean - Join the Overwatch Team!",
        Text = "As BAR grows, so does the need for solid community moderation. We're looking for reliable, level-headed players to join the Overwatch Team—a trusted group that helps review reports, flag issues, and keep things fair.".." \n".." \n".."If you're active and care about a respectful game space, we'd love your help!".." \n".." \n",
        Image = "LuaMenu/images/welcomepanel/overwatch.png",
        Url = "https://discord.com/channels/549281623154229250/1097438343861649458",
        UrlText = "Sign Up for Overwatch",
    },

    {
        Header = "Now Available: BAR Guides",
        Text = "New to Beyond All Reason? Check out these new Guides on Discord written by Zeteo!" .. " \n" .. " \n",
        Url = "https://discord.com/channels/549281623154229250/1303141562120929320/1303141562120929320",
        UrlText = "Read the new Guides",
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
        Text = "We've just released a new engine update. Be sure to report any issues to #bugreports on the discord and thank you for bearing with us through any teething problems with it.."
    },
    --]]

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
