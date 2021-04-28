/**
 * @description       : LWC used for showing second page (category hierarchy and selection of products) of Agreement New UX
 * @author            : Karan Khatri
 * @group             : 
 * @last modified on  : 20-04-2021
 * @last modified by  : Karan Khatri
 * Modifications Log 
 * Ver   Date         Author         Modification
 * 1.0   19-03-2021   Karan Khatri   Initial Version(DQ-4112)
**/

import { LightningElement,wire,track,api } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getCategoryDetails from '@salesforce/apex/APTS_InitiateAgreementController.getAllCategoryDetails';
import staticResource from '@salesforce/resourceUrl/AgreementNewUX';
const columns = [        
    //{ label: 'Product Image:', fieldName: 'productImage', type: 'image'/*,cellAttributes:{class:{fieldName: 'modifiedLineItem'}}*/},
    { label: 'Product Code:', fieldName: 'productCode', type: 'text',initialWidth:140/*,cellAttributes:{class:{fieldName: 'modifiedLineItem'}}*/}, 
    { label:'Product Name:', fieldName: 'productLink', type: 'url',typeAttributes: {label: {fieldName: 'productName'}, tooltip: {fieldName: 'productName'}, target: '_blank'}},
    //{ label: 'Configuration Type:', fieldName: 'configurationType', type: 'text',/*,cellAttributes:{class:{fieldName: 'modifiedLineItem'}}*/} , 
    //{ label: 'Quantity:', fieldName: 'quantity', type: 'number', editable: true ,cellAttributes:{cellAttributes: { alignment: 'left' }}} ,
    //{ label: 'Description:', fieldName: 'description', type: 'text'/*,cellAttributes:{class:{fieldName: 'modifiedLineItem'}}*/} , 
    { label: 'Action:', fieldName: 'buttonName', type:'button',initialWidth:140, typeAttributes: {label:' Add to Cart ',name:'AddToCart',tooltip: 'Add this product to cart',target:'_blank'/*,disabled:{fieldName:'cancelOrder'}*/}},      
];
const miniCartColumns = [        
    { label:'Product Name:', fieldName: 'productLink', type: 'url', typeAttributes: {label: {fieldName: 'productName'}, tooltip:{fieldName: 'productName'}, target: '_blank'}},
   // { label: 'Configuration Type:', fieldName: 'configurationType', type: 'text'/*,cellAttributes:{class:{fieldName: 'modifiedLineItem'}}*/} , 
   // { label: 'Quantity:', fieldName: 'quantity', type: 'number', editable: true ,cellAttributes:{cellAttributes: { alignment: 'left' }}} ,
    { label: 'Action:', fieldName: 'buttonName', type:'button',initialWidth:110, typeAttributes: {label:' Remove ',name:'RemoveFromCart',tooltip: 'Add this product to cart',target:'_blank'/*,disabled:{fieldName:'cancelOrder'}*/}},      
]; 
export default class AptsAgreementCatalogPage extends LightningElement {
    @track columns = columns;
    @track miniCartColumns = miniCartColumns;
    @api agreementwrapper;
    @api minicartwrapper;
    @track addToCartList;
    displayCategories;
    allCategories;
    checkedCatalogProducts;
    showProductsTable;
    productClassificationRecs;
    tableRecordsExist;
    showAddToCartButton;
    showRemoveButton;
    oldlist;
    jdeProfessionalLogo = staticResource + '/images/JDE_Proffesional.png';
    showMiniCart;
    selectedMiniProducts;
    checkedMiniCartProducts;
    categoryProductList;
    searchProductText;
    selectedCategory;
    browseCatalogMode;
    globalSearchMode;
    @track isLoaded=false;
    //@wire(getCategoryDetails({recordId: this.recordId},{agreementWrapper:this.agreementWrapperList}).then(data) => {
    /*@wire(getCategoryDetails)
        wiredCategories({ error, data }) {*/
    @wire(getCategoryDetails, { agreementwrapper : '$agreementwrapper' })
        wiredCategories({ error, data }) {
        this.showProductsTable=false;
        this.showAddToCartButton=false;
        this.showMiniCart=false;
        console.log('this.minicartwrapper===>'+this.minicartwrapper);
        console.log('this.showMiniCart===>'+this.showMiniCart);
        if(this.minicartwrapper!='null' && this.minicartwrapper!=null && this.minicartwrapper!=undefined && this.minicartwrapper!=''){
            var miniCartWrapperList = JSON.parse(this.minicartwrapper);
            console.log('miniCartWrapperList===>'+miniCartWrapperList);
            if(miniCartWrapperList.length>1){
                this.addToCartList=miniCartWrapperList;
                this.showMiniCart=true;
            }
        }
        console.log('this.addToCartList===>'+this.addToCartList);
        console.log('this.showMiniCart=E==>'+this.showMiniCart);
        //console.log('staticResource=======>'+staticResource + '/images/JDE_Proffesional.png');
        if(data){   
            //console.log('AGREEMENT LIST=====>'+JSON.stringify(this.agreementwrapper));
            //console.log('CATEGORY PAGE data=====>'+JSON.stringify(data));
            let recs = [];
            let allCategoriesrecs = [];
            for(let i=0; i<data.length; i++){
                let category = {};
                category = Object.assign(category, data[i]); 
                //console.log('category===>'+category);
                //console.log('category=L1==>'+JSON.stringify(category.items));
                /*for(let i=0; i<category.Hierarchylevel1List.length; i++){
                    console.log('category=L2==>'+JSON.stringify(category.Hierarchylevel1List[i].Hierarchylevel2List));
                }*/
                if(category.name!='All'){
                    recs.push(category);
                }else{
                    allCategoriesrecs.push(category);
                }
                this.isLoaded=true;
            }   
            this.displayCategories=recs;
            this.allCategories=allCategoriesrecs;
            if(recs.length==0){
                this.showToast(false,'Dear User, The selected pricelist doesnt have any category linked please choose another pricelist to proceed!','error','sticky');
            }
        }else{
            this.error = error;
        }
        this.globalSearchMode=true;
        this.browseCatalogMode=false;
        //console.log('this.isLoaded===>'+this.isLoaded);
    }
    handleSelectedCategory(event){
        var categoryFound=false;
        //console.log('ID====>'+event.detail.name);
        this.oldlist=this.productClassificationRecs;
        this.browseCatalogMode=true;
        this.globalSearchMode=false;
        this.productClassificationRecs=[];
        this.checkedCatalogProducts=undefined;
        this.showProductsTable=false;
        this.tableRecordsExist=false;
        this.searchProductText=undefined;
        this.searchAllProductsIndicator=false;
        this.selectedCategory=event.detail.name;
        if(this.displayCategories && this.selectedCategory){
            //this.showProductsTable=true;
            //check on category level
            this.displayCategories.forEach(category => {
               if(category.name == this.selectedCategory && category.products){
                    categoryFound=true;
                    this.showProductsTable=true;
                    //console.log('Category level');
                    this.productClassificationRecs = category.products;
                    //console.log('this.productClassificationRecs==L0======>'+JSON.stringify(this.productClassificationRecs));
               }
            });
             //check on hierarchy level 1
            if(categoryFound==false){
                if(this.displayCategories){
                    this.displayCategories.forEach(category => {
                        if(category.items){
                            category.items.forEach(categoryL1 => {
                                //console.log('l1 name==>'+categoryL1.name);
                                //console.log('l1 products==>'+categoryL1.products);
                                if(categoryL1.name == this.selectedCategory && categoryL1.products){
                                    categoryFound=true;
                                    this.showProductsTable=true;
                                    this.productClassificationRecs = categoryL1.products;
                                    //console.log('Category hierarchy level 1');
                                    //console.log('this.productClassificationRecs==L1======>'+JSON.stringify(this.productClassificationRecs));
                                }
                            });
                        }
                    });
                }
            }
            //check on hierarchy level 2
            if(categoryFound==false){
                this.displayCategories.forEach(category => {
                    if(category.items){
                        category.items.forEach(categoryL1 => {
                            if(categoryL1.items){
                                categoryL1.items.forEach(categoryL2 => {
                                    if(categoryL2.name == this.selectedCategory && categoryL2.products){
                                        this.showProductsTable=true;
                                        categoryFound=true;
                                        this.productClassificationRecs = categoryL2.products;
                                        //console.log('Category hierarchy level 2');
                                        //console.log('this.productClassificationRecs==L2======>'+JSON.stringify(this.productClassificationRecs));
                                    }
                                });
                            }
                        });
                    }
                });
            }
        }
        //console.log('CATEGORY JSON=OLD===>'+JSON.stringify(this.oldlist));
        if(this.oldlist && this.oldlist.length>0){
            //console.log('CATEGORY LEN===>'+this.oldlist.length);
            this.tableRecordsExist=true;
        }
       // console.log('tableRecordsExist==E==>'+this.tableRecordsExist);
        if(this.tableRecordsExist==true){
            this.template.querySelector('c-apts-lwc-datatable').handleTotalRecordsChange(this.productClassificationRecs);
        }
        this.categoryProductList=this.productClassificationRecs;
    }
    handleAddToCart(event){
        /*console.log('Handle Add to Cart======>');
        console.log('lineItemDetail======>'+lineItemDetail);
        console.log('this.addToCartList======>'+this.addToCartList);
        console.log('Handle Add to Cart======>');*/
        let recs= [];
        if(this.addToCartList){
            recs = this.addToCartList;

        }
        if(event.detail){
            let product = {};
            product = Object.assign(product, event.detail); 
            if(this.addToCartList){
                product.rowIndex=this.addToCartList.length+1;
            }else{
                product.rowIndex=1;
            }
            recs.push(product);
        }
        //console.log('lineItemDetail======>'+lineItemDetail);
        this.addToCartList=recs;
        //this.template.querySelector('c-apts-lwc-datatable').handleTotalRecordsChange(this.addToCartList);
        //console.log('this.addToCartList===E===>'+this.addToCartList);
        //console.log('LENGTH===>'+this.addToCartList.length);
        this.showMiniCart=true;
        //console.log('this.addToCartList===E===>'+JSON.stringify(this.addToCartList));
        /*this.template.querySelectorAll('c-apts-lwc-datatable').forEach(each => {
            console.log('each value =====>'+ each);
        }); */
        if(this.addToCartList!=undefined && this.addToCartList!=null && this.addToCartList!='' && this.addToCartList.length>=170){
            this.showToast(false,'Dear User, Cart threshold limit has exceeded as you are trying to add more than 170 line items.','error','sticky');
        }
        this.showToast(false,'1 item has been added to Cart!','success','pester');
        if(this.template.querySelectorAll('c-apts-lwc-datatable').length==2){
            this.template.querySelectorAll('c-apts-lwc-datatable')[1].handleTotalRecordsChange(this.addToCartList);
        }
    }

