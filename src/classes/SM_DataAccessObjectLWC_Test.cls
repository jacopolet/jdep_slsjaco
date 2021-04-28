@isTest
public without sharing class SM_DataAccessObjectLWC_Test {
    static testMethod void testgetAgreementList() {
        Account acc = new Account();
        acc.Name = 'accName';
        acc.Second_Account_Name__c = 'sAccName';
        acc.Sales_Organization__c = 'SAP_0111';
        acc.Phone = '+09238409384';
        insert acc;
            
        Contact con1 = new Contact();
        
        Con1.FirstName = 'Jed';
        Con1.LastName = 'Samaniego';
        Con1.AccountId = acc.id;
        Con1.Phone = '+31302979111';
        Con1.Email = 'testqweqwe@gmail.com';
        Con1.MobilePhone = '+31302979122';
        Con1.Sales_Organization__c = 'SAP_0111';
        checkRecursive.run = true; 
        insert con1;

        Opportunity opp = new Opportunity();
        opp.Name = 'oppName';
        opp.AccountId = acc.id;
        opp.CLoseDate = Date.Today();
        opp.StageName = 'Open';
        opp.RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get(SM_Constants.OppStandardRT).getRecordTypeId();
        insert opp;

        List<Apttus_Config2__PriceList__c> priceList=new List<Apttus_Config2__PriceList__c>();
        priceList=TestDataFactory.createPriceList(1);
        insert priceList;

        Apttus__APTS_Agreement__c oAgreement = new Apttus__APTS_Agreement__c();
        oAgreement.Apttus__Status_Category__c = 'In Effect';
        oAgreement.Apttus__Status__c = 'Activated';
        oAgreement.Apttus__Contract_End_Date__c = Date.Today().addDays(365);             
        oAgreement.APTS_Is_Amended_for_Indexation__c = true; //to increase line coverage - akhilesh 
        oAgreement.recordtypeid = Schema.SObjectType.Apttus__APTS_Agreement__c.getRecordTypeInfosByName().get('Standard Deal').getRecordTypeId();
        oAgreement.Name = 'Agreement';
        oAgreement.Apttus__Primary_Contact__c = con1.Id;          
        oAgreement.Apttus_CMConfig__PriceListId__c = priceList[0].Id;
        oAgreement.Apttus_CMConfig__PricingDate__c = System.Today();
        oAgreement.Apttus__Account__c = acc.Id;
        oAgreement.APTS_Sold_To__c = acc.Id;
        insert oAgreement;
       

        List<SM_DataAccessObjectLWC.AgreementWrapper> result = SM_DataAccessObjectLWC.getAgreementList(opp.Id);
        System.assert(result.size() > 0);
    }

    static testMethod void testGTM() {
        Account gtm = new Account();
        gtm.Name = 'accName';
        gtm.Second_Account_Name__c = 'sAccName';
        gtm.Sales_Organization__c = 'SAP_0111';
        gtm.Phone = '+09238409384';
        gtm.Partner__c = true;
        gtm.FSD__c = true;
        insert gtm;

        Account acc = new Account();
        acc.Name = 'accName';
        acc.Second_Account_Name__c = 'sAccName';
        acc.Sales_Organization__c = 'SAP_0111';
        acc.Phone = '+09238409384';
        acc.GTM_Ingredients__c = gtm.Id;
        insert acc;

        Account result1 = SM_DataAccessObjectLWC.fetchAccount(acc.Id);
        System.assert(result1.GTM_Ingredients__c != Null);
    }
}