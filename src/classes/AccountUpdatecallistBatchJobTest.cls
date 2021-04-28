/*
    * @author        Aditya
    * @date          10.12.2018           
    * @description   This class will cover the code of below batch class
    * @revision(s)
    * @class         Batch class :UpdateAccountCallList. 
    */


@isTest
public class AccountUpdatecallistBatchJobTest
{
 static testMethod void testMethod1()
  {
    //List<Account> lstAccount= new List<Account>();
    List<Account> lstAccount1= new List<Account>();
    List<Account> lstAccount2= new List<Account>();
    List<Account> lstAccount3= new List<Account>();
    List<Account> lstAccount4= new List<Account>();
    List<Account> lstAccount5= new List<Account>();
    List<Account> lstAccount6= new List<Account>();
    List<Account> lstAccount7= new List<Account>();
    List<Account> lstAccount8= new List<Account>();
    List<Account> lstAccount9= new List<Account>();
    List<Account> lstAccount10= new List<Account>();
     List<Account> lstAccount11= new List<Account>();
     List<Account> lstAccount12= new List<Account>();
      List<Account> lstAccount13= new List<Account>();
     
    
      
       Account acc12 = new Account();
      acc12.Name ='AD12';
      acc12.Call_Frequency__c=1.0;
      acc12.Call_List__c=true;
      acc12.Start_Date_Frequency__c=system.today()-1;
      acc12.Call_List_Preferred_Day__c='None';
      //date myDate = date.today();
      acc12.Call_List_Next_Preferred_Date__c=system.today();
      lstAccount12.add(acc12);
      
      
     Account acc1 = new Account();
      acc1.Name ='AD1';
      acc1.Call_Frequency__c=1.0; 
      acc1.Call_List__c=true;
      acc1.Start_Date_Frequency__c=system.today()-1;
      acc1.Call_List_Preferred_Day__c='Tuesday';
      acc1.Sales_Organization__c='SAP_0333';
      date myDate1 = date.today();
      acc1.Call_List_Next_Preferred_Date__c=myDate1.toStartofWeek()+1;
      lstAccount1.add(acc1);
      
      
      
       Account acc3 = new Account();
      acc3.Name ='AD3';
      acc3.Call_Frequency__c=1.0; 
      acc3.Call_List__c=true;
      acc3.Start_Date_Frequency__c=system.today()-1;
      acc3.Call_List_Preferred_Day__c='Thursday';
      acc3.Sales_Organization__c='SAP_0333';
      date myDate3 = date.today();
      acc3.Call_List_Next_Preferred_Date__c=myDate3.toStartofWeek()+3;
      lstAccount3.add(acc3);
      
       Account acc10 = new Account();
      acc10.Name ='AD4';
      acc10.Call_Frequency__c=1.0; 
      acc10.Call_List__c=true;
      acc10.Start_Date_Frequency__c=system.today()-1;
      acc10.Call_List_Preferred_Day__c='Friday';
      acc10.Sales_Organization__c='SAP_0333';
      acc10.Call_List_Next_Preferred_Date__c=system.today()+4;
      lstAccount10.add(acc10);
      
      Account acc9 = new Account();
      acc9.Name ='AD5';
      acc9.Call_Frequency__c=6.0; 
      acc9.Call_List__c=true;
      acc9.Start_Date_Frequency__c=system.today()-100;
      acc9.Call_List_Preferred_Day__c='Thursday';
      acc9.Sales_Organization__c='SAP_0333';
      acc9.Call_List_Next_Preferred_Date__c=system.today()+3;
      lstAccount9.add(acc9);
      
      Account acc4 = new Account();
      acc4.Name ='AD6';
      acc4.Call_Frequency__c=2.0; 
      acc4.Call_List__c=true;
      acc4.Start_Date_Frequency__c=system.today()-210;
      acc4.Call_List_Preferred_Day__c='Friday';
      acc4.Sales_Organization__c='SAP_0333';
      date myDate4 = date.today();
      acc4.Call_List_Next_Preferred_Date__c=myDate4.toStartofWeek()+4;
      lstAccount4.add(acc4);
      
       Account acc5 = new Account();
      acc5.Name ='Ad7';
      acc5.Call_Frequency__c=2.0; 
      acc5.Call_List__c=true;
      acc5.Start_Date_Frequency__c=system.today()-210;
      acc5.Call_List_Preferred_Day__c='None';
      acc5.Sales_Organization__c='SAP_0333';
      acc5.Call_List_Next_Preferred_Date__c=system.today();
      lstAccount5.add(acc5);
      
        Account acc6 = new Account();
      acc6.Name ='AD8';
      acc6.Call_Frequency__c=2.0; 
      acc6.Call_List__c=true;
      acc6.Start_Date_Frequency__c=system.today()-210;
      acc6.Call_List_Preferred_Day__c='Tuesday';
      acc6.Sales_Organization__c='SAP_0333';
      acc6.Call_List_Next_Preferred_Date__c=system.today()+1;
      lstAccount6.add(acc6);
      
      Account acc7 = new Account();
      acc7.Name ='AD9';
      acc7.Call_Frequency__c=2.0; 
      acc7.Call_List__c=true;
      acc7.Start_Date_Frequency__c=system.today()-210;
      acc7.Call_List_Preferred_Day__c='Wednesday';
      acc7.Sales_Organization__c='SAP_0333';
      acc7.Call_List_Next_Preferred_Date__c=system.today()+2;
      lstAccount7.add(acc7);
      
      Account acc8 = new Account();
      acc8.Name ='AD10';
      acc8.Call_Frequency__c=2.0; 
      acc8.Call_List__c=true;
      acc8.Start_Date_Frequency__c=system.today()-210;
      acc8.Call_List_Preferred_Day__c='Thursday';
      acc8.Sales_Organization__c='SAP_0333';
      acc8.Call_List_Next_Preferred_Date__c=system.today()+3;
      lstAccount8.add(acc8);
      
       Account acc13 = new Account();
      acc13.Name ='AD101';
      acc13.Call_Frequency__c=2.0; 
      acc13.Call_List__c=true;
      acc13.Start_Date_Frequency__c=system.today()-1;
      //acc13.Call_List_Preferred_Day__c='Thursday';
      //acc13.Sales_Organization__c='SAP_0333';
      acc13.Call_List_Next_Preferred_Date__c=null;
      acc13.Call_List_Last_Updated_Date__c=system.today();
      lstAccount13.add(acc13);
      
      
      
      
     
      //insert lstAccount;
      insert lstAccount1;
      insert lstAccount2;
      insert lstAccount3;
      insert lstAccount4;
      insert lstAccount5;
      insert lstAccount6;
      insert lstAccount7;
      insert lstAccount8;
      insert lstAccount9;
      insert lstAccount10;
      insert lstAccount11;
      insert lstAccount12;
      insert lstAccount13;
      
      Test.startTest();
      list<string> str=new list<string>();
      str.add('SAP_0333');
      UpdateAccountCallList obj = new UpdateAccountCallList(str);
      obj.currentweek=1;
      DataBase.executeBatch(obj);
     
      Test.stopTest();
     }
     }