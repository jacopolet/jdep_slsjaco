import { LightningElement, wire, track ,api} from "lwc";
import getCER from '@salesforce/apex/APTS_CreateOrderNewUXCtrl.getCER';
const columns = [
    { label:'Product Code',sortable:true, fieldName: 'APTS_Product_Code__c', type: 'text'},
    { label: 'Bundle', sortable:true, fieldName: 'ProdName', type: 'text' },
    { label: 'Option', sortable:true, fieldName: 'OptionName', type: 'text'},
    { label: 'Contracted On', sortable:true, fieldName: 'COntractedOn', type: 'text'},
    { label: 'Contract Type', fieldName: 'ContractType', type: 'text'} ,
    { label:'Quantity', fieldName: 'qty', type: 'text' ,editable: true}       
];
export default class AptsCPPPage extends LightningElement {
    

    @api recordId;   
    @api  allRecords;
    @track error;
    sapAccName;
    AccName;
   // @track allRecords;  
    @track columns = columns;
    @track cssClass = 'slds-button slds-button_neutral';
    @track iconName = '';
    checkedOptionValue; 
    showAddToCartButton;
   
    buttonClicked; 
  @api enabledSelections;
  @api isLoaded;
  @wire(getCER,{recordId: '$recordId'})  
  wCER({ error, data }) {       
    if(data){
        var allRecords = [];
      
      if(data[0].APTS_Sold_to_Party__c)
      {this.sapAccName=data[0].APTS_Sold_to_Party__r.SAP_Customer_ID__c;
      this.AccName= data[0].APTS_Sold_to_Party__r.Name;
      console.log('Lavanya console chk'+this.AccName);}
        let recs = [];
         for(let i=0; i<data.length; i++){
            let cer = {};
            cer.linetype=  data[i].APTS_Agreement_Line_Item__r.Apttus_CMConfig__LineType__c;
            cer.primaryline = data[i].APTS_Agreement_Line_Item__r.Apttus_CMConfig__IsPrimaryLine__c;
            if(cer.linetype=='Product/Service' && cer.primaryline==true)        
            {cer.ProdName = data[i].APTS_Product__r.Name; 
            cer.prodCode=data[i].APTS_Product_Code__c;
            cer.COntractedOn = data[i].APTS_Contributing_Agreement_Level__c;
            cer.ContractType = data[i].APTS_Agreement_Line_Item__r.APTS_Type_of_Contract__c  ;
            cer.qty= data[i].APTS_Agreement_Line_Item__r.Apttus__Quantity__c;
            }
            else if(cer.linetype=='Option')
            {cer.OptionName = data[i].APTS_Product__r.Name;}
            
            cer = Object.assign(cer, data[i]); 
            recs.push(cer);

        }
        this.allRecords = recs;
       // console.log('Lavanya cer'+allRecords);
    }else{
        this.error = error;
    }       
  }

  handleSelectedItem(event){
    
    this.checkedOptionValue = event.detail;
    let selectedOptionlines = [];  
    this.showAddToCartButton=false;
    console.log('selectedRows=====>'+JSON.stringify(this.checkedOptionValue));
    console.log('selectedRows==LEN===>'+this.checkedOptionValue.length);        
    if(this.checkedOptionValue!=undefined && this.checkedOptionValue!=null && this.checkedOptionValue.length > 0 ){
        //selectedOptionlines = this.checkedOptionValue;
        this.checkedOptionValue.forEach(option => {
            selectedOptionlines.push(option.id);
        });
        if(selectedOptionlines)
        {
            this.showAddToCartButton= true;
        }
        console.log('selectedOptionlines===>'+selectedOptionlines); 
        this.allRecords.forEach(record => {
          // 
        });
       
        //this.endDateValue = null;
        //this.showRemoveButton=true;
    }
}

 //Modal try
 @track bShowActionModal = false;   
    @track selectedActions;
	@track bShowChangeAssetModal;
	@track isStatusScreen = false;

openModal() {    
        // to open modal window set 'bShowActionModal' tarck value as true
        this.bShowActionModal = true;
        this.selectedActions = undefined;
        this.bShowChangeAssetModal = false;
//this.resetConverionOrderSeletion();
    }
 
     closeChangeAssetModal() {
        this.bShowChangeAssetModal = false;
    }    
	
	 closeModal() {    
        // to close modal window set 'bShowActionModal' tarck value as false
        this.bShowActionModal = false;
        
        //this.resetConverionOrderSeletion();
    } 
	
	
	openChangeAssetModal() {
        this.bShowChangeAssetModal = true;
        this.bShowActionModal = false;
       // this.resetConverionOrderSeletion();
    }
	
	createOrder(event) {
       
       
                    this.isStatusScreen=true;
                
 
}
  
}