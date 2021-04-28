/*************************************************************
@Name: APTS_UOMConversionUtils
@Author: Karan Khatri
@CreateDate: 17-09-2018
@Description: Reusable method for frequency conversions(OOB)
******************************************************************/
//v2 30-Oct-2018 Raul Mora(RM) : Declare the class with sharing to be able to deploy the class.
global with sharing class APTS_UOMConversionUtils {

	/* Description : get product based UOM conversion in Bulk*/
	global static Map<String,Decimal> getUOMConversions(Set<String> conversionStringSet){
		//Set<String> toUOMSet = new Set<String>();
		Set<String> allUOMSet = new Set<String>();
		Set<String> productCodeSet = new Set<String>();
		Map<String,Decimal> conversionFactorResultMap = new Map<String,Decimal>();
		Map<String,Set<String>> mappingsOfUOMs = new Map<String,Set<String>>();
		if(!conversionStringSet.isEmpty()){
			for(String uomValue : conversionStringSet){
				List<String> uomValueList = uomValue.split(';');
				if(!uomValueList.isEmpty() && uomValueList.size()==3){
					productCodeSet.add(uomValueList[0]);
					allUOMSet.add(uomValueList[1]);
					allUOMSet.add(uomValueList[2]);
					if(mappingsOfUOMs.get(uomValueList[0])==null){
						mappingsOfUOMs.put(uomValueList[0],new Set<String>{uomValueList[1]+';'+uomValueList[2]});
					}else{
						mappingsOfUOMs.get(uomValueList[0]).add(uomValueList[1]+';'+uomValueList[2]);
					}
				}
			}
		}
		if(!allUOMSet.isEmpty() && !productCodeSet.isEmpty()){
			for( Apttus_Config2__FrequencyConversionRate__c freqConversion : [select id,Apttus_Config2__FromUom__c,Apttus_Config2__ToUom__c,Apttus_Config2__ProductFamily__c,Apttus_Config2__ConversionFactor__c,Apttus_Config2__ProductId__c,APTS_ProductCode__c from Apttus_Config2__FrequencyConversionRate__c where Apttus_Config2__ToUom__c IN : allUOMSet and Apttus_Config2__FromUom__c IN: allUOMSet and APTS_ProductCode__c IN: productCodeSet and APTS_Product_Family2__c = null and APTS_Product_Family3__c = null limit 50000]){
				Set<String> fromToUOM;
				if(!mappingsOfUOMs.isEmpty()){
					fromToUOM = mappingsOfUOMs.get(freqConversion.APTS_ProductCode__c);
				}
				if(!fromToUOM.isEmpty()){
					for(String uom : fromToUOM){
						List<String> UOMSet = uom.split(';');
						if(UOMSet.size()==2){
							String fromUOM = UOMSet[0]; 
							String toUOM = UOMSet[1];
							if(freqConversion.Apttus_Config2__FromUom__c!=null && freqConversion.Apttus_Config2__FromUom__c!=null && toUOM!=null && fromUOM!=null && freqConversion.Apttus_Config2__FromUom__c.equalsIgnoreCase(fromUOM) && freqConversion.Apttus_Config2__ToUom__c.equalsIgnoreCase(toUOM)){
								conversionFactorResultMap.put(freqConversion.APTS_ProductCode__c+';'+freqConversion.Apttus_Config2__FromUom__c+';'+freqConversion.Apttus_Config2__ToUom__c,freqConversion.Apttus_Config2__ConversionFactor__c);
							}
							if(freqConversion.Apttus_Config2__FromUom__c!=null && freqConversion.Apttus_Config2__FromUom__c!=null && toUOM!=null && fromUOM!=null && freqConversion.Apttus_Config2__FromUom__c.equalsIgnoreCase(toUOM) && freqConversion.Apttus_Config2__ToUom__c.equalsIgnoreCase(fromUOM) && freqConversion.Apttus_Config2__ConversionFactor__c!=null && freqConversion.Apttus_Config2__ConversionFactor__c!=0){
								conversionFactorResultMap.put(freqConversion.APTS_ProductCode__c+';'+freqConversion.Apttus_Config2__ToUom__c+';'+freqConversion.Apttus_Config2__FromUom__c,(1/freqConversion.Apttus_Config2__ConversionFactor__c));
							}
						}
					}
				}
			}
		}
		//System.debug('######conversionFactorResultMap======>'+conversionFactorResultMap);
		return conversionFactorResultMap;
	}
	/* Description : get sub category based UOM conversion in Bulk*/
	global static Map<String,Decimal> getSubcategoryConversions(Set<String> conversionStringSet){
		Set<String> toUOMSet = new Set<String>();
		Set<String> fromUOMSet = new Set<String>();
		Set<String> categorySubcategorySet = new Set<String>();
		Map<String,Decimal> conversionFactorResultMap = new Map<String,Decimal>();
		Map<String,Set<String>> mappingsOfUOMs = new Map<String,Set<String>>();
		if(!conversionStringSet.isEmpty()){
			for(String uomValue : conversionStringSet){
				List<String> uomValueList = uomValue.split(';');
				if(!uomValueList.isEmpty() && uomValueList.size()==3){
					categorySubcategorySet.add(uomValueList[0]);
					fromUOMSet.add(uomValueList[1]);
					toUOMSet.add(uomValueList[2]);
					if(mappingsOfUOMs.get(uomValueList[0])==null){
						mappingsOfUOMs.put(uomValueList[0],new Set<String>{uomValueList[1]+';'+uomValueList[2]});
					}else{
						mappingsOfUOMs.get(uomValueList[0]).add(uomValueList[1]+';'+uomValueList[2]);
					}
				}
			}
		}
		if(!toUOMSet.isEmpty() && !fromUOMSet.isEmpty() && !categorySubcategorySet.isEmpty()){
			for( Apttus_Config2__FrequencyConversionRate__c freqConversion : [select id,Apttus_Config2__FromUom__c,Apttus_Config2__ToUom__c,Apttus_Config2__ProductFamily__c,Apttus_Config2__ConversionFactor__c,Apttus_Config2__ProductId__c,APTS_Product_Family2__c from Apttus_Config2__FrequencyConversionRate__c where Apttus_Config2__ToUom__c IN : toUOMSet and Apttus_Config2__FromUom__c IN: fromUOMSet and APTS_Product_Family2__c IN: categorySubcategorySet and APTS_Product_Family3__c = null and Apttus_Config2__ProductId__c = null limit 50000]){
				Set<String> fromToUOM;
				if(!mappingsOfUOMs.isEmpty()){
					fromToUOM = mappingsOfUOMs.get(freqConversion.APTS_Product_Family2__c);
				}
				if(!fromToUOM.isEmpty()){
					for(String uom : fromToUOM){
						List<String> UOMSet = uom.split(';');
						if(UOMSet.size()==2){
							String fromUOM = UOMSet[0]; 
							String toUOM = UOMSet[1];
							if(freqConversion.Apttus_Config2__FromUom__c!=null && freqConversion.Apttus_Config2__FromUom__c!=null && toUOM!=null && fromUOM!=null && freqConversion.Apttus_Config2__FromUom__c.equalsIgnoreCase(fromUOM) && freqConversion.Apttus_Config2__ToUom__c.equalsIgnoreCase(toUOM)){
								conversionFactorResultMap.put(freqConversion.APTS_Product_Family2__c+';'+freqConversion.Apttus_Config2__FromUom__c+';'+freqConversion.Apttus_Config2__ToUom__c,freqConversion.Apttus_Config2__ConversionFactor__c);
							}
						}
					}
				}
			}
		}
		//System.debug('######conversionFactorResultMap===CAT===>'+conversionFactorResultMap);
		return conversionFactorResultMap;
	}
	/* Description : get sub sub based UOM conversion in Bulk*/
	global static Map<String,Decimal> getSubsubcategoryConversions(Set<String> conversionStringSet){
		Set<String> toUOMSet = new Set<String>();
		Set<String> fromUOMSet = new Set<String>();
		Set<String> subSubCategorySet = new Set<String>();
		Map<String,Decimal> conversionFactorResultMap = new Map<String,Decimal>();
		Map<String,Set<String>> mappingsOfUOMs = new Map<String,Set<String>>();
		if(!conversionStringSet.isEmpty()){
			for(String uomValue : conversionStringSet){
				List<String> uomValueList = uomValue.split(';');
				if(!uomValueList.isEmpty() && uomValueList.size()==3){
					subSubCategorySet.add(uomValueList[0]);
					fromUOMSet.add(uomValueList[1]);
					toUOMSet.add(uomValueList[2]);
					if(mappingsOfUOMs.get(uomValueList[0])==null){
						mappingsOfUOMs.put(uomValueList[0],new Set<String>{uomValueList[1]+';'+uomValueList[2]});
					}else{
						mappingsOfUOMs.get(uomValueList[0]).add(uomValueList[1]+';'+uomValueList[2]);
					}
				}
			}
		}
		if(!toUOMSet.isEmpty() && !fromUOMSet.isEmpty() && !subSubCategorySet.isEmpty()){
			for( Apttus_Config2__FrequencyConversionRate__c freqConversion : [select id,Apttus_Config2__FromUom__c,Apttus_Config2__ToUom__c,Apttus_Config2__ProductFamily__c,Apttus_Config2__ConversionFactor__c,Apttus_Config2__ProductId__c,APTS_Product_Family3__c from Apttus_Config2__FrequencyConversionRate__c where Apttus_Config2__ToUom__c IN : toUOMSet and Apttus_Config2__FromUom__c IN: fromUOMSet and APTS_Product_Family3__c IN: subSubCategorySet and APTS_Product_Family2__c = null and Apttus_Config2__ProductId__c = null limit 50000]){
				Set<String> fromToUOM;
				if(!mappingsOfUOMs.isEmpty()){
					fromToUOM = mappingsOfUOMs.get(freqConversion.APTS_Product_Family3__c);
				}
				if(!fromToUOM.isEmpty()){
					for(String uom : fromToUOM){
						List<String> UOMSet = uom.split(';');
						if(UOMSet.size()==2){
							String fromUOM = UOMSet[0]; 
							String toUOM = UOMSet[1];
							if(freqConversion.Apttus_Config2__FromUom__c!=null && freqConversion.Apttus_Config2__FromUom__c!=null && toUOM!=null && fromUOM!=null && freqConversion.Apttus_Config2__FromUom__c.equalsIgnoreCase(fromUOM) && freqConversion.Apttus_Config2__ToUom__c.equalsIgnoreCase(toUOM)){
								conversionFactorResultMap.put(freqConversion.APTS_Product_Family3__c+';'+freqConversion.Apttus_Config2__FromUom__c+';'+freqConversion.Apttus_Config2__ToUom__c,freqConversion.Apttus_Config2__ConversionFactor__c);
							}
						}
					}
				}
			}
		}
		//System.debug('######conversionFactorResultMap======>'+conversionFactorResultMap);
		return conversionFactorResultMap;
	}
}