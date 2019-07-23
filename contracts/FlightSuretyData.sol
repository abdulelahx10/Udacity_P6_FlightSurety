pragma solidity >=0.4.25;

import "../node_modules/openzeppelin-solidity/contracts/math/SafeMath.sol";

contract FlightSuretyData {
    using SafeMath for uint256;

    /********************************************************************************************/
    /*                                       DATA VARIABLES                                     */
    /********************************************************************************************/

    address private contractOwner;                                      // Account used to deploy contract
    bool private operational = true;                                    // Blocks all state changes throughout the contract if false
    mapping(address => bool) private authorizedContracts;
    mapping(address => bool) private registeredAirlines;
    uint8 private totalAirlines = 0;
    address[] private votes;
    mapping(address => uint) private airlineFunds;
    mapping(bytes32 => mapping(address => uint)) private PassengersInsurances;
    mapping(address => uint) private passengersBalance;

    /********************************************************************************************/
    /*                                       EVENT DEFINITIONS                                  */
    /********************************************************************************************/


    /**
    * @dev Constructor
    *      The deploying account becomes contractOwner
    */
    constructor(address firstAirline) public{
        contractOwner = msg.sender;
        registerAirline(firstAirline);
    }

    /********************************************************************************************/
    /*                                       FUNCTION MODIFIERS                                 */
    /********************************************************************************************/

    // Modifiers help avoid duplication of code. They are typically used to validate something
    // before a function is allowed to be executed.

    /**
    * @dev Modifier that requires the "operational" boolean variable to be "true"
    *      This is used on all state changing functions to pause the contract in
    *      the event there is an issue that needs to be fixed
    */
    modifier requireIsOperational()
    {
        require(operational, "Contract is currently not operational");
        _;  // All modifiers require an "_" which indicates where the function body will be added
    }

    /**
    * @dev Modifier that requires the "ContractOwner" account to be the function caller
    */
    modifier requireContractOwner()
    {
        require(msg.sender == contractOwner, "Caller is not contract owner");
        _;
    }

    /**
    * @dev Modifier that requires the caller contract to be authorized
    */
    modifier requireIsContractAuthorized() {
        require(authorizedCallerContracts[msg.sender] == true, "Contract not authorized to call this contract");
        _;
    }

     /**
    * @dev Modifier that requires the airline to be registered
    */
    modifier requireIsAirlineRegistered(address airline) {
        require(isAirlineRegistered(airline), "Airline not registered");
        _;
    }

    /********************************************************************************************/
    /*                                       UTILITY FUNCTIONS                                  */
    /********************************************************************************************/

    /**
    * @dev Get operating status of contract
    *
    * @return A bool that is the current operating status
    */
    function isOperational() public view returns(bool){
        return operational;
    }

    /**
    * @dev Sets contract operations on/off
    *
    * When operational mode is disabled, all write transactions except for this one will fail
    */
    function setOperatingStatus(bool mode) external requireContractOwner{
        operational = mode;
    }

    function isAirlineRegistered(address airline) public view returns(bool){
        return registeredAirlines[airline];
    }

    function authorizeContract(address contractAddress) external requireContractOwner{
        authorizedContracts[contractAddress] = true;
    }

    function deAuthorizeContract(address contractAddress) external requireContractOwner{
        delete authorizedContracts[contractAddress];
    }

    function isPassengerInsuredForFlight(
                                    address airline,
                                    string flight,
                                    uint256 timestamp,
                                    address passenger
                                )
                                external view returns(bool){
        bytes32 flightKey = getFlightKey(airline, flight, timestamp);
        return PassengersInsurances[flightKey][passenger] > 0;
    }

    /********************************************************************************************/
    /*                                     SMART CONTRACT FUNCTIONS                             */
    /********************************************************************************************/

   /**
    * @dev Add an airline to the registration queue
    *      Can only be called from FlightSuretyApp contract
    *
    */
    function registerAirline(address airline) external pure requireIsAirlineRegistered(msg.sender){
        require(!isAirlineRegistered(airline), "Airline is already registered");
        if (airlineCount <= 4) {
            registeredAirlines[airline] = true;
        }
        else { // Need 50% consensys
            for(uint i = 0; i < votes.length; i++) {
                if(approvalVotes[i] == msg.sender) {
                    require(true, "Duplicate vote");
                }
            }
            if(votes.length >= SafeMath.div(totalAirlines, 2)) {
                registeredAirlines[airline] = true;
                delete approvalVotes;
             } else {
                votes.push(msg.sender);
            }
        }
    }


   /**
    * @dev Buy insurance for a flight
    *
    */
    function buy
                            (
                            )
                            external
                            payable
    {

    }

    /**
     *  @dev Credits payouts to insurees
    */
    function creditInsurees
                                (
                                )
                                external
                                pure
    {
    }


    /**
     *  @dev Transfers eligible payout funds to insuree
     *
    */
    function pay
                            (
                            )
                            external
                            pure
    {
    }

   /**
    * @dev Initial funding for the insurance. Unless there are too many delayed flights
    *      resulting in insurance payouts, the contract should be self-sustaining
    *
    */
    function fund() public payable{
        require(msg.value > 10 ether, "Caller has not sent enough funds to register");
    }

    function getFlightKey
                        (
                            address airline,
                            string memory flight,
                            uint256 timestamp
                        )
                        pure
                        internal
                        returns(bytes32)
    {
        return keccak256(abi.encodePacked(airline, flight, timestamp));
    }

    /**
    * @dev Fallback function for funding smart contract.
    *
    */
    function()
                            external
                            payable
    {
        fund();
    }


}

