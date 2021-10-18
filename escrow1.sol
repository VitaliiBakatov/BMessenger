pragma solidity 0.8.7;      

contract Escrow { 
    address payable public executor; 
    address payable public customer;  

    string public service;
    uint256 public sum;
    uint256 public deadline;
    State public state; 
 
    enum State { awate_payment, awate_delivery, complete }                                                
      
    modifier instate(State expected_state) { 
        require(state == expected_state); 
        _; 
    } 

    modifier instateInProcess() { 
        require(state == State.awate_payment || state == State.awate_delivery); 
        _; 
    } 

    modifier onlyCustomer() { 
        require(_msgSender() == customer);  
        _; 
    } 

    modifier onlyExecutor() { 
        require(_msgSender() == executor); 
        _; 
    } 

    modifier checkDeadline() { 
        //require(deadline >= block.timestamp, "Deadline for this service is over");
        if (deadline < block.timestamp) 
          setState(State.complete);
        else
            _; 
    } 

    constructor(address payable _customer, address payable _executor,
        string memory _service,
        uint256 _sum, 
        uint256 _deadline
        ) 
    {       
        customer = _customer; 
        executor = _executor;
        service = _service;
        sum = _sum;      
        deadline = _deadline;  
        state = State.awate_payment; 
    } 
 
    function pay() onlyCustomer checkDeadline instateInProcess() public payable {        
        setState(State.awate_delivery);
    } 

    function deliverToExecutor() onlyCustomer checkDeadline
        instate(State.awate_delivery) 
        public
    { 
        uint256 balance = address(this).balance;
        sum -= balance;
        if (sum == 0) 
            setState(State.complete);
        (bool success,) = executor.call{value: balance}("");  
            require(success, "Failed to transfer Ether");
    } 
  
    function returnPayment() onlyExecutor checkDeadline instate(State.awate_delivery)
        public
    { 
        uint256 balance = address(this).balance; 
        sum += balance;
        (bool success, ) = executor.call{value: balance}("");  
            require(success, "Failed to transfer Ether");
    }    

    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
    
    function getState() public view returns (State) {
        return state;
    }

    function getRemainingSum() public view returns (uint256) {
        return sum;
    }

    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }  

    function setState(State expected_state) private {
        state = expected_state;  
    }
} 


