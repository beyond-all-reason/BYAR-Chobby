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
        Header = "New Map: Vittra",
        Text = "Close quarters combat over grassy plateaus and cliffs. 1v1 - 2v2 N vs S. Made by Moose and Beherith." .. " \n" .. " \n",
        Image = "LuaMenu/configs/gameConfig/byar/minimapOverride/Vittra_3.jpg",
    },

    {
        Header = "This Month in BAR – April/May 2026",
        Text = "New visual effects, gameplay changes, and balance updates are here! GL4 visual overhaul brings build particles, death fire, beam lasers, plasma projectiles, missile trails, shield effects, bloom and more!" .. " \n" .. " \n" .. "EasyTax 2.0 overhauls resource sharing. New UI widgets, PiP improvements, ETA timers for reclaim/resurrect, and 4 new music tracks round out the update." .. " \n" .. " \n",
        Url = "https://www.beyondallreason.info/microblogs/184",
        UrlText = "Read the devlog",
    },

    {
        Header = "The BAR Documentary is Here!",
        Text = "From community roots to modern RTS ambition, this is the story of Beyond All Reason, featuring the one and only Chris Taylor." .. " \n" .. " \n" .. "Hear from BAR devs as they look back at the project's history, share where it stands today, and talk about where it's heading next. Go behind the scenes, with the journey put into context by the man who started it all." .. " \n" .. " \n" .. "Huge thanks to Fortress Sydney and the Source Code crew for making this possible!" .. " \n" .. " \n",
        Image = "LuaMenu/images/welcomepanel/sourcecode_documentary.png",
        Url = "https://www.youtube.com/watch?v=5F36yViPz7w",
        UrlText = "Watch the Documentary",
    },

    {
        Header = "Help Keep BAR Clean - Join the Overwatch Team!",
        Text = "As BAR grows, so does the need for solid community moderation. We're looking for reliable, level-headed players to join the Overwatch Team—a trusted group that helps review reports, flag issues, and keep things fair.".." \n".." \n".."If you're active and care about a respectful game space, we'd love your help!".." \n".." \n",
        Image = "LuaMenu/images/welcomepanel/overwatch.png",
        Url = "https://discord.com/channels/549281623154229250/1097438343861649458",
        UrlText = "Sign Up for Overwatch",
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
