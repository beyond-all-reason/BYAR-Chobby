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
        Header = "Get Ready for the Omega Series 5 Tournament",
        Text = "The biggest and most important team tourney is back! Gather your team and join Omega Series 5th edition!" .. " \n" .. "Format: 5v5" .. " \n" .. "Date: 7th and 8th of November" .. " \n" .. "Prize pool so far: $1100" .. " \n" .. "Register by 5 Nov 2026, 13:00 GMT-7",
        Image = "LuaMenu/images/welcomepanel/recurring_events/omegaseries.png",
        Time = "2026-11-07T15:00:00", -- needs to be in UTC and is converted to user's local timezone, shows the time difference
        Url = "https://apm.bar/tournaments/omega-series-5",
        UrlText = "Register here",
    },

    {
        Header = "Changes to Moderation Warnings",
        Text = "Warnings now only need to be acknowledged once, after which the restriction is lifted. Minor, non-malicious slip-ups may also get a private, non-punitive notice instead of formal action." .. " \n",
        Url = "https://www.beyondallreason.info/microblogs/212",
        UrlText = "Read the full update",
    },

    {
        Header = "⚖️ Balance Update: Targeting & Weapon Improvements",
        Text = "This update improves targeting, missile effectiveness and weapon responsiveness. AA should handle large air swarms more consistently, with missiles now able to switch targets mid-flight." .. " \n" .. " \n" .. "Several ground defenses and units also get targeting, range and behaviour fixes." .. " \n",
        Url = "https://www.beyondallreason.info/microblogs/210",
        UrlText = "Read the patch notes",
    },

    {
        Header = "Help Keep BAR Clean - Join the Overwatch Team!",
        Text = "As BAR grows, so does the need for solid community moderation. We're looking for reliable, level-headed players to join the Overwatch Team—a trusted group that helps review reports, flag issues, and keep things fair.".." \n".." \n".."If you're active and care about a respectful game space, we'd love your help!".." \n".." \n",
        Image = "LuaMenu/images/welcomepanel/overwatch.png",
        Url = "https://discord.com/channels/549281623154229250/1097438343861649458",
        UrlText = "Sign Up for Overwatch",
    },

    {
        Header = "Code of Conduct Update: Spec Cheating, Coaching & Stream Chat",
        Text = "We've updated Code of Conduct rule B.5 to clarify what counts as spectator cheating, and what's fine when coaching or streaming. Read the full update to see what changed." .. " \n",
        Url = "https://www.beyondallreason.info/microblogs/207",
        UrlText = "Read the full update",
    },

    {
        Header = "Important Notice to Custom Widget makers and users",
        Text = "With the new Plugins tab we're now more officially supporting community-made widgets. To keep every widget you install safe and unable to run malicious code on your system, user widgets will run in a sandbox starting with the next release." .. " \n" .. " \n" .. "Players: some of your widgets may stop working until their authors update them. If one breaks, check with its creator for a new version. Built-in widgets are not affected." .. " \n" .. " \n" .. "Widget creators: please review the changes and update your widgets. Migration guides are linked in the post." .. " \n",
        Url = "https://www.beyondallreason.info/microblogs/205",
        UrlText = "Read the details",
    },

    {
        Header = "New: In-game Keybind Editor is here!",
        Text = "Edit and manage your keybinds through a proper visual interface, available from the Keys panel in the top-right corner while in-game." .. " \n" .. " \n" .. "It also supports separate keybind profiles, so you can keep different setups or experiment without touching your main configuration." .. " \n" .. " \n" .. "Huge kudos to Harkenn for creating it!" .. " \n" .. " \n",
        Url = "https://www.beyondallreason.info/microblogs/204",
        UrlText = "Read more",
    },

    {
        Header = "New Map: Pyroclast",
        Text = "A highly asymmetric battle fought amongst the debris of a volcanic eruption. Designed for PvE or 8v8. Made by Cinnamon18." .. " \n" .. " \n",
        Image = "LuaMenu/configs/gameConfig/byar/minimapOverride/Pyroclast_1.0.3.jpg",
    },

    {
        Header = "New Map: Ceasefire",
        Text = "An ancient canyon with few remaining cliffs once left 2 sides with no choice. 3v3 East vs West. Made by Phalange." .. " \n" .. " \n",
        Image = "LuaMenu/configs/gameConfig/byar/minimapOverride/Ceasefire_1.0.jpg",
    },

    {
        Header = "BAR & Hooded Horse: A New Chapter",
        Text = "After almost seven years of development, BAR is going professional and teaming up with Hooded Horse, one of the most respected publishers in the strategy space, to bring the game to a full Steam release." .. " \n" .. " \n" .. "Multiplayer stays free forever on the website. A paid Premium Edition on Steam will add a single-player campaign, with the same multiplayer playable across both versions." .. " \n" .. " \n" .. "Read the full announcement for all the details.",
        Image = "LuaMenu/images/welcomepanel/hoodedhorse.png",
        Url = "https://www.beyondallreason.info/news/beyond-all-reason-and-hooded-horse",
        UrlText = "Read the Announcement",
    },

    --{
    --    Header = "Please help us test new engines!",
    --    Text = "Just select [Engine Test] in the launcher dropdown, and then play Skirmish and Multiplayer games. AMD testers especially needed. Report anything out of the ordinary to Discord!\n",
    --    UrlText = "BAR #engine channel on Discord"
    --},

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
