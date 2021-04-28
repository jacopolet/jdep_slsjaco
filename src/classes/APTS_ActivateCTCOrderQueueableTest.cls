/*************************************************************
    @Name: APTS_ActivateCTCOrderQueueableTest
    @Author: Aarthi Pitchai
    @CreateDate: 14-Apr-2021
    @Description: Test class to cover CTC order activation scenarios
    @UsedBy: APTS_ActivateCTCOrderQueueable
    ******************************************************************/
    @isTest
    private with sharing class APTS_ActivateCTCOrderQueueableTest {

        @testSetup static void setupTestData() {

            User oTestUser = APTS_TestFacade.createTestUser();
            APTS_TestFacade.createMandatoryRecords(oTestUser);
            APTS_TestFacade.createAndConfigureOrder(oTestUser);
        }

        @isTest static void test_ActivateCTCOrderQueueable() {

            User oTestUser = APTS_TestFacade.getTestUser();
            Apttus_Config2__Order__c oOrder = APTS_TestFacade.getOrder();
            oOrder.APTS_Scenario__c = 'Trial to Sales';
            Database.update(oOrder, false);

            test.startTest();
            System.runAs(oTestUser) {
                System.assertNotEquals(NULL, oOrder);
                System.assertNotEquals(NULL, oOrder.id);
                System.enqueueJob(new APTS_ActivateCTCOrderQueueable(oOrder.id,oOrder.Apttus_Config2__SoldToAccountId__c, oOrder.APTS_Scenario__c));              
            }
            test.stopTest();        
        }    
           
    }