/**********************************************************************************
 * @Author: Lavanya Ravindran
 * @Company: Accenture
 * @Description: Build in progress class for new machine order ux - (Dummy Code for UI purpose ONLY)
 **********************************************************************************/


public with sharing class APTS_CreateOrderNewUXCtrl {
    
   
    @AuraEnabled
   public static Account getAccount(String recordId) {
        // Perform isAccessible() checking first, then
        return [select id,name,SAP_Customer_ID__c from Account where Id = : recordId limit 1];
    } 
   
    @AuraEnabled
    public static Apttus_Config2__Order__c getOrder(String recordId) {
        // Perform isAccessible() checking first, then
      
        return [select id,Apttus_Config2__SoldToAccountId__c,APTS_Order_Sub_Sub_Type__c, APTS_Order_Sub_Type__c, APTS_Order_Type__c,  Apttus_Config2__SoldToAccountId__r.name,Apttus_Config2__SoldToAccountId__r.SAP_Customer_ID__c from Apttus_Config2__Order__c limit 1];
    }
    
    @AuraEnabled(cacheable=true)
   public static List<APTS_Contract_Entitlement_Repository__c> getCER(String recordId) {
   
   return[Select id,
                          APTS_Charge_Type__c,
                          APTS_Product__c,

                          APTS_Product_Code__c,
                          APTS_Category_Level__c,
                          APTS_Contributing_Agreement_Level__c,
                          APTS_Sold_to_Party__r.SAP_Customer_ID__c,
                          APTS_Sold_to_Party__r.Name,
                          APTS_Agreement_Line_Item__r.Apttus_CMConfig__IsPrimaryLine__c,
                          APTS_Product__r.Name,
                          APTS_CategoryCER__c,
                          APTS_CategoryCER__r.Name,
                          APTS_Agreement_Line_Item__r.Apttus_CMConfig__PriceListItemId__r.Apttus_Config2__PriceListId__c,
                          APTS_Agreement_Line_Item__r.Apttus_CMConfig__SellingUom__c,
                          APTS_Agreement_Line_Item__r.APTS_Type_of_Contract__c,
                          APTS_Sub_Category__c,
                          APTS_Sub_Sub_Category__c,
                          APTS_Adjustment_Value__c,
                          APTS_Adjustment_Type__c,
                          APTS_Agreement_Line_Item__r.APTS_YOCI_Available_CI__c,
                          APTS_Agreement_Line_Item__r.Apttus__Quantity__c,
                          APTS_Agreement_Line_Item__r.Apttus_CMConfig__ClassificationId__c,
                          APTS_Agreement_Line_Item__r.Apttus_CMConfig__OptionId__r.APTS_Option_Group_Indicator__c,
                          APTS_Agreement_Line_Item__r.Apttus_CMConfig__LineType__c,
                          APTS_Contributing_Agreement__r.Apttus_CMConfig__PriceListId__c, APTS_Contributing_Agreement__r.Apttus_CMConfig__PriceListId__r.Apttus_Config2__BasedOnPriceListId__c,APTS_Product__r.APTS_Associated_Sales_Org__c,APTS_Sold_to_Party__r.Sales_Organization__c
                          from APTS_Contract_Entitlement_Repository__c
                          where APTS_Sold_to_Party__c = :recordId
                          and APTS_Agreement_Type__c = 'Standard Deal'
                          and APTS_Is_Pending__c = false and APTS_Agreement_Line_Item__r.Apttus_CMConfig__IsOptionRollupLine__c = false
                        /*  and APTS_Product__c != null
                          and APTS_Agreement_Line_Item__r.Apttus_CMConfig__PriceListItemId__r.Apttus_Config2__Active__c = true
                          and APTS_Agreement_Line_Item__c not in(Select APTS_Agreement_Line_Item__c from APTS_Agreement_Line_Account_Exclusion__c where APTS_Account__c = :recordId)
                          and APTS_Agreement_Adjustment_Line_Item__c not in(Select APTS_Agreement_Adjustment_Line_Item__c from APTS_Adjustment_Line_Account_Exclusion__c where APTS_Account__c = :recordId)
                          and APTS_Agreement_Line_Item__r.Apttus_CMConfig__LineType__c = 'Product/Service'
                          and(APTS_Agreement_Line_Item__r.APTS_Bundle_Option__c = true or APTS_Agreement_Line_Item__r.APTS_Ingredient_Standalone__c = true or
                              APTS_Agreement_Line_Item__r.APTS_More_Standalone__c = true or
                              APTS_Agreement_Line_Item__r.APTS_Ingredient_Bundle__c = True)
                          ORDER BY APTS_Contributing_Agreement_Level_Num__c Asc, APTS_Category_Level__c Desc*/];
   }
    
    
   @AuraEnabled(cacheable=true)
   public static List<Apttus__APTS_Agreement__c> getAgreement(String recordId) {
        // Perform isAccessible() checking first, then
        
        return [SELECT Id, Name, RecordTypeId, Apttus_CMConfig__PriceListId__c, Apttus_CMConfig__PONumber__c,
                        Apttus_CMConfig__BillingPreferenceId__c, Apttus_CMConfig__PaymentTermId__c, Apttus__Status_Category__c,
                        Apttus__Status__c, Apttus__Contract_Start_Date__c, Apttus__Contract_End_Date__c,
                        Apttus__Account__r.SAP_Customer_ID__c, Apttus__Account__r.Name, Apttus__Primary_Contact__c,
                        APTS_Language__c, APTS_Bill_to_Party_Ingredients__c, APTS_Payer_Ingredients__c, APTS_Bill_to_Party_MachServ__c,
                        APTS_Payer_Machines_Services__c, Apttus__Account__c, Apttus__Version_Number__c, APTS_Location__c, APTS_Location__r.Billing_header_text__c,
                        APTS_Location__r.Delivery_text__c,
                        //V104 ++<<
                        APTS_Location__r.Picking_list_text__c,
                        //V104 ++>>
                        //V102++>>
                        APTS_Check_on_Account_Machines__c,
                        APTS_Check_on_Account_Ingredients__c
                        //V102++<<
                        FROM Apttus__APTS_Agreement__c
                        WHERE Apttus__Account__c = : recordId AND 
                        ((Apttus__Status_Category__c = :APTS_OrderConstants.IN_EFFECT AND Apttus__Status__c = :APTS_OrderConstants.ACTIVATED) OR
                         (Apttus__Status_Category__c = :APTS_OrderConstants.IN_EFFECT AND Apttus__Status__c = :APTS_OrderConstants.BEING_AMENDED) OR
                         (Apttus__Status_Category__c = :APTS_OrderConstants.IN_EFFECT AND Apttus__Status__c = :APTS_OrderConstants.BEING_RENEWED) ) AND //v105
                          RecordType.Name != :APTS_OrderConstants.REGISTRATION_FORM];
    }
    
    @AuraEnabled
    public static Apttus_Config2__Order__c saveOrder(Apttus_Config2__Order__c order) {
        // Perform isUpdatable() checking first, then
        upsert order;
        return order;
    }
}