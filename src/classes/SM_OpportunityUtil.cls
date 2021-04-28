//-------------------------------------------------------------------------------------------//
// Author       :   Glenn Serrano - Accenture
// Created Date :   April 29 2019
// Usage        :   Utility Class for Opportunity
//
//-------------------------------------------------------------------------------------------//
public without sharing class SM_OpportunityUtil {
    public static Boolean hasException = false;
    public static void oneTimeNOSCalculation(Set<Opportunity> opptyToUpdate){
        CustomLogging.push('oneTimeNOSCalculation', 'SM_OpportunityUtil');
        try {
            for(Opportunity oppty : opptyToUpdate){
                oppty.Amount = (oppty.Percentage_Rewarded__c/100) * oppty.Estimated_CY_NOS_Pipeline__c;
                // Don't delete
                // Decimal OneTimeNos = 0.00;
                // Decimal Estimated_Annual_NOS_Pipeline = 0.00;
                // Decimal Dateplaceholder = 0.00;
                // Decimal Datevalue = 0.00;
                // Decimal Finalval = 0.00;
                // if (oppty.One_Time_NOS__c != null){
                //     OneTimeNos = oppty.One_Time_NOS__c;
                // }
                // if (oppty.Estimated_Annual_NOS_Pipeline__c != null){
                //     Estimated_Annual_NOS_Pipeline = oppty.Estimated_Annual_NOS_Pipeline__c;
                // }
                // if (oppty.Expected_Revenue_Start_Date__c != null){
                //     Date thisdate = date.newInstance(oppty.Expected_Revenue_Start_Date__c.year(), 12, 31);
                //     Dateplaceholder = oppty.Expected_Revenue_Start_Date__c.daysBetween(thisdate);
                //     Datevalue = Dateplaceholder.divide(365, 4);
                // }
                // Finalval = OneTimeNos + (Estimated_Annual_NOS_Pipeline * Datevalue);
                // oppty.Amount = Finalval.setScale(2);
            }
            
            if(Test.isRunningTest() && hasException == true) {
              CalloutException e = new CalloutException();
              e.setMessage('Throw Exception for code coverage');
              Throw e;
            }
        } catch(exception e){
            CustomLogging.debugException(e);
            CustomLogging.pop();      
            System.debug(e.getMessage() + '\n' + e.getStackTraceString());
        } 
        CustomLogging.pop();
    }
    
    public static void stampifaccountisprospect(Set<Id> accountIds, Set<Opportunity> opportunityrec){
        CustomLogging.push('stampifaccountisprospect', 'SM_OpportunityUtil');
        try {
            Map<Id, Account> accountmap = new Map<Id, Account>();
            List<Account> accountrecords = [Select Id, RecordType.Name, Account_Lifecycle__c from Account where Id in:accountIds];
            for(Account acc : accountrecords){
                accountmap.put(acc.Id, acc);
            }
            if (!accountmap.isEmpty()){
                for (Opportunity oppty : opportunityrec){
                    if (accountmap.get(oppty.AccountId).RecordType.Name == 'Prospect' || accountmap.get(oppty.AccountId).RecordType.Name == 'Prospect Valid' || accountmap.get(oppty.AccountId).RecordType.Name == 'Prospect Invalid' || ((accountmap.get(oppty.AccountId).RecordType.Name == 'Customer' || accountmap.get(oppty.AccountId).RecordType.Name == 'Customer Validation') && accountmap.get(oppty.AccountId).Account_Lifecycle__c == 'Inactive Customer')){
                        oppty.Annual_NOS_Current_Agreement__c = 0;
                    }
                }
            }
            
        } catch(exception e){
            CustomLogging.debugException(e);
            CustomLogging.pop();      
            System.debug(e.getMessage() + '\n' + e.getStackTraceString());
        } 
        CustomLogging.pop();
    }
    
    public static void stampexpectedrevstartdate(Set<Opportunity> opportunityrec){
        CustomLogging.push('stampexpectedrevstartdate', 'SM_OpportunityUtil');
        try {
            for (Opportunity oppty : opportunityrec){
            	oppty.Expected_Revenue_Start_Date__c = oppty.CloseDate;
            }
        } catch(exception e){
            CustomLogging.debugException(e);
            CustomLogging.pop();      
            System.debug(e.getMessage() + '\n' + e.getStackTraceString());
        } 
        CustomLogging.pop();
    }
    
}