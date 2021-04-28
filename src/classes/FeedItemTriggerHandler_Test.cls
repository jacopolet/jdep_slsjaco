/* Karen Hung 
 * December 8, 2020
 * Test class for RelatedInvoiceTriggerHandler DOO-4734
*/
@isTest
private class FeedItemTriggerHandler_Test {
    
    static Account acct;
    static Case caseRec;
    static Task taskRec;
    
    @testSetup
    static void dataSetup() {
        TriggerSettings__c trg = TriggerSettings__c.getOrgDefaults();
        trg.FeedItemTrigger__c = true;
        upsert trg;
    }
    
    static void setupTestData(){
        acct = APTS_TestUtils.createaccount();
        insert acct;
        
        caseRec = APTS_TestUtils.createCase(acct.Id);
        caseRec.Type = TS_Constants.CASE_TYPE_CUSTOMERCARE;
        insert caseRec;
        
        taskRec = new Task();
        taskRec.WhatId = caseRec.Id;
        taskRec.ActivityDate = date.today().addDays(1);
        insert taskRec;
    }
    
    @isTest static void createCaseCommenttest(){
        User usr = TS_TestDataFactory.createUser(Label.TS_Default_User_Profile);
        System.runAs(usr) {        	
            
            test.startTest();
            setupTestData();
            
            List<FeedItem> items = new List<FeedItem>();
            FeedItem fi1 = new FeedItem();
            fi1.ParentId = caseRec.Id;
            fi1.Body = 'Case feed';
            fi1.Type = 'TextPost';
            
            Task tsk = [SELECT Id,WhatId,What.Type,ActivityDate FROM Task WHERE Id=:taskRec.Id][0];
            FeedItem fi2 = new FeedItem();
            fi2.ParentId = caseRec.Id;
            fi2.Body = 'Task Feed';
            fi2.Type = 'TextPost';
                     
            items.add(fi1);
            items.add(fi2);          
            
            insert(items);
            
            fi2.Body ='Case feed body';
            
            update fi2;            
            delete fi2;
            

            system.debug(fi2);
            test.stopTest();
            //verify if there's case comment
            List<CaseComment> cc = [SELECT ID,CommentBody FROM CaseComment];
            system.assertEquals(2, cc.size());
        }
    }
    
     @isTest static void createCaseCommenttestEx(){
        User usr = TS_TestDataFactory.createUser(Label.TS_Default_User_Profile);
        System.runAs(usr) {        	
            
            test.startTest();
            setupTestData();
            
            List<FeedItem> items = new List<FeedItem>();
            FeedItem fi1 = new FeedItem();
            fi1.ParentId = caseRec.Id;
            fi1.Body = 'Case feed';
            fi1.Type = 'TextPost';
            
            Task tsk = [SELECT Id,WhatId,What.Type,ActivityDate FROM Task WHERE Id=:taskRec.Id][0];
            FeedItem fi2 = new FeedItem();
            fi2.ParentId = caseRec.Id;
            fi2.Body = 'Task Feed';
            fi2.Type = 'TextPost';
                     
            items.add(fi1);
            items.add(fi2);  
            
            FeedItemTriggerHandler.hasException = true;
            
            insert(items);
            
            system.debug(fi2);
            test.stopTest();
            //verify if there's case comment
            List<CaseComment> cc = [SELECT ID,CommentBody FROM CaseComment];
            system.assertEquals(2, cc.size());
        }
    }

}