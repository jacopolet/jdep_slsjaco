//-------------------------------------------------------------------------------------------//
// Author       :   Rey Austral - Accenture
// Created Date :   May 12, 2017
// Usage        :   Controller of WorkOrderSignature Page
//-------------------------------------------------------------------------------------------//
public with sharing class TS_SignatureGeneratorController {
    private ApexPages.standardController controller;
    public WorkOrderLineItem woli { get; set; }
    private List<photoWrapper> photoIds;
    public List<photoWrapper> photos {
        get {
            if(photoIds == null) {
                photoIds = new List<photoWrapper>();
                String sig = '%' + INT_Constants.CLICK_SIGNATUREFILE + '%';
                String quoteSig = '%' + INT_Constants.CLICK_QUOTESIGNATUREFILE + '%';
                //String attach = '%' + INT_Constants.CLICK_ATTACHMENTFILE + '%';
                //String attach1 = '%' + INT_Constants.CLICK_ATTACHMENT1FILE + '%';
                //String attach2 = '%' + INT_Constants.CLICK_ATTACHMENT2FILE + '%';
                for(Attachment att : [select Id,Name from Attachment where ParentId =: woli.Id  and 
                    (Name Like : sig Or Name Like : quoteSig) Order by CreatedDate]) {
                    photoWrapper p = new photoWrapper();
                    p.signatureId = att.Id;
                    if (att.Name.Contains('Quote')) {
                        p.signatureLabel = INT_Constants.CLICK_QUOTESIGNATUREFILE;
                    } else {
                        p.signatureLabel = INT_Constants.CLICK_SIGNATUREFILE;
                    }
                    photoIds.add(p);
                }
            }
            
            return photoIds;
        }
    }
    
    public class photoWrapper {
        public String signatureLabel { get; set; }
        public String signatureId { get; set; }
    }
    public TS_SignatureGeneratorController(ApexPages.StandardController controller) {
        CustomLogging.push('TS_SignatureGeneratorController', 'TS_SignatureGeneratorController');
        this.controller = controller;
        this.woli = (WorkOrderLineItem)controller.getRecord();
        CustomLogging.pop();
    }
}