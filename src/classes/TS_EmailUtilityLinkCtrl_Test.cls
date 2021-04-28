/**
* @author        Paul Jarred Aguiling
* @date          12.07.2017           
* @description   Test class for TS_EmailUtilityLink
* @revision(s)   
*/
@isTest
private class TS_EmailUtilityLinkCtrl_Test {
    
    /**
    * @author        Paul Jarred Aguiling
    * @date          12.07.2017           
    * @description   Test method for constructor
    * @revision(s)   
    */
    static testMethod void testConstructor() {
        User u = TS_TestDataFactory.createUser(Label.TS_Default_User_Profile);
        
        System.runAs(u) {
            Test.startTest();
                TS_EmailUtilityLinkController ctrl = new TS_EmailUtilityLinkController();
                System.assert(ctrl.contentList != null);
            Test.stopTest();
        }
    }
    
    /**
    * @author        Adrian Reyes
    * @date          05.09.2018           
    * @description   Test force throw exception
    * @revision(s)   
    */
    static testMethod void testException() {
        TS_EmailUtilityLinkController.hasException = true;
        User u = TS_TestDataFactory.createUser(Label.TS_Default_User_Profile);
        
        System.runAs(u) {
            Test.startTest();
            TS_EmailUtilityLinkController ctrl = new TS_EmailUtilityLinkController();
            Test.stopTest();
            
            System.assert(TS_EmailUtilityLinkController.hasException);
        }
    }
}