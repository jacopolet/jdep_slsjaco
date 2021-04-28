/*************************************************************
@Name: APTS_PenaltyUtils
@Author: Abhishek Kolipey
@CreateDate: 21-08-2018
@Description: Utils Methods for Penalty Calculation
@UsedBy:
******************************************************************/
public class APTS_PenaltyUtils
{

 //Cancel assets - call cancelAssets API
    public static Map<Id, Apttus_Config2__LineItem__c> cancelAssets(Id cartId, List<Id> assetIdList,Date canDate) {

        Apttus_Config2.CPQStruct.CancelAssetsRequestDO cancelRequest = new Apttus_Config2.CPQStruct.CancelAssetsRequestDO();
        cancelRequest.CancelDate = canDate;
        cancelRequest.AssetIds = assetIdList;
        cancelRequest.CartId = cartId;

        Apttus_Config2.CPQStruct.CancelAssetsResponseDO cancelResponse;
        if(!test.isRunningTest()) cancelResponse = Apttus_Config2.AssetService.cancelAssets(cancelRequest);
        System.debug('** Abhishek Response'+cancelResponse);
        if(cancelResponse!=null) System.debug('** Abhishek Errors'+cancelResponse.Errors);
        if (Test.isRunningTest() || (cancelResponse.Errors != null && !cancelResponse.Errors.isEmpty())) {

            for (String sErr : cancelResponse.Errors) {

                throw new applicationException(sErr);
            }
        }

        return cancelResponse.LineItemMap;
    }
    
     public class applicationException extends Exception {}

}