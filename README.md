# Blackboard Simulator Hub

A self-contained, auto-indexing hub for FPGA logic simulations. Fully compatible with static web hosting and GitHub Pages.

## Directory Structure
- `index.html` - The central 2-level navigation hub.
- `update_hub.py` - Python script to index projects and generate `projects_data.js`.
- `projects_data.js` - Auto-generated JavaScript manifest of all simulators.
- `publish.sh` - Bash script to automate auth, indexing, commits, and GitHub publishing.
- `Project_X/` - Folders containing individual `.html` simulation files.

## Adding a New Project or Simulation
1. Create a new folder starting with `Project_` (e.g., `Project_8`).
2. Drop your `.html` simulation files inside that folder.
3. Run `bash publish.sh`.

The script will automatically detect the new files, update the hub, commit the changes, and push them to GitHub Pages!
