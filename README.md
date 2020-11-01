# BYAR-Chobby

BYAR mutator for Chobby

# Download links

- [Linux](https://spring-launcher.ams3.digitaloceanspaces.com/beyond-all-reason/BYAR-Chobby/Beyond%20All%20Reason.AppImage)
- [Windows](https://spring-launcher.ams3.digitaloceanspaces.com/beyond-all-reason/BYAR-Chobby/Beyond%20All%20Reason.exe)

# Development steps

1. Download using one of the links above and start the application.
2. Start the application once using the "Test" version and launch the lobby. This will download the engine and other dependencies.
3. Open the install folder (there's a button for that in the launcher), and clone this repository inside the `games` folder, `git clone https://github.com/beyond-all-reason/BYAR-Chobby.git BYAR-Chobby.sdd`
4. Choose the "Dev Lobby" config from the launcher's top right dropdown menu which will run the lobby version on your PC. You can now develop and test any BYAR specific lobby functionality.
5. If you want to develop Chobby itself, clone it in the `games` folder similar to step 3: `git clone https://github.com/Spring-Chobby/Chobby.git Chobby.sdd`. You must also change the `depend` table in `BYAR-Chobby.sdd/modinfo.lua` to use `Chobby $VERSION` instead of `rapid://chobby:test`.

To enable debugmode, make an empty devmode.txt in the /data/ folder, and then the settings->developer tab will appear in the lobby. All debug messages are visible in th Debug chat panel.

## Tips for BYAR-Chobby development:

1. Use Zerobrane Studio dev env, open up any chobby Beyond-All-Reason\data\*.lua file with Zerobrane studio, then set Project->Project Directory->From current file
2. This allows you to ctrl+shift+f to find any text in all of chobby, useful 
3. Do NOT try to edit anything in Chobby.sdd! If you want to edit something in Chobby.sdd that is not overwritten by the mutator BYAR-Chobby (e.g. does not exist in BYAR-Chobby.sdd), then copy it over to BYAR-Chobby.sdd first and commit it (so we have a baseline).
4. Open infolog.txt in notepad++ or anything to grep for errors. 
