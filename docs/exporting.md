---
title: "Exporting"
permalink: /exporting/
---

# Exporting the Map

Once you've completed your map's layout and want to test it in-game, we'll need to **export** the Map to a PCK file
Go to Project -> Export in Godot's top menu bar
![Export Project](https://raw.githubusercontent.com/bearlikelion/SurfsUpSDK/refs/heads/main/docs/assets/img/exporting/export_project.png)

Click on **Custom Map (Export as PCK)**
Under the Export Settings, go to the **Resources** tab and *only* export your custom level's .TSCN file
![Export Resources](https://raw.githubusercontent.com/bearlikelion/SurfsUpSDK/refs/heads/main/docs/assets/img/exporting/export_resources.png)

Click on the **Export PCK/ZIP** bottom button, and save your `map_name.pck` directly to `<install_dir>\Maps`
Example Path: `steamapps/common/SurfsUp/Maps`
**Keep in mind:** The `map_name.pck` and `Levels\map_name.tscn` needs to match in order to load in-game
Once exported, you can [load your map in-game](testing.md)
