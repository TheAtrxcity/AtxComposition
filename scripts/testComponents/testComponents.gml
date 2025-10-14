/// @description Game Components Library
/// @author TheAtrxcity
/// @date 2025-10-14 06:27:06 UTC

// ═══════════════════════════════════════════════════════
// COMPONENT 1: Inventory Component
// ═══════════════════════════════════════════════════════
function InventoryComponent() : AtxComponentBase() constructor
{
    name = "InventoryComponent";
    maxSlots = 20;
    items = [];
    gold = 0;
    
    static AddItem = function(_item)
    {
        if (array_length(items) < maxSlots)
        {
            array_push(items, _item);
            return true;
        }
        return false;
    }
    
    static RemoveItem = function(_item)
    {
        var _index = array_get_index(items, _item);
        if (_index != -1)
        {
            array_delete(items, _index, 1);
            return true;
        }
        return false;
    }
}

// ═══════════════════════════════════════════════════════
// COMPONENT 2: Experience Component
// ═══════════════════════════════════════════════════════
function ExperienceComponent() : AtxComponentBase() constructor
{
    name = "ExperienceComponent";
    level = 1;
    currentXP = 0;
    xpToNextLevel = 100;
    totalXP = 0;
    
    static AddXP = function(_amount)
    {
        currentXP += _amount;
        totalXP += _amount;
        
        while (currentXP >= xpToNextLevel)
        {
            LevelUp();
        }
    }
    
    static LevelUp = function()
    {
        currentXP -= xpToNextLevel;
        level++;
        xpToNextLevel = floor(xpToNextLevel * 1.5);
    }
}

// ═══════════════════════════════════════════════════════
// COMPONENT 3: AI Component
// ═══════════════════════════════════════════════════════
function AIComponent() : AtxComponentBase() constructor
{
    name = "AIComponent";
    aiType = "idle"; // idle, patrol, chase, attack, flee
    detectionRange = 200;
    target = noone;
    aggroRange = 150;
    fleeThreshold = 20; // HP percentage to flee
    
    static Step = function()
    {
        if (!enabled) return;
        
        switch(aiType)
        {
            case "idle":
                // Do nothing
                break;
            case "patrol":
                // Patrol logic
                break;
            case "chase":
                // Chase logic
                break;
        }
    }
}

// ═══════════════════════════════════════════════════════
// COMPONENT 4: Sprite Component
// ═══════════════════════════════════════════════════════
function SpriteComponent() : AtxComponentBase() constructor
{
    name = "SpriteComponent";
    spriteIndex = -1;
    imageIndex = 0;
    imageSpeed = 1;
    imageXScale = 1;
    imageYScale = 1;
    imageAlpha = 1;
    imageAngle = 0;
    imageBlend = c_white;
    
    static Draw = function()
    {
        if (!enabled || spriteIndex == -1) return;
        
        draw_sprite_ext(
            spriteIndex,
            imageIndex,
            owner.x,
            owner.y,
            imageXScale,
            imageYScale,
            imageAngle,
            imageBlend,
            imageAlpha
        );
    }
    
    static Step = function()
    {
        if (!enabled) return;
        imageIndex += imageSpeed;
    }
}

// ═══════════════════════════════════════════════════════
// COMPONENT 5: Timer Component
// ═══════════════════════════════════════════════════════
function TimerComponent() : AtxComponentBase() constructor
{
    name = "TimerComponent";
    timers = {};
    
    static CreateTimer = function(_name, _duration, _callback)
    {
        timers[$ _name] = {
            duration: _duration,
            elapsed: 0,
            callback: _callback,
            active: true
        };
    }
    
    static Step = function()
    {
        if (!enabled) return;
        
        var _timerNames = variable_struct_get_names(timers);
        for (var _i = 0; _i < array_length(_timerNames); _i++)
        {
            var _timer = timers[$ _timerNames[_i]];
            if (!_timer.active) continue;
            
            _timer.elapsed++;
            if (_timer.elapsed >= _timer.duration)
            {
                _timer.callback();
                _timer.active = false;
            }
        }
    }
}

// ═══════════════════════════════════════════════════════
// COMPONENT 6: Status Effect Component
// ═══════════════════════════════════════════════════════
function StatusEffectComponent() : AtxComponentBase() constructor
{
    name = "StatusEffectComponent";
    effects = []; // Array of {type, duration, strength}
    
    static AddEffect = function(_type, _duration, _strength)
    {
        array_push(effects, {
            type: _type,
            duration: _duration,
            strength: _strength,
            elapsed: 0
        });
    }
    
    static Step = function()
    {
        if (!enabled) return;
        
        for (var _i = array_length(effects) - 1; _i >= 0; _i--)
        {
            effects[_i].elapsed++;
            if (effects[_i].elapsed >= effects[_i].duration)
            {
                array_delete(effects, _i, 1);
            }
        }
    }
    
    static HasEffect = function(_type)
    {
        for (var _i = 0; _i < array_length(effects); _i++)
        {
            if (effects[_i].type == _type) return true;
        }
        return false;
    }
}

