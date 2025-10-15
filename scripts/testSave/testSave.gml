function TestSaveFunction()
{
    show_debug_message("\n═══════════════════════════════════════════════════════");
    show_debug_message("   💾 TESTING SAVE FUNCTION");
    show_debug_message("   Date: 2025-10-14 11:43:27 UTC");
    show_debug_message("═══════════════════════════════════════════════════════\n");
    
    // Step 1: Initialize save system
    show_debug_message("STEP 1: Initializing save system");
    AtxInitialiseSaveSystem();
    
    // Step 2: Create some test entities
    show_debug_message("\nSTEP 2: Creating test entities");
    
    var _player = AtxSpawnConstruct("player", 100, 100);
    var _goblin = AtxSpawnConstruct("enemy_goblin", 200, 150);
    var _chest = AtxSpawnConstruct("chest_rare", 300, 100);
    
    show_debug_message("   Created player, goblin, chest");
    
    // Step 3: Modify some values
    show_debug_message("\nSTEP 3: Modifying entity values");
    
    if (_player != undefined && instance_exists(_player))
    {
        var _health = _player.manager.GetComponent("TestHealthComponent");
        _health.hitPoints = 75;
        
        var _inv = _player.manager.GetComponent("InventoryComponent");
        _inv.gold = 500;
        
        show_debug_message($"   Player HP: {_health.hitPoints}");
        show_debug_message($"   Player Gold: {_inv.gold}");
    }
    show_debug_message("\nDEBUG: Checking player components");

if (_player != undefined && instance_exists(_player))
{
   show_debug_message($"   Player instance exists: {instance_exists(_player)}");
   show_debug_message($"   Player has manager: {variable_instance_exists(_player, "manager")}");
   
   if (variable_instance_exists(_player, "manager"))
   {
      show_debug_message($"   Manager exists: {_player.manager != undefined}");
      
      // Check components array
      show_debug_message($"   Manager.components is array: {is_array(_player.manager.components)}");
      show_debug_message($"   Manager.components length: {array_length(_player.manager.components)}");
      
      // Try GetAllComponents
      var _allComponents = _player.manager.GetAllComponents();
      show_debug_message($"   GetAllComponents() returned: {_allComponents}");
      show_debug_message($"   GetAllComponents() is array: {is_array(_allComponents)}");
      show_debug_message($"   GetAllComponents() length: {array_length(_allComponents)}");
      
      // Try HasComponent
      show_debug_message($"   HasComponent(TestHealthComponent): {_player.manager.HasComponent("TestHealthComponent")}");
      show_debug_message($"   HasComponent(InventoryComponent): {_player.manager.HasComponent("InventoryComponent")}");
      
      // Try GetComponent
      var _health = _player.manager.GetComponent("TestHealthComponent");
      show_debug_message($"   GetComponent returned: {_health}");
      show_debug_message($"   Health HP: {_health != undefined ? _health.hitPoints : "undefined"}");
   }
}
    // Step 4: Save the game
    show_debug_message("\nSTEP 4: Saving game state");
    
    var _saveResult = AtxSaveGame("Test Save", 0);
    
    if (_saveResult)
    {
        show_debug_message("   ✅ Save function returned true");
    }
    else
    {
        show_debug_message("   ❌ Save function returned false");
    }
    
    // Step 5: Check if file was created
    show_debug_message("\nSTEP 5: Verifying save file");
    
    var _filename = global.__atxSaveConfig.saveDirectory + "save_0.json";
    
    if (file_exists(_filename))
    {
        show_debug_message($"   ✅ File created: {_filename}");
        
        // Try to read it
        var _buffer = buffer_load(_filename);
        var _jsonString = buffer_read(_buffer, buffer_string);
        buffer_delete(_buffer);
        
        show_debug_message($"   File size: {string_length(_jsonString)} characters");
        show_debug_message($"   First 200 chars: {string_copy(_jsonString, 1, 200)}");
    }
    else
    {
        show_debug_message($"   ❌ File NOT found: {_filename}");
    }
    
    show_debug_message("\n═══════════════════════════════════════════════════════");
    show_debug_message("   TEST COMPLETE");
    show_debug_message("═══════════════════════════════════════════════════════\n");
}