    handleMiniCart(event){

    }
    handleSelectedCatalogItem(event){
        this.selectedProducts = event.detail;
        this.checkedCatalogProducts = [];
        this.showAddToCartButton=false;
        if(this.selectedProducts!=undefined && this.selectedProducts!=null && this.selectedProducts.length > 0){
            //selectedOptionlines = this.checkedCatalogProducts;
            this.selectedProducts.forEach(option => {
                this.checkedCatalogProducts.push(option.productid);
            });
            this.showAddToCartButton=true;
        }
        //console.log('selected rows===>'+this.template.querySelector('c-apts-lwc-datatable').selectedRecords);
        if(this.template.querySelector('c-apts-lwc-datatable').selectedRecords){
            this.template.querySelector('c-apts-lwc-datatable').selectedRecords=[];
        }
        //console.log('Selected Products from Catalog====>'+this.checkedCatalogProducts);
    }
    handleAddToCartBulk(event){
          /*console.log('Handle Add to Cart======>');
        console.log('lineItemDetail======>'+lineItemDetail);
        console.log('this.addToCartList======>'+this.addToCartList);
        console.log('Handle Add to Cart======>');*/
        //console.log('Selected Products====>'+this.checkedCatalogProducts);
        var haserror=false;
        let recs= [];
        if(this.addToCartList){
            recs = [...this.addToCartList];
        }
        /*let selectedOptionMap = this.checkedCatalogProducts.reduce(function(map, obj) {
            map[obj.productid] = obj;
            return map;
        }, {});*/
        /*console.log('recs Before BULK======>'+JSON.stringify(selectedOptionMap));
        console.log('selectedOptionMap BULK======>'+JSON.stringify(selectedOptionMap));*/
        var productIds = this.checkedCatalogProducts.toString().split(',');
        //console.log('productIds======>'+productIds);
        //console.log('this.productClassificationRecs BULK======>'+JSON.stringify(this.productClassificationRecs));
        this.productClassificationRecs.forEach(optionObj => {  
            //console.log('optionObj===>'+optionObj);
            let product = {};
            product = Object.assign(product, optionObj); 
            //console.log('INSIDE FOR EACH======>'+JSON.stringify(product));
            if(productIds.includes(product.productid)){
                if(recs){
                    product.rowIndex=recs.length+1;
                }else{
                    product.rowIndex=1;
                }
                recs.push(product);
            }
        })  
        console.log('recs BULK======>'+recs.length);
        if(this.addToCartList!='' && this.addToCartList!=null && this.addToCartList!=undefined){
            console.log('addtocart BULK======>'+this.addToCartList.length);
        }
        if(recs!=undefined && recs!=null && recs!='' && recs.length>170){
            this.showToast(false,'Dear User, Cart threshold limit has exceeded as you are trying to add more than 170 line items.','error','sticky');
            haserror=true;
        }
        console.log('haserror=====>'+haserror);
        if(recs!=undefined && recs!=null && recs!='' && recs.length<=170 && haserror==false){
            this.addToCartList=recs;
            //this.template.querySelector('c-apts-lwc-datatable').handleTotalRecordsChange(this.addToCartList);
            //console.log('this.addToCartList===E===>'+this.addToCartList);
            //console.log('LENGTH===>'+this.addToCartList.length);
            this.showMiniCart=true;
            //console.log('this.addToCartList===E===>'+JSON.stringify(this.addToCartList));
            /*this.template.querySelectorAll('c-apts-lwc-datatable').forEach(each => {
                console.log('each value =====>'+ each);
            }); */
            //console.log('this.checkedCatalogProducts===========>'+this.checkedCatalogProducts);
            //console.log('this.checkedCatalogProducts===========>'+this.selectedProducts);
            if(this.checkedCatalogProducts.length==1){
                this.showToast(false,'1 item has been added to Cart!','success','pester');
            }
            if(this.checkedCatalogProducts.length>1){
                this.showToast(false,this.checkedCatalogProducts.length+' items has been added to Cart!','success','pester');
            }
            this.checkedCatalogProducts=undefined;
            this.selectedProducts=undefined;
        // console.log('selected records TABLE-===========>'+this.template.querySelector('c-apts-lwc-datatable').selectedRecords);
            if(this.template.querySelector('c-apts-lwc-datatable').preSelected){
                this.template.querySelector('c-apts-lwc-datatable').preSelected=[];
            }
            if(this.template.querySelector('c-apts-lwc-datatable').totalSelected){
                this.template.querySelector('c-apts-lwc-datatable').totalSelected=0;
            }
            if(this.template.querySelectorAll('c-apts-lwc-datatable').length==2){
                this.template.querySelectorAll('c-apts-lwc-datatable')[1].handleTotalRecordsChange(this.addToCartList);
            }
            this.showAddToCartButton=false;
        }
    }
    showToast(title,message,variant,mode) {
        const event = new ShowToastEvent({
            title: title,
            message: message,
            variant:variant,
            mode: mode
        });
        this.dispatchEvent(event);
    }
    
