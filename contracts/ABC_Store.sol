pragma solidity >0.4.24 <0.6.0;

import "browser/ERC20.sol";
import "browser/SafeMath.sol";

/**
 * @author Shashank Solanki
 *  date: 19-05-2019
**/

/**
 * AdminFunctions contract is responsible for all admin functions and internal functions
 * Admin can Add new token like USDT or ABCT 
 * Admin can topoup USDT to anyone's walletAddressAdmin can load a new Iteam in stores  
 * Admin can check user balance and info any time
 * 
 * Modifiers are in place to check the transaction is coming for admin wallet and only admin can be able to trigger specidic functions
**/
contract AdminFunctions 
{
    
    using SafeMath for uint256;
    address private _owner;
    string[] products;
    address[] users;
    ERC20 internal ERC20InterfaceUSDTether; 
    address  _nullAddr;
    uint256  transactionId=1223132;
    
    mapping (address=>User) _userList;
    mapping (bytes32=>Product) _productList;
    mapping(bytes32=>address)  _tokenMap;
    mapping(uint256=>Transaction)  _transactionMap;
 
    event _newUserRegistration(address walletAddress, uint256 age,string  gender);
    event _loadInventory (string  name,uint256 price, uint256 quantityLeft);
    event _logger (string logger);
    event _loggerInt (uint256 logger);
    
    
    /**
     *Load Inventory on contract deployment time
    */
    constructor() public {
        _owner=msg.sender;
        loadInventory('Skirt',handelPriceUpto2dp(5),100,true,15);
        loadInventory('Beer',handelPriceUpto2dp(3),100,false,0);
        loadInventory('Apple',handelPriceUpto2dp(15),200,false,0);
        loadInventory('Pen',handelPriceUpto2dp(1),500,false,0);
        loadInventory('Shirt',handelPriceUpto2dp(6),50,true,15);
    }
    
    /**
     * Modifier to check if the trigger is from owner /admin
    */
    modifier ownerCheckAdmin{
        require (_owner==msg.sender);
        _;
    }
    
        struct User { // Struct
        address walletAddress;
        uint256 age;
        string  gender;
        uint256 purchaseMadeThisMonthInCents;
        uint256 pointsCollected;
        bool isEliteShoper;
        string[] transactions;
    }
    
      struct Product { // Struct
        string name;
        uint256 price;
        uint256 quantityLeft;
        bool canReturn;
        uint256 daysOfReturn;
    }
    
    struct Transaction { // Struct
        uint256 transactionId;
        string productNam;
        uint256 price;
        uint256 quantity;
        uint256 dateOfPurchase;
    }
    
    /**
     * Only Admin can topup USDT for "Registered user"
     * 
    **/
    
   function adminTopupAccountUSDT(address walletAddredd, uint256 value) public payable ownerCheckAdmin returns (bool success){
        require(_userList[walletAddredd].age!=0);
        bytes32 symbol_ =   stringToBytes32( "USDT");
        address usdtContractAddr = _tokenMap[symbol_];
        ERC20InterfaceUSDTether=ERC20(usdtContractAddr);
        ERC20InterfaceUSDTether.topupAccount(walletAddredd,convertToWei(value),msg.sender);
    }
    
    /**
     * Only Admin can load items on adhoc basis
     * 
    **/
    
    function adminLoadItem(string memory name,uint256 price_in_cents, uint256 quantityLeft,bool canReturn,uint256 daysOfReturn) public ownerCheckAdmin
    {
        
        Product memory _product;
            _product.name=name;
            _product.price=price_in_cents;
            _product.quantityLeft=quantityLeft;
            _product.canReturn=canReturn;
            _product.daysOfReturn=daysOfReturn;
            _productList[stringToBytes32(name)]=_product;
           
            products.push(name);
            emit _loadInventory(_product.name,_product.price,_product.quantityLeft);
    }
    
    /**
     * Admin can load tokens with their contract addresses EX: ABCT and USDT
     * 
    **/
    
    function adminAddNewToken(string memory __symbol, address __cotractAddr) public ownerCheckAdmin returns (bool success) {
        _tokenMap[stringToBytes32( __symbol)]=__cotractAddr;
        return true;
    }
    
    /**
     * To Check USDT balance in wei
     * 
    **/
    function checkUsdtBalance(address __cotractAddr) view public returns (uint256 value)
    {
        bytes32 symbol_ =   stringToBytes32( "USDT");
        address usdtContractAddr = _tokenMap[symbol_];
        ERC20InterfaceUSDTether=ERC20(usdtContractAddr);
        return ((ERC20InterfaceUSDTether.balanceOf(__cotractAddr)));
    }
    
    /**
     * To Check ABCT balance in wei
     * 
    **/
    function checkACBTBalance(address __cotractAddr) view public returns (uint256 value)
    {
        bytes32 symbol_ =   stringToBytes32( "ABCT");
        address usdtContractAddr = _tokenMap[symbol_];
        ERC20InterfaceUSDTether=ERC20(usdtContractAddr);
        return ((ERC20InterfaceUSDTether.balanceOf(__cotractAddr)));
    }
    
    /**
     * We can schedule this via Ethereum Alarm clock or external oracles, or from our DAPP,
     * To check at every month end if any shopper has made transaction of more than 500 USD ,he/she turns to elite member
     * 
    **/
    function checkEliteMembership() internal ownerCheckAdmin
    {
        for(uint i=0;users.length>i;i++){
            if(_userList[users[i]].purchaseMadeThisMonthInCents>=50000)
            {
               _userList[users[i]].isEliteShoper=true; 
            }
        }
    }
    
    
    /**
     * We can schedule this via Ethereum Alarm Clock or external oracles, or from our DAPP (client side)
     * This is to mint and deposit ABC tokens at the month end as same amount of USDT spent
     * 
    **/
    function monthEndABCTMint() internal ownerCheckAdmin
    {
        for(uint i=0;users.length>i;i++){
            
        require(_userList[users[i]].age!=0);
        bytes32 symbol_ =   stringToBytes32( "ABCT");
        address usdtContractAddr = _tokenMap[symbol_];
        ERC20InterfaceUSDTether=ERC20(usdtContractAddr);
        ERC20InterfaceUSDTether.topupAccount(users[i],getBackPriceUpto2dp(convertToWei(_userList[users[i]].purchaseMadeThisMonthInCents)),msg.sender);
        
        }
    }
    
    /**
     * Add entry in Map for every transaction , for record
     * 
    **/
    function addTransaction(uint256 qty,uint256 price,string name) internal  returns(uint256 transactionId)
    {
        Transaction memory _transaction;
        _transaction.transactionId=transactionId.add(1);
        _transaction.productNam=name;
        _transaction.price=price;
        _transaction.quantity=qty;
        _transaction.dateOfPurchase=now;
        
        _transactionMap[ _transaction.transactionId]=_transaction;
        return(_transaction.transactionId);
        
    }
    
     /**
     * Once purchase is succesfull, burn equivalent amoount of tokens from wallets of shopper
     * 
    **/
    function burnTokens(address __fromAddress,uint256 qty) internal returns (bool success)
    {
        bytes32 symbol_ =   stringToBytes32("USDT");
        address usdtContractAddr = _tokenMap[symbol_];
        ERC20InterfaceUSDTether=ERC20(usdtContractAddr);
        (ERC20InterfaceUSDTether.burn(__fromAddress,qty,_owner));
        return true;
    }
    
    /**
     * Check Item details on input of Item name
     * 
    **/
    function showItem(string item) view public returns (uint256 price_in_cents,uint256 qtyLeft,bool canReturn,uint256 daysOfReturn )
    {
        return(_productList[stringToBytes32( item)].price,_productList[stringToBytes32( item)].quantityLeft,_productList[stringToBytes32( item)].canReturn,_productList[stringToBytes32( item)].daysOfReturn);
    }
    
    /**
     * Give 10% discount for elite members
     * 
    **/
    function discount(uint256 price,uint percentage) internal returns(uint256 val)
    {
        return ((price.mul(100-percentage)).div(100));
    }
    
    /**
     * Load inventory on contract deployment time
     * 
    **/
    function loadInventory(string memory name, uint256 price, uint256 quantityLeft,bool canReturn,uint256 daysOfReturn ) internal  ownerCheckAdmin
    {
        Product memory _product;
            _product.name=name;
            _product.price=price;
            _product.quantityLeft=quantityLeft;
            _product.canReturn=canReturn;
            _product.daysOfReturn=daysOfReturn;
            _productList[stringToBytes32(name)]=_product;
            products.push(name);
            emit _loadInventory(_product.name,_product.price,_product.quantityLeft);
    }
    
    function adminGetTokenContractAddress(string memory __symbol) view public returns ( address contractAddr)
    {
         return (_tokenMap[stringToBytes32( __symbol)]);
    }
    
    /**
     * Other internal functions
     * 
    **/
    
    function convertToWei(uint256 val) internal  returns ( uint256 value)
    {
        return(val.mul(1000000000000000000));
    }
    
    function convertToEthToken(uint256 val) internal  returns ( uint256 value)
    {
        return(val.div(1000000000000000000));
    }
    
    function handelPriceUpto2dp(uint256 val) internal  returns ( uint256 value)
    {
        return(val.mul(100));
    }
    
     function getBackPriceUpto2dp(uint256 val) internal  returns ( uint256 value)
    {
        return(val.div(100));
    }
  
    
     function stringToBytes32(string memory source) internal returns (bytes32 result)  {
        bytes memory tempEmptyStringTest = bytes(source);
        if (tempEmptyStringTest.length == 0) {
        return 0x0;
        }
    assembly {
        result := mload(add(source, 32))
    }
  }
  
      function compareStrings (string memory a, string memory b) internal  
       returns (bool) {
        return (keccak256(abi.encodePacked((a))) == keccak256(abi.encodePacked((b))) );

       }
       
    function uint2str(uint _i) internal pure returns (string memory _uintAsString) {
    if (_i == 0) {
        return "0";
    }
    uint j = _i;
    uint len;
    while (j != 0) {
        len++;
        j /= 10;
    }
    bytes memory bstr = new bytes(len);
    uint k = len - 1;
    while (_i != 0) {
        bstr[k--] = byte(uint8(48 + _i % 10));
        _i /= 10;
    }
    return string(bstr);
}

}


