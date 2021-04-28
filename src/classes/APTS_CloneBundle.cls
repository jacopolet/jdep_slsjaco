/**********************************************************************************
* @Author: Lavanya Ravindran
* @Company: Accenture
* @Description: Error Page for Asset contract Change
* @Created Date: Jan-9-2020
* @History:
*      <Name>              <Date>          <Description>
*      Lavanya              09.01.2020       Created
**********************************************************************************/
public with sharing class APTS_CloneBundle{
public Id orderId{get;set;}
public static String BACKSLSH='/';

public PageReference Goback() {
PageReference  pageRef = new PageReference(BACKSLSH+orderId);
pageRef.setRedirect(true);
return pageRef; 

}



public APTS_CloneBundle(ApexPages.StandardController controller)
{
orderId = ApexPages.currentPage().getParameters().get('id');   
}

/** Method Name : Constructor 
* Description : url variable asign and query formation 
**/
public APTS_CloneBundle()
{
orderId = ApexPages.currentPage().getParameters().get('id');   


}

}