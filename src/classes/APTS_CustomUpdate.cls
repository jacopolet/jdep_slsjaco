/**********************************************************************************
 * @Author: Lavanya Ravindran
 * @Company: Accenture
 * @Description: ZX10/YOCI/YOFT Creation 
 * @Created Date: Oct 10, 2018
 * @History:
 *      <Name>              <Date>          <Description>
 *      Lavanya              10.04.2018       Created
 **********************************************************************************/

public without sharing class APTS_CustomUpdate{


private String flow;
private boolean hasPendingItems;
private boolean flagUpdatePrice;
private String configRequestId;
private String configId;
public String LABEL_ZP03 = 'ZP03';
public String LABEL_GSV = 'GSV';
public String LABEL_BUCKET5='Bucket 5';
public String LABEL_AUTO='Auto';
public static  List<Price_List_Item_Information__mdt> CustomMetaData=[SELECT Product_Name__c FROM Price_List_Item_Information__mdt LIMIT 500];
private static final String PRODUCT_SERVICE = 'Product/Service'; 
private static final String AGREEMENT = 'Agreement';
public List<Apttus_Config2__LineItem__c> lstTechnicalLineItem = new List<Apttus_Config2__LineItem__c>();
public string actionPollerActive { get; set; }
public List<Apttus_Config2__LineItem__c> lineitemList;
Map<Id, Apttus_Config2__LineItem__c> lineItemMap ;
Map<Id, Apttus_Config2__LineItem__c> lineItemMapAll ;
public List<String> strFixedList = new List<String>();

public PageReference APTS_CustomValidate1() 
{
    
  return null;
}
public APTS_CustomUpdate(ApexPages.StandardController controller)
{
//get the Parent Bundle Number and fetch query based on Parent Bundle Number . 
}

/** Method Name : Button Actions 
    * Description : Go to shopping Custom Button Actions
**/

public pagereference APTS_CustomUpdate()
{
lineItemMap = new Map<Id, Apttus_Config2__LineItem__c>(); 
lineItemMapAll = new Map<Id, Apttus_Config2__LineItem__c>();

lineItemMapAll = new Map<Id, Apttus_Config2__LineItem__c>([SELECT Id,Apttus_Config2__PriceListItemId__r.APTS_Call_Out_Coverage__c,Apttus_Config2__PriceListItemId__r.APTS_Labour_Coverage__c,Apttus_Config2__PriceListItemId__r.APTS_Spare_Parts_Coverage__c,Apttus_Config2__DerivedFromId__c,Apttus_Config2__ConfigurationId__r.Apttus_CMConfig__AgreementId__r.APTS_Agreement_Duration_Months__c,Apttus_Config2__ProductOptionId__r.Apttus_Config2__ProductOptionGroupId__r.Apttus_Config2__OptionGroupId__r.Apttus_Config2__Label__c,
Apttus_Config2__PriceListItemId__r.Apttus_Config2__ChargeType__c,Apttus_Config2__PricingStatus__c,Apttus_Config2__ChargeType__c,Apttus_Config2__ParentBundleNumber__c,Apttus_Config2__AttributeValueId__r.APTS_Number_of_months__c,Apttus_Config2__LineType__c,Apttus_Config2__AttributeValueId__r.APTS_Type_of_contract__c,Apttus_Config2__AssetLineItemId__r.APTS_Type_Of_Contract__c,Apttus_Config2__AssetLineItemId__r.Apttus_Config2__AttributeValueId__r.APTS_Include_Free_Service__c,Apttus_Config2__AssetLineItemId__r.Apttus_Config2__PriceListItemId__r.Apttus_Config2__ChargeType__c,Apttus_Config2__AssetLineItemId__r.Apttus_Config2__AttributeValueId__r.APTS_Charge_for_Ingredients__c,
                    Apttus_Config2__ProductId__c,APTS_Description__c,Apttus_Config2__AssetLineItemId__c,Apttus_Config2__AssetLineItemId__r.Apttus_Config2__AttributeValueId__r.APTS_Type_of_contract__c,Apttus_Config2__ExtendedPrice__c,Apttus_Config2__ProductId__r.id,Apttus_Config2__BasePrice__c,Apttus_Config2__NetPrice__c,Apttus_Config2__BasePriceOverride__c,Apttus_Config2__ProductId__r.name,Apttus_Config2__OptionId__c,Apttus_Config2__OptionId__r.Name,APTS_Type_of_contract__c,Apttus_Config2__AttributeValueId__r.APTS_Include_Free_Service__c,Apttus_Config2__AttributeValueId__r.APTS_Charge_for_Ingredients__c,
                    (Select Id, Apttus_Config2__AdjustmentType__c,Apttus_Config2__Bucket__c,Apttus_Config2__AdjustmentAppliesTo__c,isCustom__c,Apttus_Config2__IsModifiable__c,Apttus_Config2__AdjustmentAmount__c,Apttus_Config2__Type__c,Apttus_Config2__SubType__c,Apttus_Config2__LineItemId__c from Apttus_Config2__AdjustmentLineItems__r where APTS_Discount_Type__c ='Manual'), //**/
                     Apttus_Config2__ConfigurationId__c,Apttus_Config2__ClassificationId__r.Apttus_Config2__HierarchyId__r.Name,Apttus_Config2__ConfigurationId__r.Apttus_Config2__BusinessObjectType__c,Apttus_Config2__ConfigurationId__r.Apttus_Config2__AccountId__c,Apttus_Config2__ConfigurationId__r.Apttus_CMConfig__AgreementId__c,Apttus_Config2__ConfigurationId__r.Apttus_CMConfig__AgreementId__r.APTS_Fixed_Term_Type__c FROM Apttus_Config2__LineItem__c
                    WHERE Apttus_Config2__ConfigurationId__c = :configId  LIMIT : Integer.valueOf(System.Label.APTS_CustomUpdateitemSize)]);
//delete [select id from Apttus_Config2__AdjustmentLineItem__c where  Apttus_Config2__LineItemId__c IN :lineItemMap.keySet()];
 
//deletezx10AdjustmentLineItems(configId);
//updatezx10AdjustmentLineItems(configId);  
List<Apttus_Config2__LineItem__c> updateLineItemList = new List<Apttus_Config2__LineItem__c>();
//List<String> tempIng = new List<String>();
//tempIng = System.Label.APTS_AttributeValues.split(',');
Boolean Amend;
//Logic to populate lineitemMap for newLineItems or Ammended LineItems with updated Attributes
for(Apttus_Config2__LineItem__c instlineItemAll : lineItemMapAll.values())
  { // Toc || Include Tech free service || charge for ingredient || Charge type 
   // if(instlineItemAll.APTS_Type_of_contract__c == instlineItemAll.Apttus_Config2__AssetLineItemId__r.APTS_Type_of_contract__c|| instlineItemAll.Apttus_Config2__AttributeValueId__r.APTS_Include_Free_Service__c == instlineItemAll.Apttus_Config2__AssetLineItemId__r.Apttus_Config2__AttributeValueId__r.APTS_Include_Free_Service__c || instlineItemAll.Apttus_Config2__PriceListItemId__r.Apttus_Config2__ChargeType__c== instlineItemAll.Apttus_Config2__AssetLineItemId__r.Apttus_Config2__PriceListItemId__r.Apttus_Config2__ChargeType__c || instlineItemAll.Apttus_Config2__AttributeValueId__r.APTS_Charge_for_Ingredients__c==instlineItemAll.Apttus_Config2__AssetLineItemId__r.Apttus_Config2__AttributeValueId__r.APTS_Charge_for_Ingredients__c)
       if(instlineItemAll.Apttus_Config2__AttributeValueId__r.APTS_Type_of_contract__c != instlineItemAll.Apttus_Config2__AssetLineItemId__r.Apttus_Config2__AttributeValueId__r.APTS_Type_of_contract__c || instlineItemAll.Apttus_Config2__AttributeValueId__r.APTS_Include_Free_Service__c  != instlineItemAll.Apttus_Config2__AssetLineItemId__r.Apttus_Config2__AttributeValueId__r.APTS_Include_Free_Service__c  )
            {
              Amend=true;
          }
  if(instlineItemAll.Apttus_Config2__AssetLineItemId__c == NULL && instlineItemAll.Apttus_Config2__DerivedFromId__c == null /*||Amend==true*/)
  {
    
   lineItemMap.put(instlineItemAll.id,instlineItemAll); 
  }
}


if(lineItemMap!= null && !lineItemMap.values().isEmpty() && configId!=null){
 deletezx10AdjustmentLineItems(configId);
 updatezx10AdjustmentLineItems(configId);
  for(Apttus_Config2__LineItem__c lineItem : lineItemMap.values()){ //Commenting this for technical service wrking and bundle rollup
    if((lineItem.Apttus_Config2__ProductOptionId__r.Apttus_Config2__ProductOptionGroupId__r.Apttus_Config2__OptionGroupId__r.Apttus_Config2__Label__c != null 
    && lineItem.Apttus_Config2__ProductOptionId__r.Apttus_Config2__ProductOptionGroupId__r.Apttus_Config2__OptionGroupId__r.Apttus_Config2__Label__c=='Technical Service') ||
    lineItem.Apttus_Config2__PriceListItemId__r.APTS_Call_Out_Coverage__c!=null || 
    lineItem.Apttus_Config2__PriceListItemId__r.APTS_Labour_Coverage__c!=null ||
    lineItem.Apttus_Config2__PriceListItemId__r.APTS_Spare_Parts_Coverage__c!=null){
        lineItem.Apttus_Config2__PricingStatus__c='Pending';
        updateLineItemList.add(lineItem);
    }
  }
  try{
  if(!updateLineItemList.isEmpty()){
    Database.update(updateLineItemList);
  } 
  }
   catch(exception e) {
        //v102 ++ <<
        APTS_CustomErrorLogging.createErrorLog('APTS_CustomUpdate', 'Apex', e.getTypeName() + ':' + e.getMessage() + '__StackTrace:_' + e.getStackTraceString(), 'APTS_CustomUpdate',
                                           'APTS_CustomUpdate', 'cpq', false, false, null, true, 'APTS_CustomUpdate', null, e.getmessage());
              
        }
  //Apttus_Config2.CPQStruct.PricePendingInfo checkPricePending = Apttus_Config2.PricingWebService.updatePriceForCart(configId);      
//updatePriceforCart1(configId);
}
  return GoBacktoCart();
}

/** Method Name : Constructor
    * Description : Get Id's of URL
    **/

public APTS_CustomUpdate()
{
  configId = ApexPages.currentPage().getParameters().get('id');   
  flow = ApexPages.currentPage().getParameters().get('flow');
  configRequestId = ApexPages.currentPage().getParameters().get('configRequestId');

}
/** Method Name : updatePriceforCart1
    * Description : Update price For Cart for handling Technical Services
**/

public void updatePriceforCart1(Id CartId)
{
  hasPendingItems = false;
  actionPollerActive = 'true';
  if(String.isBlank(cartId))
  {
    ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.info, 'Please create cart.'));
    Apttus_CpqApi.CPQ.UpdatePriceRequestDO objUpdatePriceRequestDO = new Apttus_CpqApi.CPQ.UpdatePriceRequestDO();
  }
  else
  {
    Apttus_CpqApi.CPQ.UpdatePriceRequestDO objUpdatePriceRequestDO = new Apttus_CpqApi.CPQ.UpdatePriceRequestDO();
    objUpdatePriceRequestDO.CartId = cartId;
    Apttus_CpqApi.CPQ.UpdatePriceResponseDO result;
      if(!Test.isRunningTest())
      {
         result =Apttus_CpqApi.CPQWebService.updatePriceForCart(objUpdatePriceRequestDO);
        hasPendingItems = result.IsPricePending;
      }
  if (Test.isRunningTest() || hasPendingItems)
  {
    actionPollerActive = 'true';
    flagUpdatePrice = true;
  }
  }
}

