// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract DisasterReliefFund {
    // 定义发起人结构体
    struct Needer {
        address payable neederAddress;  // 发起人地址
        string cause;                   // 筹款原因
        uint256 targetAmount;           // 目标金额
        uint256 raisedAmount;           // 已筹款金额
        uint256 creationTime;           // 项目创建时间
        bool isCompleted;               // 是否完成筹款
        bool isWithdrawn;               // 资金是否已被提取
    }

    // 定义捐赠人的结构体
    struct Funder {
        address funderAddress;  // 捐赠人地址
        uint256 amount;         // 捐赠金额
    }

    // 储存筹款的项目
    Needer[] public needers;

    // 存储每个筹款项目的捐赠人
    mapping(uint256 => Funder[]) public funders;

    // 提取时间限制（30天）
    uint256 public constant WITHDRAWAL_DELAY = 30 days;

    // 事件：记录筹款项目创建
    event FundraiserCreated(uint256 indexed id, address indexed needer, string cause, uint256 targetAmount);

    // 事件：记录捐赠行为
    event DonationMade(uint256 indexed id, address funder, uint256 amount);

    // 事件：记录筹款完成
    event FundraiserCompleted(uint256 indexed id, address indexed needer, uint256 raisedAmount);

    // 事件：记录资金提取
    event FundsWithdrawn(uint256 indexed id, address indexed needer, uint256 amount);

    // 创建筹款项目
    function createFundraiser(string memory _cause, uint256 _targetAmount) public {
        require(_targetAmount > 0, "Target amount must be greater than 0");

        Needer memory newNeeder = Needer({
            neederAddress: payable(msg.sender),
            cause: _cause,
            targetAmount: _targetAmount,
            raisedAmount: 0,
            creationTime: block.timestamp,
            isCompleted: false,
            isWithdrawn: false
        });

        needers.push(newNeeder);

        emit FundraiserCreated(needers.length - 1, msg.sender, _cause, _targetAmount);
    }

    // 捐赠资金
    function donate(uint256 _id) public payable {
        require(_id < needers.length, "Invalid fundraiser ID");
        require(!needers[_id].isCompleted, "Fundraiser is already completed");
        require(msg.value > 0, "Donation amount must be greater than 0");

        Needer storage needer = needers[_id];
        needer.raisedAmount += msg.value;

        // 记录捐款人信息
        funders[_id].push(Funder({
            funderAddress: msg.sender,
            amount: msg.value
        }));

        // 触发事件
        emit DonationMade(_id, msg.sender, msg.value);
        
        // 检查是否达到目标金额 （检查-效果-交互）
        if(needer.raisedAmount >= needer.targetAmount) {
            needer.isCompleted = true;
            needer.isWithdrawn = true;
            needer.neederAddress.transfer(needer.raisedAmount);
            emit FundraiserCompleted(_id, needer.neederAddress, needer.raisedAmount);
        }
    }
    
    // 提取资金函数 - 允许发起人在一定时间后提取资金
    function withdrawFunds(uint256 _id) public {
        require(_id < needers.length, "Invalid fundraiser ID");
        Needer storage needer = needers[_id];
        
        // 只有项目发起人可以提取资金
        require(msg.sender == needer.neederAddress, "Only the fundraiser creator can withdraw funds");
        
        // 项目不能已经完成或已经提取过资金
        require(!needer.isCompleted, "Fundraiser is already completed");
        require(!needer.isWithdrawn, "Funds have already been withdrawn");
        
        // 检查是否已经过了等待期
        require(block.timestamp >= needer.creationTime + WITHDRAWAL_DELAY, "Withdrawal is not allowed yet");
        
        // 必须有资金可以提取
        require(needer.raisedAmount > 0, "No funds to withdraw");
        
        // 更新状态
        needer.isWithdrawn = true;
        
        // 转移资金
        uint256 amount = needer.raisedAmount;
        needer.neederAddress.transfer(amount);
        
        // 触发事件
        emit FundsWithdrawn(_id, msg.sender, amount);
    }
    
    // 检查是否可以提取资金
    function canWithdraw(uint256 _id) public view returns (bool) {
        if (_id >= needers.length) return false;
        
        Needer memory needer = needers[_id];
        
        return (
            !needer.isCompleted && 
            !needer.isWithdrawn && 
            block.timestamp >= needer.creationTime + WITHDRAWAL_DELAY &&
            needer.raisedAmount > 0
        );
    }

    // 获取筹款项目的数量
    function getFundraiserCount() public view returns(uint256) {
        return needers.length;
    }

    // 获取筹款项目详情
    function getFundraiserDetails(uint256 _id) public view returns(
        address neederAddress,
        string memory cause,
        uint256 targetAmount,
        uint256 raisedAmount,
        uint256 creationTime,
        bool isCompleted,
        bool isWithdrawn
    ) {
        require(_id < needers.length, "Invalid fundraiser ID");

        Needer memory needer = needers[_id];
        return (
            needer.neederAddress,
            needer.cause,
            needer.targetAmount,
            needer.raisedAmount,
            needer.creationTime,
            needer.isCompleted,
            needer.isWithdrawn
        );
    }
    
    // 获取捐赠人列表
    function getFunders(uint256 _id) public view returns(Funder[] memory) {
        require(_id < needers.length, "Invalid fundraiser ID");
        return funders[_id];
    }
}
