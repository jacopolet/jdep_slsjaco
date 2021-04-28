/**
* @author        Paul Jarred Aguiling
* @date          12.07.2017           
* @description   Test class for TS_EmailUtility_Hyperlink_Controller
* @revision(s)   
*/
@isTest
private class TS_EmailUtilityHyperlinkCtrl_Test {
    
    /**
    * @author        Paul Jarred Aguiling
    * @date          12.07.2017           
    * @description   Test method for constructor
    * @revision(s)   
    */
    static testMethod void testConstructor() {
        User u = TS_TestDataFactory.createUser(Label.TS_Default_User_Profile);
        
        System.runAs(u) {
            PageReference emailUtilityPage = Page.TS_EmailUtility_Hyperlink;
            Test.setCurrentPageReference(emailUtilityPage); 
            ApexPages.currentPage().getParameters().put('id', null);
            ApexPages.currentPage().getParameters().put('showAsPDF', 'false');

            Test.startTest();
                TS_EmailUtility_Hyperlink_Controller ctrl = new TS_EmailUtility_Hyperlink_Controller();
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
        TS_EmailUtility_Hyperlink_Controller.hasException = true;
        User u = TS_TestDataFactory.createUser(Label.TS_Default_User_Profile);
        
        System.runAs(u) {
            PageReference emailUtilityPage = Page.TS_EmailUtility_Hyperlink;
            Test.setCurrentPageReference(emailUtilityPage); 
            ApexPages.currentPage().getParameters().put('id', null);
            ApexPages.currentPage().getParameters().put('showAsPDF', 'false');

            Test.startTest();
            TS_EmailUtility_Hyperlink_Controller ctrl = new TS_EmailUtility_Hyperlink_Controller();
            Test.stopTest();
            
            System.assert(TS_EmailUtility_Hyperlink_Controller.hasException);
        }
    }
}