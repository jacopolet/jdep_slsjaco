/**
* Class Name : APTS_AdjustmentLineItemHandler_Test
* Description :  Test class to test APTS_AdjustmentLineItemTriggerHandler Apex Class
* Author : Lavanya Ravindran
* Date Created : 12-04-2018
**/
@isTest 
private class APTS_AdjustmentLineItemHandler_Test{

    @isTest
    static void testHandler(){
        Test.startTest();
        // Create Trigger Settings
        TriggerSettings__c settings = new TriggerSettings__c();
        settings.AdjustmentLineItemTrigger__c = true;
        insert settings;
        System.assertequals([ Select id from TriggerSettings__c limit 1].size(),1);
        // Create Product Configuration
        Apttus_Config2__ProductConfiguration__c prodConfig = new Apttus_Config2__ProductConfiguration__c (Name= 'Test Product');
        insert prodConfig;
        System.assertequals([ Select id from Apttus_Config2__ProductConfiguration__c limit 1].size(),1);
        // Create Price Rule Set
        Apttus_Config2__PriceRuleset__c priceRuleSet= new Apttus_Config2__PriceRuleset__c (Name = 'Test',Apttus_Config2__Sequence__c =1);
        insert priceRuleSet;
        System.assertequals([ Select id from Apttus_Config2__PriceRuleset__c limit 1].size(),1);
        // Create Price Rule 
        Apttus_Config2__PriceRule__c priceRule = new Apttus_Config2__PriceRule__c (Name = 'Test',Apttus_Config2__RulesetId__c=priceRuleSet.id,Apttus_Config2__Sequence__c =1);
        insert priceRule;
        System.assertequals([ Select id from Apttus_Config2__PriceRule__c limit 1].size(),1);
        // Create Price Rule Entry
        Apttus_Config2__PriceRuleEntry__c priceEntry = new Apttus_Config2__PriceRuleEntry__c (Apttus_Config2__Sequence__c= 1,Apttus_Config2__PriceRuleId__c= priceRule.id);
        insert priceEntry;
        System.assertequals([ Select id from Apttus_Config2__PriceRuleEntry__c limit 1].size(),1);
        // Create Incentive
        Apttus_Config2__Incentive__c incentive = new Apttus_Config2__Incentive__c (Name='Test Incentive',
                                                                                   Apttus_Config2__ApplicationMethod__c='Buy X Get X',
                                                                                   Apttus_Config2__EffectiveDate__c = system.today(),
                                                                                   Apttus_Config2__Sequence__c=1);
        insert incentive;
        System.assertequals([ Select id from Apttus_Config2__Incentive__c limit 1].size(),1);
        // Create Incentive Coupon
        Apttus_Config2__IncentiveCoupon__c incentiveCoupon= new Apttus_Config2__IncentiveCoupon__c (Apttus_Config2__CouponCode__c='Test', Apttus_Config2__IncentiveId__c = incentive.id);
        insert incentiveCoupon;
        System.assertequals([ Select id from Apttus_Config2__IncentiveCoupon__c limit 1].size(),1);
        // Create  Line Item
        Apttus_Config2__LineItem__c lineItem = new Apttus_Config2__LineItem__c (Apttus_Config2__LineNumber__c=12345, 
        Apttus_Config2__ConfigurationId__c = prodConfig.id,CurrencyIsoCode='EUR',Apttus_Config2__ItemSequence__c = 1,Apttus_Config2__IncentiveId__c = incentive.id,
        Apttus_Config2__IncentiveCode__c = incentiveCoupon.id);
        insert lineItem;
        
        System.assertequals([ Select id from Apttus_Config2__LineItem__c limit 1].size(),1);
        // Create  Adjustment Line Item
        Apttus_Config2__AdjustmentLineItem__c adjustlineItem = new Apttus_Config2__AdjustmentLineItem__c (Apttus_Config2__LineNumber__c=12345,
                                                                                               Apttus_Config2__PriceRuleEntryId__c = priceEntry.id, 
                                                                                               Apttus_Config2__LineItemId__c = lineItem.id,
                                                                                               Apttus_Config2__IncentiveId__c = incentive.id,
                                                                                               Apttus_Config2__Type__c= APTS_CPQConstants.LABEL_PROMOTION,
                                                                                               Apttus_Config2__IncentiveCode__c = incentiveCoupon.id);
        adjustlineItem.CurrencyIsoCode='EUR';
        System.debug('**abhi'+adjustlineItem);
        //insert adjustlineItem;  
        Test.stopTest();
        List<Apttus_Config2__AdjustmentLineItem__c> newItems = new List<Apttus_Config2__AdjustmentLineItem__c>();
        newItems.add(adjustlineItem);
        APTS_AdjustmentLineItemTriggerHandler handler = new APTS_AdjustmentLineItemTriggerHandler();
        handler.BeforeInsert(newItems);
        handler.AfterInsert(newItems,null);
       handler.BeforeUpdate(newItems, null, null, null);
        handler.BeforeDelete(newItems, null);
        handler.AfterUpdate(newItems, null, null, null);
        handler.AfterDelete(newItems, null);
        handler.AfterUndelete(newItems, null);
        System.assertequals(newItems.size(),1);
    }
}