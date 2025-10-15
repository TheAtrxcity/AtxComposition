#macro ATX_GAME_VERSION 0

enum ATX_SAVE
{
   SYSTEM,
   INTERACTABLES,
   ENVIROMENT,
   ITEMS,
   DEFAULT,
   NPC,
   ENEMY,
   PLAYER,
}

global.__atxSaveConfig = 
{
   saveDirectory : "saves/",
   maxSaveSlots : 10,
   // Future implementation?
   //autoSaveEnabled : true,
   //autoSaveInterval : 300, 
}