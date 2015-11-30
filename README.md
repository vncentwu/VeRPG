# verilog_text_rpg

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