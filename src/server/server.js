import FlightSuretyApp from '../../build/contracts/FlightSuretyApp.json';
import FlightSuretyData from '../../build/contracts/FlightSuretyData.json';
import Config from './config.json';
import Web3 from 'web3';
import express from 'express';

const STATUS_CODE_UNKNOWN = 0
const STATUS_CODE_ON_TIME = 10
const STATUS_CODE_LATE_AIRLINE = 20
const STATUS_CODE_LATE_WEATHER = 30
const STATUS_CODE_LATE_TECHNICAL = 40
const STATUS_CODE_LATE_OTHER = 50

const TOTAL_ORACLES = 20
let oracles = {}

let config = Config['localhost'];
let web3 = new Web3(new Web3.providers.WebsocketProvider(config.url.replace('http', 'ws')));
web3.eth.defaultAccount = web3.eth.accounts[0];
let flightSuretyApp = new web3.eth.Contract(FlightSuretyApp.abi, config.appAddress);
let flightSuretyData = new web3.eth.Contract(FlightSuretyData.abi,config.dataAddress);

web3.eth.getAccounts().then(accounts => {
  flightSuretyData.methods.authorizeContract(config.appAddress).send({ from: accounts[0] })
    .then(result => {
      console.log('App contract authorized of data contract');
    })
    .catch(error => {
      console.log('Error in authorizing: ' + error);
    })
  flightSuretyApp.methods.REGISTRATION_FEE().call()
    .then(fee => {
      for (let a = 1; a < TOTAL_ORACLES; a++) {
        flightSuretyApp.methods.registerOracle().send({ from: accounts[a], value: fee, gas: 4000000 })
          .then(result => {
            flightSuretyApp.methods.getMyIndexes().call({ from: accounts[a] })
              .then(indices => {
                oracles[accounts[a]] = indices;
                console.log('Oracle registered: ' + accounts[a] + ' indices:' + indices);
              })
          })
          .catch(error => {
            console.log('Error while registering oracles: ' + accounts[a] + ' Error: ' + error);
          });
      }
    });
});

flightSuretyApp.events.FlightStatusInfo({
    fromBlock: 0
  }, function (error, event) {
    if (error) console.log(error)
    else {
      console.log('Received flightstatusInfo event:  ' + JSON.stringify(event))
    }
  }
)

flightSuretyApp.events.OracleRequest({
    fromBlock: 0
  }, function (error, event) {
    if (error) console.log(error)
    else{
      console.log(event)
      const index = event.returnValues.index
      const airline = event.returnValues.airline
      const flight = event.returnValues.flight
      const timestamp = event.returnValues.timestamp
      for (var key in oracles) {
        var indexes = oracles[key]
        if (indexes.includes(index)) {
          flightSuretyApp.methods
            .submitOracleResponse(
              index,
              airline,
              flight,
              timestamp,
              STATUS_CODE_LATE_AIRLINE // always late for testing
            )
            .send({ from: key, gas: 1000000 })
            .then(result => {
              console.log('Oracle response sent with statuscode: ' + STATUS_CODE_LATE_AIRLINE + ' for ' + flight + ' and index:' + index);
            })
            .catch(error => {
              console.log('Error while sending Oracle response  for ' + flight + ' Error:' + error);
            })
        }
      }
    }
});

const app = express();
app.get('/api', (req, res) => {
    res.send({
      message: 'An API for use with your Dapp!'
    })
})

export default app;


