/*******************************************************************************************
Name            : APTS_AgreementPODetailsTriggerHandlerTest
Created By      : Shanmuga Prasath
Created Date    : 12/06/2018
Description     : Test class written for 'APTS_AgreementPODetailsTriggerHandler'.
Version history : 
*********************************************************************************************/
@isTest(SeeAllData=false)
private class APTS_AgreementPODetailsTriggerTest{
    
    /* create test data */
    @TestSetup
    private static void createTestData(){
        
        TriggerSettings__c oTriggerSettings = new TriggerSettings__c(APTS_AgreementPODetails__c=true);
        Database.insert(oTriggerSettings);
        
        Account testAccount = APTS_TestUtils.createGrandParentAccount();
        testAccount.Name = 'Test Account';
        Database.Insert(testAccount);
        
        Apttus_Config2__PriceList__c priceList = APTS_TestUtils.createPriceList();
        Database.Insert(priceList);
        
        Id recordtype = Schema.SObjectType.Apttus__APTS_Agreement__c.getRecordTypeInfosByName().get(System.Label.APTS_Standard_Deal).getRecordTypeId();
        
        List<Apttus__APTS_Agreement__c> agreementList = new List<Apttus__APTS_Agreement__c>();
        Apttus__APTS_Agreement__c machineTestAgreement = new Apttus__APTS_Agreement__c(Apttus__Account__c = testAccount.Id, 
                        Name = 'Test Agreement',RecordTypeId = recordtype,
                        Apttus__Contract_Start_Date__c = Date.today(), Apttus__Contract_End_Date__c = Date.today()+365, 
                        Apttus_CMConfig__PriceListId__c = priceList.id,Apttus__Subtype__c ='Fixed-Term-Fixed Costs',
                        Apttus__Status_Category__c = 'In Effect', Apttus__Status__c = 'Activated');
        agreementList.add(machineTestAgreement);
        
        Apttus__APTS_Agreement__c optionTestAgreement = new Apttus__APTS_Agreement__c(Apttus__Account__c = testAccount.Id, 
                        Name = 'New Agreement',RecordTypeId = recordtype,
                        Apttus__Contract_Start_Date__c = Date.today(), Apttus__Contract_End_Date__c = Date.today()+365, 
                        Apttus_CMConfig__PriceListId__c = priceList.id,Apttus__Subtype__c ='Fixed-Term-Fixed Costs',
                        Apttus__Status_Category__c = 'Request', Apttus__Status__c = 'Activated');
        agreementList.add(optionTestAgreement);
        Database.Insert(agreementList);
        
        List<APTS_Agreement_PO_Details__c> poList = new List<APTS_Agreement_PO_Details__c>();
        APTS_Agreement_PO_Details__c machineAgreementPODetails = new APTS_Agreement_PO_Details__c();
        machineAgreementPODetails.APTS_PO_Number_Required__c = 'Yes';
        machineAgreementPODetails.APTS_PO_Number_Type__c = 'Variable';
        machineAgreementPODetails.APTS_PO_Number__c = '123567';
        machineAgreementPODetails.APTS_Agreement__c = machinetestAgreement.Id;
        poList.add(machineAgreementPODetails);
        
        APTS_Agreement_PO_Details__c optionAgreementPODetails = new APTS_Agreement_PO_Details__c();
        optionAgreementPODetails.APTS_PO_Number_Required__c = 'Yes';
        optionAgreementPODetails.APTS_PO_Number_Type__c = 'Variable';
        optionAgreementPODetails.APTS_PO_Number__c = '123567';
        optionAgreementPODetails.APTS_Agreement__c = optionTestAgreement.Id;
        poList.add(optionAgreementPODetails);
        Database.Insert(poList);
        
        Id machineRecId = Schema.SObjectType.PhysicalAsset__c.getRecordTypeInfosByName().get('Machine').getRecordTypeId();
        Id optionRecId = Schema.SObjectType.PhysicalAsset__c.getRecordTypeInfosByName().get('Option').getRecordTypeId();
        
        List<PhysicalAsset__c> physicalAssetList = new List<PhysicalAsset__c>();
        PhysicalAsset__c machinePhysicalAsset = new PhysicalAsset__c();
        machinePhysicalAsset.Name = 'Test Machine Physical Asset';
        machinePhysicalAsset.RecordTypeId = machineRecId;
        machinePhysicalAsset.PONumberMachines__c = '123567';
        machinePhysicalAsset.PONumberRequiredMachines__c = 'Yes';
        machinePhysicalAsset.PONumberTypeMachines__c = 'Variable';
        physicalAssetList.add(machinePhysicalAsset);
        
        PhysicalAsset__c optionPhysicalAsset = new PhysicalAsset__c();
        optionPhysicalAsset.Name = 'Test Option Physical Asset';
        optionPhysicalAsset.RecordTypeId = optionRecId;
        optionPhysicalAsset.PONumberServices__c = '123567';
        optionPhysicalAsset.PONumberRequiredServices__c = 'Yes';
        optionPhysicalAsset.PONumberTypeServices__c = 'Variable';
        physicalAssetList.add(optionPhysicalAsset);
        Database.Insert(physicalAssetList);
        
        List<Apttus_Config2__AssetLineItem__c> aLIList = new List<Apttus_Config2__AssetLineItem__c>();
        Apttus_Config2__AssetLineItem__c machineAssetLineItem = new Apttus_Config2__AssetLineItem__c();
        machineAssetLineItem.Name = 'Test Machine Asset Line Item';
        machineAssetLineItem.Apttus_CMConfig__AgreementId__c = machinetestAgreement.Id;
        machineAssetLineItem.APTS_Physical_Asset__c = machinePhysicalAsset.Id;
        aLIList.add(machineAssetLineItem);
        
        Apttus_Config2__AssetLineItem__c optionAssetLineItem = new Apttus_Config2__AssetLineItem__c();
        optionAssetLineItem.Name = 'Test Option Asset Line Item';
        optionAssetLineItem.Apttus_CMConfig__AgreementId__c = optionTestAgreement.Id;
        optionAssetLineItem.APTS_Physical_Asset__c = optionPhysicalAsset.Id;
        aLIList.add(optionAssetLineItem);
        
        Apttus_Config2__AssetLineItem__c relatedAssetLineItem = new Apttus_Config2__AssetLineItem__c();
        relatedAssetLineItem.Name = 'Test Option Asset Line Item';
        relatedAssetLineItem.APTS_relatedlist_agreement__c = optionTestAgreement.Id;
        relatedAssetLineItem.APTS_Physical_Asset__c = machinePhysicalAsset.Id;
        aLIList.add(relatedAssetLineItem);
        Database.Insert(aLIList);
        
    }
    
