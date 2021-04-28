/*Created by: Karen Hung
 *Date: December 2,2020 DOO-5045
 *Description: Test Class for TS_ToastNotifController
*/
@isTest
public class TS_ToastNotifController_Test {
    static Account acct;
    static Case caseRec;
    static Case caseRec2;
    static PhysicalAsset__c asset;
    
    static void setupTestData(){
        acct = APTS_TestUtils.createaccount();
        insert acct;
        
        asset = TS_TestDataFactory.createPhysicalAsset();
        insert asset;
        
        caseRec = APTS_TestUtils.createCase(acct.Id);
        caseRec.Type = 'Field Service';
        caseRec.Subtype__c = 'S10';
        caseRec.Status = 'Open';
        caseRec.PhysicalAsset__c = asset.Id;
		insert caseRec;
        
        caseRec2 = APTS_TestUtils.createCase(acct.Id);
        caseRec2.Type = 'Field Service';
        caseRec2.Subtype__c = 'S10';
        caseRec2.Status = 'New';
        caseRec.PhysicalAsset__c = asset.Id;
		insert caseRec2;        
    }
    
    private static testMethod void getServiceCasesTest(){
        User usr = TS_TestDataFactory.createUser(Label.TS_Default_User_Profile);
        System.runAs(usr) {
            test.startTest();
            setupTestData();
            TS_ToastNotifController.getServiceCases(caseRec.Id, caseRec.Subtype__c, asset.Id);
            test.stopTest();
            //verify values
			system.assertEquals(caseRec.SubType__c, caseRec2.SubType__c);
        }
    }

}