@isTest
private class TS_GenerateFileLinkController_Test {
    /**
    * @author        
    * @date                     
    * @description   Test method for constructor
    * @revision(s)   
    */

    static testMethod void testConstructor() {
        User u = TS_TestDataFactory.createUser(Label.TS_Default_User_Profile);
        
        System.runAs(u) {
            Test.startTest();
                TS_GenerateFileLinkController ctrl = new TS_GenerateFileLinkController();
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
        TS_GenerateFileLinkController.hasException = true;
        User u = TS_TestDataFactory.createUser(Label.TS_Default_User_Profile);
        
        System.runAs(u) {
            Test.startTest();
            TS_GenerateFileLinkController ctrl = new TS_GenerateFileLinkController();
            Test.stopTest();
            
            System.assert(TS_GenerateFileLinkController.hasException);
        }
    }
}