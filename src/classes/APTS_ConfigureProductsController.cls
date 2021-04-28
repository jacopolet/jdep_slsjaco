/*************************************************************
@Name: APTS_ConfigureProductsController
@Author: Galin Georgiev
@CreateDate: 16-10-2018
@Description: Redirect to contracted products when user click on Configure Products
@UsedBy: APTS_ConfigureProducts page
******************************************************************/
//v100 16-10-20188 Galin Georgiev: Initial version.
//Comments in this format are mandatory for each change of code.
//Adding code comment example: v100++<< means start of changes and v100++>> means end of changes
//Removing code comment example: v100--<< means start of changes and v100-->> means end of changes

public class APTS_ConfigureProductsController {

	private static final String ID = System.Label.APTS_Id;
	private static final String FLOW = System.Label.APTS_Flow;

	private static final String USEADVANCEDAPPROVAL = System.Label.APTS_useAdvancedApproval;
	private static final String USEDEALOPTIMIZER = System.Label.APTS_useDealOptimizer;

	private Id orderId;
	private String sFlow;

	public APTS_ConfigureProductsController() {

		orderId = ApexPages.currentPage().getParameters().get(ID);
		sFlow = ApexPages.currentPage().getParameters().get(FLOW);
	}

	public PageReference goToContractedProducts() {

		PageReference pageRef;

		Id cartId;

		List<Apttus_Config2__ProductConfiguration__c> configurationList = [
		            SELECT Id, Apttus_Config2__Status__c
		            FROM Apttus_Config2__ProductConfiguration__c
		            WHERE Apttus_Config2__OrderId__c = :orderId ORDER BY Apttus_Config2__VersionNumber__c DESC];

		if (!configurationList.isEmpty()) {
			Apttus_Config2__ProductConfiguration__c oConfiguration = configurationList.get(0);
			cartId = configurationList.get(0).Id;

			if (oConfiguration.Apttus_Config2__Status__c == 'New') {

				Id tempObjectId = getTempObject(cartId);

				pageRef = new PageReference('/apex/APTS_ContractedProducts');

				pageRef.getParameters().put('configRequestId', tempObjectId);
				pageRef.getParameters().put('Id', cartId);
				pageRef.getParameters().put('flow', sFlow);
				pageRef.getParameters().put('businessObjectId', orderId);
				pageRef.getParameters().put('retId', orderId);
			} else {
				pageRef = new PageReference('/apex/Apttus_Config2__OrderConfiguration');

				pageRef.getParameters().put('Id', orderId);
				pageRef.getParameters().put('flow', sFlow);
			}
		} else {
			cartId = createCart(orderId, sFlow);

			Id tempObjectId = getTempObject(cartId);

			pageRef = new PageReference('/apex/APTS_ContractedProducts');

			pageRef.getParameters().put('configRequestId', tempObjectId);
			pageRef.getParameters().put('Id', cartId);
			pageRef.getParameters().put('flow', sFlow);
			pageRef.getParameters().put('businessObjectId', orderId);
			pageRef.getParameters().put('retId', orderId);
		}

		return pageRef;
	}

	//@Description: method would return cart ID
	public static Id createCart(Id orderId, String sFlow) {

		Id cartId;
		//try{
		if (String.isNotBlank(orderId)) {
			// Create config properties
			List<Apttus_Config2.Property> configProps = new List<Apttus_Config2.Property>();
			Apttus_Config2.Property prop = new Apttus_Config2.Property();
			prop = new Apttus_Config2.Property();
			prop.Name = 'flow';
			prop.Value = sFlow;
			configProps.add(prop);

			// Create the request
			Apttus_Config2.CPQStruct.CreateCartRequestDO request = new Apttus_Config2.CPQStruct.CreateCartRequestDO();
			request.OrderId = orderId;
			request.Properties.addAll(configProps);
			//Response
			Apttus_Config2.CPQStruct.CreateCartResponseDO result = Apttus_Config2.OrderWebService.createCart(request);
			cartId = result.CartId;
		}
		//} catch (Exception e) {
		//    APTS_CustomLogging.createErrorLog(e.getTypeName(), 'Apex', e.getStackTraceString() , 'Order', ApexPages.currentPage().getParameters().get(Label.APTS_Id), 'OM', false, true, EMAIL, true);
		//}
		return cartId;
	}

	private Id getTempObject(Id cartId) {

		Id tempObjectId = null;
		List<Apttus_Config2__TempObject__c> tempObjectList = [SELECT Id FROM Apttus_Config2__TempObject__c WHERE Apttus_Config2__ConfigurationId__c = :cartId];

		if (tempObjectList != null && !tempObjectList.isEmpty()) {
			tempObjectId = tempObjectList.get(0).Id;
		}

		return tempObjectId;
	}
}