/** 
@author                       Elie Habka
@date                         7/21/2026
@description                  This trigger runs automatically whenever an Opportunity is created or updated  
*/
trigger OpportunityTrigger on Opportunity (before insert, before update, after insert, after update) {
new OpportunityTriggerHandler().run(); 
}