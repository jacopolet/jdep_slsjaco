/*************************************************************
@Name: APTS_ConfigurationTriggerHandler
@Author: Galin Georgiev
@CreateDate: 19-12-2017
@Description: Configuration trigger handler
@UsedBy: Configuration trigger
******************************************************************/
//v100 07-02-2017 Galin Georgiev: Initial version.
//Comments in this format are mandatory for each change of code.
//Adding code comment example: v100++<< means start of changes and v100++>> means end of changes
//Removing code comment example: v100--<< means start of changes and v100-->> means end of changes
//Added Custom logging --> Sethukkarasi
// Added CPQ Flow(NGDefault Population Logic--Shahul
// v102 - 16-10-2018 - Sanjay Nair - Comment stamping of Agreement ID on Configuration for Orders - Defect 20303
// v103 - Def#21390 - Nikita Modi-Remove Add More Products button on MO and conditionally on SO/RSO
// v104 - CER Fixes - Delete Pending CER Records in case of the Agreeement Cart is abandoned or deleted
// v105 - Updated isDisabled scope from Private to Public 
// v106 27-mar-2019 Neev : setting flow field value to NGStandardOrder for RSO Order as PCB runs on FLOW logic.
// v107 08-Apr-2019 Akanksha : CR 2259 : Addition of new flow for Deinstall Order.
// v108 31-Dec-2019 Mahesh Chilaka : DFT2C - 2157, DQ - 533 : INC0148271 - P4 - error in shopping cart, Code optimized and fixed the defect in afterUpdate method.
// v109 30-Jan-2020 Shahul- DQ-1083 : Show Updated indexed List price in Amendment  Cart
// v110 13-Aug-2020 Manisha: DQ-2353: Modified the logic to update Configuration status on order.
/* APTS_ConfigurationTriggerHandler Body*/
public without sharing class APTS_ConfigurationTriggerHandler implements ITriggerHandler {
     
    //v105 ++ <<
    public static Boolean isTriggerDisabled = true;
    //v105 -- >>
    //v104 ++ <<
    private static final String AGREEMENT = 'Agreement';
    //v104 -->>
    public static boolean Amendflag = true;
    /* beforeInsert Body*/
    public void beforeInsert(List<SObject> newItems) {

        List<Apttus_Config2__ProductConfiguration__c> configurationList = (List<Apttus_Config2__ProductConfiguration__c>) newItems;

        Set<Id> orderIdSet = new Set<Id>();
        //initialization loop
        //try{
        for (Apttus_Config2__ProductConfiguration__c oConfiguration : configurationList) {
            if (oConfiguration.Apttus_Config2__OrderId__c != null) {
                orderIdSet.add(oConfiguration.Apttus_Config2__OrderId__c);
            }
        }
        /* }
            catch(Exception e)
              {
        APTS_CustomLogging.createErrorLog(e.getTypeName(), 'Apex', e.getStackTraceString() ,'Order', ApexPages.currentPage().getParameters().get(Label.APTS_Id),'OM',false,true, APTS_OrderConstants.APTS_EMAIL, true);
              } */
              
        Map<Id, Apttus_Config2__Order__c> idToOrderMap = new Map<Id, Apttus_Config2__Order__c>([SELECT APTS_Order_Type__c , APTS_Order_Sub_Type__c, APTS_Source_Order_Number__c, Apttus_CMConfig__AgreementId__c,Apttus_CMConfig__AgreementId__r.APTS_Order_Non_Contracted_Products__c FROM Apttus_Config2__Order__c WHERE Id IN :orderIdSet]);
        //main loop
        //try{
        for (Apttus_Config2__ProductConfiguration__c oConfiguration : configurationList) {

            if (oConfiguration.Apttus_Config2__OrderId__c != null) {
                 
                Apttus_Config2__Order__c oOrder = idToOrderMap.get(oConfiguration.Apttus_Config2__OrderId__c);
                if (oOrder.APTS_Order_Type__c == APTS_OrderConstants.STANDARD_ORDER) {
                    // v103 - Start
                    if(oOrder.Apttus_CMConfig__AgreementId__r.APTS_Order_Non_Contracted_Products__c == TRUE || oOrder.Apttus_CMConfig__AgreementId__c == null){
                        oConfiguration.APTS_Flow__c = APTS_OrderConstants.NGSTANDARD_ORDER;
                    }
                    else{
                        oConfiguration.APTS_Flow__c = APTS_OrderConstants.NGSTANDARD_ORDERWOC;
                    }
                    // v103 - End
                }
                //v107 ++ <<
                else if (oOrder.APTS_Order_Type__c == APTS_OrderConstants.MACHINE_ORDER && oOrder.APTS_Order_Sub_Type__c == APTS_OrderConstants.DE_INSTALLATION) {
                    oConfiguration.APTS_Flow__c = APTS_OrderConstants.NG_MACHINEDEINSTALLORDER;
                }//v107 ++ >>
                else if (oOrder.APTS_Order_Type__c == APTS_OrderConstants.MACHINE_ORDER) {
                    oConfiguration.APTS_Flow__c = APTS_OrderConstants.NG_MACHINEORDER;
                } else if (oOrder.APTS_Order_Type__c == APTS_OrderConstants.ORDER_TYPE_ROUTESALES || oOrder.APTS_Order_Type__c == APTS_OrderConstants.ORDER_TYPE_OPERATING){ //v106
                    //v106
                    oConfiguration.APTS_Flow__c = APTS_OrderConstants.NGSTANDARD_ORDER;
                }
               //Code Added for ABO CR - 2288 by Sofiya
        
                else if(oOrder.APTS_Order_Type__c == APTS_OrderConstants.ADMIN_ORDER)
                {
                    oConfiguration.APTS_Flow__c = APTS_OrderConstants.NG_ADMINORDER;
                }
             //Code Added for ABO CR - 2288 by Sofiya
            //v102 - start - comment stamping agreement id  
           // oConfiguration.Apttus_CMConfig__AgreementId__c = oOrder.Apttus_CMConfig__AgreementId__c;
            //v102 - end 
            }            
                        
            if(oConfiguration.Apttus_CMConfig__AgreementId__c!=null&& oConfiguration.Apttus_Config2__OrderId__c == null){
                oConfiguration.APTS_Flow__c = APTS_OrderConstants.NGDEFAULT;
            }
        }
           /* }
            catch(Exception e)
              {
        APTS_CustomLogging.createErrorLog(e.getTypeName(), 'Apex', e.getStackTraceString() ,'Order', ApexPages.currentPage().getParameters().get(Label.APTS_Id),'OM',false,true, APTS_OrderConstants.APTS_EMAIL, true);
              } */
    }
    /* afterInsert Body*/
    public void afterInsert(List<SObject> newList, Map<Id, SObject> newItems) {
          
    }
    /* beforeUpdate Body*/
    public void beforeUpdate(List<SObject> newList, Map<Id, SObject> newItems, List<SObject> oldList, Map<Id, SObject> oldItems) {

    }
    /* afterUpdate Body*/
    public void afterUpdate(List<SObject> newList, Map<Id, SObject> newItems, List<SObject> oldList, Map<Id, SObject> oldItems) {
    // v108 - START
        system.debug('++ShahultoDebug++');        
        list<CERDiscountCache__c> listCERDiscount = new list<CERDiscountCache__c>();
        list<string> lineItemlist = new list<string>();
        list<Apttus_Config2__LineItem__c> Linelist=new list<Apttus_Config2__LineItem__c>();
        list<Apttus_Config2__LineItem__c> Lineamendindexlist=new list<Apttus_Config2__LineItem__c>();
        list<Apttus_Config2__ProductConfiguration__c> Prodamendindexlist=new list<Apttus_Config2__ProductConfiguration__c>();
        list<Apttus_Config2__AdjustmentLineItem__c> adjlist=new list<Apttus_Config2__AdjustmentLineItem__c>();  
        list<CERDiscountCache__c> deleteCERCache = new list<CERDiscountCache__c>();
        Map<Id, Apttus_Config2__Order__c> idToOrderMap = new Map<Id, Apttus_Config2__Order__c>();   
        Map<Id, List<Apttus_Config2__LineItem__c>> configurationIdToLineItemListMap = new Map<Id, List<Apttus_Config2__LineItem__c>>();
        Map<String, Apttus_Config2__AdjustmentLineItem__c> mapCERDiscount = new Map<String, Apttus_Config2__AdjustmentLineItem__c>();
        Map<Id, Apttus_Config2__ProductConfiguration__c> idToConfigurationMap = (Map<Id, Apttus_Config2__ProductConfiguration__c>) newItems;
        CERDiscountCache__c cerRec = new CERDiscountCache__c();
        String formulaCERDiscount = '';
        
    try{
          
            for(Apttus_Config2__AdjustmentLineItem__c adjdel:[SELECT id,APTS_Category__c, Apttus_Config2__LineItemId__c,APTS_Adjustment_Source__c,
                                                                    Apttus_Config2__LineItemId__r.Apttus_Config2__ConfigurationId__r.Apttus_Config2__AncestorId__c,Apttus_Config2__SubType__c,Apttus_Config2__LineItemId__r.Apttus_Config2__ConfigurationId__r.Apttus_Config2__BusinessObjectType__c,Apttus_Config2__LineItemId__r.Apttus_Config2__ConfigurationId__r.Apttus_Config2__Status__c, Apttus_Config2__LineItemId__r.Apttus_Config2__ConfigurationId__c
                                                              FROM Apttus_Config2__AdjustmentLineItem__c 
                                                              WHERE Apttus_Config2__LineItemId__r.Apttus_Config2__ConfigurationId__c IN : newItems.keySet() AND
                                                                (
                                                                    (   APTS_Category__c = NULL AND APTS_Adjustment_Source__c = 'Child' AND 
                                                                        Apttus_Config2__LineItemId__r.Apttus_Config2__ConfigurationId__r.Apttus_Config2__AncestorId__c != null AND 
                                                                        Apttus_Config2__LineItemId__r.Apttus_Config2__ConfigurationId__r.Apttus_Config2__BusinessObjectType__c = 'Agreement' AND 
                                                                        Apttus_Config2__LineItemId__r.Apttus_Config2__ConfigurationId__r.Apttus_Config2__Status__c = 'New'
                                                                    ) 
                                                                    OR 
                                                                    (
                                                                        (Apttus_Config2__LineItemId__r.Apttus_Config2__ConfigurationId__r.Apttus_Config2__BusinessObjectType__c = 'Agreement' OR  
                                                                        Apttus_Config2__LineItemId__r.Apttus_Config2__ConfigurationId__r.Apttus_Config2__BusinessObjectType__c = 'Order') AND 
                                                                        Apttus_Config2__LineItemId__r.Apttus_Config2__ConfigurationId__r.Apttus_Config2__Status__c =: APTS_OrderConstants.FINALIZED
                                                                    )
                                                                ) ]){
                
                if(adjdel.APTS_Category__c == null && adjdel.APTS_Adjustment_Source__c == 'Child' && 
                    adjdel.Apttus_Config2__LineItemId__r.Apttus_Config2__ConfigurationId__r.Apttus_Config2__AncestorId__c != null && 
                    adjdel.Apttus_Config2__LineItemId__r.Apttus_Config2__ConfigurationId__r.Apttus_Config2__BusinessObjectType__c == 'Agreement' && 
                    adjdel.Apttus_Config2__LineItemId__r.Apttus_Config2__ConfigurationId__r.Apttus_Config2__Status__c == 'New'){
                        
                    formulaCERDiscount = adjdel.Apttus_Config2__LineItemId__c+adjdel.Apttus_Config2__SubType__c+adjdel.APTS_Adjustment_Source__c;
                    cerRec = CERDiscountCache__c.getValues(formulaCERDiscount);
                    if(!mapCERDiscount.containsKey(formulaCERDiscount) && cerRec == null){mapCERDiscount.put(formulaCERDiscount, adjdel);}
                }
                
                if((adjdel.Apttus_Config2__LineItemId__r.Apttus_Config2__ConfigurationId__r.Apttus_Config2__BusinessObjectType__c == 'Agreement' || 
                    adjdel.Apttus_Config2__LineItemId__r.Apttus_Config2__ConfigurationId__r.Apttus_Config2__BusinessObjectType__c =='Order') && 
                    adjdel.Apttus_Config2__LineItemId__r.Apttus_Config2__ConfigurationId__r.Apttus_Config2__Status__c == APTS_OrderConstants.FINALIZED){
                        
                    lineItemlist.add(adjdel.Apttus_Config2__LineItemId__c);
                }
            }
            for(String formulaAdjLineItem : mapCERDiscount.keyset()){
                
                Apttus_Config2__AdjustmentLineItem__c adjdel = mapCERDiscount.get(formulaAdjLineItem);CERDiscountCache__c recCER = new CERDiscountCache__c(Name=formulaAdjLineItem, Sub_Type__c = adjdel.Apttus_Config2__SubType__c, Name__c = adjdel.Apttus_Config2__LineItemId__c, Configuration__c = adjdel.Apttus_Config2__LineItemId__r.Apttus_Config2__ConfigurationId__c, Source__c = adjdel.APTS_Adjustment_Source__c);listCERDiscount.add(recCER);
                
            }

            deleteCERCache = [select id from CERDiscountCache__c where Name__c =: lineItemlist];
            if(!deleteCERCache.isEmpty()) { Delete deleteCERCache; }
            
            if(!listCERDiscount.isEmpty()){        
                insert listCERDiscount;
            }       
            

            //get the order details
            idToOrderMap = getOrderDetails(idToConfigurationMap.values());
            if (!idToOrderMap.isEmpty()) {              
              

                for (Apttus_Config2__LineItem__c olineItem : [SELECT Id, Apttus_Config2__ConfigurationId__c, APTS_Requested_Delivery_Date__c
                                                              FROM Apttus_Config2__LineItem__c
                                                              WHERE Apttus_Config2__ConfigurationId__c IN :idToConfigurationMap.keySet()]) {

                    List<Apttus_Config2__LineItem__c> liteItemList = configurationIdToLineItemListMap.get(olineItem.Apttus_Config2__ConfigurationId__c);
                    
                    if (liteItemList == null) {
                        liteItemList = new List<Apttus_Config2__LineItem__c>();
                        configurationIdToLineItemListMap.put(olineItem.Apttus_Config2__ConfigurationId__c, liteItemList);
                    }

                    liteItemList.add(olineItem);
                }
            }
          
          setOrderConfigurationStatus(idToConfigurationMap.values(), idToOrderMap, configurationIdToLineItemListMap, false);
          
            
           
       //v109 
       /* for(Apttus_Config2__LineItem__c AmendLI:[select id,Apttus_Config2__PricingStatus__c,Apttus_Config2__ConfigurationId__r.APTS_Amendment_Pricing__c,Apttus_Config2__PriceListItemId__r.Apttus_Config2__ListPrice__c,Apttus_Config2__ListPrice__c,Apttus_Config2__HasOptions__c from Apttus_Config2__LineItem__c where Apttus_Config2__ConfigurationId__c IN:newItems.keySet() AND
                ( Apttus_Config2__ConfigurationId__r.Apttus_Config2__AncestorId__c != null AND
                  Apttus_Config2__ConfigurationId__r.Apttus_Config2__BusinessObjectType__c = 'Agreement' AND
                  Apttus_Config2__ConfigurationId__r.Apttus_Config2__Status__c = 'New'
                )
        ]){
            if(AmendLI.Apttus_Config2__PricingStatus__c!='pending'&&AmendLI.Apttus_Config2__ListPrice__c!=AmendLI.Apttus_Config2__PriceListItemId__r.Apttus_Config2__ListPrice__c&&AmendLI.Apttus_Config2__HasOptions__c==false&&AmendLI.Apttus_Config2__ConfigurationId__r.APTS_Amendment_Pricing__c==false){
            AmendLI.Apttus_Config2__PricingStatus__c='pending';
            AmendLI.Apttus_Config2__ConfigurationId__r.APTS_Amendment_Pricing__c=True;
            Prodamendindexlist.add(AmendLI.Apttus_Config2__ConfigurationId__r);
            Lineamendindexlist.add(AmendLI);
        }}
        if(!Lineamendindexlist.isEmpty()&&!Prodamendindexlist.isEmpty()){
        //Amendflag=false;
        Database.update(Lineamendindexlist);
       // Database.update(Prodamendindexlist);
        }*/
       //v109 
      
      }
      catch(Exception e)
      {
      
        APTS_CustomLogging.createErrorLog(e.getTypeName(), 'Apex', e.getStackTraceString() ,'Order', null,'OM',false,true, APTS_OrderConstants.APTS_EMAIL, true);
      } 
     // v108 - END.
    }

    /* beforeDelete Body*/
    //v104 ++ << - Delete Pending CER Records in case agreement cart is deleted or abandoned 
    public void beforeDelete(List<SObject> oldList, Map<Id, SObject> oldItems) {
        
         List<Apttus_Config2__ProductConfiguration__c> configurationList = (List<Apttus_Config2__ProductConfiguration__c>) oldList;
         Map<Id, Apttus_Config2__LineItem__c> idToLineItemMap;
         list<Apttus_Config2__LineItem__c> Linelistdel=new list<Apttus_Config2__LineItem__c>();
         list<string> lineItemlistdel=new list<string>();
         Linelistdel=[select id,Apttus_Config2__ConfigurationId__r.Apttus_Config2__BusinessObjectType__c,Apttus_Config2__ConfigurationId__r.Apttus_Config2__Status__c from Apttus_Config2__LineItem__c where Apttus_Config2__ConfigurationId__c IN :configurationList];
         if(Linelistdel.size()>0){
                 for(Apttus_Config2__LineItem__c licer:Linelistdel){
                        if(licer.Apttus_Config2__ConfigurationId__r.Apttus_Config2__BusinessObjectType__c=='Agreement'||licer.Apttus_Config2__ConfigurationId__r.Apttus_Config2__BusinessObjectType__c=='Order'){
                        lineItemlistdel.add(licer.Id);
                        }
                    }
            }
         list<CERDiscountCache__c> deleteCERCachedel=new list<CERDiscountCache__c>();
         deleteCERCachedel=[select id from CERDiscountCache__c where Name__c =:lineItemlistdel];
         if(deleteCERCachedel.size()>0){
            Delete deleteCERCachedel;
        }
         

        Set<Id> configset = new Set<Id>();
        //initialization loop - get the Config ID 
        //try{
        for (Apttus_Config2__ProductConfiguration__c agConfiguration : configurationList) {
            if (agConfiguration.Apttus_Config2__BusinessObjectType__c != null && agConfiguration.Apttus_Config2__BusinessObjectType__c.equalsIgnoreCase(AGREEMENT)) {
                configset.add(agConfiguration.ID);
            }
        }
       
        // DML to get the Line items and then corresponding CER Records 
        if (configset != null && configset.size() >0 )
        {
            APTS_ConfigurationTriggerHelper.deleteRecoverCERRecords(configset);
        } 
               
    }
    
    //v104 -->>  end of v104
    /* afterDelete Body*/
    //v110--<<
    public void afterDelete(List<SObject> oldList, Map<Id, SObject> oldItems) {
        Map<Id, Apttus_Config2__Order__c> idToOrderMap = new Map<Id, Apttus_Config2__Order__c>();
         Map<Id, List<Apttus_Config2__LineItem__c>> configurationIdToLineItemListMap = new Map<Id, List<Apttus_Config2__LineItem__c>>();
         Map<Id, Apttus_Config2__ProductConfiguration__c> idToConfigurationMap = (Map<Id, Apttus_Config2__ProductConfiguration__c>) oldItems;
  
       try{
        idToOrderMap = getOrderDetails(idToConfigurationMap.values());
        setOrderConfigurationStatus(idToConfigurationMap.values(), idToOrderMap, configurationIdToLineItemListMap, true);
        }
        catch(Exception e){
            system.debug(e);
        }
    }
    //v110>>--
    /* afterUndelete Body*/
    public void afterUndelete(List<SObject> newList, Map<Id, SObject> newItems) {

    }
 
     /* populateRequestedDeliveryDate Body*/
    private Boolean populateRequestedDeliveryDate(Apttus_Config2__Order__c oOrder, List<Apttus_Config2__LineItem__c> allLineItems) {
        Boolean dateChanged = false;
        if(oOrder.APTS_Requested_Delivery_Date__c != null)
        {
            Date dtBiggestRequestedDeliveryDate = oOrder.APTS_Requested_Delivery_Date__c;
            for (Apttus_Config2__LineItem__c oLineItem : allLineItems) {
                if (dtBiggestRequestedDeliveryDate < oLineItem.APTS_Requested_Delivery_Date__c) {
                    dtBiggestRequestedDeliveryDate = oLineItem.APTS_Requested_Delivery_Date__c;
                    dateChanged = true;
                }
            }
            if (dateChanged) {
                oOrder.APTS_Requested_Delivery_Date__c = dtBiggestRequestedDeliveryDate;
            }
        }       

        return dateChanged;
    }
    //v110-- start
    public void setOrderConfigurationStatus(List<Apttus_Config2__ProductConfiguration__c> lstConfiguration,  Map<Id, Apttus_Config2__Order__c> idToOrderMap, Map<Id, List<Apttus_Config2__LineItem__c>> configurationIdToLineItemListMap, Boolean bAfterDelete)
    {
            List<Apttus_Config2__Order__c> orderToUpdateList = new List<Apttus_Config2__Order__c>();
            Set<String> flowset = new Set<String>{'NGStandardOrder','NGStandardOrderWOC','NGRSOOrder','NGRSOOrderWOC','NGMachineOrder','NGMachineDeinstallOrder','NGAdminOrder','NGChangeContract'};
            //main loop
            
            for (Apttus_Config2__ProductConfiguration__c oConfiguration : lstConfiguration) {
            if (oConfiguration.Apttus_Config2__OrderId__c != null && (oConfiguration.Apttus_Config2__Status__c == APTS_OrderConstants.FINALIZED || oConfiguration.Apttus_Config2__Status__c == 'New' )) {
                Apttus_Config2__Order__c oOrder = idToOrderMap.get(oConfiguration.Apttus_Config2__OrderId__c);
                if (oOrder != null && flowset.contains(oConfiguration.APTS_Flow__c)) {
                    
                    if(!bAfterDelete){
                    oOrder.APTS_Configuration_Status__c =oConfiguration.Apttus_Config2__Status__c ;
                    }
                    else{
                    oOrder.APTS_Configuration_Status__c =APTS_OrderConstants.FINALIZED ;
                    }
                    if(!bAfterDelete && oConfiguration.Apttus_Config2__Status__c == APTS_OrderConstants.FINALIZED)
                        populateRequestedDeliveryDate(oOrder, configurationIdToLineItemListMap.get(oConfiguration.Id));
                    orderToUpdateList.add(oOrder);
                
                }
            } 
            }      

           
            if (!orderToUpdateList.isEmpty()) {       
                APTS_OrderUtils.stopOrderTrigger();
                Database.update(orderToUpdateList, false);
                APTS_OrderUtils.startOrderTrigger();
            }
     
    }
    public Map<Id, Apttus_Config2__Order__c> getOrderDetails(List<Apttus_Config2__ProductConfiguration__c> lstConfiguration)
    {
        Set<Id> orderIdSet = new Set<Id>();
        Map<Id, Apttus_Config2__Order__c> idToOrderMap = new Map<Id, Apttus_Config2__Order__c>();
        //initialization loop
        for (Apttus_Config2__ProductConfiguration__c oConfiguration : lstConfiguration) {
                if (oConfiguration.Apttus_Config2__OrderId__c != null && (oConfiguration.Apttus_Config2__Status__c == APTS_OrderConstants.FINALIZED || oConfiguration.Apttus_Config2__Status__c == 'New' )) {
                    orderIdSet.add(oConfiguration.Apttus_Config2__OrderId__c);
                }
            }

            if (!orderIdSet.isEmpty()) {
               
                for(Apttus_Config2__Order__c orderRec : [SELECT APTS_Order_Type__c, APTS_Configuration_Status__c, APTS_Requested_Delivery_Date__c
                                                         FROM Apttus_Config2__Order__c
                                                         WHERE Id IN :orderIdSet]){
                                                             
                    idToOrderMap.put(orderRec.Id, orderRec);
                }
                }
                return idToOrderMap;
    }
    //v110-- end
    //Muting logic
    public Boolean IsDisabled(){
       if (TriggerSettings__c.getInstance().APTS_Configuration_Trigger__c == true) {
    return false;
    } else {
    return isTriggerDisabled;
    }
    }
}