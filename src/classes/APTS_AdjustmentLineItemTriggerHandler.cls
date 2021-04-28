/**
* Class Name : APTS_AdjustmentLineItemTriggerHandler
* Description :  Adjustment Line Item Trigger Handler which implements ITriggerHandler interface
* Author : Lavanya Ravindran
* Date Created : 07-04-2018
* v2 DQ-2132 Lavanya- May 12 2020 Population of Agreement and UOM_Translated field for Adjustment LineItem.
**/
public with sharing class APTS_AdjustmentLineItemTriggerHandler implements ITriggerHandler{

    
    
    public void BeforeInsert(List<Apttus_Config2__AdjustmentLineItem__c> newItems){
        Set<ID> priceRuleSetIDSet = new Set<ID>();
        String apiObject= 'Apttus_Config2__AdjustmentLineItem__c';
        // Modified by Saranya Rajagopal Date: 12th sep 2018
        /* 
        String PREVIOUS_PRICE = 'Previous Price'; // unused varriable 
        String STARTING_PRICE = 'Starting Price';  // unused varriable 
        */
        Set<ID> incentiveSet = new Set<ID>();
        Set<ID> lineItemSet = new Set<ID>();
        Map<ID,Set<String>> incentiveCodeMap = new Map<ID,Set<String>>();
        List<Apttus_Config2__AdjustmentLineItem__c> newList = (List<Apttus_Config2__AdjustmentLineItem__c>) newItems;
        Map<ID,Apttus_Config2__LineItem__c> couponCodeLineItemMap = new Map<ID,Apttus_Config2__LineItem__c>();
        //DQ-2132
        Map<String, String> mapFields= new Map<String, String>();
        Map<String, String> mapNew= new Map<String, String>();
        mapFields.put('Apttus_Config2__AdjustmentUom__c', 'APTS_Adjustment_UOM_translated__c');
        mapNew= APTS_LanguageTranslator.getAPItoLabel(apiObject,mapFields);
        //DQ-2132
        //DOQCP-102 | template changes start
     /*   Map<String,String> adjustmentUOMLabelMap = new Map<String,String>();
        for( Schema.PicklistEntry v : Apttus_Config2__AdjustmentLineItem__c.Apttus_Config2__AdjustmentUom__c.getDescribe().getPicklistValues()) {
          adjustmentUOMLabelMap.put(v.getValue(),v.getLabel());
        } */
        //DOQCP-102 | template changes end
        try{
            for(Apttus_Config2__AdjustmentLineItem__c instAdjustment : newList){

               // if(instAdjustment.APTS_Category__c!=null){instAdjustment.APTS_Category_Adjustment_Applied__c=true;}
                priceRuleSetIDSet.add(instAdjustment.Apttus_Config2__PriceRuleEntryId__c);
                incentiveSet.add(instAdjustment.Apttus_Config2__IncentiveId__c);
                lineItemSet.add(instAdjustment.Apttus_Config2__LineItemId__c);
            }
            Map<Id,Apttus_Config2__LineItem__c> lineItemMap = new Map<Id,Apttus_Config2__LineItem__c>();
           
            if(!lineItemSet.isEmpty())
            {
            for(Apttus_Config2__LineItem__c lineItem : [SELECT Id,Apttus_Config2__ConfigurationId__r.Apttus_CMConfig__AgreementId__c,Apttus_Config2__ConfigurationId__r.Apttus_CMConfig__AgreementId__r.Apttus__Contract_Start_Date__c, Apttus_Config2__ConfigurationId__r.Apttus_CMConfig__AgreementId__r.Apttus__Contract_End_Date__c, Apttus_Config2__ConfigurationId__r.Apttus_CMConfig__AgreementId__r.APTS_Agreement_Request__c,Apttus_Config2__ProductId__r.Name,Apttus_Config2__LineStatus__c,Apttus_Config2__DerivedFromId__c,Apttus_Config2__ConfigurationId__r.Apttus_Config2__CouponCodes__c, Apttus_Config2__SellingUom__c, Apttus_Config2__ConfigurationId__r.Apttus_Config2__BusinessObjectType__c, Apttus_Config2__StartDate__c, Apttus_Config2__EndDate__c FROM Apttus_Config2__LineItem__c WHERE Id IN: lineItemSet]){
                if(couponCodeLineItemMap.get(lineItem.id) == null){
                    couponCodeLineItemMap.put(lineItem.id,lineItem);
                }
            }
            }
            if(!couponCodeLineItemMap.isempty()){
               
                for(Apttus_Config2__AdjustmentLineItem__c aggr1 : (List<Apttus_Config2__AdjustmentLineItem__c>)newList){

                    if(couponCodeLineItemMap.get(aggr1.Apttus_Config2__LineItemId__c).Apttus_Config2__ConfigurationId__r.Apttus_CMConfig__AgreementId__r.APTS_Agreement_Request__c == APTS_CPQNonBacthConstants.LABEL_RENEW)
                    {
                     aggr1.APTS_Start_Date__c=couponCodeLineItemMap.get(aggr1.Apttus_Config2__LineItemId__c).Apttus_Config2__ConfigurationId__r.Apttus_CMConfig__AgreementId__r.Apttus__Contract_Start_Date__c;
                     aggr1.APTS_End_Date__c=couponCodeLineItemMap.get(aggr1.Apttus_Config2__LineItemId__c).Apttus_Config2__ConfigurationId__r.Apttus_CMConfig__AgreementId__r.Apttus__Contract_End_Date__c;
                    }
                    /*else if(couponCodeLineItemMap.get(aggr1.Apttus_Config2__LineItemId__c).Apttus_Config2__ConfigurationId__r.Apttus_CMConfig__AgreementId__r.APTS_Agreement_Request__c == APTS_CPQNonBacthConstants.LABEL_New)
                    {
                     aggr1.APTS_Start_Date__c=couponCodeLineItemMap.get(aggr1.Apttus_Config2__LineItemId__c).Apttus_Config2__ConfigurationId__r.Apttus_CMConfig__AgreementId__r.Apttus__Contract_Start_Date__c;
                     aggr1.APTS_End_Date__c=couponCodeLineItemMap.get(aggr1.Apttus_Config2__LineItemId__c).Apttus_Config2__ConfigurationId__r.Apttus_CMConfig__AgreementId__r.Apttus__Contract_End_Date__c;
                    }
                    else if(couponCodeLineItemMap.get(aggr1.Apttus_Config2__LineItemId__c).Apttus_Config2__ConfigurationId__r.Apttus_CMConfig__AgreementId__r.APTS_Agreement_Request__c == APTS_CPQNonBacthConstants.LABEL_AMENDMENT)
                    {
                     aggr1.APTS_Start_Date__c=couponCodeLineItemMap.get(aggr1.Apttus_Config2__LineItemId__c).Apttus_Config2__StartDate__c;
                     aggr1.APTS_End_Date__c=couponCodeLineItemMap.get(aggr1.Apttus_Config2__LineItemId__c).Apttus_Config2__EndDate__c;
                    }*/
                    else if(aggr1.APTS_Start_Date__c==null&&aggr1.APTS_End_Date__c==null)
                    {
                     aggr1.APTS_Start_Date__c=couponCodeLineItemMap.get(aggr1.Apttus_Config2__LineItemId__c).Apttus_Config2__StartDate__c;   
                     aggr1.APTS_End_Date__c=couponCodeLineItemMap.get(aggr1.Apttus_Config2__LineItemId__c).Apttus_Config2__EndDate__c;   
                    }

                    /*if(aggr1.APTS_Agreement__c==null && couponCodeLineItemMap.get(aggr1.Apttus_Config2__LineItemId__c)!=null && couponCodeLineItemMap.get(aggr1.Apttus_Config2__LineItemId__c).Apttus_Config2__ConfigurationId__c!=null && couponCodeLineItemMap.get(aggr1.Apttus_Config2__LineItemId__c).Apttus_Config2__ConfigurationId__r.Apttus_CMConfig__AgreementId__c!=null){
                        aggr1.APTS_Agreement__c=couponCodeLineItemMap.get(aggr1.Apttus_Config2__LineItemId__c).Apttus_Config2__ConfigurationId__r.Apttus_CMConfig__AgreementId__c;
                    }*/
                    
                    //DQ-2132
                    if(aggr1.APTS_Agreement__c==null && couponCodeLineItemMap.get(aggr1.Apttus_Config2__LineItemId__c)!=null && couponCodeLineItemMap.get(aggr1.Apttus_Config2__LineItemId__c).Apttus_Config2__ConfigurationId__c!=null && couponCodeLineItemMap.get(aggr1.Apttus_Config2__LineItemId__c).Apttus_Config2__ConfigurationId__r.Apttus_CMConfig__AgreementId__c!=null){
                        aggr1.APTS_Agreement__c=couponCodeLineItemMap.get(aggr1.Apttus_Config2__LineItemId__c).Apttus_Config2__ConfigurationId__r.Apttus_CMConfig__AgreementId__c;
                    } 
                    if(!mapNew.isEmpty() && mapNew.containsKey(aggr1.Apttus_Config2__AdjustmentUom__c) && mapNew.get(aggr1.Apttus_Config2__AdjustmentUom__c)!= null)
                    aggr1.APTS_Adjustment_UOM_translated__c = mapNew.get(aggr1.Apttus_Config2__AdjustmentUom__c);
                    //DQ-2132
                 
                    
                }
            }
            if(!incentiveSet.isempty())
            {
            for(Apttus_Config2__IncentiveCoupon__c incentive : [SELECT Id, Apttus_Config2__IncentiveId__c, Apttus_Config2__CouponCode__c FROM Apttus_Config2__IncentiveCoupon__c WHERE Apttus_Config2__IncentiveId__c IN: incentiveSet ]){
                if(incentiveCodeMap.get(incentive.Apttus_Config2__IncentiveId__c) != null){
                    incentiveCodeMap.get(incentive.Apttus_Config2__IncentiveId__c).add(incentive.Apttus_Config2__CouponCode__c);
                }else{
                    incentiveCodeMap.put(incentive.Apttus_Config2__IncentiveId__c,new Set<String>{incentive.Apttus_Config2__CouponCode__c});   
                }
            }
            }
            
            Map<ID,Apttus_Config2__PriceRuleEntry__c> priceRuleEntryMap = new Map<ID,Apttus_Config2__PriceRuleEntry__c>([SELECT Id,APTS_TPR__c FROM Apttus_Config2__PriceRuleEntry__c WHERE Id IN: priceRuleSetIDSet ]);
            if(!priceRuleEntryMap.isEmpty()){
                for(Apttus_Config2__AdjustmentLineItem__c instAdjustment : newList){
                    if(instAdjustment.Apttus_Config2__PriceRuleEntryId__c != null){
                        if(instAdjustment.Apttus_Config2__Type__c == APTS_CPQConstants.LABEL_PROMOTION){
                            instAdjustment.Apttus_Config2__Type__c = APTS_CPQConstants.LABEL_TPR;
                            instAdjustment.Apttus_Config2__Bucket__c = APTS_CPQConstants.LABEL_BUCKET2;
                            instAdjustment.Apttus_Config2__AdjustmentAppliesTo__c = APTS_CPQConstants.LABEL_BUCKET1;
                            //Adding logic to populate Selling UOM as Adjustment UOM 
                            if(!couponCodeLineItemMap.isEmpty() && couponCodeLineItemMap.get(instAdjustment.Apttus_Config2__LineItemId__c) != null){
                                instAdjustment.Apttus_Config2__AdjustmentUom__c = couponCodeLineItemMap.get(instAdjustment.Apttus_Config2__LineItemId__c).Apttus_Config2__SellingUom__c;
                                if(couponCodeLineItemMap.get(instAdjustment.Apttus_Config2__LineItemId__c).Apttus_Config2__ConfigurationId__r.Apttus_Config2__BusinessObjectType__c == APTS_CPQConstants.LABEL_AGREEEMENT){
                                    instAdjustment.APTS_Start_Date__c = couponCodeLineItemMap.get(instAdjustment.Apttus_Config2__LineItemId__c).Apttus_Config2__StartDate__c;
                                    instAdjustment.APTS_End_Date__c = couponCodeLineItemMap.get(instAdjustment.Apttus_Config2__LineItemId__c).Apttus_Config2__EndDate__c;
                                }
                            }
                            if(!incentiveCodeMap.isEmpty() && !couponCodeLineItemMap.isEmpty() && incentiveCodeMap.get(instAdjustment.Apttus_Config2__IncentiveId__c).contains(couponCodeLineItemMap.get(instAdjustment.Apttus_Config2__LineItemId__c).Apttus_Config2__ConfigurationId__r.Apttus_Config2__CouponCodes__c)){
                                instAdjustment.Apttus_Config2__SubType__c =  APTS_CPQConstants.LABEL_COUPANS_LOYALTY;
                            }
                            else if(priceRuleEntryMap.get(instAdjustment.Apttus_Config2__PriceRuleEntryId__c).APTS_TPR__c){
                                instAdjustment.Apttus_Config2__SubType__c = APTS_CPQConstants.LABEL_TPR_100_DISCOUNT;
                            }
                            else{
                                instAdjustment.Apttus_Config2__SubType__c = APTS_CPQConstants.LABEL_SUB_TYPE_PROMOTION;
                            }
                        }
                    }
                }
            }
        }catch(Exception e){
            APTS_CustomLogging.createErrorLog(e.getTypeName(), APTS_CPQConstants.APEX_NAME, e.getMessage()+'\n\n'+e.getStackTraceString() ,APTS_CPQConstants.LABEL_ADJUSTMENTLINEITEM, ApexPages.currentPage().getParameters().get(APTS_CPQConstants.BSN_OBJ_ID),APTS_CPQConstants.CPQ,false,true, APTS_CPQConstants.EX_ABHI_MAIL,true);
        }
    }
    public void BeforeUpdate(List<Apttus_Config2__AdjustmentLineItem__c > newList, Map<Id, SObject> newItems, List<SObject> oldList, Map<Id, SObject> oldItems){
    }
    public void BeforeDelete(List<SObject> oldList, Map<Id, SObject> oldItems){

        List<Apttus_Config2__AdjustmentLineItem__c> castlist=(List<SObject>) oldList;
        List<Apttus_Config2__AdjustmentLineItem__c> finallist=new List<Apttus_Config2__AdjustmentLineItem__c> ();
        list<String> newlist=new list<String>();
        list<CERDiscountCache__c> newcercache=new list<CERDiscountCache__c>();
        map<Id,String> cercachemap=new map<id,String>();
        List<Apttus_Config2__LineItem__c> lineItemprod=new list<Apttus_Config2__LineItem__c>();
        lineItemprod=[select id, Apttus_Config2__ProductId__c,Apttus_Config2__ConfigurationId__c from Apttus_Config2__LineItem__c where id =:castlist[0].Apttus_Config2__LineItemId__c];   
        for(Apttus_Config2__AdjustmentLineItem__c adj:castlist){
            if(adj.APTS_Adjustment_Source__c=='Child'&&adj.APTS_Category__c==null){
                cercachemap.put(adj.Apttus_Config2__LineItemId__c,adj.Apttus_Config2__LineItemId__c+adj.Apttus_Config2__SubType__c+adj.APTS_Adjustment_Source__c);
                finallist.add(adj);
            }

        }
        CERDiscountCache__c ret=new CERDiscountCache__c();
        CERDiscountCache__c cac;
        for(String s:cercachemap.values()){
        ret=CERDiscountCache__c.getValues(s);
        }
        for(Apttus_Config2__AdjustmentLineItem__c finadj:finallist){
            if(ret==null){
                cac=new CERDiscountCache__c(Name=finadj.Apttus_Config2__LineItemId__c+finadj.Apttus_Config2__SubType__c+finadj.APTS_Adjustment_Source__c,Sub_Type__c=finadj.Apttus_Config2__SubType__c,Name__c=finadj.Apttus_Config2__LineItemId__c,Configuration__c=lineItemprod[0].Apttus_Config2__ConfigurationId__c,Source__c=finadj.APTS_Adjustment_Source__c);
                //newcercache.add(cac);

            }
        }
        if(cac!=null){
        insert cac;}
        //String tempstring=castlist[0].Apttus_Config2__LineItemId__c+castlist[0].Apttus_Config2__SubType__c;
        system.debug('++Shahul+++'+castlist[0].Apttus_Config2__LineItemId__r.Apttus_Config2__ProductId__c);
        system.debug('++Shahul+++'+castlist[0]);
        
        //CERDiscountCache__c ret=new CERDiscountCache__c();
       // ret=CERDiscountCache__c.getValues(tempstring);
      /* try{
                if(ret==null){

                system.debug('++Shahul+++'+castlist[0]);
                CERDiscountCache__c cac=new CERDiscountCache__c(Name=castlist[0].Apttus_Config2__LineItemId__c+castlist[0].Apttus_Config2__SubType__c,Sub_Type__c=castlist[0].Apttus_Config2__SubType__c,Name__c=castlist[0].Apttus_Config2__LineItemId__c,Configuration__c=lineItemprod[0].Apttus_Config2__ConfigurationId__c);
                insert cac;

                }
            }catch(Exception e){
            APTS_CustomLogging.createErrorLog(e.getTypeName(), APTS_CPQConstants.APEX_NAME, e.getMessage()+'\n\n'+e.getStackTraceString() ,APTS_CPQConstants.LABEL_ADJUSTMENTLINEITEM, ApexPages.currentPage().getParameters().get(APTS_CPQConstants.BSN_OBJ_ID),APTS_CPQConstants.CPQ,false,true, APTS_CPQConstants.EX_ABHI_MAIL,true);
        }*/
 }
    public void AfterInsert(List<Apttus_Config2__AdjustmentLineItem__c> newList, Map<Id, SObject> newItems){
    Map<ID, Apttus_Config2__LineItem__c> parentline = new Map<ID, Apttus_Config2__LineItem__c>(); 
    List<Id> listIds = new List<Id>();
    
    for(Apttus_Config2__AdjustmentLineItem__c ABOadj:newList){
        listIds.add(ABOadj.Apttus_Config2__LineItemId__c);

    }
      parentline = new Map<Id, Apttus_Config2__LineItem__c>([SELECT id,Apttus_Config2__ConfigurationId__c,APTS_ABO_Applied__c,Apttus_Config2__ConfigurationId__r.Apttus_Config2__OrderId__r.APTS_Order_Sub_Type__c from Apttus_Config2__LineItem__c WHERE ID IN :listIds]);
    
       for(Apttus_Config2__AdjustmentLineItem__c ABOadj1:newList){
       Apttus_Config2__LineItem__c line=parentline.get(ABOadj1.Apttus_Config2__LineItemId__c);
       if(line.Apttus_Config2__ConfigurationId__r.Apttus_Config2__OrderId__r.APTS_Order_Sub_Type__c=='Conversion Order'&&line.APTS_ABO_Applied__c==false){
       line.APTS_ABO_Applied__c=true;
       }

    }if(parentline.values().size()>0&&!Test.isRunningTest()){
    update parentline.values();
         }
    }
    public void AfterUpdate(List<SObject> newList, Map<Id, SObject> newItems, List<SObject> oldList, Map<Id, SObject> oldItems){}
 
    public void AfterDelete(List<SObject> oldList, Map<Id, SObject> oldItems){}
 
    public void AfterUndelete(List<SObject> newList, Map<Id, SObject> newItems){}
    
    public Boolean IsDisabled(){
        return (TriggerSettings__c.getInstance().AdjustmentLineItemTrigger__c == true ? false : true);
    }
}