/**********************************************************************************
 * @Author: Juhi Rawal
 * @Company: Apttus
 * @Description: Controller for APTS_AgreementApprovalEmail Component
 * @Created Date: June 7, 2018
 * @History:
 *      <Name>              <Date>          <Description>
 *      juhi.rawal      6.07.2018           Created
 *      jason.e.mactal  8.01.2018           Added methods to handle fetching of Billing Setting and Incentive Records
 *      jason.e.mactal  11.20.2018          Added listMainBundleLines, and with sharing access modifer
 **********************************************************************************/
public with sharing class APTS_AgreementApprovalEmailCtrl{
    public Id agreementId;   
    public String approvalType{get; set;} 
    public List<Apttus__AgreementLineItem__c> listAgreementLineItems{get;set;}
    public List<Apttus__AgreementLineItem__c> listTrialALI{get;set;}
    public List<Apttus__AgreementLineItem__c> listMainBundleLines{get;set;}

    public Id getagreementId(){ return agreementId;}
    
    /*@methodName - setagreementId
    * @description - set agreementId
    * @author - Juhi Rawal
    * @param - Id
    * @return - void
    */  
    public void setagreementId(Id idAgr){
        agreementId = idAgr;
        agreementLineItems();
    }
    
    /*@methodName - agreementLineItems
    * @description - get Agreement Line Items
    * @author - Juhi Rawal
    * @param - void
    * @return - void
    */ 
    public void agreementLineItems(){
        try{
            listTrialALI = new List<Apttus__AgreementLineItem__c>();
            listMainBundleLines = new List<Apttus__AgreementLineItem__c>();
            listAgreementLineItems = [select id,name,Apttus__ProductId__r.Name,Apttus__Quantity__c,APTS_Type_of_Contract__c,Apttus_CMConfig__ClassificationHierarchy__c,
                                        Apttus__AgreementId__r.Apttus__Account__r.Name,Apttus__ProductId__r.Family,Apttus_CMConfig__DerivedFromId__r.Apttus_Config2__AttributeValueId__r.APTS_Number_of_weeks__c,
                                        Apttus_CMConfig__IsPrimaryLine__c, Apttus_CMConfig__HasOptions__c, Apttus_CMConfig__DerivedFromId__r.Category_Group__c
                                        from Apttus__AgreementLineItem__c
                                        where Apttus__AgreementId__c=: AgreementId];
            System.debug(' listAgreementLineItems;====> ' + listAgreementLineItems);
            for(Apttus__AgreementLineItem__c oALI : listAgreementLineItems){
                if(oALI.APTS_Type_of_Contract__c == 'Trial' && oALI.Apttus_CMConfig__IsPrimaryLine__c == TRUE && oALI.Apttus_CMConfig__HasOptions__c == TRUE){
                    listTrialALI.add(oALI);
                }
                if(oALI.Apttus_CMConfig__IsPrimaryLine__c == TRUE && oALI.Apttus_CMConfig__HasOptions__c == TRUE){
                    listMainBundleLines.add(oALI);
                }
            }
        } catch(Exception e){APTS_CustomLogging.createErrorLog(e.getTypeName(), 'Apex', e.getStackTraceString() ,'APTS_AgreementApprovalEmailCtrl','','CPQ',false,true,'cpqerror@accenture.com',true);             } 
    } 
    
    /*@methodName - getagreementDetails
    * @description - get Agreement fields
    * @author - Juhi Rawal
    * @param - void
    * @return - Apttus__APTS_Agreement__c
    */ 
    public Apttus__APTS_Agreement__c  getagreementDetails(){
        Apttus__APTS_Agreement__c oAgr = [select Apttus__Account__r.Name, APTS_NetSalesValue__c,APTS_ROS__c, Apttus__Account__r.Creditworthiness_Flag__c,Apttus__Contract_Start_Date__c,
                                            Apttus__Contract_End_Date__c,APTS_Preferred_way_of_ingredient_orderi__c, APTS_Non_Standard_Deal_Payment_Terms__c, APTS_Non_Standard_Deal_Fixed_Term__c,
                                            APTS_Non_Standard_Deal_Fixed_End_Date__c, APTS_Non_Standard_Deal_Indexation__c, APTS_Non_Standard_Deal_Payment_Method__c, APTS_Non_Standard_Deal_Billing_Arrears__c,
                                            APTS_Non_Standard_Deal_Trial__c, APTS_Payment_Term_Value_1__c, APTS_Payment_Term_Value_2__c, APTS_Number_of_Drinks_per_year__c, APTS_NSV__c, CurrencyIsoCode
                                            from Apttus__APTS_Agreement__c 
                                            where Id =: agreementId];
        return oAgr;
    }
    
    /*@methodName - getbShowIngredient
    * @description - checks whether ingredients should be showed
    * @author - Juhi Rawal
    * @param - void
    * @return - Boolean
    */ 
    public Boolean getbShowIngredient(){
        Boolean bShowIngredient = false;
        for(Apttus__AgreementLineItem__c oALI : listAgreementLineItems){
            if(oALI.Apttus__ProductId__r.Family == 'SAP_01' || oALI.Apttus__ProductId__r.Family == 'SAP_02' || oALI.Apttus__ProductId__r.Family == 'SAP_03'){
                bShowIngredient = true;
                break;
            }
        }
        return bShowIngredient;
    }
    
    /*@methodName - getIngredientCategory
    * @description - get Ingredient's Category|Sub-Category|SubSubCategory
    * @author - Jason Mactal
    * @param - void
    * @return - Boolean
    */ 
    public string getIngredientCategory(){
        string ingCategory = '';
        try{
            for(Apttus__AgreementLineItem__c oALI : listAgreementLineItems){
                if((oALI.Apttus__ProductId__r.Family == 'SAP_01' || oALI.Apttus__ProductId__r.Family == 'SAP_02' || oALI.Apttus__ProductId__r.Family == 'SAP_03') && !ingCategory.contains(oALi.Apttus_CMConfig__DerivedFromId__r.Category_Group__c)){
                    boolean isNotBlank = ingCategory.length()!=0? true: false;
                    ingCategory += isNotBlank? ', ': '';
                    ingCategory += oALi.Apttus_CMConfig__DerivedFromId__r.Category_Group__c;
                }
            }
        } catch(Exception e){APTS_CustomLogging.createErrorLog(e.getTypeName(), 'Apex', e.getStackTraceString() ,'APTS_AgreementApprovalEmailCtrl','','CPQ',false,true,'cpqerror@accenture.com',true); return null; } 
        return ingCategory;
    }
    
    /*@methodName - getKPIRecord
    * @description - get KPI/SLA Records
    * @author - Juhi Rawal
    * @param - void
    * @return - List<Contracted_kpi_sla__c>
    */ 
    public List<Contracted_kpi_sla__c> getKPIRecord(){
        List<Contracted_kpi_sla__c> listKpiRecords = [select kpi_type_value__c from Contracted_kpi_sla__c where kpi_contract__c =: agreementId];
        return listKpiRecords;
    }

    /*@methodName - getBillingSettingsRecords
    * @description - getBillingSettingsRecords
    * @author - Jason Mactal
    * @param - void
    * @return - string
    */ 
    public string getPaymentMethods(){
        string paymentMethodName = '';
        try{
            Set<String> setSAPIds = new Set<String> {'SAP_02024','SAP_0202D','SAP_0202I','SAP_0067D','SAP_01546','SAP_0154J','SAP_0154Q','SAP_6706Q','SAP_6750D','SAP_00794','SAP_0079D','SAP_0079E','SAP_0079H','SAP_0079I','SAP_0160D'};
            List<APTS_Billing_Settings__c> billingSettingsList = [select APTS_Payment_Term_Setting__r.Apttus_Config2__Value__c, APTS_Payment_Method__r.APTS_Ext_ID__c, APTS_Payment_Method__r.Name from APTS_Billing_Settings__c where APTS_Agreement_ID__c =: agreementId];
            
            for(APTS_Billing_Settings__c billSet: billingSettingsList){
                //get Payment Methods that Triggered Approval
                if(setSAPIds.contains(billSet.APTS_Payment_Method__r.APTS_Ext_ID__c) && !paymentMethodName.contains(billSet.APTS_Payment_Method__r.Name)){
                    boolean isNotBlank = paymentMethodName.length()!=0? true: false;
                    paymentMethodName += isNotBlank? ', ': '';
                    paymentMethodName += billSet.APTS_Payment_Method__r.Name;
                }
            }
        } catch(Exception e){APTS_CustomLogging.createErrorLog(e.getTypeName(), 'Apex', e.getStackTraceString() ,'APTS_AgreementApprovalEmailCtrl','','CPQ',false,true,'cpqerror@accenture.com',true); return null; } 
        return paymentMethodName;
    }
    
    /*@methodName - getWithIncentives
    * @description - check if Agreement has Incentives
    * @author - Jason Mactal
    * @param - void
    * @return - boolean
    */ 
    public boolean getWithIncentives(){
        boolean withIncentives = FALSE;
        try{
            List<Apttus_Config2__Incentive__c> incentivesList = [select id from Apttus_Config2__Incentive__c where Apttus_CMConfig__AgreementId__c =: agreementId];
            
            if(incentivesList!=null && incentivesList.size()!=0){
                withIncentives = TRUE;
            }
        } catch(Exception e){APTS_CustomLogging.createErrorLog(e.getTypeName(), 'Apex', e.getStackTraceString() ,'APTS_AgreementApprovalEmailCtrl','','CPQ',false,true,'cpqerror@accenture.com',true); return null;} 
        return withIncentives;
    }
}