// ═══════════════════════════════════════════════════════
// COMPONENT 7: Weapon Component
// ═══════════════════════════════════════════════════════
function WeaponComponent() : AtxComponentBase() constructor
{
    name = "WeaponComponent";
    weaponType = "sword"; // sword, bow, staff, gun
    damage = 10;
    attackSpeed = 60; // Frames between attacks
    range = 50;
    projectileSprite = -1;
    lastAttackFrame = -999;
    
    static CanAttack = function()
    {
        return (current_time - lastAttackFrame) >= attackSpeed;
    }
    
    static Attack = function()
    {
        if (!CanAttack()) return false;
        lastAttackFrame = current_time;
        return true;
    }
}

// ═══════════════════════════════════════════════════════
// COMPONENT 8: Armor Component
// ═══════════════════════════════════════════════════════
function ArmorComponent() : AtxComponentBase() constructor
{
    name = "ArmorComponent";
    defense = 5;
    damageReduction = 0.1; // 10% damage reduction
    armorType = "light"; // light, medium, heavy
    durability = 100;
    maxDurability = 100;
    
    static CalculateDamageReduction = function(_incomingDamage)
    {
        var _reducedDamage = _incomingDamage * (1 - damageReduction);
        _reducedDamage = max(0, _reducedDamage - defense);
        return _reducedDamage;
    }
    
    static DamageDurability = function(_amount)
    {
        durability = max(0, durability - _amount);
        if (durability == 0)
        {
            defense = 0;
            damageReduction = 0;
        }
    }
}

// ═══════════════════════════════════════════════════════
// COMPONENT 9: Loot Drop Component
// ═══════════════════════════════════════════════════════
function LootDropComponent() : AtxComponentBase() constructor
{
    name = "LootDropComponent";
    lootTable = [];
    guaranteedDrops = [];
    goldMin = 0;
    goldMax = 10;
    dropChance = 0.5; // 50% chance to drop
    
    static AddLoot = function(_item, _chance, _quantityMin = 1, _quantityMax = 1)
    {
        array_push(lootTable, {
            item: _item,
            chance: _chance,
            quantityMin: _quantityMin,
            quantityMax: _quantityMax
        });
    }
    
    static DropLoot = function()
    {
        var _drops = [];
        
        // Guaranteed drops
        for (var _i = 0; _i < array_length(guaranteedDrops); _i++)
        {
            array_push(_drops, guaranteedDrops[_i]);
        }
        
        // Chance-based drops
        for (var _i = 0; _i < array_length(lootTable); _i++)
        {
            if (random(1) <= lootTable[_i].chance)
            {
                array_push(_drops, lootTable[_i].item);
            }
        }
        
        return _drops;
    }
}

// ═══════════════════════════════════════════════════════
// COMPONENT 10: Quest Component
// ═══════════════════════════════════════════════════════
function QuestComponent() : AtxComponentBase() constructor
{
    name = "QuestComponent";
    activeQuests = [];
    completedQuests = [];
    maxActiveQuests = 5;
    
    static AddQuest = function(_questId, _questData)
    {
        if (array_length(activeQuests) >= maxActiveQuests) return false;
        
        array_push(activeQuests, {
            id: _questId,
            data: _questData,
            progress: 0,
            started: current_time
        });
        return true;
    }
    
    static CompleteQuest = function(_questId)
    {
        for (var _i = 0; _i < array_length(activeQuests); _i++)
        {
            if (activeQuests[_i].id == _questId)
            {
                array_push(completedQuests, activeQuests[_i]);
                array_delete(activeQuests, _i, 1);
                return true;
            }
        }
        return false;
    }
    
    static HasQuest = function(_questId)
    {
        for (var _i = 0; _i < array_length(activeQuests); _i++)
        {
            if (activeQuests[_i].id == _questId) return true;
        }
        return false;
    }
}

/// @description Test Components for ECS System
/// @author TheAtrxcity
/// @date 2025-10-14 08:16:08 UTC

// ═══════════════════════════════════════════════════════
// TEST COMPONENT 1: Health Component
// ═══════════════════════════════════════════════════════
function TestHealthComponent() : AtxComponentBase() constructor
{
    name = "TestHealthComponent";
    hitPoints = 100;
    maxHitPoints = 100;
    isAlive = true;
    
    static TakeDamage = function(_amount)
    {
        if (!enabled) return;
        
        hitPoints -= _amount;
        hitPoints = max(0, hitPoints);
        
        if (hitPoints <= 0)
        {
            isAlive = false;
            Die();
        }
    }
    
    static Heal = function(_amount)
    {
        if (!enabled) return;
        
        hitPoints += _amount;
        hitPoints = min(hitPoints, maxHitPoints);
    }
    
    static Die = function()
    {
        show_debug_message($"Entity {owner} died!");
    }
    
    static Step = function()
    {
        if (!enabled) return;
        // Health regeneration could go here
    }
}

