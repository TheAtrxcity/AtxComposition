/// @function AtxInitialiseSaveSystem
/// @description Initializes the save system and creates the save directory if it doesn't exist
/// @return {undefined}
function AtxInitialiseSaveSystem()
{
   if (!directory_exists(global.__atxSaveConfig.saveDirectory))
   {
      directory_create(global.__atxSaveConfig.saveDirectory);
   }
   global.__atxPendingLoad = 
   {
      loading : false,
      timeSource : undefined, 
      clearRoom : true,
      startTime : 0,
      endTime : 0, 
      constructCount : 0,
      data : {},
   };
   show_debug_message("AtxSaveSystem Initialised..")
}

/// @function AtxSaveGame
/// @description Saves the current game state to a JSON file
/// @param {string} _saveName Display name for this save
/// @param {real} _slotNumber Save slot number (default: 0)
/// @return {bool} True if save succeeded
function AtxSaveGame(_saveName, _slotNumber = 0)
{
   show_debug_message("AtxSaveGame: Saving Game State...");
   var _timeStart = get_timer();
   
   var _saveData = 
   {
      metaData :
      {
         saveName : _saveName,
         timeStamp : date_current_datetime(),
         slotNumber : _slotNumber,
         roomName : room_get_name(room),
         gameVersion : ATX_GAME_VERSION,
      },
      constructs : [],
   }
   
   var _saveAbleConstructs = [];
   
   with (all)
   {
      if (!variable_instance_exists(self, "manager") || !manager.enableSave) continue;

      var _constructData = 
      {
         constructName : manager.constructReference,
         savePriority : manager.savePriority,
         objectName : object_get_name(object_index),
         x : x,
         y : y,
         depth : depth,
         layer : layer_get_name(layer),
         direction : direction,
         speed : speed,
         image_index : image_index,
         image_speed : image_speed,
         image_xscale : image_xscale,
         image_yscale : image_yscale,
         image_angle : image_angle,
         image_blend : image_blend,
         image_alpha : image_alpha,
         components : {},
         metaData : manager.saveMetadata,
      };
      
      var _components = manager.GetAllComponents();
      var _componentNames = variable_struct_get_names(_components);
      var _componentCount = array_length(_componentNames);
      
      for (var _j = 0; _j < _componentCount; _j++)
      {
         var _componentName = _componentNames[_j];
         var _component = _components[$ _componentName];
         var _componentData = AtxGetSaveDataComponent(_component);
         
         variable_struct_set(_constructData.components, _componentName, _componentData);
      }
      
      array_push(_saveAbleConstructs, _constructData);
   }
   
   var _saveAbleConstructCount = array_length(_saveAbleConstructs);
   show_debug_message($"AtxSaveGame: Found {_saveAbleConstructCount} constructs to save.");
   
   array_sort(_saveAbleConstructs, function(_a, _b) 
   {
      return _a.savePriority - _b.savePriority;
   });
   
   _saveData.constructs = _saveAbleConstructs;
   
   var _jsonString = json_stringify(_saveData, true);
   
   var _fileName = global.__atxSaveConfig.saveDirectory + "save_" + string(_slotNumber) + ".json";
   var _buffer = buffer_create(string_byte_length(_jsonString) + 1, buffer_fixed, 1);
   buffer_write(_buffer, buffer_string, _jsonString);
   buffer_save(_buffer, _fileName);
   buffer_delete(_buffer);
   
   var _timeEnd = get_timer();
   var _timeTaken = (_timeEnd - _timeStart) / 1000;
   
   show_debug_message($"AtxSaveGame: Successfully saved {_saveAbleConstructCount} constructs.");
   show_debug_message($"AtxSaveGame: File: {_fileName}");
   show_debug_message($"AtxSaveGame: Time taken: {_timeTaken}ms");
   
   return true;
}

/// @function AtxClearSaveableEntities
/// @description Destroys all non-persistent entities that have save enabled
/// @return {undefined}
function AtxClearSaveableEntities()
{
   var _counter = 0;
   with (all)
   { 
      if (persistent) continue;
      if (!variable_instance_exists(self, "manager") || !manager.enableSave) continue;
      instance_destroy(self);
      _counter++;
   }
   show_debug_message($"AtxClearSaveableEntities: Constructs destroyed {_counter}.");
}

