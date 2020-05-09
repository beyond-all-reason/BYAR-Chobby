# BYAR-Chobby

BYAR mutator for Chobby

# Download links

- [Linux](https://spring-launcher.ams3.digitaloceanspaces.com/beyond-all-reason/BYAR-Chobby/Beyond%20All%20Reason.AppImage)
- [Windows](https://spring-launcher.ams3.digitaloceanspaces.com/beyond-all-reason/BYAR-Chobby/Beyond%20All%20Reason.exe)

# Development steps

1. Download using one of the links above and start the application.
2. Start the application once using the "Test" version and launch the lobby. This will download the engine and other dependencies.
3. Open the install folder (there's a button for that in the launcher), and clone this repository inside the `games` folder, `git clone https://github.com/beyond-all-reason/BYAR-Chobby.git BYAR-Chobby.sdd`
4. Choose the "Dev Lobby" config which will run the lobby version on your PC. You can now develop and test any BYAR specific lobby functionality.
5. If you want to develop Chobby itself, clone it in the `games` folder similar to step 3: `git clone https://github.com/Spring-Chobby/Chobby.git Chobby.sdd`. You must also change the `depend` table in `BYAR-Chobby.sdd/modinfo.lua` to use `Chobby $VERSION` instead of `rapid://chobby:test`.
