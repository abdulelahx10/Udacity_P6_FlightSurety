import DOM from './dom';
import Contract from './contract';
import './flightsurety.css';


(async () => {

    let result = null;

    let contract = new Contract('localhost', () => {

        // Read transaction
        contract.isOperational((error, result) => {
            console.log(error, result);
            display('Operational Status', 'Check if contract is operational', [{
                label: 'Operational Status',
                error: error,
                value: result
            }]);
        });
        
        DOM.elid('registerAirline').addEventListener('click', () => {
            let airlineToBeRegistered = DOM.elid('registerAirlineAddress').value;
            let registeredAirline = DOM.elid('registeredAirline').value;
            contract.registerAirline(registeredAirline, airlineToBeRegistered, (error, result) => {
                if (error) {
                    alert(error);
                }
                DOM.elid('registerAirlineAddress').value = "";
                DOM.elid('registeredAirline').value = "";
                
                display('', 'Register submitted', [{
                    label: 'Register submitted',
                    error: error,
                    value: `Airline Address:  ${airlineToBeRegistered}, Requester Address: ${registeredAirline}`
                }], "register");
            });
        });
        
        DOM.elid('submitFunds').addEventListener('click', () => {
            let submitAirlineAddress = DOM.elid('fundsAirlineAddress').value;
            let fundsValue = DOM.elid('fundsValue').value;
            contract.sendFunds(submitAirlineAddress, fundsValue, (error, result) => {
                if (error) {
                    alert(error);
                }
                DOM.elid('fundsAirlineAddress').value = "";
                DOM.elid('fundsValue').value = "";
                
                display('', 'Submitted Funds', [{
                    label: 'Submitted Funds',
                    error: error,
                    value: `Airline Address:  ${submitAirlineAddress}, Funds Value: ${fundsValue}`
                }], "funds");
            });
        });
        
        DOM.elid('buyInsurance').addEventListener('click', () => {
            let passengerAddress = DOM.elid('passengerAddress').value;
            let insuranceAirlineAddress = DOM.elid('insuranceAirlineAddress').value;
            let selectedFlight = document.getElementById("selectFlight").options[document.getElementById("selectFlight").selectedIndex].value;
            let insuranceValue = DOM.elid('insuranceValue').value;
            if (selectedFlight === "0") {
                alert("Please select a flight");
            } else {
                selectedFlight = JSON.parse(selectedFlight);
                contract.buyInsurance(insuranceAirlineAddress, selectedFlight.flight, selectedFlight.timestamp, passengerAddress, insuranceValue, (error, result) => {
                    if (error) {
                        alert(error);
                    }
                    DOM.elid('insuranceAirlineAddress').value = "";
                    DOM.elid('passengerAddress').value = "";
                    DOM.elid('insuranceValue').value = "";
                    display('', 'Insurance purchased', [{
                        label: 'Insurance Purchased',
                        error: error,
                        value: `Insuree:  ${passengerAddress}, value: ${insuranceValue} ETH, flight: ${selectedFlight.flight}, airline: ${insuranceAirlineAddress}, timestamp:  ${selectedFlight.timestamp}`
                    }], "insurance");
                    
                });
            }
        });
         
        DOM.elid('withdrawFunds').addEventListener('click', () => {
            let insureeAddreess = DOM.elid('insureeAddreess').value;
            let value = DOM.elid('value').value;
            
            contract.withdrawFunds(insureeAddreess, value, (error, result) => {
                if (error) {
                    alert(error);
                }
                DOM.elid('insureeAddreess').value = "";
                DOM.elid('value').value = "";
                display('', 'Credits Refunded', [{
                    label: 'Credits Refunded',
                    error: error,
                    value: `Passenger:  ${insureeAddreess}`
                }], "credits");
            });
            
        });

        // User-submitted transaction
        DOM.elid('submit-oracle').addEventListener('click', () => {
            let flight = DOM.elid('flight-number').value;
            // Write transaction
            contract.fetchFlightStatus(flight, (error, result) => {
                display('Oracles', 'Trigger oracles', [{
                    label: 'Fetch Flight Status',
                    error: error,
                    value: result.flight + ' ' + result.timestamp
                }]);
            });
        })
        
    });

})();


function display(title, description, results) {
    let displayDiv = DOM.elid("display-wrapper");
    let section = DOM.section();
    section.appendChild(DOM.h2(title));
    section.appendChild(DOM.h5(description));
    results.map((result) => {
        let row = section.appendChild(DOM.div({
            className: 'row'
        }));
        row.appendChild(DOM.div({
            className: 'col-sm-4 field'
        }, result.label));
        row.appendChild(DOM.div({
            className: 'col-sm-8 field-value'
        }, result.error ? String(result.error) : String(result.value)));
        section.appendChild(row);
    })
    displayDiv.append(section);

}