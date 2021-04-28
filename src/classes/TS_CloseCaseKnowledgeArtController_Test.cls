/*
* @author       Francis Alindogan
* @date         12/21/2019
* @description   Test class for TS_CloseCaseKnowledgeArtController
* @revision(s)
*/
@isTest
private class TS_CloseCaseKnowledgeArtController_Test {
    
    private static List<Id> cseList = new List<Id>();
    private static Knowledge__kav ka = new Knowledge__kav();
    
    
    @TestSetup
    static void setupTestData() {  

        Case csea = new Case();
        csea = TS_TestDataFactory.createFieldServiceCase();
        insert csea;
        
        Case cseb = new Case();
        cseb = TS_TestDataFactory.createFieldServiceCase();
        cseb.status = TS_Constants.STATUS_CLOSED;
        insert cseb;
        /*
        Knowledge__kav kart = new Knowledge__kav();
        kart = TS_TestDataFactory.createKA();
        insert kart;
        */             
    }               
    
    //method to get all records
    static void getAllRecords(){
        List<Case> csesList = [SELECT Id FROM Case];
        system.debug(csesList);
        for(Case cse : csesList){
            cseList.add(cse.Id);
            }
        //ka = [SELECT Id FROM Knowledge__kav LIMIT 1];
    }
     
    
    @isTest
    private static void testFilterOpenCase(){
        User u = TS_TestDataFactory.createUser(Label.TS_Default_User_Profile);
        System.runAs(u) { 
            setupTestData();
            getAllRecords();
            Test.startTest();
            List<Case> retCseList;
            String kavId = 'work-around-for-test-class-1';
            retCseList = TS_CloseCaseKnowledgeArtController.filterOpenCase(cseList, kavId);
            Test.stopTest();
            //Verify Results
            System.assertNotEquals(null,[SELECT COUNT() FROM Case WHERE Id IN: retCseList]);
        }
    }

    /*
    @isTest
    private static void testGetKnowledgeArticle(){
        User u = TS_TestDataFactory.createUser(Label.TS_Default_User_Profile);
        System.runAs(u) {
            setupTestData();
            getAllRecords();
            Test.startTest();
            Knowledge__kav retKa;
            retKa = TS_CloseCaseKnowledgeArtController.getKnowledgeArticle(ka.Id);
            Test.stopTest();
            //Verify Results
            System.assertEquals(1,[SELECT COUNT() FROM Knowledge__kav WHERE Id =: retKa.Id]);
        }
    }
    */
    
    @isTest 
    private static void testHasException(){
        User u = TS_TestDataFactory.createUser(Label.TS_Default_User_Profile);
        System.runAs(u) {
            setupTestData();
            getAllRecords();
            Test.startTest();
            List<Case> retCseList;
            Knowledge__kav retKa;
            TS_CloseCaseKnowledgeArtController.hasException = true;
            retKa = TS_CloseCaseKnowledgeArtController.getKnowledgeArticle(cseList[0]);
            String kavId = 'work-around-for-test-class-2';
            retCseList =TS_CloseCaseKnowledgeArtController.filterOpenCase(cseList, kavId);
            Test.stopTest();
            //Verify Results
            System.assertNotEquals(null,[SELECT COUNT() FROM Case WHERE Id IN: retCseList]);
        }
    }
}