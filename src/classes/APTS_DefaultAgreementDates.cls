/**********************************************************************************
* @Author: Shahul
* @Company: Accenture
* @Description: Handles the defaulting of Dates based on multiple Conditions
* @Created Date: Feb 22, 2018
* @History:
*      <Name>              <Date>          <Description>
*      Shahul              2.14.2018       Created
*      jason.e.mactal      6.21.2018       Added Condition to check fields if has a value before populating defaults - ALM: 15821
*      aftab               7/5/2018        Commenting Account Location 
*      Akanksha            28/5/2018       Adding code for Registration Form <DOK31-225> -- v101
**********************************************************************************/
public with sharing class APTS_DefaultAgreementDates implements ITriggerHandler {
    
    public static final String CONSUMPTION = 'Consumptions Model';
    public static final String REGULAR='Regular';
    public static final String REQUEST='Request';
    public static final String DEFAULTS='Default';
    public static final String NEWREQUEST='New';
    public static final String INSIGNATURES='In Signatures';
    public static boolean triggerDisabled = false;
    
    public void beforeInsert(List<SObject> newList)
    {
        try{
            Set<Id> AccountIds = new Set<Id>();
            Set<Id> OppIds = new Set<Id>();
            Set<Id> AccountLocIds = new Set<Id>();
            Map<ID,Schema.RecordTypeInfo> RecMap = Apttus__APTS_Agreement__c.sObjectType.getDescribe().getRecordTypeInfosById();
            String accLocationId;
            String contactId;
            Set<Id> billToAccountIds = new Set<Id>();
            
            for(Apttus__APTS_Agreement__c aggrBefore:(List<Apttus__APTS_Agreement__c>)newList)
            {
                aggrBefore.APTS_PricingDate__c  = system.today(); 
                //aggrBefore.APTS_Region__c=aggrBefore.Apttus_CMConfig__PriceListId__r.APTS_Region__c; 
                OppIds.add(aggrBefore.Apttus__Related_Opportunity__c);
                //v101 << ++
                if(aggrBefore.Apttus__Related_Opportunity__c != null) {
                    AccountIds.add(aggrBefore.Apttus__Related_Opportunity__r.AccountId);
                }
                else {
                    AccountIds.add(aggrBefore.Apttus__Account__c);
                }
                //v101 ++ >>
                AccountLocIds.add(aggrBefore.APTS_Location__c);
                billToAccountIds.add(aggrBefore.Apttus__Account__c);
                if(aggrBefore.Apttus__Contract_Start_Date__c == null && aggrBefore.APTS_Migration_Date__c == null)
                {
                    aggrBefore.Apttus__Contract_Start_Date__c =system.today().addDays(7).toStartOfWeek();
                }
                if(aggrBefore.APTS_Migration_Date__c == null){
                    
                    //Populating Fixed Term Agreement Date for New Agreements with Jan 1st of next year
                    if(aggrBefore.Apttus__Version_Number__c==0){
                        aggrBefore.APTS_Fixed_Term_Startdate__c = Date.newinstance(System.Today().addYears(1).year(), 01, 01);                        
                        aggrBefore.Apttus__Auto_Renewal__c=true;
                        aggrBefore.Apttus__Subtype__c=DEFAULTS;
                    }
                    aggrBefore.Apttus__Status__c=REQUEST;
                }
                
                aggrBefore.APTS_Agreement_Request__c=NEWREQUEST;
                if(RecMap.get(aggrBefore.recordTypeID).getName().containsIgnoreCase(Consumption))
                {
                    aggrBefore.APTS_Unlimited_Machine_Ordering__c=true;
                }
                /* Commenting as this is not needed now.
                //BEG: Added by Juhi Rawal (Apttus) for flexibility rules on 7th March,2018.
                if(String.isNotBlank(aggrBefore.APTS_Location__c)){
                Id idAccnt = [select Apttus_Config2__AccountId__c from Apttus_Config2__AccountLocation__c where id =: aggrBefore.APTS_Location__c].Apttus_Config2__AccountId__c;
                aggrBefore.Apttus__Account__c = idAccnt;
                }
                //END: Added by Juhi Rawal (Apttus) for flexibility rules on 7th March,2018.
                //*/
            }
            
            List<Opportunity> OppQue=new list<Opportunity>();
            OppQue=[select id,Accountid,Account.Sales_Organization__c,Account.billingcountry,Account.Language__c,Account.Bill_To_Payer_Account__c,Account.Related_Bill_to_Machines_Services__c,Account.Related_Caterer__c,Account.Related_Payer_Account__c,Account.Related_Payer_Machines_Services__c from Opportunity where id IN:OppIds];
            List<Apttus_Config2__AccountLocation__c> AccLoc=new list<Apttus_Config2__AccountLocation__c>();
            if(OppQue.size() > 0){
                AccLoc=[select id,Apttus_Config2__AccountId__c from Apttus_Config2__AccountLocation__c where Apttus_Config2__IsDefault__c=true AND Apttus_Config2__AccountId__c = :OppQue[0].AccountId];
            
            Map<ID, Account> allAccountMap = new Map<ID, Account> ([SELECT Id, Language__c, (SELECT Id FROM Contacts WHERE Main_Commercial_Person__c=true), (SELECT Id FROM Apttus_Config2__AccountLocations__r WHERE Apttus_Config2__IsDefault__c=true) FROM Account WHERE ID=:OppQue[0].AccountId]);
            List<Account> accountList = new List<Account>();
            if(!allAccountMap.values().isempty()){
            for(Account accountSO : allAccountMap.values()){
                if(OppQue.size() > 0 && accountSO.ID == OppQue[0].AccountId)
                {
                    accountList.add(accountSO);
                }
            }
            }
            
            if(OppQue != null && OppQue.size()>0){
                
                if(accountList.size()>0){
                    for(Apttus_Config2__AccountLocation__c accLocation : accountList[0].Apttus_Config2__AccountLocations__r){
                        accLocationId = accLocation.Id;
                    }
                    for(Contact contact : accountList[0].Contacts){
                        contactId = contact.Id;
                    }
                }
            }
            
            
            for(Apttus__APTS_Agreement__c aggr1 : (List<Apttus__APTS_Agreement__c>)newList)
            {
                if(aggr1.Apttus__Related_Opportunity__c == null && allAccountMap.containsKey(aggr1.Apttus__Account__c)){
                    aggr1.APTS_Language__c = allAccountMap.get(aggr1.Apttus__Account__c).Language__c;
                }
                else{
                    aggr1.APTS_Language__c = OppQue[0].Account.Language__c;
                }
                if(OppQue.size()>0){
                    if(aggr1.APTS_Migration_Date__c == null){
                        aggr1.Apttus__Account__c=OppQue[0].AccountId;
                        if(OppQue[0].Account.Related_Caterer__c!=null){
                            aggr1.APTS_Caterer__c=OppQue[0].Account.Related_Caterer__c;
                        }
                    }
                    
                    if(aggr1.APTS_Location__c==null && AccLoc!=null&&!AccLoc.isempty()){
                        aggr1.APTS_Location__c=AccLoc[0].id;
                    }
                    
                    aggr1.APTS_Sold_To__c=OppQue[0].AccountId;
                    
                    if(aggr1.Apttus__Version_Number__c == 0 && aggr1.APTS_Migration_Date__c == null){ // No Defaulting for Amended Agreements
                        if(OppQue[0].Account.Bill_To_Payer_Account__c!=null && aggr1.APTS_Bill_to_Party_Ingredients__c == null ){
                            aggr1.APTS_Bill_to_Party_Ingredients__c=OppQue[0].Account.Bill_To_Payer_Account__c;
                        }else{
                            aggr1.APTS_Bill_to_Party_Ingredients__c=OppQue[0].AccountId;
                        }
                        
                        if(OppQue[0].Account.Related_Bill_to_Machines_Services__c!=null && aggr1.APTS_Bill_to_Party_MachServ__c == null){
                            aggr1.APTS_Bill_to_Party_MachServ__c=OppQue[0].Account.Related_Bill_to_Machines_Services__c;
                        }else{
                            aggr1.APTS_Bill_to_Party_MachServ__c=OppQue[0].AccountId;
                        }
                        
                        if(OppQue[0].Account.Related_Payer_Account__c!=null && aggr1.APTS_Payer_Ingredients__c == null){
                            aggr1.APTS_Payer_Ingredients__c=OppQue[0].Account.Related_Payer_Account__c;
                        }else{
                            aggr1.APTS_Payer_Ingredients__c=OppQue[0].AccountId;
                        }
                        
                        if(OppQue[0].Account.Related_Payer_Machines_Services__c!=null && aggr1.APTS_Payer_Machines_Services__c == null){
                            aggr1.APTS_Payer_Machines_Services__c=OppQue[0].Account.Related_Payer_Machines_Services__c;
                        }else{
                            aggr1.APTS_Payer_Machines_Services__c=OppQue[0].AccountId;
                        }
                    }
                    
                    if(String.IsBlank(aggr1.APTS_Location__c) && String.IsNotBlank(accLocationId)){
                        aggr1.APTS_Location__c = accLocationId;
                    }
                    if(String.IsBlank(aggr1.Apttus__Primary_contact__c) && String.IsNotBlank(contactId)){
                        aggr1.Apttus__Primary_contact__c = contactId;
                    }
                }
            }
            } 
            //v101 << ++
            else {
                List<Account> AccQue = [Select id, Bill_To_Payer_Account__c, Related_Bill_to_Machines_Services__c, Related_Payer_Account__c, Related_Payer_Machines_Services__c from Account where id IN:AccountIds];
                if(AccQue.size() > 0) {
                List<Contact> ConList = [SELECT Id FROM Contact WHERE Main_Commercial_Person__c=true and AccountId = :AccQue[0].Id];
                if(ConList.size() > 0) {    
                    contactId = ConList[0].Id;
                }
                    for(Apttus__APTS_Agreement__c aggr1 : (List<Apttus__APTS_Agreement__c>)newList) {
                        if(aggr1.Apttus__Version_Number__c == 0 && aggr1.APTS_Migration_Date__c == null){ // No Defaulting for Amended Agreements
                            if(AccQue[0].Bill_To_Payer_Account__c!=null && aggr1.APTS_Bill_to_Party_Ingredients__c == null ){
                                aggr1.APTS_Bill_to_Party_Ingredients__c=AccQue[0].Bill_To_Payer_Account__c;
                            }else{
                                aggr1.APTS_Bill_to_Party_Ingredients__c=AccQue[0].Id;
                            }
                            
                            if(AccQue[0].Related_Bill_to_Machines_Services__c!=null && aggr1.APTS_Bill_to_Party_MachServ__c == null){
                                aggr1.APTS_Bill_to_Party_MachServ__c=AccQue[0].Related_Bill_to_Machines_Services__c;
                            }else{
                                aggr1.APTS_Bill_to_Party_MachServ__c=AccQue[0].Id;
                            }
                            
                            if(AccQue[0].Related_Payer_Account__c!=null && aggr1.APTS_Payer_Ingredients__c == null){
                                aggr1.APTS_Payer_Ingredients__c=AccQue[0].Related_Payer_Account__c;
                            }else{
                                aggr1.APTS_Payer_Ingredients__c=AccQue[0].Id;
                            }
                            
                            if(AccQue[0].Related_Payer_Machines_Services__c!=null && aggr1.APTS_Payer_Machines_Services__c == null){
                                aggr1.APTS_Payer_Machines_Services__c=AccQue[0].Related_Payer_Machines_Services__c;
                            }else{
                                aggr1.APTS_Payer_Machines_Services__c=AccQue[0].Id;
                            }
                        }
                        if(String.IsBlank(aggr1.Apttus__Primary_contact__c) && String.IsNotBlank(contactId)){
                            aggr1.Apttus__Primary_contact__c = contactId;
                        }
                    }
            
                }
            }
            //v101 ++ >>
            /*
list<account> Acclst=new list<Account>();
Acclst=[select id,name,Bill_To_Payer_Account__c,Related_Bill_to_Machines_Services__c,Related_Caterer__c,Related_Payer_Account__c,Related_Payer_Machines_Services__c from account where id IN:AccountIds LIMIT 1];

if(Acclst!=null&&!Acclst.isempty())
{
for(Apttus__APTS_Agreement__c aggr2 : (List<Apttus__APTS_Agreement__c>)newList)
{
if(aggr2.Apttus__Account__c!=null)
{
//Added Conditions to not update fields that has values
aggr2.APTS_Sold_To__c=Acclst[0].Id;
if(aggr2.Apttus__Account__r.Related_Caterer__c!=null){
aggr2.APTS_Caterer__c=aggr2.Apttus__Account__r.Related_Caterer__c;}else{aggr2.APTS_Caterer__c=Acclst[0].Id;}
if(Acclst[0].Bill_To_Payer_Account__c!=null && aggr2.APTS_Bill_to_Party_Ingredients__c == null){
aggr2.APTS_Bill_to_Party_Ingredients__c=Acclst[0].Bill_To_Payer_Account__c;}else{aggr2.APTS_Bill_to_Party_Ingredients__c=Acclst[0].Id;}
if(Acclst[0].Related_Bill_to_Machines_Services__c!=null && aggr2.APTS_Bill_to_Party_MachServ__c == null){
aggr2.APTS_Bill_to_Party_MachServ__c=Acclst[0].Related_Bill_to_Machines_Services__c;}else{aggr2.APTS_Bill_to_Party_MachServ__c=Acclst[0].Id;}
if(Acclst[0].Related_Payer_Account__c!=null && aggr2.APTS_Payer_Ingredients__c == null){
aggr2.APTS_Payer_Ingredients__c=Acclst[0].Related_Payer_Account__c;}else{aggr2.APTS_Payer_Ingredients__c=Acclst[0].Id;}
if(Acclst[0].Related_Payer_Machines_Services__c!=null && aggr2.APTS_Payer_Machines_Services__c == null){
aggr2.APTS_Payer_Machines_Services__c=Acclst[0].Related_Payer_Machines_Services__c;}else{aggr2.APTS_Payer_Machines_Services__c=Acclst[0].Id;}
}
}
}*/
        }catch(exception e){APTS_CustomLogging.createErrorLog(e.getTypeName(), 'Apex', e.getStackTraceString() ,'Agreement',null,'CPQ',false,false,'cpqerror@accenture.com',true);}
    }
    
    public void beforeUpdate(List<SObject> newList, Map<Id, SObject> newItems,List<SObject> oldList, Map<Id, SObject> oldItems){
        Map<Id, Apttus__APTS_Agreement__c> aggrMap = new Map<Id, Apttus__APTS_Agreement__c>();
        Integer TempContractTerm;
        Date TempLastmodifieddate;
        Date TempCreateddate;
        Map<ID,Schema.RecordTypeInfo> RecMap = Apttus__APTS_Agreement__c.sObjectType.getDescribe().getRecordTypeInfosById();
        try
        {
        //Recursive Check
            if(!APTS_CheckRecursive.processedSet.contains('APTS_DefaultAgreementDatesBeforeUpdate')){
                APTS_CheckRecursive.processedSet.add('APTS_DefaultAgreementDatesBeforeUpdate');
                for(Apttus__APTS_Agreement__c aggr : (List<Apttus__APTS_Agreement__c>)newList)
                {
                    DateTime dT = aggr.lastmodifieddate;
                    TempLastmodifieddate= date.newinstance(dT.year(), dT.month(), dT.day());
                    //Added by CPQ_rQTC-Contract basics-007
                    Apttus__APTS_Agreement__c OldAgre=(Apttus__APTS_Agreement__c)Trigger.oldMap.get(aggr.ID);
                    if(aggr.Apttus__Status_Category__c!=OldAgre.Apttus__Status_Category__c&&aggr.Apttus__Status_Category__c=='In Signatures'&&aggr.Apttus__Version_Number__c==0){
                        aggr.APTS_Agreement_Proposal_Valid_Date__c=TempLastmodifieddate.adddays(30);
                    }
                    //Added by shahul-DFT2C-930
                    DateTime dT1 = aggr.createddate;
                    Tempcreateddate= date.newinstance(dT1.year(), dT1.month(), dT1.day());
                    if(aggr.Apttus__Status__c=='Request'&&aggr.Apttus__Status_Category__c=='Request'&&aggr.Apttus__Version_Number__c>0){
                        aggr.APTS_Agreement_Proposal_Valid_Date__c=Tempcreateddate.adddays(30);
                    }
                    
                    if(aggr.Apttus__Subtype__c=='Default' && aggr.APTS_Migration_Date__c == null){
                       aggr.Apttus__Subtype__c=REGULAR;
                    }
                    TempContractTerm=Integer.valueof(aggr.APTS_Agreement_Duration_Months__c);
                    
                    if(aggr.Apttus__Contract_Start_Date__c!= null && TempContractTerm!= NULL && aggr.Apttus__Subtype__c != 'Fixed End Date' && aggr.APTS_Migration_Date__c == null){ // Lavanya - to check with Shahul 
                        aggr.Apttus__Contract_End_Date__c=aggr.Apttus__Contract_Start_Date__c.addmonths(TempContractTerm).adddays(-1);
                        
                    }
                    
                    if(aggr.APTS_Migration_Date__c == null && aggr.Apttus__Contract_Start_Date__c!= null && aggr.Apttus__Contract_End_Date__c!= NULL && aggr.Apttus__Subtype__c == 'Fixed End Date'){ // Lavanya - to check with Shahul
                        //APTS_DaysByCalendarMonthAVG__c instDayByCalendar =  APTS_DaysByCalendarMonthAVG__c.getValues('Decimal2'); 
                        //aggr.APTS_Agreement_Duration_Months__c=((aggr.Apttus__Contract_Start_Date__c.daysbetween(aggr.Apttus__Contract_End_Date__c)+1)/instDayByCalendar.DivideBy__c).setScale(2, RoundingMode.HALF_UP); // Derived from 365/12
                        Date sd = aggr.Apttus__Contract_Start_Date__c;
                        date ed = aggr.Apttus__Contract_End_Date__c;
                        aggr.APTS_Agreement_Duration_Months__c=Apttus_Config2.CPQWebService.computeTerm(sd,ed,'Monthly');
                    }
                    
                    //BEG: Added by Juhi Rawal (Apttus) for flexibility rules on 7th March,2018.
                    if(RecMap.get(aggr.recordTypeID).getName().containsIgnoreCase(Consumption)){
                        aggr.APTS_Unlimited_Machine_Ordering__c=true;
                    }
                    
                    
                    /**for(Apttus__APTS_Agreement__c aggrOld : (List<Apttus__APTS_Agreement__c>)oldList)
                    {
                        //  if(aggrOld.Apttus__Contract_End_Date__c != aggr.Apttus__Contract_End_Date__c)
                        //  aggr.Apttus__Contract_End_Date__c = aggrOld.Apttus__Contract_End_Date__c;
                    }**/
                    
                }
            }
        }
        catch(Exception e){APTS_CustomLogging.createErrorLog(e.getTypeName(), 'Apex', e.getStackTraceString() ,'Agreement',null,'CPQ',false,false,'cpqerror@accenture.com',true);}
        
    }
    
    public void BeforeDelete(List<SObject> oldList, Map<Id, SObject> oldItems){}
    
    public void AfterInsert(List<SObject> newList, Map<Id, SObject> newItems){}
    
    public void AfterUpdate(List<SObject> newList, Map<Id, SObject> newItems, List<SObject> oldList, Map<Id, SObject> oldItems){}
    
    public void AfterDelete(List<SObject> oldList, Map<Id, SObject> oldItems){}
    
    public void AfterUndelete(List<SObject> newList, Map<Id, SObject> newItems){}
    
    public Boolean isDisabled() {
        return triggerDisabled;
    }  

}