/**
 * 
 * @author Shashank Solanki
 * Date 19-05-2019
 * 
 * This contract is store contract and functions will be visible to shoppers and admin both
 * Functions:
 * Buy item
 * Register new User
 * Check retun returnEligibility
 * Get user details 
 * 
**/



contract ABCStore is AdminFunctions
{
    
    address private _owner;
    address _nullAddr;


    constructor() public {
        _owner=msg.sender;
       
       
    }
    modifier ownerCheck{
        require (_owner==msg.sender);
        _;
    }
    
     modifier ageCheckForBeerPurchase(uint256 age){
        require (age>21);
        _;
    }
    
    modifier genderCheckForSkirt(string gender){
       require (compareStrings(gender,"F"));
        _;
    }
    
    modifier returnEligibility(uint256 transactionId){
        require (now<=_transactionMap[transactionId].dateOfPurchase + 15 days);
        _;
    }
    
    /**
     * New user can register themself using this function, they can give their personal wallet address , age and gender as input
     * 
    **/
    function registerNewUser(address walletAddress,uint256 age, string memory gender) public returns (bool success)
    {
        require(_userList[walletAddress].walletAddress==0x0);
         User memory _user;
            _user.walletAddress= walletAddress;
            _user.age= age;
            _user.gender= gender;
            _user.purchaseMadeThisMonthInCents= 0;
            _user.pointsCollected= 0;
            
         _userList[_user.walletAddress]= _user;
         users.push(_user.walletAddress);
         _newUserRegistration(_user.walletAddress,_user.age,_user.gender);
    }
    
    /**
     * Once user is register they can buy item by providing item name and qty.
     * 
     * This function also force item specific restrictions ex 
     * 
     * 1) Only someone older than 21 years can buy Beer
     * 2) Only female can buy Skirts
     * 3) User has sufficient balance or Not
     * 4) Is item in stock?
     * 
     * Once respective criterias are validated , the purchase is made and same amount of tokens get burnt from users wallet 
     * Transaction will be recorded in transacion book
     * 
    **/
    function buy(string item,uint256 qty) public returns (string result)
    {
        emit _newUserRegistration(_userList[msg.sender].walletAddress,_userList[msg.sender].age,_userList[msg.sender].gender);
        if(_userList[msg.sender].age==0)
        {
          emit _logger("Not a registered user");
          return("You are not a registered user, please register yourself first");
           
        }else
        {
            if(_productList[stringToBytes32(item)].quantityLeft>qty){
            uint256 totalVal;
                if(_userList[msg.sender].isEliteShoper)
                {
                    totalVal= getBackPriceUpto2dp(convertToWei(discount(_productList[stringToBytes32(item)].price,10).mul(qty)));
                }else{
                    totalVal= getBackPriceUpto2dp(convertToWei(_productList[stringToBytes32(item)].price.mul(qty)));
                } 
            if(totalVal<=checkUsdtBalance(msg.sender))
            {
                uint256 transactionID;
                if(compareStrings(_productList[stringToBytes32(item)].name,"Skirt"))
                {
                if(purchaseSkirt(_userList[msg.sender]) ){
                    _productList[stringToBytes32(item)].quantityLeft= _productList[stringToBytes32(item)].quantityLeft.sub(qty);
                    burnTokens(msg.sender,getBackPriceUpto2dp(convertToWei(_productList[stringToBytes32(item)].price)));
                    _userList[msg.sender].purchaseMadeThisMonthInCents=_userList[msg.sender].purchaseMadeThisMonthInCents+_productList[stringToBytes32(item)].price.mul(qty);
                    transactionID=addTransaction(qty,_productList[stringToBytes32(item)].price,_productList[stringToBytes32(item)].name);
                    emit _loggerInt(transactionID);
                    return(uint2str(transactionID));
                    }else{
                    emit _logger("Only female can purchase Skirts");    
                    return("Only female can purchase Skirts");
                    }
                }
                else if(compareStrings(_productList[stringToBytes32(item)].name,"Beer"))
                {
                if(purchaseBeer(_userList[msg.sender]) ){
                    _productList[stringToBytes32(item)].quantityLeft= _productList[stringToBytes32(item)].quantityLeft.sub(qty);
                    burnTokens(msg.sender,getBackPriceUpto2dp(convertToWei(_productList[stringToBytes32(item)].price)));
                    _userList[msg.sender].purchaseMadeThisMonthInCents=_userList[msg.sender].purchaseMadeThisMonthInCents+_productList[stringToBytes32(item)].price.mul(qty);
                    transactionID=addTransaction(qty,_productList[stringToBytes32(item)].price,_productList[stringToBytes32(item)].name);
                    emit _loggerInt(transactionID);
                    return(uint2str(transactionID));
                     }else{
                         emit _logger("Age restriction 21 years old");
                         return("Age restriction 21 years old");
                     }   
                }
                else
                {
                    _productList[stringToBytes32(item)].quantityLeft= _productList[stringToBytes32(item)].quantityLeft.sub(qty);
                    burnTokens(msg.sender,getBackPriceUpto2dp(convertToWei(_productList[stringToBytes32(item)].price)));
                    _userList[msg.sender].purchaseMadeThisMonthInCents=_userList[msg.sender].purchaseMadeThisMonthInCents+_productList[stringToBytes32(item)].price.mul(qty);
                    transactionID=addTransaction(qty,_productList[stringToBytes32(item)].price,_productList[stringToBytes32(item)].name);
                    emit _loggerInt(transactionID);
                    return(uint2str(transactionID));
                }
                emit _logger("Item bought successfully");
                return("Item bought successfully");

            }else
            {
                 emit _logger("Insufficient Balance");
                 return("Insufficient Balance");
            }
            }else
            {
            emit _logger("Product is out of stock");
            return("Product is out of stock");
            }
        }
        
    }
    
    /**
     * User/Admin can check if the purchase is elegible for return or not
     * 
    **/
    function checkReturnEligibility(uint256 transactionId) view public returns(bool success)
    {
        if(_productList[stringToBytes32(_transactionMap[transactionId].productNam)].canReturn &&now<=_transactionMap[transactionId].dateOfPurchase + 15 days){
            return true;
        }
    }
    /**
     * User/Admin can check if the purchase is elegible for return or not
     * 
    **/
    function getUserDetails(address walletAddress) view public returns ( address UserWalletAddress,  uint256 age, string gender, uint256 purchaseMadeThisMonthInCents,uint256 ABCT,uint256 USDT)
    {
        require(msg.sender==walletAddress || _owner == msg.sender);
        User memory _user=_userList[walletAddress];
        return (_user.walletAddress,_user.age,_user.gender,_user.purchaseMadeThisMonthInCents,checkACBTBalance(walletAddress),checkUsdtBalance(walletAddress));
    }
    
    function purchaseSkirt(User user) internal genderCheckForSkirt(user.gender) returns(bool success) 
    {
        return true;
    }
    
    function purchaseBeer(User user) internal ageCheckForBeerPurchase(user.age) returns(bool success) 
    {
        return true;
    }
    

}