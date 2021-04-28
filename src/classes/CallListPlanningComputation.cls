//-------------------------------------------------------------------------------------------//
// Author       :   Divino Brinas - Accenture
// Created Date :   May 05, 2017
// Usage        :   We are keeping track of how often a Contact should be called by the field Call Frequency
//-------------------------------------------------------------------------------------------//
public with sharing class CallListPlanningComputation{
    @InvocableMethod
    public static void callListValidate(List<Account> accountId){
       CustomLogging.push('callListValidate', 'CallListPlanningComputation');
       try{
            
        List<Account> acctList = new List<Account>();
        if (Schema.sObjectType.Account.fields.Id.isAccessible() &&
            Schema.sObjectType.Account.fields.Name.isAccessible() && 
            Schema.sObjectType.Account.fields.Call_List__c.isAccessible() &&
            Schema.sObjectType.Account.fields.Call_Frequency__c.isAccessible() && 
            Schema.sObjectType.Account.fields.Start_Date_Frequency__c.isAccessible() &&
            Schema.sObjectType.Account.fields.Last_Order_Date__c.isAccessible() &&
            Schema.sObjectType.Account.fields.Call_List_Adjusted__c.isAccessible() &&
            Schema.sObjectType.Account.fields.Call_List_Computation__c.isAccessible()){
            acctList = [SELECT Id, Name, Call_List__c, Call_Frequency__c, Start_Date_Frequency__c, Last_Order_Date__c
                                         , Call_List_Adjusted__c, Call_List_Computation__c
                                    FROM Account
                                   WHERE Id in : accountId ]; 
        }

        List<Account> finalAccount = new List<Account>();
        Boolean isUpdated = false;
        Date todaydate = date.today();
        Date todayDateInstance = date.newinstance(todaydate.year(), todaydate.month(), todaydate.day());
        
        
        Integer currentyear = todaydate.year();
        Date startDate = date.newinstance(currentyear, 01, 01);
        integer numberDaysDue = startDate.daysBetween(todaydateinstance);
        
        Date weekNumberToday = todayDateInstance.toStartofWeek();
        Integer numberOfWeeks = Integer.valueof(Label.Call_List_Number_of_Weeks);
        Integer numberOfWeekNow = math.MOD(Integer.valueof(math.FLOOR( ( numberDaysDue )/7)),52) + 1; 
        
        System.debug(' @@@@@ weekNumberToday  ' + weekNumberToday );
        System.debug(' @@@@@ numberOfWeeks ' + numberOfWeeks );
        System.debug(' @@@@@ numberDaysDue ' + numberDaysDue );
        System.debug(' @@@@@ numberOfWeekNow ' + numberOfWeekNow);
        
        
        
        for(Account acct : acctList ){
            if((acct.Start_Date_Frequency__c <> null && acct.Call_Frequency__c <> null) || (acct.Call_Frequency__c <> null && acct.Last_Order_Date__c <> null) ){
                String callListComputationValue = ';';
                Integer callListFreqNumber = Integer.valueof(acct.Call_Frequency__c);
                Date startDateInstance = date.newinstance(acct.Start_Date_Frequency__c.year(),acct.Start_Date_Frequency__c.month(), acct.Start_Date_Frequency__c.day());
                integer startDaysDue = startDate.daysBetween(startDateInstance );
                Integer startOfWeek = math.MOD(Integer.valueof(math.FLOOR( ( startDaysDue )/7)),52) + 1; 
                System.debug(' @@@@@ startDateInstance ' + startDateInstance );
                System.debug(' @@@@@ startOfWeek ' + startOfWeek );
        

                // Create Call List Computation field
                for(Integer i = 0; i < numberOfWeeks; i++ ){
                    callListComputationValue = callListComputationValue + startOfWeek + ';';
                    Integer holdValueNumber = startOfWeek;
                    Integer newYearWeek = 1; 
                    Integer counterWeek = 0;
                    Boolean doEnterHere = true;
                    
                    startOfWeek = startOfWeek + callListFreqNumber;
                    System.debug(' @@@@@ loop startOfWeek ' + startOfWeek );
                    if(startOfWeek > numberOfWeeks){
                        for(Integer j=holdValueNumber; j < 70; j++ ){
                            System.debug(' @@@@ j ' + j);
                            System.debug(' @@@@ counterWeek  ' + counterWeek );
                            System.debug(' @@@@ numberOfWeeks ' + numberOfWeeks);
                            if( j <= numberOfWeeks){
                                System.debug(' @@@@ j > numberOfWeeks' );
                                counterWeek = counterWeek + 1;
                            }else{
                                
                                if(doEnterHere){
                                    System.debug(' @@@@ doEnterHere');
                                    counterWeek = counterWeek + 1;
                                    newYearWeek = newYearWeek + 1;
                                    doEnterHere = false;
                                }else{
                                    System.debug(' @@@@ doEnterHere else ');
                                    counterWeek = counterWeek + 1;
                                    newYearWeek = newYearWeek + 1;
                                }
                            }
                            System.debug(' @@@@ after counterWeek  ' + counterWeek );
                            System.debug(' @@@@ after newYearWeek ' + newYearWeek );
                            if(counterWeek == callListFreqNumber ){
                                callListComputationValue = callListComputationValue + newYearWeek + ';';
                                counterWeek = 0;
                            }
                        }
                        break; 
                    }
                }
                
                System.debug(' @@@@@ callListComputationValue  ' + callListComputationValue );
                System.debug(' @@@@@ startOfWeek ' + startOfWeek );
                
                acct.Call_List_Computation__c = callListComputationValue;
                
                // For Start Frequency Date
                String valueToSearch = ';' + numberOfWeekNow + ';';
                System.debug(' @@@@@ valueToSearch ' + valueToSearch );
                System.debug(' @@@@@ callListComputationValue ' + callListComputationValue);
                if(callListComputationValue.contains(valueToSearch )){
                    if(acct.Call_List__c == false){
                        acct.Call_List__c = true;
                        finalAccount.add(acct);
                        isUpdated = true;
                    }
                }else{
                    if(acct.Call_List__c){
                        acct.Call_List__c = false;
                        finalAccount.add(acct);
                        isUpdated = true;
                    }
                
                }
                
                // For Last Order Date
                if(acct.Last_Order_Date__c <> null){
                    Date lastOrderDateInstance = date.newinstance(acct.Last_Order_Date__c.year(),acct.Last_Order_Date__c.month(), acct.Last_Order_Date__c.day());
                    Integer lastOrderNumberWeeksDue = lastOrderDateInstance.daysBetween(todayDateInstance) / 7;
                    integer lastOrderDaysDue = startDate.daysBetween(lastOrderDateInstance );
                    Integer lastOrderOfWeek = math.MOD(Integer.valueof(math.FLOOR( ( lastOrderDaysDue )/7)),52) + 1;
                    
                    system.debug(' @@@@ lastOrderDaysDue  >>> ' + lastOrderDaysDue );
                    System.debug(' @@@@ lastOrderOfWeek  >>> ' + lastOrderOfWeek );
                    System.debug(' @@@@ acct.Call_Frequency__c >>> ' + acct.Call_Frequency__c );
                    
                    Integer callListFreqMinusOne = Integer.valueof(acct.Call_Frequency__c) - 1;
                    Integer lastOrderWeekComputation = numberOfWeekNow - lastOrderOfWeek;
                    
                    System.debug(' @@@@ callListFreqMinusOne >>> ' + callListFreqMinusOne );
                    System.debug(' @@@@ lastOrderWeekComputation  >>> ' + lastOrderWeekComputation  );
                    
                    // Update the Call List Update
                    if(callListFreqNumber == 1 || lastOrderOfWeek == 0){
                        if(acct.Call_List_Adjusted__c == false){
                            System.debug(' @@@@@ acct.Call_List_Adjusted__c == false ');
                            acct.Call_List_Adjusted__c = true;
                            finalAccount.add(acct);
                            isUpdated = true;
                        }
                    }else if(lastOrderWeekComputation <= callListFreqMinusOne ){
                        if(acct.Call_List_Adjusted__c == true){
                            System.debug(' @@@@@ lastOrderDateInstance.daysBetween(todayDateInstance) < 7  ');
                            acct.Call_List_Adjusted__c = false;
                            finalAccount.add(acct);
                            isUpdated = true;
                        }
                    }else{
                        if(acct.Call_List_Adjusted__c == false){
                            System.debug(' @@@@@ acct.Call_List_Adjusted__c == false ');
                            acct.Call_List_Adjusted__c = true;
                            finalAccount.add(acct);
                            isUpdated = true;
                        }
                    }
                
                
                }
                
            }else{
                if(acct.Call_List_Adjusted__c == true || acct.Call_List__c == true){
                    acct.Call_List_Adjusted__c = false;
                    acct.Call_List__c = false;
                    finalAccount.add(acct);
                }
            }
        }
        
        if(finalAccount <> null){
            System.debug(' @@@@@ finalAccount <> null ');
            if (Schema.sObjectType.Account.fields.Call_List__c.isUpdateable() && Schema.sObjectType.Account.fields.Call_Frequency__c.isUpdateable() &&
                Schema.sObjectType.Account.fields.Start_Date_Frequency__c.isUpdateable() && Schema.sObjectType.Account.fields.Last_Order_Date__c.isUpdateable() &&
                Schema.sObjectType.Account.fields.Call_List_Adjusted__c.isUpdateable() && Schema.sObjectType.Account.fields.Call_List_Computation__c.isUpdateable()){
                update finalAccount;
            }
        }
        
        } catch (Exception e) {
            CustomLogging.debugException(e);
            CustomLogging.pop();      
            System.debug(e.getMessage() + '\n' + e.getStackTraceString());
        }
    }
    
}