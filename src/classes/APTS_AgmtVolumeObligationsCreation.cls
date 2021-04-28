/*************************************************************
@Name: APTS_AgmtVolumeObligationsCreation
@Author: Tamil Arasan
@CreateDate: 09-01-2018
@Description: APTS_AgmtVolumeObligationsCreation
******************************************************************/

public with sharing class APTS_AgmtVolumeObligationsCreation {
    /* Method to APTS_AgreementVolumeObligation__c records upon Agreement Activation
    * createAgmtVolumeObligation() will be invoked from APTS_AgreementTriggerHandler trigger event
    */
     private static final String AGREEMENTSOBJ = 'Apttus__APTS_Agreement__c';
     private static final String VOLI = 'APTS_Agreement_Volume_Obligation_Line__c';
     public void createAgmtVolumeObligation(Map<Id, SObject> mapAgreements, Map<Id, SObject> mapOldAgreements) {
        
        List<APTS_AgreementVolumeObligation__c> agreementVolumeObligationsToInsert = new List<APTS_AgreementVolumeObligation__c>();
        Database.SaveResult[] insertedList;
        Database.SaveResult[] updatedList;
        Set<ID> agreementIdSet = new Set<ID>();
        List<Apttus__APTS_Related_Agreement__c> relatedAgreeList = new List<Apttus__APTS_Related_Agreement__c>();
        Set<Id> fromAgreeIdSet = new Set<Id>();
        Map<String, Map<String, List<APTS_Agreement_Volume_Obligation_Line__c>>> voliMap = new Map<String, Map<String, List<APTS_Agreement_Volume_Obligation_Line__c>>>();
        List<APTS_Agreement_Volume_Obligation_Line__c> existingLineItems = new List<APTS_Agreement_Volume_Obligation_Line__c>();
        List<APTS_AgreementVolumeObligation__c> createdSchedules = new List<APTS_AgreementVolumeObligation__c>();
        Map<Id,Id> toFromAgreeMap = new Map<Id,Id>();
        try{
            List<APTS_AgreementTotalVolumeObligation__c> allAgreementTotalVolumeObligationsList = [SELECT Id,
                                                     APTS_Agreement__c,APTS_Agreement__r.Id,
                                                     APTS_Name__c,
                                                     APTS_Type__c,
                                                     APTS_Value__c,
                                                     APTS_Value_Name__c,
                                                     APTS_Unit_of_Measure__c,
                                                     APTS_Malus_per_Unit__c,
                                                     APTS_Volume_Obligation__c,
                                                     APTS_Close__c
                                                     FROM APTS_AgreementTotalVolumeObligation__c
                                                     WHERE APTS_Agreement__c IN :mapAgreements.keySet()];
                                                     
            Map<Id, List<APTS_AgreementTotalVolumeObligation__c>> agrTotalVolumeObligationsToAgrMap = new Map<Id, List<APTS_AgreementTotalVolumeObligation__c>>();
            for (APTS_AgreementTotalVolumeObligation__c agreementTotalVolumeObligation : allAgreementTotalVolumeObligationsList) {
                agreementIdSet.add(agreementTotalVolumeObligation.APTS_Agreement__r.Id);
                if(agrTotalVolumeObligationsToAgrMap.containsKey(agreementTotalVolumeObligation.APTS_Agreement__c)){
                    List<APTS_AgreementTotalVolumeObligation__c> agreementTotalVolumeObligationsList = new list<APTS_AgreementTotalVolumeObligation__c>();
                    agreementTotalVolumeObligationsList =  agrTotalVolumeObligationsToAgrMap.get(agreementTotalVolumeObligation.APTS_Agreement__c);
                    agreementTotalVolumeObligationsList.add(agreementTotalVolumeObligation);
                    agrTotalVolumeObligationsToAgrMap.put(agreementTotalVolumeObligation.APTS_Agreement__c, agreementTotalVolumeObligationsList);
                }else{
                    List<APTS_AgreementTotalVolumeObligation__c> agreementTotalVolumeObligationsList = new list<APTS_AgreementTotalVolumeObligation__c>();
                    agreementTotalVolumeObligationsList.add(agreementTotalVolumeObligation);
                    agrTotalVolumeObligationsToAgrMap.put(agreementTotalVolumeObligation.APTS_Agreement__c, agreementTotalVolumeObligationsList);
                    
                }
                
            }
            //END
            if(!agreementIdSet.isEmpty()){
                relatedAgreeList = [Select Id,Apttus__APTS_Contract_To__c,Apttus__APTS_Contract_From__c From Apttus__APTS_Related_Agreement__c Where Apttus__APTS_Contract_To__c IN :agreementIdSet];
                if(!relatedAgreeList.isEmpty()){
                    for(Apttus__APTS_Related_Agreement__c rel:relatedAgreeList){
                        fromAgreeIdSet.add(rel.Apttus__APTS_Contract_From__c);
                        toFromAgreeMap.put(rel.Apttus__APTS_Contract_To__c,rel.Apttus__APTS_Contract_From__c);
                    }
                }
            }
            if(!fromAgreeIdSet.isEmpty()){
                existingLineItems = [Select Id,APTS_Agreement__r.Id, APTS_Agreement__c,APTS_Agreement_Volume_Obligation__c,
                                    APTS_External_Order_Line_Item__c,APTS_Ordered_Quantity__c,APTS_Fulfillment_Date__c,
                                    APTS_Inactive__c,APTS_Order_In_Progress_Quantity__c,APTS_Order_Line_Item__c,
                                    APTS_Agreement_Volume_Obligation__r.APTS_Agreement_Total_Volume_Obligation__r.APTS_Type__c ,
                                    APTS_Agreement_Volume_Obligation__r.APTS_Agreement_Total_Volume_Obligation__r.APTS_Value__c, 
                                    APTS_Agreement_Volume_Obligation__r.APTS_Agreement_Total_Volume_Obligation__r.APTS_SubCategoryName__c,
                                    APTS_Agreement_Volume_Obligation__r.APTS_Agreement_Total_Volume_Obligation__r.APTS_Volume_Obligation__c 
                                    From APTS_Agreement_Volume_Obligation_Line__c where APTS_Agreement__c IN :fromAgreeIdSet];
                if(!existingLineItems.isEmpty() && existingLineItems.size()>0){
                    for(APTS_Agreement_Volume_Obligation_Line__c voli: existingLineItems){
                        if(voliMap.containsKey(voli.APTS_Agreement__r.Id+voli.APTS_Agreement_Volume_Obligation__r.APTS_Agreement_Total_Volume_Obligation__r.APTS_Type__c)){
                            if(voliMap.get(voli.APTS_Agreement__r.Id+voli.APTS_Agreement_Volume_Obligation__r.APTS_Agreement_Total_Volume_Obligation__r.APTS_Type__c).containsKey(voli.APTS_Agreement_Volume_Obligation__r.APTS_Agreement_Total_Volume_Obligation__r.APTS_Value__c+voli.APTS_Agreement_Volume_Obligation__r.APTS_Agreement_Total_Volume_Obligation__r.APTS_Volume_Obligation__c)){
                                voliMap.get(voli.APTS_Agreement__r.Id+voli.APTS_Agreement_Volume_Obligation__r.APTS_Agreement_Total_Volume_Obligation__r.APTS_Type__c).get(voli.APTS_Agreement_Volume_Obligation__r.APTS_Agreement_Total_Volume_Obligation__r.APTS_Value__c+voli.APTS_Agreement_Volume_Obligation__r.APTS_Agreement_Total_Volume_Obligation__r.APTS_Volume_Obligation__c).add(voli);
                            }else{
                                voliMap.get(voli.APTS_Agreement__r.Id+voli.APTS_Agreement_Volume_Obligation__r.APTS_Agreement_Total_Volume_Obligation__r.APTS_Type__c).put(voli.APTS_Agreement_Volume_Obligation__r.APTS_Agreement_Total_Volume_Obligation__r.APTS_Value__c+voli.APTS_Agreement_Volume_Obligation__r.APTS_Agreement_Total_Volume_Obligation__r.APTS_Volume_Obligation__c, new List<APTS_Agreement_Volume_Obligation_Line__c>{voli});
                            }
                        }else{
                            voliMap.put(voli.APTS_Agreement__r.Id+voli.APTS_Agreement_Volume_Obligation__r.APTS_Agreement_Total_Volume_Obligation__r.APTS_Type__c,new Map<String,List<APTS_Agreement_Volume_Obligation_Line__c>>{voli.APTS_Agreement_Volume_Obligation__r.APTS_Agreement_Total_Volume_Obligation__r.APTS_Value__c+voli.APTS_Agreement_Volume_Obligation__r.APTS_Agreement_Total_Volume_Obligation__r.APTS_Volume_Obligation__c => new List<APTS_Agreement_Volume_Obligation_Line__c>{voli}}); 
                        }
                    }
                }
            }

            for (Apttus__APTS_Agreement__c oAgreement : (List<Apttus__APTS_Agreement__c>)mapAgreements.values()) {

                Apttus__APTS_Agreement__c oOldAgreement = (Apttus__APTS_Agreement__c)mapOldAgreements.get(oAgreement.id);

                if (oOldAgreement != null &&
                        (oOldAgreement.Apttus__Status__c != oAgreement.Apttus__Status__c || oOldAgreement.Apttus__Status_Category__c != oAgreement.Apttus__Status_Category__c) &&
                        (oAgreement.Apttus__Status__c == 'Activated' && oAgreement.Apttus__Status_Category__c == 'In Effect')) {
                    system.debug('obligation ==> ');
                    List<APTS_AgreementTotalVolumeObligation__c> agreementTotalVolumeObligationsList = agrTotalVolumeObligationsToAgrMap.get(oAgreement.Id);
                    if (agreementTotalVolumeObligationsList != null) {
                        for (APTS_AgreementTotalVolumeObligation__c agreementTotalVolumeObligation : agreementTotalVolumeObligationsList) {
                            Date contractStartDate = oAgreement.Apttus__Contract_Start_Date__c;
                            Date contractEndDate = oAgreement.Apttus__Contract_End_Date__c;
                            Integer currentYear = contractStartDate.year();
                            while (currentYear <= contractEndDate.year()) {
                                Date firstDayOfYear = Date.newInstance(currentYear, 1, 1);
                                Date lastDayOfYear = Date.newInstance(currentYear, 12, 31);

                                Date periodStartDate = contractStartDate > firstDayOfYear ? contractStartDate : firstDayOfYear;
                                Date periodEndDate = contractEndDate < lastDayOfYear ? contractEndDate : lastDayOfYear;
                                Decimal prorationCoefficient = periodStartDate.daysBetween(periodEndDate + 1) / (Date.isLeapYear(currentYear) ? 366.0 : 365.0);
                                APTS_AgreementVolumeObligation__c agreementVolumeObligation = new APTS_AgreementVolumeObligation__c();
                                agreementVolumeObligation.APTS_Agreement__c = oAgreement.Id;
                                agreementVolumeObligation.APTS_Start_Date__c = periodStartDate;
                                agreementVolumeObligation.APTS_End_Date__c = periodEndDate;
                                agreementVolumeObligation.APTS_Type__c = agreementTotalVolumeObligation.APTS_Type__c;
                                agreementVolumeObligation.APTS_Unit_of_Measure__c = agreementTotalVolumeObligation.APTS_Unit_of_Measure__c;
                                agreementVolumeObligation.APTS_Value__c = agreementTotalVolumeObligation.APTS_Value__c;
                                agreementVolumeObligation.APTS_Agreement_Total_Volume_Obligation__c = agreementTotalVolumeObligation.Id;
                                agreementVolumeObligation.APTS_Value_Name__c = agreementTotalVolumeObligation.APTS_Value_Name__c;
                                if(agreementTotalVolumeObligation.APTS_Volume_Obligation__c != null){
                                    agreementVolumeObligation.APTS_Volume_Obligation__c = agreementTotalVolumeObligation.APTS_Volume_Obligation__c *  prorationCoefficient;
                                }

                                agreementVolumeObligation.APTS_Malus_per_Unit__c = agreementTotalVolumeObligation.APTS_Malus_per_Unit__c;
                                agreementVolumeObligation.APTS_Agreement_Total_Volume_Obligation__c = agreementTotalVolumeObligation.Id;
                                if(agreementTotalVolumeObligation.APTS_Close__c){
                                    agreementVolumeObligation.APTS_Status__c='Closed';
                                }else{
                                    agreementVolumeObligation.APTS_Status__c='Open';
                                }
                                agreementVolumeObligationsToInsert.add(agreementVolumeObligation);
                                currentYear++;
                            }
                        }
                    }
                    //END                
                }
            }
            Set<ID> vOIdSet = new Set<Id>();
            List<APTS_Agreement_Volume_Obligation_Line__c> existingVoli = new List<APTS_Agreement_Volume_Obligation_Line__c>();
            List<APTS_Agreement_Volume_Obligation_Line__c> insertVoliLine = new List<APTS_Agreement_Volume_Obligation_Line__c>();
            APTS_Agreement_Volume_Obligation_Line__c agreementVolumeObligationLineItem ;
            if(!agreementVolumeObligationsToInsert.isEmpty()){
                //Added by Saranya Rajagopal 
                DescribeSObjectResult objResultLSP = APTS_OTCUtil.getsObjectAccess(AGREEMENTSOBJ);
                if(objResultLSP!=null && objResultLSP.isCreateable())
                {
                    insertedList = Database.insert(agreementVolumeObligationsToInsert,false);
                    for(Integer i=0;i<insertedList.size();i++){
                        if (insertedList.get(i).isSuccess()){
                            vOIdSet.add(insertedList.get(i).getId());
                        }
                    }
                    APTS_BIRUtils.logError(null,insertedList,null,null,APTS_BIRUtils.TRIGGERVALUE,APTS_BIRUtils.AGREEMENTVOLOBLIGATIONOBJECT,APTS_BIRUtils.EMPTY_STRING,false,false,APTS_BIRUtils.EMPTY_STRING,false);
                }
            }
            if(!vOIdSet.isEmpty()){
                createdSchedules = [Select Id,APTS_Agreement__r.Id,APTS_Start_Date__c,APTS_End_Date__c,APTS_Agreement__c,
                                    APTS_Type__c,APTS_Value__c,APTS_Agreement_Total_Volume_Obligation__r.APTS_Volume_Obligation__c 
                                    From APTS_AgreementVolumeObligation__c Where Id In :vOIdSet];
            }
            if(!createdSchedules.isEmpty()){
                for(APTS_AgreementVolumeObligation__c sched: createdSchedules){
                    ID fromAgreeId = toFromAgreeMap.get(sched.APTS_Agreement__r.Id);
                    string key = fromAgreeId+sched.APTS_Type__c;
                    system.debug('$$$voliMap'+voliMap);
                    if(voliMap.containsKey(key) 
                        && voliMap.get(key).containsKey(sched.APTS_Value__c+sched.APTS_Agreement_Total_Volume_Obligation__r.APTS_Volume_Obligation__c)){
                        existingVoli = voliMap.get(key).get(sched.APTS_Value__c+sched.APTS_Agreement_Total_Volume_Obligation__r.APTS_Volume_Obligation__c);
                        for(APTS_Agreement_Volume_Obligation_Line__c voli: existingVoli){
                            if(sched.APTS_Start_Date__c <= voli.APTS_Fulfillment_Date__c && 
                                    sched.APTS_End_Date__c >= voli.APTS_Fulfillment_Date__c){
                                agreementVolumeObligationLineItem = new APTS_Agreement_Volume_Obligation_Line__c();
                                agreementVolumeObligationLineItem.APTS_Agreement__c = sched.APTS_Agreement__c;
                                agreementVolumeObligationLineItem.APTS_Agreement_Volume_Obligation__c = sched.Id;
                                agreementVolumeObligationLineItem.APTS_External_Order_Line_Item__c = voli.APTS_External_Order_Line_Item__c;
                                agreementVolumeObligationLineItem.APTS_Ordered_Quantity__c = voli.APTS_Ordered_Quantity__c;
                                agreementVolumeObligationLineItem.APTS_Fulfillment_Date__c = voli.APTS_Fulfillment_Date__c;
                                agreementVolumeObligationLineItem.APTS_Inactive__c = voli.APTS_Inactive__c;
                                agreementVolumeObligationLineItem.APTS_Order_In_Progress_Quantity__c = voli.APTS_Order_In_Progress_Quantity__c;
                                agreementVolumeObligationLineItem.APTS_Order_Line_Item__c = voli.APTS_Order_Line_Item__c;
                                insertVoliLine.add(agreementVolumeObligationLineItem);
                            }
                        }
                    }
                }
            }
            if(!insertVoliLine.isEmpty()){
                //Added by Saranya Rajagopal 
                DescribeSObjectResult objResultLSP = APTS_OTCUtil.getsObjectAccess(VOLI);
                if(objResultLSP!=null && objResultLSP.isCreateable())
                {
                    insertedList = Database.insert(insertVoliLine,false);
                    APTS_BIRUtils.logError(null,insertedList,null,null,APTS_BIRUtils.TRIGGERVALUE,VOLI,APTS_BIRUtils.EMPTY_STRING,false,false,APTS_BIRUtils.EMPTY_STRING,false);
                }
            }
            
        }catch(Exception e){
            APTS_BIRUtils.logError(null,null,null,e,APTS_BIRUtils.TRIGGERVALUE,APTS_BIRUtils.AGREEMENTVOLOBLIGATIONOBJECT,APTS_BIRUtils.EMPTY_STRING,false,false,APTS_BIRUtils.EMPTY_STRING,true);

        }
    }
}