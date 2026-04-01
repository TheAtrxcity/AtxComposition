# AtxComposition

> A composition-over-inheritance framework for GameMaker 2.3+ — build flexible, reusable game entities without deep inheritance trees.

---

## Table of Contents

1. [Overview](#overview)
2. [Features](#features)
3. [Installation](#installation)
4. [Quick Start](#quick-start)
5. [Core Concepts](#core-concepts)
   - [Components](#components-atxcomponentbase)
   - [Component Manager](#component-manager-atxcomponentmanager)
   - [Constructs (Entity Templates)](#constructs-entity-templates)
   - [Events and Queries](#events-and-queries)
   - [Tagging](#tagging)
   - [Priority & Sorting](#priority--sorting)
   - [Component Dependencies](#component-dependencies)
6. [API Reference](#api-reference)
   - [AtxSetup](#atxsetup)
   - [AtxComponentBase](#atxcomponentbase-1)
   - [AtxComponentManager](#atxcomponentmanager-1)
   - [AtxConstructs](#atxconstructs-1)
   - [AtxSavingAndLoading](#atxsavingandloading-1)
7. [Save System](#save-system)
8. [Construct Templates](#construct-templates)
9. [Advanced Examples](#advanced-examples)
10. [Configuration](#configuration)
11. [License](#license)

---

## Overview

AtxComposition brings **Entity Component System (ECS)** design to GameMaker Studio 2.3+. Instead of building entities through deep `parent → child → grandchild` inheritance chains, you attach small, focused **components** to a central **Component Manager**. Each component handles a single concern — health, movement, rendering — and components communicate through an **event** and **query** system rather than direct coupling.

**Why composition over inheritance?**

| Inheritance | Composition |
|---|---|
| Behavior locked in object hierarchy | Mix and match any combination of behaviors |
| Changing a parent breaks all children | Components are independent and reusable |
| Hard to share logic across unrelated objects | Attach the same component to any entity |
| Deep trees become difficult to reason about | Flat, explicit component lists are easy to read |

---

## Features

- **Component-based architecture** — attach any number of components to any object
- **Lifecycle hooks** — `Step`, `Draw`, `DrawGUI`, and `Cleanup` methods per component, automatically called by the manager
- **Priority-based ordering** — control the execution order of Step, Draw, and DrawGUI across components
- **Event system** — broadcast named events with data to all listening components
- **Query system** — gather data from components (`Query`, `QueryFirst`, `QueryReduce`) without tight coupling
- **Tagging** — categorize components with string tags and perform bulk enable/disable/event operations
- **Component dependencies** — declare `requires` arrays so the manager enforces correct setup order
- **Construct registry** — register entity templates (prefabs) and spawn them by name with optional overrides
- **Full save/load system** — serialize and restore all saveable entities to JSON with priority-ordered loading
- **Save slot management** — check existence, retrieve metadata, validate, and delete save files

---

## Installation

1. Download or clone this repository.
2. In GameMaker, go to **Tools → Import Local Package** (or drag-and-drop the `.yymps` file onto the IDE).
3. Import all assets from the package, or at minimum:
   - `scripts/AtxSetup`
   - `scripts/AtxComponentBase`
   - `scripts/AtxComponentManager`
   - `scripts/AtxConstructs`
   - `scripts/AtxSavingAndLoading`
   - `objects/__atxConstructParent`
4. **AtxSetup** runs automatically at game start — it initializes the save directory and the pending-load state.

> **GameMaker version:** Requires GML 2.3+ (structs, constructors, and `method()` support).

---

## Quick Start

### 1. Create a component

Every component extends `AtxComponentBase`. Define your data as properties and your logic as `Step`, `Draw`, `DrawGUI`, or `Cleanup` methods.

```gml
// scripts/CmpHealth/CmpHealth.gml
function CmpHealth() : AtxComponentBase() constructor
{
    maxHealth = 100;
    health    = 100;

    Step = function()
    {
        if (health <= 0)
        {
            // signal other components through an event
            componentManager.TriggerEvent("died", {});
        }
    }

    events.takeDamage = function(_data)
    {
        health -= _data.amount;
        health  = clamp(health, 0, maxHealth);
    }
}
```

### 2. Create an object that uses the manager

Either use `__atxConstructParent` as the parent object (it wires up everything automatically), or do it manually in your own object:

**Create event:**
```gml
manager = new AtxComponentManager(self);
manager.AddComponent(new CmpHealth());
```

**Step event:**
```gml
manager.Step();
```

**Draw event:**
```gml
manager.Draw();
```

**Cleanup event:**
```gml
manager.Cleanup();
```

### 3. Communicate between components

```gml
// Fire a damage event — CmpHealth.events.takeDamage will be called
manager.TriggerEvent("takeDamage", { amount: 25 });

// Read health directly
var _health = manager.GetComponent("CmpHealth");
show_debug_message($"HP: {_health.health}");
```

---

## Core Concepts

### Components (`AtxComponentBase`)

A component is a constructor that extends `AtxComponentBase`. It holds data and optionally defines lifecycle methods and event/query handlers.

```gml
function CmpMovement() : AtxComponentBase() constructor
{
    speed     = 4;
    direction = 0;

    // Called every step if this component is enabled
    Step = function()
    {
        parentInstance.x += lengthdir_x(speed, direction);
        parentInstance.y += lengthdir_y(speed, direction);
    }
}
```

**Key base properties:**

| Property | Default | Description |
|---|---|---|
| `parentInstance` | `noone` | The GameMaker instance that owns the manager |
| `componentManager` | `undefined` | Reference to the owning `AtxComponentManager` |
| `events` | `{}` | Struct of named event handler functions |
| `queries` | `{}` | Struct of named query functions |
| `enabled` | `true` | Whether this component participates in lifecycle calls |
| `stepPriority` | `100` | Execution order for Step (lower = earlier) |
| `drawPriority` | `100` | Execution order for Draw (lower = drawn first) |
| `DrawGUIPriority` | `100` | Execution order for DrawGUI (lower = drawn first) |
| `requires` | `[]` | Array of component names this component depends on |

Setting `Step`, `Draw`, `DrawGUI`, or `Cleanup` to `undefined` (the default) means the manager skips that component for the corresponding lifecycle pass — there is no overhead for empty hooks.

---

### Component Manager (`AtxComponentManager`)

The manager is the central hub of an entity. It owns all components and drives their lifecycle.

```gml
// Minimal setup inside an object's Create event
manager = new AtxComponentManager(self);
```

```gml
// With save system options
manager = new AtxComponentManager(self, true, ATX_SAVE.PLAYER);
//                                 ^caller  ^enableSave  ^savePriority
```

The `__atxConstructParent` object does all of this for you automatically — just set it as the parent of your entity objects.

---

### Constructs (Entity Templates)

Constructs are reusable entity templates stored in a global registry. Register a template once, then spawn instances of it anywhere.

```gml
// Register a template (e.g., in a controller object's Create event)
AtxCreateConstruct("enemy_goblin", {
    object : obj_enemy,
    layer  : "Instances",
    config : {
        components : {
            CmpHealth   : { maxHealth: 30, health: 30 },
            CmpMovement : { speed: 2 },
        },
        tags : {
            CmpHealth : ["damageable"],
        }
    }
});

// Spawn an instance
var _goblin = AtxSpawnConstruct("enemy_goblin", 256, 128);
```

---

### Events and Queries

**Events** are fire-and-forget broadcasts. Any component that has registered a handler under the same name will be called.

```gml
// Component defines a handler
events.onHeal = function(_data)
{
    health = min(health + _data.amount, maxHealth);
}

// Somewhere in game code, trigger the event
manager.TriggerEvent("onHeal", { amount: 10 });
```

**Queries** ask components for data and collect results.

```gml
// Component defines a query
queries.getStats = function(_data)
{
    return { health: health, maxHealth: maxHealth };
}

// Game code asks for all stats
var _results = manager.Query("getStats");     // array of all results
var _first   = manager.QueryFirst("getStats"); // first non-undefined result

// Accumulator pattern — sum total damage modifiers
var _totalMod = manager.QueryReduce("getDamageModifier", 1.0);
```

---

### Tagging

Tags let you group components and perform bulk operations.

```gml
// Add tags when adding a component
manager.AddComponent(new CmpPoison());
manager.AddTag("CmpPoison", "statusEffect");

// Or add multiple tags at once
manager.AddTags("CmpPoison", ["statusEffect", "debuff"]);

// Bulk enable/disable by tag
manager.DisableComponentsByTag("statusEffect");
manager.EnableComponentsByTag("statusEffect");

// Fire an event on all components with a specific tag
manager.TriggerEventsWithTag("statusEffect", "tick", { delta: 1 });

// Query only tagged components
var _results = manager.QueryByTag("statusEffect", "getTickDamage");
```

---

### Priority & Sorting

Lower priority numbers execute first. This applies independently to Step, Draw, and DrawGUI.

```gml
// Suggested priority ranges (from AtxComponentBase comments):
// 0  – 99  : Begin Step / early update
// 100–200  : Normal Step
// 200+     : Late Step / post-update

manager.SetStepPriority("CmpPhysics",   50);   // runs before
manager.SetStepPriority("CmpMovement", 100);   // runs after
manager.SetDrawPriority("CmpShadow",    10);   // drawn first (below)
manager.SetDrawPriority("CmpSprite",   100);   // drawn on top

// Or set step + draw to the same value
manager.SetBothPriority("CmpHUD", 200);

// Or set all three at once
manager.SetAllPriority("CmpDebug", 999);
```

---

### Component Dependencies

Use the `requires` array to declare that a component needs other components to be present first. The manager enforces this when `AddComponent` is called.

```gml
function CmpArmor() : AtxComponentBase() constructor
{
    requires = ["CmpHealth"]; // CmpHealth must be added before CmpArmor

    defense = 5;

    events.takeDamage = function(_data)
    {
        // Reduce incoming damage — CmpHealth will receive the remainder
        _data.amount = max(0, _data.amount - defense);
        componentManager.TriggerEvent("takeDamage", _data, "CmpHealth");
    }
}
```

If `CmpHealth` is missing when `AddComponent(new CmpArmor())` is called, the manager logs a warning and does **not** add the component.

---

## API Reference

### AtxSetup

| Symbol | Type | Description |
|---|---|---|
| `ATX_GAME_VERSION` | macro | Your game's version number (default `0`). Stored in save metadata. |
| `ATX_SAVE` | enum | Save priority constants: `SYSTEM(0)`, `INTERACTABLES(1)`, `ENVIRONMENT(2)`, `ITEMS(3)`, `DEFAULT(4)`, `NPC(5)`, `ENEMY(6)`, `PLAYER(7)` |
| `global.__atxSaveConfig` | struct | `saveDirectory` (`"saves/"`) and `maxSaveSlots` (`10`) |

---

### AtxComponentBase

**Constructor:** `AtxComponentBase()`

| Member | Type | Description |
|---|---|---|
| `parentInstance` | `Id.Instance` | Owner instance, set by `SetParent` |
| `componentManager` | `struct` | Owning manager, set by `SetParent` |
| `events` | `struct` | Named event handler functions |
| `queries` | `struct` | Named query functions |
| `enabled` | `bool` | Whether lifecycle methods are called |
| `stepPriority` | `real` | Step execution order |
| `drawPriority` | `real` | Draw execution order |
| `DrawGUIPriority` | `real` | DrawGUI execution order |
| `requires` | `array<string>` | Required component names |
| `Step` | `function\|undefined` | Called every Step event |
| `Draw` | `function\|undefined` | Called every Draw event |
| `DrawGUI` | `function\|undefined` | Called every Draw GUI event |
| `Cleanup` | `function\|undefined` | Called on instance Cleanup |

**Static methods:**

| Method | Signature | Description |
|---|---|---|
| `SetParent` | `(_componentManager)` | Sets `parentInstance` and `componentManager`. Called automatically by `AddComponent`. |

---

### AtxComponentManager

**Constructor:** `AtxComponentManager(_caller, _enableSave = true, _priority = ATX_SAVE.DEFAULT)`

#### Adding / Removing

| Method | Signature | Returns | Description |
|---|---|---|---|
| `AddComponent` | `(_component, _overrides = undefined)` | `struct\|undefined` | Adds a component. Checks dependencies first. Returns the component on success. |
| `RemoveComponent` | `(_componentKey)` | `bool` | Removes a component by name. Fails if other components depend on it. |

#### Lifecycle

| Method | Signature | Returns | Description |
|---|---|---|---|
| `Step` | `()` | `undefined` | Runs `Step()` on all enabled components, sorted by `stepPriority`. |
| `Draw` | `()` | `undefined` | Runs `Draw()` on all enabled components, sorted by `drawPriority`. |
| `DrawGUI` | `()` | `undefined` | Runs `DrawGUI()` on all enabled components, sorted by `DrawGUIPriority`. |
| `Cleanup` | `()` | `undefined` | Runs `Cleanup()` on all components that have it defined. |

#### Enabling / Disabling

| Method | Signature | Returns | Description |
|---|---|---|---|
| `EnableComponent` | `(_componentKey)` | `bool` | Enables a single component. |
| `DisableComponent` | `(_componentKey)` | `bool` | Disables a single component. |
| `EnableAllComponents` | `()` | `undefined` | Enables every component. |
| `DisableAllComponents` | `()` | `undefined` | Disables every component. |
| `EnableAllComponentsExcept` | `(_names)` | `undefined` | Enables all except the named component(s). |
| `DisableAllComponentsExcept` | `(_names)` | `undefined` | Disables all except the named component(s). |

#### Getting Components

| Method | Signature | Returns | Description |
|---|---|---|---|
| `GetComponent` | `(_component)` | `struct\|undefined` | Returns a component by name, or `undefined`. |
| `GetAllComponents` | `()` | `struct` | Returns the raw components struct. |
| `GetAllComponentKeys` | `()` | `array<string>` | Returns an array of all component names. |
| `GetComponentCount` | `()` | `real` | Number of registered components. |
| `HasComponent` | `(_component)` | `bool` | `true` if the component is registered. |
| `HasTheseComponents` | `(_names)` | `bool` | `true` if **all** named components are registered. |
| `HasAnyOfTheseComponents` | `(_names)` | `bool` | `true` if **any** named components are registered. |
| `GetComponentsWithEvent` | `(_eventName)` | `array<struct>` | Components that registered a handler for this event. |

#### Priority / Sorting

| Method | Signature | Returns | Description |
|---|---|---|---|
| `GetStepPriority` | `(_componentKey)` | `real\|undefined` | Gets step priority. |
| `SetStepPriority` | `(_componentKey, _priority)` | `bool` | Sets step priority and marks sort needed. |
| `GetDrawPriority` | `(_componentKey)` | `real\|undefined` | Gets draw priority. |
| `SetDrawPriority` | `(_componentKey, _priority)` | `bool` | Sets draw priority and marks sort needed. |
| `GetDrawGUIPriority` | `(_componentKey)` | `real\|undefined` | Gets DrawGUI priority. |
| `SetDrawGUIPriority` | `(_componentKey, _priority)` | `bool` | Sets DrawGUI priority and marks sort needed. |
| `SetBothPriority` | `(_componentKey, _priority)` | `bool` | Sets step and draw priorities to the same value. |
| `SetAllPriority` | `(_componentKey, _priority)` | `bool` | Sets step, draw, and DrawGUI priorities to the same value. |
| `SortStepComponents` | `()` | `undefined` | Manually triggers step sort. |
| `SortDrawComponents` | `()` | `undefined` | Manually triggers draw sort. |
| `SortDrawGUIComponents` | `()` | `undefined` | Manually triggers DrawGUI sort. |

#### Events

| Method | Signature | Returns | Description |
|---|---|---|---|
| `TriggerEvent` | `(_eventName, _eventData, _componentKey = undefined)` | `undefined` | Broadcasts an event to all components (or one specific component) that registered a handler for it. |

#### Queries

| Method | Signature | Returns | Description |
|---|---|---|---|
| `Query` | `(_queryName, _data = {})` | `array` | Returns an array of all non-`undefined` results from query handlers. |
| `QueryFirst` | `(_queryName, _data = {})` | `any` | Returns the first non-`undefined` result. |
| `QueryReduce` | `(_queryName, _initialValue, _data = {})` | `any` | Accumulates results; each handler receives `_data.accumulator`. |
| `QueryByTag` | `(_tag, _queryName, _data)` | `array` | `Query` restricted to components with a specific tag. |
| `QueryByTagFirst` | `(_tag, _queryName, _data)` | `any` | `QueryFirst` restricted to components with a specific tag. |
| `QueryReduceByTag` | `(_tag, _queryName, _initialValue, _data = {})` | `any` | `QueryReduce` restricted to components with a specific tag. |

#### Tagging

| Method | Signature | Returns | Description |
|---|---|---|---|
| `AddTag` | `(_componentKey, _tag)` | `bool` | Adds a tag to a component. |
| `AddTags` | `(_componentKey, _tagArray)` | `real` | Adds multiple tags at once. Returns the count added. |
| `RemoveTag` | `(_componentKey, _tag)` | `bool` | Removes a tag from a component. |
| `HasTag` | `(_componentKey, _tag)` | `bool` | `true` if the component has the tag. |
| `GetComponentsWithTag` | `(_tag)` | `array<string>` | Component keys that have this tag. |
| `GetComponentTags` | `(_componentKey)` | `array<string>` | All tags on a specific component. |
| `GetAllTags` | `()` | `array<string>` | All tags currently in use. |
| `GetTagCount` | `(_tag)` | `real` | Number of components with this tag. |
| `EnableComponentsByTag` | `(_tag)` | `real` | Enables all components with the tag; returns count. |
| `DisableComponentsByTag` | `(_tag)` | `real` | Disables all components with the tag; returns count. |
| `TriggerEventsWithTag` | `(_tag, _eventKey, _data)` | `undefined` | Fires an event only on components with this tag. |

#### Dependencies

| Method | Signature | Returns | Description |
|---|---|---|---|
| `HasAllDependencies` | `(_component)` | `bool` | `true` if all entries in `_component.requires` are present. |
| `GetMissingDependencies` | `(_component)` | `array<string>` | Names of required components not yet registered. |
| `GetDependents` | `(_componentKey)` | `array<string>` | Names of components that list `_componentKey` in their `requires`. |

#### Helpers

| Method | Signature | Returns | Description |
|---|---|---|---|
| `ResolveComponentKey` | `(_componentOrKey)` | `string\|undefined` | Converts a component instance or partial name to its full key. |

---

### AtxConstructs

| Function | Signature | Returns | Description |
|---|---|---|---|
| `AtxCreateConstruct` | `(_constructName, _config = {})` | `bool` | Registers a construct template. `_config` must have `object` and `layer`/`depth`. |
| `AtxSpawnConstruct` | `(_constructName, _x, _y, _layerOrDepthOverride = undefined, _overrides = undefined)` | `Id.Instance\|undefined` | Instantiates a construct from the registry. |
| `AtxCreateComponentFromConfig` | `(_componentName, _componentConfig)` | `struct\|undefined` | Creates a component instance from a config struct. |
| `AtxGetConstruct` | `(_constructName)` | `struct\|undefined` | Returns the template config, or `undefined`. |
| `AtxGetAllConstructs` | `()` | `array<string>` | Returns all registered construct names. |
| `AtxConstructExists` | `(_constructName)` | `bool` | `true` if the construct is registered. |
| `AtxDeleteConstruct` | `(_constructName)` | `bool` | Removes a construct from the registry. |
| `AtxSaveConstructsToFile` | `(_fileName)` | `undefined` | Serializes all registered constructs to a JSON file. |
| `AtxLoadConstructsFromFile` | `(_fileName, _clearExisting = true)` | `undefined` | Loads constructs from a JSON file into the registry. |

---

### AtxSavingAndLoading

| Function | Signature | Returns | Description |
|---|---|---|---|
| `AtxInitialiseSaveSystem` | `()` | `undefined` | Creates the save directory and initializes pending-load state. Called automatically by AtxSetup. |
| `AtxSaveGame` | `(_saveName, _slotNumber = 0)` | `bool` | Serializes all saveable instances to `saves/save_N.json`. |
| `AtxLoadGame` | `(_slotNumber = 0, _clearRoom = true)` | `bool` | Loads a save, optionally clearing the room and transitioning to the saved room. |
| `AtxClearSaveableEntities` | `()` | `undefined` | Destroys all non-persistent instances that have save enabled. |
| `AtxSaveExists` | `(_slotNumber = 0)` | `bool` | `true` if a save file exists in the slot. |
| `AtxDeleteSave` | `(_slotNumber = 0)` | `bool` | Deletes a save file. |
| `AtxGetSaveMetadata` | `(_slotNumber = 0)` | `struct\|undefined` | Reads only the metadata from a save file (fast — does not load constructs). |
| `AtxGetSaves` | `(_saveAmount = maxSaveSlots)` | `array<struct>` | Returns an array of `{ slotNumber, exists, metaData }` for every slot. |
| `AtxValidateSave` | `(_slotNumber = 0)` | `bool` | Validates that a save file is not corrupted and has all required fields. |

---

## Save System

### Configuration

Edit `scripts/AtxSetup/AtxSetup.gml` to change the save directory or the maximum number of save slots:

```gml
// AtxSetup.gml
#macro ATX_GAME_VERSION 1   // increment with each game update

global.__atxSaveConfig =
{
    saveDirectory : "saves/",  // relative to %localappdata%/<GameName>/
    maxSaveSlots  : 10,
}
```

Use `ATX_SAVE` priorities to control **load order** when restoring a game. Entities with lower priority values are spawned first:

```gml
// Examples
manager = new AtxComponentManager(self, true, ATX_SAVE.SYSTEM);       // loads first
manager = new AtxComponentManager(self, true, ATX_SAVE.PLAYER);       // loads last
manager = new AtxComponentManager(self, true, ATX_SAVE.DEFAULT);      // middle
manager = new AtxComponentManager(self, false);                        // not saved
```

### Saving the game

```gml
// Save to slot 0 with a display name
AtxSaveGame("Slot 1 – Chapter 2", 0);
```

The save file captures per-instance properties (`x`, `y`, `depth`, `direction`, `speed`, image settings) and all component data, minus internal framework fields.

### Loading the game

```gml
// Load slot 0, clearing existing saveable entities first
AtxLoadGame(0, true);
```

If the saved room differs from the current room, `AtxLoadGame` automatically transitions there and resumes loading after the room switch completes (using a `time_source`).

### Save file management

```gml
// Check before loading
if (AtxSaveExists(0))
{
    if (AtxValidateSave(0))
    {
        AtxLoadGame(0);
    }
    else
    {
        show_debug_message("Save file is corrupted.");
    }
}

// Delete a save
AtxDeleteSave(0);

// Read metadata without loading the full save (useful for save select screens)
var _meta = AtxGetSaveMetadata(0);
if (_meta != undefined)
{
    draw_text(10, 10, $"Save: {_meta.saveName}");
    draw_text(10, 30, $"Room: {_meta.roomName}");
    draw_text(10, 50, $"Time: {date_datetime_string(_meta.timeStamp)}");
}

// Build a save-select screen
var _saves = AtxGetSaves();
for (var _i = 0; _i < array_length(_saves); _i++)
{
    var _slot = _saves[_i];
    if (_slot.exists)
    {
        draw_text(10, 10 + _i * 20, $"Slot {_slot.slotNumber}: {_slot.metaData.saveName}");
    }
    else
    {
        draw_text(10, 10 + _i * 20, $"Slot {_slot.slotNumber}: Empty");
    }
}
```

---

## Construct Templates

### Registering a construct

```gml
AtxCreateConstruct("player", {
    object : obj_player,
    layer  : "Instances",
    config : {
        components : {
            CmpHealth   : { maxHealth: 100, health: 100 },
            CmpMovement : { speed: 4 },
            CmpSprite   : { sprite: spr_player },
        },
        tags : {
            CmpHealth : ["damageable"],
        }
    },
    savePriority : ATX_SAVE.PLAYER,
});
```

- `object` — GameMaker object asset name or index (required)
- `layer` or `depth` — placement on creation (one is required)
- `config.components` — struct of `ComponentName: { ...properties }` pairs
- `config.tags` — struct of `ComponentName: ["tag1", "tag2"]` pairs
- `savePriority` — overrides the default save load order

### Spawning with overrides

```gml
// Spawn at default values
var _player = AtxSpawnConstruct("player", room_width / 2, room_height / 2);

// Spawn with a different layer
var _enemy = AtxSpawnConstruct("enemy_goblin", 400, 300, "EnemyLayer");

// Spawn with component overrides (e.g., a stronger variant)
var _boss = AtxSpawnConstruct("enemy_goblin", 600, 300, undefined, {
    CmpHealth   : { maxHealth: 200, health: 200 },
    CmpMovement : { speed: 1 },
});
```

### Saving and loading construct definitions

Persist your entire construct registry to a file so it can be loaded later (useful for moddable games or data-driven designs):

```gml
// Save all registered constructs
AtxSaveConstructsToFile("constructs.json");

// Load constructs, clearing any previously registered ones
AtxLoadConstructsFromFile("constructs.json", true);

// Load without clearing
AtxLoadConstructsFromFile("extra_constructs.json", false);
```

---

## Advanced Examples

### Health component with damage and heal events

```gml
function CmpHealth() : AtxComponentBase() constructor
{
    maxHealth = 100;
    health    = 100;
    isDead    = false;

    Step = function()
    {
        if (health <= 0 && !isDead)
        {
            isDead = true;
            componentManager.TriggerEvent("died", {});
        }
    }

    events.takeDamage = function(_data)
    {
        if (isDead) return;
        health -= _data.amount;
        health  = max(0, health);
        show_debug_message($"Took {_data.amount} damage. HP: {health}/{maxHealth}");
    }

    events.heal = function(_data)
    {
        health += _data.amount;
        health  = min(health, maxHealth);
        show_debug_message($"Healed {_data.amount}. HP: {health}/{maxHealth}");
    }

    queries.getHealth = function(_data)
    {
        return { current: health, max: maxHealth, ratio: health / maxHealth };
    }
}
```

```gml
// Usage
manager.TriggerEvent("takeDamage", { amount: 15 });
manager.TriggerEvent("heal",       { amount: 5  });

var _hp = manager.QueryFirst("getHealth");
draw_healthbar(10, 10, 110, 20, _hp.ratio * 100, c_black, c_red, c_lime, 0, true, true);
```

---

### Movement component with step logic

```gml
function CmpMovement() : AtxComponentBase() constructor
{
    speed        = 4;
    acceleration = 0.5;
    friction_val = 0.8;

    _vx = 0;
    _vy = 0;

    Step = function()
    {
        var _input_x = (keyboard_check(vk_right) - keyboard_check(vk_left));
        var _input_y = (keyboard_check(vk_down)  - keyboard_check(vk_up));

        _vx += _input_x * acceleration;
        _vy += _input_y * acceleration;

        _vx = clamp(_vx, -speed, speed);
        _vy = clamp(_vy, -speed, speed);

        _vx *= friction_val;
        _vy *= friction_val;

        parentInstance.x += _vx;
        parentInstance.y += _vy;
    }
}
```

---

### Sprite renderer component

```gml
function CmpSprite() : AtxComponentBase() constructor
{
    sprite      = spr_player;
    subimage    = 0;
    animSpeed   = 0.25;
    xscale      = 1;
    yscale      = 1;
    blendColour = c_white;
    alpha       = 1;

    drawPriority = 10; // draw early so other components draw on top

    Draw = function()
    {
        subimage = (subimage + animSpeed) mod sprite_get_number(sprite);
        draw_sprite_ext(sprite, floor(subimage),
            parentInstance.x, parentInstance.y,
            xscale, yscale, 0, blendColour, alpha);
    }
}
```

---

### Using queries to gather data from components

```gml
// Every buff/debuff component registers a damage modifier
function CmpBuff_strengthPotion() : AtxComponentBase() constructor
{
    modifier  = 1.5;
    duration  = 300; // steps

    Step = function()
    {
        duration--;
        if (duration <= 0) componentManager.RemoveComponent("CmpBuff_strengthPotion");
    }

    queries.getDamageModifier = function(_data)
    {
        return _data.accumulator * modifier; // multiply into accumulator
    }
}

// When dealing damage, reduce all modifiers to one value
var _baseDamage  = 10;
var _finalDamage = manager.QueryReduce("getDamageModifier", _baseDamage);
show_debug_message($"Dealing {_finalDamage} damage.");
```

---

### Using tags to categorize and bulk-operate on components

```gml
// Create a freeze effect that disables all movement-related components
manager.AddTag("CmpMovement", "movement");
manager.AddTag("CmpDash",     "movement");
manager.AddTag("CmpJump",     "movement");

// Freeze the player
manager.DisableComponentsByTag("movement");

// Unfreeze after 2 seconds
call_later(2, time_source_units_seconds, function()
{
    manager.EnableComponentsByTag("movement");
});
```

---

### Component dependencies

```gml
function CmpShield() : AtxComponentBase() constructor
{
    // Shield requires a health component to intercept damage
    requires = ["CmpHealth"];

    shieldPoints    = 50;
    maxShieldPoints = 50;

    events.takeDamage = function(_data)
    {
        var _blocked = min(_data.amount, shieldPoints);
        shieldPoints -= _blocked;
        _data.amount -= _blocked;

        // Pass remaining damage to CmpHealth
        if (_data.amount > 0)
        {
            componentManager.TriggerEvent("takeDamage", _data, "CmpHealth");
        }
    }
}

// This will succeed only if CmpHealth is already added
manager.AddComponent(new CmpHealth());
manager.AddComponent(new CmpShield()); // OK

// This would log a warning and return undefined
// manager.AddComponent(new CmpShield()); // FAIL — CmpHealth missing
```

---

## Configuration

All library configuration lives in `scripts/AtxSetup/AtxSetup.gml`.

### `ATX_GAME_VERSION`

```gml
#macro ATX_GAME_VERSION 1
```

Stored in every save file's metadata. Use this to detect outdated saves and handle migration.

### `ATX_SAVE` enum

Controls the order in which entities are spawned during a load. Entities are sorted ascending by priority before spawning.

```gml
enum ATX_SAVE
{
    SYSTEM        = 0, // game managers, controllers
    INTERACTABLES = 1, // doors, chests
    ENVIRONMENT   = 2, // platforms, terrain
    ITEMS         = 3, // pickups, collectibles
    DEFAULT       = 4, // general purpose
    NPC           = 5,
    ENEMY         = 6,
    PLAYER        = 7, // player is always last
}
```

### `global.__atxSaveConfig`

```gml
global.__atxSaveConfig =
{
    saveDirectory : "saves/",  // folder created inside %localappdata%/<GameName>/
    maxSaveSlots  : 10,        // used by AtxGetSaves() as the default scan range
}
```

---

## License

This project is licensed under the **MIT License**. See the [LICENSE](LICENSE) file for details.
