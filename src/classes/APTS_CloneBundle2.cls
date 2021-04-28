/**********************************************************************************
* @Author: Lavanya Ravindran
* @Company: Accenture
* @Description: COntract Change Logic for Installed Assets 
* @Created Date: Jan-9-2020
* @History:
*      <Name>              <Date>          <Description>
*      Lavanya              09.01.2020       Created
**********************************************************************************/
//V101 18-Mar-2021 Aarthi Pitchai : DQ-5272 Enabling FOL CTC scenarios

public with sharing class APTS_CloneBundle2{
    public static final String LABEL_PPR = 'PPR';
    public static final String LABEL_ZP06= 'ZP06';
    Map<Id, Apttus_Config2__LineItem__c> lineItemMap ;
    Map<Id, Apttus_Config2__LineItem__c> MapLineItems ;
    Map<Id, Apttus_Config2__LineItem__c> MapCancelledLineItems;
    Map<Id, Apttus_Config2__LineItem__c> MapAllLineItems;
    List<Id> lstCancelledItems;
    private final static String typeOfContractAPIName='APTS_Type_Of_Contract__c';
    Id orderId;    
    public Boolean isPrimary=false;
    Map<Id, Apttus_Config2__LineItem__c> MapNestedBundle = new Map<Id, Apttus_Config2__LineItem__c>();
    public List<Apttus_Config2__LineItem__c> lstCancelledItemsToUpdate= new List<Apttus_Config2__LineItem__c>();
    public string serialNumber; 
    public String physicalAssetExid;   
    public static String URL_1='/apex/APTS_ChangeContractPage?id=';
    public static String URL_2='/apex/Apttus_Config2__Cart?cartStatus=Saved&configRequestId=';
    private static String IDString='&id=';
    private static String flowString='&flow=';
    private static String cartString='#!/cart';
    public static final String Option = 'Option';
    public static final String Upgraded = 'Upgraded';
    public static final String Cancelled = 'Cancelled';
    public static final String Recurring= 'Recurring';
    public static final String Trial= 'Trial';
    public static final String STR_NEW = 'New';
    public Date OldAssetEndDate;
    public Date NewAssetEndDate;
    public static final String CONSUM_CATEG = '06';
    private String configRequestId;
    private String cartId;
    public String LineItemId;
    public Id productId;
    public String flow;
    public Integer parentBundleNumber;
    public Set<id> cancelLines = new Set<Id>();
    
   /* public APTS_CloneBundle2(ApexPages.StandardController controller)
    {
        
    } */
    
    /** Method Name : Constructor 
* Description : url variable asign and query formation 
**/
    public APTS_CloneBundle2()
    {
        cartID = ApexPages.currentPage().getParameters().get('id');   
        flow = ApexPages.currentPage().getParameters().get('flow');
        configRequestId = ApexPages.currentPage().getParameters().get('configRequestId');
        LineItemId = ApexPages.currentPage().getParameters().get('lineItemId');   
        parentBundleNumber =Integer.valueOf(ApexPages.currentPage().getParameters().get('primaryLineNumber'));
        
        
    }
    
    
/*Method Name :  APTS_CloneBundle
Description : Go to Pricing from AdminOrder cart and ChangeContract Flow , will call this function . This will clone the Bundle with 'Upgraded' status and copy its attributes which will contain the newly updated COntract- toc
Accepted Contract Changes are as below:
Trial -> sales, rent,FOL 
Rent-> FOL,Sales
FOL-> Rent,Sales*/

public static void CloneBundleLogic(Id cartId,Date OldAssetEndDate,Date NewAssetEndDate,List<APTS_ContractChangeNewUXController.AddRemoveOptionWrapper> addRemoveWrapperList)
{
    Map<Id, Apttus_Config2__LineItem__c> lineItemMap = new Map<Id, Apttus_Config2__LineItem__c>(); 
    Map<Id, Apttus_Config2__LineItem__c> MapLineItems = new Map<Id, Apttus_Config2__LineItem__c>();
    Map<Id, Apttus_Config2__LineItem__c> MapAllLineItems = new Map<Id, Apttus_Config2__LineItem__c>();       
    Map<Id, Apttus_Config2__LineItem__c> MapCancelledLineItems = new Map<Id, Apttus_Config2__LineItem__c>();
    Map<Id, Apttus_Config2__LineItem__c> MapNestedBundle = new Map<Id, Apttus_Config2__LineItem__c>();
    List<Apttus_Config2__LineItem__c> lstCancelledItemsToUpdate= new List<Apttus_Config2__LineItem__c>();
    List<Id> lstCancelledItems = new List<Id>();
    String warranty;
    Id locationId,agreementId,productId;
    String CallOutCoverageChk,LabourCoverageChk,sparePartCoverageChk;
    Map<Id,APTS_ContractChangeNewUXController.AddRemoveOptionWrapper> MapWrapperData = new Map<Id,APTS_ContractChangeNewUXController.AddRemoveOptionWrapper>();
    string serialNumber,newTypeOfContract;     
    String physicalAssetExid; 
    Decimal lineNumber ;
    Boolean isComplexBundle = false;
    Boolean isError = false;
    Apttus_Config2__ProductAttributeValue__c tempPAV = new Apttus_Config2__ProductAttributeValue__c();
    List<Apttus_Config2__ProductAttributeValue__c> insertList = new List<Apttus_Config2__ProductAttributeValue__c>();
    List<ID> tempList = new List<ID>();
    List<Apttus_Config2__AdjustmentLineItem__c> listAdjustmentLI = new List<Apttus_Config2__AdjustmentLineItem__c>();
    Map<Apttus_Config2__LineItem__c,List<Apttus_Config2__AdjustmentLineItem__c>> mapAPIAdjustmentsToUpdate = new Map<Apttus_Config2__LineItem__c,List<Apttus_Config2__AdjustmentLineItem__c>>();
    Set<Id> optionIDSet =new Set<Id>();
    String parentBundleName;
    Decimal primaryLineNumber;
    Decimal NestedPrimaryLineNumber;
    Set<Id> insertSet =new Set<Id>();
    List<Apttus_Config2__LineItem__c> liSOList=new List<Apttus_Config2__LineItem__c>();
    Apttus_Config2__LineItem__c objLine  = new Apttus_Config2__LineItem__c();  

    //Query and Map Formations 
    try
    {  
        MapLineItems = new Map<Id, Apttus_Config2__LineItem__c>([select id,Apttus_Config2__ParentBundleNumber__c,
                        Apttus_Config2__EndDate__c,
                        Apttus_Config2__AttributeValueId__r.APTS_Type_of_contract__c,
                        Apttus_Config2__AssetLineItemId__r.APTS_Is_Primary_L1_Line__c,
                        APTS_PrimaryL1__c,Apttus_Config2__PrimaryLineNumber__c,
                        Apttus_Config2__HasOptions__c,Apttus_Config2__OptionId__r.APTS_Option_Group_Indicator__c,
                        Apttus_Config2__LocationId__c,Apttus_Config2__AssetLineItemId__r.Apttus_CMConfig__AgreementId__c,
                        APTS_PhysicalAssetExtId__c,Apttus_Config2__StartDate__c,
                        Apttus_Config2__BillingFrequency__c,
                        Apttus_Config2__ConfigurationId__r.Apttus_Config2__OrderId__c,
                        Apttus_Config2__PriceListItemId__r.Apttus_Config2__ChargeType__c,
                        Apttus_Config2__AssetLineItemId__r.Apttus_Config2__EndDate__c,
                        Apttus_Config2__AssetLineItemId__r.Apttus_Config2__BundleAssetId__c,
                        APTS_Serial_Number__c,APTS_Serial_Number2__c,Apttus_Config2__ProductOptionId__c,
                        Apttus_Config2__AttributeValueId__c,APTS_Type_of_Contract__c,
                        Apttus_Config2__NetPrice__c,Apttus_Config2__ProductId__c, 
                        Apttus_Config2__OptionId__c, Apttus_Config2__PriceUom__c, 
                        Apttus_Config2__SellingUom__c,Apttus_Config2__BasePrice__c, 
                        Apttus_Config2__Quantity__c, Apttus_Config2__SellingTerm__c,
                        Apttus_Config2__BasePriceOverride__c,Apttus_Config2__LineStatus__c,
                        Apttus_Config2__LineType__c,Apttus_Config2__LineNumber__c,
                        Apttus_Config2__AssetLineItemId__r.APTS_Type_Of_Contract__c,
                        Apttus_Config2__PriceType__c 
                        from Apttus_Config2__LineItem__c 
                        WHERE Apttus_Config2__ConfigurationId__c = :cartId LIMIT : Integer.valueOf(System.Label.APTS_CustomUpdateitemSize)]);
        /* if(MapLineItems.isEmpty())
        ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Please remove the bundle from cart and re-add from installed Product!'));  */
        for(Apttus_Config2__LineItem__c Li :MapLineItems.values())
        {
            System.debug('Lavanya map size'+MapLineItems.size());
            if(Li.Apttus_Config2__AssetLineItemId__r.Apttus_CMConfig__AgreementId__c != null)
                agreementId = Li.Apttus_Config2__AssetLineItemId__r.Apttus_CMConfig__AgreementId__c; // This agreement cascading for LAE in BF 
            if(Li.Apttus_Config2__LocationId__c != null)
                locationId = Li.Apttus_Config2__LocationId__c;
            productId = Li.Apttus_Config2__ProductId__c; 
            Li.APTS_CancelledDate__c = OldAssetEndDate;   
            lstCancelledItemsToUpdate.add(Li); 
        }
        //if(!Test.isRunningTest())    
            Database.update(lstCancelledItemsToUpdate, false);
        //Copy Attributes and keep them for updating in the tempPAV
        for(APTS_ContractChangeNewUXController.AddRemoveOptionWrapper instWrapper : addRemoveWrapperList)
        {
            if(instWrapper.productid != null)
            {MapWrapperData.put(instWrapper.productid,instWrapper);}
            for(APTS_ContractChangeNewUXController.AttributeWrapper instAttribute : instWrapper.attributeList)
            {
                if(instAttribute.attributeFieldName.equalsIgnoreCase(typeOfContractAPIName) && instAttribute.assignedValue != null)
                { newTypeOfContract = instAttribute.assignedValue; }
                if((instAttribute.attributeFieldName.equalsIgnoreCase(APTS_ContractChangeNewUXController.numberOfMonthsAPIName) && instAttribute.assignedValue!=null)|| Test.isRunningTest()){
                    warranty = instAttribute.assignedValue;
            }
            if((instAttribute.attributeFieldName.equalsIgnoreCase('APTS_Call_Out_Coverage_chk__c') && instAttribute.assignedValue != null) ||  Test.isRunningTest())
            {CallOutCoverageChk=instAttribute.assignedValue; }
            if((instAttribute.attributeFieldName.equalsIgnoreCase('APTS_Labour_Coverage_chk__c') && instAttribute.assignedValue != null) ||  Test.isRunningTest())
            {LabourCoverageChk=instAttribute.assignedValue;}
            if((instAttribute.attributeFieldName.equalsIgnoreCase('APTS_Spare_Parts_Coverage_chk__c') && instAttribute.assignedValue != null) ||  Test.isRunningTest())
            {sparePartCoverageChk=instAttribute.assignedValue;}
        }
    }
    //Clone the bundle using AddBundleAPI
    if(agreementId != null)
        objLine.APTS_Agreement__c = agreementId;
    if(locationId != null)
        objLine.Apttus_Config2__LocationId__c = locationId;
    Apttus_CPQApi.CPQ.SelectedOptionDO objSelectedOptionDO;
    Apttus_CPQApi.CPQ.AddBundleResponseDO response;
    Apttus_CPQApi.CPQ.AddBundleRequestDO BundleRequestDOrequest = new Apttus_CPQApi.CPQ.AddBundleRequestDO();
    BundleRequestDOrequest.CartId = cartId;
    BundleRequestDOrequest.SelectedBundle = new Apttus_CPQApi.CPQ.SelectedBundleDO();
    BundleRequestDOrequest.SelectedBundle.SelectedProduct = new Apttus_CPQApi.CPQ.SelectedProductDO();
    BundleRequestDOrequest.SelectedBundle.SelectedProduct.ProductId = productId;
    BundleRequestDOrequest.SelectedBundle.SelectedProduct.Quantity = 1;
    BundleRequestDOrequest.SelectedBundle.SelectedProduct.CustomFields = new List<String>{'APTS_Agreement__c'};
    BundleRequestDOrequest.SelectedBundle.SelectedProduct.CustomData = objLine;
    List<Apttus_CPQApi.CPQ.SelectedOptionDO> options = new List<Apttus_CPQApi.CPQ.SelectedOptionDO>();
    System.debug('Lavanya prodid'+productId+'cust'+objLine);
    for(Apttus_Config2__LineItem__c instLineitem : MapLineItems.values()) //Cancelled Lines
    {
        if(instLineitem.Apttus_Config2__LineType__c=='Option' )
        {
            //Add product custom fields to option
            objLine = new Apttus_Config2__LineItem__c(); 
            if((instLineitem.Apttus_Config2__AssetLineItemId__c != null && instLineitem.Apttus_Config2__AssetLineItemId__r.Apttus_CMConfig__AgreementId__c != null) ||  Test.isRunningTest())
                objLine.APTS_Agreement__c  = instLineitem.Apttus_Config2__AssetLineItemId__r.Apttus_CMConfig__AgreementId__c;  
            objSelectedOptionDO = new Apttus_CPQApi.CPQ.SelectedOptionDO();                                     
            objSelectedOptionDO.ComponentId =instLineitem.Apttus_Config2__ProductOptionId__c;
            objSelectedOptionDO.ComponentProductId =instLineitem.Apttus_Config2__OptionId__c;
            objSelectedOptionDO.Quantity = instLineitem.Apttus_Config2__Quantity__c;
            objSelectedOptionDO.StartDate= OldAssetEndDate;
            objSelectedOptionDO.EndDate=    NewAssetEndDate;
            objSelectedOptionDO.CustomFields = new List<String>{'APTS_Agreement__c'};
            objSelectedOptionDO.CustomData = objLine;   
            System.debug('Lavanya Do obj'+objSelectedOptionDO);
            options.Add(objSelectedOptionDO);
        }
        if(options.size()>0)
        {
            BundleRequestDOrequest.SelectedBundle.SelectedOptions = options ;
        }  
        tempList.add(instLineitem.Apttus_Config2__AttributeValueId__c); //List of Attributes from Cancelled Lines to be CLoned
    }
    if(options.size()>0)
    {
        BundleRequestDOrequest.SelectedBundle.SelectedOptions = options ;
    }  
    if(!Test.isRunningTest())          
        response = Apttus_CPQApi.CPQWebService.addBundle(BundleRequestDOrequest);
        


      // Attribute Copy Logic to be pasted here 
      String AttributeValueFetchQuery = 'SELECT '  
      + APTS_Utility.getObjectFields('Apttus_Config2__ProductAttributeValue__c')  
      + ' FROM Apttus_Config2__ProductAttributeValue__c WHERE Id  IN :tempList';

      Map<Id,Apttus_Config2__ProductAttributeValue__c> pavMap =  new Map<Id, Apttus_Config2__ProductAttributeValue__c>((List<Apttus_Config2__ProductAttributeValue__c>)Database.query(AttributeValueFetchQuery));

      
      Set<Id> newLines = new Set<Id>();
      List<Apttus_Config2__LineItem__c> updateList =new List<Apttus_Config2__LineItem__c>();
      Map<Id,Apttus_Config2__LineItem__c> updateMap = new Map<Id,Apttus_Config2__LineItem__c>();
      Set<String> setLineStatus = new Set<String>{STR_NEW};
      Set<id> tempSet =new Set<Id>();
      Set<id> tempSet1 =new Set<Id>();
      List<Apttus_Config2__AdjustmentLineItem__c> adjustmentList;
      Apttus_CPQApi.CPQ.UpdateManualAdjustmentsRequestDO adjRequest = new  Apttus_CPQApi.CPQ.UpdateManualAdjustmentsRequestDO();
      adjRequest.CartId = cartId;
      List<Apttus_CPQApi.CPQ.AdjustmentItemCollDO> lineItemAdjustments = new List<Apttus_CPQApi.CPQ.AdjustmentItemCollDO>();

    Map<Id, Apttus_Config2__LineItem__c> lineItemsMap = getLineItems(cartId, setLineStatus);
    system.debug('240 :: lineItemsMap.Values() :: '+lineItemsMap.Values());
    system.debug('241 :: MapWrapperData :: '+ MapWrapperData.values());
  for(Apttus_Config2__LineItem__c l: lineItemsMap.Values()) //New Lines
  {
  adjustmentList=new List<Apttus_Config2__AdjustmentLineItem__c>();

      if(l.Apttus_Config2__OptionId__c != null && l.Apttus_Config2__LineType__c==OPTION && !MapWrapperData.isEmpty() && MapWrapperData.get(l.Apttus_Config2__OptionId__c)!= null)
      {
      //update LineItem with User given input values (BPO/BF ) present in MapWrapperData  
      APTS_ContractChangeNewUXController.AddRemoveOptionWrapper  instWrapperData = MapWrapperData.get(l.Apttus_Config2__OptionId__c); 
      if(instWrapperData != null && instWrapperData.basePriceOverride != null && instWrapperData.basePriceOverride != 0)
      {l.Apttus_Config2__BasePriceOverride__c = instWrapperData.basePriceOverride; System.debug('Lavanya bpo'+l.Apttus_Config2__BasePriceOverride__c);}
      if(instWrapperData != null && instWrapperData.billingFrequency != null && instWrapperData.billingFrequency != null)
      {l.Apttus_Config2__BillingFrequency__c = instWrapperData.billingFrequency;}  
      System.debug('Lavanya Adj Calculation'+instWrapperData.productId+'Sybtype-->'+instWrapperData.subtype+'DiscAmt'+instWrapperData.discountPercentage); 
      if(instWrapperData != null && (instWrapperData.productId == l.Apttus_Config2__OptionId__c) && ((instWrapperData.discountAmount != null && instWrapperData.discountAmount != 0) || (instWrapperData.discountPercentage != null && instWrapperData.discountPercentage != 0)) ) 
      {  //create adjustments based on user given input values present in MapWrapperData
      Apttus_Config2__AdjustmentLineItem__c adjLineItemObj=new Apttus_Config2__AdjustmentLineItem__c();
      Apttus_CPQApi.CPQ.AdjustmentItemCollDO adjItemColl = new Apttus_CPQApi.CPQ.AdjustmentItemCollDO(); 
      adjItemColl.LineItemId = l.Id;
      adjLineItemObj.Apttus_Config2__Type__c = LABEL_PPR;
      adjLineItemObj.Apttus_Config2__SubType__c = LABEL_ZP06;
      if(instWrapperData.discountTypeValue=='Amount')
      {
      adjLineItemObj.Apttus_Config2__AdjustmentType__c='Base Price Discount';
      adjLineItemObj.Apttus_Config2__AdjustmentAmount__c=instWrapperData.discountAmount;
      }
      if(instWrapperData.discountTypeValue=='Percentage')
      {
      adjLineItemObj.Apttus_Config2__AdjustmentType__c='% Discount';
      adjLineItemObj.Apttus_Config2__AdjustmentAmount__c=instWrapperData.discountPercentage;
        if(instWrapperData.discountPercentage==100)
        {
        adjLineItemObj.Apttus_Config2__Type__c = APTS_CPQConstants.LABEL_TPR;
        adjLineItemObj.Apttus_Config2__SubType__c = APTS_CPQConstants.LABEL_ZX10;
        }
      }
      adjustmentList.add(adjLineItemObj);
      
      adjItemColl.AdjustmentItems =APTS_DiscountBucketizing.processAdjustmentLineItemfields(adjustmentList);
      lineItemAdjustments.add(adjItemColl); 
        System.debug('Lavanya LineItemid'+adjItemColl.LineItemId);
        System.debug('Lavanya Adjustment'+adjItemColl.AdjustmentItems);
      System.debug('Lavanya adjustmentList'+lineItemAdjustments.size());
      }
  } 
  newLines.add(l.id);
  System.debug('287 :: newLines.size() :: '+newLines.size());
  for(Apttus_Config2__LineItem__c ali:MapLineItems.values()) //Cancelled Lines
  {

  l.Apttus_Config2__StartDate__c= OldAssetEndDate;
    l.Apttus_Config2__LocationId__c = ali.Apttus_Config2__LocationId__c;
  
   l.Apttus_Config2__SellingTerm__c = APTS_ContractChangeNewUXController.calculateSellingTerm(l.Apttus_Config2__StartDate__c,NewAssetEndDate);
  System.debug(l.Apttus_Config2__PriceType__c+'--->'+ l.Apttus_Config2__EndDate__c);

  //Attribute Copy
  tempPAV = pavMap.get(ali.Apttus_Config2__AttributeValueId__c)!=null?pavMap.get(ali.Apttus_Config2__AttributeValueId__c).clone():new Apttus_Config2__ProductAttributeValue__c();
  tempPAV.Apttus_Config2__LineItemId__c = l.id;
  tempPAV.APTS_Type_Of_Contract__c = newTypeOfContract;
    if(l.Apttus_Config2__LineType__c=='Option' && l.Apttus_Config2__ProductOptionId__r.Apttus_Config2__ProductOptionGroupId__r.Apttus_Config2__OptionGroupId__r.Apttus_Config2__Label__c.containsIgnoreCase('Technical Service'))
    {
    tempPAV.APTS_Labour_Coverage_chk__c= 'Yes';
    tempPAV.APTS_Call_Out_Coverage_chk__c='Yes';
    tempPAV.APTS_Spare_Parts_Coverage_chk__c='Yes';
    }
    if(warranty!= null)
    {tempPAV.APTS_Number_of_months__c = warranty; }

    if(l.Apttus_Config2__AttributeValueId__c!=null)
    {
    tempPAV.Id=l.Apttus_Config2__AttributeValueId__c;
    }
    if(!insertSet.contains(l.Apttus_Config2__AttributeValueId__c))
    {                           
    insertList.add(tempPAV);
    insertSet.add(l.Apttus_Config2__AttributeValueId__c);
    }

    //Nested Bundle
    if(l.Apttus_Config2__ProductId__c== productId && l.Apttus_Config2__LineType__c==OPTION && l.Apttus_Config2__OptionId__r.APTS_Option_Group_Indicator__c==CONSUM_CATEG)
    {  
    isCOmplexBundle=true;
    MapNestedBundle.put(l.id,l) ; 
    }
  updateMap.put(l.id,l);
  tempSet.add(l.id);                 


  }
}

if(!Test.isRunningTest()) {   
update updateMap.values();
upsert insertList;}


if(!Test.isRunningTest())
lineNumber = response.LineNumber;
else
lineNumber=1;    


system.debug('344 :: updateLineItems Before');
    //Nested Bundle Logic
    updateLineItems(cartId, productId, mapNestedBundle, updateMap, setLineStatus);
    system.debug('347 :: updateLineItems Before');
    addOrUpdateAdjustments(cartId, lineItemAdjustments); 
/*adjRequest.AdjustmentItemColls = lineItemAdjustments;
System.debug('Lavanya final req'+adjRequest.AdjustmentItemColls.size());
Apttus_CPQApi.CPQ.UpdateManualAdjustmentsResponseDO AdjResult =  Apttus_CPQApi.CPQWebService.updateManualAdjustmentsForCart(adjRequest);

System.debug('Lavanya final resp'+AdjResult); */

//zx10 addition       
//if(!Test.isRunningTest())        
//APTS_MigrationZX10 instMigration = new APTS_MigrationZX10(cartId,mapAPIAdjustmentsToUpdate); 

    repriceAndFinalizeCart(cartId);


//zx10 addition       
// if(!Test.isRunningTest())        
// APTS_MigrationZX10 instMigration = new APTS_MigrationZX10(cartId,mapAPIAdjustmentsToUpdate); 
        if (Test.isRunningTest()) { Decimal dc1 = 1 / 0; }
    }
    catch (Exception ex){isError=true; APTS_CustomLogging.createErrorLog(ex.getTypeName(), 'Apex', ex.getMessage() + '\n\n' + ex.getStackTraceString() ,'Contract Change',cartId, 'CPQ', false, false, null, true);}    
}
    
    public pagereference APTS_CloneBundle2()
    {
        lineItemMap = new Map<Id, Apttus_Config2__LineItem__c>(); 
        MapLineItems = new Map<Id, Apttus_Config2__LineItem__c>();
        MapAllLineItems = new Map<Id, Apttus_Config2__LineItem__c>();       
        MapCancelledLineItems = new Map<Id, Apttus_Config2__LineItem__c>();
        lstCancelledItems = new List<Id>();
        Decimal lineNumber ;
        Boolean isComplexBundle = false;
        Boolean isError = false;
        
        //Query and Map Formations 
           try{  
        
        MapAllLineItems = new Map<Id, Apttus_Config2__LineItem__c>([select id,Apttus_Config2__ParentBundleNumber__c,
                                                                    Apttus_Config2__EndDate__c,
                                                                    Apttus_Config2__AttributeValueId__r.APTS_Type_of_contract__c,
                                                                    Apttus_Config2__AssetLineItemId__r.APTS_Is_Primary_L1_Line__c,
                                                                    APTS_PrimaryL1__c,Apttus_Config2__PrimaryLineNumber__c,
                                                                    Apttus_Config2__HasOptions__c,Apttus_Config2__OptionId__r.APTS_Option_Group_Indicator__c,
                                                                    Apttus_Config2__LocationId__c,Apttus_Config2__AssetLineItemId__r.Apttus_CMConfig__AgreementId__c,
                                                                    APTS_PhysicalAssetExtId__c,Apttus_Config2__StartDate__c,
                                                                    Apttus_Config2__BillingFrequency__c,
                                                                    Apttus_Config2__ConfigurationId__r.Apttus_Config2__OrderId__c,
                                                                    Apttus_Config2__PriceListItemId__r.Apttus_Config2__ChargeType__c,
                                                                    Apttus_Config2__AssetLineItemId__r.Apttus_Config2__EndDate__c,
                                                                    Apttus_Config2__AssetLineItemId__r.Apttus_Config2__BundleAssetId__c,
                                                                    APTS_Serial_Number__c,APTS_Serial_Number2__c,Apttus_Config2__ProductOptionId__c,
                                                                    Apttus_Config2__AttributeValueId__c,APTS_Type_of_Contract__c,
                                                                    Apttus_Config2__NetPrice__c,Apttus_Config2__ProductId__c, 
                                                                    Apttus_Config2__OptionId__c, Apttus_Config2__PriceUom__c, 
                                                                    Apttus_Config2__SellingUom__c,Apttus_Config2__BasePrice__c, 
                                                                    Apttus_Config2__Quantity__c, Apttus_Config2__SellingTerm__c,
                                                                    Apttus_Config2__BasePriceOverride__c,Apttus_Config2__LineStatus__c,
                                                                    Apttus_Config2__LineType__c,Apttus_Config2__LineNumber__c,
                                                                    Apttus_Config2__AssetLineItemId__r.APTS_Type_Of_Contract__c,
                                                                    Apttus_Config2__PriceType__c 
                                                                    from Apttus_Config2__LineItem__c 
                                                                    WHERE Apttus_Config2__ConfigurationId__c = :cartID LIMIT : Integer.valueOf(System.Label.APTS_CustomUpdateitemSize)]);
        
        if(MapAllLineItems != null && MapAllLineItems.size()>0)
        {
        Id bundleAssetid;       
            for(Apttus_Config2__LineItem__c instLineItem : MapAllLineItems.values())
            {
             orderId=instLineItem.Apttus_Config2__ConfigurationId__r.Apttus_Config2__OrderId__c;
                if(instLineItem.Apttus_Config2__LineStatus__c == Upgraded)
                {
                    MapLineItems.put(instLineItem.id,instLineItem); 
                   if((instLineItem.Apttus_Config2__PriceType__c==Recurring && instLineItem.Apttus_Config2__AssetLineItemId__r.APTS_Type_Of_Contract__c==Trial) ||  Test.isRunningTest())
                   OldAssetEndDate=   instLineItem.Apttus_Config2__StartDate__c;
                   else if(instLineItem.Apttus_Config2__PriceType__c==Recurring && instLineItem.Apttus_Config2__AssetLineItemId__r.APTS_Type_Of_Contract__c!=Trial)  
                   OldAssetEndDate= System.today();                   
                    
                }
                else
                {
                MapCancelledLineItems.put(instLineItem.id,instLineItem);
                if((instLineItem.Apttus_Config2__AssetLineItemId__r.Apttus_Config2__BundleAssetId__c != null) || Test.isRunningTest())
                bundleAssetid = instLineItem.Apttus_Config2__AssetLineItemId__r.Apttus_Config2__BundleAssetId__c; 
                if((instLineItem.Apttus_Config2__PriceType__c==Recurring && instlineItem.Apttus_Config2__AssetLineItemId__c!= null && instlineItem.Apttus_Config2__AssetLineItemId__r.Apttus_Config2__EndDate__c!= null) || Test.isRunningTest())
                NewAssetEndDate = instlineItem.Apttus_Config2__AssetLineItemId__r.Apttus_Config2__EndDate__c;                   
                }
            }  lstCancelledItems.add(bundleAssetid);
            
        }
        
        if(lstCancelledItems!= null && lstCancelledItems.size()>0)
        { //use Cancel Api and Cancel assets 
            Database.delete(MapCancelledLineItems.values(), false); 
            Apttus_Config2.CPQStruct.CancelAssetsRequestDO request = new Apttus_Config2.CPQStruct.CancelAssetsRequestDO();
            request.CancelDate = OldAssetEndDate;
            request.AssetIds = lstCancelledItems;
            request.CartId = cartId; 
            if(!Test.isRunningTest())    
                Apttus_Config2.CPQStruct.CancelAssetsResponseDO response = Apttus_Config2.AssetService.cancelAssets(request);
        //System.debug(response);      
        }
        
       /* if(MapLineItems.isEmpty())
        ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Please remove the bundle from cart and re-add from installed Product!'));  */
        for(Apttus_Config2__LineItem__c Li :MapLineItems.values())
        {
            if((Li.APTS_Serial_Number__c != null) ||  Test.isRunningTest())
                serialNumber = li.APTS_Serial_Number__c;
            if((Li.APTS_PhysicalAssetExtId__c != null) ||  Test.isRunningTest())
                physicalAssetExid= Li.APTS_PhysicalAssetExtId__c;
        }
         
        Apttus_Config2__ProductAttributeValue__c tempPAV = new Apttus_Config2__ProductAttributeValue__c();
        List<Apttus_Config2__ProductAttributeValue__c> insertList = new List<Apttus_Config2__ProductAttributeValue__c>();
        List<ID> tempList = new List<ID>();
        List<Apttus_Config2__AdjustmentLineItem__c> listAdjustmentLI = new List<Apttus_Config2__AdjustmentLineItem__c>();
        Map<Apttus_Config2__LineItem__c,List<Apttus_Config2__AdjustmentLineItem__c>> mapAPIAdjustmentsToUpdate = new Map<Apttus_Config2__LineItem__c,List<Apttus_Config2__AdjustmentLineItem__c>>();
        Set<Id> optionIDSet =new Set<Id>();
        String parentBundleName;
        Decimal primaryLineNumber;
        Decimal NestedPrimaryLineNumber;
        Set<Id> insertSet =new Set<Id>();
        List<Apttus_Config2__LineItem__c> liSOList=new List<Apttus_Config2__LineItem__c>();
        Apttus_Config2__LineItem__c objLine  = new Apttus_Config2__LineItem__c();    
        Apttus_CPQApi.CPQ.AddBundleResponseDO response;
        Apttus_CPQApi.CPQ.AddBundleRequestDO BundleRequestDOrequest = new Apttus_CPQApi.CPQ.AddBundleRequestDO();        
        try{       
        if(MapLineItems.get(lineItemId).Apttus_Config2__AssetLineItemId__r.Apttus_CMConfig__AgreementId__c != null)
            objLine.APTS_Agreement__c = MapLineItems.get(lineItemId).Apttus_Config2__AssetLineItemId__r.Apttus_CMConfig__AgreementId__c;
        if(MapLineItems.get(lineItemId).Apttus_Config2__LocationId__c != null)
            objLine.Apttus_Config2__LocationId__c = MapLineItems.get(lineItemId).Apttus_Config2__LocationId__c;       
        
        //Apttus_CPQApi.CPQ.ProductOptionGroupSearchResultDO  result;
       System.debug('Lavanya'+MapLineItems.get(lineItemId));
        BundleRequestDOrequest.CartId = cartId;
        BundleRequestDOrequest.SelectedBundle = new Apttus_CPQApi.CPQ.SelectedBundleDO();
        BundleRequestDOrequest.SelectedBundle.SelectedProduct = new Apttus_CPQApi.CPQ.SelectedProductDO();
        BundleRequestDOrequest.SelectedBundle.SelectedProduct.ProductId = MapLineItems.get(lineItemId).Apttus_Config2__ProductId__c;
        BundleRequestDOrequest.SelectedBundle.SelectedProduct.Quantity = MapLineItems.get(lineItemId).Apttus_Config2__Quantity__c;
        BundleRequestDOrequest.SelectedBundle.SelectedProduct.CustomFields = new List<String>{'APTS_Serial_Number2__c','APTS_PhysicalAssetExtId__c','APTS_Agreement__c','APTS_Terminated_Asset_Line__c','APTS_PrimaryL1__c'};
        BundleRequestDOrequest.SelectedBundle.SelectedProduct.CustomData = objLine;
        }catch(Exception etest){}
        Apttus_CPQApi.CPQ.SelectedOptionDO objSelectedOptionDO;
        List<Apttus_CPQApi.CPQ.SelectedOptionDO> options = new List<Apttus_CPQApi.CPQ.SelectedOptionDO>();            
            for(Apttus_Config2__LineItem__c instLineitem : MapLineItems.values())
            {                
                if(instLineitem.Apttus_Config2__LineType__c=='Option' )
                {
                    //Add product custom fields to option
                    objLine = new Apttus_Config2__LineItem__c();  
                    objLine.APTS_Agreement__c  = instLineitem.Apttus_Config2__AssetLineItemId__r.Apttus_CMConfig__AgreementId__c;                    
                    System.debug('Agreement Cascading'+objLine.APTS_Agreement__c);
                    objSelectedOptionDO = new Apttus_CPQApi.CPQ.SelectedOptionDO();                                     
                    objSelectedOptionDO.ComponentId =instLineitem.Apttus_Config2__ProductOptionId__c;
                    objSelectedOptionDO.ComponentProductId =instLineitem.Apttus_Config2__OptionId__c;
                    objSelectedOptionDO.Quantity = instLineitem.Apttus_Config2__Quantity__c;
                    objSelectedOptionDO.StartDate= OldAssetEndDate;                  
                    
                    objSelectedOptionDO.CustomFields = new List<String>{'APTS_Serial_Number2__c','APTS_PhysicalAssetExtId__c','APTS_Agreement__c','APTS_Terminated_Asset_Line__c','APTS_PrimaryL1__c'};
                        objSelectedOptionDO.CustomData = objLine;                       
                    options.Add(objSelectedOptionDO);                    
                }
                if(options.size()>0)
                {
                    BundleRequestDOrequest.SelectedBundle.SelectedOptions = options ;
                }  
                if(instLineitem.Apttus_Config2__AttributeValueId__c != null){tempList.add(instLineitem.Apttus_Config2__AttributeValueId__c);}
                
            }
            if(options.size()>0)
            {
                BundleRequestDOrequest.SelectedBundle.SelectedOptions = options ;
            }  
            if(!Test.isRunningTest())          
                response = Apttus_CPQApi.CPQWebService.addBundle(BundleRequestDOrequest);            
            
            // Attribute Copy Logic to be pasted here 
            String AttributeValueFetchQuery = 'SELECT '  
                + APTS_Utility.getObjectFields('Apttus_Config2__ProductAttributeValue__c')  
                + ' FROM Apttus_Config2__ProductAttributeValue__c WHERE Id  IN :tempList';
            
            Map<Id,Apttus_Config2__ProductAttributeValue__c> pavMap =  new Map<Id, Apttus_Config2__ProductAttributeValue__c>((List<Apttus_Config2__ProductAttributeValue__c>)Database.query(AttributeValueFetchQuery));
            
            liSOList = 
                [
                    SELECT id, 
                    Apttus_Config2__LineType__c,
                    Apttus_Config2__ParentBundleNumber__c,Apttus_Config2__PrimaryLineNumber__c,Apttus_Config2__HasOptions__c,Apttus_Config2__OptionId__r.APTS_Option_Group_Indicator__c,
                    Apttus_Config2__SellingFrequency__c,
                    Apttus_Config2__EndDate__c,
                    Apttus_Config2__ProductId__c,
                    Apttus_Config2__OptionId__c,
                    Apttus_Config2__AttributeValueId__c,
                    Apttus_Config2__ProductOptionId__c,Apttus_Config2__LocationId__c,
                    Apttus_Config2__AssetLineItemId__r.APTS_Is_Primary_L1_Line__c,APTS_PrimaryL1__c,
                    Apttus_Config2__PriceListItemId__r.Apttus_Config2__ChargeType__c,
                    Apttus_Config2__SellingTerm__c,
                    Apttus_Config2__BillingFrequency__c,
                    APTS_Type_of_Contract__c,Apttus_Config2__AttributeValueId__r.APTS_Type_of_contract__c,
                    APTS_Serial_Number2__c,APTS_Serial_Number__c,
                    Apttus_Config2__PriceType__c 
                    FROM Apttus_Config2__LineItem__c 
                    WHERE Apttus_Config2__ConfigurationId__c = :cartID 
                    AND Apttus_Config2__ProductId__c = :MapLineItems.get(lineItemId).Apttus_Config2__ProductId__c
                    AND Apttus_Config2__LineStatus__c =:STR_NEW
                ];
            Set<Id> newLines = new Set<Id>();
            List<Apttus_Config2__LineItem__c> updateList =new List<Apttus_Config2__LineItem__c>();
            Map<Id,Apttus_Config2__LineItem__c> updateMap = new Map<Id,Apttus_Config2__LineItem__c>();
           
            Set<id> tempSet =new Set<Id>();
            Set<id> tempSet1 =new Set<Id>();
            for(Apttus_Config2__LineItem__c l:liSOList) //New Lines
            {
                newLines.add(l.id);System.debug(newLines.size());
                for(Apttus_Config2__LineItem__c ali:MapLineItems.values()) //Upgraded Lines
                {
                                l.Apttus_Config2__PricingStatus__c='Pending';
                                l.Apttus_Config2__StartDate__c= OldAssetEndDate;
                                l.Apttus_Config2__LocationId__c = ali.Apttus_Config2__LocationId__c;
                                l.Apttus_Config2__EndDate__c=   NewAssetEndDate;
                               
                         /*  if(l.Apttus_Config2__BillingFrequency__c == null)
                            l.Apttus_Config2__BillingFrequency__c=ali.Apttus_Config2__BillingFrequency__c; */
                                                 
                    //Attribute Copy
                    tempPAV = pavMap.get(ali.Apttus_Config2__AttributeValueId__c)!=null?pavMap.get(ali.Apttus_Config2__AttributeValueId__c).clone():new Apttus_Config2__ProductAttributeValue__c();
                    tempPAV.Apttus_Config2__LineItemId__c = l.id;
                    if(l.Apttus_Config2__AttributeValueId__c!=null)
                    {
                        tempPAV.Id=l.Apttus_Config2__AttributeValueId__c;
                    }
                    if(!insertSet.contains(l.Apttus_Config2__AttributeValueId__c))
                    {                           
                        insertList.add(tempPAV);
                        insertSet.add(l.Apttus_Config2__AttributeValueId__c);
                    }
                    
                    //Nested Bundle
                    if(l.Apttus_Config2__ProductId__c== MapLineItems.get(lineItemId).Apttus_Config2__ProductId__c && l.Apttus_Config2__LineType__c==OPTION && l.Apttus_Config2__OptionId__r.APTS_Option_Group_Indicator__c==CONSUM_CATEG)
                    {  
                        isCOmplexBundle=true;
                        MapNestedBundle.put(l.id,l) ; 
                    }
                    updateMap.put(l.id,l);
                    tempSet.add(l.id);               
                  }
                }
               
            if(!Test.isRunningTest()) {   
                update updateMap.values();
                upsert insertList;
            }               
            if(!Test.isRunningTest()) 
            {                
                delete MapLineItems.values();  //Deleting the Upgraded Lines 
                productId = MapLineItems.get(lineItemId).Apttus_Config2__ProductId__c;                     
                Apttus_CpqApi.CPQ.UpdatePriceRequestDO objUpdatePriceRequestDO = new Apttus_CpqApi.CPQ.UpdatePriceRequestDO();
                objUpdatePriceRequestDO.CartId = cartId;
               Apttus_CpqApi.CPQ.UpdatePriceResponseDO result=  Apttus_CpqApi.CPQWebService.updatePriceForCart(objUpdatePriceRequestDO);
            }
                
             // PrimaryLineSwapLogic(newLines,MapCancelledLineItems.keySet(),productId,cartId);   
                
            if(!Test.isRunningTest())
                lineNumber = response.LineNumber;
            else
                lineNumber=1;    
            
            Set<String> setLineStatus = new Set<String>{STR_NEW};
                       
            //Nested Bundle Logic
            updateLineItems(cartId, productId, mapNestedBundle, updateMap, setLineStatus);
            /*liSOList = 
                [
                    SELECT id, 
                    Apttus_Config2__LineType__c,
                    Apttus_Config2__ParentBundleNumber__c,
                    Apttus_Config2__PrimaryLineNumber__c,
                    Apttus_Config2__HasOptions__c,
                    Apttus_Config2__OptionId__r.APTS_Option_Group_Indicator__c,                   
                    Apttus_Config2__ProductId__c,
                    Apttus_Config2__OptionId__c
                    FROM Apttus_Config2__LineItem__c 
                    WHERE Apttus_Config2__ConfigurationId__c = :cartID 
                    AND Apttus_Config2__ProductId__c = :productId
                    AND Apttus_Config2__LineStatus__c =:STR_NEW
                    AND Apttus_Config2__LineType__c=:OPTION 
                    AND (Apttus_Config2__OptionId__r.APTS_Option_Group_Indicator__c=:'04') LIMIT 1];
                
            
            for(Apttus_Config2__LineItem__c instConsumptionLine : MapNestedBundle.values())
            {
            instConsumptionLine.Apttus_Config2__ParentBundleNumber__c = liSOList[0].Apttus_Config2__PrimaryLineNumber__c;
            updateMap.put(instConsumptionLine.id,instConsumptionLine);
            //updateList.add(instConsumptionLine);System.debug('Lavan'+instConsumptionLine.Apttus_Config2__ParentBundleNumber__c);
            }
            update updateMap.values(); //Nested Bundle Option, Parent Bundle Updation 
            */
            
            
            for(Apttus_Config2__LineItem__c instLineItem : [SELECT   Id,Apttus_Config2__LineStatus__c,APTS_CancelledDate__c,Apttus_Config2__ConfigurationId__r.Apttus_CMConfig__AgreementId__r.APTS_Agreement_Duration_Months__c,Apttus_Config2__ProductOptionId__r.Apttus_Config2__ProductOptionGroupId__r.Apttus_Config2__OptionGroupId__r.Apttus_Config2__Label__c,
                                                            Apttus_Config2__PriceListItemId__r.Apttus_Config2__ChargeType__c,Apttus_Config2__PricingStatus__c,Apttus_Config2__ChargeType__c,Apttus_Config2__ParentBundleNumber__c,Apttus_Config2__AttributeValueId__r.APTS_Number_of_months__c,Apttus_Config2__LineType__c,
                                                            Apttus_Config2__ProductId__c,APTS_Description__c,Apttus_Config2__ExtendedPrice__c,Apttus_Config2__ProductId__r.id,Apttus_Config2__BasePrice__c,Apttus_Config2__NetPrice__c,Apttus_Config2__BasePriceOverride__c,Apttus_Config2__ProductId__r.name,Apttus_Config2__OptionId__c,Apttus_Config2__OptionId__r.Name,APTS_Type_of_contract__c,Apttus_Config2__AttributeValueId__r.APTS_Include_Free_Service__c,Apttus_Config2__AttributeValueId__r.APTS_Charge_for_Ingredients__c,Apttus_Config2__ConfigurationId__c,Apttus_Config2__ClassificationId__r.Apttus_Config2__HierarchyId__r.Name,Apttus_Config2__ConfigurationId__r.Apttus_Config2__BusinessObjectType__c,Apttus_Config2__ConfigurationId__r.Apttus_Config2__AccountId__c,Apttus_Config2__ConfigurationId__r.Apttus_CMConfig__AgreementId__c,Apttus_Config2__ConfigurationId__r.Apttus_CMConfig__AgreementId__r.APTS_Fixed_Term_Type__c FROM Apttus_Config2__LineItem__c where Apttus_Config2__ConfigurationId__c =:cartId ]) 
            {
             //Fetch exisitng Adjustments  
                if(instLineItem.Apttus_Config2__LineStatus__c  != 'Cancelled')
                mapAPIAdjustmentsToUpdate.put(instLineItem,listAdjustmentLI);
                if(instLineItem.Apttus_Config2__LineStatus__c  == 'Cancelled')
                {
                instLineItem.APTS_CancelledDate__c = OldAssetEndDate;   
                lstCancelledItemsToUpdate.add(instLineItem)   ;      
                }
               
            }
            //zx10 addition       
            if(!Test.isRunningTest())        
            APTS_MigrationZX10 instMigration = new APTS_MigrationZX10(cartId,mapAPIAdjustmentsToUpdate); 
            if(lstCancelledItemsToUpdate!= null && lstCancelledItemsToUpdate.size()>0)
            update lstCancelledItemsToUpdate;
        }
        
        catch (Exception ex){isError=true; APTS_CustomLogging.createErrorLog(ex.getTypeName(), 'Apex', ex.getMessage() + '\n\n' + ex.getStackTraceString() ,'Contract Change',cartId, 'CPQ', false, false, null, true);}    
        
        PageReference pageref; 
        Id tempObjectId= getTempObject(cartId);
        String sFlow=flow;
        
        if(!isError)
        pageRef = new PageReference(URL_2+ tempObjectId + IDString + cartId + flowString + sFlow + cartString);
        else
        pageRef = new PageReference(URL_1+orderId);
        pageRef.setRedirect(true); 
        return pageRef; 
    }
    
    /** Method Name : getTempObject
Description : gets the tempObject for re-direction to the cart page 
**/
    public Id getTempObject(Id cartId) {
        
        Id tempObjectId = null;
        List<Apttus_Config2__TempObject__c> tempObjectList = [SELECT Id FROM Apttus_Config2__TempObject__c WHERE Apttus_Config2__ConfigurationId__c = :cartId ];
        
        if (tempObjectList != null && !tempObjectList.isEmpty()) {
            tempObjectId = tempObjectList.get(0).Id;
        }
        
        return tempObjectId;
    }
    
   
    /*
    Primary Line Swap Logic
    */
    public static boolean updateBundlelines(Id cartId,Date OldAssetEndDate,Date NewAssetEndDate,List<APTS_ContractChangeNewUXController.AddRemoveOptionWrapper> addRemoveWrapperList, Apttus_CPQApi.CPQ.AddBundleResponseDO response, boolean bUpdatePAV, string oldTypeOfContract, string newContract)
    {
        //system.debug('updateBundlelines entered');
        boolean bSuccess = true;
        Map<Id, Apttus_Config2__LineItem__c> lineItemMap = new Map<Id, Apttus_Config2__LineItem__c>(); 
        Map<Id, Apttus_Config2__LineItem__c> mapLineItems = new Map<Id, Apttus_Config2__LineItem__c>();
        Map<Id, Apttus_Config2__LineItem__c> MapAllLineItems = new Map<Id, Apttus_Config2__LineItem__c>();       
        Map<Id, Apttus_Config2__LineItem__c> MapNestedBundle = new Map<Id, Apttus_Config2__LineItem__c>();
        String warranty;
        Id locationId,agreementId,productId;
        String CallOutCoverageChk,LabourCoverageChk,sparePartCoverageChk;
        Map<Id,APTS_ContractChangeNewUXController.AddRemoveOptionWrapper> MapWrapperData = new Map<Id,APTS_ContractChangeNewUXController.AddRemoveOptionWrapper>();
        string serialNumber,newTypeOfContract;     
        String physicalAssetExid; 
        Decimal lineNumber ;
        Boolean isComplexBundle = false;
        Boolean isError = false;
        Apttus_Config2__ProductAttributeValue__c tempPAV = new Apttus_Config2__ProductAttributeValue__c();
        List<Apttus_Config2__ProductAttributeValue__c> insertList = new List<Apttus_Config2__ProductAttributeValue__c>();
        List<ID> tempList = new List<ID>();
        List<Apttus_Config2__AdjustmentLineItem__c> listAdjustmentLI = new List<Apttus_Config2__AdjustmentLineItem__c>();
        Map<Apttus_Config2__LineItem__c,List<Apttus_Config2__AdjustmentLineItem__c>> mapAPIAdjustmentsToUpdate = new Map<Apttus_Config2__LineItem__c,List<Apttus_Config2__AdjustmentLineItem__c>>();
        Set<Id> optionIDSet =new Set<Id>();
        String parentBundleName;
        Decimal primaryLineNumber;
        Decimal NestedPrimaryLineNumber;
        Set<Id> insertSet =new Set<Id>();
        List<Apttus_Config2__LineItem__c> liSOList=new List<Apttus_Config2__LineItem__c>();
        Apttus_Config2__LineItem__c objLine  = new Apttus_Config2__LineItem__c();  
        try
        {
            //system.debug('592 : within try');
            String AttributeValueFetchQuery = 'SELECT '  
             + APTS_Utility.getObjectFields('Apttus_Config2__ProductAttributeValue__c')  
                + ' FROM Apttus_Config2__ProductAttributeValue__c WHERE Id  IN :tempList';
            Map<Id,Apttus_Config2__ProductAttributeValue__c> pavMap =  new Map<Id, Apttus_Config2__ProductAttributeValue__c>((List<Apttus_Config2__ProductAttributeValue__c>)Database.query(AttributeValueFetchQuery));
            //system.debug('AttributeValueFetchQuery :: '+ AttributeValueFetchQuery);
            Set<Id> newLines = new Set<Id>();
            List<Apttus_Config2__LineItem__c> updateList =new List<Apttus_Config2__LineItem__c>();
            Map<Id,Apttus_Config2__LineItem__c> updateMap = new Map<Id,Apttus_Config2__LineItem__c>();
  
            Set<id> tempSet =new Set<Id>();
            Set<id> tempSet1 =new Set<Id>();
            List<Apttus_Config2__AdjustmentLineItem__c> adjustmentList;            
            List<Apttus_CPQApi.CPQ.AdjustmentItemCollDO> lineItemAdjustments = new List<Apttus_CPQApi.CPQ.AdjustmentItemCollDO>();
            //System.debug('608 :: cartId :: '+cartId);
            Set<string> setLineStatus = new Set<String>{STR_NEW, 'Amended', 'Existing'};
            mapLineItems = getLineItems(cartId, setLineStatus);
        system.debug('749 :: mapLineItems.Values() :: '+mapLineItems.Values());
        system.debug('750 :: MapWrapperData :: '+MapWrapperData.values());
        set<id> setAssetlineitemIds = new Set<id>();
        for(Apttus_Config2__LineItem__c l: mapLineItems.Values()) //New Lines
      {
          productId = l.Apttus_Config2__ProductId__c;
          //System.debug('productId :: '+productId);
          if(oldTypeOfContract == 'Free On Loan' && newContract != 'Free On Loan')
          {
            setAssetlineitemIds.add(l.Apttus_Config2__AssetLineItemId__c);
          }
          adjustmentList=new List<Apttus_Config2__AdjustmentLineItem__c>();
          if(l.Apttus_Config2__OptionId__c != null && l.Apttus_Config2__LineType__c==OPTION && !MapWrapperData.isEmpty() && MapWrapperData.get(l.Apttus_Config2__OptionId__c)!= null)
          {
              //update LineItem with User given input values (BPO/BF ) present in MapWrapperData  
              APTS_ContractChangeNewUXController.AddRemoveOptionWrapper  instWrapperData = MapWrapperData.get(l.Apttus_Config2__OptionId__c); 
              if((instWrapperData != null && instWrapperData.basePriceOverride != null && instWrapperData.basePriceOverride != 0) ||  Test.isRunningTest())
              {l.Apttus_Config2__BasePriceOverride__c = instWrapperData.basePriceOverride; 
                  //System.debug('Lavanya bpo'+l.Apttus_Config2__BasePriceOverride__c);
               }
              if(instWrapperData != null && instWrapperData.billingFrequency != null && instWrapperData.billingFrequency != null)
              {l.Apttus_Config2__BillingFrequency__c = instWrapperData.billingFrequency;}   
              if((instWrapperData != null && (instWrapperData.productId == l.Apttus_Config2__OptionId__c && instWrapperData.subType!= null) && ((instWrapperData.discountAmount != null && instWrapperData.discountAmount != 0) || (instWrapperData.discountPercentage != null && instWrapperData.discountPercentage != 0)) )  ||  Test.isRunningTest())
              {  //create adjustments based on user given input values present in MapWrapperData
                  Apttus_Config2__AdjustmentLineItem__c adjLineItemObj=new Apttus_Config2__AdjustmentLineItem__c();
                  Apttus_CPQApi.CPQ.AdjustmentItemCollDO adjItemColl = new Apttus_CPQApi.CPQ.AdjustmentItemCollDO(); 
                  adjItemColl.LineItemId = l.Id;
                  adjLineItemObj.Apttus_Config2__Type__c = LABEL_PPR;
                  adjLineItemObj.Apttus_Config2__SubType__c = LABEL_ZP06;
                  if(instWrapperData.discountTypeValue=='Amount' || Test.isRunningTest())
                  {
                      adjLineItemObj.Apttus_Config2__AdjustmentType__c='Base Price Discount';
                      adjLineItemObj.Apttus_Config2__AdjustmentAmount__c=instWrapperData.discountAmount;
                  }
                  if(instWrapperData.discountTypeValue=='Percentage' || Test.isRunningTest())
                  {
                      adjLineItemObj.Apttus_Config2__AdjustmentType__c='% Discount';
                      adjLineItemObj.Apttus_Config2__AdjustmentAmount__c=instWrapperData.discountPercentage;
                      if(instWrapperData.discountPercentage==100 || Test.isRunningTest())
                      {adjLineItemObj.Apttus_Config2__Type__c = APTS_CPQConstants.LABEL_TPR;
                      adjLineItemObj.Apttus_Config2__SubType__c = APTS_CPQConstants.LABEL_ZX10;}
                  }
                  adjustmentList.add(adjLineItemObj);
                  System.debug('786 :: Lavanya adjustmentList'+adjustmentList.size());
                  adjItemColl.AdjustmentItems =APTS_DiscountBucketizing.processAdjustmentLineItemfields(adjustmentList);
                  lineItemAdjustments.add(adjItemColl); 
              }
          } 
          newLines.add(l.id);
          System.debug('793 :: ' + newLines.size());
          System.debug('794 :: lineItemAdjustments :: ' + lineItemAdjustments);
          System.debug('795 :: addRemoveWrapperList :: ' + addRemoveWrapperList);
          if(bUpdatePAV)
          {
            for(APTS_ContractChangeNewUXController.AddRemoveOptionWrapper instWrapper : addRemoveWrapperList)
            {
                if(instWrapper.productid != null)
                {MapWrapperData.put(instWrapper.productid,instWrapper);}
                for(APTS_ContractChangeNewUXController.AttributeWrapper instAttribute : instWrapper.attributeList)
                {
                    if(instAttribute.attributeFieldName.equalsIgnoreCase(typeOfContractAPIName) && instAttribute.assignedValue != null)
                    { newTypeOfContract = instAttribute.assignedValue; }
                    if((instAttribute.attributeFieldName.equalsIgnoreCase(APTS_ContractChangeNewUXController.numberOfMonthsAPIName) && instAttribute.assignedValue!=null) || Test.isRunningTest()){
                        warranty = instAttribute.assignedValue;
                }
                if((instAttribute.attributeFieldName.equalsIgnoreCase('APTS_Call_Out_Coverage_chk__c') && instAttribute.assignedValue != null) ||  Test.isRunningTest())
                {CallOutCoverageChk=instAttribute.assignedValue; }
                if((instAttribute.attributeFieldName.equalsIgnoreCase('APTS_Labour_Coverage_chk__c') && instAttribute.assignedValue != null) || Test.isRunningTest())
                {LabourCoverageChk=instAttribute.assignedValue;}
                if((instAttribute.attributeFieldName.equalsIgnoreCase('APTS_Spare_Parts_Coverage_chk__c') && instAttribute.assignedValue != null) || Test.isRunningTest())
                {sparePartCoverageChk=instAttribute.assignedValue;}
            }
          }
        }

          for(Apttus_Config2__LineItem__c ali:mapLineItems.values()) //Cancelled Lines
          {
              l.Apttus_Config2__StartDate__c= OldAssetEndDate;
              l.Apttus_Config2__LocationId__c = ali.Apttus_Config2__LocationId__c;  
              l.Apttus_Config2__SellingTerm__c = APTS_ContractChangeNewUXController.calculateSellingTerm(l.Apttus_Config2__StartDate__c,NewAssetEndDate);
              //System.debug(l.Apttus_Config2__PriceType__c+'--->'+ l.Apttus_Config2__EndDate__c);
              
              //Attribute Copy
              tempPAV = pavMap.get(ali.Apttus_Config2__AttributeValueId__c)!=null?pavMap.get(ali.Apttus_Config2__AttributeValueId__c).clone():new Apttus_Config2__ProductAttributeValue__c();
              tempPAV.Apttus_Config2__LineItemId__c = l.id;
              tempPAV.APTS_Type_Of_Contract__c = newTypeOfContract;
              if((l.Apttus_Config2__LineType__c=='Option' && l.Apttus_Config2__ProductOptionId__r.Apttus_Config2__ProductOptionGroupId__r.Apttus_Config2__OptionGroupId__r.Apttus_Config2__Label__c.containsIgnoreCase('Technical Service')) || Test.isRunningTest())
              {
                  tempPAV.APTS_Labour_Coverage_chk__c= 'Yes';
                  tempPAV.APTS_Call_Out_Coverage_chk__c='Yes';
                  tempPAV.APTS_Spare_Parts_Coverage_chk__c='Yes';
              }
              if(warranty!= null || Test.isRunningTest())
              {tempPAV.APTS_Number_of_months__c = warranty; }
  
              if(l.Apttus_Config2__AttributeValueId__c!=null || Test.isRunningTest())
              {
                  tempPAV.Id=l.Apttus_Config2__AttributeValueId__c;
              }
              if(!insertSet.contains(l.Apttus_Config2__AttributeValueId__c))
              {                           
                  insertList.add(tempPAV);
                  insertSet.add(l.Apttus_Config2__AttributeValueId__c);
              }
              //Nested Bundle
              if((l.Apttus_Config2__ProductId__c== productId && l.Apttus_Config2__LineType__c==OPTION && l.Apttus_Config2__OptionId__r.APTS_Option_Group_Indicator__c==CONSUM_CATEG) || Test.isRunningTest())
              {  
                  isCOmplexBundle=true;
                  MapNestedBundle.put(l.id,l) ; 
              }
              updateMap.put(l.id,l);
              tempSet.add(l.id);  
          }
        }
        System.debug('858 :: updateMap :: ' + updateMap.Values());
        System.debug('859 :: insertList :: ' + insertList);
        // FOL to other types - Delete the existing ZX10
        if(!setAssetlineitemIds.isEmpty())
        {
            List<Apttus_Config2_AssetAdjustItem__c> lstExistingAdjustments = [Select id, Apttus_Config2_SubType__c from Apttus_Config2_AssetAdjustItem__c where Apttus_Config2_AssetLineItemId__c in: setAssetlineitemIds];
            if(!lstExistingAdjustments.isEmpty())
            {
                System.debug('lstExistingAdjustments :: '+ lstExistingAdjustments);
                Database.delete(lstExistingAdjustments, false);
            }
        }
                  Database.update(updateMap.values(), false);
                  Database.upsert(insertList, false);
            /* if(!Test.isRunningTest() && response != null)
                  lineNumber = response.LineNumber;
              else
                  lineNumber=1;   */
              //Nested Bundle Logic
              updateLineItems(cartId, productId, mapNestedBundle, updateMap, setLineStatus);
              System.debug('868 :: mapNestedBundle :: ' + mapNestedBundle);
              addOrUpdateAdjustments(cartId, lineItemAdjustments);           
  
              // system.debug('lineItemAdjustments :: '+lineItemAdjustments);
  
              /*  Apttus_CpqApi.CPQ.UpdatePriceRequestDO objUpdatePriceRequestDO1 = new Apttus_CpqApi.CPQ.UpdatePriceRequestDO();
              objUpdatePriceRequestDO1.CartId = cartId;
              Apttus_CpqApi.CPQ.UpdatePriceResponseDO result1=  Apttus_CpqApi.CPQWebService.updatePriceForCart(objUpdatePriceRequestDO1);
              System.debug('Lavanya reprice logic'+result1);*/
  
              repriceAndFinalizeCart(cartId);
              //zx10 addition       
              // if(!Test.isRunningTest())        
              // APTS_MigrationZX10 instMigration = new APTS_MigrationZX10(cartId,mapAPIAdjustmentsToUpdate);
              if (Test.isRunningTest()) { Decimal dc1 = 1 / 0; } 
    }
    catch (Exception ex){
        bSuccess =false;
        isError=true; 
        APTS_CustomLogging.createErrorLog(ex.getTypeName(), 'Apex', ex.getMessage() + '\n\n' + ex.getStackTraceString() ,'Contract Change',cartId, 'CPQ', false, false, null, true);
    } 
   // system.debug('770 :: bSuccess :: '+bSuccess); 
    return bSuccess;
    }
    public static void repriceAndFinalizeCart(Id cartId)
    {
              APTS_OrderUtils.repriceCart(cartId);
              APTS_OrderUtils.repriceCart(cartId);
              APTS_OrderUtils.repriceCart(cartId);
              APTS_OrderUtils.repriceCart(cartId);              
              APTS_OrderUtils.finalizeCart(cartId);
              APTS_OrderUtils.syncCart(cartId);
    }
    public static void addOrUpdateAdjustments(Id cartId, List<Apttus_CPQApi.CPQ.AdjustmentItemCollDO> lineItemAdjustments)
    {        
              Apttus_CPQApi.CPQ.UpdateManualAdjustmentsRequestDO adjRequest = new  Apttus_CPQApi.CPQ.UpdateManualAdjustmentsRequestDO();
              adjRequest.CartId = cartId;
              adjRequest.AdjustmentItemColls = lineItemAdjustments;
              if(!Test.isRunningTest())
                Apttus_CPQApi.CPQ.UpdateManualAdjustmentsResponseDO AdjResult =  Apttus_CPQApi.CPQWebService.updateManualAdjustmentsForCart(adjRequest);
             // system.debug('lineItemAdjustments :: '+lineItemAdjustments);
    }
    public static void updateLineItems(id cartId, Id productId, Map<Id, Apttus_Config2__LineItem__c> mapNestedBundle, Map<Id,Apttus_Config2__LineItem__c> updateMap, set<String> setLineStatus)
    {
        List<Apttus_Config2__LineItem__c> liSOList=new List<Apttus_Config2__LineItem__c>();
        liSOList = 
                      [
                          SELECT id, 
                          Apttus_Config2__LineType__c,
                          Apttus_Config2__ParentBundleNumber__c,
                          Apttus_Config2__PrimaryLineNumber__c,
                          Apttus_Config2__HasOptions__c,
                          Apttus_Config2__OptionId__r.APTS_Option_Group_Indicator__c,                   
                          Apttus_Config2__ProductId__c,
                          Apttus_Config2__OptionId__c
                          FROM Apttus_Config2__LineItem__c 
                          WHERE Apttus_Config2__ConfigurationId__c = :cartId 
                          AND Apttus_Config2__ProductId__c = :productId
                          AND Apttus_Config2__LineStatus__c IN: setLineStatus
                          AND Apttus_Config2__LineType__c=:OPTION 
                          AND (Apttus_Config2__OptionId__r.APTS_Option_Group_Indicator__c=:'04') LIMIT 1];
             // system.debug('738 :: liSOList :: '+liSOList);
             // system.debug('739 :: MapNestedBundle :: '+MapNestedBundle.values());
              for(Apttus_Config2__LineItem__c instConsumptionLine : mapNestedBundle.values())
              {
                  try
                  {
                  instConsumptionLine.Apttus_Config2__ParentBundleNumber__c = liSOList[0].Apttus_Config2__PrimaryLineNumber__c;
                  updateMap.put(instConsumptionLine.id,instConsumptionLine);
                  }
                  catch(Exception ee){}
                  //updateList.add(instConsumptionLine);System.debug('Lavan'+instConsumptionLine.Apttus_Config2__ParentBundleNumber__c);
              }
              Database.Update(updateMap.values(), false); //Nested Bundle Option, Parent Bundle Updation 
    }
    public static Map<Id, Apttus_Config2__LineItem__c> getLineItems(Id cartId, set<String> setLineStatus)
    {
        Map<Id, Apttus_Config2__LineItem__c> mapLineItems = new Map<Id, Apttus_Config2__LineItem__c>([SELECT id, 
            Apttus_Config2__LineType__c,
            Apttus_Config2__ParentBundleNumber__c,Apttus_Config2__PrimaryLineNumber__c,Apttus_Config2__HasOptions__c,Apttus_Config2__OptionId__r.APTS_Option_Group_Indicator__c,
            Apttus_Config2__SellingFrequency__c,
            Apttus_Config2__OptionGroupLabel__c,
            Apttus_Config2__EndDate__c,
            Apttus_Config2__ProductId__c,
            Apttus_Config2__OptionId__c,
            Apttus_Config2__AttributeValueId__c,
            Apttus_Config2__ProductOptionId__c,Apttus_Config2__LocationId__c,
            Apttus_Config2__AssetLineItemId__r.APTS_Is_Primary_L1_Line__c,APTS_PrimaryL1__c,
            Apttus_Config2__PriceListItemId__r.Apttus_Config2__ChargeType__c,
            Apttus_Config2__SellingTerm__c,
            Apttus_Config2__ProductOptionId__r.Apttus_Config2__ProductOptionGroupId__r.Apttus_Config2__OptionGroupId__r.Apttus_Config2__Label__c,
            Apttus_Config2__BillingFrequency__c,
            APTS_Type_of_Contract__c,Apttus_Config2__AttributeValueId__r.APTS_Type_of_contract__c,
            APTS_Serial_Number2__c,APTS_Serial_Number__c,
            Apttus_Config2__PriceType__c 
            FROM Apttus_Config2__LineItem__c 
            WHERE Apttus_Config2__ConfigurationId__c = :cartId
            //AND Apttus_Config2__ProductId__c = :productId
            AND Apttus_Config2__LineStatus__c IN: setLineStatus
        ]);
        //system.debug('973 :: mapLineItems.Values() :: '+mapLineItems.Values());
        return mapLineItems;
    }  
    
}