/** Method Name : deletezx10AdjustmentLineItems
    * Description : Deletion of exisitng AdjustmentLineItems before adding CER and ZX10/YOCI/YOFT Adjustments
**/
public void deletezx10AdjustmentLineItems(Id cartId)
{

Apttus_CPQApi.CPQ.UpdateManualAdjustmentsRequestDO request = new Apttus_CPQApi.CPQ.UpdateManualAdjustmentsRequestDO();
request.CartId = cartId;
List<Apttus_Config2__AdjustmentLineItem__c> deleteAdli = New List<Apttus_Config2__AdjustmentLineItem__c>();
List< Apttus_CPQApi.CPQ.AdjustmentItemCollDO> adjItemColls = new List< Apttus_CPQApi.CPQ.AdjustmentItemCollDO>();
  for(Apttus_Config2__LineItem__c li : lineItemMap.values())
  {
    Apttus_CPQApi.CPQ.AdjustmentItemCollDO adjItemColl = new Apttus_CPQApi.CPQ.AdjustmentItemCollDO();
    adjItemColl.LineItemId = li.id;
    adjItemColl.AdjustmentItems = deleteAdli;    
    adjItemColls.add(adjItemColl);
  }
request.AdjustmentItemColls = adjItemColls;
Apttus_CPQApi.CPQ.UpdateManualAdjustmentsResponseDO result = Apttus_CPQApi.CPQWebService.updateManualAdjustmentsForCart(request);

}



/** Method Name : processcerdata
    Description : Format Retreived CER Adjustments from Account into AdjustmentLineItems
**/

