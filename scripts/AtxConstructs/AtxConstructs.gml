global.__atxConstructRegistry = {};

/// @function AtxCreateConstruct
/// @description Register a new construct (entity template) in the system
/// @param {string} _constructName Unique identifier for this construct
/// @param {struct} _config Configuration struct containing object, layer/depth, components, and tags
/// @return {bool} True if construct was created successfully, false otherwise
function AtxCreateConstruct(_constructName, _config = {})
{
   if (!is_string(_constructName))
   {
      show_debug_message("AtxCreateConstruct: A construct name needs to be a string.");
      return false;
   }
   show_debug_message($"Initialising {_constructName}...");
   
   if (!variable_struct_exists(_config, "object"))
   {
      show_debug_message("AtxCreateConstruct: Config is missing an object field.");
      return false;
   }
   
   if (!variable_struct_exists(_config, "layer") && !variable_struct_exists(_config, "depth"))
   {
      show_debug_message("AtxCreateConstruct: Config is missing a layer or depth field.");
      return false;
   }
   
   if (is_string(_config.object))
   {
      var _object = asset_get_index(_config.object);
      if (_object == -1)
      { 
         show_debug_message($"AtxCreateConstruct: Couldn't find object {_config.object}");
         return false;
      }
      _config.object = _object;
   }

   if (!variable_struct_exists(_config, "config"))
   {
       _config.config = {};
   }
      
   if (!variable_struct_exists(_config.config, "components"))
   {
      _config.config.components = {};
   }
   
   if (!variable_struct_exists(_config.config, "tags"))
   {
      _config.config.tags = {};
   }
   
   struct_set(global.__atxConstructRegistry, _constructName, _config);
   
   show_debug_message($"AtxCreateConstruct: Succesfully added {_constructName} to construct registry!\n");
   return true;
}

/// @function AtxCreateComponentFromConfig
/// @description Creates a component instance from a configuration struct
/// @param {string} _componentName The name of the component constructor function
/// @param {struct} _componentConfig Configuration struct with property values to set
/// @return {struct.AtxComponentBase,undefined} The created component instance, or undefined if failed
function AtxCreateComponentFromConfig(_componentName, _componentConfig)
{
   var _componentReference = variable_global_get(_componentName);
   if (_componentReference == -1) 
   {
      show_debug_message($"AtxCreateComponentFromConfig: {_componentName} does not exist or is not a script.")
      return undefined;
   }
   var _component = new _componentReference();
   var _properties = struct_get_names(_componentConfig);
   var _propertyCount = array_length(_properties);
   for (var _i = 0; _i < _propertyCount; _i++)
   {
      variable_struct_set(_component, _properties[_i], _componentConfig[$ _properties[_i]])
   }
   return _component;
}

/// @function AtxSpawnConstruct
/// @description Spawn an construct from a registered construct template
/// @param {string} _constructName The name of the construct to spawn
/// @param {real} _x The x position to spawn at
/// @param {real} _y The y position to spawn at
/// @param {string,real} _layerOrDepthOverride Optional layer name or depth value to override construct settings
/// @param {struct} _overrides Optional struct containing component property overrides
/// @return {Id.Instance,undefined} The spawned instance, or undefined if failed
function AtxSpawnConstruct(_constructName, _x, _y, _layerOrDepthOverride = undefined, _overrides = undefined)
{
   if (!variable_struct_exists(global.__atxConstructRegistry, _constructName))
   {
      show_debug_message($"AtxSpawnConstruct: Can not find {_constructName} inside the construct registry.");
      return undefined;
   }
   var _construct = global.__atxConstructRegistry[$ _constructName];
   var _constructInstance = variable_struct_exists(_construct, "object") ? _construct[$ "object"] : __atxConstructParent;
   var _constructInstanceReference = undefined;
   var _depth = undefined;
   var _layer = undefined;
   if (_layerOrDepthOverride != undefined)
   {
      if (is_real(_layerOrDepthOverride))
      {
         _depth = _layerOrDepthOverride;
      }
      if (is_string(_layerOrDepthOverride))
      {
         var _layerId = layer_get_id(_layerOrDepthOverride);
         _layer = _layerId != -1 ? _layerId : undefined;
      }
   }
   else
   {
      if (variable_struct_exists(_construct, "depth"))
      {
         _depth = _construct.depth;
      }
      else if (variable_struct_exists(_construct, "layer"))
      {
         var _layerId = layer_get_id(_construct.layer);
         _layer = _layerId != -1 ? _layerId : undefined;
      }
   }
   
   if (_depth != undefined)
   {
      _constructInstanceReference = instance_create_depth(_x, _y, _depth, _constructInstance);
   }
   else if (_layer != undefined) 
   { 
      _constructInstanceReference = instance_create_layer(_x, _y, _layer, _constructInstance);
   }
   else
   {
      show_debug_message($"AtxSpawnConstruct: No layer or Depth was found for {_constructName}.")
      return undefined;
   }
      
   if (!variable_instance_exists(_constructInstanceReference, "manager"))
   {
      _constructInstanceReference.manager = new AtxComponentManager();
   }
   
   _constructInstanceReference.manager.constructReference = _constructName;
   
   if (variable_instance_exists(_construct, "savePriority"))
   {
      _constructInstanceReference.manager.savePriority = _construct.savePriority;
   }
   
   var _componentKeys = variable_struct_get_names(_construct.config.components);
   var _componentCount = array_length(_componentKeys);
   
   for (var _i = 0; _i < _componentCount; _i++)
   {
      var _currentComponentKey = _componentKeys[_i];
      var _currentConfig = _construct.config.components[$ _currentComponentKey];
      var _finalConfig = {};
      var _configKeys = variable_struct_get_names(_currentConfig);
      for (var _j = 0; _j < array_length(_configKeys); _j++)
      {
         var _key = _configKeys[_j];
         _finalConfig[$ _key] = _currentConfig[$ _key];
      }
      
      if (_overrides != undefined && variable_struct_exists(_overrides, _currentComponentKey))
      {
         var _overrideConfig = _overrides[$ _currentComponentKey];
         var _overrideKeys = variable_struct_get_names(_overrideConfig);
         var _overrideKeyCount = array_length(_overrideKeys);
         
         for (var _j = 0; _j < _overrideKeyCount; _j++)
         {
            var _overrideKey = _overrideKeys[_j];
            var _overrideValue = _overrideConfig[$ _overrideKey];
            _finalConfig[$ _overrideKey] = _overrideValue;
         }
      }
      
      var _currentComponent = AtxCreateComponentFromConfig(_currentComponentKey, _finalConfig);
      _constructInstanceReference.manager.AddComponent(_currentComponent);
   }
   
   if (variable_struct_exists(_construct.config, "tags"))
   {
      var _taggedComponents = variable_struct_get_names(_construct.config.tags);
      var _taggedComponentCount = array_length(_taggedComponents);
      for (var _i = 0; _i < _taggedComponentCount; _i++)
      {
         var _componentKey = _taggedComponents[_i];
         var _tags = _construct.config.tags[$ _componentKey];
         _constructInstanceReference.manager.AddTags(_componentKey, _tags);
      }
   }
   return _constructInstanceReference;
}

