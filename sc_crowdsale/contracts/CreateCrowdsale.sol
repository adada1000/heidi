pragma solidity ^0.5.0;

interface RewardToken {
    function transfer(address receiver, uint amount) external;
    function balanceOf(address holder) external returns (uint);
    function totalSupply() external returns (uint);
}

interface PaymentToken {
    function transferFrom(address from, address to, uint tokens) external returns (bool success);
    function allowance(address tokenOwner, address spender) external view returns (uint remaining);
    function balanceOf(address tokenOwner) external view returns (uint balance);
}

contract Crowdsale {
    address public beneficiary;
    uint public fundingGoal;
    uint public amountRaised;
    uint public deadline;
    uint public price;
    RewardToken public tokenReward;
    PaymentToken public tokenPayment;
    mapping(address => uint256) public balanceOf;
    bool public fundingGoalReached = false;
    bool public crowdsaleClosed = false;

    event GoalReached(address recipient, uint totalAmountRaised);
    event FundTransfer(address backer, uint amount, bool isContribution);

    /**
     * Constructor
     *
     * Setup the owner
     */
    constructor(
        address ifSuccessfulSendTo,
        uint fundingGoalInPaymentToken,
        uint durationInMinutes,
        uint costOfEachToken,
        address addressOfTokenUsedAsReward,
        address addressOfTokenUsedAsPayment
    ) public {
        beneficiary = ifSuccessfulSendTo;
        fundingGoal = fundingGoalInPaymentToken;
        deadline = now + durationInMinutes * 1 minutes;
        price = costOfEachToken;
        tokenReward = RewardToken(addressOfTokenUsedAsReward);
        tokenPayment = PaymentToken(addressOfTokenUsedAsPayment);
    }

    /**
     * Fallback function
     *
     * The function without name is the default function that is called whenever anyone sends funds to a contract
     */
     
    
//    function () payable external {
//        require(!crowdsaleClosed);
//        uint amount = msg.value;
//        balanceOf[msg.sender] += amount;
//        amountRaised += amount;
//        tokenReward.transfer(msg.sender, amount / price);
//       emit FundTransfer(msg.sender, amount, true);
//    }


    function buy(uint amount) public {
        require(!crowdsaleClosed, "Sale Closed");
        uint numTokens = ( amount * 1e18 ) / price;
        require(tokenReward.balanceOf(address(this)) >= numTokens, "Not enough tokens remaining");
        require(tokenPayment.transferFrom(msg.sender, address(this), amount), "Payment Missing");
        balanceOf[msg.sender] += amount;
        amountRaised += amount;
        tokenReward.transfer(msg.sender, numTokens);
        emit FundTransfer(msg.sender, amount, true);
    }

    function remaining() public returns (uint) {
        return tokenReward.balanceOf(address(this));
    }
    
    
    modifier afterDeadline() { if (now >= deadline) _; }

    /**
     * Check if goal was reached
     *
     * Checks if the goal or time limit has been reached and ends the campaign
     */
    function checkGoalReached() public afterDeadline {
        if (amountRaised >= fundingGoal){
            fundingGoalReached = true;
            emit GoalReached(beneficiary, amountRaised);
        }
        crowdsaleClosed = true;
    }


    /**
     * Withdraw the funds
     *
     * Checks to see if goal or time limit has been reached, and if so, and the funding goal was reached,
     * sends the entire amount to the beneficiary. If goal was not reached, each contributor can withdraw
     * the amount they contributed.
     */
    function safeWithdrawal() public afterDeadline {
        
        if (!fundingGoalReached) {
            uint amount = balanceOf[msg.sender];
            require(tokenPayment.transferFrom(address(this), msg.sender, amount), "No funds");
            balanceOf[msg.sender] = 0;
            emit FundTransfer(msg.sender, amount, false);
        }

        if (fundingGoalReached && beneficiary == msg.sender) {
            if (tokenPayment.transferFrom(address(this), msg.sender, amountRaised)) {
               emit FundTransfer(beneficiary, amountRaised, false);
            } else {
                //If we fail to send the funds to beneficiary, unlock funders balance
                fundingGoalReached = false;
            }
        }
    }
}

