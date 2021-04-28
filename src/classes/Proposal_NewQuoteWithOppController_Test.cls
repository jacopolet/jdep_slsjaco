/**
 * Class Name: Proposal_NewQuoteWithOppController_Test
 * @author: James Azana
 * Date: 28-Jun-2017
 * @description: Test Class for Proposal_NewQuoteWithOppController
 *
 */
 
@isTest(SeeAllData=false)
public class Proposal_NewQuoteWithOppController_Test{
    
    public static Account acc;
    
    private static testMethod void testProceed() {
        
        createTestData();
        
        system.test.startTest();
        
        ApexPages.StandardController sc = new ApexPages.standardController(acc); 
        Proposal_NewQuoteWithOppController controller = new Proposal_NewQuoteWithOppController(sc);
        
        //simulate press of 'New Quote with Opportunity' and 'Yes' button
        controller.createOpportunityAndProposal();
        
        //Check if opportunity is created with segment similar to account's segment
        List<Opportunity> opp = [SELECT id, name, accountid, Segment__c FROM Opportunity WHERE accountid = :acc.id];
        system.assertEquals(opp.size(), 1);
        system.assertEquals(opp[0].Segment__c, acc.Segment__c);
        
        //Check if proposal is created
        List<Apttus_Proposal__Proposal__c> proposal = [SELECT id, name, Apttus_Proposal__Opportunity__c, Apttus_Proposal__Account__c FROM Apttus_Proposal__Proposal__c
                                                       WHERE Apttus_Proposal__Opportunity__c = :opp[0].id AND Apttus_Proposal__Account__c = :acc.id];
                                                 
        system.assertEquals(proposal.size(), 1);
        controller.returnToEdit();
        controller.returnToNewProposal();
        
        system.test.stopTest();
    }
    
    private static testMethod void negativetestProceed() {
        try {
            system.test.startTest();

            ApexPages.StandardController sc = new ApexPages.standardController(new Account()); 
            Proposal_NewQuoteWithOppController controller = new Proposal_NewQuoteWithOppController(sc);
            
            //simulate press of 'New Quote with Opportunity' and 'Yes' button
            controller.createOpportunityAndProposal();
            
            //Check if opportunity is created with segment similar to account's segment
            List<Opportunity> opp = [SELECT id, name, accountid, Segment__c FROM Opportunity WHERE accountid = :acc.id];
            system.assertEquals(opp.size(), 1);
            system.assertEquals(opp[0].Segment__c, acc.Segment__c);
            
            //Check if proposal is created
            List<Apttus_Proposal__Proposal__c> proposal = [SELECT id, name, Apttus_Proposal__Opportunity__c, Apttus_Proposal__Account__c FROM Apttus_Proposal__Proposal__c
                                                           WHERE Apttus_Proposal__Opportunity__c = :opp[0].id AND Apttus_Proposal__Account__c = :acc.id];
                                                     
            system.assertEquals(proposal.size(), 1);
            controller.returnToEdit();
            controller.returnToNewProposal();
            
            system.test.stopTest();
        } catch (Exception e) {
            System.debug(e);
        }
    }
    
    private static testMethod void testCancel() {
        
        createTestData();
        
        system.test.startTest();
        
        ApexPages.StandardController sc = new ApexPages.standardController(acc); 
        Proposal_NewQuoteWithOppController controller = new Proposal_NewQuoteWithOppController(sc);
        
        //simulate press of 'New Quote with Opportunity' and 'No' button
        controller.returnToAccount();
        
        system.test.stopTest();
        
        system.assertEquals(controller.acc.Id, acc.Id);
    }
    
    
    private static void createTestData() {
        
        //Create Account
        acc = new Account();
        acc.Name = 'Test Account';
        acc.recordtypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Customer').getRecordTypeId();
        acc.Main_Street_Only__c = 'Test Street';
        acc.Phone = '+1234567890';
        acc.CurrencyIsoCode = 'EUR';
        acc.Language__c = 'SAP_EN';
        acc.Sales_Organization__c = 'SAP_0333';
        acc.Account_Type__c = 'Customer';
        acc.Segment__c = 'SAP_A';
        acc.of_Beds__c = 10;
        acc.of_drinks__c = 10;
        //acc.WSONE_DATA__NumberFulltimeEmployees__c = 10;
        acc.Exclude_from_Territory_Assignment__c = false;
        acc.Area_Code__c = 1000;
        acc.of_Seats__c = 10;
        insert acc;
        
    }
    
}