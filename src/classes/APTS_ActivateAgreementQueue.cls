/*************************************************************
@Name: APTS_ActivateAgreementQueue
@Author: Wendy Kelley
@CreateDate: 23/02/2018
@Description: Queueable class for activating given list of agreements
@UsedBy: APTS_AgreementTriggerHandler class
******************************************************************/
public with sharing class APTS_ActivateAgreementQueue implements Queueable {

    private Set<Id> agmtIds;
    //public Set<Id> signedDocIds;

    public APTS_ActivateAgreementQueue(Set<Id> agmtIds) {
        this.agmtIds = agmtIds;
        //this.signedDocIds = signedDocIds;
    }
    
     /**
    * @author        Wendy Kelley
    * @date          23/02/2018
    * @description   Queuable class execute method
    * @params        QueueableContext
    * @return        void
    * @revision(s)
    */
    public void execute(QueueableContext context) {
        try {
            Map<Id, Id> agmAttMap = new Map<Id, Id>();
            for(Attachment att : [SELECT Id, ParentId FROM Attachment WHERE ParentId IN: agmtIds AND Name LIKE '%_signed%' ORDER BY CreatedDate]) {
                agmAttMap.put(att.parentId, att.Id);
            }
    
            for(Id agmtId : agmAttMap.keySet()) {
                boolean res = Apttus.AgreementWebService.activateAgreement(agmtId, new List<Id>{agmAttMap.get(agmtId)}, new List<Id>{});
            }
        } catch(Exception ex) {APTS_CustomLogging.createErrorLog(ex.getTypeName(), 'Batch', ex.getStackTraceString() ,'Agreement', null,'CLM',false,false, null, true);}
    }
}