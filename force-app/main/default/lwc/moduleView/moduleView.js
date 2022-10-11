import { LightningElement, api } from 'lwc';

export default class ModuleView extends LightningElement {
    @api recordId;
    @api 
    module
    @api 
    thisUnits

    @api
    get unitsFromModule(){
        return
    }

    set unitsFromModule(value){
        this.thisUnits.includes(value)
    }
    
    handleClick(){
        console.log('MODULE');
        console.log(JSON.parse(JSON.stringify(this.module)));
        console.log('UNITS');
        console.log(JSON.parse(JSON.stringify(this.thisUnits)));
        console.log('FILTERED UNITS');
        console.log(variableX)
    }
}