interface tokenRecipient { 
    function receiveApproval(address _from, uint256 _value, address _token, bytes calldata _extraData) external; 
}

contract ListERC20 {
    // Public variables of the token
    string public name;
    string public symbol;
    uint8 public decimals = 18;
    // 18 decimals is the strongly suggested default, avoid changing it
    uint256 public totalSupply;

    // This creates an array with all balances
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;

    // This generates a public event on the blockchain that will notify clients
    event Transfer(address indexed from, address indexed to, uint256 value);
    
    // This generates a public event on the blockchain that will notify clients
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

    // This notifies clients about the amount burnt
    event Burn(address indexed from, uint256 value);

    // maintain iteratable list of balances
    mapping (address => mapping (bool => address) ) public list;
    bool constant NEXT = true;
    bool constant PREV = false;
    address constant HEAD = address(0);
    
    /**
     *  Add entry to head of list
     * 
     */
    function addToList(address a) private {
        list[a][PREV] = HEAD;             
        list[a][NEXT] = list[HEAD][NEXT];   
        if ( list[HEAD][NEXT] != HEAD ) {
            list[ list[HEAD][NEXT] ][PREV] = a;
        }
        list[HEAD][NEXT] = a;   
    }

    /**
     *  Remove entry from list
     *
     */
    function removeFromList(address a) private {
        address prev_entry = list[a][PREV];
        address next_entry = list[a][NEXT];
        list[next_entry][PREV] = prev_entry;
        list[prev_entry][NEXT] = next_entry;
        delete list[a][PREV];
        delete list[a][NEXT];
    }


    /**
     * Constructor function
     *
     * Initializes contract with initial supply tokens to the creator of the contract
     */
    constructor(
        uint256 initialSupply,
        string memory tokenName,
        string memory tokenSymbol
    ) public {
        totalSupply = initialSupply;                        // in wei
        balanceOf[msg.sender] = totalSupply;                // Give the creator all initial tokens
        addToList(msg.sender);
        name = tokenName;                                   // Set the name for display purposes
        symbol = tokenSymbol;                               // Set the symbol for display purposes
    }

    /**
     * Internal transfer, only can be called by this contract
     */
    function _transfer(address _from, address _to, uint _value) internal {
        // Prevent transfer to 0x0 address. Use burn() instead
        require(_to != address(0x0));
        // Check if the sender has enough
        require(balanceOf[_from] >= _value, "Insufficient Funds");
        // Check for overflows
        require(balanceOf[_to] + _value >= balanceOf[_to]);
        // Save this for an assertion in the future
        uint previousBalances = balanceOf[_from] + balanceOf[_to];
        // Subtract from the sender
        balanceOf[_from] -= _value;
        
        if( balanceOf[_from] == 0) {
            removeFromList(_from);
        }        
        
        if (balanceOf[_to]==0 && _value > 0) {
            addToList(_to);
        }
        
        // Add the same to the recipient
        balanceOf[_to] += _value;
        emit Transfer(_from, _to, _value);
        // Asserts are used to use static analysis to find bugs in your code. They should never fail
        assert(balanceOf[_from] + balanceOf[_to] == previousBalances);
    }

    /**
     * Transfer tokens
     *
     * Send `_value` tokens to `_to` from your account
     *
     * @param _to The address of the recipient
     * @param _value the amount to send
     */
    function transfer(address _to, uint256 _value) public returns (bool success) {
        _transfer(msg.sender, _to, _value);
        return true;
    }

    /**
     * Transfer tokens from other address
     *
     * Send `_value` tokens to `_to` on behalf of `_from`
     *
     * @param _from The address of the sender
     * @param _to The address of the recipient
     * @param _value the amount to send
     */
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(_value <= allowance[_from][msg.sender]);     // Check allowance
        allowance[_from][msg.sender] -= _value;
        _transfer(_from, _to, _value);
        return true;
    }

    /**
     * Set allowance for other address
     *
     * Allows `_spender` to spend no more than `_value` tokens on your behalf
     *
     * @param _spender The address authorized to spend
     * @param _value the max amount they can spend
     */
    function approve(address _spender, uint256 _value) public
        returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    /**
     * Set allowance for other address and notify
     *
     * Allows `_spender` to spend no more than `_value` tokens on your behalf, and then ping the contract about it
     *
     * @param _spender The address authorized to spend
     * @param _value the max amount they can spend
     * @param _extraData some extra information to send to the approved contract
     */
    function approveAndCall(address _spender, uint256 _value, bytes memory _extraData)
        public
        returns (bool success) {
        tokenRecipient spender = tokenRecipient(_spender);
        if (approve(_spender, _value)) {
            spender.receiveApproval(msg.sender, _value, address(this), _extraData);
            return true;
        }
    }

    /**
     * Destroy tokens
     *
     * Remove `_value` tokens from the system irreversibly
     *
     * @param _value the amount of money to burn
     */
    function burn(uint256 _value) public returns (bool success) {
        require(balanceOf[msg.sender] >= _value);   // Check if the sender has enough
        balanceOf[msg.sender] -= _value;            // Subtract from the sender
        if( balanceOf[msg.sender] == 0) {
            removeFromList(msg.sender);
        } 
        totalSupply -= _value;                      // Updates totalSupply
        emit Burn(msg.sender, _value);
        return true;
    }

    /**
     * Destroy tokens from other account
     *
     * Remove `_value` tokens from the system irreversibly on behalf of `_from`.
     *
     * @param _from the address of the sender
     * @param _value the amount of money to burn
     */
    function burnFrom(address _from, uint256 _value) public returns (bool success) {
        require(balanceOf[_from] >= _value);                // Check if the targeted balance is enough
        require(_value <= allowance[_from][msg.sender]);    // Check allowance
        balanceOf[_from] -= _value;                         // Subtract from the targeted balance
        if( balanceOf[_from] == 0) {
            removeFromList(_from);
        } 
        allowance[_from][msg.sender] -= _value;             // Subtract from the sender's allowance
        totalSupply -= _value;                              // Update totalSupply
        emit Burn(_from, _value);
        return true;
    }
}

