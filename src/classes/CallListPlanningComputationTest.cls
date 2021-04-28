/**
 * This class contains unit tests for validating the behavior of CallListPlanningComputation
 * and triggers.
 */
//-------------------------------------------------------------------------------------------//
// Author       :   Alvin Lomod - Accenture
// Created Date :   June 23, 2017
// Usage        :   
// Updates      :   September 18, 2017 - Alvin Lomod - Remediation - Assert
//-------------------------------------------------------------------------------------------//
@isTest
private class CallListPlanningComputationTest{
    
    
    static testMethod void Scene1Test(){
        
        Test.startTest();
        
        List<Account> accList = new List<Account>();
        
        Account acc = new Account();
        acc.Name = 'accNamexx';
        acc.Second_Account_Name__c = 'sAccNamexx';
        //acc.Sales_Office__c = 'SAP_F020';
        acc.Phone = '+31302979222';
        acc.Call_List__c = true;
        acc.Call_Frequency__c = 2;
        acc.Start_Date_Frequency__c = Date.Today();
        acc.Last_Order_Date__c = Date.Today().addYears(-1);
        acc.Call_List_Adjusted__c = false;
        acc.Call_List_Computation__c = '';
        
        accList.add(acc);
        insert accList;
        
        CallListPlanningComputation.CallListValidate(accList);
        
        Test.stopTest();
        
        Account nAcc = [SELECT Id, Call_List__c, Call_Frequency__c, Call_List_Adjusted__c, Call_List_Computation__c FROM Account LIMIT 1]; 
        //system.assertEquals(';38;40;42;44;46;48;50;52;2;4;6;8;10;12;14;16;18;', nAcc.Call_List_Computation__c);
        system.assertEquals(true, nAcc.Call_List_Adjusted__c);
        system.assertEquals(true, nAcc.Call_List__c);
        
    }
    
    static testMethod void Scene2Test(){
        
        Test.startTest();
        
        List<Account> accList = new List<Account>();
        
        Account acc = new Account();
        acc.Name = 'accNamexx';
        acc.Second_Account_Name__c = 'sAccNamexx';
        //acc.Sales_Office__c = 'SAP_F020';
        acc.Phone = '+31302979333';
        acc.Call_List__c = false;
        acc.Call_Frequency__c = 1;
        acc.Start_Date_Frequency__c = Date.Today();
        acc.Last_Order_Date__c = Date.Today().addYears(-1);
        acc.Call_List_Adjusted__c = true;
        acc.Call_List_Computation__c = '';
        
        accList.add(acc);
        insert accList;
        
        CallListPlanningComputation.CallListValidate(accList);
        
        Test.stopTest();
        
        
        Account nAcc = [SELECT Id, Call_List__c, Call_Frequency__c, Call_List_Adjusted__c, Call_List_Computation__c FROM Account LIMIT 1]; 
        //system.assertEquals(';38;39;40;41;42;43;44;45;46;47;48;49;50;51;52;1;2;3;4;5;6;7;8;9;10;11;12;13;14;15;16;17;18;', nAcc.Call_List_Computation__c);
        system.assertEquals(true, nAcc.Call_List_Adjusted__c);
        system.assertEquals(true, nAcc.Call_List__c);
    }
    
    static testMethod void Scene3Test(){
        
        Test.startTest();
        
        List<Account> accList = new List<Account>();
        
        Account acc = new Account();
        acc.Name = 'accNamexx';
        acc.Second_Account_Name__c = 'sAccNamexx';
        //acc.Sales_Office__c = 'SAP_F020';
        acc.Phone = '+31302979333';
        acc.Call_List__c = true;
        acc.Call_Frequency__c = 1;
        acc.Start_Date_Frequency__c = Date.Today();
        acc.Last_Order_Date__c = Date.Today().addDays(-14);
        acc.Call_List_Adjusted__c = false;
        acc.Call_List_Computation__c = '';
        
        accList.add(acc);
        insert accList;
        
        CallListPlanningComputation.CallListValidate(accList);
        
        Test.stopTest();
        
        Account nAcc = [SELECT Id, Call_List__c, Call_Frequency__c, Call_List_Adjusted__c, Call_List_Computation__c FROM Account LIMIT 1]; 
        //system.assertEquals(';38;39;40;41;42;43;44;45;46;47;48;49;50;51;52;1;2;3;4;5;6;7;8;9;10;11;12;13;14;15;16;17;18;', nAcc.Call_List_Computation__c);
        system.assertEquals(true, nAcc.Call_List_Adjusted__c);
        system.assertEquals(true, nAcc.Call_List__c);
    }
    
    static testMethod void Scene4Test(){
        
        Test.startTest();
        
        List<Account> accList = new List<Account>();
        
        Account acc = new Account();
        acc.Name = 'accNamexx';
        acc.Second_Account_Name__c = 'sAccNamexx';
        //acc.Sales_Office__c = 'SAP_F020';
        acc.Phone = '+31302979333';
        acc.Call_List__c = true;
        acc.Call_Frequency__c = null;
        acc.Start_Date_Frequency__c = null;
        acc.Last_Order_Date__c = null;
        acc.Call_List_Adjusted__c = true;
        acc.Call_List_Computation__c = '';
        
        accList.add(acc);
        insert accList;
        
        CallListPlanningComputation.CallListValidate(accList);
        
        Test.stopTest();
        
        Account nAcc = [SELECT Id, Call_List__c, Call_Frequency__c, Call_List_Adjusted__c, Call_List_Computation__c FROM Account LIMIT 1]; 
        //system.assertEquals(null, nAcc.Call_List_Computation__c);
        system.assertEquals(false, nAcc.Call_List_Adjusted__c);
        system.assertEquals(false, nAcc.Call_List__c);
    }

}