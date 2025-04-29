# Polaris UI

This is the Polaris frontend, which serves various purposes:

1. represent goal automata
2. facilitate the creation of goal automata
3. communicate with the Polaris backend

## Installation

1. Install the Godot 4.4 dev snapshot 5 from [here](https://godotengine.org/article/dev-snapshot-godot-4-4-dev-5/).
2. Download the code into a folder called `Polaris Godot`.
3. On windows, copy and paste Resouces/saves/map.save into `%APPDATA%\Godot\app_userdata\Polaris Godot`. On Mac or Linux, you'll need to copy the file into wherever Godot saves are located on your OS.
4. Open the project in Godot.

## Running

The Polaris UI will only work if connected to the Polaris backend. To do this, you will first need to obtain the IP address of the server hosting the backend. *127.0.0.1* (i.e., localhost) works just fine.

If you want to host on a different address, the command to get the IP address is `ifconfig`.

In the Godot editor, click on Polaris.tscn in the FileSystem. Click on the `Comm` node in the Scene tree and add the IP address that you want to use in the field titled 'IP' in the inspector.

Start the backend and then press play in Godot.

## Options

Polaris offers different runtime options. To acces these options, load `polaris.tscn` into the editor and click on the `Polaris` node in the hierarchy. These options can then be selected from the inspector.

- Timeline: To activate the timeline (rather than the drawing board), check the `"timeline"` option under the `Options` variable.
- Maintenance Goals: To activate maintenance goals, check the `"maintenance_goals"` option under the `Options` variable.
