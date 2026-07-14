public with sharing class OpportunityTriggerHandler extends TriggerHandler implements ITriggerHandler {

    private Map<Id, Opportunity> newMap;
    private Map<Id, Opportunity> oldMap;
    private List<Opportunity> TriggerNew;
    private List<Opportunity> TriggerOld;
    
    public OpportunityTriggerHandler() {
        this.newMap = (Map<Id, Opportunity>) Trigger.newMap;
        this.oldMap = (Map<Id, Opportunity>) Trigger.oldMap;
        this.TriggerNew = (List<Opportunity>) Trigger.New;
        this.TriggerOld = (List<Opportunity>) Trigger.Old;
    }
    
    public static Boolean TriggerDisabled = false;
    
    public Boolean isDisabled() {
        return TriggerDisabled;
    }
    public override void beforeInsert() {
    }
    public override void beforeUpdate() {
    }
    public override void afterInsert() {
    }
public override void afterUpdate() {
        // Create a list to hold the IDs of the opportunities that match our criteria
        List<Id> oppIdsToSend = new List<Id>();
        
        for (Opportunity opp : TriggerNew) {
            if ((opp.StageName == 'Closed Won' && oldMap.get(opp.Id).StageName != 'Closed Won' )||(opp.StageName == 'Closed Lost' && oldMap.get(opp.Id).StageName != 'Closed Lost')) {
                oppIdsToSend.add(opp.Id); 
            }
        }
        if (!oppIdsToSend.isEmpty()) {
            OpportunityPDFEmailer.sendOpportunityPDF(oppIdsToSend); 
        }
    }
    
    public override void beforeDelete() {}
    public override void afterDelete() {}
    public override void afterUnDelete() {}
}



