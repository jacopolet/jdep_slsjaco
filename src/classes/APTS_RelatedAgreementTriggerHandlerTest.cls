/*******************************************************************************************
Name            : APTS_RelatedAgreementTriggerHandlerTest
Created By      : Shanmuga Prasath
Created Date    : 06-03-2018
Description     : Test class written for 'APTS_RelatedAgreementTriggerHandler'.
Version history : 1.0
Classes Covered : APTS_RelatedAgreementTriggerHandler
*********************************************************************************************/
@isTest
private class APTS_RelatedAgreementTriggerHandlerTest{

    @isTest
    private static void testRelatedTrigger(){
        Set<ID> agreementIdSet = new Set<Id>();
        TriggerSettings__c settings = new TriggerSettings__c(Agreement__c=true);
        Database.insert(settings, false);
        
        Account accnt = APTS_TestUtils.createGrandParentAccount();
        Database.Insert(accnt);
        accnt.name = 'Test Account';
        Database.update(accnt);
        
        Apttus_Config2__PriceList__c priceList = APTS_TestUtils.createPriceList();
        Database.Insert(priceList);
        
        Id RecId = Schema.SObjectType.Apttus__APTS_Agreement__c.getRecordTypeInfosByName().get('Standard Deal').getRecordTypeId();
        
        List<Apttus__APTS_Agreement__c> agreementList = new List<Apttus__APTS_Agreement__c>();
        Apttus__APTS_Agreement__c testAgreement = new Apttus__APTS_Agreement__c(Apttus__Account__c = accnt.Id, 
                        Name = 'Test Agreement',RecordTypeId = RecId,
                        Apttus__Contract_Start_Date__c = Date.today(), Apttus__Contract_End_Date__c = Date.today()+365, 
                        Apttus_CMConfig__PriceListId__c = priceList.id,Apttus__Subtype__c ='Fixed-Term-Fixed Costs',
                        Apttus__Status_Category__c = 'In Effect', Apttus__Status__c = 'Being Amended');
        agreementList.add(testAgreement);
        
        Apttus__APTS_Agreement__c NewAgreement = new Apttus__APTS_Agreement__c(Apttus__Account__c = accnt.Id, 
                        Name = 'New Agreement',RecordTypeId = RecId,
                        //Apttus__Contract_Start_Date__c = system.today().addmonths(1), Apttus__Contract_End_Date__c = system.today().addmonths(12), 
                        Apttus__Contract_Start_Date__c = Date.today(), Apttus__Contract_End_Date__c = Date.today()+365,
                        Apttus_CMConfig__PriceListId__c = priceList.id,Apttus__Subtype__c ='Fixed-Term-Fixed Costs',
                        Apttus__Status_Category__c = 'Request', Apttus__Status__c = 'In Amendment');
        agreementList.add(NewAgreement);
        
        Apttus__APTS_Agreement__c dummyAgreement = new Apttus__APTS_Agreement__c(Apttus__Account__c = accnt.Id, 
                        Name = 'Dummy Agreement',RecordTypeId = RecId,
                        Apttus__Contract_Start_Date__c = Date.today(), Apttus__Contract_End_Date__c = Date.today()+365, 
                        Apttus_CMConfig__PriceListId__c = priceList.id,Apttus__Subtype__c ='Fixed-Term-Fixed Costs',
                        Apttus__Status_Category__c = 'Request', Apttus__Status__c = 'Request');
        agreementList.add(dummyAgreement);
        
        Apttus__APTS_Agreement__c fromAgreement = new Apttus__APTS_Agreement__c(Apttus__Account__c = accnt.Id, 
                        Name = 'From Agreement',RecordTypeId = RecId,
                        Apttus__Contract_Start_Date__c = Date.today(), Apttus__Contract_End_Date__c = Date.today()+365, 
                        Apttus_CMConfig__PriceListId__c = priceList.id,Apttus__Subtype__c ='Fixed-Term-Fixed Costs',
                        Apttus__Status_Category__c = 'In Effect', Apttus__Status__c = 'Activated');
        agreementList.add(fromAgreement);
        
        Apttus__APTS_Agreement__c toAgreement = new Apttus__APTS_Agreement__c(Apttus__Account__c = accnt.Id, 
                        Name = 'To Agreement',RecordTypeId = RecId,
                        Apttus__Contract_Start_Date__c = Date.today(), Apttus__Contract_End_Date__c = Date.today()+365, 
                        Apttus_CMConfig__PriceListId__c = priceList.id,
                        Apttus__Status_Category__c = 'Request', Apttus__Status__c = 'Request');
                        
        Apttus__APTS_Agreement__c toAgreement1 = new Apttus__APTS_Agreement__c(Apttus__Account__c = accnt.Id, 
                        Name = 'To Agreement 1',RecordTypeId = RecId,
                        Apttus__Contract_Start_Date__c = Date.today(), Apttus__Contract_End_Date__c = Date.today()+365, 
                        Apttus_CMConfig__PriceListId__c = priceList.id,
                        Apttus__Status_Category__c = 'Request', Apttus__Status__c = 'Request');
        agreementList.add(toAgreement1);
        
        Database.insert(agreementList, false);
        
        test.starttest();
        
        Product2 product = APTS_TestUtils.createProduct('Dummy High Tax', '26940998', 'Coffee');
        Database.Insert(product);

        Id machineRecId = Schema.SObjectType.PhysicalAsset__c.getRecordTypeInfosByName().get('Machine').getRecordTypeId();

        PhysicalAsset__c machinePhysicalAsset = new PhysicalAsset__c();
        machinePhysicalAsset.Name = 'Test Machine Physical Asset';
        machinePhysicalAsset.RecordTypeId = machineRecId;
        machinePhysicalAsset.PONumberMachines__c = '123567';
        machinePhysicalAsset.PONumberRequiredMachines__c = 'Yes';
        machinePhysicalAsset.PONumberTypeMachines__c = 'Variable';
        Database.insert(machinePhysicalAsset);

        Apttus_Config2__AssetLineItem__c machineAssetLineItem = new Apttus_Config2__AssetLineItem__c();
        machineAssetLineItem.Name = 'Test Machine Asset Line Item';
        machineAssetLineItem.Apttus_CMConfig__AgreementId__c = fromAgreement.Id;
        machineAssetLineItem.APTS_Physical_Asset__c = machinePhysicalAsset.Id;
        Database.insert(machineAssetLineItem);
        
         List<Apttus__AgreementLineItem__c> aliList = new List<Apttus__AgreementLineItem__c>();

        for(integer i=0;i<100;i++){
         Apttus__AgreementLineItem__c agreementLineItem = new Apttus__AgreementLineItem__c();
         agreementLineItem.Apttus__ProductId__c = product.Id;
         agreementLineItem.Apttus__AgreementId__c = fromAgreement.Id;
         agreementLineItem.Apttus__Quantity__c = 1;
         aliList.add(agreementLineItem);
        }
        Database.Insert(aliList);
        
        List<Apttus_Config2__ProductConfiguration__c> prodConfigList = new List<Apttus_Config2__ProductConfiguration__c>();
        Apttus_Config2__ProductConfiguration__c prodConfig = new Apttus_Config2__ProductConfiguration__c();
        prodConfig.Apttus_Config2__AccountId__c = accnt.Id;
        prodConfig.Apttus_CMConfig__AgreementId__c = fromAgreement.Id;
        prodConfig.Apttus_Config2__Status__c = 'Finalized';
        prodConfigList.add(prodConfig);
        
        Apttus_Config2__ProductConfiguration__c prodConfig1 = new Apttus_Config2__ProductConfiguration__c();
        prodConfig1.Apttus_Config2__AccountId__c = accnt.Id;
        prodConfig1.Apttus_CMConfig__AgreementId__c = fromAgreement.Id;
        prodConfig1.Apttus_Config2__Status__c = 'Saved';
        prodConfigList.add(prodConfig1);
        
        Database.insert(prodConfigList, false);

        List<Apttus_Config2__LineItem__c> liList = new List<Apttus_Config2__LineItem__c>();

        for(integer i=0;i<100;i++){
          Apttus_Config2__LineItem__c oLI = new Apttus_Config2__LineItem__c();
          oLI.Apttus_Config2__ConfigurationId__c = prodConfigList[0].Id;
          oLI.Apttus_Config2__ItemSequence__c = 1;
          oLI.Apttus_Config2__LineNumber__c = 1;
          oLI.Apttus_Config2__LineStatus__c = 'Existing';
          oLI.Apttus_Config2__PricingStatus__c  = 'Completed';
          oLI.Apttus_Config2__IsPrimaryLine__c = true;
          oLI.Apttus_Config2__AssetLineItemId__c = machineAssetLineItem.Id;
          liList.add(oLI);
        }
        insert liList;
        
        List<Apttus__APTS_Related_Agreement__c> relatedAgreementList = new List<Apttus__APTS_Related_Agreement__c>();
        Apttus__APTS_Related_Agreement__c relatedAgree = new Apttus__APTS_Related_Agreement__c();
        relatedAgree.Apttus__APTS_Contract_From__c = fromAgreement.Id;
        system.debug('test:'+relatedAgree.Apttus__APTS_Contract_From__c);
        relatedAgree.Apttus__APTS_Contract_To__c = NewAgreement.Id;
        relatedAgreementList.add(relatedAgree);
        
        Apttus__APTS_Related_Agreement__c relatedAgree1 = new Apttus__APTS_Related_Agreement__c();
        relatedAgree1.Apttus__APTS_Contract_From__c = dummyAgreement.Id;
        relatedAgree1.Apttus__APTS_Contract_To__c = dummyAgreement.Id;
        relatedAgreementList.add(relatedAgree1);
        
        Apttus__APTS_Related_Agreement__c relatedAgree2 = new Apttus__APTS_Related_Agreement__c();
        relatedAgree2.Apttus__APTS_Contract_From__c = NewAgreement.Id;
        relatedAgree2.Apttus__APTS_Contract_To__c = NewAgreement.Id;
        relatedAgreementList.add(relatedAgree2);
        
        Apttus__APTS_Related_Agreement__c relatedAgreementforRenewal = new Apttus__APTS_Related_Agreement__c();
        relatedAgreementforRenewal.Apttus__APTS_Contract_From__c = fromAgreement.Id;
        relatedAgreementforRenewal.Apttus__APTS_Contract_To__c = toAgreement.Id;
        relatedAgreementforRenewal.Apttus__Relationship_From_Type__c = 'Is Renewed By';
        relatedAgreementforRenewal.Apttus__Relationship_To_Type__c = 'Is Renewal For';
        relatedAgreementList.add(relatedAgreementforRenewal);

        Apttus__APTS_Related_Agreement__c relatedAgreementforAmend = new Apttus__APTS_Related_Agreement__c();
        relatedAgreementforAmend.Apttus__APTS_Contract_From__c = fromAgreement.Id;
        relatedAgreementforAmend.Apttus__APTS_Contract_To__c = toAgreement1.Id;
        relatedAgreementforAmend.Apttus__Relationship_From_Type__c = 'Is Amended By';
        relatedAgreementforAmend.Apttus__Relationship_To_Type__c = 'Is Amendment For';
        relatedAgreementList.add(relatedAgreementforAmend);
        
        Database.insert(relatedAgreementList, false);
        Set<Id> amendSetId = new Set<Id>();
        Set<Id> renewedAgreeSetId = new Set<Id>();
        Map<Id,Id> agreementMap = new Map<Id,Id>(); 
        set<Id> fromAgreementSet = new set<Id>();
        set<Id> amendSet = new set<Id>();
        set<Id> renewSet = new set<Id>();
        Set<ID> relAgreeId = new Set<ID>();
        for(Apttus__APTS_Related_Agreement__c relAggr :relatedAgreementList){
                agreementMap.put(relAggr.Apttus__APTS_Contract_To__c, relAggr.Apttus__APTS_Contract_From__c);
                amendSetId.add(relAggr.Apttus__APTS_Contract_To__c);
                relAgreeId.add(relAggr.Id);
                fromAgreementSet.add(relAggr.Apttus__APTS_Contract_From__c);

                }

        
        APTS_RelatedAgreementTriggerHandler handler = new APTS_RelatedAgreementTriggerHandler();
        handler.beforeInsert(null);
        handler.beforeUpdate(null, null, null, null);
        handler.afterUpdate(null, null, null, null);
        handler.beforeDelete(null, null);
        handler.afterDelete(null, null);
        handler.afterUndelete(null, null);    
        List<Apttus__APTS_Agreement__c> agrList = new List<Apttus__APTS_Agreement__c>([Select Id,APTS_Agreement_Request__c,Apttus__Contract_End_Date__c,Apttus__Contract_Start_Date__c from Apttus__APTS_Agreement__c where id =: fromAgreement.Id]);
       //System.assertEquals('Amendment',agrList[0].APTS_Agreement_Request__c); 
        //System.assertEquals('New',agrList[0].APTS_Agreement_Request__c);   
        For(Apttus__APTS_Agreement__c agr : agrList){
            agreementIdSet.add(agr.id);   
        }
        System.enqueuejob( new APTS_RelatedAgreementQueueable(agreementIdSet));
        APTS_RelatedAgreementQueueable.enqueueCounterReadingQueue(agreementIdSet);   
        APTS_RelatedAgreementQueueable.initialCall(relatedAgreementList,true, false, true);
        APTS_RelatedAgreementQueueable.initialCall(relatedAgreementList,false, true, false);
        APTS_RelatedAgreementQueueable.initialCall(relatedAgreementList,true, false, false);
        APTS_RelatedAgreementQueueable.relatedAgreementFinalizeCart(relatedAgreementList, amendSetId, relAgreeId, agreementMap, fromAgreementSet, renewSet, amendSet);
        test.stoptest();
    }
    
