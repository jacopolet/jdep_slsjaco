/*******************************************************************************************
Name            : APTS_RelatedAgreementTriggerHandler
Created By      : Shanmuga Prasath
Created Date    : 05-03-2018
Description     : Deep Cloning the product Configuration from Parent to Child Agreement
Version history : 1.0
Test Class      : APTS_RelatedAgreementTriggerHandlerTest
*********************************************************************************************/
public with sharing class APTS_RelatedAgreementTriggerHandler implements ITriggerHandler{

    private static String OBJECT_NAME = 'Related Agreement';
    private static String STREAM = 'CLM';
    private static String CODE_TYPE = 'Apex';
    private static String IS_RENEWED_BY = 'Is Renewed By';
    private static String IS_RENEWAL_FOR = 'Is Renewal For';
    private static String IS_AMENDED_BY = 'Is Amended By';
    private static String IS_AMENDED_FOR = 'Is Amendment For';
    public Map<Id,Id> oldAgrToNewMap = new Map<Id,Id>();
    
    /* Check custom setting for agreement trigger activation. */
    public Boolean isDisabled(){
        try{
            return TriggerSettings__c.getInstance().Agreement__c == true ? false : true;
        }catch(exception ex){APTS_CustomLogging.createErrorLog(ex.getTypeName(), CODE_TYPE, ex.getStackTraceString(), OBJECT_NAME, null, STREAM, false, false, null, true); return true;}
    }
    
    /* After agreement is updated. */
    public void afterUpdate(List<SObject> newList, Map<Id, SObject> mapAgreements, List<SObject> oldList, Map<Id, SObject> mapOldAgreements){}

    /* Before inserting agreement. */
    public void beforeInsert(List<SObject> newItems){}

    /* Before record updation. */
    public void beforeUpdate(List<SObject> newList, Map<Id, SObject> newItems, List<SObject> oldList, Map<Id, SObject> oldItems){}

    /* Before deleting agreement records. */
    public void beforeDelete(List<SObject> oldList, Map<Id, SObject> oldItems){}

    /* After insert agreement records. */
    public void afterInsert(List<SObject> newList, Map<Id, SObject> newItems){
        
         Boolean callQueueable = false;
         Boolean isSuccess= false;
         set<Id> agreementFromSet = new set<Id>();
         set<Id> relAgreeId = new set<Id>();
         Set<Id> relAgreeOldId  = new Set<Id>();
         List<APTS_Related_Agreement_Transaction__c> ragtList = new List<APTS_Related_Agreement_Transaction__c>();
         

    try{ 
        for(Apttus__APTS_Related_Agreement__c relAggr : (List<Apttus__APTS_Related_Agreement__c>)newList){
            agreementFromSet.add(relAggr.Apttus__APTS_Contract_From__c);
            relAgreeId.add(relAggr.Id);
            isSuccess = Apttus_CMConfig.CMConfigWebService.copyProductConfiguration(relAggr.Apttus__APTS_Contract_From__c,relAggr.Apttus__APTS_Contract_To__c);
            APTS_Related_Agreement_Transaction__c ragtNew = new APTS_Related_Agreement_Transaction__c();
            ragtNew.Related_Agreement__c = relAggr.Id;
            ragtNew.Status__c = 'TBProcessed';

            ragtList.add(ragtNew);

        }

        for(Apttus__APTS_Related_Agreement__c relAgree : [SELECT Id FROM Apttus__APTS_Related_Agreement__c WHERE Apttus__APTS_Contract_From__c IN: agreementFromSet ]) {
            relAgreeOldId.add(relAgree.Id);
        }

        if(!relAgreeOldId.isEmpty()){
            APTS_RelatedAgreementQueueable.updateRelatedAgreeTransaction(relAgreeOldId, false, false, true);
        }

        if(!ragtList.isEmpty()){
            insert ragtList;
        }
      
       if(!newList.isEmpty() && newList.size() == 1) {
            for(Apttus_Config2__ProductConfiguration__c prodConfig : [SELECT id, Apttus_Config2__NumberOfItems__c 
                                                                      FROM Apttus_Config2__ProductConfiguration__c 
                                                                      WHERE Apttus_CMConfig__AgreementId__c IN: agreementFromSet AND
                                                                            Apttus_Config2__Status__c = 'Finalized' 
                                                                            ORDER BY Createddate DESC LIMIT 1]){
                
                if(prodConfig.Apttus_Config2__NumberOfItems__c <= 1){
                    APTS_RelatedAgreementQueueable.initialCall(newList, true, false, true);
                }
                else if(prodConfig.Apttus_Config2__NumberOfItems__c > 1) { callQueueable = true; }
                            
            }
        }

        if(callQueueable && APTS_RelatedAgreementQueueable.hasQueueableJobRunning()) {
            if(!Test.isRunningTest()) {
                //DFT2C-1249 | Below line helps to run only for user specific agreements (Expected value of 1 agreement at a time)  
                System.enqueuejob( new APTS_RelatedAgreementQueueable(agreementFromSet)); }              
        }

     }catch(Exception ex){
        APTS_CustomLogging.createErrorLog(ex.getTypeName(), CODE_TYPE, ex.getMessage() + '\n\n' + ex.getStackTraceString(), OBJECT_NAME, null, STREAM, false, false, null, true);
        APTS_RelatedAgreementQueueable.updateRelatedAgreeTransaction(relAgreeId, false, true, false);
     } 
    
    }
    
    /* After deleting agreement records. */
    public void afterDelete(List<SObject> oldList, Map<Id, SObject> oldItems){}

     /* After undeleting agreement records. */
    public void afterUndelete(List<SObject> newList, Map<Id, SObject> newItems){}

}