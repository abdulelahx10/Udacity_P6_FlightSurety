import FlightSuretyApp from '../../build/contracts/FlightSuretyApp.json';
import Config from './config.json';
import Web3 from 'web3';

export default class Contract {
    constructor(network, callback) {

        let config = Config[network];
        this.web3 = new Web3(new Web3.providers.HttpProvider(config.url));
        this.flightSuretyApp = new this.web3.eth.Contract(FlightSuretyApp.abi, config.appAddress);
        this.initialize(callback);
        this.owner = null;
        this.airlines = [];
        this.passengers = [];
    }

    initialize(callback) {
        this.web3.eth.getAccounts((error, accts) => {
           
            this.owner = accts[0];

            let counter = 1;
            
            while(this.airlines.length < 5) {
                this.airlines.push(accts[counter++]);
            }

            while(this.passengers.length < 5) {
                this.passengers.push(accts[counter++]);
            }

            callback();
        });
    }

    isOperational(callback) {
       let self = this;
       self.flightSuretyApp.methods
            .isOperational()
            .call({ from: self.owner}, callback);
    }

    fetchFlightStatus(flight, callback) {
        let self = this;
        let payload = {
            airline: self.airlines[0],
            flight: flight,
            timestamp: Math.floor(Date.now() / 1000)
        } 
        self.flightSuretyApp.methods
            .fetchFlightStatus(payload.airline, payload.flight, payload.timestamp)
            .send({ from: self.owner}, (error, result) => {
                callback(error, payload);
            });
    }

    registerAirline(registeredAirline, airlineToBeRegistered, callback) {
        let self = this
    
        self.flightSuretyApp.methods
          .registerAirline(airlineToBeRegistered.toString())
          .send(
            { from: registeredAirline.toString(), gas: 1000000 },
            (error, result) => {
              callback(error, result)
            }
          )
      }
    
      sendFunds(airline, funds, callback) {
        let self = this
        const fundAmount = self.web3.utils.toWei(funds, 'ether')
    
        self.flightSuretyApp.methods.fund()
          .send(
            { from: airline.toString(), value: fundAmount },
            (error, result) => {
              callback(error, result)
            }
          )
      }
    
      purchaseInsurance(airline, flight, passenger, funds_ether, timestamp, callback) {
        let self = this
        const fundAmount = self.web3.utils.toWei(funds_ether, 'ether')
    
        self.flightSuretyApp.methods
          .registerFlight(airline.toString(), flight.toString(), timestamp)
          .send(
            { from: passenger.toString(), value: fundAmount, gas: 1000000 },
            (error, result) => {
              callback(error, result)
            }
          )
      }
      
      getPassengerBalance (passenger, callback) {
        let self = this

        self.flightSuretyApp.methods
          .getPassengerBalance()
          .call({ from: passenger }, (error, result) => {
            callback(error, result)
          })
      }

      withdrawFunds (passenger, funds, callback) {
        let self = this
    
        const amount = self.web3.utils.toWei(funds, 'ether')
        self.flightSuretyApp.methods
          .withdrawFunds(amount)
          .send({ from: passenger.toString() }, (error, result) => {
            callback(error, result)
          })
      }
    }