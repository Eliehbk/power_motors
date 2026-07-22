/** 
@author          Elie Habka
@date            7/21/2026
@description     This Lightning Web Component handles displaying a searchable product catalog, filtering products by category or country,
                  viewing product details, and creating a won Opportunity from the selected items.
*/
import { LightningElement, api, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { getPicklistValues } from 'lightning/uiObjectInfoApi';
import { NavigationMixin } from 'lightning/navigation';
import ORIGIN_FIELD from '@salesforce/schema/Product2.Country_of_Origin__c';
import getB2CProductsPaged from '@salesforce/apex/B2CProductController.getB2CProductsPaged';
import createWonOpportunity from '@salesforce/apex/B2CProductController.createWonOpportunity';

export default class B2cProductCatalog extends NavigationMixin(LightningElement) {
    @api recordId;

    products = [];
    selectedProduct = null;
    selectedRowIds = [];

    pageSize = 5;
    currentPage = 1;
    hasNextPage = false;

    selectedCategory = 'All';
    selectedCountry = 'All';

    categoryOptions = [
        { label: 'All Types', value: 'All' },
        { label: 'Generators', value: 'Generators' },
        { label: 'Parts', value: 'Parts' }
    ];

    countryOptions = [{ label: 'All Countries', value: 'All' }];

    columns = [
        { label: 'Product Name', fieldName: 'name', type: 'text' },
        { label: 'Code', fieldName: 'code', type: 'text' },
        { label: 'Type', fieldName: 'recordType', type: 'text' },
        { label: 'Origin', fieldName: 'origin', type: 'text' },
        { label: 'Price', fieldName: 'price', type: 'currency', cellAttributes: { alignment: 'left' } },
        {
            type: 'button-icon',
            width: 50,
            typeAttributes: {
                iconName: 'utility:preview',
                name: 'view_details',
                title: 'Click to view details',
                variant: 'border-filled',
                alternativeText: 'View Specs'
            } }
    ];

    @wire(getPicklistValues, {
        recordTypeId: '012000000000000AAA',
        fieldApiName: ORIGIN_FIELD
    })
    wiredCountryValues(result) {
        if (result.data) {
            const options = [{ label: 'All Countries', value: 'All' }];
            for (let i = 0; i < result.data.values.length; i++) {
                options.push({ label: result.data.values[i].label, value: result.data.values[i].value });
            }
            this.countryOptions = options;}}

    @wire(getB2CProductsPaged, {
        pageNumber: '$currentPage',
        pageSize: '$pageSize',
        category: '$selectedCategory',
        country: '$selectedCountry'
    })
    wiredProducts(result) {
        if (!result.data) {
            return;
        }

        const records = result.data;
        this.hasNextPage = records.length > this.pageSize;
        const productList = [];

        for (let i = 0; i < records.length; i++) {
            if (i >= this.pageSize) {
                break;
            }
            const pbe = records[i];
            const product = pbe.Product2;

           let recType;
            if (product.RecordType) {recType = product.RecordType.DeveloperName;} 
            else {recType = '';}

            productList.push({
                pbeId: pbe.Id,
                name: product.Name,
                code: product.ProductCode,
                recordType: recType,
                origin: product.Country_of_Origin__c,
                price: pbe.UnitPrice,
                lifeExpectancy: product.Average_Life_Expectancy__c,
                imageUrl: product.Image_URL__c,
                isGenerator: recType === 'Generators',
                size: product.Size__c,
                weight: product.Weight_kg__c,
                phase: product.Phase__c,
                powerKVA: product.Power_Generated_KVA__c,
                engineType: product.Engine_Type__c,
                description: product.Description
            });
        }
        this.products = productList;
        this.selectedRowIds = this.copyArray(this.selectedRowIds);
    }
    handleFilterChange(event) {
        if (event.target.name === 'category') {
            this.selectedCategory = event.target.value;
        }
        if (event.target.name === 'country') {
            this.selectedCountry = event.target.value;}

        this.currentPage = 1;}
    handleRowSelection(event) {
        const checkedRowsOnThisPage = event.detail.selectedRows;

        const idsOnThisPage = [];
        for (let i = 0; i < this.products.length; i++) {
            idsOnThisPage.push(this.products[i].pbeId);
        }

        const otherPageSelections = [];
        for (let i = 0; i < this.selectedRowIds.length; i++) {
            const id = this.selectedRowIds[i];
            if (!this.isIdInList(id, idsOnThisPage)) {
                otherPageSelections.push(id);
            }
        }

        const newSelections = otherPageSelections;
        for (let i = 0; i < checkedRowsOnThisPage.length; i++) {
            newSelections.push(checkedRowsOnThisPage[i].pbeId);
        }

        this.selectedRowIds = newSelections;
    }
    handleRowAction(event) {
        const actionName = event.detail.action.name;
        const row = event.detail.row;

        if (actionName === 'view_details') {
            for (let i = 0; i < this.products.length; i++) {
                if (this.products[i].pbeId === row.pbeId) {
                    this.selectedProduct = this.products[i];
                    break;
                }
            }
        }
    }
    handleSave() {
        createWonOpportunity({ accountId: this.recordId, pbeIds: this.selectedRowIds })
            .then((newOppId) => {
                this.selectedRowIds = [];
                this.selectedProduct = null;

                this[NavigationMixin.Navigate]({
                    type: 'standard__recordPage',
                    attributes: {
                        recordId: newOppId,
                        objectApiName: 'Opportunity',
                        actionName: 'view'
                    }
                });
            })
            .catch((error) => {
                this.showToast('Error', error.body.message, 'error');
            });
    }

    previousPage() {
        if (this.currentPage > 1) {
            this.currentPage = this.currentPage - 1;}
    }

    nextPage() {
        if (this.hasNextPage) {
            this.currentPage = this.currentPage + 1;}
    }

    isIdInList(id, listOfIds) {
        for (let i = 0; i < listOfIds.length; i++) {
            if (listOfIds[i] === id) {
                return true;
            }
        }
        return false; }

    copyArray(originalArray) {
        const newArray = [];
        for (let i = 0; i < originalArray.length; i++) {
            newArray.push(originalArray[i]);
        }
        return newArray;}

    showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));}

    get isSaveDisabled() {return this.selectedRowIds.length === 0;}
    get isPrevDisabled() {return this.currentPage <= 1;}
    get isNextDisabled() {return !this.hasNextPage;}
}