/*************************************************************
@Name: APTS_IndexedRepriceCtrl
@Author: Shahul Hameed
@CreateDate: 23-11-2020
@Description: DQ-2273
@UsedBy:Custom reprice to show the indexed price in agreement cart
******************************************************************/

public without sharing class APTS_IndexedRepriceCtrl{
        private String flow;
        private String configRequestId;
        private String configId;
        private boolean excludeTAX;
        private boolean excludeVAT;
        Static boolean RecurringAmendflag = true;
        Static boolean OneTimeAmendflag = true;
        public APTS_IndexedRepriceCtrl(Id configId){
        this.configId = configId;
        flow = null;
        configRequestId = null;
        excludeTAX=false;
        excludeVAT=false;
        Apttus_Config2__ProductConfiguration__c productConfig = new Apttus_Config2__ProductConfiguration__c();
        if(configId!=null)
        {
        productConfig = [select Apttus_CMConfig__AgreementId__r.APTS_Exclude_TAX__c,Apttus_CMConfig__AgreementId__r.APTS_Exclude_VAT__c,Apttus_CMConfig__AgreementId__c from Apttus_Config2__ProductConfiguration__c where id =: configId];
        if(productConfig.Apttus_CMConfig__AgreementId__c!=null){
            excludeTAX = productConfig.Apttus_CMConfig__AgreementId__r.APTS_Exclude_TAX__c;
            excludeVAT = productConfig.Apttus_CMConfig__AgreementId__r.APTS_Exclude_VAT__c;
        }
        }
    }
    public APTS_IndexedRepriceCtrl(ApexPages.StandardController stdController){
        this(ApexPages.currentPage().getParameters().get(APTS_CPQConstants.TAX_ID));
        flow = ApexPages.currentPage().getParameters().get(APTS_CPQConstants.FLOW);
        configRequestId = ApexPages.currentPage().getParameters().get(APTS_CPQConstants.CONFIG_REQUEST_ID);
    }
    public APTS_IndexedRepriceCtrl(){
        
    }
    
     public void IndexedRepriceAction(){
        IndexedReprice();
    }
    
    public PageReference IndexedReprice(){
    
             Map<Id,Apttus_Config2__LineItem__c> Lineamendindex=new Map<id,Apttus_Config2__LineItem__c>();
             list<Apttus_Config2__LineItem__c> Lineamendindexlist=new list<Apttus_Config2__LineItem__c>();
             list<Apttus_Config2__LineItem__c> Lineamendindexlistnew=new list<Apttus_Config2__LineItem__c>();
             Map<String,list<Apttus_Config2__LineItem__c>> modifiedMap = new Map<String,list<Apttus_Config2__LineItem__c>>(); 

             set<id> pmelist = new set<id>();

    
             for(Apttus_Config2__LineItem__c AmendLI:[select id,Apttus_Config2__StartDate__c,Apttus_Config2__EndDate__c,Apttus_Config2__ChargeType__c,Apttus_Config2__OptionId__c,Apttus_Config2__BasePrice__c,Apttus_Config2__SellingTerm__c,Apttus_Config2__PricingStatus__c,Apttus_Config2__PriceListItemId__r.Apttus_Config2__ListPrice__c,Apttus_Config2__ListPrice__c,Apttus_Config2__HasOptions__c,Apttus_Config2__PriceListItemId__r.Apttus_Config2__NumberOfMatrices__c from Apttus_Config2__LineItem__c where Apttus_Config2__ConfigurationId__c=:configId AND
                     Apttus_Config2__ConfigurationId__r.Apttus_Config2__AncestorId__c != null AND Apttus_Config2__ConfigurationId__r.Apttus_Config2__BusinessObjectType__c='Agreement' AND Apttus_Config2__ConfigurationId__r.Apttus_Config2__Status__c = 'New'
                ]){
                if(AmendLI.Apttus_Config2__PriceListItemId__r.Apttus_Config2__NumberOfMatrices__c==0&&AmendLI.Apttus_Config2__PricingStatus__c!='pending'&&AmendLI.Apttus_Config2__ListPrice__c!=AmendLI.Apttus_Config2__PriceListItemId__r.Apttus_Config2__ListPrice__c&&AmendLI.Apttus_Config2__HasOptions__c==false){AmendLI.Apttus_Config2__PricingStatus__c='pending';Lineamendindex.put(AmendLI.Id,AmendLI);}
                else if(AmendLI.Apttus_Config2__PriceListItemId__r.Apttus_Config2__NumberOfMatrices__c>0&&AmendLI.Apttus_Config2__PricingStatus__c!='pending'&&AmendLI.Apttus_Config2__HasOptions__c==false){pmelist.add(AmendLI.Apttus_Config2__PriceListItemId__c);Lineamendindexlistnew.add(AmendLI);modifiedMap.put(AmendLI.Apttus_Config2__OptionId__c+AmendLI.Apttus_Config2__ChargeType__c,Lineamendindexlistnew);}}
                for(Apttus_Config2__PriceMatrixEntry__c pmatrixEntry : [select id,
                                    Apttus_Config2__Dimension1Value__c,Apttus_Config2__PriceMatrixId__r.Apttus_Config2__PriceListItemId__r.Apttus_Config2__ChargeType__c,
                                    Apttus_Config2__AdjustmentAmount__c,
                                    Apttus_Config2__PriceMatrixId__r.Apttus_Config2__PriceListItemId__c,
                                    Apttus_Config2__PriceMatrixId__r.Apttus_Config2__PriceListItemId__r.Apttus_Config2__ProductId__c
                                    from Apttus_Config2__PriceMatrixEntry__c 
                                    where Apttus_Config2__PriceMatrixId__r.Apttus_Config2__PriceListItemId__c IN:pmelist order by Apttus_Config2__Sequence__c
                                    ]){
                                        if(!modifiedMap.isEmpty() && modifiedMap.get(pmatrixEntry.Apttus_Config2__PriceMatrixId__r.Apttus_Config2__PriceListItemId__r.Apttus_Config2__ProductId__c+pmatrixEntry.Apttus_Config2__PriceMatrixId__r.Apttus_Config2__PriceListItemId__r.Apttus_Config2__ChargeType__c)!=null){
                                        Lineamendindexlist=modifiedMap.get(pmatrixEntry.Apttus_Config2__PriceMatrixId__r.Apttus_Config2__PriceListItemId__r.Apttus_Config2__ProductId__c+pmatrixEntry.Apttus_Config2__PriceMatrixId__r.Apttus_Config2__PriceListItemId__r.Apttus_Config2__ChargeType__c);
                                    //System.debug('Range =>'+ pmatrixEntry.Apttus_Config2__Dimension1Value__c);
                                    //System.debug('the value 1 =>'+ pmatrixEntry.Apttus_Config2__AdjustmentAmount__c);
                                    
                                    for(Apttus_Config2__LineItem__c AmendLInew:Lineamendindexlist){AmendLInew.Apttus_Config2__SellingTerm__c=calculateSellingTerm(AmendLInew.Apttus_Config2__StartDate__c,AmendLInew.Apttus_Config2__EndDate__c).setScale(5);if(!Lineamendindex.containsKey(AmendLInew.Id)&&AmendLInew.Apttus_Config2__SellingTerm__c!=null&&(Decimal.valueOf(pmatrixEntry.Apttus_Config2__Dimension1Value__c) >= AmendLInew.Apttus_Config2__SellingTerm__c)){AmendLInew.Apttus_Config2__BasePrice__c=pmatrixEntry.Apttus_Config2__AdjustmentAmount__c;AmendLInew.Apttus_Config2__ListPrice__c=pmatrixEntry.Apttus_Config2__AdjustmentAmount__c;AmendLInew.Apttus_Config2__PricingStatus__c='pending';Lineamendindex.put(AmendLInew.Id,AmendLInew);
                                           // break;
                                    }

                                    
                                    }
                
         }
                                    }
         
        if(Lineamendindex.Values()!=null&&OneTimeAmendflag==true)
        {
        OneTimeAmendflag=false;
        Database.update(Lineamendindex.values());
        }
        APTS_OrderUtils.repriceCart(configId);
        APTS_OrderUtils.repriceCart(configId);
        //APTS_CustomUpdate cu=new APTS_CustomUpdate();
        //cu.updatePriceforCart1(configId);    
        return GoBacktoCart();

    
    }
    
    public list<Apttus_Config2__LineItem__c> IndexedRepriceapi(Set<Id> configId){
    
             Map<Id,Apttus_Config2__LineItem__c> Lineamendindex=new Map<id,Apttus_Config2__LineItem__c>();
             list<Apttus_Config2__LineItem__c> Lineamendindexlist=new list<Apttus_Config2__LineItem__c>();
             list<Apttus_Config2__LineItem__c> Lineamendindexlistnew=new list<Apttus_Config2__LineItem__c>();
             Map<String,list<Apttus_Config2__LineItem__c>> modifiedMap = new Map<String,list<Apttus_Config2__LineItem__c>>(); 
             //Set<String> uomString = new Set<String> ();
             set<id> pmelist = new set<id>();
             string tempString,tempStringnew;
            // Map<String, Decimal> uomOutput = new Map<String, Decimal> ();
            Map<String, Decimal> uomLIOutput = new Map<String, Decimal> ();
            Set<String> uomString = new Set<String> ();
            decimal uomLIFactor = 1.0;
            Set<String> uomLIString = new Set<String> ();
             Map<String, Decimal> uomOutput = new Map<String, Decimal> ();

    
              for(Apttus_Config2__LineItem__c AmendLI:[select id,Apttus_Config2__ProductId__r.ProductCode,Apttus_Config2__SellingUom__c,Apttus_Config2__PriceUom__c,Apttus_Config2__StartDate__c,Apttus_Config2__EndDate__c,Apttus_Config2__ChargeType__c,Apttus_Config2__OptionId__c,Apttus_Config2__BasePrice__c,Apttus_Config2__SellingTerm__c,Apttus_Config2__PricingStatus__c,Apttus_Config2__PriceListItemId__r.Apttus_Config2__ListPrice__c,Apttus_Config2__ListPrice__c,Apttus_Config2__HasOptions__c,Apttus_Config2__PriceListItemId__r.Apttus_Config2__NumberOfMatrices__c from Apttus_Config2__LineItem__c where Apttus_Config2__ConfigurationId__c IN:configId AND
                Apttus_Config2__ConfigurationId__r.Apttus_Config2__BusinessObjectType__c='Agreement'
                ]){
                if(AmendLI.Apttus_Config2__PriceListItemId__r.Apttus_Config2__NumberOfMatrices__c==0&&AmendLI.Apttus_Config2__ListPrice__c!=AmendLI.Apttus_Config2__PriceListItemId__r.Apttus_Config2__ListPrice__c&&AmendLI.Apttus_Config2__HasOptions__c==false){
                tempString = AmendLI.Apttus_Config2__ProductId__r.ProductCode;tempString+=';'+AmendLI.Apttus_Config2__PriceUom__c;tempString+=';'+AmendLI.Apttus_Config2__SellingUom__c;uomString.add(tempString);
                }
               uomOutput = APTS_UOMConversionUtils.getUOMConversions(uomString);
               system.debug('++++uomOutput'+uomOutput);

                }
             for(Apttus_Config2__LineItem__c AmendLI:[select id,Apttus_Config2__ProductId__r.ProductCode,Apttus_Config2__SellingUom__c,Apttus_Config2__PriceUom__c,Apttus_Config2__StartDate__c,Apttus_Config2__EndDate__c,Apttus_Config2__ChargeType__c,Apttus_Config2__OptionId__c,Apttus_Config2__BasePrice__c,Apttus_Config2__SellingTerm__c,Apttus_Config2__PricingStatus__c,Apttus_Config2__PriceListItemId__r.Apttus_Config2__ListPrice__c,Apttus_Config2__ListPrice__c,Apttus_Config2__HasOptions__c,Apttus_Config2__PriceListItemId__r.Apttus_Config2__NumberOfMatrices__c from Apttus_Config2__LineItem__c where Apttus_Config2__ConfigurationId__c IN:configId AND
                Apttus_Config2__ConfigurationId__r.Apttus_Config2__BusinessObjectType__c='Agreement'
                ]){
                if(AmendLI.Apttus_Config2__PriceListItemId__r.Apttus_Config2__NumberOfMatrices__c==0&&AmendLI.Apttus_Config2__ListPrice__c!=AmendLI.Apttus_Config2__PriceListItemId__r.Apttus_Config2__ListPrice__c&&AmendLI.Apttus_Config2__HasOptions__c==false){
                AmendLI.Apttus_Config2__PricingStatus__c='pending';tempStringnew = AmendLI.Apttus_Config2__ProductId__r.ProductCode;tempStringnew+=';' +AmendLI.Apttus_Config2__PriceUom__c;tempStringnew+=';' +AmendLI.Apttus_Config2__SellingUom__c;uomLIFactor = uomOutput.get(tempStringnew)!= null?uomOutput.get(tempStringnew):1;
                system.debug('++++uomLIFactor+++++'+uomLIFactor);
                if(uomLIFactor!=null&&AmendLI.Apttus_Config2__PriceListItemId__r.Apttus_Config2__ListPrice__c!=null){
                AmendLI.Apttus_Config2__BasePrice__c=AmendLI.Apttus_Config2__PriceListItemId__r.Apttus_Config2__ListPrice__c*uomLIFactor;}
                else{AmendLI.Apttus_Config2__BasePrice__c=AmendLI.Apttus_Config2__PriceListItemId__r.Apttus_Config2__ListPrice__c;}
                AmendLI.Apttus_Config2__ListPrice__c=AmendLI.Apttus_Config2__PriceListItemId__r.Apttus_Config2__ListPrice__c;
                Lineamendindex.put(AmendLI.Id,AmendLI);
            }
            else if(AmendLI.Apttus_Config2__PriceListItemId__r.Apttus_Config2__NumberOfMatrices__c>0&&AmendLI.Apttus_Config2__PricingStatus__c!='pending'&&AmendLI.Apttus_Config2__HasOptions__c==false){
                pmelist.add(AmendLI.Apttus_Config2__PriceListItemId__c);Lineamendindexlistnew.add(AmendLI);modifiedMap.put(AmendLI.Apttus_Config2__OptionId__c+AmendLI.Apttus_Config2__ChargeType__c,Lineamendindexlistnew);
                
            }
                }
                for(Apttus_Config2__PriceMatrixEntry__c pmatrixEntry : [select id,Apttus_Config2__Dimension1Value__c,Apttus_Config2__PriceMatrixId__r.Apttus_Config2__PriceListItemId__r.Apttus_Config2__ChargeType__c,Apttus_Config2__AdjustmentAmount__c,Apttus_Config2__PriceMatrixId__r.Apttus_Config2__PriceListItemId__c,Apttus_Config2__PriceMatrixId__r.Apttus_Config2__PriceListItemId__r.Apttus_Config2__ProductId__c from Apttus_Config2__PriceMatrixEntry__c where Apttus_Config2__PriceMatrixId__r.Apttus_Config2__PriceListItemId__c IN:pmelist order by Apttus_Config2__Sequence__c]){
                                        if(!modifiedMap.isEmpty() && modifiedMap.get(pmatrixEntry.Apttus_Config2__PriceMatrixId__r.Apttus_Config2__PriceListItemId__r.Apttus_Config2__ProductId__c+pmatrixEntry.Apttus_Config2__PriceMatrixId__r.Apttus_Config2__PriceListItemId__r.Apttus_Config2__ChargeType__c)!=null){
                                        Lineamendindexlist=modifiedMap.get(pmatrixEntry.Apttus_Config2__PriceMatrixId__r.Apttus_Config2__PriceListItemId__r.Apttus_Config2__ProductId__c+pmatrixEntry.Apttus_Config2__PriceMatrixId__r.Apttus_Config2__PriceListItemId__r.Apttus_Config2__ChargeType__c);
                                    //System.debug('Range =>'+ pmatrixEntry.Apttus_Config2__Dimension1Value__c);
                                    //System.debug('the value 1 =>'+ pmatrixEntry.Apttus_Config2__AdjustmentAmount__c);
                                    
                                    for(Apttus_Config2__LineItem__c AmendLInew:Lineamendindexlist){
                                        AmendLInew.Apttus_Config2__SellingTerm__c=calculateSellingTerm(AmendLInew.Apttus_Config2__StartDate__c,AmendLInew.Apttus_Config2__EndDate__c).setScale(5);
                                        if(!Lineamendindex.containsKey(AmendLInew.Id)&&AmendLInew.Apttus_Config2__SellingTerm__c!=null&&(Decimal.valueOf(pmatrixEntry.Apttus_Config2__Dimension1Value__c) >= AmendLInew.Apttus_Config2__SellingTerm__c)&&AmendLInew.Apttus_Config2__OptionId__c==pmatrixEntry.Apttus_Config2__PriceMatrixId__r.Apttus_Config2__PriceListItemId__r.Apttus_Config2__ProductId__c){
                                            AmendLInew.Apttus_Config2__BasePrice__c=pmatrixEntry.Apttus_Config2__AdjustmentAmount__c;AmendLInew.Apttus_Config2__ListPrice__c=pmatrixEntry.Apttus_Config2__AdjustmentAmount__c;AmendLInew.Apttus_Config2__PricingStatus__c='pending';Lineamendindex.put(AmendLInew.Id,AmendLInew);
                                           // break;
                                    }

                                    
                                    }
                
         }
                                    }
                                    system.debug('+++ShahulLineamendindex++++'+Lineamendindex);
         
        if(Lineamendindex.Values()!=null){
        return Lineamendindex.values();
        }
        else {
        return null;
        }
        //APTS_OrderUtils.repriceCart(configId);
        //APTS_OrderUtils.repriceCart(configId);
        //APTS_CustomUpdate cu=new APTS_CustomUpdate();
        //cu.updatePriceforCart1(configId);    
        //return GoBacktoCart();

    
    }
    public PageReference GoBacktoCart(){  
         PageReference pg;
         pg = Page.Apttus_Config2__Cart;
         pg.getParameters().put(APTS_CPQConstants.TAX_ID, configId);
         pg.getParameters().put(APTS_CPQConstants.FLOW,flow);       
         pg.getParameters().put(APTS_CPQConstants.CONFIG_REQUEST_ID, configRequestId);  
         pg.getParameters().put(APTS_CPQConstants.LAUNCH_STATE, APTS_CPQConstants.CART);     
         return pg; 
    }
    
       public static Decimal calculateSellingTerm(Date expectedStartDate,Date expectedEndDate){
       Decimal sellingTerm;
       //Calculate selling term 
       Integer startYear = expectedStartDate.year();
       Integer startMonth = expectedStartDate.Month();
       Integer startDay = expectedStartDate.Day();
       Integer startDaysInMonth = date.daysInMonth(startYear,startMonth);   
       Integer endYear = expectedEndDate.year();
       Integer endMonth = expectedEndDate.Month();
       Integer endDay = expectedEndDate.Day();
       Integer endDaysInMonth = date.daysInMonth(endYear,endMonth);                       
       Integer sellingMonths = expectedStartDate.monthsBetween(expectedEndDate)-1;
       Decimal sellingProratedStart = ((date.daysInMonth(startYear,startMonth)-startDay+1.00)*1.00)/(1.00*date.daysInMonth(startYear,startMonth));
       Decimal sellingProratedEnd = (endDay*1.00)/(1.00*date.daysInMonth(endYear,endMonth));
       Decimal CalculatedSellingTermMonth = sellingProratedStart+sellingMonths+sellingProratedEnd;
       //SellingTerm = CalculatedSellingTermMonth;                                  
       SellingTerm = CalculatedSellingTermMonth;
       System.debug('expectedEndDate===========>'+expectedEndDate);
       return sellingTerm;
    }
    }