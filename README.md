# MT-Biome2Voronoi
 Parse Minetest/Luanti Biome-Definitions in Lua/Json code to CSV, and make Voronoi-Diagrams from CSV.

![Voronoi-Diagram of Minetest Bioms](https://raw.githubusercontent.com/Distributed-DeadLock/MT-Biome2Voronoi/refs/heads/main/Screenshots/MTBV_08_Result_Voronoi-Diagram.png)

![The Interface](https://raw.githubusercontent.com/Distributed-DeadLock/MT-Biome2Voronoi/refs/heads/main/Screenshots/MTBV_01_Interface.png)


This Python-Script helps you to collect Minetest/Luanti Biom-Definitions from Lua-Code and "ethereal-style" JSON-Biom-Definitions.
It parses the Definitions into a CSV-List (CSV = Comma-Seperated-Values, a text-format that can be imported into any Spreadsheet-Software).

From this CSV-List it then creates Voronoi-Diagrams as png-image-files.
You can either generate a Voronoi-Diagram for All Biomes, or
create a Voronoi-Diagram for the Bioms at a given Height-Level.

The Voronoi-Diagrams are made labeled and randomly colored.

## Requires
Requires following python-libraries to be installed(via `pip3 intall`):
generativepy
scipy
tkinter
shopen
pathlib
math
random

## Usage
Start program (e.g. with `python MT-Biome2Voronoi.py`).

Copy the Lua-Code containing Biome-Definitions from a mod, or copy  "ethereal-style" JSON-Biom-Definitions.
Paste the text (Ctrl-V) into the Left Text-Box of the program (Title: Lua/JSON to parse here).
Press the "Parse Lua/Json"-Button (at the bottom-left).
The Right Text-Box should now contain a Biom-List in CSV-format. It should look like this:
`biome1_name,50,50,-1,100
biome2_name,40,60,-100,400`

Repeat the above steps, until you have all Biomes collected in you CSV-List.

Then press the "Generate Voronoi with All Biomes"-Button.
A png-image with the Voronoi-Diagram will be generated, saved in the script-directory and the opened.

Alternativly, press the "Generate Voronoi at Height"-Button after putting a Height-Level in the text-field next to the button.
A png-image with a Voronoi-Diagram for the Bioms at a given Height-Level will be generated, saved in the script-directory and the opened.

To change the file-name of the generated png-image, change the text-field next to "Image File-Name (no extension)" to the new filename (without extension)

![Usage1](https://raw.githubusercontent.com/Distributed-DeadLock/MT-Biome2Voronoi/refs/heads/main/Screenshots/MTBV_01_Interface.png)
![Usage2](https://raw.githubusercontent.com/Distributed-DeadLock/MT-Biome2Voronoi/refs/heads/main/Screenshots/MTBV_02_Usage_Copy.png)
![Usage3](https://raw.githubusercontent.com/Distributed-DeadLock/MT-Biome2Voronoi/refs/heads/main/Screenshots/MTBV_03_Usage_Paste.png)
![Usage4](https://raw.githubusercontent.com/Distributed-DeadLock/MT-Biome2Voronoi/refs/heads/main/Screenshots/MTBV_04_Usage_Parse.png)
![Usage5](https://raw.githubusercontent.com/Distributed-DeadLock/MT-Biome2Voronoi/refs/heads/main/Screenshots/MTBV_05_Usage_Copy_more.png)
![Usage6](https://raw.githubusercontent.com/Distributed-DeadLock/MT-Biome2Voronoi/refs/heads/main/Screenshots/MTBV_06_Usage_Paste-n-Parse_more.png)
![Usage7](https://raw.githubusercontent.com/Distributed-DeadLock/MT-Biome2Voronoi/refs/heads/main/Screenshots/MTBV_07_Usage_Generate.png)
![Result8](https://raw.githubusercontent.com/Distributed-DeadLock/MT-Biome2Voronoi/refs/heads/main/Screenshots/MTBV_08_Result_Voronoi-Diagram.png)

## License
The software is licensed with the MIT License
