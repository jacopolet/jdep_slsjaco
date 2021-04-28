@isTest public class APTS_ContactSearchControllerTest {
    
    @testSetup static void setupTestData() {

    User oTestUser = APTS_TestFacade.createTestUser();
    APTS_TestFacade.createMandatoryRecords(oTestUser);
    APTS_TestFacade.createAndConfigureAgreement(oTestUser);
    APTS_TestFacade.createAndConfigureOrder(oTestUser);
    }
    @isTest static void test_ReOrder() {

    User oTestUser = APTS_TestFacade.getTestUser();
    Account oAccount = APTS_TestFacade.getAccount();
         Apttus_Config2__AccountLocation__c loc = new Apttus_Config2__AccountLocation__c();
    loc.Apttus_Config2__AccountId__c = oAccount.Id;
    loc.Account_Location_Status__c  = 'Valid';
    loc.SAP_Customer_ID__c = '123';
    loc.Delivery_Block_Reason__c = null;
    insert loc;
        test.startTest();
          // create contact
            List<Contact> contactList = new List<Contact>();
            Contact oContact = APTS_TestDataFactory.createContact(oAccount, '1010101011');
            oContact.Function__c = 'Buyer Ingredients';
            oContact.Main_Service_Person__c = true;
        	ocontact.LastName = 'Test TT';
        	ocontact.Email = 'testTT@qp1.org';
        string email = oContact.Email;
            contactList.add(oContact);
            Contact oContact1 = APTS_TestDataFactory.createContact(oAccount, '1010101012');
            oContact1.Function__c = 'Buyer Ingredients';
        	ocontact1.LastName = 'Test 1';
        	ocontact1.Email = 'test11@qp1.org';
        
            contactList.add(oContact1);
            Contact oContact2 = APTS_TestDataFactory.createContact(oAccount, '1010101013');
        	ocontact2.LastName = 'Test 2';
        	ocontact2.Email = 'test12@qp1.org';
            oContact2.Function__c = 'Buyer All';
            contactList.add(oContact2);     

            Database.insert(contactList);
			
         Apttus_Config2__Order__c oOrder = APTS_TestFacade.getOrder();

    System.runAs(oTestUser) {
		
      ApexPages.currentPage().getParameters().put('accountId', oAccount.Id);
        ApexPages.currentPage().getParameters().put('Id', oOrder.Id);
         APTS_ContactSearchController oController = new APTS_ContactSearchController();
      APTS_ContactSearchController.contactWrapper oWrap = new APTS_ContactSearchController.ContactWrapper();

      oController.sContactName = email;
      oController.bErrorOccurred  = false;
      //oController.oOrder = null;
      oController.sAllContactsByName = null;     
      oController.sAllContacts  = null;
      oController.iRemainContact = 1;
      oController.iLoadLess = 1;

      oController.doSOQLS();
      oController.loadContacts();
      
      ApexPages.currentPage().getParameters().put(APTS_OrderConstants.FIRST_PARAM, oAccount.Name);
      oController.sContactName = oAccount.Name;
      oController.searchContactsByName();
      oController.addContactsOnSearchByName();
      oController.updateOrder();
      oController.errorMessageForNoContacts('Test');
      oController.loadMore();
      oController.loadLess();      
      ApexPages.currentPage().getParameters().put(APTS_OrderConstants.FIRST_PARAM, 'NoResultsFound');
      oController.sContactName = 'NoResultsFound';
      oController.searchContactsByName();
      oController.addContactsOnSearchByName();
      oController.resetContactSearch(); 
    }
    

    }

}