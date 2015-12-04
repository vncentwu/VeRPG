# verilog_text_rpg


									____   ____    __________.____________  ________ 
									\   \ /   /____\______   \__\______   \/  _____/ 
									 \   Y   // __ \|       _/  ||     ___/   \  ___ 
									  \     /\  ___/|    |   \  ||    |   \    \_\  \
									   \___/  \___  >____|_  /__||____|    \______  /
									              \/       \/                     \/



 ______   _______             _______  _______    _______  _______  _______          _________ _______  _______ 
(  __  \ (  ___  )|\     /|  (  ___  )(  ____ \  (  ____ )(  ____ )(  ___  )|\     /|\__   __/(  ____ \(  ____ \
| (  \  )| (   ) |( \   / )  | (   ) || (    \/  | (    )|| (    )|| (   ) |( \   / )   ) (   | (    \/| (    \/
| |   ) || (___) | \ (_) /   | |   | || (__      | (____)|| (____)|| |   | | \ (_) /    | |   | (__    | (_____ 
| |   | ||  ___  |  \   /    | |   | ||  __)     |  _____)|     __)| |   | |  ) _ (     | |   |  __)   (_____  )
| |   ) || (   ) |   ) (     | |   | || (        | (      | (\ (   | |   | | / ( ) \    | |   | (            ) |
| (__/  )| )   ( |   | |     | (___) || )        | )      | ) \ \__| (___) |( /   \ )___) (___| (____/\/\____) |
(______/ |/     \|   \_/     (_______)|/         |/       |/   \__/(_______)|/     \|\_______/(_______/\_______)




VeRiPG is a text-based RPG created using Verilog, a hardware simulation language."
Playing is very simple. At each turn, the map i	 and a list of allowed commands are listed below.
The goal is to navigate your player to the exit, all the while leveling your character and staying alive.
Though the maps are preloaded, the user is free to modify the map files as they wish. Have fun!










======================================= PROPOSAL ================================

I wanted to create a unique project to end the semester, so I've been mulling it over for quite a while. My idea is to create a game similar to the very old text-based games from the 80s, where the player navigates a grid map and overcomes obstacles such as enemies or puzzles.

 

Ideally, this would be done with a FPGA board and display with real-time input, but time, material, and knowledge constraints probably will not allow this. My compromise would be to create this in simulation, read input from a file, and write map and current session data to the the display (terminal) as well as a log file.

 

Depending on my progress, I hope to implement a feature in which the maps can be user-created.

 

The map would be displayed as something like this:

 
X	X	X	?	?	?	?	?	?	?
X		@	?	?	?	?	?	?	?
X			X	X	X	?	?	?	?
X	X				X	X	X	X	X
<		X							X
X		X	X	X	@	X	X		X
X					!	X	X		X
X		X	X	X		X	X		X
X									X
X	X	X	X	X	X	X	X	X	X

 

Legend:

X - Wall

! - Current location

< - start

> - finish

@ - event (enemy/puzzle)

? - unknown terrain