/// @function AtxLoadGame
/// @description Loads a saved game state from a JSON file
/// @param {real} _slotNumber Save slot number to load from (default: 0)
/// @param {bool} _clearRoom Whether to destroy existing saveable entities before loading (default: true)
/// @return {bool} True if load was initiated, false if failed
function AtxLoadGame(_slotNumber = 0, _clearRoom = true)
{
   show_debug_message($"AtxLoadGame: Attempting to load data from {_slotNumber}");
   global.__atxPendingLoad.startTime = get_timer();
   var _fileName = global.__atxSaveConfig.saveDirectory + "save_" + string(_slotNumber) + ".json";
   if (!file_exists(_fileName))
   {
      show_debug_message("AtxLoadGame: Trying to load from a filename that doesn't exist!")
      return false;
   }
   
   var _buffer = buffer_load(_fileName);
   var _jsonString = buffer_read(_buffer, buffer_text);
   buffer_delete(_buffer);
   var _saveData = json_parse(_jsonString);
   
   show_debug_message($"AtxLoadGame: Loading in the following data.\nSave Name: {_saveData.metaData.saveName}"
   + $"\nTime: {date_date_string(_saveData.metaData.timeStamp)} at {date_datetime_string(_saveData.metaData.timeStamp)}"
   + $"Room: {_saveData.metaData.roomName}\nConstruct Count: {array_length(_saveData.constructs)}");
   
   global.__atxPendingLoad.constructCount = array_length(_saveData.constructs);
   
   var _roomIndex = asset_get_index(_saveData.metaData.roomName);
   if (!room_exists(_roomIndex)) 
   {
      show_debug_message("AtxLoadGame: Room doesn't exist.");
      return false;
   }
   global.__atxPendingLoad.clearRoom = _clearRoom;
   global.__atxPendingLoad.data = _saveData;
   if (room != _roomIndex) 
   {
      global.__atxPendingLoad.timeSource = time_source_create(time_source_game, 3, time_source_units_frames, AtxLoadGamePhase2);
      global.__atxPendingLoad.loading = true;
      time_source_start(global.__atxPendingLoad.timeSource);
      show_debug_message("AtxLoadGame: Loading room.")
      room_goto(_roomIndex);
      return true;
   }
   AtxLoadGamePhase2();
   return true;
}

