/*************************************************************
@Name: APTS_OptionFilterCallback
@Author: Karan Khatri
@CreateDate: 15-10-2018
@Description: Option Filter Callback to hide options under a bundle.
******************************************************************/
global with sharing class APTS_OptionFilterCallback implements Apttus_Config2.CustomClass.IOptionFilterCallback {

    /*** Callback to return option IDs which are to be excluded from the bundle* This filter is used when we configure a bundle.* @param params is the CustomClass.ActionParams that contains bundleId and productIds* @return List of option product IDs which will be excluded*/
    private static final String REGISTRATION_FORM = 'Registration Form';
    List<String> correctionProductExclusionList = System.Label.APTS_AssetCorrectionProductsExclusion.split(',');
    Set<String> skipOrderTypeStatus = new Set<String>{'Admin Order','Credit Memo','Debit Memo'};
    Set<String> skipOrderSubTypeStatus = new Set<String>{'De-installation','Internal Movement','External Movement With Contract Change','External Movement Without Contract Change'};
    //Hiding Options based on JDE criteria
    global List<ID> getExcludedOptionIds(Apttus_Config2.CustomClass.ActionParams params) {
        List<ID> excludeOptionIdList = new List<ID>();
        if(params.ConfigurationId!=null && !params.productIDs.isEmpty()){
            List<Apttus_Config2__ProductConfiguration__c> objConfig = [SELECT Id, APTS_Flow__c,Apttus_Config2__EffectivePriceListId__r.APTS_Region__c FROM Apttus_Config2__ProductConfiguration__c 
                                                                       WHERE Id =: params.ConfigurationId 
                                                                       and ((Apttus_Config2__OrderId__c != NULL and (NOT Apttus_Config2__OrderId__r.APTS_Order_Type__c IN: skipOrderTypeStatus) and (NOT Apttus_Config2__OrderId__r.APTS_Order_Sub_Type__c IN: skipOrderSubTypeStatus)) OR
                                                                       (Apttus_CMConfig__AgreementId__c!=null and Apttus_CMConfig__AgreementId__r.RecordType.name !=: REGISTRATION_FORM))];
            if(!objConfig.isEmpty()){
                for(Product2 excludeOption : [select id,name,APTS_Associated_Sales_Org__c,ProductCode from Product2 where id IN : params.productIDs]){
                   //hide options on catalog if the Associated Sales org on the option doesnt match with Price List's region
                   if(excludeOption.APTS_Associated_Sales_Org__c==null || 
                   (excludeOption.APTS_Associated_Sales_Org__c!=null && objConfig[0].Apttus_Config2__EffectivePriceListId__c!=null && objConfig[0].Apttus_Config2__EffectivePriceListId__r.APTS_Region__c!=null && !excludeOption.APTS_Associated_Sales_Org__c.contains(objConfig[0].Apttus_Config2__EffectivePriceListId__r.APTS_Region__c)) ||
                   correctionProductExclusionList.contains(excludeOption.ProductCode)){
                        excludeOptionIdList.add(excludeOption.id);
                    }
                }
            }
        }
        return excludeOptionIdList;
    }
}