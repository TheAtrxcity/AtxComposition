/// @description Complete JSON Save/Load Test
/// @author TheAtrxcity
/// @date 2025-10-14 06:27:06 UTC

function TestJSONSystem()
{
    show_debug_message("\n═══════════════════════════════════════════════════════");
    show_debug_message("   💾 COMPLETE JSON SAVE/LOAD SYSTEM TEST");
    show_debug_message("   Date: 2025-10-14 06:27:06 UTC");
    show_debug_message("   User: TheAtrxcity");
    show_debug_message("═══════════════════════════════════════════════════════\n");
    
    var _testsPassed = 0;
    var _testsFailed = 0;
    
    // ═══════════════════════════════════════════════════════
    // TEST 1: Create 15 game constructs
    // ═══════════════════════════════════════════════════════
    show_debug_message("TEST 1: Create 15 game constructs");
    
    SetupGameConstructs();
    
    var _constructCount = array_length(AtxGetAllConstructs());
    
    if (_constructCount == 15)
    {
        show_debug_message($"✅ PASS: Created {_constructCount} constructs\n");
        _testsPassed++;
    }
    else
    {
        show_debug_message($"❌ FAIL: Expected 15, got {_constructCount}\n");
        _testsFailed++;
    }
    
    // ═══════════════════════════════════════════════════════
    // TEST 2: Save all constructs to JSON
    // ═══════════════════════════════════════════════════════
    show_debug_message("TEST 2: Save all constructs to JSON file");
    
    var _filename = "game_constructs.json";
    AtxSaveConstructsToFile(_filename);
    
    if (file_exists(_filename))
    {
        show_debug_message($"✅ PASS: File '{_filename}' created successfully\n");
        _testsPassed++;
    }
    else
    {
        show_debug_message($"❌ FAIL: File '{_filename}' not found\n");
        _testsFailed++;
    }
    
    // ═══════════════════════════════════════════════════════
    // TEST 3: Verify specific constructs exist
    // ═══════════════════════════════════════════════════════
    show_debug_message("TEST 3: Verify specific constructs exist before clear");
    
    var _testConstructs = ["player", "enemy_goblin", "boss_dragon", "npc_merchant"];
    var _allExist = true;
    
    for (var _i = 0; _i < array_length(_testConstructs); _i++)
    {
        if (!AtxConstructExists(_testConstructs[_i]))
        {
            show_debug_message($"  Missing: {_testConstructs[_i]}");
            _allExist = false;
        }
    }
    
    if (_allExist)
    {
        show_debug_message("✅ PASS: All test constructs exist\n");
        _testsPassed++;
    }
    else
    {
        show_debug_message("❌ FAIL: Some constructs missing\n");
        _testsFailed++;
    }
    
    // ═══════════════════════════════════════════════════════
    // TEST 4: Clear registry
    // ═══════════════════════════════════════════════════════
    show_debug_message("TEST 4: Clear construct registry");
    
    global.__atxConstructRegistry = {};
    var _afterClear = array_length(AtxGetAllConstructs());
    
    if (_afterClear == 0)
    {
        show_debug_message("✅ PASS: Registry cleared successfully\n");
        _testsPassed++;
    }
    else
    {
        show_debug_message($"❌ FAIL: Registry not empty (has {_afterClear} constructs)\n");
        _testsFailed++;
    }
    
    // ═══════════════════════════════════════════════════════
    // TEST 5: Load constructs from JSON
    // ═══════════════════════════════════════════════════════
    show_debug_message("TEST 5: Load constructs from JSON file");
    
    AtxLoadConstructsFromFile(_filename);
    var _afterLoad = array_length(AtxGetAllConstructs());
    
    if (_afterLoad == 15)
    {
        show_debug_message($"✅ PASS: Loaded {_afterLoad} constructs\n");
        _testsPassed++;
    }
    else
    {
        show_debug_message($"❌ FAIL: Expected 15, loaded {_afterLoad}\n");
        _testsFailed++;
    }
    
    // ═══════════════════════════════════════════════════════
    // TEST 6: Verify loaded constructs
    // ═══════════════════════════════════════════════════════
    show_debug_message("TEST 6: Verify all constructs loaded correctly");
    
    var _allLoaded = true;
    for (var _i = 0; _i < array_length(_testConstructs); _i++)
    {
        if (!AtxConstructExists(_testConstructs[_i]))
        {
            show_debug_message($"  Missing after load: {_testConstructs[_i]}");
            _allLoaded = false;
        }
    }
    
    if (_allLoaded)
    {
        show_debug_message("✅ PASS: All test constructs loaded\n");
        _testsPassed++;
    }
    else
    {
        show_debug_message("❌ FAIL: Some constructs missing after load\n");
        _testsFailed++;
    }
    
    // ═══════════════════════════════════════════════════════
    // TEST 7: Spawn player from loaded construct
    // ═══════════════════════════════════════════════════════
    show_debug_message("TEST 7: Spawn player entity from loaded construct");
    
    var _player = AtxSpawnConstruct("player", 100, 100);
    
    if (_player != undefined && instance_exists(_player))
    {
        var _hasAllComponents = _player.manager.HasTheseComponents([
            "TestHealthComponent",
            "TestCombatComponent",
            "TestMovementComponent",
            "InventoryComponent",
            "ExperienceComponent",
            "WeaponComponent",
            "ArmorComponent",
            "QuestComponent"
        ]);
        
        if (_hasAllComponents)
        {
            var _health = _player.manager.GetComponent("TestHealthComponent");
            var _inventory = _player.manager.GetComponent("InventoryComponent");
            
            if (_health.maxHitPoints == 100 && _inventory.maxSlots == 30)
            {
                show_debug_message("✅ PASS: Player spawned with correct components and values\n");
                _testsPassed++;
            }
            else
            {
                show_debug_message("❌ FAIL: Player component values incorrect\n");
                _testsFailed++;
            }
        }
        else
        {
            show_debug_message("❌ FAIL: Player missing components\n");
            _testsFailed++;
        }
        
        instance_destroy(_player);
    }
    else
    {
        show_debug_message("❌ FAIL: Player spawn failed\n");
        _testsFailed++;
    }
    
    // ═══════════════════════════════════════════════════════
    // TEST 8: Spawn boss from loaded construct
    // ═══════════════════════════════════════════════════════
    show_debug_message("TEST 8: Spawn boss entity from loaded construct");
    
    var _boss = AtxSpawnConstruct("boss_dragon", 200, 100);
    
    if (_boss != undefined && instance_exists(_boss))
    {
        var _health = _boss.manager.GetComponent("TestHealthComponent");
        var _armor = _boss.manager.GetComponent("ArmorComponent");
        var _loot = _boss.manager.GetComponent("LootDropComponent");
        
        if (_health.maxHitPoints == 500 && 
            _armor.defense == 30 && 
            _loot.goldMin == 500)
        {
            show_debug_message("✅ PASS: Boss spawned with correct values\n");
            _testsPassed++;
        }
        else
        {
            show_debug_message("❌ FAIL: Boss component values incorrect");
            show_debug_message($"  HP: {_health.maxHitPoints} (expected 500)");
            show_debug_message($"  Defense: {_armor.defense} (expected 30)");
            show_debug_message($"  Gold: {_loot.goldMin} (expected 500)\n");
            _testsFailed++;
        }
        
        instance_destroy(_boss);
    }
    else
    {
        show_debug_message("❌ FAIL: Boss spawn failed\n");
        _testsFailed++;
    }
    
    // ═══════════════════════════════════════════════════════
    // TEST 9: Verify tags preserved through save/load
    // ═══════════════════════════════════════════════════════
    show_debug_message("TEST 9: Verify tags preserved through save/load");
    
    var _enemy = AtxSpawnConstruct("enemy_goblin", 300, 100);
    
    if (_enemy != undefined && instance_exists(_enemy))
    {
        var _hasEnemyTag = _enemy.manager.HasTag("TestHealthComponent", "enemy");
        var _hasDamageableTag = _enemy.manager.HasTag("TestHealthComponent", "damageable");
        var _hasHostileTag = _enemy.manager.HasTag("AIComponent", "hostile");
        
        if (_hasEnemyTag && _hasDamageableTag && _hasHostileTag)
        {
            show_debug_message("✅ PASS: Tags preserved correctly\n");
            _testsPassed++;
        }
        else
        {
            show_debug_message("❌ FAIL: Tags not preserved");
            show_debug_message($"  enemy tag: {_hasEnemyTag}");
            show_debug_message($"  damageable tag: {_hasDamageableTag}");
            show_debug_message($"  hostile tag: {_hasHostileTag}\n");
            _testsFailed++;
        }
        
        instance_destroy(_enemy);
    }
    else
    {
        show_debug_message("❌ FAIL: Enemy spawn failed\n");
        _testsFailed++;
    }
    
    // ═══════════════════════════════════════════════════════
    // TEST 10: Verify depth preservation
    // ═══════════════════════════════════════════════════════
    show_debug_message("TEST 10: Verify depth preserved through save/load");
    
    var _merchant = AtxSpawnConstruct("npc_merchant", 400, 100);
    var _dragon = AtxSpawnConstruct("boss_dragon", 500, 100);
    
    if (_merchant != undefined && instance_exists(_merchant) &&
        _dragon != undefined && instance_exists(_dragon))
    {
        if (_merchant.depth == -10 && _dragon.depth == -100)
        {
            show_debug_message("✅ PASS: Depth values preserved\n");
            _testsPassed++;
        }
        else
        {
            show_debug_message("❌ FAIL: Depth values incorrect");
            show_debug_message($"  Merchant: {_merchant.depth} (expected -10)");
            show_debug_message($"  Dragon: {_dragon.depth} (expected -100)\n");
            _testsFailed++;
        }
        
        instance_destroy(_merchant);
        instance_destroy(_dragon);
    }
    else
    {
        show_debug_message("❌ FAIL: Depth test spawn failed\n");
        _testsFailed++;
    }
    
    // ═══════════════════════════════════════════════════════
    // TEST 11: Spawn multiple enemies
    // ═══════════════════════════════════════════════════════
    show_debug_message("TEST 11: Spawn multiple enemy types");
    
    var _enemies = [
        AtxSpawnConstruct("enemy_goblin", 100, 200),
        AtxSpawnConstruct("enemy_orc", 200, 200),
        AtxSpawnConstruct("enemy_archer", 300, 200),
        AtxSpawnConstruct("enemy_mage", 400, 200)
    ];
    
    var _allSpawned = true;
    for (var _i = 0; _i < array_length(_enemies); _i++)
    {
        if (_enemies[_i] == undefined || !instance_exists(_enemies[_i]))
        {
            _allSpawned = false;
            break;
        }
    }
    
    if (_allSpawned)
    {
        show_debug_message("✅ PASS: All enemy types spawned successfully\n");
        _testsPassed++;
        
        for (var _i = 0; _i < array_length(_enemies); _i++)
        {
            instance_destroy(_enemies[_i]);
        }
    }
    else
    {
        show_debug_message("❌ FAIL: Some enemy spawns failed\n");
        _testsFailed++;
    }
    
    // ═══════════════════════════════════════════════════════
    // TEST 12: Test construct with overrides
    // ═══════════════════════════════════════════════════════
    show_debug_message("TEST 12: Spawn with component overrides");
    
    var _customGoblin = AtxSpawnConstruct("enemy_goblin", 500, 200, undefined, {
        TestHealthComponent: {
            hitPoints: 100,
            maxHitPoints: 100
        },
        TestCombatComponent: {
            attackPower: 50
        }
    });
    
    if (_customGoblin != undefined && instance_exists(_customGoblin))
    {
        var _health = _customGoblin.manager.GetComponent("TestHealthComponent");
        var _combat = _customGoblin.manager.GetComponent("TestCombatComponent");
        
        if (_health.hitPoints == 100 && _combat.attackPower == 50)
        {
            show_debug_message("✅ PASS: Overrides applied correctly to loaded construct\n");
            _testsPassed++;
        }
        else
        {
            show_debug_message("❌ FAIL: Overrides not applied correctly\n");
            _testsFailed++;
        }
        
        instance_destroy(_customGoblin);
    }
    else
    {
        show_debug_message("❌ FAIL: Override spawn failed\n");
        _testsFailed++;
    }
    
    // ═══════════════════════════════════════════════════════
    // RESULTS
    // ═══════════════════════════════════════════════════════
    show_debug_message("\n═══════════════════════════════════════════════════════");
    show_debug_message("   📊 FINAL TEST RESULTS");
    show_debug_message("═══════════════════════════════════════════════════════");
    show_debug_message($"Total Tests:     {_testsPassed + _testsFailed}");
    show_debug_message($"Passed:          {_testsPassed} ✅");
    show_debug_message($"Failed:          {_testsFailed} ❌");
    show_debug_message($"Success Rate:    {(_testsPassed / (_testsPassed + _testsFailed)) * 100}%");
    show_debug_message("═══════════════════════════════════════════════════════\n");
    
    if (_testsFailed == 0)
    {
        show_debug_message("🎉🎉🎉 PERFECT SCORE! JSON SYSTEM FULLY COMPLETE! 🎉🎉🎉");
        show_debug_message("🔥 ALL SYSTEMS OPERATIONAL - PRODUCTION READY! 🔥\n");
    }
    else
    {
        show_debug_message("⚠️ SOME TESTS FAILED - CHECK IMPLEMENTATION\n");
    }
    
    // Cleanup test file
    if (file_exists(_filename))
    {
        show_debug_message($"💡 JSON file '{_filename}' saved for inspection");
        show_debug_message("   (Delete manually or keep for future use)\n");
    }
}