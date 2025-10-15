function TestSaveFunction()
{
    show_debug_message("\n═══════════════════════════════════════════════════════");
    show_debug_message("   💾 TESTING SAVE FUNCTION");
    show_debug_message("   Date: 2025-10-14 11:43:27 UTC");
    show_debug_message("═══════════════════════════════════════════════════════\n");
    
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

function TestSaveLoadSystem()
{
   show_debug_message("\n========== SAVE/LOAD SYSTEM TEST ==========\n");
   
   // STEP 1: Create test entities
   show_debug_message("STEP 1: Creating test entities...");
   var _player = AtxSpawnConstruct("player", 100, 100);
   var _goblin = AtxSpawnConstruct("enemy_goblin", 200, 150);
   var _chest = AtxSpawnConstruct("chest_rare", 300, 100);
   
   // STEP 2: Modify some values
   show_debug_message("\nSTEP 2: Modifying entity values...");
   var _playerHealth = _player.manager.GetComponent("TestHealthComponent");
   var _playerInv = _player.manager.GetComponent("InventoryComponent");
   
   _playerHealth.hitPoints = 75;
   _playerInv.gold = 999;
   
   show_debug_message($"   Player HP set to: {_playerHealth.hitPoints}");
   show_debug_message($"   Player Gold set to: {_playerInv.gold}");
   
   // STEP 3: Save the game
   show_debug_message("\nSTEP 3: Saving game...");
   AtxSaveGame("Test Save", 0);
   
   // STEP 4: Destroy all entities
   show_debug_message("\nSTEP 4: Clearing all entities...");
   AtxClearSaveableEntities();
   
   // STEP 5: Load the game
   show_debug_message("\nSTEP 5: Loading game...");
   AtxLoadGame(0, true);
   
   // STEP 6: Verify loaded values (wait 1 frame for Phase2)
   show_debug_message("\nSTEP 6: Verification will happen next frame...");
   call_later(1, time_source_units_frames, function() {
      show_debug_message("\n========== VERIFICATION ==========");
      
      var _foundPlayer = false;
      var _foundGoblin = false;
      var _foundChest = false;
      var _hpCorrect = false;
      var _goldCorrect = false;
      
      with (all)
      {
         if (!variable_instance_exists(self, "manager") || !manager.enableSave) continue;
         
         if (manager.constructReference == "player")
         {
            _foundPlayer = true;
            var _hp = manager.GetComponent("TestHealthComponent");
            var _inv = manager.GetComponent("InventoryComponent");
            
            show_debug_message($"   Player found at ({x}, {y})");
            show_debug_message($"   Player HP: {_hp.hitPoints} (expected 75)");
            show_debug_message($"   Player Gold: {_inv.gold} (expected 999)");
            
            _hpCorrect = (_hp.hitPoints == 75);
            _goldCorrect = (_inv.gold == 999);
         }
         
         if (manager.constructReference == "enemy_goblin")
         {
            _foundGoblin = true;
            show_debug_message($"   Goblin found at ({x}, {y})");
         }
         
         if (manager.constructReference == "chest_rare")
         {
            _foundChest = true;
            show_debug_message($"   Chest found at ({x}, {y})");
         }
      }
      
      show_debug_message("\n========== RESULTS ==========");
      show_debug_message($"   Player loaded: {_foundPlayer ? "✅" : "❌"}");
      show_debug_message($"   Goblin loaded: {_foundGoblin ? "✅" : "❌"}");
      show_debug_message($"   Chest loaded: {_foundChest ? "✅" : "❌"}");
      show_debug_message($"   HP preserved: {_hpCorrect ? "✅" : "❌"}");
      show_debug_message($"   Gold preserved: {_goldCorrect ? "✅" : "❌"}");
      
      if (_foundPlayer && _foundGoblin && _foundChest && _hpCorrect && _goldCorrect)
      {
         show_debug_message("\n🎉 ALL TESTS PASSED! 🎉");
      }
      else
      {
         show_debug_message("\n❌ SOME TESTS FAILED!");
      }
   });
}

function TestRoomChanging()
{
   show_debug_message("\n========== ROOM CHANGING TEST ==========\n");
   
   var _currentRoom = room_get_name(room);
   show_debug_message($"Current room: {_currentRoom}");
   
   if (room == rm_test_save_room_a)
   {
      // Check if we just loaded back from a save
      if (file_exists("saves/save_99.json") && instance_number(obj_player) > 0)
      {
         // We already loaded! This is the verification phase
         show_debug_message("\n========== VERIFICATION ==========");
         show_debug_message("Now in room: rm_test_save_room_a");
         show_debug_message("   ✅ Successfully returned to Room A!");
         
         var _foundPlayer = false;
         var _foundGoblin = false;
         var _hpCorrect = false;
         
         with (all)
         {
            if (!variable_instance_exists(self, "manager") || !manager.enableSave) continue;
            
            if (manager.constructReference == "player")
            {
               _foundPlayer = true;
               var _hp = manager.GetComponent("TestHealthComponent");
               show_debug_message($"   Player loaded at ({x}, {y}) with HP: {_hp.hitPoints}");
               _hpCorrect = (_hp.hitPoints == 33);
            }
            
            if (manager.constructReference == "enemy_goblin")
            {
               _foundGoblin = true;
               show_debug_message($"   Goblin loaded at ({x}, {y})");
            }
         }
         
         show_debug_message("\n========== RESULTS ==========");
         show_debug_message($"   Returned to Room A: ✅");
         show_debug_message($"   Player loaded: {_foundPlayer ? "✅" : "❌"}");
         show_debug_message($"   Goblin loaded: {_foundGoblin ? "✅" : "❌"}");
         show_debug_message($"   HP preserved (33): {_hpCorrect ? "✅" : "❌"}");
         
         if (_foundPlayer && _foundGoblin && _hpCorrect)
         {
            show_debug_message("\n🎉 ROOM CHANGE TEST PASSED! 🎉");
         }
         else
         {
            show_debug_message("\n❌ ROOM CHANGE TEST FAILED!");
         }
         
         return; // Done!
      }
      
      // Otherwise, start the test
      show_debug_message("PHASE 1: In Room A - Setting up save...");
      
      var _player = AtxSpawnConstruct("player", 100, 100);
      var _goblin = AtxSpawnConstruct("enemy_goblin", 200, 150);
      
      var _hp = _player.manager.GetComponent("TestHealthComponent");
      _hp.hitPoints = 33;
      
      show_debug_message($"   Spawned player at (100, 100) with HP: 33");
      show_debug_message($"   Spawned goblin at (200, 150)");
      
      AtxSaveGame("Room Change Test", 99);
      
      show_debug_message("\n   ✅ Saved in Room A!");
      show_debug_message("   🔄 Switching to Room B in 2 seconds...\n");
      
      call_later(2, time_source_units_seconds, function() {
         room_goto(rm_test_save_room_b);
      });
   }
   else if (room == rm_test_save_room_b)
   {
      show_debug_message("PHASE 2: In Room B - Loading save...");
      show_debug_message("   Should switch back to Room A!\n");
      
      AtxLoadGame(99, true);
   }
   else
   {
      show_debug_message("❌ ERROR: Not in Room A or B!");
      show_debug_message("   Run this test from rm_test_save_room_a!");
   }
}

function TestVisualProperties()
{
   show_debug_message("\n========== VISUAL PROPERTIES TEST ==========\n");
   
   show_debug_message("PHASE 1: Creating entity with custom visual properties...");
   
   var _player = AtxSpawnConstruct("player", 400, 300);
   
   // Set crazy visual values
   _player.image_angle = 45;
   _player.image_xscale = 2.5;
   _player.image_yscale = 0.5;
   _player.image_alpha = 0.7;
   _player.image_blend = c_red;
   _player.depth = -100;
   _player.image_index = 3;
   _player.image_speed = 0;
   _player.direction = 135;
   _player.speed = 5;
   
   show_debug_message($"   Set visual properties:");
   show_debug_message($"      image_angle: {_player.image_angle}");
   show_debug_message($"      image_xscale: {_player.image_xscale}");
   show_debug_message($"      image_yscale: {_player.image_yscale}");
   show_debug_message($"      image_alpha: {_player.image_alpha}");
   show_debug_message($"      image_blend: {_player.image_blend}");
   show_debug_message($"      depth: {_player.depth}");
   show_debug_message($"      image_index: {_player.image_index}");
   show_debug_message($"      direction: {_player.direction}");
   show_debug_message($"      speed: {_player.speed}");
   
   // Save
   show_debug_message("\nPHASE 2: Saving...");
   AtxSaveGame("Visual Test", 98);
   
   // Clear
   show_debug_message("\nPHASE 3: Clearing entities...");
   AtxClearSaveableEntities();
   
   // Load
   show_debug_message("\nPHASE 4: Loading...");
   AtxLoadGame(98, true);
   
   // Verify
   call_later(1, time_source_units_frames, function() {
      show_debug_message("\n========== VERIFICATION ==========");
      
      var _found = false;
      var _allCorrect = true;
      
      with (all)
      {
         if (!variable_instance_exists(self, "manager") || !manager.enableSave) continue;
         
         if (manager.constructReference == "player")
         {
            _found = true;
            
            show_debug_message($"   Loaded visual properties:");
            show_debug_message($"      image_angle: {image_angle} (expected 45) {image_angle == 45 ? "✅" : "❌"}");
            show_debug_message($"      image_xscale: {image_xscale} (expected 2.5) {image_xscale == 2.5 ? "✅" : "❌"}");
            show_debug_message($"      image_yscale: {image_yscale} (expected 0.5) {image_yscale == 0.5 ? "✅" : "❌"}");
            show_debug_message($"      image_alpha: {image_alpha} (expected 0.7) {image_alpha == 0.7 ? "✅" : "❌"}");
            show_debug_message($"      image_blend: {image_blend} (expected {c_red}) {image_blend == c_red ? "✅" : "❌"}");
            show_debug_message($"      depth: {depth} (expected -100) {depth == -100 ? "✅" : "❌"}");
            show_debug_message($"      image_index: {image_index} (expected 3) {image_index == 3 ? "✅" : "❌"}");
            show_debug_message($"      direction: {direction} (expected 135) {direction == 135 ? "✅" : "❌"}");
            show_debug_message($"      speed: {speed} (expected 5) {speed == 5 ? "✅" : "❌"}");
            
            _allCorrect = (
               image_angle == 45 &&
               image_xscale == 2.5 &&
               image_yscale == 0.5 &&
               image_alpha == 0.7 &&
               image_blend == c_red &&
               depth == -100 &&
               image_index == 3 &&
               direction == 135 &&
               speed == 5
            );
         }
      }
      
      show_debug_message("\n========== RESULTS ==========");
      show_debug_message($"   Player found: {_found ? "✅" : "❌"}");
      show_debug_message($"   All properties correct: {_allCorrect ? "✅" : "❌"}");
      
      if (_found && _allCorrect)
      {
         show_debug_message("\n🎉 VISUAL PROPERTIES TEST PASSED! 🎉");
      }
      else
      {
         show_debug_message("\n❌ VISUAL PROPERTIES TEST FAILED!");
      }
   });
}

function TestMultipleComponents()
{
   show_debug_message("\n========== MULTIPLE COMPONENTS TEST ==========\n");
   
   show_debug_message("PHASE 1: Creating entity with multiple components...");
   
   var _player = AtxSpawnConstruct("player", 500, 400);
   
   // Modify ALL component values to unique numbers
   var _health = _player.manager.GetComponent("TestHealthComponent");
   var _inventory = _player.manager.GetComponent("InventoryComponent");
   var _experience = _player.manager.GetComponent("ExperienceComponent");
   
   _health.hitPoints = 42;
   _health.maxHitPoints = 200;
   
   _inventory.gold = 1337;
   
   _experience.currentLevel = 99;
   _experience.currentXP = 12345;
   
   show_debug_message($"   Set component values:");
   show_debug_message($"      HP: {_health.hitPoints}/{_health.maxHitPoints}");
   show_debug_message($"      Gold: {_inventory.gold}");
   show_debug_message($"      Level: {_experience.currentLevel}");
   show_debug_message($"      XP: {_experience.currentXP}");
   
   // Save
   show_debug_message("\nPHASE 2: Saving...");
   AtxSaveGame("Components Test", 97);
   
   // Clear
   show_debug_message("\nPHASE 3: Clearing...");
   AtxClearSaveableEntities();
   
   // Load
   show_debug_message("\nPHASE 4: Loading...");
   AtxLoadGame(97, true);
   
   // Verify
   call_later(1, time_source_units_frames, function() {
      show_debug_message("\n========== VERIFICATION ==========");
      
      var _found = false;
      var _allCorrect = true;
      
      with (all)
      {
         if (!variable_instance_exists(self, "manager") || !manager.enableSave) continue;
         
         if (manager.constructReference == "player")
         {
            _found = true;
            
            var _hp = manager.GetComponent("TestHealthComponent");
            var _inv = manager.GetComponent("InventoryComponent");
            var _xp = manager.GetComponent("ExperienceComponent");
            
            show_debug_message($"   Loaded component values:");
            show_debug_message($"      HP: {_hp.hitPoints}/{_hp.maxHitPoints} (expected 42/200) {(_hp.hitPoints == 42 && _hp.maxHitPoints == 200) ? "✅" : "❌"}");
            show_debug_message($"      Gold: {_inv.gold} (expected 1337) {_inv.gold == 1337 ? "✅" : "❌"}");
            show_debug_message($"      Level: {_xp.currentLevel} (expected 99) {_xp.currentLevel == 99 ? "✅" : "❌"}");
            show_debug_message($"      XP: {_xp.currentXP} (expected 12345) {_xp.currentXP == 12345 ? "✅" : "❌"}");
            
            _allCorrect = (
               _hp.hitPoints == 42 &&
               _hp.maxHitPoints == 200 &&
               _inv.gold == 1337 &&
               _xp.currentLevel == 99 &&
               _xp.currentXP == 12345
            );
         }
      }
      
      show_debug_message("\n========== RESULTS ==========");
      show_debug_message($"   Player found: {_found ? "✅" : "❌"}");
      show_debug_message($"   All components correct: {_allCorrect ? "✅" : "❌"}");
      
      if (_found && _allCorrect)
      {
         show_debug_message("\n🎉 MULTIPLE COMPONENTS TEST PASSED! 🎉");
      }
      else
      {
         show_debug_message("\n❌ MULTIPLE COMPONENTS TEST FAILED!");
      }
   });
}

function TestLoadOrder()
{
   show_debug_message("\n========== LOAD ORDER TEST ==========\n");
   
   show_debug_message("PHASE 1: Creating entities with different priorities...");
   
   var _player = AtxSpawnConstruct("player", 100, 100);
   var _goblin = AtxSpawnConstruct("enemy_goblin", 200, 100);
   var _chest = AtxSpawnConstruct("chest_rare", 300, 100);
   
   // Set different priorities
   _player.manager.savePriority = 10;
   _goblin.manager.savePriority = 50;
   _chest.manager.savePriority = 5;
   
   show_debug_message($"   Player priority: {_player.manager.savePriority}");
   show_debug_message($"   Goblin priority: {_goblin.manager.savePriority}");
   show_debug_message($"   Chest priority: {_chest.manager.savePriority}");
   show_debug_message("\n   Expected load order: Chest(5) → Player(10) → Goblin(50)");
   
   // Save
   show_debug_message("\nPHASE 2: Saving...");
   AtxSaveGame("Priority Test", 96);
   
   // Clear
   show_debug_message("\nPHASE 3: Clearing...");
   AtxClearSaveableEntities();
   
   // Load (check console output for order!)
   show_debug_message("\nPHASE 4: Loading...");
   show_debug_message("   (Watch debug output for load order)\n");
   AtxLoadGame(96, true);
   
   call_later(1, time_source_units_frames, function() {
      show_debug_message("\n========== RESULTS ==========");
      show_debug_message("   Check the debug output above!");
      show_debug_message("   Entities should have loaded in order: Chest → Player → Goblin");
      show_debug_message("\n🎯 PRIORITY ORDER TEST COMPLETE!");
   });
}

function RunAllTests(_testToRun = 3)
{
   show_debug_message("\n");
   show_debug_message("╔════════════════════════════════════════════╗");
   show_debug_message("║   ATX SAVE SYSTEM - COMPREHENSIVE TESTS   ║");
   show_debug_message("╚════════════════════════════════════════════╝");
   show_debug_message("\n");
   
   show_debug_message("Select which test to run:");
   show_debug_message("1. Basic Save/Load Test");
   show_debug_message("2. Room Changing Test (run from rm_test_save_room_a)");
   show_debug_message("3. Visual Properties Test");
   show_debug_message("4. Multiple Components Test");
   show_debug_message("5. Load Order Test");
   show_debug_message("\n");
   
   switch(_testToRun)
   {
      case 1: TestSaveLoadSystem(); break;
      case 2: TestRoomChanging(); break;
      case 3: TestVisualProperties(); break;
      case 4: TestMultipleComponents(); break;
      case 5: TestLoadOrder(); break;
      default: show_debug_message("Invalid test number!"); break;
   }
}