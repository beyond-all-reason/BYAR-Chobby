This is how you can measure incoming command performance:
1. Modify the datadir in `parse_and_plot.ipynb` to point to BAR data directory (where infolog is located).
2. Enable command capture: open `dbg_command_capture.lua` and set `ENABLED` to `true`.
3. Collect data: Run the lobby once, grab some real-world command data.
4. Parse data: Open `parse_and_plot.ipynb` and run all cells.
5. Set streaming mode: open `dbg_command_replay.lua` and set `ENABLED` to `true`. Optionally set `AUTO_QUIT` to `true` so it auto-exists when finished.
6. Measure: open Chobby again and have it stream all the commands.
7. Parse measurements: Execute all cells in `time_measurements.ipynb` again. Compare with previous entries.

Steps 1~5 are preparation steps. You are likely to repeat only steps 6 & 7 as you perform optimization.
