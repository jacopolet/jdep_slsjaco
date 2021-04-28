/**
* Class Name : APTS_IncentiveTriggerHandlerTest 
* Description :  Test class for APTS_IncentiveTriggerHandler
* Author : Juhi Rawal (Apttus)
* Date Created : 8th June,2018
**/
@isTest
public class APTS_IncentiveTriggerHandlerTest{
	private static testMethod void updateAgrFieldTestMethod() {
		TriggerSettings__c settings = new TriggerSettings__c();
        settings.APTS_IncentiveTrigger__c = true;
        insert settings;

    	Apttus_Config2__PriceList__c priceList = APTS_TestUtils.createPriceList();
        Database.Insert(priceList);

        Account account = APTS_TestUtils.createGrandParentAccount();
        account.name= 'Test'; 
        Database.Insert(account);

        Id RecId = Schema.SObjectType.Apttus__APTS_Agreement__c.getRecordTypeInfosByName().get('Standard Deal').getRecordTypeId();
        Apttus__APTS_Agreement__c   testAgreement = new Apttus__APTS_Agreement__c(Apttus__Account__c = account.Id, 
                                                                                Name = 'Test Agreement',
                                                                                RecordTypeId = RecId,
                                                                                Apttus__Contract_Start_Date__c = Date.today(),
                                                                                Apttus__Contract_End_Date__c = Date.today()+365, 
                                                                                Apttus_CMConfig__PriceListId__c = priceList.id,
                                                                                Apttus__Subtype__c ='Default',
                                                                                APTS_Bill_to_Party_Ingredients__c = account.Id,
                                                                                APTS_Bill_to_Party_MachServ__c = account.Id);
        Database.Insert(testAgreement);

        Apttus_Config2__Incentive__c testIncentive = APTS_TestUtils.createIncentive(Null);
        testIncentive.Apttus_CMConfig__AgreementId__c=testAgreement.id;
        testIncentive.Apttus_Config2__Active__c=TRUE;
        Database.insert(testIncentive);

        Database.Delete([select id from Apttus_Config2__Incentive__c]);

        APTS_IncentiveTriggerHandler oIncentiveHandler = new APTS_IncentiveTriggerHandler(); 
        oIncentiveHandler.beforeInsert(null);
        oIncentiveHandler.beforeUpdate(null,null,null,null);
        oIncentiveHandler.beforeDelete(null,null);
        oIncentiveHandler.AfterUndelete(null,null);        
    }
}