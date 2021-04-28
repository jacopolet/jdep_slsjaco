@isTest
private class APTS_GetPriceRest_Test {

    /**
     * This is a test method for all
     */
  

       @testSetup
    private static void testDataSetup() 
    {
        User testuser = APTS_TestUtils.createUser();
        System.runAs(testuser) 
        {
            // Get Custom Class Settings
            Apttus_Config2__ConfigCustomClasses__c configCustomClasses = APTS_TestUtils.getCustomClassSettings();
            insert configCustomClasses;
            
            // Create a contact
            Contact con= APTS_TestUtils.createContact();
            insert con;
            
            // Create purchasing organization
            Account organisation = APTS_TestUtils.createBuyingGroup();
            insert organisation;
            
            // Create three accounts
            Account grandParentAccount = APTS_TestUtils.createGrandParentAccount();
            grandParentAccount.Purchasing_Organization__c = organisation.Id;
            insert grandParentAccount;
            
            Account parentAccount = APTS_TestUtils.createParentAccount(grandParentAccount);
            parentAccount.Purchasing_Organization__c = organisation.Id;
            insert parentAccount;
            
            Account childAccount = APTS_TestUtils.createChildAccount(parentAccount);
            childAccount.Purchasing_Organization__c = organisation.Id;
            insert childAccount;

            
            
           
        }
        
    }
      static testMethod void test_all() {
        Test.startTest();
        Account a=APTS_TestUtils.getchildaccount();
        id soldToAccountId=a.id;
           RestRequest req = new RestRequest();
           RestResponse res = new RestResponse();
            req.requestUri = '/services/apexrest/price/'+soldToAccountId;
            req.httpMethod = 'GET';
           
            RestContext.request = req;
            RestContext.response= res; 
              
        APTS_GetPriceRest.GetPriceReturnObject gpo=APTS_GetPriceRest.doGet();

        System.assertEquals(TRUE, gpo.success);
        Test.stopTest();

        // Check
        // System.assert(ApexPages.hasMessages());
        // for(ApexPages.Message msg : ApexPages.getMessages()) {
        //     System.assertEquals('Upload file is NULL', msg.getSummary());
        //     System.assertEquals(ApexPages.Severity.ERROR, msg.getSeverity());
        // }
    }


}