public with sharing class APTS_Cercachedeletion {
public String ConfigId {get; set;}
public APTS_Cercachedeletion(APTS_CategoryBasedAdjustmentsCtrl controller){
        ConfigId=ApexPages.currentPage().getParameters().get('Id');

}
    public void Deletecercache(){
    system.debug('++shahulConfigId+++'+ConfigId);
    Map<String,String> Storedelmap=new map<String,String>();
        List<Apttus_Config2__LineItem__c> lstLI = 
        [
            SELECT Id,
            Apttus_Config2__ClassificationId__c,
            Apttus_Config2__ConfigurationId__r.Apttus_Config2__AccountId__c,
            APTS_Category_Level__c,
            APTS_Sub_Category__c,
            APTS_Sub_Sub_Category__c,
            Apttus_Config2__ProductId__c,
            (
                SELECT Id,
                Apttus_Config2__AdjustmentType__c,
                Apttus_Config2__AdjustmentAmount__c,
                Apttus_Config2__Bucket__c,
                Apttus_Config2__Type__c,
                Apttus_Config2__SubType__c,
                Apttus_Config2__AdjustmentAppliesTo__c,
                Apttus_Config2__LineItemId__c,
                Apttus_Config2__LineType__c,
                Apttus_Config2__AdjustmentUom__c,
                APTS_Category__c,
                APTS_Adjustment_Source__c,
                APTS_Sub_Category__c,
                APTS_Sub_Sub_Category__c,
                Apttus_Config2__LineItemId__r.Apttus_Config2__ConfigurationId__c,
                APTS_Start_Date__c,
                APTS_End_Date__c
                FROM Apttus_Config2__AdjustmentLineItems__r
            ),
            Apttus_Config2__ClassificationId__r.Apttus_Config2__HierarchyId__c,
            Apttus_Config2__ClassificationId__r.Apttus_Config2__PrimordialId__c,
            Apttus_Config2__ClassificationId__r.Apttus_Config2__AncestorId__c,
            Apttus_Config2__ClassificationId__r.Name,
            Apttus_Config2__PricingStatus__c
            FROM Apttus_Config2__LineItem__c
            WHERE Apttus_Config2__ConfigurationId__c = :ConfigId
            AND Apttus_Config2__LineType__c = 'Product/Service'
            AND Apttus_Config2__HasOptions__c = false
        ];
        list<CERDiscountCache__c> deleteCERCache=new list<CERDiscountCache__c>();
        list<String> deletefinalCERCache=new list<String>();
        list<Apttus_Config2__AdjustmentLineItem__c> ceradjdel=new list<Apttus_Config2__AdjustmentLineItem__c>();
        set<Id> ceradjdelline=new set<Id>();
        list<Apttus_Config2__LineItem__c> finalceradjdelline=new list<Apttus_Config2__LineItem__c>();

        delete deleteCERCache;
        CERDiscountCache__c cac;
        CERDiscountCache__c ret;
        if(!lstLI.isEmpty()){
            for(Apttus_Config2__LineItem__c currentLI : lstLI){
                if(!currentLI.Apttus_Config2__AdjustmentLineItems__r.isEmpty()){
                    for(Apttus_Config2__AdjustmentLineItem__c currentAdj : currentLI.Apttus_Config2__AdjustmentLineItems__r){
                        if(currentAdj.APTS_Adjustment_Source__c!='child'){
                            ceradjdel.add(currentAdj);
                            ceradjdelline.add(currentAdj.Apttus_Config2__LineItemId__c);
                        }
                      if(currentAdj.APTS_Adjustment_Source__c=='child'&&currentAdj.APTS_Category__c==null){
                    String tempstring=currentAdj.Apttus_Config2__LineItemId__c+currentAdj.Apttus_Config2__SubType__c+currentAdj.APTS_Adjustment_Source__c;
                    deletefinalCERCache.add(currentAdj.Apttus_Config2__LineItemId__c+currentAdj.Apttus_Config2__SubType__c+currentAdj.APTS_Adjustment_Source__c);
                    ret=new CERDiscountCache__c();ret=CERDiscountCache__c.getValues(tempstring);
                    system.debug('++tempstring++'+tempstring);
                    system.debug('++retshahul++'+ret);
                    cac=new CERDiscountCache__c(Name=currentAdj.Apttus_Config2__LineItemId__c+currentAdj.Apttus_Config2__SubType__c+currentAdj.APTS_Adjustment_Source__c,Sub_Type__c=currentAdj.Apttus_Config2__SubType__c,Name__c=currentAdj.Apttus_Config2__LineItemId__c,Configuration__c=currentAdj.Apttus_Config2__LineItemId__r.Apttus_Config2__ConfigurationId__c,Source__c=currentAdj.APTS_Adjustment_Source__c);
                    system.debug('++cacshahul++'+cac);
                    }
                }
                }
                
            }
            
            if(ceradjdel.size()>0){
            Delete ceradjdel;
            }
            for(Apttus_Config2__LineItem__c currentLI1 :[select id,Apttus_Config2__PricingSteps__c,Apttus_Config2__PricingStatus__c from Apttus_Config2__LineItem__c where Id IN:ceradjdelline]){
                currentLI1.Apttus_Config2__PricingStatus__c='Pending';
                currentLI1.Apttus_Config2__PricingSteps__c='';
                finalceradjdelline.add(currentLI1);
            }
            if(finalceradjdelline.size()>0){
            update finalceradjdelline;
            }
            deleteCERCache=[select id,Name__c,Sub_Type__c from CERDiscountCache__c where Configuration__c =:ConfigId AND Name IN:deletefinalCERCache];
            if(deleteCERCache.size()>0){
            Delete deleteCERCache;
            }
            system.debug('+++Sh+++'+deletefinalCERCache);
            system.debug('+++Sh+++'+deleteCERCache);
            system.debug('++cacshahul++'+cac);
        if(cac!=null&&ret==null){
        Insert cac;
        }
        }
        
    }

}