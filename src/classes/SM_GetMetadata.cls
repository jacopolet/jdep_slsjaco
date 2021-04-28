//-------------------------------------------------------------------------------------------//
// Author       :   Glenn Serrano - Accenture
// Created Date :   November 14, 2019
// Usage        :   
//
//-------------------------------------------------------------------------------------------//
public without sharing class SM_GetMetadata {
    //Retrieve Postal Box Rule values from Postal_Box_Rule__mdt
    public static Map<String, Decimal> getpostalBoxRule() {
        List<Postal_Box_Rule__mdt> pbRule = [Select DeveloperName, Rule__c from Postal_Box_Rule__mdt];
        Map <String, Decimal> postalBoxRule = new Map<String, Decimal>();
        if (!pbRule.isEmpty()){
            for (Postal_Box_Rule__mdt rule : pbRule){
                postalBoxRule.put(rule.DeveloperName, rule.Rule__c);
            }
        }
        
        return postalBoxRule;
    }
    //Retrieve Postal Box length values from Postal_Box_Length__mdt
    public static Map<String, Decimal> getpostalBoxLength() {
        List<Postal_Box_Length__mdt> pbLength = [Select DeveloperName, Length__c from Postal_Box_Length__mdt];
        Map <String, Decimal> postalBoxLegnth = new Map<String, Decimal>();
        if (!pbLength.isEmpty()){
            for (Postal_Box_Length__mdt length : pbLength){
                postalBoxLegnth.put(length.DeveloperName, length.Length__c);
            }
        }
        
        return postalBoxLegnth;
    }
    //Retrieve VAT Rule values from VAT_Rule__mdt
    public static Map<String, Decimal> vatRule() {
        List<VAT_Rule__mdt> vatRules = [Select DeveloperName, Rule__c from VAT_Rule__mdt];
        Map <String, Decimal> vatRulehMap = new Map<String, Decimal>();
        if (!vatRules.isEmpty()){
            for (VAT_Rule__mdt vatRule : vatRules){
                vatRulehMap.put(vatRule.DeveloperName, vatRule.Rule__c);
            }
        }
        
        return vatRulehMap;
    }
    //Retrieve VAT Length values from VAT_Length__mdt
    public static Map<String, Decimal> vatLength() {
        List<VAT_Length__mdt> vatLengths = [Select DeveloperName, Length__c from VAT_Length__mdt];
        Map <String, Decimal> vatLengthMap = new Map<String, Decimal>();
        if (!vatLengths.isEmpty()){
            for (VAT_Length__mdt vatLength : vatLengths){
                vatLengthMap.put(vatLength.DeveloperName, vatLength.Length__c);
            }
        }
        
        return vatLengthMap;
    }
    
    //Retrieve Call_List_Day_Counter__mdt sales orgnizations
    public static Set<String> getconditionforquerycalllistday() {
        List<Call_List_Day_Counter__mdt> salesorganizationsinmdt = [Select Label from Call_List_Day_Counter__mdt];
        Set<String> salesorganizations = new Set<String>();
        if (!salesorganizationsinmdt.isEmpty()){
            for (Call_List_Day_Counter__mdt cldcrec : salesorganizationsinmdt){
                salesorganizations.add(cldcrec.Label);
            }
        }
        
        return salesorganizations;
    }
    
    //Retrieve Call_List_Day_Counter__mdt records
    public static Map<String, Call_List_Day_Counter__mdt> getcalllistmdtrecords() {
        List<Call_List_Day_Counter__mdt> cldslist = [Select Label, Counter__c, Queue__c, User_ID__c from Call_List_Day_Counter__mdt];
        Map<String, Call_List_Day_Counter__mdt> cldsmap = new Map<String, Call_List_Day_Counter__mdt>();
        if (!cldslist.isEmpty()){
            for (Call_List_Day_Counter__mdt cldcrec : cldslist){
                cldsmap.put(cldcrec.Label, cldcrec);
            }
        }
        
        return cldsmap;
    }
    
    //Retrieve Country_Code__c records
    public static Map<String, String> getcountrycodemdtrecords() {
        List<Country_code__mdt> countrycodelist = [Select Label, Country_Code__c from Country_code__mdt];
        Map<String, String> countrycodemap = new Map<String, String>();
        if (!countrycodelist.isEmpty()){
            for (Country_code__mdt cldcrec : countrycodelist){
                countrycodemap.put(cldcrec.Label, cldcrec.Country_Code__c);
            }
        }
        
        return countrycodemap;
    }
    
    //Retrieve Queue_Lead_Tasks__mdt records
    public static Map<String, Queue_Lead_Tasks__mdt> getqueueleadtasks() {
        List<Queue_Lead_Tasks__mdt> queueleadlist = [Select Label, Touchpoint_Type__c, Sales_Organization__c, Queue_for_Task_Record__c, Queue_for_Lead__c, MQL_Campaign_ID__c, 
                                                     Gate_Keeper__c, Create_Task_from_Form_API__c, Chatter_Group_ID__c, Queue_for_Case__c, Queue_for_Case_Name__c from Queue_Lead_Tasks__mdt];
        Map<String, Queue_Lead_Tasks__mdt> queueleadmap = new Map<String, Queue_Lead_Tasks__mdt>();
        String qltreckey = '';
        if (!queueleadlist.isEmpty()){
            for (Queue_Lead_Tasks__mdt qltrec : queueleadlist){
                qltreckey = qltrec.Sales_Organization__c + qltrec.Touchpoint_Type__c;
                queueleadmap.put(qltreckey, qltrec);
            }
        }
        
        return queueleadmap;
    }
    
    //Retrieve Sales Organization Settings records
    public static Map<String, String> getsalesorgdoisoi() {
        List<APTS_SalesOrg_Settings__mdt> salesorglist = [Select Label, DOI_SOI__c, Sales_Organization__c from APTS_SalesOrg_Settings__mdt];
        Map<String, String> salesorgmap = new Map<String, String>();
        if (!salesorglist.isEmpty()){
            for (APTS_SalesOrg_Settings__mdt salesorgval : salesorglist){
                salesorgmap.put(salesorgval.Sales_Organization__c, salesorgval.DOI_SOI__c);
            }
        }
        
        return salesorgmap;
    }

    //Retrieve Sales Organization Campaign records
    public static Map<String, String> getcampaignfromcmdt() {
        List<SM_FormAPICampaign__mdt> formapicampaign = [Select Campaign_Id__c, Lead_Source__c, Sales_Organization__c from SM_FormAPICampaign__mdt];
        Map<String, String> campaignmap = new Map<String, String>();
        if (!formapicampaign.isEmpty()){
            for (SM_FormAPICampaign__mdt cmdtcampaignval : formapicampaign){
                campaignmap.put(cmdtcampaignval.Sales_Organization__c + cmdtcampaignval.Lead_Source__c, cmdtcampaignval.Campaign_Id__c);
            }
        }
        
        return campaignmap;
    }
    
    //Retrieve Pre populated One-Time NOS Opportunity records
    public static Map<String, Decimal> getonetimenosval() {
        List<Populate_One_Time_NOS__mdt> prepopulatedonetimenos = [Select Label, One_Time_NOS_prepopulated_value__c from Populate_One_Time_NOS__mdt];
        Map<String, Decimal> prepoponetimenosmap = new Map<String, Decimal>();
        if (!prepopulatedonetimenos.isEmpty()){
            for (Populate_One_Time_NOS__mdt prepoponetimenosval : prepopulatedonetimenos){
                prepoponetimenosmap.put(prepoponetimenosval.Label, prepoponetimenosval.One_Time_NOS_prepopulated_value__c);
            }
        }
        
        return prepoponetimenosmap;
    }

    //Retrieve Internal Assignment
    public static Map<String, String> getInternalAssigment() {
        List<Internal_Assignment__mdt> internalAssignment = [Select DeveloperName, Owner_Id__c from Internal_Assignment__mdt];
        Map<String, String> internalAssignMap = new Map<String, String>();
        if (!internalAssignment.isEmpty()){
            for (Internal_Assignment__mdt iA : internalAssignment){
                internalAssignMap.put(iA.DeveloperName, iA.Owner_Id__c);
            }
        }
        
        return internalAssignMap;

    }
    
    //Retrieve Sales Organization Settingsm archive account records
    public static Map<String, String> getsalesorgarchiveaccount() {
        List<APTS_SalesOrg_Settings__mdt> salesorglist = [Select Label, ArchiveAccountID__c, Sales_Organization__c from APTS_SalesOrg_Settings__mdt];
        Map<String, String> salesorgmap = new Map<String, String>();
        if (!salesorglist.isEmpty()){
            for (APTS_SalesOrg_Settings__mdt salesorgval : salesorglist){
                salesorgmap.put(salesorgval.Sales_Organization__c, salesorgval.ArchiveAccountID__c);
            }
        }
        
        return salesorgmap;
    }
    
    //Retrieve Sales Organization Settingsm records
    public static Map<String, APTS_SalesOrg_Settings__mdt> getsalesorgmetadatarec() {
        List<APTS_SalesOrg_Settings__mdt> salesorglist = [Select Label, Show_NBA__c, Sales_Organization__c from APTS_SalesOrg_Settings__mdt];
        Map<String, APTS_SalesOrg_Settings__mdt> salesorgmap = new Map<String, APTS_SalesOrg_Settings__mdt>();
        if (!salesorglist.isEmpty()){
            for (APTS_SalesOrg_Settings__mdt salesorgval : salesorglist){
                salesorgmap.put(salesorgval.Sales_Organization__c, salesorgval);
            }
        }
        
        return salesorgmap;
    }
    
    //Retrieve Machine Park Validation Records
    //public static Map<String, Machine_Park_Validation__mdt> getmachineparkvalidationmarketcriteria() {
    //    List<Machine_Park_Validation__mdt> machineparklist = [Select Segment__c, Subsegment__c, Show_NBA__c, LastContactDateCriteria__c, LastServiceDateCriteria__c from Machine_Park_Validation__mdt];
    //    Map<String, Machine_Park_Validation__mdt> machineparkrecmap = new Map<String, Machine_Park_Validation__mdt>();
    //   if (!machineparklist.isEmpty()){
    //        for (Machine_Park_Validation__mdt machineparkval : machineparklist){
    //            machineparkrecmap.put(machineparkval.Segment__c + machineparkval.Subsegment__c, machineparkval);
    //        }
    //    }
    //    
    //    return machineparkrecmap;
    //}
}