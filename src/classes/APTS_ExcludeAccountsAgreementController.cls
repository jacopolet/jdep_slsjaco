/*************************************************************
@Name: APTS_ExcludeAccountsAgreementController 
@Author: Pranjal Mittal
@CreateDate: 27-02-2018
@Description: Create Account exclusion for Agreement, Agreement Line Item and Adjustment Agreement Line Item
@UsedBy: APTS_ExcludeAccountsForAgreement (Ligtning Component)
******************************************************************/

public with sharing class APTS_ExcludeAccountsAgreementController{

    public class ChildAccountWrapper{
        @AuraEnabled public Boolean isSelected {get;set;}
        @AuraEnabled public Account selectedAccount {get;set;}
    }

    public static final String AGREEMENT_API = 'Apttus__APTS_Agreement__c'; //API for Agreement
    public static final String ALI_API = 'Apttus__AgreementLineItem__c'; //API for Agreement Line Item
    public static final String AALI_API = 'Apttus_CMConfig__AgreementAdjustmentLineItem__c'; //API for Agreement Adjustment Line Item
    
    @AuraEnabled
    public static List<ChildAccountWrapper> getExclusionData(String recordId){
        //lstChildAccountWrapper = new List<ChildAccountWrapper>();
        Id recId = recordId;
        Id soldToPartyId;
        Id aliRecordId;
        String sObjName = recId.getSObjectType().getDescribe().getName();
        Apttus__APTS_Agreement__c aggrRecord = new Apttus__APTS_Agreement__c();
        Apttus__AgreementLineItem__c aliRecord = new Apttus__AgreementLineItem__c();
        Map<Id, Id> mapAccountIdExcId = new Map<Id, Id>();
            
        if(sObjName.equalsIgnoreCase(AGREEMENT_API)){
            aggrRecord = [SELECT Apttus__Account__c FROM Apttus__APTS_Agreement__c WHERE Id = :recordId][0];
            soldToPartyId = aggrRecord.Apttus__Account__c;
            for(APTS_Agreement_Account_Exclusion__c tmp : [SELECT Id, APTS_Account__c FROM APTS_Agreement_Account_Exclusion__c WHERE APTS_Agreement__c = :recordId]){
                mapAccountIdExcId.put(tmp.APTS_Account__c, tmp.Id);
            }
        }
        else if(sObjName.equalsIgnoreCase(ALI_API)){
            aliRecord = [SELECT Apttus__AgreementId__r.Apttus__Account__c FROM Apttus__AgreementLineItem__c WHERE Id = :recordId][0];
            soldToPartyId = aliRecord.Apttus__AgreementId__r.Apttus__Account__c;
            for(APTS_Agreement_Line_Account_Exclusion__c tmp : [SELECT Id, APTS_Account__c FROM APTS_Agreement_Line_Account_Exclusion__c WHERE APTS_Agreement_Line_Item__c = :recordId]){
                mapAccountIdExcId.put(tmp.APTS_Account__c, tmp.Id);
            }
        }
        else if(sObjName.equalsIgnoreCase(AALI_API)){
            aliRecordId = [SELECT Apttus_CMConfig__LineItemId__r.Apttus__AgreementId__c FROM Apttus_CMConfig__AgreementAdjustmentLineItem__c WHERE Id = :recordId][0].Apttus_CMConfig__LineItemId__c;
            soldToPartyId = [SELECT Apttus__AgreementId__r.Apttus__Account__c FROM Apttus__AgreementLineItem__c WHERE Id = :aliRecordId][0].Apttus__AgreementId__r.Apttus__Account__c;
            for(APTS_Adjustment_Line_Account_Exclusion__c tmp : [SELECT Id, APTS_Account__c FROM APTS_Adjustment_Line_Account_Exclusion__c WHERE APTS_Agreement_Adjustment_Line_Item__c = :recordId]){
                mapAccountIdExcId.put(tmp.APTS_Account__c, tmp.Id);
            }
        }

        //String soldToPartyName;
        Account soldtoParty;
        if(soldToPartyId != null){
            soldtoParty = [SELECT Id, Name from Account WHERE Id = :soldToPartyId];
        }
        
        List<ChildAccountWrapper> lstChildAccountWrapper = new List<ChildAccountWrapper>();

        if(soldToPartyId != null && soldtoParty != null){
            for(Account tmpAccount : [SELECT Id, 
                                      Name,
                                      Ultimate_Parent_Account__c,
                                      Purchase_Organization__c,
                                      SAP_Customer_ID__c,
                                      Main_Street_Only__c,
                                      Main_House_Number__c,
                                      Main_City__c,
                                      Main_Country__c,
                                      Main_Postal_Code__c
                                      FROM Account
                                      WHERE Id IN :APTS_ManageCER.getHierarchyAccountIdList(soldToPartyId, soldtoParty.Name)]){
                ChildAccountWrapper tmpWrapper = new ChildAccountWrapper();
                if(mapAccountIdExcId.containsKey(tmpAccount.Id)){
                    tmpWrapper.isSelected = true;
                }
                else{
                    tmpWrapper.isSelected = false;
                }
                tmpWrapper.selectedAccount = tmpAccount;
                lstChildAccountWrapper.add(tmpWrapper);
            }
        }

        return lstChildAccountWrapper;
    }

    @AuraEnabled
    public static void excludeAgreement(String wrapperRecords, String recordId){
        List<Id> lstAccountIds = new List<Id>();
        //List<Id> agreementAdjustmentLineItemId = new List<Id>();
        List<APTS_Agreement_Account_Exclusion__c> lstAggrExc = new List<APTS_Agreement_Account_Exclusion__c>();
        List<APTS_Agreement_Line_Account_Exclusion__c> lstAggrLineItemExc = new List<APTS_Agreement_Line_Account_Exclusion__c>();
        List<APTS_Adjustment_Line_Account_Exclusion__c> lstAggrAdjExc = new List<APTS_Adjustment_Line_Account_Exclusion__c>();
        Id aggrId;
        Apttus__AgreementLineItem__c oALI = new Apttus__AgreementLineItem__c();  
        Apttus_CMConfig__AgreementAdjustmentLineItem__c oAALI = new Apttus_CMConfig__AgreementAdjustmentLineItem__c();
        List<Id> lstUnselectedAccountIds = new List<Id>();
        List<Id> lstOfAccountExcToDelete = new List<Id>();
        
        Id recId = recordId;
        
        String sObjName = recId.getSObjectType().getDescribe().getName();

        List<ChildAccountWrapper> lstChildWrapper = (List<ChildAccountWrapper>)System.JSON.deserialize(wrapperRecords,List<ChildAccountWrapper>.class);
        
        if(lstChildWrapper != null && lstChildWrapper.size()>0){
            for(ChildAccountWrapper tmpWrapper: lstChildWrapper){
                if(tmpWrapper.isSelected){
                    lstAccountIds.add(tmpWrapper.selectedAccount.Id);
                }
                else{
                    lstUnselectedAccountIds.add(tmpWrapper.selectedAccount.Id);   
                }
            }
        }

        //Calling APTS_ManageCER functionalities
        if((lstAccountIds != null && lstAccountIds.size() > 0) || (lstUnselectedAccountIds != NULL && lstUnselectedAccountIds.size()>0)){
            if(sObjName.equalsIgnoreCase(AGREEMENT_API)){
                //APTS_ManageCER.excludeAccountFromAgreement(recordId, lstAccountIds);
                aggrId = recordId;
                for(Id tmpId : lstAccountIds){
                    APTS_Agreement_Account_Exclusion__c tmpExc = new APTS_Agreement_Account_Exclusion__c();
                    tmpExc.APTS_Account__c = tmpId;
                    tmpExc.APTS_Agreement__c = recId;
                    lstAggrExc.add(tmpExc);
                }

                for(Id tmpId: lstUnselectedAccountIds){
                    lstOfAccountExcToDelete.add(tmpId);
                }
                
                if(lstOfAccountExcToDelete != NULL && lstOfAccountExcToDelete.size()>0){
                    delete([SELECT Id, APTS_Account__c FROM APTS_Agreement_Account_Exclusion__c WHERE APTS_Account__c IN :lstOfAccountExcToDelete AND APTS_Agreement__c =: recId]);
                }
            }
            else if(sObjName.equalsIgnoreCase(ALI_API)){
                oALI = [SELECT Id, Apttus__AgreementId__c FROM Apttus__AgreementLineItem__c WHERE Id = :recId LIMIT 1];
                //APTS_ManageCER.excludeAccountFromAgreementLineItem(oALI.Apttus__AgreementId__c, recordId, lstAccountIds);
                aggrId = oALI.Apttus__AgreementId__c;
                for(Id tmpId : lstAccountIds){
                    APTS_Agreement_Line_Account_Exclusion__c tmpExc = new APTS_Agreement_Line_Account_Exclusion__c();
                    tmpExc.APTS_Account__c = tmpId;
                    tmpExc.APTS_Agreement_Line_Item__c = recId;
                    tmpExc.APTS_Agreement__c = aggrId;
                    lstAggrLineItemExc.add(tmpExc);
                }

                for(Id tmpId: lstUnselectedAccountIds){
                    lstOfAccountExcToDelete.add(tmpId);
                }
                
                if(lstOfAccountExcToDelete != NULL && lstOfAccountExcToDelete.size()>0){
                    delete([SELECT Id, APTS_Account__c FROM APTS_Agreement_Line_Account_Exclusion__c WHERE APTS_Account__c IN :lstOfAccountExcToDelete AND APTS_Agreement_Line_Item__c =: recId]);
                }
            }
            else if(sObjName.equalsIgnoreCase(AALI_API)){
                oAALI = [SELECT Apttus_CMConfig__LineItemId__c FROM Apttus_CMConfig__AgreementAdjustmentLineItem__c WHERE Id = :recId];
                oALI = [SELECT Id, Apttus__AgreementId__c FROM Apttus__AgreementLineItem__c WHERE Id = :oAALI.Apttus_CMConfig__LineItemId__c];
                //agreementAdjustmentLineItemId.add(recId);
                //APTS_ManageCER.excludeAccountFromAdjustments(oALI.Apttus__AgreementId__c, oALI.Id, agreementAdjustmentLineItemId, lstAccountIds);
                aggrId = oALI.Apttus__AgreementId__c;
                for(Id tmpId : lstAccountIds){
                    APTS_Adjustment_Line_Account_Exclusion__c tmpExc = new APTS_Adjustment_Line_Account_Exclusion__c();
                    tmpExc.APTS_Account__c = tmpId;
                    tmpExc.APTS_Agreement_Adjustment_Line_Item__c = recId;
                    tmpExc.APTS_Agreement__c = aggrId;
                    tmpExc.APTS_Agreement_Line_Item__c = oALI.Id;
                    lstAggrAdjExc.add(tmpExc);
                }

                for(Id tmpId: lstUnselectedAccountIds){
                    lstOfAccountExcToDelete.add(tmpId);
                }
                
                if(lstOfAccountExcToDelete != NULL && lstOfAccountExcToDelete.size()>0){
                    delete([SELECT Id, APTS_Account__c FROM APTS_Adjustment_Line_Account_Exclusion__c WHERE APTS_Account__c IN :lstOfAccountExcToDelete AND APTS_Agreement_Adjustment_Line_Item__c =: recId]);
                }
            }
        }

        //Creation of Agreement - Account Exclusion records
        if(lstAggrExc != null && lstAggrExc.size() > 0){
            List<APTS_Agreement_Account_Exclusion__c> lstAccountPresent = [SELECT Id, APTS_Account__c, APTS_Agreement__c from APTS_Agreement_Account_Exclusion__c WHERE APTS_Agreement__c = :recId];
            List<APTS_Agreement_Account_Exclusion__c> lstExcToInsert = new List<APTS_Agreement_Account_Exclusion__c>();
            Set<Id> lstAccIds = new Set<Id>();

            for(APTS_Agreement_Account_Exclusion__c tmpAccountPresent : lstAccountPresent){
                lstAccIds.add(tmpAccountPresent.APTS_Account__c);
            }

            for(APTS_Agreement_Account_Exclusion__c tmpExc : lstAggrExc){
                if(!lstAccIds.contains(tmpExc.APTS_Account__c)){
                    lstExcToInsert.add(tmpExc);
                }
            }

            //Insert Agreement - Account Exclusion records
            if(lstExcToInsert != null && lstExcToInsert.size()>0){
                insert lstExcToInsert;
                updateFieldonAggr(aggrId, 'Account Exclusion');
            }
        }

        //Creation of Agreement Line  - Account Exclusion records
        if(lstAggrLineItemExc != null && lstAggrLineItemExc.size() > 0){
            List<APTS_Agreement_Line_Account_Exclusion__c> lstAccountPresent = [SELECT Id, APTS_Account__c, APTS_Agreement_Line_Item__c from APTS_Agreement_Line_Account_Exclusion__c WHERE APTS_Agreement_Line_Item__c = :recId];
            List<APTS_Agreement_Line_Account_Exclusion__c> lstExcToInsert = new List<APTS_Agreement_Line_Account_Exclusion__c>();
            Set<Id> lstAccIds = new Set<Id>();

            for(APTS_Agreement_Line_Account_Exclusion__c tmpAccountPresent : lstAccountPresent){
                lstAccIds.add(tmpAccountPresent.APTS_Account__c);
            }

            for(APTS_Agreement_Line_Account_Exclusion__c tmpExc : lstAggrLineItemExc){
                if(!lstAccIds.contains(tmpExc.APTS_Account__c)){
                    lstExcToInsert.add(tmpExc);
                }
            }

            //Insert Agreement Line Account Exclusion records
            if(lstExcToInsert != null && lstExcToInsert.size()>0){
                insert lstExcToInsert;
                updateFieldonAggr(aggrId, 'Categories/Products Exclusion');
                //updateFieldonAggr(aggrId, 'Adjustment Exclusion');
            }
        }

        //Creation of Adjustment Line - Account Exclusion records
        if(lstAggrAdjExc != null && lstAggrAdjExc.size() > 0){
            List<APTS_Adjustment_Line_Account_Exclusion__c> lstAccountPresent = [SELECT Id, APTS_Account__c from APTS_Adjustment_Line_Account_Exclusion__c WHERE APTS_Agreement_Adjustment_Line_Item__c = :recId];
            List<APTS_Adjustment_Line_Account_Exclusion__c> lstExcToInsert = new List<APTS_Adjustment_Line_Account_Exclusion__c>();
            Set<Id> lstAccIds = new Set<Id>();

            for(APTS_Adjustment_Line_Account_Exclusion__c tmpAccountPresent : lstAccountPresent){
                lstAccIds.add(tmpAccountPresent.APTS_Account__c);
            }

            for(APTS_Adjustment_Line_Account_Exclusion__c tmpExc : lstAggrAdjExc){
                if(!lstAccIds.contains(tmpExc.APTS_Account__c)){
                    lstExcToInsert.add(tmpExc);
                }
            }

            //Insert Agreement Line Account Exclusion records
            if(lstExcToInsert != null && lstExcToInsert.size()>0){
                insert lstExcToInsert;
                updateFieldonAggr(aggrId, 'Adjustment Exclusion');
            }
        }
    }

    //Method to help identifying type of exclusion in output document template
    public static void updateFieldonAggr(Id aggrId, String exclusionType){
        Apttus__APTS_Agreement__c oAggr = [SELECT Id, APTS_ExclusionRelatedDetails__c FROM Apttus__APTS_Agreement__c WHERE Id = :aggrId];
        Boolean flag = false;

        if(oAggr.APTS_ExclusionRelatedDetails__c == null){
            oAggr.APTS_ExclusionRelatedDetails__c = exclusionType;
            flag = true;
        }
        else if(!oAggr.APTS_ExclusionRelatedDetails__c.contains(exclusionType)){
            oAggr.APTS_ExclusionRelatedDetails__c = oAggr.APTS_ExclusionRelatedDetails__c + '|' + exclusionType;
            flag = true;
        }

        if(flag){
            update oAggr;
        }
    }
 }