pragma solidity 0.8.7;      

contract Escrow { 
    address payable public executor; 
    address payable public customer;  

    string private service;
    uint256 private sum;
    uint256 private deadline;
    State private state;
 
    enum State { awate_payment, awate_delivery, complete }                                                
      
    modifier instate(State expected_state) { 
        require(state == expected_state,
            "Unappropriate state of service for function"); 
        _; 
    } 

    modifier instateInProcess() { 
        require(state == State.awate_payment || state == State.awate_delivery,
            "Unappropriate state of service for function");
        _; 
    } 

    modifier onlyCustomer() { 
        require(_msgSender() == customer,
            "Only customer is allowed to call function");  
        _; 
    } 

    modifier onlyExecutor() { 
        require(_msgSender() == executor,
            "Only customer is allowed to call function"); 
        _; 
    } 

    modifier checkDeadline() { 
        require(deadline >= block.timestamp,
            "Deadline for this service is over");
        _; 
    } 


    constructor(address payable _customer, 
        address payable _executor,
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
    } 
    
    // перевод на контракт
    function pay() onlyCustomer checkDeadline instateInProcess() public payable {        
        setState(State.awate_delivery);
    } 
    
    // перевод с контракта на адрес исполнителя
    // изменение состояния, суммы
    function deliverToExecutor() onlyCustomer checkDeadline
        instate(State.awate_delivery) 
        public
    { 
        uint256 balance = address(this).balance;
        if (sum < balance)
            balance = sum;
        sum -= balance;
        if (sum == 0) 
            setState(State.complete);
        (bool success,) = executor.call{value: balance}("");  
            require(success, "Failed to transfer Ether to executor");
    } 
    
    // возврат покупателю
    function returnPayment() onlyExecutor checkDeadline 
        instate(State.awate_delivery)
        public
    { 
        uint256 balance = address(this).balance; 
        sum += balance;
        (bool success, ) = customer.call{value: balance}("");  
            require(success, "Failed to transfer Ether to customer");
    }   
    
    // само-возврат покупателем, если внёс слишком большую сумму
    function returnPaymentForCustomer() onlyCustomer 
        instate(State.complete)
        public
    { 
        uint256 balance = address(this).balance; 
        (bool success, ) = customer.call{value: balance}("");  
            require(success, "Failed to transfer Ether to customer");
    }


    function getService() public view returns (string memory) {
        return service;
    }  

    function getRemainingSum() public view returns (uint256) {
        return sum;
    }

    function getDeadline() public view returns (uint256) {
        return deadline;
    }

    function getState() public view returns (State) {
        return state;
    }

    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }  


    function _msgSender() internal view returns (address) {
        return msg.sender;
    }

    function setState(State expected_state) private {
        state = expected_state;  
    }
} 
