/// @description Setup Game Constructs
/// @author TheAtrxcity
/// @date 2025-10-14 06:27:06 UTC

function SetupGameConstructs()
{
    show_debug_message("\n🔧 Setting up game constructs...\n");
    
    // ═══════════════════════════════════════════════════════
    // CONSTRUCT 1: Player Character
    // ═══════════════════════════════════════════════════════
    AtxCreateConstruct("player", {
        object: obj_quick_test_entity,
        layer: "Instances",
        config: {
            components: {
                TestHealthComponent: {
                    hitPoints: 100,
                    maxHitPoints: 100
                },
                TestCombatComponent: {
                    attackPower: 25
                },
                TestMovementComponent: {
                    moveSpeed: 4
                },
                InventoryComponent: {
                    maxSlots: 30,
                    gold: 100
                },
                ExperienceComponent: {
                    level: 1,
                    currentXP: 0,
                    xpToNextLevel: 100
                },
                WeaponComponent: {
                    weaponType: "sword",
                    damage: 25,
                    attackSpeed: 30,
                    range: 50
                },
                ArmorComponent: {
                    defense: 10,
                    damageReduction: 0.15,
                    armorType: "medium"
                },
                QuestComponent: {
                    maxActiveQuests: 10
                }
            },
            tags: {
                TestHealthComponent: ["player", "damageable"],
                TestCombatComponent: ["player_attack"],
                InventoryComponent: ["player_inventory"]
            }
        }
    });
    
    // ═══════════════════════════════════════════════════════
    // CONSTRUCT 2: Goblin Enemy
    // ═══════════════════════════════════════════════════════
    AtxCreateConstruct("enemy_goblin", {
        object: obj_quick_test_entity,
        layer: "Instances",
        config: {
            components: {
                TestHealthComponent: {
                    hitPoints: 30,
                    maxHitPoints: 30
                },
                TestCombatComponent: {
                    attackPower: 8
                },
                TestMovementComponent: {
                    moveSpeed: 2
                },
                AIComponent: {
                    aiType: "chase",
                    detectionRange: 150,
                    aggroRange: 100
                },
                LootDropComponent: {
                    goldMin: 5,
                    goldMax: 15,
                    dropChance: 0.6
                },
                ExperienceComponent: {
                    level: 3
                }
            },
            tags: {
                TestHealthComponent: ["enemy", "damageable"],
                AIComponent: ["hostile", "melee"]
            }
        }
    });
    
    // ═══════════════════════════════════════════════════════
    // CONSTRUCT 3: Orc Warrior
    // ═══════════════════════════════════════════════════════
    AtxCreateConstruct("enemy_orc", {
        object: obj_quick_test_entity,
        depth: -50,
        config: {
            components: {
                TestHealthComponent: {
                    hitPoints: 80,
                    maxHitPoints: 80
                },
                TestCombatComponent: {
                    attackPower: 20
                },
                TestMovementComponent: {
                    moveSpeed: 1.5
                },
                AIComponent: {
                    aiType: "patrol",
                    detectionRange: 200,
                    aggroRange: 150
                },
                WeaponComponent: {
                    weaponType: "sword",
                    damage: 20,
                    attackSpeed: 60,
                    range: 40
                },
                ArmorComponent: {
                    defense: 15,
                    damageReduction: 0.2,
                    armorType: "heavy"
                },
                LootDropComponent: {
                    goldMin: 15,
                    goldMax: 30,
                    dropChance: 0.8
                }
            },
            tags: {
                TestHealthComponent: ["enemy", "damageable", "boss"],
                AIComponent: ["hostile", "melee", "armored"]
            }
        }
    });
    
    // ═══════════════════════════════════════════════════════
    // CONSTRUCT 4: Archer Enemy
    // ═══════════════════════════════════════════════════════
    AtxCreateConstruct("enemy_archer", {
        object: obj_quick_test_entity,
        layer: "Instances",
        config: {
            components: {
                TestHealthComponent: {
                    hitPoints: 25,
                    maxHitPoints: 25
                },
                TestCombatComponent: {
                    attackPower: 15
                },
                TestMovementComponent: {
                    moveSpeed: 2.5
                },
                AIComponent: {
                    aiType: "flee",
                    detectionRange: 250,
                    aggroRange: 200
                },
                WeaponComponent: {
                    weaponType: "bow",
                    damage: 15,
                    attackSpeed: 45,
                    range: 200
                },
                LootDropComponent: {
                    goldMin: 8,
                    goldMax: 20,
                    dropChance: 0.5
                }
            },
            tags: {
                TestHealthComponent: ["enemy", "damageable"],
                AIComponent: ["hostile", "ranged"]
            }
        }
    });
    
    // ═══════════════════════════════════════════════════════
    // CONSTRUCT 5: Mage Enemy
    // ═══════════════════════════════════════════════════════
    AtxCreateConstruct("enemy_mage", {
        object: obj_quick_test_entity,
        layer: "Instances",
        config: {
            components: {
                TestHealthComponent: {
                    hitPoints: 40,
                    maxHitPoints: 40
                },
                TestCombatComponent: {
                    attackPower: 30
                },
                TestMovementComponent: {
                    moveSpeed: 1.8
                },
                AIComponent: {
                    aiType: "chase",
                    detectionRange: 300,
                    aggroRange: 250
                },
                WeaponComponent: {
                    weaponType: "staff",
                    damage: 30,
                    attackSpeed: 90,
                    range: 250
                },
                StatusEffectComponent: {},
                LootDropComponent: {
                    goldMin: 20,
                    goldMax: 50,
                    dropChance: 0.9
                }
            },
            tags: {
                TestHealthComponent: ["enemy", "damageable", "magic_user"],
                AIComponent: ["hostile", "ranged", "magic"]
            }
        }
    });
    
    // ═══════════════════════════════════════════════════════
    // CONSTRUCT 6: Treasure Chest
    // ═══════════════════════════════════════════════════════
    AtxCreateConstruct("chest_common", {
        object: obj_quick_test_entity,
        layer: "Instances",
        config: {
            components: {
                LootDropComponent: {
                    goldMin: 50,
                    goldMax: 100,
                    dropChance: 1.0
                }
            },
            tags: {
                LootDropComponent: ["treasure", "common"]
            }
        }
    });
    
    // ═══════════════════════════════════════════════════════
    // CONSTRUCT 7: Rare Treasure Chest
    // ═══════════════════════════════════════════════════════
    AtxCreateConstruct("chest_rare", {
        object: obj_quick_test_entity,
        layer: "Instances",
        config: {
            components: {
                LootDropComponent: {
                    goldMin: 200,
                    goldMax: 500,
                    dropChance: 1.0
                }
            },
            tags: {
                LootDropComponent: ["treasure", "rare"]
            }
        }
    });
    
    // ═══════════════════════════════════════════════════════
    // CONSTRUCT 8: NPC Merchant
    // ═══════════════════════════════════════════════════════
    AtxCreateConstruct("npc_merchant", {
        object: obj_quick_test_entity,
        depth: -10,
        config: {
            components: {
                InventoryComponent: {
                    maxSlots: 50,
                    gold: 1000
                },
                QuestComponent: {
                    maxActiveQuests: 3
                }
            },
            tags: {
                InventoryComponent: ["merchant", "vendor"],
                QuestComponent: ["quest_giver"]
            }
        }
    });
    
    // ═══════════════════════════════════════════════════════
    // CONSTRUCT 9: NPC Quest Giver
    // ═══════════════════════════════════════════════════════
    AtxCreateConstruct("npc_quest_giver", {
        object: obj_quick_test_entity,
        layer: "Instances",
        config: {
            components: {
                QuestComponent: {
                    maxActiveQuests: 10
                }
            },
            tags: {
                QuestComponent: ["quest_giver", "important"]
            }
        }
    });
    
    // ═══════════════════════════════════════════════════════
    // CONSTRUCT 10: Boss - Dragon
    // ═══════════════════════════════════════════════════════
    AtxCreateConstruct("boss_dragon", {
        object: obj_quick_test_entity,
        depth: -100,
        config: {
            components: {
                TestHealthComponent: {
                    hitPoints: 500,
                    maxHitPoints: 500
                },
                TestCombatComponent: {
                    attackPower: 50
                },
                TestMovementComponent: {
                    moveSpeed: 3
                },
                AIComponent: {
                    aiType: "chase",
                    detectionRange: 400,
                    aggroRange: 350
                },
                WeaponComponent: {
                    weaponType: "breath",
                    damage: 50,
                    attackSpeed: 120,
                    range: 300
                },
                ArmorComponent: {
                    defense: 30,
                    damageReduction: 0.4,
                    armorType: "heavy"
                },
                StatusEffectComponent: {},
                LootDropComponent: {
                    goldMin: 500,
                    goldMax: 1000,
                    dropChance: 1.0
                },
                ExperienceComponent: {
                    level: 20
                }
            },
            tags: {
                TestHealthComponent: ["boss", "damageable", "elite"],
                AIComponent: ["hostile", "flying", "fire"],
                LootDropComponent: ["boss_loot", "guaranteed"]
            }
        }
    });
    
    // ═══════════════════════════════════════════════════════
    // CONSTRUCT 11: Healer NPC
    // ═══════════════════════════════════════════════════════
    AtxCreateConstruct("npc_healer", {
        object: obj_quick_test_entity,
        layer: "Instances",
        config: {
            components: {
                TestHealthComponent: {
                    hitPoints: 60,
                    maxHitPoints: 60
                },
                WeaponComponent: {
                    weaponType: "staff",
                    damage: 15,
                    attackSpeed: 60,
                    range: 150
                }
            },
            tags: {
                WeaponComponent: ["healing", "support"]
            }
        }
    });
    
    // ═══════════════════════════════════════════════════════
    // CONSTRUCT 12: Guard NPC
    // ═══════════════════════════════════════════════════════
    AtxCreateConstruct("npc_guard", {
        object: obj_quick_test_entity,
        layer: "Instances",
        config: {
            components: {
                TestHealthComponent: {
                    hitPoints: 120,
                    maxHitPoints: 120
                },
                TestCombatComponent: {
                    attackPower: 15
                },
                WeaponComponent: {
                    weaponType: "sword",
                    damage: 15,
                    attackSpeed: 45,
                    range: 50
                },
                ArmorComponent: {
                    defense: 20,
                    damageReduction: 0.25,
                    armorType: "heavy"
                },
                AIComponent: {
                    aiType: "patrol",
                    detectionRange: 200,
                    aggroRange: 150
                }
            },
            tags: {
                TestHealthComponent: ["friendly", "guard"],
                AIComponent: ["defensive", "patrol"]
            }
        }
    });
    
    // ═══════════════════════════════════════════════════════
    // CONSTRUCT 13: Training Dummy
    // ═══════════════════════════════════════════════════════
    AtxCreateConstruct("training_dummy", {
        object: obj_quick_test_entity,
        layer: "Instances",
        config: {
            components: {
                TestHealthComponent: {
                    hitPoints: 999999,
                    maxHitPoints: 999999
                },
                ArmorComponent: {
                    defense: 0,
                    damageReduction: 0,
                    armorType: "none"
                }
            },
            tags: {
                TestHealthComponent: ["training", "invulnerable"]
            }
        }
    });
    
    // ═══════════════════════════════════════════════════════
    // CONSTRUCT 14: Companion - Wolf
    // ═══════════════════════════════════════════════════════
    AtxCreateConstruct("companion_wolf", {
        object: obj_quick_test_entity,
        layer: "Instances",
        config: {
            components: {
                TestHealthComponent: {
                    hitPoints: 50,
                    maxHitPoints: 50
                },
                TestCombatComponent: {
                    attackPower: 12
                },
                TestMovementComponent: {
                    moveSpeed: 5
                },
                AIComponent: {
                    aiType: "follow",
                    detectionRange: 300,
                    aggroRange: 200
                }
            },
            tags: {
                TestHealthComponent: ["companion", "damageable"],
                AIComponent: ["friendly", "pet"]
            }
        }
    });
    
    // ═══════════════════════════════════════════════════════
    // CONSTRUCT 15: Projectile - Arrow
    // ═══════════════════════════════════════════════════════
    AtxCreateConstruct("projectile_arrow", {
        object: obj_quick_test_entity,
        depth: -20,
        config: {
            components: {
                TestCombatComponent: {
                    attackPower: 15
                },
                TestMovementComponent: {
                    moveSpeed: 8
                },
                TimerComponent: {}
            },
            tags: {
                TestCombatComponent: ["projectile", "physical"],
                TimerComponent: ["despawn_timer"]
            }
        }
    });
    
    show_debug_message("✅ Game constructs created: 15 constructs\n");
}

SetupGameConstructs();