#region Helpers

/// @function AtxGetConstruct
/// @description Retrieves a construct configuration from the registry
/// @param {string} _constructName The name of the construct to retrieve
/// @return {struct,undefined} The construct configuration struct, or undefined if not found
function AtxGetConstruct(_constructName)
{
   if (AtxConstructExists(_constructName)) return (global.__atxConstructRegistry[$ _constructName])
}

/// @function AtxGetAllConstructs
/// @description Returns an array of all registered construct names
/// @return {array<string>} Array of construct names
function AtxGetAllConstructs()
{
   return (struct_get_names(global.__atxConstructRegistry));
}

/// @function AtxConstructExists
/// @description Checks if a construct exists in the registry
/// @param {string} _constructName The name of the construct to check
/// @return {bool} True if construct exists, false otherwise
function AtxConstructExists(_constructName)
{
   if (!variable_struct_exists(global.__atxConstructRegistry, _constructName))
   {
      show_debug_message($"AtxConstructExists: Could not find construct {_constructName} inside the construct registry.");
      return false;
   }
   return true;
}

/// @function AtxDeleteConstruct
/// @description Removes a construct from the registry
/// @param {string} _constructName The name of the construct to delete
/// @return {bool} True if construct was deleted, false if it didn't exist
function AtxDeleteConstruct(_constructName)
{
   if (!AtxConstructExists(_constructName)) return false; 
      
   variable_struct_remove(global.__atxConstructRegistry, _constructName);
   return true;
}

/// @function AtxSaveConstructsToFile
/// @description Saves all registered constructs to a JSON file
/// @param {string} _fileName The file path to save to
/// @return {undefined}
function AtxSaveConstructsToFile(_fileName)
{
   var _saveData = {};
   var _constructKeys = variable_struct_get_names(global.__atxConstructRegistry);
   var _constructKeyCount = array_length(_constructKeys);
   
   for (var _i = 0; _i < _constructKeyCount; _i++)
   {
      var _construct = global.__atxConstructRegistry[$ _constructKeys[_i]];
      var _constructConfig = variable_clone(_construct);
      var _objectName = "";
      if (variable_struct_exists(_constructConfig, "object"))
      {
         _objectName = object_get_name(_constructConfig.object);
      }
      _constructConfig.object = _objectName;
      variable_struct_set(_saveData, _constructKeys[_i], _constructConfig);
   }
   
   var _jsonString = json_stringify(_saveData, true);
   var _buffer = buffer_create(string_byte_length(_jsonString) + 1, buffer_fixed, 1);
   buffer_write(_buffer, buffer_string, _jsonString);
   buffer_save(_buffer, _fileName);
   buffer_delete(_buffer);
   show_debug_message($"AtxSaveConstructsToFile: Saved {_constructKeyCount} constructs to {_fileName}.");
}

/// @function AtxLoadConstructsFromFile
/// @description Loads constructs from a JSON file into the registry
/// @param {string} _fileName The file path to load from
/// @param {bool} _clearExisting Whether to clear existing constructs before loading
/// @return {undefined}
function AtxLoadConstructsFromFile(_fileName, _clearExisting = true)
{
   if (!file_exists(_fileName))
   {
      show_debug_message($"AtxLoadConstructsFromFile: Can not find a file with {_fileName}.");
      return;
   }
   
   var _buffer = buffer_load(_fileName);
   var _jsonString = buffer_read(_buffer, buffer_text);
   buffer_delete(_buffer);
   var _parsedData = json_parse(_jsonString);
   
   if (_clearExisting) global.__atxConstructRegistry = {};
      
   var _constructKeys = variable_struct_get_names(_parsedData);
   var _constructKeyCount = array_length(_constructKeys);
   
   for (var _i = 0; _i < _constructKeyCount; _i++)
   {
      AtxCreateConstruct(_constructKeys[_i], _parsedData[$ _constructKeys[_i]])
   }
   show_debug_message($"AtxLoadConstructsFromFile: Loaded {_constructKeyCount} constructs from {_fileName}.");
}

#endregion