/// @function AtxLoadGamePhase2
/// @description Internal function that handles the second phase of loading after room transition
/// @return {undefined}
function AtxLoadGamePhase2()
{
   show_debug_message("AtxLoadGamePhase2: Starting Phase 2...");
   
   if (global.__atxPendingLoad.clearRoom) 
   {
      AtxClearSaveableEntities();
   }
   
   if (time_source_exists(global.__atxPendingLoad.timeSource))
   {
      time_source_destroy(global.__atxPendingLoad.timeSource);
   }
   
   show_debug_message("AtxLoadGamePhase2: Loading constructs into room.");
   var _saveData = global.__atxPendingLoad.data;
   
   if (_saveData == undefined)
   {
      show_debug_message("AtxLoadGamePhase2: Savedata is undefined. Critical error.");
      global.__atxPendingLoad = 
      {
         loading : false,
         timeSource : undefined, 
         startTime : 0,
         endTime : 0, 
         constructCount : 0,
         clearRoom : true,
         data : {},
      };
      return;
   }
   
   if (!variable_struct_exists(_saveData, "constructs"))
   {
      show_debug_message("AtxLoadGamePhase2: Savedata does not have a constructs property!");
      show_debug_message($"AtxLoadGamePhase2: content: {json_stringify(_saveData)}");
      global.__atxPendingLoad = 
      {
         loading : false,
         timeSource : undefined, 
         startTime : 0,
         endTime : 0, 
         constructCount : 0,
         clearRoom : true,
         data : {},
      };
      return;
   }
   
   var _constructsToLoad = _saveData.constructs;
   var _constructCount = array_length(_constructsToLoad);
   var _counter = 0;
   show_debug_message($"AtxLoadGamePhase2 : Found {_constructCount} constructs to load.");
   
   for (var _i = 0; _i < _constructCount; _i++)
   {
      var _construct = undefined;
      var _constructReference = _constructsToLoad[_i];
      if (_constructReference.constructName != "")
      {
         _construct = AtxSpawnConstruct(_constructReference.constructName, _constructReference.x, _constructReference.y);
         show_debug_message($"AtxLoadGamePhase2: Successfully loaded {_constructReference.constructName}");
      }
      if (_construct == undefined)
      {
         var _constructObjectIndex = asset_get_index(_constructReference.objectName);
         if (_constructObjectIndex != -1 && asset_get_type(_constructObjectIndex) == asset_object)
         {
            if (variable_struct_exists(_constructReference, "layer"))
            {
               _construct = instance_create_layer(_constructReference.x, _constructReference.y, _constructReference.layer, _constructObjectIndex);
            }
            else if (variable_struct_exists(_constructReference, "depth"))
            {
               _construct = instance_create_depth(_constructReference.x, _constructReference.y, _constructReference.depth, _constructObjectIndex);
            }
            else
            { 
               show_debug_message($"AtxLoadGamePhase2: Had to fallback to spawning at 0 depth because layer or depth were not set at index {_i}{_constructReference.constructName}");
               _construct = instance_create_depth(_constructReference.x, _constructReference.y, 0, _constructObjectIndex);
            }
         }
      }
      if (_construct == undefined) 
      {
         show_debug_message($"AtxLoadGamePhase2: Something unexpected happened when spawning constructs. Didn't spawn the construct at index {_i}{_constructReference.constructName}");
         continue;
      }
      if (!variable_instance_exists(_construct, "manager")) with (_construct) { manager = new AtxComponentManager(); }
      _construct.direction = _constructReference.direction;
      _construct.speed = _constructReference.speed;
      _construct.image_index = _constructReference.image_index;
      _construct.image_speed = _constructReference.image_speed;
      _construct.image_xscale = _constructReference.image_xscale;
      _construct.image_yscale = _constructReference.image_yscale;
      _construct.image_angle = _constructReference.image_angle;
      _construct.image_blend = _constructReference.image_blend;
      _construct.image_alpha = _constructReference.image_alpha;
      _construct.depth = _constructReference.depth;
      _construct.manager.savePriority = _constructReference.savePriority;
      _construct.manager.constructReference = _constructReference.constructName;
      _construct.manager.saveMetaData = _constructReference.metaData;
      var _componentKeys = variable_struct_get_names(_constructReference.components);
      var _componentCount = array_length(_componentKeys);
      for (var _j = 0; _j < _componentCount; _j++)
      {
         var _componentKey = _componentKeys[_j];
         var _componentData = _constructReference.components[$ _componentKey];
         if (_construct.manager.HasComponent(_componentKey))
         {
            var _component = _construct.manager.GetComponent(_componentKey);
            AtxSetSaveDataComponent(_component, _componentData);
         }
         else 
         {
            var _component = _construct.manager.AddComponent(_componentKey);
            AtxSetSaveDataComponent(_component, _componentData);
         }
      }
      _counter++;
   }
   
   var _timeTaken = (get_timer() - global.__atxPendingLoad.startTime) / 1000;
   
   show_debug_message($"AtxLoadGamePhase2: Finished loading all constructs:\nTime Taken: {_timeTaken}ms\nConstructs Loaded {_counter} out of {global.__atxPendingLoad.constructCount}");
   
   global.__atxPendingLoad = 
   {
      loading : false,
      timeSource : undefined, 
      startTime : 0,
      endTime : 0, 
      constructCount : 0,
      clearRoom : true,
      data : {},
   };
}

/// @function AtxSaveExists
/// @description Checks if a save file exists in the specified slot
/// @param {real} _slotNumber The slot number to check (default: 0)
/// @return {bool} True if save exists, false otherwise
function AtxSaveExists(_slotNumber = 0)
{
   var _fileName = global.__atxSaveConfig.saveDirectory + "save_" + string(_slotNumber) + ".json";
   if (file_exists(_fileName)) return true;
   return false;
}

/// @function AtxDeleteSave
/// @description Deletes a save file from the specified slot
/// @param {real} _slotNumber The slot number to delete (default: 0)
/// @return {bool} True if deletion succeeded, false if file didn't exist
function AtxDeleteSave(_slotNumber = 0)
{
   var _fileName = global.__atxSaveConfig.saveDirectory + "save_" + string(_slotNumber) + ".json";
   if (file_exists(_fileName))
   {
      file_delete(_fileName);
      return true;
   }
   return false;
}

/// @function AtxGetSaveMetadata
/// @description Retrieves metadata from a save file without loading the entire save
/// @param {real} _slotNumber The slot number to read (default: 0)
/// @return {struct,undefined} Metadata struct if found, undefined otherwise
function AtxGetSaveMetadata(_slotNumber = 0)
{
   var _fileName = global.__atxSaveConfig.saveDirectory + "save_" + string(_slotNumber) + ".json";
   if (file_exists(_fileName))
   {
      var _buffer = buffer_load(_fileName);
      var _jsonString = buffer_read(_buffer, buffer_text);
      buffer_delete(_buffer);
      var _jsonParsed = json_parse(_jsonString);
      if (variable_struct_exists(_jsonParsed, "metaData"))
      {
         return _jsonParsed.metaData;
      }
      return undefined;
   } 
   else 
   {
      show_debug_message($"AtxGetSaveMetadata: Save file {_slotNumber} doesn't exist.");
   }
   return undefined;
}

