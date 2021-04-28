/*
 * This class(Handler) is used to create Permutation of UOM records based on existing UOM records.
 * Source class : APTS_CreateUOMsBatch
 * Created By - Karan Khatri
 * Created Date - 14th Feb, 2019
 * 
 * v100 - Karan - initial class logic
*/
public without sharing class APTS_CreateUOMsBatchHandler {

	public static final String EMPTY_STRING = ' ';
	//Dynamic query creation for frequency UOM records
	public static String getObjectQuery(String objectName){
        Map<String, Schema.SObjectField> fieldMap = Schema.getGlobalDescribe().get(objectName).getDescribe().fields.getMap();
        String thisQuery = Label.APTS_SelectLabel + EMPTY_STRING;
        for(Schema.SObjectField field : fieldMap.values()){
            thisQuery += field.getDescribe().getName() + Label.APTS_CommaSeparator;
        }
        thisQuery = thisQuery.subString(0, thisQuery.length()-1);
        thisQuery += EMPTY_STRING + Label.APTS_FromLabel + EMPTY_STRING + objectName + EMPTY_STRING;
        return thisQuery;
    }

    //populate prerquisite maps required to process permutational UOMs
	public static void populateUOMBatchMaps(Map<String,Apttus_Config2__FrequencyConversionRate__c> productUOMFactorMap,Map<Id,Set<String>> productIdToUomMap,Map<String,Apttus_Config2__FrequencyConversionRate__c> existingUOMsMap,Set<ID> productIDs)  {
    	for(Apttus_Config2__FrequencyConversionRate__c freqUOM : [select id,Apttus_Config2__ProductId__c,Apttus_Config2__ToUom__c,Apttus_Config2__FromUom__c,
																Apttus_Config2__ConversionFactor__c,APTS_Added_by_UOM_batch__c,APTS_ProductCode__c,APTS_UOM_External_ID__c
																from Apttus_Config2__FrequencyConversionRate__c where Apttus_Config2__ProductId__c IN: productIDs limit 50000]){
			
			//Only populatiing maps for TO UOMS as they are unique and expectation is FROM UOM will always be Piece 
			if(freqUOM.Apttus_Config2__ToUom__c!=null && freqUOM.Apttus_Config2__ProductId__c!=null && freqUOM.Apttus_Config2__ToUom__c!=null &&
			 freqUOM.Apttus_Config2__ToUom__c != 'SAP_PCE' && freqUOM.Apttus_Config2__FromUom__c!=null && freqUOM.Apttus_Config2__FromUom__c == 'SAP_PCE' && !freqUOM.APTS_Added_by_UOM_batch__c){
				//Populate map for capturing product ID and its associated TO UOMS
				if(productIdToUomMap.get(freqUOM.Apttus_Config2__ProductId__c)==null){
					productIdToUomMap.put(freqUOM.Apttus_Config2__ProductId__c,new Set<String>{freqUOM.Apttus_Config2__ToUom__c});
				}else{
					productIdToUomMap.get(freqUOM.Apttus_Config2__ProductId__c).add(freqUOM.Apttus_Config2__ToUom__c);
				}
				//Populate map for storing frequency UOMs based on unique key 
				if(productUOMFactorMap.get(freqUOM.Apttus_Config2__ProductId__c+freqUOM.Apttus_Config2__ToUom__c)==null){
					productUOMFactorMap.put(freqUOM.Apttus_Config2__ProductId__c+freqUOM.Apttus_Config2__ToUom__c,freqUOM);
				}
			}
			if(freqUOM.APTS_Added_by_UOM_batch__c){
				if(existingUOMsMap.get(freqUOM.Apttus_Config2__ProductId__c+freqUOM.Apttus_Config2__FromUom__c+freqUOM.Apttus_Config2__toUom__c)==null){
					existingUOMsMap.put(freqUOM.Apttus_Config2__ProductId__c+freqUOM.Apttus_Config2__FromUom__c+freqUOM.Apttus_Config2__toUom__c,freqUOM);
				}
			}
		}
	}

	//Brain logic to create permutational UOMs
    public static void createPermutationalUOMs(Map<String,Apttus_Config2__FrequencyConversionRate__c> productUOMFactorMap,Map<Id,Set<String>> productIdToUomMap,Map<String,Apttus_Config2__FrequencyConversionRate__c> existingUOMsMap,Map<String,Apttus_Config2__FrequencyConversionRate__c> freqUOMsInsertMap)  {
    	if(!productIdToUomMap.isEmpty() && !productUOMFactorMap.isEmpty()){
			
			//Iterating over all the product IDs
			for(ID id : productIdToUomMap.keySet()){
				//get all its associated TO UOMs
				Set<String> uomValues = productIdToUomMap.get(id);
				//used two for loops for creating one to one unique permutation and not repetative records in versa versa case
				for(String fromUom : uomValues){
					for(String toUOM : uomValues){
						if(fromUom!=toUOM){
							//creating frequency UOMs based on permutations
							Apttus_Config2__FrequencyConversionRate__c freqUOM = new Apttus_Config2__FrequencyConversionRate__c();
							freqUOM.Apttus_Config2__ConversionFactor__c=0;
							freqUOM.Apttus_Config2__FromUom__c = fromUom;
							freqUOM.Apttus_Config2__toUom__c = toUOM;
							freqUOM.Apttus_Config2__ProductId__c = id;
							//setting this flag as true as this helps us to identify which records were created by UOM Batch
							freqUOM.APTS_Added_by_UOM_batch__c=true;
							//get product code based on previously populated Maps and also get its conversion factor
							if(productUOMFactorMap.get(id+freqUOM.Apttus_Config2__toUom__c)!=null && productUOMFactorMap.get(id+freqUOM.Apttus_Config2__FromUom__c)!=null && productUOMFactorMap.get(id+freqUOM.Apttus_Config2__FromUom__c).Apttus_Config2__ConversionFactor__c!=0 && productUOMFactorMap.get(id+freqUOM.Apttus_Config2__toUom__c).Apttus_Config2__ConversionFactor__c!=0){
								freqUOM.APTS_ProductCode__c = productUOMFactorMap.get(id+freqUOM.Apttus_Config2__toUom__c).APTS_ProductCode__c;
								freqUOM.Apttus_Config2__ConversionFactor__c = productUOMFactorMap.get(id+freqUOM.Apttus_Config2__toUom__c).Apttus_Config2__ConversionFactor__c / productUOMFactorMap.get(id+freqUOM.Apttus_Config2__FromUom__c).Apttus_Config2__ConversionFactor__c;
								freqUOM.APTS_UOM_External_ID__c = freqUOM.APTS_ProductCode__c + '|' + freqUOM.Apttus_Config2__FromUom__c.substringAfter('SAP_') + '|' + freqUOM.Apttus_Config2__toUom__c.substringAfter('SAP_');	
							}

							//checking for fromuom + touom should be unique at all times inclusive vice versa case - if such records not previously created then only insert
							if(existingUOMsMap.get(freqUOM.Apttus_Config2__ProductId__c+freqUOM.Apttus_Config2__FromUom__c+freqUOM.Apttus_Config2__toUom__c)==null && existingUOMsMap.get(freqUOM.Apttus_Config2__ProductId__c+freqUOM.Apttus_Config2__toUom__c+freqUOM.Apttus_Config2__FromUom__c)==null && 
								freqUOMsInsertMap.get(freqUOM.Apttus_Config2__ProductId__c+freqUOM.Apttus_Config2__FromUom__c+freqUOM.Apttus_Config2__toUom__c)==null && freqUOMsInsertMap.get(freqUOM.Apttus_Config2__ProductId__c+freqUOM.Apttus_Config2__toUom__c+freqUOM.Apttus_Config2__FromUom__c)==null){
								
								freqUOMsInsertMap.put(freqUOM.Apttus_Config2__ProductId__c+freqUOM.Apttus_Config2__FromUom__c+freqUOM.Apttus_Config2__toUom__c,freqUOM);
							}
						}
					}
				}
			}
		}
    }
}