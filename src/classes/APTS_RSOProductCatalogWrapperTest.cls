@isTest
public class APTS_RSOProductCatalogWrapperTest {
@isTest static void APTS_RSOProductCatalogTest(){
        Account testAccount = APTS_TestDataFactory.createAccount('Test Account');
      Database.insert(testAccount, false);
    Contact oContact = APTS_TestDataFactory.createContact(testAccount, '567889999');
    Database.Insert(oContact, false);
    
      Product2 testProduct = APTS_TestDataFactory.createProduct('TestCoffee', 'pc123', 'Coffee', 'Standalone', true, false);
      Database.Insert(testProduct, false);
    
           APTS_RSOProductCatalogWrapper pcw = new APTS_RSOProductCatalogWrapper();
    pcw.ProductID = testProduct.Id;
	pcw.ProductCode = 'Test Product Code';
	pcw.ProductName = 'Test Product';
	pcw.ProductImage = 'Test Image';
	pcw.Category = 'Tea';
	pcw.SubCategory =  'Green Tea';
	pcw.SubSubCategory = 'Green Tea';
	pcw.UOM = 'Piece';
	pcw.RouteSales = true;
    pcw.isActive = true;
    
    APTS_RSOProductCatalogWrapper.ContractedProducts cp = new APTS_RSOProductCatalogWrapper.ContractedProducts();
    cp.AccountID = testAccount.Id;
    	//cp.PONumber = 'Test PO Number';
    	cp.ProductID = testProduct.Id;
   		cp.ProductCode = 'Test Product Code';
   		cp.ProductName = ' Test Product Name';
   		cp.ProductImage = 'test Product Image';
   		cp.UOM = 'Piece';
   		cp.SubSubCategory = null;
   		cp.SubCategory = null;
   		cp.Consignment = true;
   		cp.Category = null;   
   		   	
     APTS_RSOProductCatalogWrapper.Products oprod = new APTS_RSOProductCatalogWrapper.Products();
   oprod.ProductID = testProduct.Id;
   		oprod.ProductCode = 'Test Product Code';
   		oprod.ProductName = ' Test Product Name';
   		oprod.ProductImage = 'test Product Image';
   		oprod.UOM = 'Piece';
   		oprod.isActive = true;
    oprod.Category = 'Tea';
	oprod.SubCategory =  'Green Tea';
	oprod.SubSubCategory = 'Green Tea';
    
    APTS_RSOProductCatalogWrapper.UserInfo oUser  = new APTS_RSOProductCatalogWrapper.UserInfo();
      oUser.ExecutingEngineer = 'Test@123.com';
      oUser.WorkOrderType = 's25';
    oUser.AvailableUOM = 'SAP_PCE';
    
    APTS_RSOProductCatalogWrapper.RoutesInfo oRoute = new APTS_RSOProductCatalogWrapper.RoutesInfo();
     oRoute.AccountID = testAccount.Id;
    oRoute.AccountName = testAccount.Name;
    oRoute.SalesforceAccountLocationID = null;
    oRoute.LocationName = 'Test Location';
    oRoute.HouseNumber = 'ty7';
      oRoute.Street = 'Test Street';
      oRoute.City ='Utrecht';
      oRoute.State = 'Test';
      oRoute.Country = 'Netherlands';
      oRoute.PostalCode = 'Test Postal Code';
      oRoute.ContactFirstName = 'Test First Name';
      oRoute.ContactLastName = 'Test last Name';
      oRoute.ContactPhone = 'Test88999';
          
      oRoute.ContactEmail = 'test@abc.com';
      oRoute.ContactID = null;
      oRoute.CaseID = null;
      oRoute.ActualStartDate = DateTime.now();
      oRoute.PONumber = 'Test PO Number';
      oRoute.PONumberRequired = 'true';
      oRoute.OrderNonContractedProducts = true;
    oRoute.SAPCustomerID = '';
      
      System.assertEquals('Netherlands',oRoute.Country);
      System.assertEquals('true',oRoute.PONumberRequired);
     APTS_RSOProductCatalogWrapper.RSOProducts oRouteProd = new APTS_RSOProductCatalogWrapper.RSOProducts();
    oRouteProd.ProductID = testProduct.Id;
   		oRouteProd.ProductCode = 'Test Product Code';
   		oRouteProd.ProductName = ' Test Product Name';
   		oRouteProd.ProductImage = 'test Product Image';
   		oRouteProd.UOM = 'Piece';
   		oRouteProd.SubSubCategory = null;
   		oRouteProd.SubCategory = null;
   		oRouteProd.Routesales = true;
    oRouteProd.isActive = true;
   		oRouteProd.Category = null;   
     APTS_RSOProductCatalogWrapper.CERData oCER = new APTS_RSOProductCatalogWrapper.CERData();
    APTS_RSOProductCatalogWrapper.BlockedProducts oBlockedProducts = new APTS_RSOProductCatalogWrapper.BlockedProducts();
    oBlockedProducts.ProductID = testProduct.Id;
    oBlockedProducts.ProductCode = 'Test Prod Code';
    oBlockedProducts.ProductName = 'Test Prod';
    oBlockedProducts.IsActive = true;
    oBlockedProducts.BlockedForSelling = true; 
        
        
    }
}