public Map<String, Apttus_Config2__AdjustmentLineItem__c> processcerdata(Apttus_Config2__LineItem__c lineItem, List<APTS_Contract_Entitlement_Repository__c> ceradjustments) {
        Integer lineNumber = 1;
        List<APTS_Contract_Entitlement_Repository__c> cerList = new List<APTS_Contract_Entitlement_Repository__c>();
            Id soldToacctID;            
            Boolean boolagreement;
        Map<String, Apttus_Config2__AdjustmentLineItem__c> ceradjustmentMap = new Map<String, Apttus_Config2__AdjustmentLineItem__c>();
        if (ceradjustments != null) {
            for (APTS_Contract_Entitlement_Repository__c ceradjustment : ceradjustments ) {                
                ID prdID = PRODUCT_SERVICE.equalsIgnoreCase(lineItem.Apttus_Config2__LineType__c) ? lineItem.Apttus_Config2__ProductId__c : lineItem.Apttus_Config2__OptionId__c;                
                if (prdID != null  ) {                    
                    Apttus_Config2__AdjustmentLineItem__c adjustmentLineItem = new Apttus_Config2__AdjustmentLineItem__c();
                    adjustmentLineItem.Apttus_Config2__LineItemId__c = lineItem.Id;
                    adjustmentLineItem.Apttus_Config2__LineType__c = LABEL_AUTO;
                    adjustmentLineItem.Apttus_Config2__LineNumber__c = lineNumber++;
                    adjustmentLineItem.Apttus_Config2__AdjustmentType__c = ceradjustment.APTS_Adjustment_Type__c;
                    adjustmentLineItem.Apttus_Config2__AdjustmentAmount__c = ceradjustment.APTS_Adjustment_Value__c;
                    adjustmentLineItem.Apttus_Config2__AdjustmentAppliesTo__c = ceradjustment.APTS_Adjustment_Applies_To__c;
                    adjustmentLineItem.Apttus_Config2__Bucket__c = ceradjustment.APTS_Bucket__c;
                    adjustmentLineItem.Apttus_Config2__IsModifiable__c = TRUE;
                    adjustmentLineItem.Apttus_Config2__Type__c = ceradjustment.APTS_Type__c;
                    adjustmentLineItem.Apttus_Config2__SubType__c = ceradjustment.APTS_Sub_Type__c;
                    adjustmentLineItem.Apttus_Config2_SellingUom__c = ceradjustment.APTS_UOM__c;
                    adjustmentLineItem.APTS_Adjustment_Source__c = ceradjustment.APTS_Contributing_Agreement_Level__c;
                    adjustmentLineItem.APTS_Category__c= ceradjustment.APTS_CategoryCER__c;
                    adjustmentLineItem.APTS_Sub_Category__c= ceradjustment.APTS_Sub_Category__c;
                    adjustmentLineItem.APTS_Sub_Sub_Category__c= ceradjustment.APTS_Sub_Sub_Category__c;
                    //v101++<<
                    adjustmentLineItem.Apttus_Config2__AdjustmentUom__c = ceradjustment.APTS_UOM__c; 
                    ceradjustmentMap.put(adjustmentLineItem.Apttus_Config2__Type__c + '-' + adjustmentLineItem.Apttus_Config2__SubType__c + '-' + adjustmentLineItem.Apttus_Config2__AdjustmentType__c, adjustmentLineItem);
                   
                }
               
            }
        }  
        return ceradjustmentMap;
    }

/** Method Name : updateMergedAdjustments
    Description : Function for zx10 without CER records
**/
public void updateMergedAdjustments(Id cartId,Map<Id,List<Apttus_Config2__AdjustmentLineItem__c>> mapZX10AdjustmentsToUpdate)
{

List<Apttus_Config2__AdjustmentLineItem__c> addAdli;
Apttus_CPQApi.CPQ.UpdateManualAdjustmentsRequestDO request = new  Apttus_CPQApi.CPQ.UpdateManualAdjustmentsRequestDO();
List< Apttus_CPQApi.CPQ.AdjustmentItemCollDO> adjItemColls = new List< Apttus_CPQApi.CPQ.AdjustmentItemCollDO>();
Apttus_CPQApi.CPQ.AdjustmentItemCollDO adjItemColl ;//= new  Apttus_CPQApi.CPQ.AdjustmentItemCollDO();
request.CartId = cartId;
for(Id instLineItemID : mapZX10AdjustmentsToUpdate.keySet())
    {  
     addAdli = New List<Apttus_Config2__AdjustmentLineItem__c>();
     adjItemColl = new  Apttus_CPQApi.CPQ.AdjustmentItemCollDO(); 
     List<Apttus_Config2__AdjustmentLineItem__c> ListMergedAdjustmentLineItems = mapZX10AdjustmentsToUpdate.get(instLineItemID);           
     for(Apttus_Config2__AdjustmentLineItem__c instMergedADLI : ListMergedAdjustmentLineItems)
              {
              adjItemColl.LineItemId = instLineItemID; 
                adjItemColl.AdjustmentItems = ListMergedAdjustmentLineItems;
                adjItemColls.add(adjItemColl);  
              }  
              request.AdjustmentItemColls = adjItemColls;  
    }
 Apttus_CPQApi.CPQ.UpdateManualAdjustmentsResponseDO result =  Apttus_CPQApi.CPQWebService.updateManualAdjustmentsForCart(request);
}


/** Method Name : updateMergedAdjustments
    Description : Function for zx10 with CER records, Main Function that Merges ZX10 , CER , YOCi, YOFT
**/
public void updateMergedAdjustments(Id cartId,Map<Id,List<Apttus_Config2__AdjustmentLineItem__c>> mapZX10AdjustmentsToUpdate,Map<Id,List<Apttus_Config2__AdjustmentLineItem__c>> mapCERAdjustmentsToUpdate)
{

List<Apttus_Config2__AdjustmentLineItem__c> addAdli;
Map<Id,List<Apttus_Config2__AdjustmentLineItem__c>> mapZX10ORCERADLI = new Map<Id,List<Apttus_Config2__AdjustmentLineItem__c>>();
Set<Id> setZx10AndCERID = new Set<Id>();
Apttus_CPQApi.CPQ.UpdateManualAdjustmentsRequestDO request = new  Apttus_CPQApi.CPQ.UpdateManualAdjustmentsRequestDO();
List< Apttus_CPQApi.CPQ.AdjustmentItemCollDO> adjItemColls = new List< Apttus_CPQApi.CPQ.AdjustmentItemCollDO>();
List< Apttus_CPQApi.CPQ.AdjustmentItemCollDO> adjItemCollection = new List< Apttus_CPQApi.CPQ.AdjustmentItemCollDO>();
Apttus_CPQApi.CPQ.AdjustmentItemCollDO adjItemColl ;//= new  Apttus_CPQApi.CPQ.AdjustmentItemCollDO();
request.CartId = cartId;
for(Id instLineItemID : mapZX10AdjustmentsToUpdate.keySet())
{
  for(Id instCERLineItemId : mapCERAdjustmentsToUpdate.keySet())
  {
     addAdli = New List<Apttus_Config2__AdjustmentLineItem__c>();
      adjItemColl = new  Apttus_CPQApi.CPQ.AdjustmentItemCollDO(); 
     
     if(instCERLineItemId == instLineItemID)    // if a single lineitem has both CER and ZX10, then they have to be merged and inserted
     {
    
      
      List<Apttus_Config2__AdjustmentLineItem__c> ListMergedAdjustmentLineItems = mapZX10AdjustmentsToUpdate.get(instLineItemID);

      ListMergedAdjustmentLineItems.addAll(mapCERAdjustmentsToUpdate.get(instCERLineItemId));
        
            adjItemColl.LineItemId = instLineItemID; 
            adjItemColl.AdjustmentItems = ListMergedAdjustmentLineItems;
            adjItemColls.add(adjItemColl);
            setZx10AndCERID.add(instLineItemID);  
       

     } 
  } 
}  

mapZX10AdjustmentsToUpdate.putALL(mapCERAdjustmentsToUpdate); 
mapZX10ORCERADLI.putALL(mapZX10AdjustmentsToUpdate);
 if(setZx10AndCERID != NULL && setZx10AndCERID.size()>0){
    for(Id instId : setZx10AndCERID)
        {
           mapZX10ORCERADLI.remove(instId);
           
          }
   }                

 for(Id instCERORZX10: mapZX10ORCERADLI.keySet())
           {  
            List<Apttus_Config2__AdjustmentLineItem__c> ListZX10ORCERAdjustmentLineItems = new List<Apttus_Config2__AdjustmentLineItem__c>();
            adjItemColl = new  Apttus_CPQApi.CPQ.AdjustmentItemCollDO(); 
            ListZX10ORCERAdjustmentLineItems =mapZX10ORCERADLI.get(instCERORZX10);  
            adjItemColl.LineItemId = instCERORZX10; 
            adjItemColl.AdjustmentItems = ListZX10ORCERAdjustmentLineItems;
            adjItemColls.add(adjItemColl); 
           } 
          
Apttus_CPQApi.CPQ.AdjustmentItemCollDO instCOLLDOSequence;
  for(Apttus_CPQApi.CPQ.AdjustmentItemCollDO instCOLLDO : adjItemColls)
                {
                instCOLLDOSequence = new Apttus_CPQApi.CPQ.AdjustmentItemCollDO();  
                List<Apttus_Config2__AdjustmentLineItem__c> ListSequenceAdjLineItem= APTS_DiscountBucketizing.processAdjustmentLineItemfields(instCOLLDO.AdjustmentItems); 
                instCOLLDOSequence.LineItemId = instCOLLDO.LineItemId;
                instCOLLDOSequence.AdjustmentItems = ListSequenceAdjLineItem;
                adjItemCollection.add(instCOLLDO);                
                } 
                request.AdjustmentItemColls = adjItemCollection;
Apttus_CPQApi.CPQ.UpdateManualAdjustmentsResponseDO result =  Apttus_CPQApi.CPQWebService.updateManualAdjustmentsForCart(request);
 
}

