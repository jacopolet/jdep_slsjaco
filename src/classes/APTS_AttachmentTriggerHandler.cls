public without sharing class APTS_AttachmentTriggerHandler implements ITriggerHandler {

    public static final String AGREEMENT_API = 'Apttus__APTS_Agreement__c';
    public static final String OPSIGNATURES = 'Other Party Signatures';
    public static final String ACTIVATED = 'Activated';

    /**
    * @author        Wendy Kelley
    * @date          22/02/2018
    * @description   Method for handling before insert event on trigger
    * @params        List<SObject>
    * @return        void
    * @revision(s)
    */
    public void beforeInsert(List<SObject> newItems) {
        /**try {            
            Set<Id> agmtIds = new Set<Id>();
            Map<Id, Attachment> agmtAttMap = new Map<Id, Attachment>();
            for(Attachment att : (List<Attachment>) newItems) {
                Id pId = att.ParentId;
                String sobjectType = pId.getSObjectType().getDescribe().getName();
                String attExt = (att.Name).substring((att.Name).length() - 4);
                System.debug('### Wendy=signed=' + !(att.Name).containsIgnoreCase('signed'));
                System.debug('### Wendy=sObjectType=' +sObjectType);
                System.debug('### Wendy=attExt=' +attExt);
                if('.pdf'.equalsIgnoreCase(attExt) && sObjectType == 'Apttus__APTS_Agreement__c' && !(att.Name).containsIgnoreCase('signed')) {
                    agmtAttMap.put(pId, att);
                }
             }
            
        } catch (Exception ex) {}**/    
    }

    /**
    * @author        Wendy Kelley
    * @date          19/01/2018
    * @description   Method for handling after insert event on trigger
    * @params        List<SObject>, Map<Id, SObject>
    * @return        void
    * @revision(s)
    */
    public void afterInsert(List<SObject> newList, Map<Id, SObject> newItems) {
        List<Id> lstParentId = new List<Id>();
        Map<Id, Id> mapAggrAttch = new Map<Id, Id>();
        List<Apttus__APTS_Agreement__c> agreementUpdateList = new List<Apttus__APTS_Agreement__c>();
        Boolean isSigned = true;
        Map<ID, Attachment> agreementToAttachmentMap = new Map<ID, Attachment>();
        
        //Get the list of Parent ids of type agreement
        try{
            for(Attachment tmp : (List<Attachment>) newList){
                System.debug('qwe++' + (tmp.Name).containsIgnoreCase('signed'));
                System.debug('qwe++1' + ((String) tmp.ParentId).substring(0,2).equalsIgnoreCase('a01'));
                //System.debug('qwe++2' + sObjName.equalsIgnoreCase(AGREEMENT_API));
                String sObjName = (tmp.ParentId).getSObjectType().getDescribe().getName();
                if(((tmp.Name).containsIgnoreCase('signed') || (tmp.Name).endsWithIgnoreCase('msg')) && sObjName.equalsIgnoreCase(AGREEMENT_API)){
                    agreementToAttachmentMap.put(tmp.ParentId, tmp);
                }
            }
            System.debug('Inside Attachment Trigger+++ ' + lstParentId);
            //create map of agreement id and attachment id
            if(agreementToAttachmentMap.size() > 0)
            {
                for(Apttus__APTS_Agreement__c tmpAggr : [SELECT Id, Apttus__Status__c, RecordType.DeveloperName FROM Apttus__APTS_Agreement__c WHERE Id IN :agreementToAttachmentMap.keySet()]){
                    System.debug('Agreementrecord type+++ ' +tmpAggr.RecordType.DeveloperName);
                    if(tmpAggr.RecordType.DeveloperName != 'Registration_Form' && agreementToAttachmentMap.get(tmpAggr.Id).Name.containsIgnoreCase('signed'))
                    {
                        if(OPSIGNATURES.equalsIgnoreCase(tmpAggr.Apttus__Status__c)){
                            tmpAggr.Apttus__Status__c = 'Fully Signed';
                            agreementUpdateList.add(tmpAggr);
                            isSigned = false;
                        }
                        if(tmpAggr.Apttus__Status__c.equalsIgnoreCase('Fully Signed') && isSigned){
                            mapAggrAttch.put(tmpAggr.Id, agreementToAttachmentMap.get(tmpAggr.Id).ID);
                        }
                    }
                    else if(tmpAggr.RecordType.DeveloperName == 'Registration_Form' && agreementToAttachmentMap.get(tmpAggr.Id).Name.endsWithIgnoreCase('msg'))
                    {
                        tmpAggr.Apttus__Status__c = 'Added';
                        agreementUpdateList.add(tmpAggr);
                    }
                }
            
                if(!agreementUpdateList.IsEmpty()){
                    update agreementUpdateList;
                }

                //calling agreement activate API
                for(Id aggrId : mapAggrAttch.keySet()){
                    List<Id> listActivatedDocIds = new List<Id>();
                    listActivatedDocIds.add(mapAggrAttch.get(aggrId));
                    List<Id> listRemovableDocIds = new List<Id>();
                    Apttus.AgreementWebService.activateAgreement(aggrId, listActivatedDocIds, listRemovableDocIds);
                    Apttus.AgreementWebService.publishToDocumentRepository(aggrId, mapAggrAttch.get(aggrId));
                }
            }
        }
        catch(Exception ex)
        {
            APTS_CustomLogging.createErrorLog(ex.getTypeName(), 'Apex', ex.getStackTraceString() ,'Agreement Attachment', newList[0].Id, 'CLM', false, false, null, true);
        }
    }

    /**
    * @author        Wendy Kelley
    * @date          19/01/2018
    * @description   Method for handling before update event on trigger
    * @params        List<SObject>, Map<Id, SObject>, List<SObject>, Map<Id, SObject>
    * @return        void
    * @revision(s)
    */
    public void beforeUpdate(List<SObject> newList, Map<Id, SObject> newItems, List<SObject> oldList, Map<Id, SObject> oldItems) {}

    /**
    * @author        Wendy Kelley
    * @date          19/01/2018
    * @description   Method for handling after update event on trigger
    * @params        List<SObject>, Map<Id, SObject>, List<SObject>, Map<Id, SObject>
    * @return        void
    * @revision(s)
    */
    public void afterUpdate(List<SObject> newList, Map<Id, SObject> newItems, List<SObject> oldList, Map<Id, SObject> oldItems) {}

    /**
    * @author        Wendy Kelley
    * @date          19/01/2018
    * @description   Method for handling before delete event on trigger
    * @params        List<SObject>, Map<Id, SObject>
    * @return        void
    * @revision(s)
    */
    public void beforeDelete(List<SObject> oldList, Map<Id, SObject> oldItems) {}

    /**
    * @author        Wendy Kelley
    * @date          19/01/2018
    * @description   Method for handling after delete event on trigger
    * @params        List<SObject>, Map<Id, SObject>
    * @return        void
    * @revision(s)
    */
    public void afterDelete(List<SObject> oldList, Map<Id, SObject> oldItems) {}

    /**
    * @author        Wendy Kelley
    * @date          19/01/2018
    * @description   Method for handling after undelete event on trigger
    * @params        List<SObject>, Map<Id, SObject>
    * @return        void
    * @revision(s)
    */
    public void afterUndelete(List<SObject> newList, Map<Id, SObject> newItems) {}

    /**
    * @author        Wendy Kelley
    * @date          19/01/2018
    * @description   Method to check if trigger is disabled
    * @params        None
    * @return        Boolean
    * @revision(s)
    */
    public Boolean isDisabled() {
        return TriggerSettings__c.getInstance().APTS_AssetTxnHistoryTrigger__c ? false : true;
    }
    
    public void renameAgreementAttachments(Map<Id, Attachment> agmtAttMap) {
        try{
            if(agmtAttMap != null && !agmtAttMap.isEmpty()) {
                for(Apttus__APTS_Agreement__c agmt : [SELECT Id, APTS_Document_Version__c FROM Apttus__APTS_Agreement__c WHERE Id IN :agmtAttMap.keySet()]) {
                    Attachment att = agmtAttMap.get(agmt.Id);
                    att.Name = att.Name.split('.pdf')[0] + '_v' + (agmt.APTS_Document_Version__c++) + '.pdf';
                }
            }
        }catch(Exception ex){APTS_CustomLogging.createErrorLog(ex.getTypeName(), 'Apex', ex.getStackTraceString(), 'Agreement Attachment', agmtAttMap.values()[0].Id, 'CLM', false, false, null, true);}
    }
}