    /* updatng the Agreement PO Details*/
    @isTest
    private static void testPODetailsUpdate(){
        Id machineRecId = Schema.SObjectType.PhysicalAsset__c.getRecordTypeInfosByName().get('Machine').getRecordTypeId();
        Id optionRecId = Schema.SObjectType.PhysicalAsset__c.getRecordTypeInfosByName().get('Option').getRecordTypeId();
        
        APTS_AgreementPODetailsTriggerHandler handler = new APTS_AgreementPODetailsTriggerHandler();
        handler.beforeDelete(null, null);
        handler.afterDelete(null, null);
        handler.afterUndelete(null, null);
        
        Test.startTest();
        User testUser = [SELECT Id FROM User LIMIT 1];
        List<Account> accountList = [SELECT Id FROM Account WHERE name = 'Test Account' LIMIT 1];
        Apttus__APTS_Agreement__c machineTestAgreement = [SELECT Id,Name,APTS_Country__c,recordtype.name FROM Apttus__APTS_Agreement__c 
                                                    WHERE Name LIKE 'Test Agreement' LIMIT 1];
        Apttus__APTS_Agreement__c optionTestAgreement = [SELECT Id,Name,APTS_Country__c,recordtype.name FROM Apttus__APTS_Agreement__c 
                                                    WHERE Name LIKE 'New Agreement' LIMIT 1];
        
        List<APTS_Agreement_PO_Details__c> poUpdateList = new List<APTS_Agreement_PO_Details__c>();
        APTS_Agreement_PO_Details__c machineAgreementPODetails = [SELECT Id, APTS_PO_Number_Required__c, APTS_PO_Number_Type__c, APTS_PO_Number__c, APTS_Agreement__c FROM APTS_Agreement_PO_Details__c WHERE APTS_Agreement__c =: machineTestAgreement.Id LIMIT 1];
        machineAgreementPODetails.APTS_PO_Number_Type__c = 'Fixed';
        machineAgreementPODetails.APTS_PO_Number__c = '123567';
        poUpdateList.add(machineAgreementPODetails);
        
        APTS_Agreement_PO_Details__c optionAgreementPODetails = [SELECT Id, APTS_PO_Number_Required__c, APTS_PO_Number_Type__c, APTS_PO_Number__c, APTS_Agreement__c FROM APTS_Agreement_PO_Details__c WHERE APTS_Agreement__c =: optionTestAgreement.Id LIMIT 1];
        optionAgreementPODetails.APTS_PO_Number_Type__c = 'Fixed';
        optionAgreementPODetails.APTS_PO_Number__c = '23456';
        poUpdateList.add(optionAgreementPODetails);
        Database.Update(poUpdateList);
    
        List<PhysicalAsset__c> updatedMachineAsset = [SELECT Id, PONumberMachines__c, PONumberRequiredMachines__c, PONumberTypeMachines__c, RecordTypeId FROM PhysicalAsset__c WHERE RecordTypeId =: machineRecId LIMIT 1];
        List<APTS_Agreement_PO_Details__c> machineAgreementList = [SELECT Id, APTS_PO_Number__c, APTS_PO_Number_Required__c, APTS_PO_Number_Type__c FROM APTS_Agreement_PO_Details__c WHERE APTS_Agreement__c =: machinetestAgreement.Id LIMIT 1];
        system.assertEquals(machineAgreementList[0].APTS_PO_Number__c, updatedMachineAsset[0].PONumberMachines__c);
        
        Test.stopTest();        
    }
}