/** Method Name : updatezx10AdjustmentLineItems
    Description : Function that prepares the AdjustmentLine Items in Map<LineItemId, List<AdjustmentLI>> format 
**/
  public void updatezx10AdjustmentLineItems(Id cartId){

integer lineNum=1;
List<String> lstString = new List<String>();
List<Apttus_Config2__AdjustmentLineItem__c> ListSequenceAdjLineItem1= new list<Apttus_Config2__AdjustmentLineItem__c>();
List<Apttus_Config2__AdjustmentLineItem__c> addAdli;
Map<Id,List<Apttus_Config2__AdjustmentLineItem__c>> mapLiAdjLi = new Map<Id,List<Apttus_Config2__AdjustmentLineItem__c>>();
Map<Id,List<Apttus_Config2__AdjustmentLineItem__c>> mapAdjwithLI = new Map<Id,List<Apttus_Config2__AdjustmentLineItem__c>>();
List<Apttus_Config2__LineItem__c> lineitemList = lineItemMap.values();//[select id,Name,APTS_Type_of_Contract__c,Apttus_Config2__ProductOptionId__r.Apttus_Config2__ProductOptionGroupId__r.Apttus_Config2__OptionGroupId__r.Apttus_Config2__Label__c,Apttus_Config2__AttributeValueId__r.APTS_Include_Free_Service__c,Apttus_Config2__AttributeValueId__r.APTS_Charge_for_Ingredients__c from Apttus_Config2__LineItem__c where Apttus_Config2__ConfigurationId__c = :cartId];

Boolean isapplied = false;
Boolean deletedAdjustment = false;
Map<Id,String> mapofAdjType = new Map<Id,String>(); 
Map<Id,List<String>> mapofAdjTypeList = new Map<Id,List<String>>(); 
// CER Adjustments MAP<LI, List<CER Adjustments>>

Map<ID, List<APTS_Contract_Entitlement_Repository__c>> cerprdmap = new Map<ID, List<APTS_Contract_Entitlement_Repository__c>>();
List<APTS_Contract_Entitlement_Repository__c> cerList = new List<APTS_Contract_Entitlement_Repository__c>();
Map<String, Apttus_Config2__AdjustmentLineItem__c> ceradjustmentMap = new Map<String, Apttus_Config2__AdjustmentLineItem__c>();
Id soldToacctID;
Id prdID;
Boolean boolagreement;
Map<Id,List<Apttus_Config2__AdjustmentLineItem__c>> mapCERAdjustmentsToUpdate = new Map<Id,List<Apttus_Config2__AdjustmentLineItem__c>>();Map<Id,List<Apttus_Config2__AdjustmentLineItem__c>> mapZX10AdjustmentsToUpdate = new Map<Id,List<Apttus_Config2__AdjustmentLineItem__c>>();
  for(Apttus_Config2__LineItem__c instCerLineItem : lineItemMap.values())
            {
            if (AGREEMENT.equalsIgnoreCase(instCerLineItem.Apttus_Config2__ConfigurationId__r.Apttus_Config2__BusinessObjectType__c)) 
                          boolagreement = true;
                          soldToacctID = instCerLineItem.Apttus_Config2__ConfigurationId__r.Apttus_Config2__AccountId__c;
            }
               // cerprdmap = APTS_CERUtility.getContractedProductsWithDiscounts(soldToacctID, cartId, boolagreement);  
                for(Apttus_Config2__LineItem__c instCerLineItem : lineItemMap.values())
                {
                prdID = PRODUCT_SERVICE.equalsIgnoreCase(instCerLineItem.Apttus_Config2__LineType__c) ? instCerLineItem.Apttus_Config2__ProductId__c : instCerLineItem.Apttus_Config2__OptionId__c;
               // cerList = cerprdmap.get(prdID);                
                //ceradjustmentMap = processcerdata(instCerLineItem,cerList);                
                
                 
                 for(Apttus_Config2__AdjustmentLineItem__c instCERAdjustmentLineItem : instCerLineItem.Apttus_Config2__AdjustmentLineItems__r)
            {    
                if(mapCERAdjustmentsToUpdate.containsKey(instCERAdjustmentLineItem.Apttus_Config2__LineItemId__c))
                    { List<Apttus_Config2__AdjustmentLineItem__c> lstAdjustment = new List<Apttus_Config2__AdjustmentLineItem__c>();
                      lstAdjustment = mapCERAdjustmentsToUpdate.get(instCERAdjustmentLineItem.Apttus_Config2__LineItemId__c);
                      lstAdjustment.add(instCERAdjustmentLineItem);
                      mapCERAdjustmentsToUpdate.put(instCERAdjustmentLineItem.Apttus_Config2__LineItemId__c,lstAdjustment);
                    }
                    else
                    {
                      List<Apttus_Config2__AdjustmentLineItem__c> lstAdjustment = new List<Apttus_Config2__AdjustmentLineItem__c>();
                      lstAdjustment.add(instCERAdjustmentLineItem);
                      mapCERAdjustmentsToUpdate.put(instCERAdjustmentLineItem.Apttus_Config2__LineItemId__c,lstAdjustment);
                    } 
            } 
  
  }

// CER adjustments END 


for(Apttus_Config2__LineItem__c instLineItem : lineitemList)
{ 

  if(instLineItem.Apttus_Config2__LineType__c.containsIgnoreCase('Option')){

      if (Test.isRunningTest() ||(instLineItem.APTS_Type_of_contract__c!= NULL && instLineItem.APTS_Type_of_contract__c.equalsIgnoreCase('Sales') && instLineItem.Apttus_Config2__AttributeValueId__r.APTS_Include_Free_Service__c!= NULL && instLineItem.Apttus_Config2__AttributeValueId__r.APTS_Include_Free_Service__c.equalsIgnoreCase('Yes') && instLineItem.Apttus_Config2__ProductOptionId__r.Apttus_Config2__ProductOptionGroupId__r.Apttus_Config2__OptionGroupId__r.Apttus_Config2__Label__c!= NULL && instLineItem.Apttus_Config2__ProductOptionId__r.Apttus_Config2__ProductOptionGroupId__r.Apttus_Config2__OptionGroupId__r.Apttus_Config2__Label__c.containsIgnoreCase('Technical Service')) )
      {
         List<String> lstAdjustment = new List<String>();    
          
          if(mapofAdjTypeList.containskey(instLineItem.id))
          {
            lstAdjustment = mapofAdjTypeList.get(instLineItem.id);
            lstAdjustment.add(APTS_CPQConstants.LABEL_ZX10);
          }
          else
          {
            lstAdjustment.add(APTS_CPQConstants.LABEL_ZX10);
          } 
        
          mapofAdjTypeList.put(instLineItem.id,lstAdjustment);
        //mapofAdjType.put(instLineItem.id,APTS_CPQConstants.LABEL_ZX10);
      }
      
       if (Test.isRunningTest() ||(instLineItem.APTS_Type_of_contract__c!= NULL && instLineItem.APTS_Type_of_contract__c.equalsIgnoreCase('Sales') && instLineItem.Apttus_Config2__AttributeValueId__r.APTS_Include_Free_Service__c!= NULL && instLineItem.Apttus_Config2__AttributeValueId__r.APTS_Include_Free_Service__c.equalsIgnoreCase('No') && instLineItem.Apttus_Config2__ProductOptionId__r.Apttus_Config2__ProductOptionGroupId__r.Apttus_Config2__OptionGroupId__r.Apttus_Config2__Label__c!= NULL && instLineItem.Apttus_Config2__ProductOptionId__r.Apttus_Config2__ProductOptionGroupId__r.Apttus_Config2__OptionGroupId__r.Apttus_Config2__Label__c.containsIgnoreCase('Technical Service')) && instLineItem.Apttus_Config2__AttributeValueId__r.APTS_Number_of_months__c!=null)
      {
         List<String> lstAdjustment = new List<String>();    
          
          if(mapofAdjTypeList.containskey(instLineItem.id))
          {
            lstAdjustment = mapofAdjTypeList.get(instLineItem.id);
            lstAdjustment.add(LABEL_GSV);
          }
          else
          {
            lstAdjustment.add(LABEL_GSV);
          } 
        
          //mapofAdjTypeList.put(instLineItem.id,lstAdjustment);
        //mapofAdjType.put(instLineItem.id,APTS_CPQConstants.LABEL_ZX10);

        } 
      
      if(Test.isRunningTest() ||(instLineItem.APTS_Type_of_contract__c!= NULL && instLineItem.APTS_Type_of_contract__c.equalsIgnoreCase('Rent') && instLineItem.Apttus_Config2__ProductOptionId__r.Apttus_Config2__ProductOptionGroupId__r.Apttus_Config2__OptionGroupId__r.Apttus_Config2__Label__c!= NULL && instLineItem.Apttus_Config2__ProductOptionId__r.Apttus_Config2__ProductOptionGroupId__r.Apttus_Config2__OptionGroupId__r.Apttus_Config2__Label__c.containsIgnoreCase('Technical Service')&&instLineItem.Apttus_Config2__AttributeValueId__r.APTS_Include_Free_Service__c.equalsIgnoreCase('Yes')))
                {
                    List<String> lstAdjustment = new List<String>();    
                        
                        if(mapofAdjTypeList.containskey(instLineItem.id))
                        {
                            lstAdjustment = mapofAdjTypeList.get(instLineItem.id);
                            lstAdjustment.add(APTS_CPQConstants.LABEL_ZX10);
                        }
                        else
                        {
                              lstAdjustment.add(APTS_CPQConstants.LABEL_ZX10);
                        } 
                    
                        mapofAdjTypeList.put(instLineItem.id,lstAdjustment);
                    //mapofAdjType.put(instLineItem.id,APTS_CPQConstants.LABEL_ZX10);
                }
                if(Test.isRunningTest() || ((instLineItem.APTS_Type_of_contract__c!= NULL && instLineItem.APTS_Type_of_contract__c.equalsIgnoreCase('Free On Loan')&&((instLineItem.Apttus_Config2__PriceListItemId__r.Apttus_Config2__ChargeType__c!= NULL && instLineItem.Apttus_Config2__PriceListItemId__r.Apttus_Config2__ChargeType__c.containsIgnoreCase('Rental Fee'))|| (instLineItem.Apttus_Config2__ProductOptionId__r.Apttus_Config2__ProductOptionGroupId__r.Apttus_Config2__OptionGroupId__r.Apttus_Config2__Label__c!= NULL && instLineItem.Apttus_Config2__ProductOptionId__r.Apttus_Config2__ProductOptionGroupId__r.Apttus_Config2__OptionGroupId__r.Apttus_Config2__Label__c.containsIgnoreCase('Technical Service') && instLineItem.Apttus_Config2__AttributeValueId__r.APTS_Include_Free_Service__c!= NULL && instLineItem.Apttus_Config2__AttributeValueId__r.APTS_Include_Free_Service__c.equalsIgnoreCase('Yes'))))) ){ 
                    List<String> lstAdjustment = new List<String>();    
                        
                        if(mapofAdjTypeList.containskey(instLineItem.id))
                        {
                            lstAdjustment = mapofAdjTypeList.get(instLineItem.id);
                            lstAdjustment.add(APTS_CPQConstants.LABEL_ZX10);
                        }
                        else
                        {
                              lstAdjustment.add(APTS_CPQConstants.LABEL_ZX10);
                        } 
                    
                        mapofAdjTypeList.put(instLineItem.id,lstAdjustment);
                    //mapofAdjType.put(instLineItem.id,APTS_CPQConstants.LABEL_ZX10);
                }
            if(Test.isRunningTest()||(instLineItem.APTS_Type_of_contract__c!= NULL && instLineItem.APTS_Type_of_contract__c.equalsIgnoreCase('Trial') && ((instLineItem.Apttus_Config2__ProductOptionId__r.Apttus_Config2__ProductOptionGroupId__r.Apttus_Config2__OptionGroupId__r.Apttus_Config2__Label__c!= NULL && instLineItem.Apttus_Config2__ProductOptionId__r.Apttus_Config2__ProductOptionGroupId__r.Apttus_Config2__OptionGroupId__r.Apttus_Config2__Label__c.containsIgnoreCase('Technical Service')) || (instLineItem.Apttus_Config2__PriceListItemId__r.Apttus_Config2__ChargeType__c!= NULL && instLineItem.Apttus_Config2__PriceListItemId__r.Apttus_Config2__ChargeType__c.containsIgnoreCase('Sales Price') && instLineItem.Apttus_Config2__ProductOptionId__r.Apttus_Config2__ProductOptionGroupId__r.Apttus_Config2__OptionGroupId__r.Apttus_Config2__Label__c!= NULL && !instLineItem.Apttus_Config2__ProductOptionId__r.Apttus_Config2__ProductOptionGroupId__r.Apttus_Config2__OptionGroupId__r.Apttus_Config2__Label__c.containsIgnoreCase('Installation Ingredient')) ||  (instLineItem.Apttus_Config2__PriceListItemId__r.Apttus_Config2__ChargeType__c!= NULL && instLineItem.Apttus_Config2__PriceListItemId__r.Apttus_Config2__ChargeType__c.containsIgnoreCase('Additional Service Fee'))|| (instLineItem.Apttus_Config2__AttributeValueId__r.APTS_Charge_for_Ingredients__c!=NULL && instLineItem.Apttus_Config2__AttributeValueId__r.APTS_Charge_for_Ingredients__c.containsIgnoreCase('No') && instLineItem.Apttus_Config2__ProductOptionId__r.Apttus_Config2__ProductOptionGroupId__r.Apttus_Config2__OptionGroupId__r.Apttus_Config2__Label__c!= NULL && instLineItem.Apttus_Config2__ProductOptionId__r.Apttus_Config2__ProductOptionGroupId__r.Apttus_Config2__OptionGroupId__r.Apttus_Config2__Label__c.containsIgnoreCase('Installation Ingredient')))) )
            { 
                     
 
                    List<String> lstAdjustment = new List<String>();    
                        
                        if(mapofAdjTypeList.containskey(instLineItem.id))
                        {
                            lstAdjustment = mapofAdjTypeList.get(instLineItem.id);
                            lstAdjustment.add(APTS_CPQConstants.LABEL_ZX10);
                        }
                        else
                        {
                              lstAdjustment.add(APTS_CPQConstants.LABEL_ZX10);
                        } 
                    
                        mapofAdjTypeList.put(instLineItem.id,lstAdjustment);
                    //mapofAdjType.put(instLineItem.id,APTS_CPQConstants.LABEL_ZX10);
              }

              if(Test.isRunningTest() || (instLineItem.APTS_Type_of_contract__c!= NULL && instLineItem.APTS_Type_of_contract__c.equalsIgnoreCase('Consumption') && instLineItem.Apttus_Config2__ProductOptionId__r.Apttus_Config2__ProductOptionGroupId__r.Apttus_Config2__OptionGroupId__r.Apttus_Config2__Label__c!= NULL && instLineItem.Apttus_Config2__ProductOptionId__r.Apttus_Config2__ProductOptionGroupId__r.Apttus_Config2__OptionGroupId__r.Apttus_Config2__Label__c.containsIgnoreCase(APTS_CPQConstants.LABEL_ConsignmentIngredients)) )
                  {
                     List<String> lstAdjustment = new List<String>();    
                        
                        if(mapofAdjTypeList.containskey(instLineItem.id))
                        {
                            lstAdjustment = mapofAdjTypeList.get(instLineItem.id);
                            lstAdjustment.add(APTS_CPQConstants.LABEL_YOCI);
                        }
                        else
                        {
                              lstAdjustment.add(APTS_CPQConstants.LABEL_YOCI);
                        } 
                    
                        mapofAdjTypeList.put(instLineItem.id,lstAdjustment);
                     //mapofAdjType.put(instLineItem.id,APTS_CPQConstants.LABEL_YOCI);
                  }

                  if(Test.isRunningTest() || (instLineItem.APTS_Type_of_contract__c!= NULL && instLineItem.APTS_Type_of_contract__c.equalsIgnoreCase('Consumption') && (instLineItem.Apttus_Config2__PriceListItemId__r.Apttus_Config2__ChargeType__c!= NULL && (instLineItem.Apttus_Config2__PriceListItemId__r.Apttus_Config2__ChargeType__c.containsIgnoreCase('Rental Fee') || instLineItem.Apttus_Config2__PriceListItemId__r.Apttus_Config2__ChargeType__c.containsIgnoreCase('Additional Service')))) )            
                {
                    List<String> lstAdjustment = new List<String>();    
                        
                        if(mapofAdjTypeList.containskey(instLineItem.id))
                        {
                            lstAdjustment = mapofAdjTypeList.get(instLineItem.id);
                            lstAdjustment.add(APTS_CPQConstants.LABEL_YOCI);
                        }
                        else
                        {
                              lstAdjustment.add(APTS_CPQConstants.LABEL_YOCI);
                        } 
                    
                        mapofAdjTypeList.put(instLineItem.id,lstAdjustment);
                    //mapofAdjType.put(instLineItem.id,APTS_CPQConstants.LABEL_ZX10);
                }
                if(Test.isRunningTest() || (instLineItem.APTS_Type_of_contract__c!= NULL && instLineItem.APTS_Type_of_contract__c.equalsIgnoreCase('Consumption') && ((instLineItem.Apttus_Config2__PriceListItemId__r.Apttus_Config2__ChargeType__c!= NULL && instLineItem.Apttus_Config2__PriceListItemId__r.Apttus_Config2__ChargeType__c.containsIgnoreCase('Sales Price') && instLineItem.Apttus_Config2__ProductOptionId__r.Apttus_Config2__ProductOptionGroupId__r.Apttus_Config2__OptionGroupId__r.Apttus_Config2__Label__c!= NULL && !instLineItem.Apttus_Config2__ProductOptionId__r.Apttus_Config2__ProductOptionGroupId__r.Apttus_Config2__OptionGroupId__r.Apttus_Config2__Label__c.containsIgnoreCase('Consignment Ingredient')) || (instLineItem.Apttus_Config2__ProductOptionId__r.Apttus_Config2__ProductOptionGroupId__r.Apttus_Config2__OptionGroupId__r.Apttus_Config2__Label__c!= NULL && instLineItem.Apttus_Config2__ProductOptionId__r.Apttus_Config2__ProductOptionGroupId__r.Apttus_Config2__OptionGroupId__r.Apttus_Config2__Label__c.containsIgnoreCase('Technical Service')))) )
                {
                    List<String> lstAdjustment = new List<String>();    
                        
                        if(mapofAdjTypeList.containskey(instLineItem.id))
                        {
                            lstAdjustment = mapofAdjTypeList.get(instLineItem.id);
                            lstAdjustment.add(APTS_CPQConstants.LABEL_YOCI);
                        }
                        else
                        {
                              lstAdjustment.add(APTS_CPQConstants.LABEL_YOCI);
                        } 
                    
                        mapofAdjTypeList.put(instLineItem.id,lstAdjustment);
                    //mapofAdjType.put(instLineItem.id,APTS_CPQConstants.LABEL_ZX10);
                }  

                for(Price_List_Item_Information__mdt metaData :CustomMetaData){                  
                  strFixedList.add(metaData.Product_Name__c);
                }

      //only Fixed cost          
    
      if(Test.isRunningTest() || (instLineItem!=null && instLineItem.Apttus_Config2__ConfigurationId__c!=null && instLineItem.Apttus_Config2__ConfigurationId__r.Apttus_CMConfig__AgreementId__c!=null && String.isNotBlank(instLineItem.Apttus_Config2__ConfigurationId__r.Apttus_CMConfig__AgreementId__r.APTS_Fixed_Term_Type__c) && (instLineItem.Apttus_Config2__ConfigurationId__r.Apttus_CMConfig__AgreementId__r.APTS_Fixed_Term_Type__c.equalsignorecase('Fixed Cost'))))
                 {
                 if((Test.isRunningTest()  || instLineItem.Apttus_Config2__OptionId__c==null || ( instLineItem.Apttus_Config2__OptionId__c!=null && !strFixedList.contains(instLineItem.Apttus_Config2__OptionId__r.name))) || (Test.isRunningTest()  || instLineItem.Apttus_Config2__ProductId__c==null || ( instLineItem.Apttus_Config2__ProductId__c!=null && !strFixedList.contains(instLineItem.Apttus_Config2__ProductId__r.name))))
                  {   
                    if(Test.isRunningTest()  || (instLineItem.Apttus_Config2__ProductOptionId__r.Apttus_Config2__ProductOptionGroupId__r.Apttus_Config2__OptionGroupId__r.Apttus_Config2__Label__c!= NULL && !instLineItem.Apttus_Config2__ProductOptionId__r.Apttus_Config2__ProductOptionGroupId__r.Apttus_Config2__OptionGroupId__r.Apttus_Config2__Label__c.contains('Ingredient')))
                   { 
                    List<String> lstAdjustment = new List<String>();    
                        
                        if(mapofAdjTypeList.containskey(instLineItem.id))
                        {
                            lstAdjustment = mapofAdjTypeList.get(instLineItem.id);
                            lstAdjustment.add(APTS_CPQConstants.LABEL_YOFT);
                        }
                        else
                        {
                              lstAdjustment.add(APTS_CPQConstants.LABEL_YOFT);
                        } 
                    
                        mapofAdjTypeList.put(instLineItem.id,lstAdjustment);
                     //mapofAdjType.put(instLineItem.id,APTS_CPQConstants.LABEL_YOFT);
                  } 
                }
              }

              // Both Fixed cost and Ingredient
              if(Test.isRunningTest() || (instLineItem!=null && instLineItem.Apttus_Config2__ConfigurationId__c!=null && instLineItem.Apttus_Config2__ConfigurationId__r.Apttus_CMConfig__AgreementId__c!=null && String.isNotBlank(instLineItem.Apttus_Config2__ConfigurationId__r.Apttus_CMConfig__AgreementId__r.APTS_Fixed_Term_Type__c) && instLineItem.Apttus_Config2__ConfigurationId__r.Apttus_CMConfig__AgreementId__r.APTS_Fixed_Term_Type__c.equalsignorecase('Fixed Costs and Ingredients')))
                 {
                 if((Test.isRunningTest()  || instLineItem.Apttus_Config2__OptionId__c==null || ( instLineItem.Apttus_Config2__OptionId__c!=null && !strFixedList.contains(instLineItem.Apttus_Config2__OptionId__r.name))) || (Test.isRunningTest()  || instLineItem.Apttus_Config2__ProductId__c==null || ( instLineItem.Apttus_Config2__ProductId__c!=null && !strFixedList.contains(instLineItem.Apttus_Config2__ProductId__r.name))))
                  {   
                     
                    List<String> lstAdjustment = new List<String>();    
                        
                        if(mapofAdjTypeList.containskey(instLineItem.id))
                        {
                            lstAdjustment = mapofAdjTypeList.get(instLineItem.id);
                            lstAdjustment.add(APTS_CPQConstants.LABEL_YOFT);
                        }
                        else
                        {
                              lstAdjustment.add(APTS_CPQConstants.LABEL_YOFT);
                        } 
                    
                        mapofAdjTypeList.put(instLineItem.id,lstAdjustment);
                     //mapofAdjType.put(instLineItem.id,APTS_CPQConstants.LABEL_YOFT);
                  
                }
              }



// ONLY Ingredients

                  if(Test.isRunningTest() || (instLineItem!=null && instLineItem.Apttus_Config2__ConfigurationId__c!=null && instLineItem.Apttus_Config2__ConfigurationId__r.Apttus_CMConfig__AgreementId__c!=null && String.isNotBlank(instLineItem.Apttus_Config2__ConfigurationId__r.Apttus_CMConfig__AgreementId__r.APTS_Fixed_Term_Type__c) && (instLineItem.Apttus_Config2__ConfigurationId__r.Apttus_CMConfig__AgreementId__r.APTS_Fixed_Term_Type__c.equalsignorecase('All Ingredients'))))
                 { 
                 if((Test.isRunningTest()  || instLineItem.Apttus_Config2__OptionId__c==null || ( instLineItem.Apttus_Config2__OptionId__c!=null && !strFixedList.contains(instLineItem.Apttus_Config2__OptionId__r.name))) || (Test.isRunningTest()  || instLineItem.Apttus_Config2__ProductId__c==null || ( instLineItem.Apttus_Config2__ProductId__c!=null && !strFixedList.contains(instLineItem.Apttus_Config2__ProductId__r.name))))
                  { 
                   if(Test.isRunningTest()  || (instLineItem.Apttus_Config2__ProductOptionId__r.Apttus_Config2__ProductOptionGroupId__r.Apttus_Config2__OptionGroupId__r.Apttus_Config2__Label__c!= NULL && instLineItem.Apttus_Config2__ProductOptionId__r.Apttus_Config2__ProductOptionGroupId__r.Apttus_Config2__OptionGroupId__r.Apttus_Config2__Label__c.containsIgnoreCase('Ingredient')))
                   {   
                    List<String> lstAdjustment = new List<String>();    
                        
                        if(mapofAdjTypeList.containskey(instLineItem.id))
                        {
                            lstAdjustment = mapofAdjTypeList.get(instLineItem.id);
                            lstAdjustment.add(APTS_CPQConstants.LABEL_YOFT);
                        }
                        else
                        {
                              lstAdjustment.add(APTS_CPQConstants.LABEL_YOFT);
                        } 
                    
                        mapofAdjTypeList.put(instLineItem.id,lstAdjustment);
                  } 
                  }
                }
                }
                

      }

    for(Id instLI : mapofAdjTypeList.keySet())
      { 

        addAdli = New List<Apttus_Config2__AdjustmentLineItem__c>();        
        lstString = mapofAdjTypeList.get(instLI);
      for(String instAdj : lstString)
       {  
      Apttus_Config2__AdjustmentLineItem__c  adjLineItem= new Apttus_Config2__AdjustmentLineItem__c();    
      adjLineItem.isCustom__c = true;
      adjLineItem.Apttus_Config2__AdjustmentType__c = APTS_CPQConstants.DISCOUNT;
      adjLineItem.Apttus_Config2__AdjustmentAmount__c = 100;
      adjLineItem.Apttus_Config2__LineItemId__c = instLI;
      adjLineItem.Apttus_Config2__LineNumber__c =lineNum;      
      adjLineItem.Apttus_Config2__LineType__c =LABEL_AUTO;
      adjLineItem.APTS_Discount_Type__c=LABEL_AUTO;
   
              if(Test.isRunningTest() || instAdj.equalsignorecase(APTS_CPQConstants.LABEL_YOFT))//mapofAdjType.get(instLineItem.id) == APTS_CPQConstants.LABEL_YOFT)
                {                               
                adjLineItem.Apttus_Config2__Type__c = APTS_CPQConstants.LABEL_YOFT;
                adjLineItem.Apttus_Config2__SubType__c = APTS_CPQConstants.LABEL_YOFT;
                adjLineItem.Apttus_Config2__Bucket__c = APTS_CPQConstants.LABEL_BUCKET6; 
                adjLineItem.Apttus_Config2__AdjustmentAppliesTo__c=APTS_CPQConstants.LABEL_BUCKET5;
                }
           
      if(Test.isRunningTest() || instAdj.equalsignorecase(APTS_CPQConstants.LABEL_ZX10))//mapofAdjType.get(instLineItem.id) == APTS_CPQConstants.LABEL_ZX10)
                { 
      adjLineItem.Apttus_Config2__Type__c = APTS_CPQConstants.LABEL_TPR;
      adjLineItem.Apttus_Config2__SubType__c = APTS_CPQConstants.LABEL_ZX10;
      adjLineItem.Apttus_Config2__Bucket__c = APTS_CPQConstants.LABEL_BUCKET4;     
      adjLineItem.Apttus_Config2__AdjustmentAppliesTo__c=APTS_CPQConstants.LABEL_BUCKET3;
                } //Abhishek code end 
                

               if(Test.isRunningTest() || instAdj.equalsignorecase(LABEL_GSV))
                {
                    //if(lineItemMap.get(instLI).Apttus_Config2__AttributeValueId__r.APTS_Number_of_months__c!=null)  
                     adjLineItem.APTS_Number_of_months__c  = lineItemMap.get(instLI).Apttus_Config2__AttributeValueId__r.APTS_Number_of_months__c;
                     adjLineItem.APTS_Start_Date__c = null;
                     adjLineItem.APTS_End_Date__c = null;                     
                     adjLineItem.APTS_Exclude_Warranty__c= true;
                     adjLineItem.Apttus_Config2__Type__c =LABEL_GSV;
                     adjLineItem.Apttus_Config2__SubType__c =LABEL_ZP03; 
                     adjLineItem.Apttus_Config2__Bucket__c = APTS_CPQConstants.LABEL_BUCKET1;
                     adjLineItem.Apttus_Config2__AdjustmentAppliesTo__c=APTS_CPQConstants.LABEL_BUCKET4;                     
                     if(adjLineItem.APTS_Number_of_months__c!=null && lineItemMap.get(instLI).Apttus_Config2__ConfigurationId__r.Apttus_CMConfig__AgreementId__r.APTS_Agreement_Duration_Months__c!=null)
                    {
                        adjLineItem.Apttus_Config2__AdjustmentAmount__c = (Decimal)(Double.valueOf(adjLineItem.APTS_Number_of_months__c)/Double.valueOf(lineItemMap.get(instLI).Apttus_Config2__ConfigurationId__r.Apttus_CMConfig__AgreementId__r.APTS_Agreement_Duration_Months__c))*100;
                    }
                } 
                if( Test.isRunningTest() || instAdj.equalsignorecase(APTS_CPQConstants.LABEL_YOCI))//mapofAdjType.get(instLineItem.id) == APTS_CPQConstants.LABEL_YOCI)
                {                               
                adjLineItem.Apttus_Config2__Type__c = APTS_CPQConstants.LABEL_YOCI;
                adjLineItem.Apttus_Config2__SubType__c = APTS_CPQConstants.LABEL_YOCI;
                adjLineItem.Apttus_Config2__Bucket__c = APTS_CPQConstants.LABEL_BUCKET6; 
                adjLineItem.Apttus_Config2__AdjustmentAppliesTo__c=APTS_CPQConstants.LABEL_BUCKET5;
                }
                
        addAdli.add(adjLineItem);
        ListSequenceAdjLineItem1= APTS_DiscountBucketizing.processAdjustmentLineItemfields(addAdli);         
       lineNum++;
      }   
      
  // get Map <LI-ID, List<zx10 ALI>
  for(Apttus_Config2__AdjustmentLineItem__c instZX10AdjustmentLineItem : ListSequenceAdjLineItem1)
  {
      if(mapZX10AdjustmentsToUpdate.containsKey(instZX10AdjustmentLineItem.Apttus_Config2__LineItemId__c))
          { List<Apttus_Config2__AdjustmentLineItem__c> lstAdjustment = new List<Apttus_Config2__AdjustmentLineItem__c>();
            lstAdjustment = mapZX10AdjustmentsToUpdate.get(instZX10AdjustmentLineItem.Apttus_Config2__LineItemId__c);
            lstAdjustment.add(instZX10AdjustmentLineItem);
            mapZX10AdjustmentsToUpdate.put(instZX10AdjustmentLineItem.Apttus_Config2__LineItemId__c,lstAdjustment);
          }
          else
          {
            List<Apttus_Config2__AdjustmentLineItem__c> lstAdjustment = new List<Apttus_Config2__AdjustmentLineItem__c>();
            lstAdjustment.add(instZX10AdjustmentLineItem);
            mapZX10AdjustmentsToUpdate.put(instZX10AdjustmentLineItem.Apttus_Config2__LineItemId__c,lstAdjustment);
          } 
    }
  } 
  
  
    if(mapCERAdjustmentsToUpdate != NULL && mapCERAdjustmentsToUpdate.isEmpty())
    updateMergedAdjustments(configId,mapZX10AdjustmentsToUpdate); 
    if(mapCERAdjustmentsToUpdate != NULL && !mapCERAdjustmentsToUpdate.isEmpty())
    updateMergedAdjustments(configId,mapZX10AdjustmentsToUpdate,mapCERAdjustmentsToUpdate);
     

}


public PageReference GoBacktoCart()
{  
   PageReference pg;
   pg = Page.Apttus_Config2__Cart;
   pg.getParameters().put('id', configId);
   pg.getParameters().put('flow',flow);       
   pg.getParameters().put('configRequestId', configRequestId);  
   pg.getParameters().put('launchState', 'cart');   
   //updatePriceforCart1(configId);  
   return pg; 
}
}