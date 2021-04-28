/**
* @author        Harold Marilag
* @date          7.10.2017           
* @description   Test class for CaseModificationBatch
* @revision(s)
*/
@isTest
private class CaseModificationBatch_Test {

    @testSetup
    static void dataSetup() {
        //Custom settings is being shared by all test class, if another test class has already inserted the record 
        //this test class will throw "UNABLE_TO_LOCK_ROW, unable to obtain exclusive access to this record"
        try {
            TriggerSettings__c trg = TriggerSettings__c.getOrgDefaults();
            trg.CaseTrigger__c = true;
            trg.WorkOrderTrigger__c = true;
            trg.WorkOrderLineItemTrigger__c = true;
            upsert trg;      
            system.debug('trg is:'+trg);
        } catch(Exception ex) {
            system.debug(ex);
        }

         try {
            IntegrationTriggerSettings__c trg1 = IntegrationTriggerSettings__c.getOrgDefaults();
            trg1.IntegrationLogTrigger__c = true;
            upsert trg1; 
        } catch(Exception ex) {
            system.debug(ex);
        }

        ProcessBuilderSettings__c pb = new ProcessBuilderSettings__c();
        pb.WorkOrderPBFlows__c = true;
        pb.CasePBFlows__c = true;
        insert pb;
    }

    /**
    * @author        Harold Marilag
    * @date          7.11.2017           
    * @description   Test method for batch methods
    * @revision(s)   PA 7.11.2017 - Updated the test method
    */
    static testMethod void testCaseModificationBatch(){
        
        User usr = TS_TestDataFactory.createUser(Label.TS_Default_User_Profile);

        System.runAs(usr) {
            
            List<Account> accList = TS_TestDataFactory.createAccounts(5);
            for(integer l=0; l<accList.size();l++){
                accList.get(l).Sales_Organization__c = 'SAP_0333';
            }
            insert accList;
                
            List<Contact> conList = new List<Contact>();
            List<Apttus_Config2__AccountLocation__c> alList = new List<Apttus_Config2__AccountLocation__c>();
            for(Account a : accList){
                Contact newContact = new Contact(AccountId=a.Id, Lastname='Sample' + a.Id, Email='sample@test.com', Phone='+31302979111');
                conList.add(newContact);
                
                Apttus_Config2__AccountLocation__c al = TS_TestDataFactory.createAccountLocation(a.Id);     
                al.ApprovalPreventiveMaintenanceWTS__c = true;
                al.Account_Location_Status__c = 'ACTIVE';
                al.Apttus_Config2__IsDefault__c = true;
                al.ApprovalPreventiveMaintenanceWTS__c = true;
                al.Additional_Case_Contact__c = newContact.Id;
                alList.add(al);
            }
            insert conList; 
            insert alList;
            
            List<Product2> prodList = new List<Product2>();
            for(Integer j=0;j<=5;j++){
                Product2 p2 = TS_TestDataFactory.createProduct('P' + j, 'MA');
                //p2.Cost_Price_Unit__c = '100';
                //p2.Standard_Price__c = '100';
                prodList.add(p2);
            }
            insert prodList;
            
            List<Case> caseList = new List<Case>();
            List<Id> accountIds = new List<Id>();
            List<Id> accLocIds = new List<Id>();
            List<Id> productIds = new List<Id>();
            
            for(Integer i = 0; i<=5; i++){
                Case cse = new Case();
                cse.Subject = 'Case ' + i;
                cse.AccountId = accList.get(i).Id;
                cse.ContactId = conList.get(i).Id;
                cse.SLADate__c = datetime.now();
                cse.Status = 'New';
                cse.SubType__c = 'Corrective Maintenance';
                cse.Type = 'Field Service';
                cse.Origin = 'E-mail';
                cse.SalesOrganization__c='SAP_0333';
                cse.GenerateOrder__c = true;
                cse.ProductId = prodList.get(i).Id;
                cse.AccountLocation__c = alList.get(i).Id;
                cse.OwnerId = usr.Id;
                caseList.add(cse);
                
            }
            
            insert caseList;
            
            for(Case c :  caseList){
                accountIds.add(c.AccountId);
                accLocIds.add(c.AccountLocation__c);
                productIds.add(c.ProductId);
            }

            PhysicalAsset__c pa = new PhysicalAsset__c(Name='TestAnonymous', 
                              UniqueNumber__c = 'TestMachine-1', 
                              RecordTypeId = Schema.SObjectType.PhysicalAsset__c.getRecordTypeInfosByName().get('Machine').getRecordTypeId(),
                              SalesOrganization__c='SAP_0333',
                              IncludesPreventiveMaintenanceCoverage__c = true,
                              PreventiveMaintenanceInterval__c = '1',
                              LastPreventiveMaintenanceDate__c = Date.valueOf('2017-1-2'),
                              AssetStatus__c = 'Activated',
                              Product__c = productIds.get(1),
                              SoldTo__c = accountIds.get(1),
                              AccountLocation__c = accLocIds.get(1));

            insert pa;

            Id pricebookId = Test.getStandardPricebookId();
            
            Pricebook2 customPB = new Pricebook2(Name='Custom Pricebook', isActive=true, Is_Country_Standard_Price__c = true, Sales_Organization__c = 'SAP_0333');
            insert customPB;
            
            PricebookEntry standardPrice = new PricebookEntry(
                Pricebook2Id = pricebookId, 
                IsActive = true, 
                UseStandardPrice=false,
                Product2Id = productIds.get(1),
                UnitPrice = 100, 
                OldStandardPrice__c=100.0);
            insert standardPrice;
            
            PricebookEntry customPrice = new PricebookEntry(
                Pricebook2Id = customPB.Id, 
                IsActive = true, 
                UseStandardPrice=false,
                Product2Id = productIds.get(1),
                UnitPrice = 100, 
                OldStandardPrice__c=100.0);
            insert customPrice;
            
            Test.startTest();
                Database.executeBatch(new CaseModificationBatch(caseList, accountIds, accLocIds, productIds), 40);
            Test.stopTest();
                
            System.assertEquals(caseList.size() + 1, [Select count() from Case]);
        }
    }
}