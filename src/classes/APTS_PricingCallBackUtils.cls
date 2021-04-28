/*************************************************************
@Name: APTS_PricingCallBackUtils
@Author: Galin Georgiev
@CreateDate: 20-03-2018
@Description: PricingCallBack utils
@UsedBy:APTS_PricingCallBack
******************************************************************/
//v100 20-03-2018 Galin Georgiev: Initial version.
//Comments in this format are mandatory for each change of code.
//Adding code comment example: v100++<< means start of changes and v100++>> means end of changes
//Removing code comment example: v100--<< means start of changes and v100-->> means end of changes
//Added Custom logging --> Sethukkarasi

public without sharing class APTS_PricingCallBackUtils {

    private static final String NGSTANDARD_ORDER = System.Label.APTS_NGStandardOrder;
    private static final String NGMACHINE_ORDER = System.Label.APTS_NGMachineOrder;
    private static final String EMAIL = System.Label.APTS_Email;

    public static Date getBiggestRequestedDeliveryDate(Id prodConfigId, Date dtRequestedDelivaryDate) {

        Date dtBiggestRequestedDeliveryDate;
        List<Apttus_Config2__LineItem__c> lineItemList = [
                    SELECT APTS_Requested_Delivery_Date__c
                    FROM Apttus_Config2__LineItem__c
                    WHERE Apttus_Config2__ConfigurationId__c = :prodConfigId ORDER BY APTS_Requested_Delivery_Date__c DESC LIMIT 1];
        //try{
        if (!lineItemList.isEmpty() && lineItemList != null) {
            dtBiggestRequestedDeliveryDate = lineItemList.get(0).APTS_Requested_Delivery_Date__c;
        }

        if (dtBiggestRequestedDeliveryDate == null || dtBiggestRequestedDeliveryDate < dtRequestedDelivaryDate) {
            dtBiggestRequestedDeliveryDate = dtRequestedDelivaryDate;
        }
         /* }
            catch(Exception e)
              {
        APTS_CustomLogging.createErrorLog(e.getTypeName(), 'Apex', e.getStackTraceString() ,'Order', ApexPages.currentPage().getParameters().get(Label.APTS_Id),'OM',false,true, EMAIL, true);
              } */
        return dtBiggestRequestedDeliveryDate;
    }

    public static void setRequestedDeliveryDate(Apttus_Config2__LineItem__c oLineItem, String sFlow, Date dtBiggestRequestedDelivaryDate) {
        //try{
        if (sFlow == NGSTANDARD_ORDER || sFlow == NGMACHINE_ORDER || sFlow == APTS_OrderConstants.NGSTANDARD_ORDERWOC || sFlow == APTS_OrderConstants.NGRSO_ORDERWOC) {
            oLineItem.APTS_Requested_Delivery_Date__c = dtBiggestRequestedDelivaryDate;
        }
         /* }
            catch(Exception e)
              {
        APTS_CustomLogging.createErrorLog(e.getTypeName(), 'Apex', e.getStackTraceString() ,'Order', ApexPages.currentPage().getParameters().get(Label.APTS_Id),'OM',false,true, EMAIL, true);
              } */
    }

    public static void setRequestedInstallationDate(Apttus_Config2__LineItem__c oLineItem, String sFlow, Date dtRequestedInstallationDate) {
        
       //try{
        if (sFlow == NGMACHINE_ORDER) {
            oLineItem.APTS_Requested_Installation_Date__c = dtRequestedInstallationDate;            
        }
         /* }
            catch(Exception e)
              {
        APTS_CustomLogging.createErrorLog(e.getTypeName(), 'Apex', e.getStackTraceString() ,'Order', ApexPages.currentPage().getParameters().get(Label.APTS_Id),'OM',false,true, EMAIL, true);
              } */
    }    

    public static void setLocation(Apttus_Config2__LineItem__c oLineItem, String sFlow, Id locationId) {

       //try{
        if (sFlow == NGSTANDARD_ORDER || sFlow == NGMACHINE_ORDER || sFlow == APTS_OrderConstants.NGSTANDARD_ORDERWOC || sFlow == APTS_OrderConstants.NGRSO_ORDERWOC) {
            if (oLineItem.Apttus_Config2__IsPrimaryLine__c && oLineItem.Apttus_Config2__LocationId__c == null) {
                oLineItem.Apttus_Config2__LocationId__c = locationId;
            }
        }
         /* }
            catch(Exception e)
              {
        APTS_CustomLogging.createErrorLog(e.getTypeName(), 'Apex', e.getStackTraceString() ,'Order', ApexPages.currentPage().getParameters().get(Label.APTS_Id),'OM',false,true, EMAIL, true);
              } */
    }
    
    /*
    public static void updateLineItemCategory(List<Apttus_Config2__LineItem__c> lineItems)
    {
    System.debug('**insideupdatelin'+lineItems.size());
    for(Apttus_Config2__LineItem__c linItem : lineItems)
    {
    System.debug(linItem.CurrencyIsoCode+'**insideupdatelinloop'+linItem.Apttus_Config2__AttributeValueId__c);
            If(
        String.isNotBlank(linItem.Apttus_Config2__AttributeValueId__c)  && 
        linItem.Apttus_Config2__NetPrice__c!=null  && 
        String.isNotBlank(linItem.Apttus_Config2__AttributeValueId__r.APTS_Type_of_contract__c) &&
        linItem.Apttus_Config2__AttributeValueId__r.APTS_Type_of_contract__c.equals('Trial') 
        ) linItem.APTS_Item_Category__c = 'A07';
        
        If(
        String.isNotBlank(linItem.Apttus_Config2__ProductOptionId__c)  && 
        String.isNotBlank(linItem.Apttus_Config2__ProductOptionId__r.Apttus_Config2__ProductOptionGroupId__c)  && 
        String.isNotBlank(linItem.Apttus_Config2__ProductOptionId__r.Apttus_Config2__ProductOptionGroupId__r.Apttus_Config2__ParentOptionGroupId__c) &&
        String.isNotBlank(linItem.Apttus_Config2__ProductOptionId__r.Apttus_Config2__ProductOptionGroupId__r.Apttus_Config2__ParentOptionGroupId__r.Apttus_Config2__Label__c) &&
        linItem.Apttus_Config2__ProductOptionId__r.Apttus_Config2__ProductOptionGroupId__r.Apttus_Config2__ParentOptionGroupId__r.Apttus_Config2__Label__c.equals('Machine') &&
        linItem.Apttus_Config2__NetPrice__c!=null &&
        String.isNotBlank(linItem.Apttus_Config2__PriceListItemId__c) &&
        String.isNotBlank(linItem.Apttus_Config2__PriceListItemId__r.Apttus_Config2__ChargeType__c) &&    
        linItem.Apttus_Config2__PriceListItemId__r.Apttus_Config2__ChargeType__c.equals('Sales Price')          
        ) linItem.APTS_Item_Category__c = 'A04';
        
        
         
         If(
         String.isNotBlank(linItem.Apttus_Config2__ProductOptionId__c)  && 
        String.isNotBlank(linItem.Apttus_Config2__ProductOptionId__r.Apttus_Config2__ProductOptionGroupId__c)  && 
        String.isNotBlank(linItem.Apttus_Config2__ProductOptionId__r.Apttus_Config2__ProductOptionGroupId__r.Apttus_Config2__ParentOptionGroupId__c) &&
        String.isNotBlank(linItem.Apttus_Config2__ProductOptionId__r.Apttus_Config2__ProductOptionGroupId__r.Apttus_Config2__ParentOptionGroupId__r.Apttus_Config2__Label__c) &&
        linItem.Apttus_Config2__ProductOptionId__r.Apttus_Config2__ProductOptionGroupId__r.Apttus_Config2__ParentOptionGroupId__r.Apttus_Config2__Label__c.equals('Machine') &&
        (
        
        (
        String.isNotBlank(linItem.Apttus_Config2__PriceListItemId__c) &&
        String.isNotBlank(linItem.Apttus_Config2__PriceListItemId__r.Apttus_Config2__ChargeType__c) &&
        linItem.Apttus_Config2__PriceListItemId__r.Apttus_Config2__ChargeType__c.equals('Rental Fee') &&
        linItem.Apttus_Config2__NetPrice__c!=null 
        )
        
        ||
        
        (
        String.isNotBlank(linItem.Apttus_Config2__AttributeValueId__c)  && 
        String.isNotBlank(linItem.Apttus_Config2__AttributeValueId__r.APTS_Type_of_contract__c) &&
        linItem.Apttus_Config2__AttributeValueId__r.APTS_Type_of_contract__c.equals('Free On Loan') 
        )
        
        )
         
         )linItem.APTS_Item_Category__c = 'A03';
        
        
        
        
        If(
        String.isNotBlank(linItem.Apttus_Config2__ProductOptionId__c)  && 
        String.isNotBlank(linItem.Apttus_Config2__ProductOptionId__r.Apttus_Config2__ProductOptionGroupId__c)  && 
        String.isNotBlank(linItem.Apttus_Config2__ProductOptionId__r.Apttus_Config2__ProductOptionGroupId__r.Apttus_Config2__ParentOptionGroupId__c) &&
        String.isNotBlank(linItem.Apttus_Config2__ProductOptionId__r.Apttus_Config2__ProductOptionGroupId__r.Apttus_Config2__ParentOptionGroupId__r.Apttus_Config2__Label__c) &&
        linItem.Apttus_Config2__ProductOptionId__r.Apttus_Config2__ProductOptionGroupId__r.Apttus_Config2__ParentOptionGroupId__r.Apttus_Config2__Label__c.equals('Machine') &&
        String.isNotBlank(linItem.Apttus_Config2__PriceListItemId__c) &&
        String.isNotBlank(linItem.Apttus_Config2__PriceListItemId__r.Apttus_Config2__ChargeType__c) &&
        linItem.Apttus_Config2__PriceListItemId__r.Apttus_Config2__ChargeType__c.equals('Rental Fee') &&
        linItem.Apttus_Config2__NetPrice__c!=null
        )linItem.APTS_Item_Category__c = 'A05';
        
        If(
        String.isNotBlank(linItem.Apttus_Config2__OptionId__c)
        &&
        (linItem.Apttus_Config2__OptionId__r.name.contains('ALL-IN COVERAGE')
        ||
        linItem.Apttus_Config2__OptionId__r.name.contains('BASIC COVERAGE'))
        &&
        (
        String.isNotBlank(linItem.Apttus_Config2__AttributeValueId__r.APTS_Type_of_contract__c) &&
        linItem.Apttus_Config2__AttributeValueId__r.APTS_Type_of_contract__c.equals('Remt')
        )
        )linItem.APTS_Item_Category__c = 'A10';
            
            
            
    If(
        (String.isNotBlank(linItem.Apttus_Config2__AttributeValueId__c)  && 
        String.isNotBlank(linItem.Apttus_Config2__AttributeValueId__r.APTS_Type_of_contract__c) &&
        linItem.Apttus_Config2__AttributeValueId__r.APTS_Type_of_contract__c.equals('Sales') &&
        String.isNotBlank(linItem.Apttus_Config2__AttributeValueId__r.APTS_Include_Free_Service__c) &&
        linItem.Apttus_Config2__AttributeValueId__r.APTS_Include_Free_Service__c.equals('NO') )
        
        &&
        (
        String.isNotBlank(linItem.Apttus_Config2__OptionId__c)
        &&
        (linItem.Apttus_Config2__OptionId__r.name.equals('All-in Coverage-Draft')
        ||
        linItem.Apttus_Config2__OptionId__r.name.equals('Basic Coverage-Draft'))
        )
        &&
        (
         linItem.Apttus_Config2__NetPrice__c!=null
        )
        &&
        (
         String.isNotBlank(linItem.Apttus_Config2__ProductOptionId__c)  && 
        String.isNotBlank(linItem.Apttus_Config2__ProductOptionId__r.Apttus_Config2__ProductOptionGroupId__c)  && 
        String.isNotBlank(linItem.Apttus_Config2__ProductOptionId__r.Apttus_Config2__ProductOptionGroupId__r.Apttus_Config2__ParentOptionGroupId__c) &&
        String.isNotBlank(linItem.Apttus_Config2__ProductOptionId__r.Apttus_Config2__ProductOptionGroupId__r.Apttus_Config2__ParentOptionGroupId__r.Apttus_Config2__Label__c) &&
        linItem.Apttus_Config2__ProductOptionId__r.Apttus_Config2__ProductOptionGroupId__r.Apttus_Config2__ParentOptionGroupId__r.Apttus_Config2__Label__c.equals('Machine')
        )
        ) linItem.APTS_Item_Category__c = 'A09';
        
        
        If(
        (String.isNotBlank(linItem.Apttus_Config2__AttributeValueId__c)  && 
        String.isNotBlank(linItem.Apttus_Config2__AttributeValueId__r.APTS_Type_of_contract__c) &&
        linItem.Apttus_Config2__AttributeValueId__r.APTS_Type_of_contract__c.equals('Sales'))
        
        
        &&
        (
        String.isNotBlank(linItem.Apttus_Config2__OptionId__c)
        &&
        (linItem.Apttus_Config2__OptionId__r.name.contains('ALL-IN COVERAGE')
        ||
        linItem.Apttus_Config2__OptionId__r.name.contains('Basic Coverage'))
        )
        &&
        (
         linItem.Apttus_Config2__NetPrice__c!=null
        )
        &&
        (
         String.isNotBlank(linItem.Apttus_Config2__ProductOptionId__c)  && 
        String.isNotBlank(linItem.Apttus_Config2__ProductOptionId__r.Apttus_Config2__ProductOptionGroupId__c)  && 
        String.isNotBlank(linItem.Apttus_Config2__ProductOptionId__r.Apttus_Config2__ProductOptionGroupId__r.Apttus_Config2__ParentOptionGroupId__c) &&
        String.isNotBlank(linItem.Apttus_Config2__ProductOptionId__r.Apttus_Config2__ProductOptionGroupId__r.Apttus_Config2__ParentOptionGroupId__r.Apttus_Config2__Label__c) &&
        linItem.Apttus_Config2__ProductOptionId__r.Apttus_Config2__ProductOptionGroupId__r.Apttus_Config2__ParentOptionGroupId__r.Apttus_Config2__Label__c.equals('Machine')
        )
        ) linItem.APTS_Item_Category__c = 'A06';
        
        
        If(
        (
        String.isNotBlank(linItem.Apttus_Config2__AttributeValueId__c)  && 
        String.isNotBlank(linItem.Apttus_Config2__AttributeValueId__r.APTS_Include_Free_Service__c)  &&   
        linItem.Apttus_Config2__AttributeValueId__r.APTS_Include_Free_Service__c.equals('NO') &&
        String.isNotBlank(linItem.Apttus_Config2__AttributeValueId__r.APTS_Type_of_contract__c) &&
        linItem.Apttus_Config2__AttributeValueId__r.APTS_Type_of_contract__c.equals('Sales') 
        )
        &&
        ( String.isNotBlank(linItem.Apttus_Config2__OptionId__c) 
        &&
        (linItem.Apttus_Config2__OptionId__r.name.equals('All-in Coverage-Draft')
        ||
        linItem.Apttus_Config2__OptionId__r.name.equals('Basic Coverage-Draft')
        )
        )
        &&
        (
         linItem.Apttus_Config2__NetPrice__c!=null
        )
        &&
        (
        String.isNotBlank(linItem.Apttus_Config2__ProductOptionId__c)  && 
        String.isNotBlank(linItem.Apttus_Config2__ProductOptionId__r.Apttus_Config2__ProductOptionGroupId__c)  && 
        String.isNotBlank(linItem.Apttus_Config2__ProductOptionId__r.Apttus_Config2__ProductOptionGroupId__r.Apttus_Config2__ParentOptionGroupId__c) &&
        String.isNotBlank(linItem.Apttus_Config2__ProductOptionId__r.Apttus_Config2__ProductOptionGroupId__r.Apttus_Config2__ParentOptionGroupId__r.Apttus_Config2__Label__c) &&
        linItem.Apttus_Config2__ProductOptionId__r.Apttus_Config2__ProductOptionGroupId__r.Apttus_Config2__ParentOptionGroupId__r.Apttus_Config2__Label__c.equals('Machine')
        )
        
        
        )linItem.APTS_Item_Category__c = 'A12';
        
        
        
        
        
        If(
        (String.isNotBlank(linItem.Apttus_Config2__AttributeValueId__c)  && 
        String.isNotBlank(linItem.Apttus_Config2__AttributeValueId__r.APTS_Type_of_contract__c) &&
        linItem.Apttus_Config2__AttributeValueId__r.APTS_Type_of_contract__c.equals('Free On Loan') &&
        String.isNotBlank(linItem.Apttus_Config2__AttributeValueId__r.APTS_Include_Free_Service__c) &&
        linItem.Apttus_Config2__AttributeValueId__r.APTS_Include_Free_Service__c.equals('NO') )
        &&
        ( 
        
        (String.isNotBlank(linItem.Apttus_Config2__OptionId__c) 
        &&
        (linItem.Apttus_Config2__OptionId__r.name.equals('All-in Coverage-Draft')
        ||
        linItem.Apttus_Config2__OptionId__r.name.equals('Basic Coverage-Draft')
        )
        )
        ||
        (
        String.isNotBlank(linItem.Apttus_Config2__AttributeValueId__c)  && 
        String.isNotBlank(linItem.Apttus_Config2__AttributeValueId__r.APTS_Type_of_contract__c) &&
        linItem.Apttus_Config2__AttributeValueId__r.APTS_Type_of_contract__c.equals('Rent')
        )
        )
        &&
        (
        ( linItem.Apttus_Config2__NetPrice__c!=null)
        &&
        (
        String.isNotBlank(linItem.Apttus_Config2__ProductOptionId__c)  && 
        String.isNotBlank(linItem.Apttus_Config2__ProductOptionId__r.Apttus_Config2__ProductOptionGroupId__c)  && 
        String.isNotBlank(linItem.Apttus_Config2__ProductOptionId__r.Apttus_Config2__ProductOptionGroupId__r.Apttus_Config2__ParentOptionGroupId__c) &&
        String.isNotBlank(linItem.Apttus_Config2__ProductOptionId__r.Apttus_Config2__ProductOptionGroupId__r.Apttus_Config2__ParentOptionGroupId__r.Apttus_Config2__Label__c) &&
        linItem.Apttus_Config2__ProductOptionId__r.Apttus_Config2__ProductOptionGroupId__r.Apttus_Config2__ParentOptionGroupId__r.Apttus_Config2__Label__c.equals('Machine')
        )
        
        )
        )linItem.APTS_Item_Category__c = 'A08';
        
        
        
        
        
        If(
        (String.isNotBlank(linItem.Apttus_Config2__AttributeValueId__c)  && 
        String.isNotBlank(linItem.Apttus_Config2__AttributeValueId__r.APTS_Type_of_contract__c) &&
        linItem.Apttus_Config2__AttributeValueId__r.APTS_Type_of_contract__c.equals('Free On Loan') &&
        String.isNotBlank(linItem.Apttus_Config2__AttributeValueId__r.APTS_Include_Free_Service__c) &&
        linItem.Apttus_Config2__AttributeValueId__r.APTS_Include_Free_Service__c.equals('YES') )
        &&
        (
        
        String.isNotBlank(linItem.Apttus_Config2__OptionId__c) 
        &&
        (linItem.Apttus_Config2__OptionId__r.name.contains('ALL-IN COVERAGE')
        ||
        linItem.Apttus_Config2__OptionId__r.name.equals('Basic Coverage-Draft')
        )
        
        )
        )linItem.APTS_Item_Category__c = 'A11';
        
        
        
        IF(
        linItem.Apttus_Config2__NetPrice__c!=null &&
        String.isNotBlank(linItem.Apttus_Config2__ProductId__c) &&
        String.isNotBlank(linItem.Apttus_Config2__ProductId__r.APTS_Material_Type__c) &&
        linItem.Apttus_Config2__ProductId__r.APTS_Material_Type__c.equals('ZFIN') &&
        String.isNotBlank(linItem.Apttus_Config2__ProductId__r.Apttus_Config2__ConfigurationType__c) &&
        linItem.Apttus_Config2__ProductId__r.Apttus_Config2__ConfigurationType__c.equals('Standalone')
        )linItem.APTS_Item_Category__c = 'A02';
        
                IF(
        linItem.Apttus_Config2__NetPrice__c!=null &&
        String.isNotBlank(linItem.Apttus_Config2__ProductId__c) &&
        String.isNotBlank(linItem.Apttus_Config2__ProductId__r.APTS_Material_Type__c) &&
        linItem.Apttus_Config2__ProductId__r.APTS_Material_Type__c.equals('ZFIN') &&
        String.isNotBlank(linItem.Apttus_Config2__AttributeValueId__c)  && 
        String.isNotBlank(linItem.Apttus_Config2__AttributeValueId__r.APTS_Type_of_contract__c) &&
        linItem.Apttus_Config2__AttributeValueId__r.APTS_Type_of_contract__c.equals('Consumption')
        )linItem.APTS_Item_Category__c = 'A01';
            
            
          }  
            }
    */
}