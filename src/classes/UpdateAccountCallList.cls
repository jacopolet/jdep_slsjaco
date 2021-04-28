/*
* @author        Aditya
* @date          10.12.2018           
* @description   This class will update the call list start date when ever the Call List Frequency = populated and  current week value
* @revision(s)   November 29, 2018 - Johan de Wild - API Field Names update. Changed Call_List_Frequency__c to Call_Frequency__c and Call_List_Start_Date__c to Start_Date_Frequency__c
                 December 10, 2018 - Johan de Wild - added || a.Call_List_Preferred_Day__c==null) to line 109
                 January 7, 2019 - Johan de Wild - edited criteria to a.Start_Date_Frequency__c <= date.today(), used to be <. Removed +1 after addDays(dayCount).
* @class         Secdhular class :UpdateAccountCallListschedule.  Test class: AccountUpdatecallistBatchJobTest
*/


global class UpdateAccountCallList  implements Database.Batchable<sObject>{ 
    //Updated on 10/11/2018
    private  list<String> sOrganization;
    public UpdateAccountCallList(String[] sorg) {
     sOrganization = sorg;
    }
    
    global decimal currentweek;
    
    global Database.QueryLocator start(Database.BatchableContext BC)
    {
        return Database.getQueryLocator('SELECT Id,Sales_Organization__c,Current_Week__c,Start_Week__c, Call_List__c,Call_List_Preferred_Day__c,Start_Date_Frequency__c,Call_Frequency__c,Call_List_Last_Updated_Date__c FROM Account where Start_Date_Frequency__c != null and Call_Frequency__c !=null  and Sales_Organization__c IN :sOrganization');
    }
    
    global void execute(Database.BatchableContext BC,List<Account> scope) {
        CustomLogging.push('execute', 'UpdateAccountCallList');
		try {
            decimal week;
            for(Account a : scope) {
                if(a.Start_Date_Frequency__c !=null && a.Start_Date_Frequency__c <= date.today() && a.Call_Frequency__c !=null) {
                    integer Evenweek=a.Current_Week__c.intvalue();
                    integer evenfrequency=a.Call_Frequency__c.intValue();
                    if( math.mod(evenfrequency, 2) == 0 && a.Current_Week__c != null && a.Call_Frequency__c !=null) {
                        week=a.Current_Week__c;
                        decimal freuency= a.Call_Frequency__c;
                        decimal startweek=week-a.Start_Week__c;
                        currentweek=startweek/freuency;
                        String currentweeks = String.valueOf(currentweek);
                        
                        if(currentweeks.indexOf('.') == -1 ) {
                            a.Call_List__c=true;
                            a.Call_List_Last_Updated_Date__c=system.today();
                            
                            Integer dayCount=0;
                            if(a.Call_List_Preferred_Day__c=='Monday') {
                                dayCount=0;
                                date myDate = date.today();
                                a.Call_List_Next_Preferred_Date__c = myDate.toStartofWeek().addDays(dayCount);
                            }
                            else if(a.Call_List_Preferred_Day__c=='Tuesday') {
                                dayCount=1;
                                date myDate = date.today();
                                a.Call_List_Next_Preferred_Date__c = myDate.toStartofWeek().addDays(dayCount);
                            }
                            else if(a.Call_List_Preferred_Day__c=='Wednesday') {
                                dayCount=2;
                                date myDate = date.today();
                                a.Call_List_Next_Preferred_Date__c = myDate.toStartofWeek().addDays(dayCount);
                            }
                            else if(a.Call_List_Preferred_Day__c=='Thursday') {
                                dayCount=3;
                                date myDate = date.today();
                                a.Call_List_Next_Preferred_Date__c = myDate.toStartofWeek().addDays(dayCount);
                            }
                            else if(a.Call_List_Preferred_Day__c=='Friday') {
                                dayCount=4;
                                date myDate = date.today();
                                a.Call_List_Next_Preferred_Date__c = myDate.toStartofWeek().addDays(dayCount);
                            }                    
                            else if(a.Call_List_Preferred_Day__c=='None' || a.Call_List_Preferred_Day__c==null) {
                                a.Call_List_Next_Preferred_Date__c=system.today();
                            }
                            
                        }
                        else {
                            a.Call_List__c=false;
                            a.Call_List_Next_Preferred_Date__c= null;
                            a.Call_List_Last_Updated_Date__c=system.today();
                        }
                    }
                    
                    else
                    {
                        decimal Eweek=a.Current_Week__c;
                        decimal Efreuency= a.Call_Frequency__c;
                        decimal Estartweek=Eweek-a.Start_Week__c;
                        decimal Ecurrentweek=Estartweek/Efreuency;
                        String Ecurrentweeks = String.valueOf(Ecurrentweek);
                        
                        if(Ecurrentweeks.indexOf('.') == -1 )
                        {
                            a.Call_List__c=true;
                            a.Call_List_Last_Updated_Date__c=system.today();
                            Integer dayCount=0;
                           if(a.Call_List_Preferred_Day__c=='Monday')
                            {
                                dayCount=0; 
                                date myDate = date.today();
                                a.Call_List_Next_Preferred_Date__c = myDate.toStartofWeek().addDays(dayCount);
                            }
                           else if(a.Call_List_Preferred_Day__c=='Tuesday')
                            {
                                dayCount=1;
                                date myDate = date.today();
                                a.Call_List_Next_Preferred_Date__c = myDate.toStartofWeek().addDays(dayCount);
                            }
                            
                           else if(a.Call_List_Preferred_Day__c=='Wednesday')
                            {
                                dayCount=2;
                                date myDate = date.today();
                                a.Call_List_Next_Preferred_Date__c = myDate.toStartofWeek().addDays(dayCount);
                            }
                           else if(a.Call_List_Preferred_Day__c=='Thursday')
                            {
                                dayCount=3;
                                date myDate = date.today();
                                a.Call_List_Next_Preferred_Date__c = myDate.toStartofWeek().addDays(dayCount);
                            }
                           else if(a.Call_List_Preferred_Day__c=='Friday')
                            {
                                dayCount=4;
                                date myDate = date.today();
                                a.Call_List_Next_Preferred_Date__c = myDate.toStartofWeek().addDays(dayCount);
                            }
                            
                           else if(a.Call_List_Preferred_Day__c=='None' || a.Call_List_Preferred_Day__c==null)
                            {
                                a.Call_List_Next_Preferred_Date__c=system.today();
                            }
                            
                        }
                        else
                        {
                            a.Call_List__c=false;
                            a.Call_List_Next_Preferred_Date__c= null;
                            a.Call_List_Last_Updated_Date__c=system.today();
                        }
                    }
                    
                }                                                   
            }
            update scope;
        } catch(exception e){
            CustomLogging.debugException(e);
            CustomLogging.pop();      
            System.debug(e.getMessage() + '\n' + e.getStackTraceString());
        }
        CustomLogging.pop();
    }
    
    global void finish(Database.BatchableContext BC) {    
        //do nothing
    }      
    
}