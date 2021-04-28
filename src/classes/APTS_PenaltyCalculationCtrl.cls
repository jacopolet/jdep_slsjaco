public without sharing class  APTS_PenaltyCalculationCtrl
{
    public APTS_PenaltyCalculationCtrl(ApexPages.StandardController controller) 
    {

    }
    public boolean calculateClicked{get;set;}
    public map<Id,Decimal> totalBilling{get;set;}
    public map<Id,Decimal> purchaseValues{get;set;}
    public map<Id,Decimal> alreadyInvoiced{get;set;}
    public map<Id,Decimal> pending{get;set;}
    public map<Id,Decimal> refund{get;set;}
    public map<Id,Decimal> additionalDiscount{get;set;}
    public map<Id,Decimal> optionalDiscount{get;set;}
    public map<Id,Decimal> optionalPenalty{get;set;}
    public map<Id,Decimal> additionalPenalty{get;set;}
    public map<Id,Decimal> credits{get;set;}
    public map<Id,Decimal> remainingTerm{get;set;}
    public Map<Id,Id> productOptionMap{get;set;}
    public List<Apttus_Config2__AssetLineItem__c> selectedAssets{get;set;}
    public Set<Apttus_Config2__AssetLineItem__c> optionAssets{get;set;}
    public List<Apttus_Config2__AssetLineItem__c> nonRecurringAssets{get;set;}
    public List<Apttus_Billing__BillingSchedule__c> billings{get;set;}
    public Set<id> productIds{get;set;}
    public Map<Id,List<String>> productOptions{get;set;}
    public Map<Id,List<Apttus_Config2__AssetLineItem__c>> productOptionAssets{get;set;}
    public Map<Id,Apttus_Config2__AssetLineItem__c> productAssets{get;set;}
    public Set<Id> passedIds{get;set;}
    public list<Id> recIds{get;set;}
    public Apttus_Config2__ProductConfiguration__c prodConfig{get;set;}
    public boolean remainsjdecust {get;set;}
    public date terminationDate{get;set;}

    public APTS_PenaltyCalculationCtrl()//ApexPages.StandardController stdController)
    {
        try
        {
            calculateClicked = true;
            selectedAssets = new List<Apttus_Config2__AssetLineItem__c>();
            optionAssets= new Set<Apttus_Config2__AssetLineItem__c>();
            nonRecurringAssets = new List<Apttus_Config2__AssetLineItem__c>();
            totalBilling = new map<Id,Decimal>();
            remainsjdecust  = false;
            terminationDate= Date.today();
            productOptionMap = new Map<Id,Id>();
            alreadyInvoiced= new map<Id,Decimal>();
            purchaseValues = new map<Id,Decimal>();
            optionalDiscount= new map<Id,Decimal>();
            optionalPenalty= new map<Id,Decimal>();
            remainingTerm = new map<Id,Decimal>();
            pending= new map<Id,Decimal>();
            refund= new map<Id,Decimal>();
            credits= new map<Id,Decimal>();
            additionalDiscount= new map<Id,Decimal>();
            additionalPenalty= new map<Id,Decimal>();
            billings = new List<Apttus_Billing__BillingSchedule__c>();
            productids = new Set<Id>();
            productOptions = new Map<Id,List<String>>();
            productOptionAssets = new Map<Id,List<Apttus_Config2__AssetLineItem__c>>();
            productAssets = new Map<Id,Apttus_Config2__AssetLineItem__c>();
    
            prodConfig = new Apttus_Config2__ProductConfiguration__c();
            passedIds = new Set<Id>();
            recIds = new list<Id>();
            //System.debug('****prodconfig'+ApexPages.currentPage().getParameters().get('prodconfig'));
            prodConfig  = [Select id from Apttus_Config2__ProductConfiguration__c where id=:ApexPages.currentPage().getParameters().get(APTS_CPQConstants.PRD_CONFIG1)][0];
            for(String s : ApexPages.currentPage().getParameters().get(APTS_CPQConstants.IDS).split(APTS_CPQConstants.COMMA_SIGN,-1))
            {
                //System.debug('Lavanya s'+s);
                passedIds.add(Id.valueOf(s));                
                recIds.add(Id.valueOf(s));
            }
            for(Apttus_Config2__AssetLineItem__c initialAsset: [Select Apttus_Config2__StartDate__c,Apttus_Config2__EndDate__c,Apttus_Config2__ShipToAccountId__c,Apttus_Config2__PriceListId__c ,Apttus_Config2__Description__c ,Apttus_Config2__PriceListItemId__c ,Apttus_Config2__ChargeType__c ,Apttus_Config2__BasePrice__c ,Apttus_Config2__ExtendedPrice__c ,Apttus_Config2__BillToAccountId__c,Apttus_Config2__AccountId__c,Apttus_CMConfig__AgreementId__c,Apttus_CMConfig__AgreementLineItemId__c,Apttus_Config2__AttributeValueId__r.APTS_Purchase_Value__c,Apttus_Config2__ListPrice__c,Apttus_Config2__Quantity__c,Apttus_Config2__PriceListItemId__r.Apttus_Config2__ListPrice__c,Apttus_Config2__BillThroughDate__c,Apttus_Config2__BillingStartDate__c,Apttus_Config2__BillingEndDate__c,Apttus_Config2__ProductId__c, Apttus_Config2__ProductId__r.name,Apttus_Config2__Frequency__c,Apttus_Config2__PriceType__c,APTS_Type_Of_Contract__c, Apttus_Config2__AssetStatus__c from Apttus_Config2__AssetLineItem__c where id in :passedIds])
            {
                //if(initialAsset.Apttus_Config2__PriceType__c!= APTS_CPQConstants.LABEL_RECURRING) nonRecurringAssets.add(initialAsset);
                //else 
                selectedAssets.add(initialAsset);
            }
    
           
    
            for(Apttus_Config2__AssetLineItem__c asset : selectedAssets )
            {
                productids.add(asset.Apttus_Config2__ProductId__c);
                productOptionAssets.put(asset.id,new List<Apttus_Config2__AssetLineItem__c>());//Apttus_Config2__ProductId__c
                productAssets.put(asset.Apttus_Config2__ProductId__c,asset);
                productOptions.put(asset.Apttus_Config2__ProductId__c,new List<String>());
                optionalPenalty.put(asset.Apttus_Config2__ProductId__c,0);
                optionalDiscount.put(asset.Apttus_Config2__ProductId__c,0);
                totalBilling.put(asset.id,0);
                alreadyInvoiced.put(asset.id,0);
                pending.put(asset.id,0);
                refund.put(asset.id,0);
                additionalDiscount.put(asset.id,0);
                additionalPenalty.put(asset.id,0);
                credits.put(asset.id,0);
                remainingTerm.put(asset.id,0);
    
                if(asset.Apttus_Config2__AttributeValueId__r.APTS_Purchase_Value__c!=null) 
                    purchaseValues.put(asset.id,asset.Apttus_Config2__AttributeValueId__r.APTS_Purchase_Value__c);
                else 
                    purchaseValues.put(asset.id,0);
  
            }
    
            if(productids.size()>0 && !passedIds.isEmpty())
            {
                for(Apttus_Config2__AssetLineItem__c asset :  
                    [Select Apttus_Config2__ParentAssetId__r.id,Apttus_Config2__ParentAssetId__c,
                        Apttus_Config2__StartDate__c,Apttus_Config2__EndDate__c,Apttus_Config2__BundleAssetId__c,
                        Apttus_Config2__ShipToAccountId__c,Apttus_Config2__PriceListId__c,
                        Apttus_Config2__Description__c,Apttus_Config2__PriceListItemId__c,
                        Apttus_Config2__ChargeType__c,Apttus_Config2__BasePrice__c,
                        Apttus_Config2__ExtendedPrice__c, Apttus_Config2__BillToAccountId__c,
                        Apttus_Config2__AccountId__c, Apttus_Config2__OptionId__c,Apttus_Config2__OptionId__r.name,
                        Apttus_CMConfig__AgreementId__c,Apttus_CMConfig__AgreementLineItemId__c,
                        Apttus_Config2__AttributeValueId__r.APTS_Purchase_Value__c,
                        Apttus_Config2__ListPrice__c,Apttus_Config2__Quantity__c,Apttus_Config2__PriceListItemId__r.Apttus_Config2__ListPrice__c,
                        Apttus_Config2__BillThroughDate__c,Apttus_Config2__BillingStartDate__c,Apttus_Config2__BillingEndDate__c,
                        Apttus_Config2__ProductId__c, Apttus_Config2__ProductId__r.name,Apttus_Config2__Frequency__c,Apttus_Config2__PriceType__c,
                        APTS_Type_Of_Contract__c, Apttus_Config2__AssetStatus__c 
                    from Apttus_Config2__AssetLineItem__c 
                    where Apttus_Config2__PriceType__c!=''  
                    and Apttus_Config2__Frequency__c!='' 
                    and Apttus_Config2__OptionId__c!=null 
                    and Apttus_Config2__BundleAssetId__c IN :passedIds 
                    and Apttus_Config2__IsPrimaryLine__c=true])
                {
                    if (productAssets.get(asset.Apttus_Config2__ProductId__c).Apttus_CMConfig__AgreementId__c == asset.Apttus_CMConfig__AgreementId__c 
                        && productAssets.get(asset.Apttus_Config2__ProductId__c).Apttus_Config2__AccountId__c == asset.Apttus_Config2__AccountId__c)
                    {
                        //System.debug('Lavanya Bundle Asset->'+asset.Apttus_Config2__BundleAssetId__c+'ParentAsset->'+asset.Apttus_Config2__ParentAssetId__c);
                        //if(productOptionAssets.containskey(productAssets.get(asset.Apttus_Config2__ProductId__c).id)) productOptionAssets.get(productAssets.get(asset.Apttus_Config2__ProductId__c).id).add(asset);
                        // else productOptionAssets.put(productAssets.get(asset.Apttus_Config2__ProductId__c).id,new List<Apttus_Config2__AssetLineItem__c>{asset});
                        if(asset.Apttus_Config2__ParentAssetId__c!=null)
                        {
                            if(productOptionAssets.containskey(asset.Apttus_Config2__ParentAssetId__c)) 
                                productOptionAssets.get(asset.Apttus_Config2__ParentAssetId__c).add(asset);
                            else 
                                productOptionAssets.put(asset.Apttus_Config2__ParentAssetId__c,new List<Apttus_Config2__AssetLineItem__c>{asset});
                            totalBilling.put(asset.Apttus_Config2__ParentAssetId__r.id,0);
                            alreadyInvoiced.put(asset.Apttus_Config2__ParentAssetId__r.id,0);
                            pending.put(asset.Apttus_Config2__ParentAssetId__r.id,0);
                            refund.put(asset.Apttus_Config2__ParentAssetId__r.id,0);
                            additionalDiscount.put(asset.Apttus_Config2__ParentAssetId__r.id,0);
                            additionalPenalty.put(asset.Apttus_Config2__ParentAssetId__r.id,0);
                            credits.put(asset.Apttus_Config2__ParentAssetId__r.id,0);
                            remainingTerm.put(asset.Apttus_Config2__ParentAssetId__r.id,0);
                        }   
                        optionAssets.add(asset);
                        totalBilling.put(asset.id,0);
                        alreadyInvoiced.put(asset.id,0);
                        pending.put(asset.id,0);
                        refund.put(asset.id,0);
                        additionalDiscount.put(asset.id,0);
                        additionalPenalty.put(asset.id,0);
                        credits.put(asset.id,0);
                        remainingTerm.put(asset.id,0);
    
                        if(asset.Apttus_Config2__AttributeValueId__r.APTS_Purchase_Value__c!=null) 
                            purchaseValues.put(asset.id,asset.Apttus_Config2__AttributeValueId__r.APTS_Purchase_Value__c);
                        else 
                            purchaseValues.put(asset.id,0);
                    }
                }
            }
    
            for(Apttus_Config2__ProductOptionComponent__c option : 
                [Select Apttus_Config2__ComponentProductId__c,Apttus_Config2__ParentProductId__c, Apttus_Config2__ComponentProductId__r.name 
                from Apttus_Config2__ProductOptionComponent__c 
                where Apttus_Config2__RelationshipType__c='Option' 
                and Apttus_Config2__ProductOptionGroupId__c 
                IN (select id from Apttus_Config2__ProductOptionGroup__c where Apttus_Config2__ProductId__c IN :productids)])
            {
                if(productOptions.containskey(option.Apttus_Config2__ParentProductId__c))
                   productOptions.get(option.Apttus_Config2__ParentProductId__c).add(option.Apttus_Config2__ComponentProductId__c+APTS_CPQConstants.AT_THE_RATE+option.Apttus_Config2__ComponentProductId__r.name); 
                else
                    productOptions.put(option.Apttus_Config2__ParentProductId__c ,new List<String>{option.Apttus_Config2__ComponentProductId__c+APTS_CPQConstants.AT_THE_RATE+option.Apttus_Config2__ComponentProductId__r.name});
                   // System.debug('Lavanya PRODUCTOPTIONS'+productOptions);
                optionalPenalty.put(option.Apttus_Config2__ComponentProductId__c,0);
                optionalDiscount.put(option.Apttus_Config2__ComponentProductId__c,0);
                productOptionMap.put(option.Apttus_Config2__ComponentProductId__c,option.Apttus_Config2__ParentProductId__c);
                
                //  System.debug('Lavanya productOptionMap'+productOptionMap);
            }

            billings  =  [select Apttus_Billing__AssetLineItemId__r.Apttus_Config2__ListPrice__c,
                                 Apttus_Billing__AssetLineItemId__r.APTS_Type_Of_Contract__c,
                                 Apttus_Billing__AssetLineItemId__r.Apttus_Config2__Quantity__c,
                                 Apttus_Billing__AssetLineItemId__r.Apttus_Config2__PriceListItemId__r.Apttus_Config2__ListPrice__c,
                                 Apttus_Billing__AssetLineItemId__r.Apttus_Config2__AssetStatus__c,
                                 Apttus_Billing__AssetLineItemId__c,Apttus_Billing__PeriodStartDate__c, 
                                 Apttus_Billing__PeriodEndDate__c, 
                                 Apttus_Billing__FeeAmount__c,Apttus_Billing__Status__c 
                        from Apttus_Billing__BillingSchedule__c 
                        where (Apttus_Billing__Status__c='Pending Billing' or Apttus_Billing__Status__c='Invoiced') 
                        and (Apttus_Billing__AssetLineItemId__c IN :selectedAssets OR Apttus_Billing__AssetLineItemId__c IN :optionAssets)];
    
            for(Apttus_Billing__BillingSchedule__c billing : billings)
            {
                if(totalBilling.containskey(billing.Apttus_Billing__AssetLineItemId__c)) 
                {
                    totalBilling.put(billing.Apttus_Billing__AssetLineItemId__c,totalBilling.get(billing.Apttus_Billing__AssetLineItemId__c)+billing.Apttus_Billing__FeeAmount__c);
                    //System.debug('IF Billing'+totalBilling);
                }
                else 
                {
                    totalBilling.put(billing.Apttus_Billing__AssetLineItemId__c,billing.Apttus_Billing__FeeAmount__c);
                    // System.debug('ELSE Billing'+totalBilling);
                }
            }
        }

        catch(Exception e)
        {
            Apexpages.addMessage(new apexpages.message(apexpages.severity.error,APTS_CPQConstants.EXCEPTIONMESSAGE));
            APTS_CustomLogging.createErrorLog(e.getTypeName(), APTS_CPQConstants.APEX_NAME, e.getStackTraceString()+e.getMessage() ,APTS_CPQConstants.PENALTY, ApexPages.currentPage().getParameters().get(APTS_CPQConstants.PRD_CONFIG1),APTS_CPQConstants.CPQ,false,true,APTS_CPQConstants.ABHI_MAIL,true);
        }
    }

/*
public APTS_PenaltyCalculationCtrl()
{
}*/

public void calculate()
{
    try
    {
        //System.debug('SelectedAssets(' + selectedAssets.size() + '): ' + selectedAssets);
        //System.debug('OptionAssets(' + optionAssets.size() + '): ' + optionAssets);
        //System.debug('ProductAssets(' + ProductAssets.size() + '): ' + ProductAssets);
        //System.debug('ProductOptionAssets(' + productOptionAssets.size() + '): ' + productOptionAssets);
        calculateClicked = false;
        for(Apttus_Config2__AssetLineItem__c asset : selectedAssets )
        {
            //totalBilling.put(asset.id,0);
            alreadyInvoiced.put(asset.id,0);
            pending.put(asset.id,0);
            refund.put(asset.id,0);
            credits.put(asset.id,0);
            remainingTerm.put(asset.id,0);
        }
    
        for(Apttus_Config2__AssetLineItem__c asset : optionAssets)
        {
            //totalBilling.put(asset.id,0);
            alreadyInvoiced.put(asset.id,0);
            pending.put(asset.id,0);
            refund.put(asset.id,0);
            credits.put(asset.id,0);
            remainingTerm.put(asset.id,0);
        }

        // If Start date is less than termi...pending or invoiced
        // If end date is 
        for(Apttus_Billing__BillingSchedule__c billing : billings)
        {
            if(String.isNotBlank(billing.Apttus_Billing__AssetLineItemId__r.APTS_Type_Of_Contract__c) && 
                !billing.Apttus_Billing__AssetLineItemId__r.APTS_Type_Of_Contract__c.equals(APTS_CPQConstants.LABEL_FREEONLOAN) && 
                !billing.Apttus_Billing__AssetLineItemId__r.APTS_Type_Of_Contract__c.equals(APTS_CPQConstants.CONSUMPTION))
            { //System.debug('FOL n CON'+billing.Apttus_Billing__AssetLineItemId__r.APTS_Type_Of_Contract__c);
                // The objective is only to calculate for options, not headers
                if (!productOptionAssets.containsKey(billing.Apttus_Billing__AssetLineItemId__c))
                {
                    if(billing.Apttus_Billing__AssetLineItemId__r.Apttus_Config2__AssetStatus__c.equals(APTS_CPQConstants.LABEL_ACTIVATED))
                    {            
                        if(billing.Apttus_Billing__Status__c.equals(APTS_CPQConstants.LABEL_INVOICED)) 
                        {
                            if(alreadyInvoiced.containskey(billing.Apttus_Billing__AssetLineItemId__c))  
                                alreadyInvoiced.put(billing.Apttus_Billing__AssetLineItemId__c,alreadyInvoiced.get(billing.Apttus_Billing__AssetLineItemId__c)+billing.Apttus_Billing__FeeAmount__c);
                            else 
                                alreadyInvoiced.put(billing.Apttus_Billing__AssetLineItemId__c,billing.Apttus_Billing__FeeAmount__c);
                        }
                    
                        if(billing.Apttus_Billing__Status__c.equals(APTS_CPQConstants.LABEL_PENDINGBILLING) && 
                            billing.Apttus_Billing__PeriodStartDate__c >= terminationDate) 
                        {
                            //System.debug('Asset: ' + billing.Apttus_Billing__AssetLineItemId__c);
                            //System.debug('Pending: ' + pending.get(billing.Apttus_Billing__AssetLineItemId__c));
                            //System.debug('Fee Amount: ' + billing.Apttus_Billing__FeeAmount__c);
                            //System.debug('New pending: ' + (pending.get(billing.Apttus_Billing__AssetLineItemId__c)+billing.Apttus_Billing__FeeAmount__c));
                            if(pending.containskey(billing.Apttus_Billing__AssetLineItemId__c))  
                                pending.put(billing.Apttus_Billing__AssetLineItemId__c,pending.get(billing.Apttus_Billing__AssetLineItemId__c)+billing.Apttus_Billing__FeeAmount__c);
                            else 
                                pending.put(billing.Apttus_Billing__AssetLineItemId__c,billing.Apttus_Billing__FeeAmount__c);
                        }
                    }

                    if(billing.Apttus_Billing__AssetLineItemId__r.Apttus_Config2__AssetStatus__c.equals(APTS_CPQConstants.LABEL_RENEWED))
                    {        
                        if(billing.Apttus_Billing__PeriodStartDate__c <= terminationDate && billing.Apttus_Billing__PeriodEndDate__c >= terminationDate)
                        {
                            if(billing.Apttus_Billing__Status__c.equals(APTS_CPQConstants.LABEL_INVOICED)) 
                            {
                                if(pending.containskey(billing.Apttus_Billing__AssetLineItemId__c)) 
                                    pending.put(billing.Apttus_Billing__AssetLineItemId__c,pending.get(billing.Apttus_Billing__AssetLineItemId__c)+(-1)*billing.Apttus_Billing__FeeAmount__c);
                                else 
                                    pending.put(billing.Apttus_Billing__AssetLineItemId__c,(-1)*billing.Apttus_Billing__FeeAmount__c);
                            }
                        }
                        else if(billing.Apttus_Billing__Status__c.equals(APTS_CPQConstants.LABEL_INVOICED)) 
                        {
                            if(alreadyInvoiced.containskey(billing.Apttus_Billing__AssetLineItemId__c))  
                                alreadyInvoiced.put(billing.Apttus_Billing__AssetLineItemId__c,alreadyInvoiced.get(billing.Apttus_Billing__AssetLineItemId__c)+billing.Apttus_Billing__FeeAmount__c);
                            else 
                                alreadyInvoiced.put(billing.Apttus_Billing__AssetLineItemId__c,billing.Apttus_Billing__FeeAmount__c);
                        }
                    }
                }
            }
            else
            {
                if(billing.Apttus_Billing__Status__c.equals(APTS_CPQConstants.LABEL_PENDINGBILLING) && billing.Apttus_Billing__PeriodStartDate__c >= terminationDate) 
                {
                    if(remainingTerm.containskey(billing.Apttus_Billing__AssetLineItemId__c)) 
                    { 
                        remainingTerm.put(billing.Apttus_Billing__AssetLineItemId__c,remainingTerm.get(billing.Apttus_Billing__AssetLineItemId__c)+1);
                        //System.debug('IF Remaining Term'+remainingTerm);
                    }
                    else {
                        remainingTerm.put(billing.Apttus_Billing__AssetLineItemId__c,1);
                        //System.debug('Else Remaining Term'+remainingTerm);
                    }}
                    //remainingTerm.put(asset.id,1);
                }
                //pending.put(billing.Apttus_Billing__AssetLineItemId__c,billing.Apttus_Billing__AssetLineItemId__r.Apttus_Config2__Quantity__c*billing.Apttus_Billing__AssetLineItemId__r.Apttus_Config2__ListPrice__c);
            }
        
        //System.debug('Pending at the end of billing iteration:' + pending);

        for(Apttus_Config2__AssetLineItem__c asset : selectedAssets )
        {
            if (String.isNotBlank(asset.APTS_Type_Of_Contract__c) && 
                (asset.APTS_Type_Of_Contract__c.equals(APTS_CPQConstants.LABEL_FREEONLOAN) || 
                    asset.APTS_Type_Of_Contract__c.equals(APTS_CPQConstants.CONSUMPTION)))
            {
                pending.put(asset.id,Double.valueOf(asset.Apttus_Config2__Quantity__c*asset.Apttus_Config2__ListPrice__c*remainingTerm.get(asset.id)));
            }    
        }
        //System.debug('Pending at the end of selectedAssets iteration:' + pending);
    
        for(Apttus_Config2__AssetLineItem__c asset : optionAssets)
        {
            if(String.isNotBlank(asset.APTS_Type_Of_Contract__c) && 
                (asset.APTS_Type_Of_Contract__c.equals(APTS_CPQConstants.LABEL_FREEONLOAN) || 
                    asset.APTS_Type_Of_Contract__c.equals(APTS_CPQConstants.CONSUMPTION)))
            {    
                pending.put(asset.id,Double.valueOf(asset.Apttus_Config2__Quantity__c*asset.Apttus_Config2__ListPrice__c*remainingTerm.get(asset.id)));
            }
    
        }
        //System.debug('Pending at the end of optionAssets iteration:' + pending);


        for(Apttus_Config2__AssetLineItem__c asset : selectedAssets )
        {
            credits.put( asset.id, pending.get(asset.id) + additionalPenalty.get(asset.id) - additionalDiscount.get(asset.id));
        }
        //System.debug('Credits at the end of selectedAssets iteration:' + credits);        
    
        for(Apttus_Config2__AssetLineItem__c asset : optionAssets)
        {
            if(additionalDiscount.get(asset.id)==0 && remainsjdecust &&!asset.Apttus_Config2__AssetStatus__c.equals(APTS_CPQConstants.LABEL_RENEWED)) 
                additionalDiscount.put(asset.id,Double.ValueOf((pending.get(asset.id) + additionalPenalty.get(asset.id))*(0.25) ));
            credits.put( asset.id, pending.get(asset.id) + additionalPenalty.get(asset.id) - additionalDiscount.get(asset.id));
        }
        //System.debug('Credits at the end of optionAssets iteration:' + credits);        
    
        for(Id i : productOptionAssets.keyset())
        {   
            Decimal pendi = pending.get(i);
            Decimal penalty = 0;
            Decimal discount= 0;
            Decimal credit = pending.get(i);
        
            for(Apttus_Config2__AssetLineItem__c asset : productOptionAssets.get(i))
            {
                pendi += pending.get(asset.id);
                penalty += additionalPenalty.get(asset.id);
                discount += additionalDiscount.get(asset.id);
                credit += pending.get(asset.id) + additionalPenalty.get(asset.id) - additionalDiscount.get(asset.id);
            }
        
            pending.put( i,pendi);
            additionalPenalty.put( i,penalty);
            additionalDiscount.put(i,discount);
            credits.put(i,credit);
            //System.debug('Pending at the end of productOptionAssets iteration:' + pending);
        //System.debug('Credits at the end of productOptionAssets iteration:' + credits);        
    
        }
}

    catch(Exception e)
    {
        Apexpages.addMessage(new apexpages.message(apexpages.severity.error,APTS_CPQConstants.EXCEPTIONMESSAGE));
        APTS_CustomLogging.createErrorLog(e.getTypeName(), APTS_CPQConstants.APEX_NAME, e.getStackTraceString()+e.getMessage() ,APTS_CPQConstants.PENALTY, ApexPages.currentPage().getParameters().get(APTS_CPQConstants.PRD_CONFIG1),APTS_CPQConstants.CPQ,false,true,APTS_CPQConstants.ABHI_MAIL,true);
    }    
}

        public PageReference confirm()
        {
        try
        {
        List<Apttus_Config2__LineItem__c> lineItemstobeInserted = new List<Apttus_Config2__LineItem__c>();
        List <Apttus_CPQApi.CPQ.SelectedProductDO> selectedProdDOList = new List <Apttus_CPQApi.CPQ.SelectedProductDO>();
        
        //Apttus__AgreementLineItem__c tempagl= [Select id from Apttus__AgreementLineItem__c limit 1][0];
        Id tempagId= ApexPages.currentPage().getParameters().get(APTS_CPQConstants.AGR_ID);//[Select id from Apttus__APTS_Agreement__c limit 1][0];
        Apttus_Config2__ProductConfiguration__c tempconfig= prodconfig;//[Select id from Apttus_Config2__ProductConfiguration__c limit 1][0];
        for(Apttus_Config2__AssetLineItem__c asset : selectedAssets )
        {
        //Agreement_Line_Item__c=asset.Apttus_CMConfig__AgreementLineItemId__c
        /*
        Id tempaglId;
        if(asset.Apttus_CMConfig__AgreementLineItemId__c!=null) tempaglId  = asset.Apttus_CMConfig__AgreementLineItemId__c;
        else tempaglId = tempagl.id;
        
        
        Id tempagId;
        if(asset.Apttus_CMConfig__AgreementId__c!=null) tempagId  = asset.Apttus_CMConfig__AgreementId__c;
        else tempagId = tempag.id;
        */
        
        //Apttus_Config2__ConfigurationId__c
        //lineItemstobeInserted.add(new Apttus_Config2__LineItem__c(Apttus_Config2__AssetQuantity__c=asset.Apttus_Config2__Quantity__c,Apttus_Config2__ProductId__c=asset.Apttus_Config2__ProductId__c,Apttus_Config2__ConfigurationId__c=tempconfig.id,CurrencyIsoCode='EUR',Apttus_Config2__LineNumber__c=1,Apttus_Config2__ItemSequence__c=1,APTS_Agreement__c=tempagId ,Apttus_Config2__LineStatus__c='Cancelled',Apttus_Config2__NetPrice__c=credits.get(asset.id),Apttus_Config2__BillToAccountId__c = asset.Apttus_Config2__BillToAccountId__c,Apttus_Config2__ShipToAccountId__c = asset.Apttus_Config2__ShipToAccountId__c,Apttus_Config2__Description__c = asset.Apttus_Config2__Description__c,Apttus_Config2__StartDate__c = asset.Apttus_Config2__StartDate__c,Apttus_Config2__EndDate__c = terminationdate,Apttus_Config2__AssetLineItemId__c = asset.id,Apttus_Config2__PriceListId__c = asset.Apttus_Config2__PriceListId__c,Apttus_Config2__PriceListItemId__c = asset.Apttus_Config2__PriceListItemId__c,Apttus_Config2__ChargeType__c = asset.Apttus_Config2__ChargeType__c,Apttus_Config2__PriceType__c = asset.Apttus_Config2__PriceType__c,Apttus_Config2__Frequency__c = asset.Apttus_Config2__Frequency__c,Apttus_Config2__ListPrice__c = asset.Apttus_Config2__ListPrice__c,Apttus_Config2__BasePrice__c = asset.Apttus_Config2__BasePrice__c,Apttus_Config2__ExtendedPrice__c = asset.Apttus_Config2__ExtendedPrice__c));
        Apttus_CPQApi.CPQ.SelectedProductDO selProdDO = new Apttus_CPQApi.CPQ.SelectedProductDO();
        selProdDO.ProductID = asset.Apttus_Config2__ProductId__c;
        selProdDO.StartDate = asset.Apttus_Config2__StartDate__c;
        selProdDO.EndDate = terminationdate;
        selProdDO.CustomFields = new List<String>{APTS_CPQConstants.NET_PRICE};
        selProdDO.CustomData = new Apttus_Config2__LineItem__c(Apttus_Config2__NetPrice__c=credits.get(asset.id));  
        selectedProdDOList.add(selProdDO);
        }
        
        Map<String,Decimal> optionprices = new Map<String,Decimal>();
        for(Apttus_Config2__AssetLineItem__c asset : optionAssets)
        {
        //Agreement_Line_Item__c=asset.Apttus_CMConfig__AgreementLineItemId__c
        optionprices.put(String.valueOf(asset.Apttus_Config2__ProductId__c)+String.valueOf(asset.Apttus_Config2__OptionId__c),credits.get(asset.id));
             
        /*
        Id tempaglId;
        if(asset.Apttus_CMConfig__AgreementLineItemId__c!=null) tempaglId  = asset.Apttus_CMConfig__AgreementLineItemId__c;
        else tempaglId = tempagl.id;
        
        
        Id tempagId;
        if(asset.Apttus_CMConfig__AgreementId__c!=null) tempagId  = asset.Apttus_CMConfig__AgreementId__c;
        else tempagId = tempag.id;
        */
        
        //Apttus_Config2__ConfigurationId__cApttus_Config2__Quantity__c = asset.Apttus_Config2__Quantity__c,
        
        
        //lineItemstobeInserted.add(new Apttus_Config2__LineItem__c(Apttus_Config2__AssetQuantity__c=asset.Apttus_Config2__Quantity__c,Apttus_Config2__LineType__c='Option',Apttus_Config2__ProductId__c=asset.Apttus_Config2__ProductId__c,Apttus_Config2__OptionId__c=asset.Apttus_Config2__OptionId__c,Apttus_Config2__ConfigurationId__c=tempconfig.id,CurrencyIsoCode='EUR',Apttus_Config2__LineNumber__c=1,Apttus_Config2__ItemSequence__c=1,APTS_Agreement__c=tempagId ,Apttus_Config2__LineStatus__c='Cancelled',Apttus_Config2__NetPrice__c=credits.get(asset.id),Apttus_Config2__BillToAccountId__c = asset.Apttus_Config2__BillToAccountId__c,Apttus_Config2__ShipToAccountId__c = asset.Apttus_Config2__ShipToAccountId__c,Apttus_Config2__Description__c = asset.Apttus_Config2__Description__c,Apttus_Config2__StartDate__c = asset.Apttus_Config2__StartDate__c,Apttus_Config2__EndDate__c = terminationdate,Apttus_Config2__AssetLineItemId__c = asset.id,Apttus_Config2__PriceListId__c = asset.Apttus_Config2__PriceListId__c,Apttus_Config2__PriceListItemId__c = asset.Apttus_Config2__PriceListItemId__c,Apttus_Config2__ChargeType__c = asset.Apttus_Config2__ChargeType__c,Apttus_Config2__PriceType__c = asset.Apttus_Config2__PriceType__c,Apttus_Config2__Frequency__c = asset.Apttus_Config2__Frequency__c,Apttus_Config2__ListPrice__c = asset.Apttus_Config2__ListPrice__c,Apttus_Config2__BasePrice__c = asset.Apttus_Config2__BasePrice__c,Apttus_Config2__ExtendedPrice__c = asset.Apttus_Config2__ExtendedPrice__c));
        
       /* Apttus_CPQApi.CPQ.SelectedProductDO selProdDO = new Apttus_CPQApi.CPQ.SelectedProductDO();
        selProdDO.ProductID = asset.Apttus_Config2__ProductId__c;
        selProdDO.StartDate = asset.Apttus_Config2__StartDate__c;
        selProdDO.EndDate = terminationdate;
        selProdDO.CustomFields = new List<String>{'Apttus_Config2__NetPrice__c'};
        selProdDO.CustomData = new Apttus_Config2__LineItem__c(Apttus_Config2__NetPrice__c=credits.get(asset.id));  
        selectedProdDOList.add(selProdDO);*/
        }
        
        
       // insert lineItemstobeInserted;
       
      
        
        List<id> asids = new List<Id>();
        for(Apttus_Config2__AssetLineItem__c  ass : nonRecurringAssets)
        {
            asids.add(ass.id);
        }
        
        List<id> recasids = new List<Id>();
        for(Apttus_Config2__AssetLineItem__c  nonass : selectedAssets)
        {
            recasids.add(nonass.id);
        }
        recasids.addAll(asids);

        
       /* Apttus_Config2.CPQStruct.CancelAssetsRequestDO request = new Apttus_Config2.CPQStruct.CancelAssetsRequestDO();
        request.CancelDate = terminationDate;
        request.AssetIds = asids;
        request.CartId = tempconfig.id;
        
        Apttus_Config2.CPQStruct.CancelAssetsResponseDO response = Apttus_Config2.AssetService.cancelAssets(request);
        
        Apttus_Config2.CPQStruct.CancelAssetsRequestDO request = new Apttus_Config2.CPQStruct.CancelAssetsRequestDO();
        request.CancelDate = terminationDate;
        system.debug('+++shahul++++'+recIds);
        request.AssetIds = recIds;
        request.CartId = tempconfig.id;
        
        Apttus_Config2.CPQStruct.CancelAssetsResponseDO response1 = Apttus_Config2.AssetService.cancelAssets(request);
        */
        APTS_OrderUtils OUtls=new APTS_OrderUtils();
        Map<Id, Apttus_Config2__LineItem__c> termiMap = new Map<Id, Apttus_Config2__LineItem__c>();
          //if(!Test.isRunningTest())  APTS_OrderUtils.cancelAssets(tempconfig.Id,recIds);
          // Added by Abhishek to Call Utils Method
        //System.debug('tempconfig.Id==========>'+tempconfig.Id);
        //System.debug('recIds==========>'+recIds);
        //System.debug('terminationdate==========>'+terminationdate);
        APTS_PenaltyUtils.cancelAssets(tempconfig.Id,recIds,terminationdate);
        //APTS_OrderUtils.cancelAssets(tempconfig.Id,recasids);
        
        Map<Id,String> attributesMissingTypes = new Map<Id,String>();
        List<Apttus_Config2__LineItem__c > itemstoupdate = new List<Apttus_Config2__LineItem__c >();
        
        //for()
        //SYstem.debug('**TermiMap'+termiMap );
        for(Apttus_Config2__LineItem__c lin:[Select APTS_Type_of_contract__c,Apttus_Config2__LineType__c,Apttus_Config2__AssetLineItemId__c,Apttus_Config2__AttributeValueId__r.APTS_Type_of_contract__c,Apttus_Config2__LineStatus__c,Apttus_Config2__ProductId__c,Apttus_Config2__OptionId__c,Apttus_Config2__NetPrice__c,Apttus_Config2__LineNumber__c from Apttus_Config2__LineItem__c where Id in :termiMap.values()])//Apttus_Config2__LineNumber__c IN :response1.LineNumbers and Apttus_Config2__ConfigurationId__c =:prodConfig.id]) 
        {
        //lin.Apttus_Config2__LineStatus__c='Cancelled';
        
                //System.debug('***attr'+productAssets.get(lin.Apttus_Config2__ProductId__c).APTS_Type_of_contract__c+productAssets.get(lin.Apttus_Config2__ProductId__c)+lin.APTS_Type_of_contract__c);
        //System.debug('***attr'+String.isBlank(lin.Apttus_Config2__AttributeValueId__r.APTS_Type_of_contract__c)+String.isNotBlank(productAssets.get(lin.Apttus_Config2__ProductId__c).APTS_Type_of_contract__c));

        if(String.isBlank(lin.Apttus_Config2__AttributeValueId__r.APTS_Type_of_contract__c) && String.isNotBlank(productAssets.get(lin.Apttus_Config2__ProductId__c).APTS_Type_of_contract__c)) 
        {
        //System.debug('**insideattr'+lin.Apttus_Config2__AttributeValueId__c);
        attributesMissingTypes.put(lin.Apttus_Config2__AttributeValueId__c,productAssets.get(lin.Apttus_Config2__ProductId__c).APTS_Type_of_contract__c);
        }
        Decimal price = 0;
        if(optionprices.get(String.valueOf(lin.Apttus_Config2__ProductId__c)+String.valueOf(lin.Apttus_Config2__OptionId__c))!=null) price = optionprices.get(String.valueOf(lin.Apttus_Config2__ProductId__c)+String.valueOf(lin.Apttus_Config2__OptionId__c));
        //System.debug('**option Price'+price+credits.get(lin.Apttus_Config2__AssetLineItemId__c));
        if(!String.isBlank(lin.Apttus_Config2__LineType__c) && !lin.Apttus_Config2__LineType__c.equals(APTS_CPQConstants.LABEL_OPTION)) lin.Apttus_Config2__BasePriceOverride__c= credits.get(lin.Apttus_Config2__AssetLineItemId__c);   //lin.Apttus_Config2__BasePriceOverride__c= credits.get(lin.Apttus_Config2__AssetLineItemId__c);
        if(!String.isBlank(lin.Apttus_Config2__LineType__c) && lin.Apttus_Config2__LineType__c.equals(APTS_CPQConstants.LABEL_OPTION))  lin.Apttus_Config2__BasePriceOverride__c= price;//lin.Apttus_Config2__AdjustmentAmount__c = price;  
        //lin.Apttus_Config2__BasePriceOverride__c= price;//optionprices.get(String.valueOf(lin.Apttus_Config2__ProductId__c)+String.valueOf(lin.Apttus_Config2__OptionId__c));
        //lin.Apttus_Config2__AdjustmentType__c = 'Price Override';
        //lin.Apttus_Config2__NetPrice__c = 0;
        lin.Apttus_Config2__PricingStatus__c = APTS_CPQConstants.LABEL_PRICING_PENDING;
        itemstoupdate.add(lin);
        }
        String LINEITEMUPDATE = 'Apttus_Config2__LineItem__c';
        DescribeSObjectResult objResultPROD = APTS_OTCUtil.getsObjectAccess(LINEITEMUPDATE);
        if(objResultPROD != null &&  objResultPROD.isUpdateable())
        {
        Database.update(itemstoupdate);
        }
        //System.debug('**attrkeys'+attributesMissingTypes.keyset());
        
        List<Apttus_Config2__ProductAttributeValue__c > finalAttribitestoUpdate = new List<Apttus_Config2__ProductAttributeValue__c >(); 
        for(Apttus_Config2__ProductAttributeValue__c prodattr :[select APTS_Type_of_contract__c from Apttus_Config2__ProductAttributeValue__c where ID IN :attributesMissingTypes.keyset()])
        {
        
        prodattr.APTS_Type_of_contract__c  = attributesMissingTypes.get(prodattr.id);
        finalAttribitestoUpdate.add(prodattr);
        }
        String PRODUCTATTRIBUTEUPDATE = 'Apttus_Config2__ProductAttributeValue__c';
        DescribeSObjectResult objResultPROD1 = APTS_OTCUtil.getsObjectAccess(PRODUCTATTRIBUTEUPDATE);
        if(objResultPROD1 != null &&  objResultPROD1.isUpdateable())
        {
        database.update(finalAttribitestoUpdate);
        }
        //return null;
        //return new pageReference('/apex/Apttus_CMConfig__AgreementConfiguration?id='+tempagId+'&useDealOptimizer=true&flow=NGDefault');
        return goToCart();
        }
                catch(Exception e)
                {
                Apexpages.addMessage(new apexpages.message(apexpages.severity.error,APTS_CPQConstants.EX_OCCUR));
                APTS_CustomLogging.createErrorLog(e.getTypeName(), APTS_CPQConstants.APEX_NAME, e.getStackTraceString()+e.getMessage() ,APTS_CPQConstants.PENALTY, ApexPages.currentPage().getParameters().get(APTS_CPQConstants.PRD_CONFIG1),APTS_CPQConstants.CPQ,false,true,APTS_CPQConstants.ABHI_MAIL,true);
                return null;
                }
        //return new pageReference('/apex/Cart?cartStatus=Saved&oldConfigId='+prodConfig.Id+'&configRequestId='+ApexPages.currentPage().getParameters().get('configRequestId')+'&id='+prodConfig.Id+'&flow='+ApexPages.currentPage().getParameters().get(System.Label.APTS_Flow)+'&launchState=cart#/cart');
        }

public PageReference goToCart() {

        /*PageReference pageRef;

        Map<String, String> parameterMap = ApexPages.currentPage().getParameters();
        Id tempObjectId = parameterMap.get('configRequestId');

        List<String> filterList = new String[] {tempObjectId , ApexPages.currentPage().getParameters().get(System.Label.APTS_Id), ApexPages.currentPage().getParameters().get(System.Label.APTS_Flow)};
        String sCartPage = String.format(System.Label.APTS_Cart_Page_Url,filterList);

        pageRef = new PageReference(sCartPage);

        return pageRef;*/
        try
        {
         PageReference pg;
         pg = Page.Apttus_Config2__Cart;
         
         pg.getParameters().put(APTS_CPQConstants.LABEL_ID, prodconfig.id);
         pg.getParameters().put(APTS_CPQConstants.LABEL_Flow,ApexPages.currentPage().getParameters().get(System.Label.APTS_Flow));       
         pg.getParameters().put(APTS_CPQConstants.LABEL_CONFIGID, ApexPages.currentPage().getParameters().get(APTS_CPQConstants.LABEL_CONFIGID));  
         pg.getParameters().put(APTS_CPQConstants.LAUNCH_STATE, APTS_CPQConstants.CART);     
         return pg; 
         }
        catch(Exception e)
        {
        Apexpages.addMessage(new apexpages.message(apexpages.severity.error,APTS_CPQConstants.EX_OCCUR));
        APTS_CustomLogging.createErrorLog(e.getTypeName(), APTS_CPQConstants.APEX_NAME, e.getStackTraceString()+e.getMessage() ,APTS_CPQConstants.PENALTY, ApexPages.currentPage().getParameters().get(APTS_CPQConstants.PRD_CONFIG1),APTS_CPQConstants.CPQ,false,true,APTS_CPQConstants.ABHI_MAIL,true);
        return null;
        }
    }

public PageReference cancel()
    {
    try
    {
    pageReference pg = new pageReference('/apex/APTS_AssetInstalledProducts?id='+prodconfig.id+'&businessObjectId='+ApexPages.currentPage().getParameters().get('agrid'));
    
        pg.getParameters().put(APTS_CPQConstants.LABEL_Flow,ApexPages.currentPage().getParameters().get(System.Label.APTS_Flow));       
         pg.getParameters().put(APTS_CPQConstants.LABEL_CONFIGID, ApexPages.currentPage().getParameters().get(APTS_CPQConstants.LABEL_CONFIGID));  
    return pg;
    }
        catch(Exception e)
        {
        APTS_CustomLogging.createErrorLog(e.getTypeName(), APTS_CPQConstants.APEX_NAME, e.getStackTraceString()+e.getMessage() ,APTS_CPQConstants.PENALTY, ApexPages.currentPage().getParameters().get(APTS_CPQConstants.PRD_CONFIG1),APTS_CPQConstants.CPQ,false,true,APTS_CPQConstants.ABHI_MAIL,true);
        Apexpages.addMessage(new apexpages.message(apexpages.severity.error,APTS_CPQConstants.EXCEPTIONMESSAGE));
        return null;
        }
    
    }

}