import { LightningElement, track, api, wire } from 'lwc';
import {ShowToastEvent} from 'lightning/platformShowToastEvent';
import uploadFile from '@salesforce/apex/TS_MassUploadServiceController.uploadFile';
import getProcessCountrySettings from '@salesforce/apex/TS_MassUploadServiceController.getProcessCountrySettings';
import getAccess from '@salesforce/apex/TS_MassUploadServiceController.checkAccess';
import portalAccessErrorMessage from '@salesforce/label/c.TS_PortalAccessError';
import userIdImport from '@salesforce/user/Id';

export default class FileUploadExample extends LightningElement {
    
    @track showLoadingSpinner = false;
    @track showTable = false;
    @track fileName = '';
    @track filesUploaded = [];
    @track fileContents;
    @track ErrorMessageFileValidation;
    @track SuccessMessageFileValidation;
    @track selectedProcess = null;
    @track options = [];
    @track recordMapVar;

    //table fields
    @track requiredFields = '';
    @track optionalFields = '';
    @track acceptableList = [];
    @track conditionalList = [];;

    picklistlabel = 'Process Name';
    disableProceed = true;
    proceed = false;
    processNameVar = 'Mass Update Jobs 3PO';
    file;
    fileReader;
    content;
    //MAX_FILE_SIZE = 1500000;
    targetElem;
    hasAccess = false;
    userId = userIdImport;
    valueDelimiter = ',';
    portalErrorMessage = '';

    get options() {
        return [
            { label: '; (Semicolon)', value: ';' },
            { label: ', (Comma)', value: ',' },
        ];
    }

    getSelection(event){
        this.valueDelimiter = event.detail.value;
    }

    @wire(getProcessCountrySettings)
    wireCountrySettings({ error, data }) {
        if (data) {

            let recordMap = new Map()
            //console.log(data);
            for(const list of data){
 
                const option = {
                    label: list.Name,
                    value: list.Name
                };
                this.options = [ ...this.options, option ];
                recordMap.set(list.Name, list);
            };
            this.selectedProcess = this.processNameVar;
            this.recordMapVar = recordMap;  
            
            /**initial values*/
            if(this.recordMapVar.has(this.selectedProcess)){

                let selectedRecord = this.recordMapVar.get(this.selectedProcess);
                this.requiredFields = (selectedRecord.Required_Fields__c  !=null && selectedRecord.Required_Fields__c != undefined) ? selectedRecord.Required_Fields__c.replaceAll(',', ', ') : '';
                this.optionalFields = (selectedRecord.Optional_Fields__c  !=null && selectedRecord.Optional_Fields__c != undefined) ? selectedRecord.Optional_Fields__c.replaceAll(',', ', ') : '';;
    
                //acceptable values
                if(selectedRecord.Acceptable_Values__c !=null && selectedRecord.Acceptable_Values__c != undefined){
                    let acceptables = selectedRecord.Acceptable_Values__c.replaceAll(':', ': ');
                    let accs = acceptables.replaceAll(',', ', ');
                    let acc = accs.split(";");
                    let acList = [];
                    for(const val of acc){
                        if(val != '' && val != null){
                            acList.push(val);
                        }    
                    }
                    this.acceptableList = acList;
                }else{
                    this.acceptableList = [];
                }
                
                //conditionally required values
                if(selectedRecord.Conditional_Fields_Values__c !=null && selectedRecord.Conditional_Fields_Values__c != undefined){
                    let cond = selectedRecord.Conditional_Fields_Values__c.replaceAll('[', ' = ');
                    let con = cond.replaceAll(']:', ', ');
                    let cons = con.split(';');
                    let conList = [];
                    for(const val of cons){
                        if(val != '' && val != null){
                            conList.push(val);
                        }                           
                    }
                    this.conditionalList = conList;
                }else{
                    this.conditionalList = [];
                }
                
                this.showTable = true;

            }           
           
        } else if (error) {
            //console.log(error);
        }
    }

    label = {
        portalAccessErrorMessage
    };

    connectedCallback(){
        //console.log('connectedCallback')
        this.portalErrorMessage = this.label.portalAccessErrorMessage;
        this.checkAccess();
    }

    renderedCallback(){
        //console.log('renderedCallback')
    }

    checkAccess(){
        getAccess()
            .then(result => {
                let resp = JSON.parse(result);
                //console.log(resp);
                if(resp.status != 'ERROR'){
                    this.hasAccess = (resp.returnValue == 'true');
                } else {
                    this.hasAccess = false;
                    this.portalErrorMessage = resp.message;
                }
            })
            .catch(error => {
                console.log(error);
            });
    }

