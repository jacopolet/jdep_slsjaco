/**************************************************************
* @Author: Keerthana
* @Company: Accenture
* @Description: Test class for APTS_AccountBizland
* @Created Date: OCT 08, 2018
* @Revisions:
*      <Name>                  <Date>          <Description>
*      Keerthana      Oct 10, 2018    Initial Version
* 
*************************************************************/
@isTest
private class APTS_AccountBizIslandTest {
    
    @testSetup
    static void testData(){
        Account acc = APTS_TestDataFactory.createAccount('testAccount,S');
        acc.APTS_BizIsland_Bonsai_Account__c = true;
        acc.Sales_Organization__c = 'SAP_0975';
        acc.Commercial_Register_Number__c = '1234';
        acc.Distribution_Channel__c = 'SAP_10';
        acc.Segment__c = 'SAP_A';
        acc.Main_Street_Only__c='Test,Test1';
        acc.Second_Account_Name__c='Test,Account';
        acc.Main_City__c='Test,City';
        acc.Main_City__c='TestCity';
        acc.Sales_Office__c='SAP_DK10';
        Database.insert(acc);
        
        Account acc1 = APTS_TestDataFactory.createAccount('testAccount1');
        acc1.APTS_BizIsland_Bonsai_Account__c = true;
        acc1.Sales_Organization__c = 'SAP_0975';
        acc1.Commercial_Register_Number__c = '1234';
        acc1.Segment__c = 'SAP_A';
        acc1.parentId =acc.id;
        acc1.CreatedDate = Date.Today()-1;
        acc1.LastModifiedDate = Date.Today();
        Database.insert(acc1);
        
         Contact contact = new Contact();
         contact.AccountId = acc.Id;
         contact.LastName = acc.Name;
         contact.Email = 'test@qp1.org';
         insert contact;
        
        Apttus_Config2__PriceList__c pricelist =APTS_TestDataFactory.createPriceList('Test');
        insert pricelist;
        
        List<Apttus__APTS_Agreement__c> agreementList=new List<Apttus__APTS_Agreement__c>();       
        Apttus__APTS_Agreement__c agreement = APTS_TestDataFactory.createAgreement(contact.id,pricelist.id,acc.id,'Standard Deal');
        agreement.Apttus__Agreement_Number__c='8059';
        agreement.Apttus__Version_Number__c=1;
        agreement.Apttus__Account__c=acc.id;
        agreement.Apttus__Status_Category__c='In Effect';
        agreement.Apttus__Status__c='Activated'; 
        agreement.APTS_Sold_To__c=acc.id;
        agreement.Apttus__Contract_End_Date__c=Date.Today();
        agreementList.add(agreement);
        insert agreementList;



        Bonsai__c customSetting = new Bonsai__c();
        customSetting.Name = 'test';
        customSetting.Delta_Load__c = true;
        customSetting.Full_Load__c = true;
        insert customSetting;
    
        BizIsland_Request__c bizland = new BizIsland_Request__c();
        bizland.name = 'Bonsai Request '+Date.Today();
        Database.insert(bizland);
    }
    
   /* @isTest
    static void testDeltaBatch(){
        
        Test.startTest();
        APTS_AccountBizIsland accountBizbatch = new APTS_AccountBizIsland();
        Database.executeBatch(accountBizbatch,200);
        
        Test.stopTest();
        
        //Account accUpdated = new Account();
        //accUpdated = [Select id, APTS_BizIsland_Bonsai_Account__c From Account where Sales_Organization__c LIKE 'SAP_'];
       // Integer acc= [SELECT count() FROM Account where Sales_Organization__c = 'SAP_0975' AND (CreatedDate = TODAY OR lastModifiedDate = TODAY)];
        //system.assertEquals(true, accUpdated.APTS_BizIsland_Bonsai_Account__c);
       // system.assertEquals(2, acc);
    }
    
   @isTest
    static void testFullBatch(){
        Bonsai__c customSetting = Bonsai__c.getAll().values();
        customSetting.Delta_Load__c = false;
        customSetting.Full_Load__c = true;
        update customSetting;
        
        Test.startTest();
        APTS_AccountBizIsland accountBizbatch = new APTS_AccountBizIsland();
        Database.executeBatch(accountBizbatch,200);
        Test.stopTest();
    }*/
    
    @isTest
    static void testElseBatch(){
        Bonsai__c customSetting = Bonsai__c.getAll().values();
        customSetting.Delta_Load__c = false;
        customSetting.Full_Load__c = true;
        update customSetting;
        
        Test.startTest();
        APTS_AccountBizIsland accountBizbatch = new APTS_AccountBizIsland();
        Database.executeBatch(accountBizbatch,200);
        Test.stopTest();
       // List<Account> accUpdatedList = [Select id, APTS_BizIsland_Bonsai_Account__c From Account where Sales_Organization__c LIKE 'SAP_'];
        //Integer acc= [SELECT count() FROM Account where Sales_Organization__c = 'SAP_0975' AND (CreatedDate = TODAY OR lastModifiedDate = TODAY)];
       // System.assert(accUpdatedList!=NULL);
    }
}