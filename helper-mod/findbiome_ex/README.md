# Minetest mod: findbiome_ex

this is modified version of findbiome by Wuzzy.
(“listbiomes”) now shows heat, humidity, y_min,y_max 
(“printbiomes”) prints this comma-separated-list to the console for easy copying.

## Description
This is a mod to help with mod/game development for Minetest.
It adds a command (“findbiome”) to find a biome nearby and teleport you to it,
and another command (“listbiomes”) to list all biomes.

Version: 1.2.0

## Known limitations
There's no guarantee you will always find the biome, even if it exists in the world.
This can happen if the biome is very obscure or small, but usually you should be
able to find the biome.

If the biome could not be found, just move to somewhere else and try again.

## Modding info

For modders, this mod offers two functions to search or list biomes via code, similar to the chat commands.
See `API.md` for details.

## Authors
- paramat (MIT License)
- Wuzzy (MIT License)
- Skivling (MIT License, `list_biomes()` function)

This mod is free software. See `license.txt` for license information.

This mod is based on the algorithm of the "spawn" mod from Minetest Game 5.0.0.