/// @function AtxGetSaves
/// @description Retrieves information about all save slots
/// @param {real} _saveAmount Maximum number of slots to check (default: global.__atxSaveConfig.maxSaveSlots)
/// @return {array<struct>} Array of save info structs containing slotNumber, exists, and metaData
function AtxGetSaves(_saveAmount = global.__atxSaveConfig.maxSaveSlots)
{
   var _saves = [];
   for (var _i = 0; _i < _saveAmount; _i++)
   {
      var _saveInfo = 
      {
         slotNumber : _i,
         exists : AtxSaveExists(_i),
         metaData : AtxGetSaveMetadata(_i),
      }
      array_push(_saves, _saveInfo);
   }
   return _saves;
}

/// @function AtxValidateSave
/// @description Validates a save file to check if it's corrupted or missing required data
/// @param {real} _slotNumber The slot number to validate (default: 0)
/// @return {bool} True if save is valid, false if corrupted or invalid
function AtxValidateSave(_slotNumber = 0)
{
   if (AtxSaveExists(_slotNumber))
   {
      var _fileName = global.__atxSaveConfig.saveDirectory + "save_" + string(_slotNumber) + ".json";
      var _saveData = undefined;
      try
      {
         var _buffer = buffer_load(_fileName);
         var _jsonString = buffer_read(_buffer, buffer_text);
         buffer_delete(_buffer);
         
         _saveData = json_parse(_jsonString);
      }
      catch(_error)
      {
         show_debug_message($"AtxValidateSave: An error occured while parsing the json. The following error message was left:\n{_error}");
         return false;
      }
      if (!variable_struct_exists(_saveData.metaData, "roomName"))
      {
         show_debug_message($"AtxValidateSave: Savefile missing roomName!");
         return false;
      }
      if (!variable_struct_exists(_saveData, "metaData")) 
      {
         show_debug_message($"AtxValidateSave: Savefile missing metadata!");
         return false;
      }
      if (!variable_struct_exists(_saveData, "constructs"))
      {
         show_debug_message($"AtxValidateSave: Savefile missing construct data!");
         return false;
      }
      if (!variable_struct_exists(_saveData.metaData, "saveName"))
      {
         show_debug_message($"AtxValidateSave: Savefile missing savename!");
         return false;
      }
   }
   else
   {
      show_debug_message("AtxValidateSave: Tried to validate a non existent file.")
      return false;
   }
   show_debug_message("AtxValidateSave: Savefile validated should be good to go!")
   return true;
}

/// @function AtxGetSaveDataComponent
/// @description Extracts saveable data from a component, excluding internal properties and methods
/// @param {struct.AtxComponentBase} _component The component to extract data from
/// @return {struct} Struct containing all saveable component properties
function AtxGetSaveDataComponent(_component)
{
   var _data = {}; 
   var _variables = variable_struct_get_names(_component);
   var _variableCount = array_length(_variables);
   
   for (var _i = 0; _i < _variableCount; _i++)
   {
      var _propertyName = _variables[_i];
      var _currentVariable = _component[$ _propertyName];
      
      if (is_method(_currentVariable)) continue;
      
      if (_propertyName == "owner") continue;
      if (_propertyName == "parentInstance") continue;        
      if (_propertyName == "componentManager") continue;        
      if (_propertyName == "events") continue;                 
      if (_propertyName == "queries") continue;                 
      if (_propertyName == "Step") continue;                   
      if (_propertyName == "Draw") continue;                    
      if (_propertyName == "Cleanup") continue;                
      if (_propertyName == "enabled") continue;                 
      if (_propertyName == "stepPriority") continue;           
      if (_propertyName == "drawPriority") continue;            
      if (_propertyName == "requires") continue;               
      if (string_starts_with(_propertyName, "__")) continue;    
      
      variable_struct_set(_data, _propertyName, _currentVariable);
   }                                                            
   
   return _data;                                                
}

/// @function AtxSetSaveDataComponent
/// @description Restores component data from a saved data struct
/// @param {struct.AtxComponentBase} _component The component to restore data to
/// @param {struct} _data The saved data struct to restore from
/// @return {undefined}
function AtxSetSaveDataComponent(_component, _data)             
{
   var _variables = variable_struct_get_names(_data);
   var _variableCount = array_length(_variables);
   for (var _i = 0; _i < _variableCount; _i++)
   {
      var _variableName = _variables[_i];
      var _value = _data[$ _variableName];
      
      _component[$ _variableName] = _value;
   }
}