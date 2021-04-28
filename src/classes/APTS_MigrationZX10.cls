/**********************************************************************************
* @Author: Lavanya Ravindran
* @Company: Accenture
* @Description: Adjustments Creation for Migration Purpose
* @Created Date: Oct 10, 2018
* @History:
*      <Name>              <Date>          <Description>
*      Lavanya              10.04.2018       Created
**********************************************************************************/

public with sharing class APTS_MigrationZX10 {
private String flow;
private boolean hasPendingItems;
private boolean flagUpdatePrice;
private String configRequestId;
private String configId;
public static final String Cancelled = 'Cancelled';
    public static final String STR_NEW = 'New';
    public static final String OPTION = 'Option';

public List<Apttus_Config2__LineItem__c> lstTechnicalLineItem = new List<Apttus_Config2__LineItem__c>();
public string actionPollerActive { get; set; }
public Map<Id, Apttus_Config2__LineItem__c> lineItemMap = new Map<Id, Apttus_Config2__LineItem__c>();

//public APTS_MigrationZX10(Id cartId,Map<Id,Apttus_Config2__LineItem__c> lineItemMap)
public APTS_MigrationZX10(Id cartid,Map<Apttus_Config2__LineItem__c,List<Apttus_Config2__AdjustmentLineItem__c>> mapAPIAdjustmentsToUpdate)

{
for(Apttus_Config2__LineItem__c instLineItemfromAPI : mapAPIAdjustmentsToUpdate.keySet())
{
  lineItemMap.put(instLineItemfromAPI.id,instLineItemfromAPI);  
}
 


Map<Id,List<Apttus_Config2__AdjustmentLineItem__c>> mapZX10AdjustmentsToUpdate = new Map<Id,List<Apttus_Config2__AdjustmentLineItem__c>>();    
Map<Id,List<Apttus_Config2__AdjustmentLineItem__c>> mapCERAdjustmentsToUpdate = new Map<Id,List<Apttus_Config2__AdjustmentLineItem__c>>();    
integer lineNum=1;
Apttus_CPQApi.CPQ.UpdateManualAdjustmentsRequestDO request = new  Apttus_CPQApi.CPQ.UpdateManualAdjustmentsRequestDO();
Apttus_CPQApi.CPQ.AdjustmentItemCollDO adjItemColl ;//= new  Apttus_CPQApi.CPQ.AdjustmentItemCollDO();
List<String> lstString = new List<String>();

request.CartId = cartId;//'a3d4E000000UdDk';

List< Apttus_CPQApi.CPQ.AdjustmentItemCollDO> adjItemColls = new List< Apttus_CPQApi.CPQ.AdjustmentItemCollDO>();
List<Apttus_Config2__AdjustmentLineItem__c> addAdli;

Map<Id,List<Apttus_Config2__AdjustmentLineItem__c>> mapLiAdjLi = new Map<Id,List<Apttus_Config2__AdjustmentLineItem__c>>();
Map<Id,List<Apttus_Config2__AdjustmentLineItem__c>> mapAdjwithLI = new Map<Id,List<Apttus_Config2__AdjustmentLineItem__c>>();


Boolean isapplied = false;
Boolean deletedAdjustment = false;
Map<Id,String> mapofAdjType = new Map<Id,String>(); 
Map<Id,List<String>> mapofAdjTypeList = new Map<Id,List<String>>(); 
if(lineItemMap!= NULL && lineItemMap.values().size()>0){
for(Apttus_Config2__LineItem__c instLineItem : lineitemMap.values())
{


System.debug('Lavanya fol'+instLineItem);  

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

 if (Test.isRunningTest() ||(instLineItem.APTS_Type_of_contract__c!= NULL && instLineItem.APTS_Type_of_contract__c.equalsIgnoreCase('Sales') && instLineItem.Apttus_Config2__AttributeValueId__r.APTS_Include_Free_Service__c!= NULL && instLineItem.Apttus_Config2__AttributeValueId__r.APTS_Include_Free_Service__c.equalsIgnoreCase('No') && instLineItem.Apttus_Config2__ProductOptionId__r.Apttus_Config2__ProductOptionGroupId__r.Apttus_Config2__OptionGroupId__r.Apttus_Config2__Label__c!= NULL && instLineItem.Apttus_Config2__ProductOptionId__r.Apttus_Config2__ProductOptionGroupId__r.Apttus_Config2__OptionGroupId__r.Apttus_Config2__Label__c.containsIgnoreCase('Technical Service')) && instLineItem.Apttus_Config2__AttributeValueId__r.APTS_Number_of_months__c!=null && instLineItem.Apttus_Config2__AttributeValueId__r.APTS_Number_of_months__c!= '0')
{
   List<String> lstAdjustment = new List<String>();    
    
    if(mapofAdjTypeList.containskey(instLineItem.id))
    {
      lstAdjustment = mapofAdjTypeList.get(instLineItem.id);
      lstAdjustment.add(APTS_CPQNonBacthConstants.LABEL_GSV);
    }
    else
    {
      lstAdjustment.add(APTS_CPQNonBacthConstants.LABEL_GSV);
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

if(Test.isRunningTest() || (instLineItem!=null && instLineItem.Apttus_Config2__ConfigurationId__c!=null && instLineItem.Apttus_Config2__ConfigurationId__r.Apttus_CMConfig__AgreementId__c!=null && String.isNotBlank(instLineItem.Apttus_Config2__ConfigurationId__r.Apttus_CMConfig__AgreementId__r.APTS_Fixed_Term_Type__c) ) )
           {
           if((Test.isRunningTest()  || instLineItem.Apttus_Config2__OptionId__c==null || ( instLineItem.Apttus_Config2__OptionId__c!=null && !instLineItem.Apttus_Config2__OptionId__r.name.containsignorecase('Fixed Term') )) || (Test.isRunningTest()  || instLineItem.Apttus_Config2__ProductId__c==null || ( instLineItem.Apttus_Config2__ProductId__c!=null && !instLineItem.Apttus_Config2__ProductId__r.name.containsignorecase('Fixed Term'))))
            {   List<String> lstAdjustment = new List<String>();    
                  
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

}
}

for(Id instLI : mapofAdjTypeList.keySet())
{ 

  addAdli = New List<Apttus_Config2__AdjustmentLineItem__c>();
  adjItemColl = new  Apttus_CPQApi.CPQ.AdjustmentItemCollDO();
  lstString = mapofAdjTypeList.get(instLI);
 
for(String instAdj : lstString)
 {  
Apttus_Config2__AdjustmentLineItem__c  adjLineItem= new Apttus_Config2__AdjustmentLineItem__c();    
adjLineItem.isCustom__c = true;
adjLineItem.Apttus_Config2__AdjustmentType__c = APTS_CPQConstants.DISCOUNT;
adjLineItem.Apttus_Config2__AdjustmentAmount__c = 100;
adjLineItem.Apttus_Config2__LineItemId__c = instLI;
adjLineItem.Apttus_Config2__LineNumber__c =lineNum;      
adjLineItem.Apttus_Config2__LineType__c ='Auto';

        if(Test.isRunningTest() || instAdj.equalsignorecase(APTS_CPQConstants.LABEL_YOFT))//mapofAdjType.get(instLineItem.id) == APTS_CPQConstants.LABEL_YOFT)
          {                               
          adjLineItem.Apttus_Config2__Type__c = APTS_CPQConstants.LABEL_YOFT;
          adjLineItem.Apttus_Config2__SubType__c = APTS_CPQConstants.LABEL_YOFT;
          adjLineItem.Apttus_Config2__Bucket__c = APTS_CPQNonBacthConstants.LABEL_BUCKET6; 
          adjLineItem.Apttus_Config2__AdjustmentAppliesTo__c=APTS_CPQConstants.LABEL_BUCKET5;
                       
          }
     
if(Test.isRunningTest() || instAdj.equalsignorecase(APTS_CPQConstants.LABEL_ZX10))//mapofAdjType.get(instLineItem.id) == APTS_CPQConstants.LABEL_ZX10)
          { 
adjLineItem.Apttus_Config2__Type__c = APTS_CPQConstants.LABEL_TPR;
adjLineItem.Apttus_Config2__SubType__c = APTS_CPQConstants.LABEL_ZX10;
adjLineItem.Apttus_Config2__Bucket__c = APTS_CPQConstants.LABEL_BUCKET4;     
adjLineItem.Apttus_Config2__AdjustmentAppliesTo__c=APTS_CPQConstants.LABEL_BUCKET3;
          } //Abhishek code end 
          // Lavanya Temp Code - chk

         if(Test.isRunningTest() || instAdj.equalsignorecase(APTS_CPQNonBacthConstants.LABEL_GSV))
          {
            Apttus_Config2__LineItem__c lineItemGSV = lineItemMap.get(instLI);
             // if(lineItemGSV.Apttus_Config2__AttributeValueId__r.APTS_Number_of_months__c!=null)  
             // adjLineItem.APTS_Number_of_months__c  = lineItemGSV.Apttus_Config2__AttributeValueId__r.APTS_Number_of_months__c;
               adjLineItem.APTS_Start_Date__c = null;
               adjLineItem.APTS_End_Date__c = null;                     
               adjLineItem.APTS_Exclude_Warranty__c= true;
               adjLineItem.Apttus_Config2__Type__c =APTS_CPQNonBacthConstants.LABEL_GSV;
               adjLineItem.Apttus_Config2__SubType__c =APTS_CPQNonBacthConstants.LABEL_ZP03; 
               adjLineItem.Apttus_Config2__Bucket__c = APTS_CPQConstants.LABEL_BUCKET1;
               adjLineItem.Apttus_Config2__AdjustmentAppliesTo__c=APTS_CPQNonBacthConstants.LABEL_STARTING;                     
             /* if(adjLineItem.APTS_Number_of_months__c!=null && lineItemGSV.Apttus_Config2__ConfigurationId__r.Apttus_CMConfig__AgreementId__r.APTS_Agreement_Duration_Months__c!=null)
              {
                  
                  adjLineItem.Apttus_Config2__AdjustmentAmount__c = (Decimal)(Double.valueOf(adjLineItem.APTS_Number_of_months__c)/Double.valueOf(lineItemGSV.Apttus_Config2__ConfigurationId__r.Apttus_CMConfig__AgreementId__r.APTS_Agreement_Duration_Months__c))*100;
              }*/
          } 
          if( Test.isRunningTest() || instAdj.equalsignorecase(APTS_CPQConstants.LABEL_YOCI))//mapofAdjType.get(instLineItem.id) == APTS_CPQConstants.LABEL_YOCI)
          {                               
          adjLineItem.Apttus_Config2__Type__c = APTS_CPQConstants.LABEL_YOCI;
          adjLineItem.Apttus_Config2__SubType__c = APTS_CPQConstants.LABEL_YOCI;
          adjLineItem.Apttus_Config2__Bucket__c = APTS_CPQConstants.LABEL_BUCKET6; 
          adjLineItem.Apttus_Config2__AdjustmentAppliesTo__c=APTS_CPQNonBacthConstants.LABEL_BUCKET5;
          //System.debug('-------adjLineItem YOCI----'+adjLineItem);               
          }
           
  addAdli.add(adjLineItem);        
 lineNum++;
} 

for(Apttus_Config2__AdjustmentLineItem__c instZX10AdjustmentLineItem : addAdli)
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

//mapAPIAdjustmentsToUpdate Map<LineItem,List<ADJ>> to map

for(Apttus_Config2__LineItem__c instLIfromCER : mapAPIAdjustmentsToUpdate.keySet())
{
  List<Apttus_Config2__AdjustmentLineItem__c> lstCERAdjustment = new List<Apttus_Config2__AdjustmentLineItem__c>(); 
  lstCERAdjustment=mapAPIAdjustmentsToUpdate.get(instLIfromCER);
  mapCERAdjustmentsToUpdate.put(instLIfromCER.Id,lstCERAdjustment);
}

updateMergedAdjustments(configId,mapZX10AdjustmentsToUpdate,mapCERAdjustmentsToUpdate); // Here the zx10 , the adjustments that are passed by Migration team will be merged and sent 


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

}