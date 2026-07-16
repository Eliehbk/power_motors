import { LightningElement, api, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { getPicklistValues } from 'lightning/uiObjectInfoApi';
import ORIGIN_FIELD from '@salesforce/schema/Product2.Country_of_Origin__c';
import getB2CProducts from '@salesforce/apex/B2CProductController.getPriceBookItem';
import createWonOpportunity from '@salesforce/apex/B2CProductController.createWonOpportunity';
export default class B2cProductCatalog extends LightningElement {
    @api recordId;

    products = [];
    filteredProducts = [];
    selectedProduct = null;
    selectedRowIds = [];

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
        {  type: 'button-icon',
            width: 50, 
            typeAttributes: {
                iconName: 'utility:preview',
                name: 'view_details',
                title: 'Click to view details',
                variant: 'border-filled',
                alternativeText: 'View Specs'
            }
        }
    ];

    @wire(getPicklistValues, {
        recordTypeId: '012000000000000AAA',
        fieldApiName: ORIGIN_FIELD
    })
    wiredCountryValues(result) {
        if (result.data) {
            const options = [{ label: 'All Countries', value: 'All' }];
            for (let i = 0; i < result.data.values.length; i++) {
                const item = result.data.values[i];
                options.push({ label: item.label, value: item.value });
            }
            this.countryOptions = options;
        } else if (result.error) {
            this.error = result.error;
        }
    }

    @wire(getB2CProducts)
    wiredProducts(result) {
        if (result.data) {
            const list = [];

            for (let i = 0; i < result.data.length; i++) {
                const pbe = result.data[i];
                const product = pbe.Product2;
                const recType = product.RecordType ? product.RecordType.DeveloperName : '';

                list.push({
                    pbeId: pbe.Id,
                    name: product.Name,
                    code: product.ProductCode,
                    recordType: recType,
                    origin: product.Country_of_Origin__c,
                    price: pbe.UnitPrice,
                    lifeExpectancy: product.Average_Life_Expectancy__c,
                    imageUrl: product.Image_URL__c ,
                    isGenerator: recType === 'Generators',
                    size: product.Size__c,
                    weight: product.Weight_kg__c,
                    phase: product.Phase__c,
                    powerKVA: product.Power_Generated_KVA__c,
                    engineType: product.Engine_Type__c,
                    description: product.Description,
                    isSelected: false
                });
            }

            this.products = list;
            this.applyFilters();
        } else if (result.error) {
            this.error = result.error;
        }
    }

    handleFilterChange(event) {
        if (event.target.name === 'category') {
            this.selectedCategory = event.target.value;
        }
        if (event.target.name === 'country') {
            this.selectedCountry = event.target.value;
        }
        this.applyFilters();
    }

    applyFilters() {
        const result = [];

        for (let i = 0; i < this.products.length; i++) {
            const item = this.products[i];
            const categoryMatches = this.selectedCategory === 'All' || item.recordType === this.selectedCategory;
            const countryMatches = this.selectedCountry === 'All' || item.origin === this.selectedCountry;

            if (categoryMatches && countryMatches) {
                result.push(item);
            }
        }

        this.filteredProducts = result;
    }

    handleRowSelection(event) {
        const selectedRows = event.detail.selectedRows;
        const ids = [];

        for (let i = 0; i < selectedRows.length; i++) {
            ids.push(selectedRows[i].pbeId);
        }
        this.selectedRowIds = ids;

        for (let i = 0; i < this.products.length; i++) {
            const item = this.products[i];
            item.isSelected = this.selectedRowIds.includes(item.pbeId);
        }
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
    get isSaveDisabled() {
        return this.selectedRowIds.length === 0;
    }

     handleSave() {
        createWonOpportunity({ accountId: this.recordId, pbeIds: this.selectedRowIds })
            .then(() => {

                for (let i = 0; i < this.products.length; i++) {
                    this.products[i].isSelected = false;
                }
                this.selectedRowIds = [];
                this.selectedProduct = null;
                this.applyFilters();
            })
    }

    showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }
}