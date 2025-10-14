function AtxComponentBase() constructor
{
   parentInstance = noone;
   componentManager = undefined;
   events = {};
   queries = {};
   enabled = true;

   // Think along these lines:
   // 0 - 99    : Begin Step
   // 100 - 200 : Step
   // 200+      : Late Step
   stepPriority = 100;
   
   // Think of draw priority as the draw order.
   // Lower numbers will be drawn first higher numbers last. 
   drawPriority = 100;
   
   requires = [];
   
   Step = undefined;
   Draw = undefined;
   Cleanup = undefined;
   
   static SetParent = function (_componentManager) 
   {
      parentInstance = _componentManager.parentInstance;
      componentManager = _componentManager;
   }
}