// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;




library SafeMath {
    
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

contract ERC20{

  using SafeMath for uint256;
  

  string public name=[[NAME]];
  string public asset=[[ASSET]];
  uint256 public totalSupply=[[TOKENSUPPLY]];
  uint256  public decimals = 18;
  address public issuer;
  address public registrar;
 

//Declaring events to emit on blockchain
  event IssuerTransferred (address indexed oldIssuer, address indexed newIssuer);
  event RegistrarTransferred (address indexed oldRegistrar, address indexed newRegistrar);
  event Burn (address from, uint256 value);
  event Transfer (address from, address to, uint256 amount);
  event AddedToWhitelist (address holder);
  event RemovedFromWhitelist (address holder);
  event Approval(address indexed owner, address indexed spender, uint256 value);

  mapping (address => uint256)  public _balances;
  mapping (address => mapping (address => uint256))  public _allowed;

  bool  public paused = false;

   constructor() {
    

      issuer  = 0x5B38Da6a701c568545dCfcB03FcB875f56beddC4; 
      registrar = 0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2;
      addToWhitelist(issuer);
      addToWhitelist(registrar);
      _balances[issuer] = totalSupply;
             paused=true;
     
}

modifier onlyIssuerOrRegistrar {
  require(msg.sender == issuer || msg.sender == registrar, "only valid for issuer or registrar");
  _;
  }
      
modifier onlyIssuer {
  require(msg.sender == issuer, "only valid for issuer");
  _;
  }

modifier onlyRegistrar {
  require(msg.sender == registrar, "only valid for issuer");
  _;
}
function checkBalanceforIsuuerorRegisterar(address _address) onlyIssuerOrRegistrar public view returns(uint256){
    require(_address!=address(0),"Null Address");
    return _balances[_address];
    }

function checkBalance() public view returns(uint256){
    return _balances[msg.sender];
}

function pauseContract() public onlyIssuerOrRegistrar returns(bool){
  require(!paused, "Contract already paused !");  
  paused=true;
    return true;
}

function unpauseContract() public onlyIssuerOrRegistrar returns(bool){
  require(paused, "Contract already unpaused !");
  paused=false;
    return true;
}

function isPaused() public view returns(bool){
    return paused;
}



function newIssuer(address payable _newIssuer) public onlyIssuerOrRegistrar {
  require(_newIssuer != address(0),"Issuer can't be Null address");
  require(_newIssuer!=issuer,"New issuer address and issuer should be same");
  removeFromWhitelist(issuer);
  issuer = _newIssuer;
  emit IssuerTransferred(issuer, _newIssuer);
  addToWhitelist(_newIssuer);

}

function newRegistrar(address payable _newRegistrar) public onlyIssuerOrRegistrar  {
  require(_newRegistrar!=address(0),"Address should be valid");
  require(_newRegistrar!=registrar,"Should be new Registrar");
  removeFromWhitelist(registrar);
  emit RegistrarTransferred(registrar, _newRegistrar);
  registrar = _newRegistrar;
  addToWhitelist(_newRegistrar);
}



function customerAllowance(address reciever) public view returns (uint256) {    
    require(reciever!=address(0),"Address should be valid");
    require(isWhitelisted(msg.sender), "Holder needs to be whitelisted by registrar or issuer");
    require(isWhitelisted(reciever), "Reciever needs to be whitelisted by registrar or issuer");
    return _allowed[msg.sender][reciever];
  }

  function increaseAllowance( address sender, address reciever,uint256 addedValue) public onlyIssuerOrRegistrar returns (bool){ 
    require(sender != address(0),"sender:  incorrect input");
    require(reciever != address(0),"reciever:  incorrect input");
    require(addedValue>0,"addedValue : incorrect input");
    _allowed[sender][reciever] = (_allowed[sender][reciever].add(addedValue));
    emit Approval(sender, reciever, _allowed[sender][reciever]);
    return true;
  }

  function decreaseAllowance(address sender, address reciever,uint256 subtractedValue) public onlyIssuerOrRegistrar returns (bool){ 
    require(sender != address(0),"sender:  incorrect input");
    require(reciever != address(0),"reciever:  incorrect input");
     require(subtractedValue>0," subtractedValue : incorrect input");
    _allowed[sender][reciever] = (
      _allowed[sender][reciever].sub(subtractedValue));
    emit Approval(sender, reciever, _allowed[sender][reciever]);
    return true;
  }

function allowanceOf(address from, address to) onlyIssuerOrRegistrar public view returns (uint256) {    
    require(from!=address(0),"from : address should be valid");
    require(to!=address(0),"to : address should be valid");
    return _allowed[from][to];
  }


function transferTokenAsIssuer(address from, address to, uint256 value) public onlyIssuerOrRegistrar returns (bool) {    
    require(value>0,"Value : incorrect value");
    require(value <= _balances[from]);
    require(value <= _allowed[from][to]);                   
    require(to != address(0));
    require(isWhitelisted(from), "Holder needs to be whitelisted by registrar or issuer");
    require(isWhitelisted(to), "Reciever needs to be whitelisted by registrar or issuer");
    require(value <= totalSupply, "Value bigger than Totalsupply");
    
    _balances[from] = _balances[from].sub(value);
    _balances[to] = _balances[to].add(value);

    require( _allowed[from][to] > 0 ,"allowance is not defined");
    _allowed[from][to] = _allowed[from][to].sub(value);   
    emit Transfer(from, to, value);
    return true;
  }

    function transferForCustomer (address _to,uint _value) public returns(bool){
    require(_to != address(0));
    require(_value>0,"_value : should be valid");
    require(!paused, "public transfer is paused");
    require(isWhitelisted(msg.sender), "Sender needs to be whitelisted by registrar or issuer");
    require(_value <= _balances[msg.sender],"Balance should be greater");
    require(isWhitelisted(_to), "Reciever needs to be whitelisted by registrar or issuer");
    require(_value <= totalSupply, "overflow protection");
    require(_value <= _balances[issuer], "not enough balance");
    _balances[_to] += _value;
    _balances[msg.sender] -= _value;
    require(_allowed[msg.sender][_to] > 0,"allowance is not defined");
    _allowed[msg.sender][_to]  -= _value;   
    emit Transfer(issuer, _to, _value);
    return true;
    }
   


  function burn(uint256 amount) public onlyIssuerOrRegistrar returns (bool) {
    require(amount > 0,"amount : should be valid");
    require(amount <= _balances[issuer], "not enough balance in issuer wallet to burn");  
    totalSupply -= amount;
    _balances[issuer]=_balances[issuer].sub(amount); 
    emit Burn(msg.sender, amount);
    return true;
}

function mint(uint256 _token) public onlyIssuerOrRegistrar returns (bool) { 
  require(_token>0,"token: should valid");
  totalSupply += _token;
  _balances[issuer] += _token;
  return true;
}

  
  function transferFromIssuer(address _to, uint256 _value) public onlyIssuer returns (bool success) 
  //no allowance Check needed (Token Erstübertragung)
{
    require(_to != address(0));
    require(_value>0,"_value : should be valid");
    require(!paused, "public transfer is paused");
    require(isWhitelisted(_to), "Reciever needs to be whitelisted by registrar or issuer");
    require(_value <= totalSupply, "overflow protection");
    require(_value <= _balances[issuer], "not enough balance");
    _balances[_to] += _value;
    _balances[issuer] -= _value;
    emit Transfer(issuer, _to, _value);
    
    return true;
}


function addToWhitelist(address verifiedAddress) public onlyIssuerOrRegistrar returns (bool success) {
  require(verifiedAddress!=address(0),"verifed Address should be valid");
  whitelist[verifiedAddress] = true;
  return true;
}
mapping (address => bool) public whitelist ;

function removeFromWhitelist(address _customer) public onlyIssuerOrRegistrar returns (bool success) {
    require(_customer!=address(0),"_customer : address should be valid");
    require(whitelist[_customer] == true, "Address is not in your whitelist");
  whitelist[_customer] = false;
  return true;
}

function isWhitelisted(address _address) public view returns (bool) {
  require(_address!=address(0),"_address : address should be valid");
  return whitelist[_address];
}

function kill() public onlyIssuer {
  burn(totalSupply);
  selfdestruct(payable(issuer));
}


}
