/**********************************************************************************
 * @Author: Shahul
 * @Company: Accenture
 * @Description: Handles the Contents/file creation for Bizisland
 * @Created Date: Feb 22, 2018
 * @History:
 *      <Name>              <Date>          <Description>
 *      Shahul              10.04.2018       Created
 **********************************************************************************/

public without sharing class APTS_BizIslandContentGenerator{ /*** PI fix # 190210 ****/
    
    public ContentVersion createContentVersion(String name, Blob body)
    {
        ContentVersion contentVersion = new ContentVersion();
        contentVersion.ContentLocation = 'S'; 
        contentVersion.PathOnClient = name+'.csv';
        contentVersion.Title = name;
        String afterblob = EncodingUtil.base64Encode(body);
        contentVersion.VersionData = EncodingUtil.base64Decode(afterblob);
        return contentVersion;
    }
    public ContentDocumentLink createContentDocumentLink(Id contentDocumentId, Id parentId)
    {
        ContentDocumentLink contentDocumentLink = new ContentDocumentLink();
        contentDocumentLink.ContentDocumentId = contentDocumentId;
        contentDocumentLink.LinkedEntityId = parentId;
        contentDocumentLink.ShareType = 'I'; // Inferred permission
        contentDocumentLink.Visibility = 'InternalUsers';
        return contentDocumentLink;
    }
    
    public void addAttachmentsToBonsai(BizIsland_Request__c bizIsland,String Str,String FileName) 
    {
        ContentVersion[] contentVersions = new List<ContentVersion>();
        Blob myBlob = Blob.valueof(Str);
        String documentName = FileName+'-v'+bizIsland.Version__c;
        ContentVersion contentVersion = createContentVersion(documentName, myBlob);
        contentVersions.add(contentVersion);
        insert contentVersions;
        List<ContentDocumentLink> contentDocumentLinks = new List<ContentDocumentLink>();
        list<ContentVersion>contentVersions1 =new list<ContentVersion>();
        contentVersions1 = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id IN :contentVersions];
        for(ContentVersion contentVersion1 : contentVersions1)
        {
            ContentDocumentLink contentDocumentLink = createContentDocumentLink(contentVersion1.ContentDocumentId, bizIsland.Id);
            contentDocumentLinks.add(contentDocumentLink);
        }
        insert contentDocumentLinks;
    }
    
}