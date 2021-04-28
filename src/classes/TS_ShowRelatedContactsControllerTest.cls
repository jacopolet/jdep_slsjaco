/**
* @author        Francis Allenn Alindogan
* @date          11.09.2020
* @description   Test Class for TS_ShowRelatedContacts_Controller
* @revision(s)
*/
@isTest
public class TS_ShowRelatedContactsControllerTest {
   static List<AccountContactRelation> acr;
   static List<Contact> conL1;
   static List<Contact> conL2;
   static List<String> retString;
   static Id retId;
    
   @testSetup static void dataSetup() {                                 
        List<Account> accountList = TS_TestDataFactory.createAccounts(1);
        accountList.get(0).Name = 'Test Acc';
        insert accountList;
       
       Contact con = TS_TestDataFactory.createContact();  
        con.Preferred_Language__c = 'SAP_EN';
        con.AccountId = accountList.get(0).Id;
        Insert con;
        
        Apttus_Config2__AccountLocation__c alocation = TS_TestDataFactory.createAccountLocation( accountList.get(0).Id );
        alocation.Apttus_Config2__PostalCode__c   = '123';
        alocation.Shipping_Country_ISO__c = 'NL';
        alocation.Shipping_Street_Only__c = '1';
        alocation.Apttus_Config2__City__c = 'city';
        insert alocation;
                 
        PhysicalAsset__c testAsset = new PhysicalAsset__c();
        testAsset.RecordTypeId = TS_UtilityClass.getRecordTypeIdByName('PhysicalAsset__c', 'Machine');
        testAsset.Name = 'Test Asset';
        testAsset.UniqueNumber__c = '1234567890';
        testAsset.AccountLocation__c = alocation.Id;
        insert testAsset;    
    }
        
    @isTest static void testGetRelatedContact() {        
        User u = TS_TestDataFactory.createUser(Label.TS_Default_User_Profile);
        Test.startTest();
        System.runAs(u){
            
            PhysicalAsset__c pa = [SELECT Id FROM PhysicalAsset__c LIMIT 1];
            Apttus_Config2__AccountLocation__c aLoc = [SELECT Id FROM Apttus_Config2__AccountLocation__c LIMIT 1];
            
            TS_ShowRelatedContacts_Controller.hasException = true;
            conL1 = TS_ShowRelatedContacts_Controller.getRelatedContact(pa.Id,'PhysicalAsset__c');
            conL2 = TS_ShowRelatedContacts_Controller.getRelatedContact(aLoc.Id,'Apttus_Config2__AccountLocation__c');            
            
        }
        Test.stopTest();  
        System.assertNotEquals(null, conL1);              
    }
    
    @isTest static void testGetRelatedAccConRelationship(){
                
        User u = TS_TestDataFactory.createUser(Label.TS_Default_User_Profile);
        Test.startTest();
        System.runAs(u){
            
            Account acc = [SELECT Id FROM Account LIMIT 1];
            Contact con = [SELECT Id FROM Contact LIMIT 1];
            TS_ShowRelatedContacts_Controller.hasException = true;
            acr = TS_ShowRelatedContacts_Controller.getRelatedAccConRelationship(acc.Id, con.Id);                        
        	    
        }
        Test.stopTest();    
        System.assertNotEquals(null, acr);               
    }   
    
	@isTest static void testGetRecTypeId(){                
        User u = TS_TestDataFactory.createUser(Label.TS_Default_User_Profile);
        Test.startTest();
        System.runAs(u){                                 
            retId = TS_ShowRelatedContacts_Controller.getRecTypeId(TS_Constants.TS_CONTACT_RECORDTYPE_OPERATIONALCONTACT);                                	    
        }
        Test.stopTest();    
        System.assertNotEquals(null, retId);               
    }   
    
	@isTest static void testFetchRecordTypeValues(){                
        User u = TS_TestDataFactory.createUser(Label.TS_Default_User_Profile);
        Test.startTest();
        System.runAs(u){            
            retString = TS_ShowRelatedContacts_Controller.fetchRecordTypeValues('Contact');                                	    
        }
        Test.stopTest();    
        System.assertNotEquals(null, retString);               
    }   
}