/// @description Component Manager for managing object components with lifecycle methods, events, and queries
function AtxComponentManager(_enableSave = true, _priority = ATX_SAVE.DEFAULT) constructor
{
   parentInstance = self;
   
   savePriority = _priority;
   enableSave = _enableSave;
   constructReference = "";
   saveMetadata = {};
   
   components = {};
   
   componentKeys = [];
   componentCount = 0;
   
   stepComponents = [];
   drawComponents = [];
   cleanupComponents = [];
   
   stepNeedsSort = false;
   drawNeedsSort = false;
   
   componentTags = {};
   taggedComponents = {};
   
   
   eventMap = {};
   queryMap = {};
   
   #region Adding / Removing components
   /// @description Adds a component to the component manager.
   /// If a component with the same type already exists, it will not be added again.
   /// @param {Struct.AtxComponentBase} _component The component instance to add (must be created with 'new').
   /// @return {Struct.AtxComponentBase} Returns the added component for chaining, or undefined if component already exists.
   static AddComponent = function(_component)
   {
      var _componentKey = instanceof(_component);
      if (variable_struct_exists(components, _componentKey))
      { 
         show_debug_message("AtxComponentManager (AddComponent): Component already exists.\n");
         return;
      }
      
      if (!HasAllDependencies(_component))
      {
         var _missing = GetMissingDependencies(_component);
         show_debug_message($"AtxComponentManager (AddComponent): Couldn't add component because of missing dependencies. {_componentKey}"+
         $"needs the following dependencies:\n{_missing}");
         return undefined;
      }
      
      _component.SetParent(self);
      components[$ _componentKey] = _component;
      componentCount++;
      
      array_push(componentKeys, _componentKey);
      
      if (is_method(_component.Step))
      {
         array_push(stepComponents, _component);
         stepNeedsSort = true;
      }
      
      if (is_method(_component.Draw))
      {
         array_push(drawComponents, _component);
         drawNeedsSort = true;
      }
      
      if (is_method(_component.Cleanup))
      {
         array_push(cleanupComponents, _component);
      }
      
      var _events = struct_get_names(_component.events);
      var _eventCount = array_length(_events);
      if (_eventCount > 0)
      {
         for (var _i = 0; _i < _eventCount; _i++)
         {
            var _eventKey = _events[_i];
            if (is_method(_component.events[$ _eventKey]))
            {
               var _boundHandler = method(_component, _component.events[$ _eventKey]);
               _component.events[$ _eventKey] = _boundHandler;
               
               if (!is_array(eventMap[$ _eventKey]))
               {
                  eventMap[$ _eventKey] = [];
               }
               array_push(eventMap[$ _eventKey], _component);
            }
         }
      }
      
      var _queries = struct_get_names(_component.queries);
      var _queryCount = array_length(_queries);
      if (_queryCount > 0)
      {
         for (var _i = 0; _i < _queryCount; _i++)
         {
            var _queryKey = _queries[_i];
            if (is_method(_component.queries[$ _queryKey]))
            {
               var _boundMethod = method(_component, _component.queries[$ _queryKey]);
               _component.queries[$ _queryKey] = _boundMethod;
               if (!is_array(queryMap[$ _queryKey]))
               {
                  queryMap[$ _queryKey] = [];
               }
               array_push(queryMap[$ _queryKey], {component: _component, method: _boundMethod});
            }
         }
      }
      
      return _component;
   }

   /// @description Removes a component from the manager and cleans up all its references.
   /// Executes the component's Cleanup method if it exists before removal.
   /// @param {String} _componentKey The component type name to remove (e.g., "AtxComponentHealth").
   /// @return {Bool} Returns true if component was removed, false if it didn't exist.
   static RemoveComponent = function(_componentKey)
   {
      if (!variable_struct_exists(components, _componentKey))
      {
         show_debug_message("AtxComponentManager (RemoveComponent): The given component does not exist. Returning false.");
         return false;
      } 
      
      var _component = components[$ _componentKey];
      var _dependents = GetDependents(_componentKey);
      var _dependentCount = array_length(_dependents);
      if (_dependentCount > 0)
      {
         show_debug_message($"AtxComponentManager (AddComponent): Couldn't remove component {_componentKey} because other components depend on it."+
         $"\nThe following components depend on this component:\n{_dependents}");
         return undefined;
      }
      
      if (variable_struct_exists(taggedComponents, _componentKey))
      {
         var _tags = taggedComponents[$ _componentKey];
         var _tagCount = array_length(_tags);
         for (var _i = 0; _i < _tagCount; _i++)
         {
            var _tag = _tags[_i];
            if (variable_struct_exists(componentTags, _tag))
            {
               var _tagComponentArray = componentTags[_tag];
               var _tagIndex = array_get_index(_tagComponentArray, _componentKey);
               {
                  array_delete(_tagComponentArray, _tagIndex, 1);
                  if (array_length(_tagComponentArray) == 0) variable_struct_remove(componentTags, _tag)
               }
            }
         }
         variable_struct_remove(taggedComponents, _componentKey);
      }
      
      if (is_method(_component.Step))
      {
         var _index = array_get_index(stepComponents, _component);
         if (_index != -1) 
         {
            array_delete(stepComponents, _index, 1);
         }
      }
      
      if (is_method(_component.Draw))
      {
         var _index = array_get_index(drawComponents, _component);
         if (_index != -1) 
         {
            array_delete(drawComponents, _index, 1);
         }
      }
      
      if (is_method(_component.Cleanup))
      {
         var _index = array_get_index(cleanupComponents, _component);
         if (_index != -1) 
         {
            _component.Cleanup();
            array_delete(cleanupComponents, _index, 1);
         }
      }
      
      var _events = variable_struct_get_names(_component.events);
      for (var _i = 0; _i < array_length(_events); _i++)
      {
         if (is_array(eventMap[$ _events[_i]]))
         {
            var _index = array_get_index(eventMap[$ _events[_i]], _component);
            if (_index != -1)
            {
               array_delete(eventMap[$ _events[_i]], _index, 1);
            }
         }
      }
      
      var _queries = variable_struct_get_names(_component.queries);
      for (var _i = 0; _i < array_length(_queries); _i++)
      {
         var _queryKey = _queries[_i];
         if (is_array(queryMap[$ _queryKey]))
         {
            var _handlers = queryMap[$ _queryKey];
            for (var _j = array_length(_handlers) - 1; _j >= 0; _j--)
            {
               if (_handlers[_j].component == _component)
               {
                  array_delete(_handlers, _j, 1);
               }
            }
         }
      }
      
      variable_struct_remove(components, _componentKey);
      var _index = array_get_index(componentKeys, _componentKey);
      if (_index != -1) array_delete(componentKeys, _index, 1);
      componentCount--;
      
      return true;
   }
   #endregion
   #region Lifecycle Methods
   /// @description Executes the Step method of all registered components that have one defined.
   /// Components are executed in priority order (lowest to highest).
   /// @return {Undefined}
   static Step = function()
   {
      if (instance_exists(parentInstance))
      {
         if (stepNeedsSort)
         {
            SortStepComponents();
            stepNeedsSort = false;
         }
         
         var _stepCount = array_length(stepComponents);
         for (var _i = 0; _i < _stepCount; _i++)
         {
            if (stepComponents[_i].enabled)
            {
               stepComponents[_i].Step();
            }
         }
      }
   }
   
   /// @description Executes the Draw method of all registered components that have one defined.
   /// Components are executed in priority order (lowest to highest).
   static Draw = function()
   {
      if (instance_exists(parentInstance))
      {
         if (drawNeedsSort)
         {
            SortDrawComponents();
            drawNeedsSort = false;
         }
         
         var _drawCount = array_length(drawComponents);
         for (var _i = 0; _i < _drawCount; _i++)
         {
            if (drawComponents[_i].enabled)
            {
               drawComponents[_i].Draw();
            }
         }
      }
   }
   
   /// @description Executes the Cleanup method of all registered components that have one defined.
   /// Use this for cleanup operations like destroying data structures, surfaces, or buffers.
   /// Components are executed in the order they were added.
   static Cleanup = function()
   {
      if (instance_exists(parentInstance))
      {
         var _cleanupCount = array_length(cleanupComponents);
         for (var _i = 0; _i < _cleanupCount; _i++)
         {
            cleanupComponents[_i].Cleanup();
         }
      }
   }
   #endregion
   #region Enabling / disabling
   /// @description Enables a component
   /// @param {String} _componentKey The component type name to enable.
   /// @return {Bool} True if enabled, false if component doesn't exist.
   static EnableComponent = function(_componentKey)
   {
      var _component = GetComponent(_componentKey);
      if (_component == undefined)
      {
         show_debug_message("AtxComponentManager (EnableComponent): Couldn't find component.");
         return false;
      }
      _component.enabled = true;
      return true;
   }
   
   static EnableAllComponents = function()
   {
      for (var _i = 0; _i < componentCount; _i++)
      {
         components[$ componentKeys[_i]].enabled = true;
      }
   }
   
   static EnableAllComponentsExcept = function(_names)
   {
      if (is_array(_names))
      {
         for (var _i = 0; _i < componentCount; _i++)
         {
            if (!array_contains(_names, componentKeys[_i])) components[$ componentKeys[_i]].enabled = true;
         }
      }
      else
      {
         for (var _i = 0; _i < componentCount; _i++)
         {
            if (componentKeys[_i] != _names) components[$ componentKeys[_i]].enabled = true;
         }
      }
   }
   
   static DisableAllComponents = function()
   {
      for (var _i = 0; _i < componentCount; _i++)
      {
         components[$ componentKeys[_i]].enabled = false;
      }
   }
   
   static DisableAllComponentsExcept = function(_names)
   {
      if (is_array(_names))
      {
         for (var _i = 0; _i < componentCount; _i++)
         {
            if (!array_contains(_names, componentKeys[_i])) components[$ componentKeys[_i]].enabled = false;
         }
      }
      else
      {
         for (var _i = 0; _i < componentCount; _i++)
         {
            if (componentKeys[_i] != _names) components[$ componentKeys[_i]].enabled = false;
         }
      }
   }
   
   /// @description Disables a component
   /// @param {String} _componentKey The component type name to disable.
   /// @return {Bool} True if disabled, false if component doesn't exist.
   static DisableComponent = function(_componentKey)
   {
      var _component = GetComponent(_componentKey);
      if (_component == undefined)
      {
         show_debug_message("AtxComponentManager (DisableComponent): Couldn't find component.");
         return false;
      }
      _component.enabled = false;
      return true;
   }
   #endregion
   #region Getting Components
   /// @description Retrieves a component by its type name.
   /// Returns undefined if the component doesn't exist.
   /// @param {String} _component The component type name (e.g., "AtxComponentHealth").
   /// @return {Struct.AtxComponentBase,Undefined} The component struct if found, undefined otherwise.
   static GetComponent = function(_component)
   {
      var _componentReturn = variable_struct_exists(components, _component) ? components[$ _component] : undefined;
      return _componentReturn;
   }
   
   static GetAllComponents = function()
   {
      return components;
   }
   
   /// @description Retrieves an array of all the current component keys. 
   /// @return {Array<String>} Array of component keys.
   static GetAllComponentKeys = function()
   {
      return componentKeys;
   }
   
   /// @description Retrieves the number of assigned components.
   /// @return {Real} The number of components currently registered.
   static GetComponentCount = function()
   {
      return componentCount;
   }
   
   /// @description Checks whether a component of the specified type is registered to this manager.
   /// @param {String} _component The component type name (e.g., "AtxComponentHealth").
   /// @return {Bool} Returns true if the component exists, false otherwise.
   static HasComponent = function(_component)
   {
      return variable_struct_exists(components, _component);
   }
   
   /// @description Checks if the component manager has ALL of the specified components.
   /// Returns true only if every component in the array exists.
   /// @param {Array<String>} _names Array of component type names to check for.
   /// @return {Bool} True if all components exist, false if any are missing.
   static HasTheseComponents = function(_names = [])
   {
      var _nameCount = array_length(_names)
      if (_nameCount == 0) return true;
      if (_nameCount > componentCount) return false;
      for (var _i  = 0; _i < _nameCount; _i++)
      {
         if (!variable_struct_exists(components, _names[_i])) return false;
      }
      return true;
   }
   
   /// @description Checks if the component manager has ANY of the specified components.
   /// @param {Array<String>} _names Array of component type names to check for.
   /// @return {Bool} True if at least one component exists, false if none exist.
   static HasAnyOfTheseComponents = function(_names = [])
   {
      var _nameCount = array_length(_names)
      if (_nameCount == 0) return false;
      for (var _i  = 0; _i < _nameCount; _i++)
      {
         if (variable_struct_exists(components, _names[_i])) return true;
      }
      return false;
   }
   
   /// @description Returns all components that have registered for a specific event.
   /// @param {String} _eventName The event name to check.
   /// @return {Array<Struct.AtxComponentBase>} Array of components, or empty array if none.
   static GetComponentsWithEvent = function(_eventName)
   {
      if (is_array(eventMap[$ _eventName]))
      {
         return eventMap[$ _eventName];
      }
      return [];
   }
   #endregion
   #region Sorting
   static GetStepPriority = function(_componentKey)
   {
      var _component = GetComponent(_componentKey);
      if (_component == undefined)
      {
         show_debug_message("AtxComponentManager (GetStepPriority): Couldn't find component returning undefined.");
         return undefined;
      }
      return _component.stepPriority;
   }
   
   static GetDrawPriority = function(_componentKey)
   {
      var _component = GetComponent(_componentKey);
      if (_component == undefined)
      {
         show_debug_message("AtxComponentManager (GetDrawPriority): Couldn't find component returning undefined.");
         return undefined;
      }
      return _component.drawPriority;
   }
   
   static SetStepPriority = function(_componentKey, _priority)
   {
      var _component = GetComponent(_componentKey);
      if (_component == undefined)
      {
         show_debug_message("AtxComponentManager (SetStepPriority): Couldn't find component returning false.")
         return false;
      }
      
      _component.stepPriority = _priority;
      if (is_method(_component.Step))
      {
         stepNeedsSort = true;
      }
      
      return true;
   }
   
   static SetDrawPriority = function(_componentKey, _priority)
   {
      var _component = GetComponent(_componentKey);
      if (_component == undefined)
      {
         show_debug_message("AtxComponentManager (SetDrawPriority): Couldn't find component returning false.")
         return false;
      }
      
      _component.drawPriority = _priority;
      if (is_method(_component.Draw))
      {
         drawNeedsSort = true;
      }
      
      return true;
   }
   
   static SetBothPriority = function(_componentKey, _priority)
   {
      var _stepCheck = SetStepPriority(_componentKey, _priority);
      if (_stepCheck == false) {show_debug_message("AtxComponentManager(SetBothPriority): Setting Step Failed")}
      var _drawCheck = SetDrawPriority(_componentKey, _priority);
      if (_drawCheck == false) {show_debug_message("AtxComponentManager(SetBothPriority): Setting Draw Failed")}
      if (!_stepCheck || !_drawCheck) return false; 
         
      return true;   
   }
   
   /// @description Sorts step components by priority (low to high).
   /// Now only sorts component array - 50% less memory usage!
   static SortStepComponents = function()
   {
      var _stepComponentCount = array_length(stepComponents);
      if (_stepComponentCount <= 1) return;
         
      var _indices = [];
      for (var _i = 0; _i < _stepComponentCount; _i++) 
      {
         _indices[_i] = _i;
      }
      
      array_sort(_indices, function(_a, _b) 
      {
         var _compA = stepComponents[_a].stepPriority;
         var _compB = stepComponents[_b].stepPriority;
         return (_compA - _compB);
      })
      
      var _newStepComponents = array_create(_stepComponentCount);
      
      for (var _i = 0; _i < _stepComponentCount; _i++)
      {
         _newStepComponents[_i] = stepComponents[_indices[_i]];
      }
      
      stepComponents = _newStepComponents;
   }
   
   /// @description Sorts draw components by priority (low to high).
   static SortDrawComponents = function()
   {
      var _drawComponentCount = array_length(drawComponents);
      if (_drawComponentCount <= 1) return;
         
      var _indices = [];
      for (var _i = 0; _i < _drawComponentCount; _i++) 
      {
         _indices[_i] = _i;
      }
      
      array_sort(_indices, function(_a, _b) 
      {
         var _compA = drawComponents[_a].drawPriority;
         var _compB = drawComponents[_b].drawPriority;
         return (_compA - _compB);
      })
      
      var _newDrawComponents = array_create(_drawComponentCount);
      
      for (var _i = 0; _i < _drawComponentCount; _i++)
      {
         _newDrawComponents[_i] = drawComponents[_indices[_i]];
      }
      
      drawComponents = _newDrawComponents;
   }
   
   // Legacy function names for compatibility
   static SortStepMethods = SortStepComponents;
   static SortDrawMethods = SortDrawComponents;
   #endregion
   #region TriggerEvent
   /// @description Triggers an event across all components that have registered a handler for it.
   /// Events allow components to communicate without direct references to each other.
   /// All components with a matching event handler will execute in the order they were added.
   /// @param {String} _eventName The name of the event to trigger (e.g., "damage", "collect", "interact").
   /// @param {Any} _eventData The data to pass to all event handlers. Can be any type (struct, array, number, etc.).
   /// @return {Undefined}
   static TriggerEvent = function(_eventName, _eventData, _componentKey = undefined)
   {
      if (is_array(eventMap[$ _eventName]))
      {
         var _eventCount = array_length(eventMap[$ _eventName]);
         if (_componentKey == undefined)
         {
            for (var _i = 0; _i < _eventCount; _i++)
            {
               var _component = eventMap[$ _eventName][_i]; 
               _component.events[$ _eventName](_eventData);
            }
         }
         else
         {
            var _component = GetComponent(_componentKey);
            if (_component != undefined && variable_struct_exists(_component.events, _eventName))
            {
                _component.events[$ _eventName](_eventData);
            }
         }
      }
   }
   #endregion
   #region Querying
   static Query = function(_queryName, _data = {})
   {
      if (!variable_struct_exists(queryMap, _queryName))
      {
         show_debug_message("AtxComponentManager (Query): Couldn't find query.")
         return undefined;
      }
      var _result = undefined;
      var _handlers = queryMap[$ _queryName];
      var _queryCount = array_length(_handlers);
      for (var _i = 0; _i < _queryCount; _i++)
      {
         var _handler = _handlers[_i];
         var _component = _handler.component;
         if (!_component.enabled) continue;
         var _method = _handler.method;
         var _returnValue = _method(_data);
         if (_returnValue != undefined) _result = _returnValue; 
      }
      return _result;
   }
   static QueryReduce = function(_queryName, _initialValue, _data = {})
   {
      if (!variable_struct_exists(queryMap, _queryName))
      {
         show_debug_message("AtxComponentManager (QueryReduce): Couldn't find query.")
         return _initialValue;
      }
      var _accumulator = _initialValue;
      var _handlers = queryMap[$ _queryName];
      var _queryCount = array_length(_handlers);
      for (var _i = 0; _i < _queryCount; _i++)
      {
         var _handler = _handlers[_i];
         var _component = _handler.component;
         if (!_component.enabled) continue;
         var _method = _handler.method;
         _data.accumulator = _accumulator;
         var _returnValue = _method(_data);
         if (_returnValue != undefined) _accumulator = _returnValue; 
      }
      
      return _accumulator;
   }
   #endregion
   #region Tagging
   static AddTag = function(_componentKey, _tag)
   {
      if (!HasComponent(_componentKey))
      {
         show_debug_message($"AtxComponentManager (AddTag): Manager does not have component {_componentKey}. Returning False.");
         return false;
      }
      
      if (!variable_struct_exists(componentTags, _tag))
      {
         componentTags[$ _tag] = [];
      }
      
      if (array_contains(componentTags[$ _tag], _componentKey))
      {
         show_debug_message($"AtxComponentManager (AddTag): Component {_componentKey} is already tagged. Returning False.");
         return false;
      }
      array_push(componentTags[$ _tag], _componentKey);
      
      if (!variable_struct_exists(taggedComponents, _componentKey))
      {
         taggedComponents[$ _componentKey] = [];
      }
      
      if (array_contains(taggedComponents[$ _componentKey], _tag))
      {
         show_debug_message($"AtxComponentManager (AddTag): Component {_componentKey} is already tagged. But didn't exist in TaggedComponents (critical). Returning False.");
         return false;
      }
      array_push(taggedComponents[$ _componentKey], _tag);
      
      return true;
   }
   /// @description Returns an array with references to the components with the tags.
   /// Caution: these are REFERENCES make sure you don't accidentally edit any of values. 
   static GetComponentsWithTag = function(_tag)
   {
      if (!variable_struct_exists(componentTags, _tag)) 
      {
         show_debug_message($"AtxComponentManager (GetComponentsWithTag): No components exist with tag {_tag}.")
         return [];
      }
      return componentTags[$ _tag];
   }
   static TriggerEventsWithTag = function(_tag, _eventKey, _data)
   {
      var _componentsWithTag = GetComponentsWithTag(_tag);
      var _componentCount = array_length(_componentsWithTag);
      if (_componentCount == 0) 
      {
         show_debug_message($"AtxComponentManager (TriggerEventsWithTag): No component found with tag {_tag}.")
         return;
      }
      for (var _i = 0; _i < _componentCount; _i++)
      {
         var _componentKey = _componentsWithTag[_i];
         TriggerEvent(_eventKey, _data, _componentKey);
      }
   }
   static RemoveTag = function(_componentKey, _tag)
   {
      if (!HasComponent(_componentKey))
      {
         show_debug_message($"AtxComponentManager (RemoveTag): Couldn't find component {_componentKey}.");
         return false;
      }
      if (!variable_struct_exists(taggedComponents, _componentKey))
      {
          show_debug_message($"AtxComponentManager (RemoveTag): Component {_componentKey} does not have any tags.");
          return false;
      }
      var _componentTagArray = taggedComponents[$ _componentKey];
      
      if (!array_contains(_componentTagArray, _tag))
      {
         show_debug_message($"AtxComponentManager (RemoveTag): Couldn't find tag {_tag} associated with component {_componentKey}.");
         return false;
      }
      
      if (!variable_struct_exists(componentTags, _tag))
      {
         show_debug_message($"AtxComponentManager (RemoveTag): Critical array missmatch, found component and tag in taggedComponents but not in componentTags.");
         return false;
      }
      var _tagComponentArray = componentTags[$ _tag];
      
      var _tagIndex = array_get_index(_tagComponentArray, _componentKey);
      if (_tagIndex != -1) array_delete(_tagComponentArray, _tagIndex, 1);
      if (array_length(_tagComponentArray) == 0) variable_struct_remove(componentTags, _tag);   
      
      var _componentIndex = array_get_index(_componentTagArray, _tag);   
      if (_componentIndex != -1) array_delete(_componentTagArray, _componentIndex, 1);
      if (array_length(_componentTagArray) == 0) variable_struct_remove(taggedComponents, _componentKey); 
      
      return true;  
   }     
   static HasTag = function(_componentKey, _tag)
   {
      return (HasComponent(_componentKey) && variable_struct_exists(taggedComponents, _componentKey) && array_contains(taggedComponents[$ _componentKey], _tag));
   }
   /// @description Returns an array of tags associated with the component.
   /// CAUTION: Take caution this returns an array of REFERENCES which means they are editable.
   static GetComponentTags = function(_componentKey)
   { 
      if (!HasComponent(_componentKey))
      {
         show_debug_message($"AtxComponentManager (GetComponentTags): Couldn't find component {_componentKey}.");
         return [];
      }
      if (!variable_struct_exists(taggedComponents, _componentKey))
      {
         return [];
      }
      return taggedComponents[$ _componentKey];
   }
   static EnableComponentsByTag = function(_tag)
   {
      var _componentsWithTag = GetComponentsWithTag(_tag);
      var _componentCount = array_length(_componentsWithTag);
      if (_componentCount == 0) return 0;
      var _counter = 0;
      for (var _i = 0; _i < _componentCount; _i++)
      {
         EnableComponent(_componentsWithTag[_i]);
         _counter++
      }
      return _counter;
   }
   static DisableComponentsByTag = function(_tag)
   {
      var _componentsWithTag = GetComponentsWithTag(_tag);
      var _componentCount = array_length(_componentsWithTag);
      if (_componentCount == 0) return 0;
      var _counter = 0;
      for (var _i = 0; _i < _componentCount; _i++)
      {
         DisableComponent(_componentsWithTag[_i]);
         _counter++
      }
      return _counter;
   }
   static AddTags = function(_componentKey, _tagArray)
   {
      if (!HasComponent(_componentKey)) return 0;
      var _tagCount = array_length(_tagArray);
      var _count = 0;
      for (var _i = 0; _i < _tagCount; _i++)
      {
         if (AddTag(_componentKey, _tagArray[_i])) _count++;
      }
      return _count;
   }
   static GetTagCount = function(_tag)
   {
      if (!variable_struct_exists(componentTags, _tag)) return 0;
         
      return (array_length(componentTags[$ _tag]));
   }
   static GetAllTags = function()
   {
      return struct_get_names(componentTags);
   }
   static QueryByTag = function(_tag, _queryName, _data)
   {
      if (!variable_struct_exists(componentTags, _tag))
      {
         show_debug_message($"AtxComponentManager (QueryByTag): Tag {_tag} has no components.");
         return [];
      }
      var _componentsWithTag = GetComponentsWithTag(_tag);
      var _componentCount = array_length(_componentsWithTag);
      if (_componentCount == 0) return [];
         
      var _results = [];
      for (var _i = 0; _i < _componentCount; _i++)
      {
         var _componentKey =  _componentsWithTag[_i];
         var _component = GetComponent(_componentKey);
         if (_component == undefined || !_component.enabled || !variable_struct_exists(_component.queries, _queryName)) continue;
         var _query = _component.queries[$ _queryName](_data);
         if (_query != undefined) array_push(_results, _query);
      }
      
      return _results;
   }
   static QueryReduceByTag = function(_tag, _queryName, _initialValue, _data = {})
   {
      if (!variable_struct_exists(componentTags, _tag))
      {
         show_debug_message($"AtxComponentManager (QueryReduceByTag): Tag {_tag} has no components.");
         return _initialValue;
      }
      var _componentsWithTag = GetComponentsWithTag(_tag);
      var _componentCount = array_length(_componentsWithTag);
      if (_componentCount == 0) return _initialValue;
         
      var _accumulator = _initialValue;
      for (var _i = 0; _i < _componentCount; _i++)
      {
         var _componentKey =  _componentsWithTag[_i];
         var _component = GetComponent(_componentKey);
         if (_component == undefined || !_component.enabled || !variable_struct_exists(_component.queries, _queryName)) continue; 
            
         _data.accumulator = _accumulator;
         var _query = _component.queries[$ _queryName](_data);
         if (_query != undefined) _accumulator = _query;   
      }
      return _accumulator;
   }
   #endregion
   #region Helper functions
   /// @description Internal helper - converts component reference to key
   /// Supports: component instance OR class name string
   /// @param {Struct,String} _componentOrKey Component instance or class name
   /// @return {String} Component key or undefined
   static ResolveComponentKey = function(_componentOrKey)
   {
      if (is_struct(_componentOrKey))
      {
          return instanceof(_componentOrKey);
      }

      if (is_string(_componentOrKey))
      {
         for (var _i = 0; _i < array_length(componentKeys); _i++)
         {
            var _key = componentKeys[_i];
            if (string_pos(_componentOrKey, _key) == 1)
            { 
               return _key;
            }
         }
         show_debug_message($"AtxComponentManager (ResolveComponentKey): Could not find component '{_componentOrKey}'.");
        return undefined;
      }
      show_debug_message("AtxComponentManager (ResolveComponentKey): Invalid parameter type. Expected component or string.");
      return undefined;
   }
   #endregion
   #region Component Dependencies
   static GetMissingDependencies = function(_component)
   {
      var _missing = [];
      
      var _requiredComponentCount = array_length(_component.requires);
      if (_requiredComponentCount == 0) return [];
         
      for (var _i = 0; _i < _requiredComponentCount; _i++)
      {
         var _currentRequiredComponent = _component.requires[_i];
         if (HasComponent(_currentRequiredComponent)) continue;
            
         array_push(_missing, _currentRequiredComponent);
      }
      
      return _missing;
   }
   static HasAllDependencies = function(_component)
   {
      var _dependencyCount = array_length(_component.requires);
      if (_dependencyCount == 0) return true;
         
      if (HasTheseComponents(_component.requires)) return true;
         
      return false;
   }
   static GetDependents = function(_componentKey)
   {
      var _dependents = [];
      for (var _i = 0; _i < componentCount; _i++)
      {
         var _currentComponent = components[$ componentKeys[_i]];
         var _requiredComponents = array_length(_currentComponent.requires);
         if (_requiredComponents == 0) continue;
            
         if (array_contains(_currentComponent.requires, _componentKey)) array_push(_dependents, instanceof(_currentComponent));
      }
      return _dependents;
   }
   #endregion
}