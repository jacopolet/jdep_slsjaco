/*************************************************************
@Name: APTS_PartialCancellationUtil
@Author: Lavanya
@CreateDate: Aug 5 , 2020
@Description: USed For Partial Cancel button in Order Header 
@UsedBy: 
******************************************************************/
public with sharing class APTS_PartialCancellationUtil{

 //@Description : Method to get the getOrderLineItems 
    public static List<Apttus_Config2__OrderLineItem__c> getOrderLineItemstoOrder(Set<Id> orderIdSet) {

        List<Apttus_Config2__OrderLineItem__c> orderLineItemList = [SELECT Id,
        Apttus_Config2__ProductId__r.Name ,Apttus_Config2__OptionId__r.Name,(Select id,Status,StatusCategory from Work_Order_Line_Items__r),
        Apttus_Config2__OptionId__r.ProductCode,Apttus_Config2__ProductId__r.ProductCode,
                                               Apttus_Config2__OrderId__c,
                                               Apttus_Config2__ChargeType__c,
                                               APTS_Type_of_Contract__c,
                                               APTS_Item_Relevant_for_SAP__c,
                                               APTS_Is_Primary_L1_Line__c,
                                               Apttus_Config2__IsPrimaryLine__c,
                                               Apttus_Config2__LineNumber__c,
                                               Apttus_Config2__OptionId__c,
                                               Apttus_Config2__LineType__c,
                                               Apttus_Config2__ProductId__c,
                                               APTS_Order_LSP_Detail__c,
                                               Apttus_Config2__LocationId__c,
                                               APTS_Physical_Asset__c,
                                               APTS_Physical_Asset__r.Name,
                                               APTS_Status__c,
                                               Apttus_CMConfig__AgreementId__c,
                                               APTS_Material_Availability_Date__c,
                                               Apttus_Config2__ActivatedDate__c,
                                               Apttus_Config2__ReadyForBillingDate__c,
                                               Apttus_Config2__Status__c,
                                               APTS_Installation_Date__c,
                                               APTS_De_installation_Date__c,
                                               APTS_Installation_Required__c,
                                               APTS_De_Installation_Required__c,
                                               Apttus_Config2__HasOptions__c,
                                               Apttus_Config2__AutoRenew__c,
                                               Apttus_Config2__LineStatus__c,
                                               Apttus_Config2__ProductId__r.Apttus_Config2__ConfigurationType__c,
                                               Apttus_Config2__PriceType__c,
                                               Apttus_Config2__Frequency__c,
                                               Apttus_Config2__BillingFrequency__c,
                                               Apttus_Config2__Term__c,
                                               APTS_Requested_Installation_Date__c,
                                               APTS_Requested_Delivery_Date__c,
                                               APTS_PlugPlay__c,
                                               APTS_Option_Group_Text__c,
                                               Apttus_Config2__Description__c,
                                               APTS_Item_Category_Adjustment__c,
                                               Apttus_Config2__OrderId__r.APTS_Order_Type__c, APTS_ATP_Check_Status__c , APTS_Reason_For_Rejection__c,
                                               APTS_Treated_By_Activation_Batch__c
                                               FROM Apttus_Config2__OrderLineItem__c
                                               WHERE Apttus_Config2__OrderId__c IN :orderIdSet];

        
        return orderLineItemList;
    }



}