    handleRemove(event){
        /*console.log('Handle Add to Cart======>');
        console.log('lineItemDetail======>'+lineItemDetail);
        console.log('this.addToCartList======>'+this.addToCartList);
        console.log('Handle Add to Cart======>');*/
        console.log('lineItemDetail===REMOVE===>'+JSON.stringify(this.addToCartList));
        let recs= [];
        let linkedProduct = {};
        linkedProduct = Object.assign(linkedProduct, event.detail);
        console.log('lineItemDetail===REMOVE===>'+JSON.stringify(linkedProduct));
        if(event.detail){
            if(this.addToCartList){
                //product.rowIndex=this.addToCartList.length+1;
                this.addToCartList.forEach(optionObj => {
                    let product = {};
                    product = Object.assign(product, optionObj); 
                    console.log('lineItemDetail.productid===>'+linkedProduct.rowIndex);
                    console.log('product.productid===>'+product.rowIndex);
                    if(linkedProduct.rowIndex!=product.rowIndex){
                        recs.push(product);
                    }
                })
            }
        }
        //console.log('lineItemDetail======>'+lineItemDetail);
        this.addToCartList=recs;
        if(this.addToCartList && this.addToCartList.length>0){
            this.showMiniCart=true;
        }else{
            this.showMiniCart=false;
        }
        //this.template.querySelector('c-apts-lwc-datatable').handleTotalRecordsChange(this.addToCartList);
        console.log('this.addToCartList==REMOVE===>'+JSON.stringify(this.addToCartList));
        //console.log('LENGTH===>'+this.addToCartList.length);
        //this.showMiniCart=true;
        //console.log('this.addToCartList===E===>'+JSON.stringify(this.addToCartList));
        /*this.template.querySelectorAll('c-apts-lwc-datatable').forEach(each => {
            console.log('each value =====>'+ each);
        }); */
        if(this.template.querySelectorAll('c-apts-lwc-datatable').length==2){
            this.template.querySelectorAll('c-apts-lwc-datatable')[1].handleTotalRecordsChange(this.addToCartList);
        }
        this.showToast(false,'1 item has been removed from the Cart!','success','pester');
    }
    handleSelectedMiniCartitem(event){
        this.selectedMiniProducts = event.detail;
        this.checkedMiniCartProducts = [];
        this.showRemoveButton=false;
        if(this.selectedMiniProducts!=undefined && this.selectedMiniProducts!=null && this.selectedMiniProducts.length > 0){
            //selectedOptionlines = this.checkedCatalogProducts;
            this.selectedMiniProducts.forEach(option => {
                this.checkedMiniCartProducts.push(option.rowIndex);
            });
            this.showRemoveButton=true;
        }
        if(this.template.querySelectorAll('c-apts-lwc-datatable').length==2 && this.template.querySelectorAll('c-apts-lwc-datatable')[1].selectedRecords){
            this.template.querySelectorAll('c-apts-lwc-datatable')[1].selectedRecords=[];
        }
        console.log('Selected Products from Mini Cart====>'+this.checkedMiniCartProducts);
    }
    handleRemoveBulk(event){
        let recs= [];
        var productIndexes = this.checkedMiniCartProducts.toString().split(',');
        console.log('productIndexes===>'+productIndexes);
        if(this.addToCartList && this.addToCartList.length>0){
            //product.rowIndex=this.addToCartList.length+1;
            this.addToCartList.forEach(optionObj => {
                let product = {};
                product = Object.assign(product, optionObj); 
                console.log('product.productid===>'+product.rowIndex);
                console.log('productIndexes===>'+productIndexes);
                console.log('includes===>'+productIndexes.includes(product.rowIndex.toString()));
                if(productIndexes.includes(product.rowIndex.toString())===false){
                    recs.push(product);
                }
            })
            this.addToCartList=[...recs];
            if(this.addToCartList && this.addToCartList.length>0){
                this.showMiniCart=true;
            }else{
                this.showMiniCart=false;
            }
            //this.template.querySelector('c-apts-lwc-datatable').handleTotalRecordsChange(this.addToCartList);
            console.log('this.addToCartList==REMOVE===>'+JSON.stringify(this.addToCartList));
            //console.log('LENGTH===>'+this.addToCartList.length);
            //this.showMiniCart=true;
            //console.log('this.addToCartList===E===>'+JSON.stringify(this.addToCartList));
            /*this.template.querySelectorAll('c-apts-lwc-datatable').forEach(each => {
                console.log('each value =====>'+ each);
            }); */
            if(this.template.querySelectorAll('c-apts-lwc-datatable').length==2){
                this.template.querySelectorAll('c-apts-lwc-datatable')[1].handleTotalRecordsChange(this.addToCartList);
            }
            if((this.addToCartList!='null' && this.addToCartList!=null && this.addToCartList!=undefined && this.addToCartList!='' && this.addToCartList.length>0 && this.template.querySelectorAll('c-apts-lwc-datatable').length==1)){
                this.template.querySelectorAll('c-apts-lwc-datatable')[0].handleTotalRecordsChange(this.addToCartList);1
            }
            if(this.checkedMiniCartProducts.length==1){
                this.showToast(false,'1 item has been removed from the Cart!','success','pester');
            }
            if(this.checkedMiniCartProducts.length>1){
                this.showToast(false,this.checkedMiniCartProducts.length+' items has been removed from the Cart!','success','pester');
            }
        }
        this.showRemoveButton=false
    }
    handleJDELogoClick(event){
        console.log('--Redirect to home page--');
        this.showProductsTable=false;
        this.categoryProductList=undefined;
        this.searchAllProductsIndicator=true;
        this.selectedCategory=undefined;
        this.showAddToCartButton=false;
        this.showRemoveButton=false;
        this.browseCatalogMode=false;
        this.globalSearchMode=true;
        this.productClassificationRecs=undefined;
    }
    handleBack(){
        this.dispatchEvent(
            new CustomEvent("gotopreviouspage", {
            bubbles:true,
            composed:true,
            detail: true
            })
        );
        this.dispatchEvent(
            new CustomEvent("minicartitems", {
            bubbles:true,
            composed:true,
            detail: this.addToCartList
            })
        );
    }
    handleNext(){
        this.dispatchEvent(
            new CustomEvent("minicartitems", {
            bubbles:true,
            composed:true,
            detail: this.addToCartList
            })
        );
        this.dispatchEvent(
            new CustomEvent("gotonextpage", {
            bubbles:true,
            composed:true,
            detail: true
            })
        );
    }
}