// ═══════════════════════════════════════════════════════
// TEST COMPONENT 2: Combat Component
// ═══════════════════════════════════════════════════════
function TestCombatComponent() : AtxComponentBase() constructor
{
    name = "TestCombatComponent";
    attackPower = 10;
    attackSpeed = 60; // Frames between attacks
    attackRange = 50;
    lastAttackTime = -999;
    
    static Attack = function(_target)
    {
        if (!enabled) return false;
        
        var _currentTime = current_time;
        if (_currentTime - lastAttackTime < attackSpeed) return false;
        
        lastAttackTime = _currentTime;
        
        // Deal damage to target
        if (instance_exists(_target) && variable_instance_exists(_target, "manager"))
        {
            if (_target.manager.HasComponent("TestHealthComponent"))
            {
                var _targetHealth = _target.manager.GetComponent("TestHealthComponent");
                _targetHealth.TakeDamage(attackPower);
                return true;
            }
        }
        
        return false;
    }
    
    static CanAttack = function()
    {
        if (!enabled) return false;
        return (current_time - lastAttackTime) >= attackSpeed;
    }
}

// ═══════════════════════════════════════════════════════
// TEST COMPONENT 3: Movement Component
// ═══════════════════════════════════════════════════════
function TestMovementComponent() : AtxComponentBase() constructor
{
    name = "TestMovementComponent";
    moveSpeed = 2;
    moveDirection = 0;
    isMoving = false;
    velocityX = 0;
    velocityY = 0;
    
    static Move = function(_dirX, _dirY)
    {
        if (!enabled) return;
        
        velocityX = _dirX * moveSpeed;
        velocityY = _dirY * moveSpeed;
        isMoving = (_dirX != 0 || _dirY != 0);
        
        if (isMoving)
        {
            moveDirection = point_direction(0, 0, _dirX, _dirY);
        }
    }
    
    static Step = function()
    {
        if (!enabled) return;
        
        if (isMoving && owner != undefined)
        {
            owner.x += velocityX;
            owner.y += velocityY;
        }
    }
    
    static Stop = function()
    {
        velocityX = 0;
        velocityY = 0;
        isMoving = false;
    }
}

// ═══════════════════════════════════════════════════════
// TEST COMPONENT 4: Render Component (for visual testing)
// ═══════════════════════════════════════════════════════
function TestRenderComponent() : AtxComponentBase() constructor
{
    name = "TestRenderComponent";
    drawColor = c_white;
    drawAlpha = 1;
    drawScale = 1;
    drawShape = "circle"; // circle, square, cross
    size = 16;
    
    static Draw = function()
    {
        if (!enabled || owner == undefined) return;
        
        draw_set_alpha(drawAlpha);
        draw_set_color(drawColor);
        
        switch(drawShape)
        {
            case "circle":
                draw_circle(owner.x, owner.y, size * drawScale, false);
                break;
                
            case "square":
                var _halfSize = size * drawScale;
                draw_rectangle(
                    owner.x - _halfSize, 
                    owner.y - _halfSize,
                    owner.x + _halfSize, 
                    owner.y + _halfSize,
                    false
                );
                break;
                
            case "cross":
                var _size = size * drawScale;
                draw_line_width(owner.x - _size, owner.y, owner.x + _size, owner.y, 3);
                draw_line_width(owner.x, owner.y - _size, owner.x, owner.y + _size, 3);
                break;
        }
        
        draw_set_alpha(1);
        draw_set_color(c_white);
    }
}

// ═══════════════════════════════════════════════════════
// TEST COMPONENT 5: Debug Component
// ═══════════════════════════════════════════════════════
function TestDebugComponent() : AtxComponentBase() constructor
{
    name = "TestDebugComponent";
    showInfo = true;
    showHealth = true;
    showPosition = true;
    
    static Draw = function()
    {
        if (!enabled || !showInfo || owner == undefined) return;
        
        var _textY = owner.y - 30;
        
        draw_set_color(c_white);
        draw_set_halign(fa_center);
        
        if (showHealth && owner.manager.HasComponent("TestHealthComponent"))
        {
            var _health = owner.manager.GetComponent("TestHealthComponent");
            draw_text(owner.x, _textY, $"{_health.hitPoints}/{_health.maxHitPoints}");
            _textY += 12;
        }
        
        if (showPosition)
        {
            draw_text(owner.x, _textY, $"({floor(owner.x)}, {floor(owner.y)})");
        }
        
        draw_set_halign(fa_left);
    }
}