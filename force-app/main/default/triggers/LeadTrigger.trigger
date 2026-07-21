/** 
@author                       Elie Habka
@date                         7/21/2026
@description                  This trigger runs automatically whenever a Lead is inserted or updated 
*/
trigger LeadTrigger on Lead (after insert, after update) {
    LeadTriggerHandler handler = new LeadTriggerHandler();

    if (handler.isDisabled()) {
        return;
    }

    if (Trigger.isAfter && Trigger.isInsert) {
        handler.afterInsert();
    }

    if (Trigger.isAfter && Trigger.isUpdate) {
        handler.afterUpdate();
    }
}