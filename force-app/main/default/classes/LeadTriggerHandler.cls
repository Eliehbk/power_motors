/** 
@author                       Elie Habka
@date                         7/21/2026
@description                  This class checks if a Lead's website address was just added or changed,
                              and triggers an asynchronous lookup for those Leads 
*/
public with sharing class LeadTriggerHandler extends TriggerHandler { 
    private Map<Id, Lead> newMap;
    private Map<Id, Lead> oldMap;
    private List<Lead> TriggerNew;
    private List<Lead> TriggerOld;

    public LeadTriggerHandler() {
        this.newMap = (Map<Id,Lead>) Trigger.newMap;
        this.oldMap = (Map<Id, Lead>) Trigger.oldMap;
        this.TriggerNew = (List<Lead>) Trigger.New;
        this.TriggerOld = (List<Lead>) Trigger.Old;
    }

    public static Boolean TriggerDisabled = false;
    
    public Boolean isDisabled() {
        return TriggerDisabled;
    }

    public override void beforeInsert() {}
    public override void beforeUpdate() {}
    
    // Added the override keyword right here
    
    public override void afterInsert() {
        List<Id> eligibleLeads = new List<Id>();
        
        for (Lead ld : this.TriggerNew) {
            if (String.isNotBlank(ld.Website)) {
                eligibleLeads.add(ld.Id);
            }
        }
        if (!eligibleLeads.isEmpty()) {
    LeadLookupManager.lookupLeadsAsync(eligibleLeads);
}
    }

  public override void afterUpdate() {
    List<Id> eligibleLeads = new List<Id>();

    for (Lead ld : this.TriggerNew) {
        Lead oldLead = oldMap.get(ld.Id);
        if (ld.Website != oldLead.Website && String.isNotBlank(ld.Website)) {
            eligibleLeads.add(ld.Id);}}
    
            if (!eligibleLeads.isEmpty()) {
        LeadLookupManager.lookupLeadsAsync(eligibleLeads);
    }}
    public override void beforeDelete() {}
    public override void afterDelete() {}
    public override void afterUnDelete() {}
}