    handleValueChange(event) {        
        this.selectedProcess = event.detail.value;
        let selectedRecord = this.recordMapVar.get(this.selectedProcess);
        this.requiredFields = (selectedRecord.Required_Fields__c  !=null && selectedRecord.Required_Fields__c != undefined) ? selectedRecord.Required_Fields__c.replaceAll(',', ', ') : '';
        this.optionalFields = (selectedRecord.Optional_Fields__c  !=null && selectedRecord.Optional_Fields__c != undefined) ? selectedRecord.Optional_Fields__c.replaceAll(',', ', ') : '';;

        //acceptable values
        if(selectedRecord.Acceptable_Values__c !=null && selectedRecord.Acceptable_Values__c != undefined){
            let acceptables = selectedRecord.Acceptable_Values__c.replaceAll(':', ': ');
            let accs = acceptables.replaceAll(',', ', ');
            let acc = accs.split(";");
            let acList = [];
            for(const val of acc){
                acList.push(val);    
            }
            this.acceptableList = acList;
        }else{
            this.acceptableList = [];
        }
        
        //conditionally required values
        if(selectedRecord.Conditional_Fields_Values__c !=null && selectedRecord.Conditional_Fields_Values__c != undefined){
            let cond = selectedRecord.Conditional_Fields_Values__c.replaceAll('[', ' = ');
            let con = cond.replaceAll(']:', ', ');
            let cons = con.split(';');
            let conList = [];
            for(const val of cons){
                conList.push(val);    
            }
            this.conditionalList = conList;
        }else{
            this.conditionalList = [];
        }
       
        this.showTable = true;
    }

    handleFilesChange(event) {
        if(event.target.files.length > 0) {
            this.filesUploaded = event.target.files;
            this.fileName = event.target.files[0].name;

            let fileExt = this.fileName.substr(this.fileName.length - 3);
            if(fileExt !== 'csv'){
                this.ErrorMessageFileValidation = this.fileName + ' is not a supported file. Please upload a csv file.';
                this.SuccessMessageFileValidation = null;
                this.disableProceed = true;
            } else {
                this.uploadHelper();
            }
            
        }
    }

    proceedUpload() {
        this.proceed = true;
        this.uploadHelper();
    }

    uploadHelper() {
        this.showLoadingSpinner = true;
        
        if(!this.proceed){
            this.file = this.filesUploaded[0];
        
            /* if(this.file.size > this.MAX_FILE_SIZE) {
                window.console.log('File Size is to long');
                return ;
            } */
        }
        
        //CREATE A FileReader OBJECT 
        this.fileReader= new FileReader();

        //SET ONLOAD FUNCTION OF FileReader OBJECT  
        this.fileReader.onloadend = (() => {
            this.fileContents = this.fileReader.result;
            let base64 = 'base64,';
            this.content = this.fileContents.indexOf(base64) + base64.length;
            this.fileContents = this.fileContents.substring(this.content);

            //console.log('fileContents: ' + this.fileContents);
            
            //CALL THE ACTUAL uploadProcess METHOD 
            uploadFile({fileName : this.fileName, 
                        base64code : this.fileContents, 
                        processName : this.processNameVar, 
                        proceedProcessing : this.proceed,
                        delimiter : this.valueDelimiter})
                .then(result => {
                    //console.log(result);
                    this.ErrorMessageFileValidation = '';
                    this.showLoadingSpinner = false;

                    let resultParse = JSON.parse(result);
                    //console.log('resultParse.status: ' + resultParse.status)
                    //console.log('resultParse.message: ' + resultParse.message)
                    
                    if(!this.proceed){
                        if(resultParse.status == 'ERROR'){
                            this.ErrorMessageFileValidation = resultParse.message;
                            this.SuccessMessageFileValidation = null;
                            this.disableProceed = true;
                        } else{
                            this.SuccessMessageFileValidation = this.file.name + ' has been successfully validated.'
                            this.ErrorMessageFileValidation = null;
                            this.disableProceed = false;
                        }
                    } else {

                        this.ErrorMessageFileValidation = null;
                        this.SuccessMessageFileValidation = null;

                        if(resultParse.status == 'ERROR'){
                            //SHOWING ERROR AFTER UPLOAD INSERT
                            this.dispatchEvent(
                                new ShowToastEvent({
                                    title: 'Error',
                                    message: resultParse.message,
                                    variant: 'error',
                                }),
                            );
                        } else{
                            //SHOWING SUCCESS AFTER UPLOAD INSERT
                            this.dispatchEvent(
                                new ShowToastEvent({
                                    title: 'Success',
                                    message: 'Mass upload has been successfully queued.',
                                    variant: 'success',
                                }),
                            );
                        }
                        this.proceed = false;
                        this.disableProceed = true;
                    }
                })
                .catch(error => {
                    console.log(error);
                    this.showLoadingSpinner = false;
                });
            
            //RESETTING THE FILE INPUT TYPE ELEMENT SO THE USER CAN UPLOAD AGAIN WITHOUT REFRESHING THE ENTIRE PAGE
            this.targetElem = this.template.querySelector('[aura-id="testid"]');
            this.targetElem.value= "";
        });
        this.fileReader.readAsDataURL(this.file);
    }
}