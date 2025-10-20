The Wave Matrix is an ambient and immersive music mod for Luanti.

Compatible with: Mineclonia and minetest_game

Features:
- 12 original music tracks created using a Suno Pro account, specifically for this mod  
- Music plays intermittently with randomized delays for a natural, immersive feel  
- Default playback mode is shuffle for varied listening  
- Supports playback modes: Shuffle, Loop, and Play in Order  
- Any track can be selected and played manually at any time  
- Volume adjustment available via GUI (default: 30%)
- An item that is given to the player to access the GUI or /wm command as well anytime.
    - The item can be crafted as follows if lost.

 [Blank][Stone][Blank]
 
 [Stone][Wood][Stone]
 
 [Blank][Stone][Blank]

Commands:
- /wm — Opens the Wave Matrix music player GUI  
- /wmdebug — Displays time remaining until the next track plays

Notes on Luanti Limitations:
- Volume cannot be adjusted dynamically while a track is playing; changing volume will restart the current track with the new setting  
- Luanti currently lacks APIs to audit sound playback status or duration  
- This limitation has been creatively addressed by introducing randomized delays between tracks for a more ambient experience  
- Future updates may include more sound hooks and configuration options as Luanti evolves

