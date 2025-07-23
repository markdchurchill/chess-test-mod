# Mods: Definitive Edition

ChessTestMod is an example mod for the game Chess: Definitive Edition - coming soon, and currently in a free playtest. 
Join the [playtest on Steam](https://store.steampowered.com/app/3603550/Chess_Definitive_Edition/) and add it to your wishlist.

> [!WARNING]
> Mod support is at a preview stage. The API will likely change and break your mod. Doubly so for integration points not listed in samples.

## Requirements

- [Godot 4.4](https://godotengine.org/download/windows)
- [DotNet 8 SDK](https://dotnet.microsoft.com/en-us/download/dotnet/8.0)

## Mod Structure

You distribute your mod into the game's `/mods/{unique-mod-id}` folder. This folder must contain a `mod.json` to describe your mod.

The `version` field is important, and is checked for multiplayer compatibility. You must update this if you make changes to game logic (ie: card code).

The `mainPck` field is the main Godot PCK file that contains your mod's resources. This should be exported as "patch" file. 
If `overlayFiles` is true it will overwrite existing resources - although I may remove this ability.

Optionally, you may provide a `mainAssembly` field that refers to your compiled assembly. Do not pack this into the PCK.

This test mod would be distributed as (mod.json, test.pck, ChessTestMod.dll) in the `/mods/test/` folder. A build script that generates a test.zip 
may be the most convenient way.

If SIMPLECHESS_MODS_PATH is set in the env, it will be used instead of /mods.

##  Features

Chess: Definitive Edition has been built to support extensibility and modding from the ground up, with a lot of work gone into allowing many different effects
on the game to coexist without logical conflicts. Generally, mods should work together, even if several are altering piece movements or abilities at the same
time. Trying to break out of the provided extension points will mean your mod will not play nicely with others (and will break multiplayer).

Multiplayer should just work.

### Custom Cards

You can extend the game with custom cards (see: Banish.cs). Inherit the most relevant base card type, add some descriptive metadata and game logic, and you're good to go.

The base card logic will load the card's image and 'on play' sound from the resource path matching your card's type and namespace (without the root), this default
suits these assets being placed next to the card script for export as PCK.

### Custom Pieces

Implemented. Guide coming soon.

### Code Notes

> [!CAUTION]
> If you need a random number, you must use the deterministic generator provided by `ChessGame.GetRandomForPurpose` for only the single method call you are in.

Types are generally immutable. Expect to use a lot of `with { ... }`.

The game space is 3D - all positioning and movement atoms are 3D, however not much content utilizes 3D as there needs to be a minimal set of content to 
make it worthwhile, and likely some UX tweaks to make it usable. This will come as a larger content drop in the future, but shouldn't break API.

### Menu Backgrounds

The game will load a random scene from `res://MenuBackgrounds/`. You can add additional scenes in your overlay.

As a direct child of your scene root, if you have a camera node named `AutoCamera` then it will tween to any `Marker3D` named after a main menu (`Settings`, `NewGame`...)

### Other Content

I plan to formalize methods for providing and selecting visual changes, eg custom piece sets, card backs, environments, boards, and so on. The intention is that
this would be pretty code-light.

At some point I will add organisation of cards into sets, and selectable starting board layouts.

Future extension concepts (which may cause breaking changes):

- Formalized difference between captured and destroyed pieces
- Special moves that can be played at any time if conditions are met (eg: Il Vaticano)
- Cards that can affect their draw probabilities, allowing increased likelyhood of counter-cards
- Random events and end-game crises

Moving Chess: Definitive Edition towards release, I will likely extract some of the core cards out into themed packs, available as source-available mods.

If the game becomes popular enough, I will add Steam Workshop support.

## License

- Banish.cs - CC0
- Banish.png from Unsplash
- Banish.wav licensed to Chess: Definitive Edition, not for reuse or distribution.

