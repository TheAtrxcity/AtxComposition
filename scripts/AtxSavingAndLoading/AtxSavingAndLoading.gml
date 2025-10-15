function AtxInitialiseSaveSystem()
{
   if (!directory_exists(global.__atxSaveConfig.saveDirectory))
   {
      directory_create(global.__atxSaveConfig.saveDirectory);
   }
   show_debug_message("AtxSaveSystem Initialised..")
}
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
function AtxSetSaveDataComponent(_component, _data)             
{
   var _variables = variable_struct_get_names(_data);
   var _variableCount = array_length(_variables);
   for (var _i = 0; _i < _variableCount; _i++)
   {
      variable_struct_set(_component, _variables[_i], _data[_variables[_i]]);
   }
}
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
      globalData : {}, 
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
   
   array_sort(_saveAbleConstructs, function(_a, _b) {
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
   var _timeTaken = (_timeEnd - _timeStart) / 1000; // Convert to milliseconds
   
   show_debug_message($"AtxSaveGame: Successfully saved {_saveAbleConstructCount} constructs.");
   show_debug_message($"AtxSaveGame: File: {_fileName}");
   show_debug_message($"AtxSaveGame: Time taken: {_timeTaken}ms");
   
   return true;
}
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
function AtxLoadGame(_slotNumber = 0, _clearRoom = true)
{
   show_debug_message($"AtxLoadGame: Attempting to load data from {_slotNumber}");
   var _startTime = get_timer();
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
   
   show_debug_message($"AtxLoadGame: Loading in the following data.\nSave Name: {_saveData.metaData.savename}"
   +$"\nTime: {date_date_string(_saveData.metaData.timeStamp)} at {date_datetime_string(_saveData.metaData.timeStamp)}"
   +$"Room: {_saveData.metaData.roomName}\nConstruct Count: {array_length(_saveData.constructs)}");
   
   var _roomIndex = asset_get_index(_saveData.metaData.roomName);
   if (!room_exists(_roomIndex)) 
   {
      show_debug_message("AtxLoadGame: Room doesn't exist.");
      return false;
   }
   if (room != _roomIndex) 
   {
      room_goto(_roomIndex);
      show_debug_message("AtxLoadGame: Loading room.")
   }
   if (_clearRoom) 
   {
      AtxClearSaveableEntities();
   }