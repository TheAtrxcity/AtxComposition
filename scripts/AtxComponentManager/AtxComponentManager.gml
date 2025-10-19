/// @function AtxComponentManager
/// @description Component Manager for managing object components with lifecycle methods, events, and queries
/// @param _caller The instance calling this constructor
/// @param {bool} _enableSave Whether this construct should be saved to disk
/// @param {real} _priority Save priority for load order (lower numbers load first)
/// @return {struct.AtxComponentManager}
function AtxComponentManager(_caller, _enableSave = true, _priority = ATX_SAVE.DEFAULT) constructor
{
   parentInstance = _caller;
   
   savePriority = _priority;
   enableSave = _enableSave;
   constructReference = "";
   saveMetadata = {};
   
   components = {};
   
   componentKeys = [];
   componentCount = 0;
   
   stepComponents = [];
   drawComponents = [];
   drawGUIComponents = [];
   cleanupComponents = [];
   
   stepNeedsSort = false;
   drawNeedsSort = false;
   drawGUINeedsSort = false;
   
   componentTags = {};
   taggedComponents = {};
   
   eventMap = {};
   queryMap = {};
   
   #region Adding / Removing components
   
   /// @description Adds a component to the component manager
   /// @param {struct.AtxComponentBase} _component The component instance to add (must be created with 'new')
   /// @param {struct} _overrides Optional struct containing property overrides to apply to the component
   /// @return {struct.AtxComponentBase} Returns the added component for chaining, or undefined if component already exists
   static AddComponent = function(_component, _overrides = undefined)
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
         show_debug_message($"AtxComponentManager (AddComponent): {parentInstance.object_index}"+
         "\nCouldn't add component because of missing dependencies. Is order wrong or are components missing?"+
         $"\n{_componentKey} needs the following dependencies:\n{_missing}");
         return undefined;
      }
      
      _component.SetParent(self);
      
      if (_overrides != undefined && is_struct(_overrides))
      {
         var _overrideKeys = variable_struct_get_names(_overrides);
         var _overrideCount = array_length(_overrideKeys);
         for (var _i = 0; _i < _overrideCount; _i++)
         {
            var _key = _overrideKeys[_i];
            _component[$ _key] = _overrides[$ _key];
         }
      }
      
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
      
      if (is_method(_component.DrawGUI))
      {
         array_push(drawGUIComponents, _component);
         drawGUINeedsSort = true;
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
   
   /// @description Removes a component from the manager and cleans up all its references
   /// @param {string} _componentKey The component type name to remove (e.g., "AtxComponentHealth")
   /// @return {bool} Returns true if component was removed, false if it didn't exist
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
         show_debug_message($"AtxComponentManager (RemoveComponent): Couldn't remove component {_componentKey} because other components depend on it." +
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
               array_delete(_tagComponentArray, _tagIndex, 1);
               if (array_length(_tagComponentArray) == 0) variable_struct_remove(componentTags, _tag)
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
      
      if (is_method(_component.DrawGUI))
      {
         var _index = array_get_index(drawGUIComponents, _component);
         if (_index != -1) 
         {
            array_delete(drawGUIComponents, _index, 1);
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
      
      delete _component;
      
      return true;
   }
   
   #endregion
   
   #region Lifecycle Methods
   
   /// @description Executes the Step method of all registered components that have one defined
   /// @return {undefined}
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
   
   /// @description Executes the Draw method of all registered components that have one defined
   /// @return {undefined}
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
   
   /// @description Executes the DrawGUI method of all registered components that have one defined
   /// @return {undefined}
   static DrawGUI = function()
   {
      if (instance_exists(parentInstance))
      {
         if (drawGUINeedsSort)
         {
            SortDrawGUIComponents();
            drawGUINeedsSort = false;
         }
         
         var _drawGUICount = array_length(drawGUIComponents);
         for (var _i = 0; _i < _drawGUICount; _i++)
         {
            if (drawGUIComponents[_i].enabled)
            {
               drawGUIComponents[_i].DrawGUI();
            }
         }
      }
   }
   
   /// @description Executes the Cleanup method of all registered components that have one defined
   /// @return {undefined}
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
   /// @param {string} _componentKey The component type name to enable
   /// @return {bool} True if enabled, false if component doesn't exist
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
   
   /// @description Enables all components in the manager
   /// @return {undefined}
   static EnableAllComponents = function()
   {
      for (var _i = 0; _i < componentCount; _i++)
      {
         components[$ componentKeys[_i]].enabled = true;
      }
   }
   
   /// @description Enables all components except the specified ones
   /// @param {string,array<string>} _names Single component name or array of component names to exclude
   /// @return {undefined}
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
   
   /// @description Disables all components in the manager
   /// @return {undefined}
   static DisableAllComponents = function()
   {
      for (var _i = 0; _i < componentCount; _i++)
      {
         components[$ componentKeys[_i]].enabled = false;
      }
   }
   
   /// @description Disables all components except the specified ones
   /// @param {string,array<string>} _names Single component name or array of component names to exclude
   /// @return {undefined}
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
   /// @param {string} _componentKey The component type name to disable
   /// @return {bool} True if disabled, false if component doesn't exist
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
   
   /// @description Retrieves a component by its type name
   /// @param {string} _component The component type name (e.g., "AtxComponentHealth")
   /// @return {struct.AtxComponentBase,undefined} The component struct if found, undefined otherwise
   static GetComponent = function(_component)
   {
      var _componentReturn = variable_struct_exists(components, _component) ? components[$ _component] : undefined;
      return _componentReturn;
   }
   
   /// @description Retrieves all components registered to this manager
   /// @return {struct} Struct containing all components keyed by their type names
   static GetAllComponents = function()
   {
      return components;
   }
   
   /// @description Retrieves an array of all the current component keys
   /// @return {array<string>} Array of component keys
   static GetAllComponentKeys = function()
   {
      return componentKeys;
   }
   
   /// @description Retrieves the number of assigned components
   /// @return {real} The number of components currently registered
   static GetComponentCount = function()
   {
      return componentCount;
   }
   
   /// @description Checks whether a component of the specified type is registered to this manager
   /// @param {string} _component The component type name (e.g., "AtxComponentHealth")
   /// @return {bool} Returns true if the component exists, false otherwise
   static HasComponent = function(_component)
   {
      return variable_struct_exists(components, _component);
   }
   
   /// @description Checks if the component manager has ALL of the specified components
   /// @param {array<string>} _names Array of component type names to check for
   /// @return {bool} True if all components exist, false if any are missing
   static HasTheseComponents = function(_names = [])
   {
      var _nameCount = array_length(_names)
      if (_nameCount == 0) return true;
      if (_nameCount > componentCount) return false;
      for (var _i = 0; _i < _nameCount; _i++)
      {
         if (!variable_struct_exists(components, _names[_i])) return false;
      }
      return true;
   }
   
   /// @description Checks if the component manager has ANY of the specified components
   /// @param {array<string>} _names Array of component type names to check for
   /// @return {bool} True if at least one component exists, false if none exist
   static HasAnyOfTheseComponents = function(_names = [])
   {
      var _nameCount = array_length(_names)
      if (_nameCount == 0) return false;
      for (var _i = 0; _i < _nameCount; _i++)
      {
         if (variable_struct_exists(components, _names[_i])) return true;
      }
      return false;
   }
   
   /// @description Returns all components that have registered for a specific event
   /// @param {string} _eventName The event name to check
   /// @return {array<struct.AtxComponentBase>} Array of components, or empty array if none
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
   
   /// @description Gets the step priority of a component
   /// @param {string} _componentKey The component type name
   /// @return {real,undefined} The step priority value, or undefined if component doesn't exist
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
   
   /// @description Gets the draw priority of a component
   /// @param {string} _componentKey The component type name
   /// @return {real,undefined} The draw priority value, or undefined if component doesn't exist
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
   
   /// @description Gets the drawGUI priority of a component
   /// @param {string} _componentKey The component type name
   /// @return {real,undefined} The drawGUI priority value, or undefined if component doesn't exist
   static GetDrawGUIPriority = function(_componentKey)
   {
      var _component = GetComponent(_componentKey);
      if (_component == undefined)
      {
         show_debug_message("AtxComponentManager (GetDrawGUIPriority): Couldn't find component returning undefined.");
         return undefined;
      }
      return _component.drawGUIPriority;
   }
   
   /// @description Sets the step priority of a component
   /// @param {string} _componentKey The component type name
   /// @param {real} _priority The new priority value (lower executes first)
   /// @return {bool} True if priority was set, false if component doesn't exist
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
   
   /// @description Sets the draw priority of a component
   /// @param {string} _componentKey The component type name
   /// @param {real} _priority The new priority value (lower executes first)
   /// @return {bool} True if priority was set, false if component doesn't exist
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
   
   /// @description Sets the drawGUI priority of a component
   /// @param {string} _componentKey The component type name
   /// @param {real} _priority The new priority value (lower executes first)
   /// @return {bool} True if priority was set, false if component doesn't exist
   static SetDrawGUIPriority = function(_componentKey, _priority)
   {
      var _component = GetComponent(_componentKey);
      if (_component == undefined)
      {
         show_debug_message("AtxComponentManager (SetDrawGUIPriority): Couldn't find component returning false.")
         return false;
      }
      
      _component.drawGUIPriority = _priority;
      if (is_method(_component.DrawGUI))
      {
         drawGUINeedsSort = true;
      }
      
      return true;
   }
   
   /// @description Sets both the step and draw priority of a component to the same value
   /// @param {string} _componentKey The component type name
   /// @param {real} _priority The new priority value (lower executes first)
   /// @return {bool} True if both priorities were set, false if component doesn't exist
   static SetBothPriority = function(_componentKey, _priority)
   {
      var _stepCheck = SetStepPriority(_componentKey, _priority);
      if (_stepCheck == false) {show_debug_message("AtxComponentManager(SetBothPriority): Setting Step Failed")}
      var _drawCheck = SetDrawPriority(_componentKey, _priority);
      if (_drawCheck == false) {show_debug_message("AtxComponentManager(SetBothPriority): Setting Draw Failed")}
      if (!_stepCheck || !_drawCheck) return false; 
         
      return true;   
   }
   
   /// @description Sets all priorities (step, draw, and drawGUI) of a component to the same value
   /// @param {string} _componentKey The component type name
   /// @param {real} _priority The new priority value (lower executes first)
   /// @return {bool} True if all priorities were set, false if component doesn't exist
   static SetAllPriority = function(_componentKey, _priority)
   {
      var _stepCheck = SetStepPriority(_componentKey, _priority);
      if (_stepCheck == false) {show_debug_message("AtxComponentManager(SetAllPriority): Setting Step Failed")}
      var _drawCheck = SetDrawPriority(_componentKey, _priority);
      if (_drawCheck == false) {show_debug_message("AtxComponentManager(SetAllPriority): Setting Draw Failed")}
      var _drawGUICheck = SetDrawGUIPriority(_componentKey, _priority);
      if (_drawGUICheck == false) {show_debug_message("AtxComponentManager(SetAllPriority): Setting DrawGUI Failed")}
      if (!_stepCheck || !_drawCheck || !_drawGUICheck) return false; 
         
      return true;   
   }
   
   /// @description Sorts step components by priority (low to high)
   /// @return {undefined}
   static SortStepComponents = function()
   {
      var _stepComponentCount = array_length(stepComponents);
      if (_stepComponentCount <= 1) return;
      
      array_sort(stepComponents, function(_a, _b) 
      {
         return _a.stepPriority - _b.stepPriority;
      });
   }
   
   /// @description Sorts draw components by priority (low to high)
   /// @return {undefined}
   static SortDrawComponents = function()
   {
      var _drawComponentCount = array_length(drawComponents);
      if (_drawComponentCount <= 1) return;
      
      array_sort(drawComponents, function(_a, _b) 
      {
         return _a.drawPriority - _b.drawPriority;
      });
   }
   
   /// @description Sorts drawGUI components by priority (low to high)
   /// @return {undefined}
   static SortDrawGUIComponents = function()
   {
      var _drawGUIComponentCount = array_length(drawGUIComponents);
      if (_drawGUIComponentCount <= 1) return;
      
      array_sort(drawGUIComponents, function(_a, _b) 
      {
         return _a.drawGUIPriority - _b.drawGUIPriority;
      });
   }
      
   #endregion
   
   #region TriggerEvent
   
   /// @description Triggers an event across all components that have registered a handler for it
   /// @param {string} _eventName The name of the event to trigger (e.g., "damage", "collect", "interact")
   /// @param {any} _eventData The data to pass to all event handlers
   /// @param {string} _componentKey Optional specific component to trigger event on, or undefined for all
   /// @return {undefined}
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
   
   /// @description Queries components and returns all the results in an array.
   /// @param {string} _queryName The name of the query to execute
   /// @param {struct} _data The data to pass to query handlers
   /// @return {array} An array of results. 
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
      var _results = [];
      for (var _i = 0; _i < _queryCount; _i++)
      {
         var _handler = _handlers[_i];
         var _component = _handler.component;
         if (!_component.enabled) continue;
         var _method = _handler.method;
         var _returnValue = _method(_data);
         if (_returnValue != undefined) array_push(_results, _returnValue); 
      }
      return _results;
   }
   
   /// @description Queries components and collects the first result
   /// @param {string} _queryName The name of the query to execute
   /// @param {struct} _data The data to pass to query handlers
   /// @return {any} Returns the first result or undefined if no results
   static QueryFirst = function(_queryName, _data = {})
   {
      if (!variable_struct_exists(queryMap, _queryName))
      {
         show_debug_message("AtxComponentManager (QueryFirst): Couldn't find query.")
         return undefined;
      }
      var _handlers = queryMap[$ _queryName];
      var _queryCount = array_length(_handlers);
      for (var _i = 0; _i < _queryCount; _i++)
      {
         var _handler = _handlers[_i];
         var _component = _handler.component;
         if (!_component.enabled) continue;
         var _method = _handler.method;
         var _returnValue = _method(_data);
         if (_returnValue != undefined) return _returnValue;
      }
      return undefined;
   }
   
   /// @description Queries components with an accumulator pattern to combine results
   /// @param {string} _queryName The name of the query to execute
   /// @param {any} _initialValue The starting value for the accumulator
   /// @param {struct} _data The data to pass to query handlers
   /// @return {any} The final accumulated value
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
   
   /// @description Queries components with a specific tag collects the first result
   /// @param {string} _tag The tag to filter components by
   /// @param {string} _queryName The name of the query to execute
   /// @param {struct} _data The data to pass to query handlers
   /// @return {array} Array of all non-undefined query results
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
         var _componentKey = _componentsWithTag[_i];
         var _component = GetComponent(_componentKey);
         if (_component == undefined || !_component.enabled || !variable_struct_exists(_component.queries, _queryName)) continue;
         var _query = _component.queries[$ _queryName](_data);
         if (_query != undefined) array_push(_results, _query);
      }
      
      return _results;
   }
   
   /// @description Queries components with a specific tag and collects first result
   /// @param {string} _tag The tag to filter components by
   /// @param {string} _queryName The name of the query to execute
   /// @param {struct} _data The data to pass to query handlers
   /// @return {any} Returns first result
   static QueryByTagFirst = function(_tag, _queryName, _data)
   {
      if (!variable_struct_exists(componentTags, _tag))
      {
         show_debug_message($"AtxComponentManager (QueryByTagFirst): Tag {_tag} has no components.");
         return undefined;
      }
      var _componentsWithTag = GetComponentsWithTag(_tag);
      var _componentCount = array_length(_componentsWithTag);
      if (_componentCount == 0) return undefined;
         
      for (var _i = 0; _i < _componentCount; _i++)
      {
         var _componentKey = _componentsWithTag[_i];
         var _component = GetComponent(_componentKey);
         if (_component == undefined || !_component.enabled || !variable_struct_exists(_component.queries, _queryName)) continue;
         var _query = _component.queries[$ _queryName](_data);
         if (_query != undefined) return _query;
      }
      
      return undefined;
   }
   
   /// @description Queries components with a specific tag using an accumulator pattern
   /// @param {string} _tag The tag to filter components by
   /// @param {string} _queryName The name of the query to execute
   /// @param {any} _initialValue The starting value for the accumulator
   /// @param {struct} _data The data to pass to query handlers
   /// @return {any} The final accumulated value
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
         var _componentKey = _componentsWithTag[_i];
         var _component = GetComponent(_componentKey);
         if (_component == undefined || !_component.enabled || !variable_struct_exists(_component.queries, _queryName)) continue; 
            
         _data.accumulator = _accumulator;
         var _query = _component.queries[$ _queryName](_data);
         if (_query != undefined) _accumulator = _query;   
      }
      return _accumulator;
   }
   
   #endregion
   
   #region Tagging
   
   /// @description Adds a tag to a component for categorization and bulk operations
   /// @param {string} _componentKey The component type name
   /// @param {string} _tag The tag to add
   /// @return {bool} True if tag was added, false if component doesn't exist or already has tag
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
   
   /// @description Returns an array of component keys that have the specified tag
   /// @param {string} _tag The tag to search for
   /// @return {array<string>} Array of component keys with this tag, or empty array if none
   static GetComponentsWithTag = function(_tag)
   {
      if (!variable_struct_exists(componentTags, _tag)) 
      {
         show_debug_message($"AtxComponentManager (GetComponentsWithTag): No components exist with tag {_tag}.")
         return [];
      }
      return componentTags[$ _tag];
   }
   
   /// @description Triggers an event on all components with a specific tag
   /// @param {string} _tag The tag to filter components by
   /// @param {string} _eventKey The event name to trigger
   /// @param {any} _data The data to pass to event handlers
   /// @return {undefined}
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
   
   /// @description Removes a tag from a component
   /// @param {string} _componentKey The component type name
   /// @param {string} _tag The tag to remove
   /// @return {bool} True if tag was removed, false if component or tag doesn't exist
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
         show_debug_message($"AtxComponentManager (RemoveTag): Critical array mismatch, found component and tag in taggedComponents but not in componentTags.");
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
   
   /// @description Checks if a component has a specific tag
   /// @param {string} _componentKey The component type name
   /// @param {string} _tag The tag to check for
   /// @return {bool} True if component has the tag, false otherwise
   static HasTag = function(_componentKey, _tag)
   {
      return (HasComponent(_componentKey) && variable_struct_exists(taggedComponents, _componentKey) && array_contains(taggedComponents[$ _componentKey], _tag));
   }
   
   /// @description Returns an array of all tags associated with a component
   /// @param {string} _componentKey The component type name
   /// @return {array<string>} Array of tags, or empty array if component has no tags
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
   
   /// @description Enables all components with a specific tag
   /// @param {string} _tag The tag to filter components by
   /// @return {real} The number of components that were enabled
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
   
   /// @description Disables all components with a specific tag
   /// @param {string} _tag The tag to filter components by
   /// @return {real} The number of components that were disabled
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
   
   /// @description Adds multiple tags to a component at once
   /// @param {string} _componentKey The component type name
   /// @param {array<string>} _tagArray Array of tags to add
   /// @return {real} The number of tags that were successfully added
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
   
   /// @description Gets the number of components that have a specific tag
   /// @param {string} _tag The tag to count
   /// @return {real} The number of components with this tag
   static GetTagCount = function(_tag)
   {
      if (!variable_struct_exists(componentTags, _tag)) return 0;
         
      return (array_length(componentTags[$ _tag]));
   }
   
   /// @description Returns an array of all unique tags in use
   /// @return {array<string>} Array of all tag names
   static GetAllTags = function()
   {
      return struct_get_names(componentTags);
   }
   
   #endregion
   
   #region Helper functions
   
   /// @description Internal helper that converts component reference to key
   /// @param {struct,string} _componentOrKey Component instance or class name
   /// @return {string,undefined} Component key or undefined if not found
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
   
   /// @description Gets an array of dependencies that a component is missing
   /// @param {struct.AtxComponentBase} _component The component to check
   /// @return {array<string>} Array of missing dependency names
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
   
   /// @description Checks if a component has all its required dependencies
   /// @param {struct.AtxComponentBase} _component The component to check
   /// @return {bool} True if all dependencies are present, false otherwise
   static HasAllDependencies = function(_component)
   {
      var _dependencyCount = array_length(_component.requires);
      if (_dependencyCount == 0) return true;
         
      if (HasTheseComponents(_component.requires)) return true;
         
      return false;
   }
   
   /// @description Gets an array of components that depend on a specific component
   /// @param {string} _componentKey The component type name to check
   /// @return {array<string>} Array of component names that depend on this component
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