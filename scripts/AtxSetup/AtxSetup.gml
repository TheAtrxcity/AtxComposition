#macro ATX_GAME_VERSION 0

// These are the priority enums the order in which constructs are loaded.
enum ATX_SAVE
{
   SYSTEM,
   INTERACTABLES,
   ENVIRONMENT,
   ITEMS,
   DEFAULT,
   NPC,
   ENEMY,
   PLAYER,
}

global.__atxSaveConfig = 
{
   saveDirectory : "saves/", // %localappdata%/yourGameName/saves/
   maxSaveSlots : 10,
   // Future implementation?
   //autoSaveEnabled : true,
   //autoSaveInterval : 300, 
}

// !! Don't change anything under here !!
AtxInitialiseSaveSystem();