interface RewardTokenFactoryInterface {
    function newRewardToken(uint totalTokens, string calldata rewardTokenName, string calldata rewardTokenSymbol) external returns(address);
}

contract RewardTokenFactory {
    function newRewardToken(uint totalTokens, string calldata rewardTokenName, string calldata rewardTokenSymbol) external returns(address) {

        ListERC20 c = new ListERC20( totalTokens, rewardTokenName, rewardTokenSymbol );
        c.transfer(msg.sender,c.totalSupply());

        return address(c);
    }
}

contract CreateCrowdsale {
    
    event CrowdsaleCreated(address createdBy, address rewardToken, address crowdsale);
    
    function createCrowdsale (uint totalTokens,                 // 1,000,000 *1e18
                              uint saleTokens,                  //   500,000 *1e18
                              uint costOfEachToken,             //         1 *1e18
                              uint durationInMinutes,           //    45,000
                              address rewardTokenFactory,  
                              string memory rewardTokenName,    // "Rights - 50 Shades"
                              string memory rewardTokenSymbol,  // RT_B_50SHADES
                              address paymentToken)             // ERC20 to pay, eg. DAI
    public
    {
       
        RewardTokenFactoryInterface f = RewardTokenFactoryInterface(rewardTokenFactory);

        address rewardToken = f.newRewardToken(totalTokens, rewardTokenName, rewardTokenSymbol);
        
        uint fundingGoalInPaymentToken = (costOfEachToken * saleTokens) / 1e18; 
        
        // create the crowdsale contract
        Crowdsale crowdsale = new Crowdsale( msg.sender, 
                                             fundingGoalInPaymentToken,
                                             durationInMinutes, 
                                             costOfEachToken,
                                             rewardToken, 
                                             address(paymentToken) );
                                              
        // transfer required amount of reward token into crowdsale contract
        RewardToken r = RewardToken(rewardToken);

        uint keepTokens = totalTokens - saleTokens;

        r.transfer(msg.sender, keepTokens);
        r.transfer(address(crowdsale), saleTokens);

        emit CrowdsaleCreated(msg.sender, rewardToken, address(crowdsale));
    }                          
            
}
