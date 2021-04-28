/*************************************************************
@Name: APTS_ContractedProductsHelper
@Author: Raul Orozco
@CreateDate: 25-07-2018
@Description: Helper class for APTS_ContractedProductsCtrl. 
@UsedBy: APTS_ContractedProductsCtrl
******************************************************************/
public without sharing class APTS_ContractedProductsHelper {
	public static Map<Id,Apttus_Config2__LineItem__c> productsInCart(Id cartId){
        //Set to store product ids
        Map<Id,Apttus_Config2__LineItem__c> mapProducts = new Map<Id,Apttus_Config2__LineItem__c>();

        //Retrieve the list of line items related with the cart
        List<Apttus_Config2__LineItem__c> lstLI =
        [
            SELECT Id, 
            Apttus_Config2__ProductId__c, 
            Apttus_Config2__OptionId__c,
            Apttus_Config2__SellingUom__c,
            Apttus_Config2__Quantity__c,
            APTS_Hierarchy_Last_Level__c
            FROM Apttus_Config2__LineItem__c
            WHERE Apttus_Config2__ConfigurationId__c = :cartId
        ];

        if(lstLI.size() > 0){
            //Check if the line item corresponds to a option or a product
            for(Apttus_Config2__LineItem__c currentLI : lstLI){
                if(currentLI.Apttus_Config2__OptionId__c != null){
                    mapProducts.put(currentLI.Apttus_Config2__OptionId__c,currentLI);
                }else{
                    mapProducts.put(currentLI.Apttus_Config2__ProductId__c,currentLI);
                }
            }
        }

        return mapProducts;
    }
}