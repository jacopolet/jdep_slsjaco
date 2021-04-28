/*
* @author        Aditya
* @date          9.11.2018           
* @description   This class will make false to calllist and calllist preferred day, calllist start day.
* @revision(s)
* @class         lightingacomponent :UpdateAccountFields.   Lightingcontroller: UpdateAccountFieldsController. Helper: UpdateAccountFieldsHelper
*/


public with sharing class AccountFieldupdates {
 @AuraEnabled
    public static void updateCheck(String key){
    //list<Account> Act_list = new list<Account>();
        Account Act_list = [select id,Call_List__c,Call_List_Preferred_Day__c ,Start_Date_Frequency__c,Call_Frequency__c,Call_List_Next_Preferred_Date__c from Account WHERE Id=:key ];
         //Account ACC =new Account();
         //ACC.id=Act_list[0].id;
        Act_list.Call_List__c=False;
        Act_list.Start_Date_Frequency__c = null;
        Act_list.Call_Frequency__c = null;
        Act_list.Call_List_Next_Preferred_Date__c = null;
        Act_list.Call_List_Preferred_Day__c = null;
        update Act_list;
    
    }
}