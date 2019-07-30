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
    mapping(address => bool) private airlines;                          // True = Registered , False = not Registered
    mapping(address => uint) private airlineFunds;
    mapping(bytes32 => address[]) private flightInsurees;
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
        airlines[firstAirline] = true;
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

    modifier requireIsContractAuthorized() {
        require(authorizedContracts[msg.sender] == true, "Contract not authorized to call this contract");
        _;
    }

    modifier requireIsAirlineRegistered(address airline) {
        require(isAirlineRegistered(airline), "Airline not registered");
        _;
    }

    modifier requireIsValidAddress(address addr) {
        require(addr != address(0), "Address is not valid");
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
        return airlines[airline];
    }

    function authorizeContract(address contractAddress) external requireContractOwner{
        authorizedContracts[contractAddress] = true;
    }

    function deAuthorizeContract(address contractAddress) external requireContractOwner{
        delete authorizedContracts[contractAddress];
    }

    function isPassengerInsuredForFlight(
                                    address airline,
                                    string calldata flight,
                                    uint256 timestamp,
                                    address passenger
                                ) external view returns(bool)
    {
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
    function registerAirline(address airline) external
    requireIsContractAuthorized()
    requireIsOperational()
    requireIsValidAddress(airline)
    returns (bool)
    {
        require(!isAirlineRegistered(airline), "Airline is already registered");
        airlines[airline] = true;
        return true;


        // if (totalAirlines <= 4) {
        //     airlines[airline] = true;
        // }
        // else { // Need 50% consensys
        //     for(uint i = 0; i < votes.length; i++) {
        //         if(votes[i] == msg.sender) {
        //             require(true, "Duplicate vote");
        //         }
        //     }
        //     if(votes.length >= SafeMath.div(totalAirlines, 2)) {
        //         airlines[airline] = true;
        //         delete votes;
        //      } else {
        //         votes.push(msg.sender);
        //     }
        // }
    }


   /**
    * @dev Buy insurance for a flight
    *
    */
    function buy(
        address airline,
        string calldata flight,
        uint256 timestamp,
        address passenger,
        uint amount) external payable
        requireIsContractAuthorized()
        requireIsOperational()
        requireIsValidAddress(airline)
        requireIsAirlineRegistered(airline)
    {
        bytes32 flightKey = getFlightKey(airline, flight, timestamp);
        flightInsurees[flightKey].push(passenger);
        PassengersInsurances[flightKey][passenger] = amount;
    }

    /**
     *  @dev Credits payouts to insurees
    */
    function creditInsurees(
        address airline,
        string calldata flight,
        uint256 timestamp,
        uint multipler) external
    {
        bytes32 flightKey = getFlightKey(airline, flight, timestamp);
        address[] storage insurees = flightInsurees[flightKey];
        for(uint8 i = 0; i < insurees.length; i++) {
            address passenger = insurees[i];
            uint insureePaidAmount = PassengersInsurances[flightKey][passenger];
            uint256 amountToBePaid = insureePaidAmount.mul(multipler).div(100);
            PassengersInsurances[flightKey][passenger] = 0;
            passengersBalance[passenger] = passengersBalance[passenger] + amountToBePaid;
        }
    }


    /**
     *  @dev Transfers eligible payout funds to insuree
     *
    */
    function pay(address payable passenger, uint amount) external
        requireIsContractAuthorized()
        requireIsOperational()
        requireIsValidAddress(passenger)
    {
        passengersBalance[passenger] = passengersBalance[passenger] - amount;
        passenger.transfer(amount);
    }

   /**
    * @dev Initial funding for the insurance. Unless there are too many delayed flights
    *      resulting in insurance payouts, the contract should be self-sustaining
    *
    */
    function fund(address airline, uint amount) external
    requireIsContractAuthorized()
    requireIsOperational()
    requireIsValidAddress(airline)
    requireIsAirlineRegistered(airline)
    {
        airlineFunds[airline] = airlineFunds[airline] + amount;
    }

    function getFlightKey
                        (
                            address airline,
                            string memory flight,
                            uint256 timestamp
                        )
                        internal
                        pure
                        returns(bytes32)
    {
        return keccak256(abi.encodePacked(airline, flight, timestamp));
    }

    // GETS


    function getFunds(address airline) external
    requireIsContractAuthorized()
    requireIsOperational()
    requireIsAirlineRegistered(airline)
    view
    returns(uint)
    {
        return airlineFunds[airline];
    }

    function getFlightInsurees(bytes32 flight) external
    requireIsContractAuthorized()
    requireIsOperational()
    view
    returns(address[] memory)
    {
        return flightInsurees[flight];
    }

    function getPassengersBalance(address passenger) external
    requireIsContractAuthorized()
    requireIsOperational()
    view
    returns(uint)
    {
        return passengersBalance[passenger];
    }



    /**
    * @dev Fallback function for funding smart contract.
    *
    */
    function() external payable
    {
        //fund();
    }


}

