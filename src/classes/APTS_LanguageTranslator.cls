/**************************************************************
 * @Author: Pranjal Mittal
 * @Description: 
 * @Created Date: 18-July-2018
 * @Revisions:
 *      <Name>              <Date>          <Description>
 *      Pranjal Mittal      18-July-2018     Initial Version
 * 
 *************************************************************/
public with sharing class APTS_LanguageTranslator{

  private static final String ALI = 'Apttus__AgreementLineItem__c';
  private static final String BUDGET = 'APTS_Agreement_Budget__c';
  private static final String INDEX = 'APTS_Index_Contract__c';
  private static final String KPISLA = 'Contracted_kpi_sla__c';
  private static final String BILLING_SETTING = 'APTS_Billing_Settings__c';
  private static final String AGREEMENT = 'Apttus__APTS_Agreement__c';
  private static final String REBATE = 'APTS_RebateDefiniation__c';
  private static final String ATVO = 'APTS_AgreementTotalVolumeObligation__c';
  private static final String BILLING_PREFERENCE = 'Apttus_Config2__BillingPreference__c';
  
  public static void translateLanguage(List<sObject> newList, String apiObject, List<String> lstLanguage){
    //Map containing <Orignal Text, Translated Text>
    Map<String, String> mapTranslation = new Map<String, String>();
    try {
        for(APTS_Language_Translation__c tmpLT: [SELECT Id, APTS_Original_Text__c, APTS_Language__c, APTS_Translated_Text__c
                              FROM APTS_Language_Translation__c WHERE APTS_Language__c IN :lstLanguage]){
          mapTranslation.put(tmpLT.APTS_Original_Text__c.toLowerCase() + tmpLT.APTS_Language__c.toLowerCase(), tmpLT.APTS_Translated_Text__c);
        }

        //Processing Agreement Line Item
        if(mapTranslation.keySet().size() > 0 && apiObject.equalsIgnoreCase(ALI)){
          Map<Id, String> mapAggrLangugage = new Map<Id, String>();
          Set<Id> setAgreementIds = new Set<Id>();
              
              for(Apttus__AgreementLineItem__c tmp : (List<Apttus__AgreementLineItem__c>) newList){
                  setAgreementIds.add(tmp.Apttus__AgreementId__c);
              }

              for(Apttus__APTS_Agreement__c tmpAggr : [SELECT Id, APTS_Language__c FROM Apttus__APTS_Agreement__c WHERE Id IN: setAgreementIds]){
                mapAggrLangugage.put(tmpAggr.Id, tmpAggr.APTS_Language__c);
              }

          //Map containing mapping of fields that needs to translated for Apttus__AgreementLineItem__c object
          Map<String, String> mapALIFields = new Map<String, String>();
          mapALIFields.put('Apttus_CMConfig__AdjustmentType__c', 'APTS_Adjustment_Type_Translated__c');
          mapALIFields.put('Apttus_CMConfig__ChargeType__c', 'APTS_Charge_Type_Translated__c');
          mapALIFields.put('Apttus_CMConfig__Frequency__c', 'APTS_Pricing_Frequency_Translated__c');
          mapALIFields.put('Apttus_Config2_SellingUom__c', 'APTS_Selling_Uom_Translated__c');

          Map<String, String> apiToLabel = getAPItoLabel(ALI, mapALIFields);

          for(Apttus__AgreementLineItem__c tmp : (List<Apttus__AgreementLineItem__c>) newList){
            for(String tmpStr : mapALIFields.keySet()){
              String translatedText =  apiToLabel.get((String) tmp.get(tmpStr)) + mapAggrLangugage.get(tmp.Apttus__AgreementId__c);
              tmp.put(mapALIFields.get(tmpStr), mapTranslation.get(translatedText.toLowerCase()));
            }
          }

          Map<String, String> mapALIFieldsNonPicklist = new Map<String, String>();
          mapALIFieldsNonPicklist.put('APTS_Type_of_Contract__c', 'APTS_Type_of_Contract_Translated__c'); //Text(100)
          mapALIFieldsNonPicklist.put('APTS_Contact_Customer_Before_Delivery__c', 'APTS_Contact_Cust_Before_Delivery_Trans__c'); //Text(5)  

          for(Apttus__AgreementLineItem__c tmp : (List<Apttus__AgreementLineItem__c>) newList){
            for(String tmpStr : mapALIFieldsNonPicklist.keySet()){
              String translatedText =  (String) tmp.get(tmpStr) + mapAggrLangugage.get(tmp.Apttus__AgreementId__c);
              tmp.put(mapALIFieldsNonPicklist.get(tmpStr), mapTranslation.get(translatedText.toLowerCase()));
            }
          }
        }

        //Processing APTS_Agreement_Budget__c
        if(mapTranslation.keySet().size() > 0 && apiObject.equalsIgnoreCase(BUDGET)){
          //Map containing mapping of fields that needs to translated for APTS_Agreement_Budget__c object
          Map<String, String> mapBudgetFields = new Map<String, String>();
          mapBudgetFields.put('APTS_Category__c', 'APTS_Category_Translated__c');
          mapBudgetFields.put('APTS_Subcategory__c', 'APTS_Sub_Category_Translated__c');

          Map<String, String> apiToLabel = getAPItoLabel(BUDGET, mapBudgetFields);

          for(APTS_Agreement_Budget__c tmp : (List<APTS_Agreement_Budget__c>) newList){
            for(String tmpStr : mapBudgetFields.keySet()){
              String translatedText = apiToLabel.get((String) tmp.get(tmpStr)) + tmp.APTS_Agreement_Language__c;
              tmp.put(mapBudgetFields.get(tmpStr), mapTranslation.get(translatedText.toLowerCase()));
            }
          }
        }

        //Processing APTS_Index_Contract__c
        if(mapTranslation.keySet().size() > 0 && apiObject.equalsIgnoreCase(INDEX)){
          //Map containing mapping of fields that needs to translated for APTS_Index_Contract__c object
          Map<String, String> mapIndexationFields = new Map<String, String>();
          mapIndexationFields.put('APTS_Indexation_Category__c', 'APTS_Index_Category_Translated__c');
          mapIndexationFields.put('APTS_Frequency__c', 'APTS_Frequency_Translated__c');
          mapIndexationFields.put('APTS_Communication_Deadline__c', 'APTS_Communication_Deadline_Translated__c');
          
          Map<String, String> apiToLabel = getAPItoLabel(INDEX, mapIndexationFields);

          mapIndexationFields.put('APTS_Customer_Approval_Required__c', 'APTS_Customer_Approval_Required_Trans__c'); //Checkbox

          for(APTS_Index_Contract__c tmp : (List<APTS_Index_Contract__c>) newList){
            for(String tmpStr : mapIndexationFields.keySet()){
              if(tmpStr.equalsIgnoreCase('APTS_Customer_Approval_Required__c')){
                if(tmp.get(tmpStr) == true){
                  String translatedText = 'Yes' + tmp.APTS_Agreement_Language__c;
                  tmp.put(mapIndexationFields.get(tmpStr), mapTranslation.get(translatedText.toLowerCase()));
                  continue;
                }
                else{
                  String translatedText = 'No' + tmp.APTS_Agreement_Language__c;
                  tmp.put(mapIndexationFields.get(tmpStr), mapTranslation.get(translatedText.toLowerCase()));
                  continue;
                }
              }
              String translatedText = apiToLabel.get((String) tmp.get(tmpStr)) + tmp.APTS_Agreement_Language__c;
              tmp.put(mapIndexationFields.get(tmpStr), mapTranslation.get(translatedText.toLowerCase()));
            }
          }
        }

        //Processing Contracted_kpi_sla__c
        if(mapTranslation.keySet().size() > 0 && apiObject.equalsIgnoreCase(KPISLA)){
          Map<String, String> mapKPISLAFields = new Map<String, String>();
          mapKPISLAFields.put('kpi_frequency__c', 'APTS_KPI_or_SLA_Frequency_Translated__c');
          
          Map<String, String> apiToLabel = getAPItoLabel(KPISLA, mapKPISLAFields);

          for(Contracted_kpi_sla__c tmp : (List<Contracted_kpi_sla__c>) newList){
            for(String tmpStr : mapKPISLAFields.keySet()){
              String translatedText = apiToLabel.get((String) tmp.get(tmpStr)) + tmp.APTS_Agreement_Language__c;
              tmp.put(mapKPISLAFields.get(tmpStr), mapTranslation.get(translatedText.toLowerCase()));
            }
          }
        }

        //Processing APTS_Billing_Settings__c
        if(mapTranslation.keySet().size() > 0 && apiObject.equalsIgnoreCase(BILLING_SETTING)){
          Map<String, String> mapBillingFields = new Map<String, String>();
          mapBillingFields.put('APTS_Billing_Interval__c', 'APTS_Billing_Interval_Translated__c');
          mapBillingFields.put('APTS_Billing_Cycle_Start__c', 'APTS_Billing_Cycle_Start_Translated__c');
          mapBillingFields.put('APTS_Billing_Day_Of_Month__c', 'APTS_Billing_Day_Of_Month_Translated__c');
          mapBillingFields.put('APTS_Billing_Rule_Contract__c', 'APTS_Billing_Rule_Translated__c');
          mapBillingFields.put('APTS_Ingredient_Billing_Cycle_Start__c', 'APTS_Ingredient_Bill_Cycle_Start_Trans__c');
          mapBillingFields.put('APTS_Ingredient_Billing_Day_Of_Month__c', 'APTS_Ingredient_Bill_Day_Of_Month_Trans__c');
          mapBillingFields.put('APTS_Ingredient_Billing_Interval__c', 'APTS_Ingredient_Bill_Interval_Translated__c');     
          
          Map<String, String> apiToLabel = getAPItoLabel(BILLING_SETTING, mapBillingFields);

          for(APTS_Billing_Settings__c tmp : (List<APTS_Billing_Settings__c>) newList){
            for(String tmpStr : mapBillingFields.keySet()){
              String translatedText = (String) tmp.get(tmpStr) + tmp.APTS_Agreement_Language__c;
              tmp.put(mapBillingFields.get(tmpStr), mapTranslation.get(translatedText.toLowerCase()));
            }
          }
        }

        //Processing Apttus__APTS_Agreement__c
        if(mapTranslation.keySet().size() > 0 && apiObject.equalsIgnoreCase(AGREEMENT)){
          Map<String, String> mapAgreementFields = new Map<String, String>();
          mapAgreementFields.put('APTS_Fixed_Term_Frequency__c', 'APTS_Fixed_Term_Settlement_Freq_Trans__c');

          for(Apttus__APTS_Agreement__c tmp : (List<Apttus__APTS_Agreement__c>) newList){
            for(String tmpStr : mapAgreementFields.keySet()){
              String translatedText = (String) tmp.get(tmpStr) + tmp.APTS_Language__c;
              tmp.put(mapAgreementFields.get(tmpStr), mapTranslation.get(translatedText.toLowerCase()));
            }
          }
        }

        //Processing APTS_RebateDefiniation__c
        if(mapTranslation.keySet().size() > 0 && apiObject.equalsIgnoreCase(REBATE)){
          Map<String, String> mapRebateFields = new Map<String, String>();
          mapRebateFields.put('APTS_BenefitUOM__c', 'APTS_Benefit_UOM_Translated__c');
          mapRebateFields.put('APTS_PayoutFrequency__c', 'APTS_Payout_Frequency_Translated__c');

          Map<String, String> apiToLabel = getAPItoLabel(REBATE, mapRebateFields);
          
          for(APTS_RebateDefiniation__c tmp : (List<APTS_RebateDefiniation__c>) newList){
            for(String tmpStr : mapRebateFields.keySet()){
              String translatedText = apiToLabel.get((String) tmp.get(tmpStr)) + tmp.APTS_Agreement_Language__c;
              tmp.put(mapRebateFields.get(tmpStr), mapTranslation.get(translatedText.toLowerCase()));
            }
          }
        }
        //Processing APTS_AgreementTotalVolumeObligation__c
        if(mapTranslation.keySet().size() > 0 && apiObject.equalsIgnoreCase(ATVO)){
          Map<String, String> mapATVOFields = new Map<String, String>();
          mapATVOFields.put('APTS_Unit_of_Measure__c', 'APTS_Unit_of_Measure_Translated__c');
          
          Map<String, String> apiToLabel = getAPItoLabel(ATVO, mapATVOFields);

          for(APTS_AgreementTotalVolumeObligation__c tmp : (List<APTS_AgreementTotalVolumeObligation__c>) newList){
            for(String tmpStr : mapATVOFields.keySet()){
              String translatedText = apiToLabel.get((String) tmp.get(tmpStr)) + tmp.APTS_Agreement_Language__c;
              tmp.put(mapATVOFields.get(tmpStr), mapTranslation.get(translatedText.toLowerCase()));
            }
          }
        }
    } catch (Exception ex) {APTS_CustomLogging.createErrorLog(ex.getTypeName(), 'Apex', ex.getStackTraceString() , 'translateLanguage', null, 'CLM', false, false, null, true);}
  }

  //Method to create a map of <API name, Label> of picklist values
  public static Map<String, String> getAPItoLabel(String apiObject, Map<String, String> mapFields){
    DescribeSObjectResult objResult = Schema.getGlobalDescribe().get(apiObject).getDescribe();
    Map<String,String> apiToLabel = new Map<String,String>();
    try {
        for(String tmpStr : mapFields.keySet()){
        if(objResult.fields.getMap().containsKey(tmpStr) && objResult.fields.getMap().get(tmpStr) != null && objResult.fields.getMap().get(tmpStr).getDescribe() != null){
          list<Schema.PicklistEntry> PicklistEntries = objResult.fields.getMap().get(tmpStr).getDescribe().getPicklistValues(); 
          for (Schema.PicklistEntry pe : PicklistEntries){
              apiToLabel.put(pe.getValue(), pe.getLabel());
          }
        }
        }
    } catch (Exception ex) {APTS_CustomLogging.createErrorLog(ex.getTypeName(), 'Apex', ex.getStackTraceString() , 'getAPItoLabel', null, 'CLM', false, false, null, true);}
    return apiToLabel;
  }
}