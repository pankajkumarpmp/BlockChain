
// SPDX-License-Identifier: Pankaj   //License Declaration

pragma solidity ^0.8.7;  //This program uses Solidity version 0.8.7 and has been created and tested using Remix IDE 
                        //on Windows 10 and using Ganache v2.5.4  All Error and successful messages can be seen in Remix Console

contract KYC {      //Contract code begins here
    
    address admin;   // variable to store the address of the Ledger admin 

    //Bank Struct Declaration
    struct Bank {
        string BankName;        //Variable to store Bank Name
        address EthAddress;     //Variable to store Bank ETH Address
        bool isBlocked;         //If Bank is blocked to add new Customers, isBlocked is true, else false      
        bool isKycAllowed;      //If Bank is blocked to do KYC,  isKycAllowed is false, else true    
    }    

    //Customer struct Declaration
    struct Customer {
        string  CustName;       //Name of Customer
        address BankAddress;    //ETH address of the Bank
        string CustData;        //Variable to address Customer's address, phone etc
        bool KYCFlag;           //If KYC is done for this Customer then True, else False 
    }
    

    Customer[] allCustomers;     //  List of all Customers
   
    
    Bank[] public allBanks;     //  List of all Banks
    
    //mapping (address => Bank) public allBanks; // without loop with index ...if single key
    //mapping (address => Bank) public allCustomers; // without loop with index ...if single key
   // mapping(address => mapping(uint256=>Customer)) public allCustomers; // without loop with composite key index ...if composite key
    
    constructor() { admin = payable(msg.sender); } // ETH address of the adin is initialized in constructor

    // This contract defines a function modifier it will be used in derived contracts to indicate that it must be called by an admin.
    // The onlyAdmin function body is inserted where the special symbol `_;` in the definition of a modifier appears.
    // This means that if the admin calls that onlyAdmin function, the function is executed, otherwise, an exception is thrown.
    
    modifier onlyAdmin {
        require(
            msg.sender == admin,
            "Only admin can call this function."
        );
        _;
    }
    
    //Function to compare two strings. If equal, it returns true, else false
    function stringsEquals (string memory a, string memory b) public pure returns (bool) {
        return (keccak256(abi.encodePacked((a))) == keccak256(abi.encodePacked((b))));
    }
    
    //Function(a derived contract) to add a new Bank to the list of all Banks in the Ledger Contract.
    //This function uses modifier onlyAdmin to restrict a call by admin only, else an exception will be thrown
    function addNewBank(string memory _bankname, address _bankaddress) public onlyAdmin payable returns(string memory) {
        require (admin == msg.sender, "Must be the admin of this Bank");        //Requires call from an admin only
        require(bytes(_bankname).length != 0, "The bank name must be set");     //Requires that the input Bank Name is not empty
        require(_bankaddress != address(0), "The Bank Address must be set");    //Requires that the input Bank Address is not empty
        
        allBanks.push(Bank(_bankname, _bankaddress, false, true));              //Initialise Flags upon adding a Bank to the Blockchain Ledger
        return "Bank has been added";                                           //Retrurns a message after successful addition      
    }

    // Derived contract to view Bank details, created by addNewBank function
    function viewBank(address _ethaddress) public payable returns(string memory BankName, bool isBlocked, bool isKycAllowed) {
        require(_ethaddress != address(0), "The Bank Address must be set");     //Requires that the input ETh address is not empty           
        for(uint i = 0; i < allBanks.length; ++ i) {                            //Loop through array of Bank struct 
            if ( allBanks[i].EthAddress == _ethaddress) {                       //find the input address exists         
                return (allBanks[i].BankName, allBanks[i].isBlocked, allBanks[i].isKycAllowed) ;    //Returns Bank details
            }
         }    
    }
    
    //Function to add new Customer to the list of all Customers
    // If isBlocked is true then don't process the request. 
    // @param _custname - customer name as the string
    // @param _custdata - customer data such as the address and mobile number    
    // @return value “1” to determine the status of success
    // @return value “0” for the failure of the function.    
    function addNewCustomer(string memory _custname, string memory _custdata) public payable returns (string memory ) {
        require(bytes(_custname).length != 0, "The Customer name must be set"); //Input Customer Name cannot be empty
      //  throw error if username already in use
        for(uint i = 0;i < allCustomers.length; ++ i) {                         //Loop through aray of Customer struct              
            if (stringsEquals(allCustomers[i].CustName, _custname)) {           //If input customer already exists then returns an error 
                return "Customer already exists";                               // Failure of the function as user already exists
            }
        }
        
        // If ETH address of the Bank is legitimate, and also Bank is Blocked (isBlocked == True) then dont process the request.
        for (uint i = 0; i < allBanks.length; ++i) {
            if (allBanks[i].EthAddress == msg.sender && allBanks[i].isBlocked) {
                return "This Bank is currently Blocked from addinng new Customers";
            }
        }
        // set Customer Name = Input Name, BankAddress = admin, Customer Data = Input Data and KycFlag = False, this will be set to true after KYC
       // allCustomers[allCustomers.length -1 ] = Customer(_custname, msg.sender, _custdata, false);
        allCustomers.push(Customer(_custname, msg.sender, _custdata, false));
        return "The customer has been added";
    }
    
    //Function to return KYC status of a Customer of the Bank
    function Check_KYC(string memory _custname) public payable returns(string memory) {
        require(bytes(_custname).length != 0, "The Customer name must be set");         //Inout Customer Name cannot be empty   
        bool cust_exists = false;
        for (uint i = 0; i < allCustomers.length; ++ i) {                               //Loop through aray of Customer struct   
            if (stringsEquals(allCustomers[i].CustName, _custname) && allCustomers[i].BankAddress == msg.sender ) {
               cust_exists = true;
            }
        } 
        if (!cust_exists) {
            return "Customer does not exist";                                           //Returns error, if Customer does not exist
        }
        bool kyc = false;
        for(uint i = 0; i < allCustomers.length; ++i) {                                  //Loop through aray of Customer struct 
            if (stringsEquals(allCustomers[i].CustName, _custname) && allCustomers[i].BankAddress == msg.sender ) {
                if (allCustomers[i].KYCFlag) {
                    kyc = true;                                                         //If KYC flag is true
                }        
            }
        }
        if  (kyc) {
            return "KYC has already been done for this Customer";                       //Returns error
        }
        else {
            return "KYC has not been done for this Customer";                           //Returns a successful message
        }
    }
    
    
    //Function to update KYC Status of a Customer of the Bank after performing KYC
    function Perform_KYC(string memory _custname) public payable returns (string memory) {
        require(bytes(_custname).length != 0, "The Customer name must be set");        
        bool cust_exists = false;
        
        for (uint i = 0; i < allCustomers.length; ++ i) {
            if (stringsEquals(allCustomers[i].CustName, _custname) && allCustomers[i].BankAddress == msg.sender ) {
               cust_exists = true;
            }
        } 
        if (cust_exists == false) {
            return "Customer does not exist";
        }
        // If Bank is Blocked (isBlocked == True) then dont process the request.
        for(uint i = 0; i < allBanks.length; ++i) {
            if ( allBanks[i].EthAddress == msg.sender && allBanks[i].isBlocked) {
                return "This Bank is currently Blocked from performing KYC of the Customers";
            }
        }        
        for (uint i = 0; i < allCustomers.length; ++ i) {
            if (stringsEquals(allCustomers[i].CustName, _custname) && allCustomers[i].BankAddress == msg.sender ) {
               allCustomers[i].KYCFlag  = true;
               return "KYC Status has been updated to true";
            }
        }
        return "KYC Status update failed";
     }
    
    //Function to Block a Bank to Add a Customer to the Ledger
    function Block_Bank_for_Cust(address _bankaddress ) public payable returns (string memory) {
        require(_bankaddress != address(0), "The Bank Address must be set");                
        for(uint i = 0; i < allBanks.length; ++i) {
            // If Bank is Blocked (isBlocked == True) then dont process the request.
            require(allBanks[i].EthAddress == msg.sender && allBanks[i].isBlocked, "This Bank is already Blocked"); 
        }
        for (uint i = 0; i < allBanks.length; ++ i) {
            if (allBanks[i].EthAddress == _bankaddress ) {
               allBanks[i].isBlocked  = true;
            }
        }
        return "This Bank has been Blocked from adding New Customers";
    }
        
    //Function to Block a Bank to do KYC of a Customer
    function Block_Bank_for_kyc(address _bankaddress ) public payable returns (string memory) {
        require(_bankaddress != address(0), "The Bank Address must be set");   
        allBanks[_bankaddress].isKycAllowed  = false;
        for(uint i = 0; i < allBanks.length; ++i) {
            // If Bank is Blocked (isBlocked == True) then dont process the request.
            require(allBanks[i].EthAddress == msg.sender && !allBanks[i].isKycAllowed, "This Bank is already Blocked from performing New KYC of any Customer"); 
        }
        for (uint i = 0; i < allBanks.length; ++ i) {
            if (allBanks[i].EthAddress == _bankaddress ) {
               allBanks[i].isKycAllowed  = false;
            }
        }
        return "This Bank has been Blocked from performing New KYC of any Customer";
    }   
    
    //Function to Unblock a Bank to Add a Customer to the Ledger
    function UnBlock_Bank_for_Cust(address _bankaddress ) public payable returns (string memory) {
        require(_bankaddress != address(0), "The Bank Address must be set");                
        for(uint i = 0; i < allBanks.length; ++i) {
            // If Bank is Blocked (isBlocked == True) then dont process the request.
            require(allBanks[i].EthAddress == msg.sender && !allBanks[i].isBlocked, "This Bank is already Unblocked"); 
        }
        for (uint i = 0; i < allBanks.length; ++ i) {
            if (allBanks[i].EthAddress == _bankaddress ) {
               allBanks[i].isBlocked  = false;
            }
        }
        return "This Bank has been Unblocked for adding New Customers";
    }    

    //Function to Unblock a Bank to do KYC of a Customer
    function UnBlock_Bank_for_kyc(address _bankaddress ) public payable returns (string memory) {
        require(_bankaddress != address(0), "The Bank Address must be set");                
        for(uint i = 0; i < allBanks.length; ++i) {
            // If Bank is Blocked (isBlocked == True) then dont process the request.
            require(allBanks[i].EthAddress == msg.sender && allBanks[i].isKycAllowed, "This Bank is already Unblocked"); 
        }
        for (uint i = 0; i < allBanks.length; ++ i) {
            if (allBanks[i].EthAddress == _bankaddress ) {
               allBanks[i].isKycAllowed  = true;
            }
        }
        return "This Bank has been Unblocked for performing New KYC of any Customer";
    }   
    
    // Function allows a bank to view details of a customer.
    // @param _custname - customer name as string.
    function viewCustomer(string memory _custname) public payable returns(string memory CustName, address BankAddress, string memory CustData, bool KYCFlag) {
        require(bytes(_custname).length != 0, "The Customer name must be set");        
        for(uint i = 0; i < allCustomers.length; ++ i) {
            if(stringsEquals(allCustomers[i].CustName, _custname)) {
                return (allCustomers[i].CustName, allCustomers[i].BankAddress, allCustomers[i].CustData, allCustomers[i].KYCFlag) ;
            }
        }
    }
}
    