    /* ---------- Start of PI fix # 718087----------------------- */
    @isTest
    private static void testRelatedTrigger1(){
        Set<ID> agreementIdSet = new Set<Id>();
        TriggerSettings__c settings = new TriggerSettings__c(Agreement__c=true);
        Database.insert(settings, false);
        
        Account accnt = APTS_TestUtils.createGrandParentAccount();
        Database.Insert(accnt);
        accnt.name = 'Test Account';
        Database.update(accnt);
        
        Apttus_Config2__PriceList__c priceList = APTS_TestUtils.createPriceList();
        Database.Insert(priceList);
        
        Id RecId = Schema.SObjectType.Apttus__APTS_Agreement__c.getRecordTypeInfosByName().get('Standard Deal').getRecordTypeId();
        
        List<Apttus__APTS_Agreement__c> agreementList = new List<Apttus__APTS_Agreement__c>();
        Apttus__APTS_Agreement__c fromAgreement = new Apttus__APTS_Agreement__c(Apttus__Account__c = accnt.Id, 
                        Name = 'From Agreement',RecordTypeId = RecId,
                        Apttus__Contract_Start_Date__c = Date.today(), Apttus__Contract_End_Date__c = Date.today()+365, 
                        Apttus_CMConfig__PriceListId__c = priceList.id,Apttus__Subtype__c ='Fixed-Term-Fixed Costs',
                        Apttus__Status_Category__c = 'In Effect', Apttus__Status__c = 'Activated');
        agreementList.add(fromAgreement);
        
         Apttus__APTS_Agreement__c toAgreement1 = new Apttus__APTS_Agreement__c(Apttus__Account__c = accnt.Id, 
                        Name = 'To Agreement 1',RecordTypeId = RecId,
                        Apttus__Contract_Start_Date__c = Date.today(), Apttus__Contract_End_Date__c = Date.today()+365, 
                        Apttus_CMConfig__PriceListId__c = priceList.id,
                        Apttus__Status_Category__c = 'Request', Apttus__Status__c = 'Request');
        agreementList.add(toAgreement1);
        
        Database.insert(agreementList, false);
        
        List<Apttus__APTS_Related_Agreement__c> relatedAgreementList = new List<Apttus__APTS_Related_Agreement__c>();
        Apttus__APTS_Related_Agreement__c relatedAgreementforRenewal = new Apttus__APTS_Related_Agreement__c();
        relatedAgreementforRenewal.Apttus__APTS_Contract_From__c = fromAgreement.Id;
        relatedAgreementforRenewal.Apttus__APTS_Contract_To__c = toAgreement1.Id;
        relatedAgreementforRenewal.Apttus__Relationship_From_Type__c = 'Is Renewed By';
        relatedAgreementforRenewal.Apttus__Relationship_To_Type__c = 'Is Renewal For';
        relatedAgreementList.add(relatedAgreementforRenewal);
        
        Database.insert(relatedAgreementList, false);
        test.starttest();
        APTS_RelatedAgreementTriggerHandler handler = new APTS_RelatedAgreementTriggerHandler();
        handler.beforeInsert(null);
        handler.beforeUpdate(null, null, null, null);
        handler.afterUpdate(null, null, null, null);
        handler.beforeDelete(null, null);
        handler.afterDelete(null, null);
        handler.afterUndelete(null, null);    
        List<Apttus__APTS_Agreement__c> agrList = new List<Apttus__APTS_Agreement__c>([Select Id,APTS_Agreement_Request__c,Apttus__Contract_End_Date__c,Apttus__Contract_Start_Date__c from Apttus__APTS_Agreement__c where id =: fromAgreement.Id]);
        //System.assertEquals('Renewal',agrList[0].APTS_Agreement_Request__c);
        For(Apttus__APTS_Agreement__c agr : agrList){
            agreementIdSet.add(agr.id);   
        }
        System.enqueuejob( new APTS_RelatedAgreementQueueable(agreementIdSet));
        APTS_RelatedAgreementQueueable.enqueueCounterReadingQueue(agreementIdSet);  
        APTS_RelatedAgreementQueueable.hasQueueableJobRunning();
        test.stoptest();
        
    }
    /* ---------- End of PI fix # 718087 ----------------------- */
    
}