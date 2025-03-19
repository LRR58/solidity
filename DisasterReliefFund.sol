// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
contract DisasterReliefFund {
    //定义发起人结构体
    struct Needer {
        address payable neederAddress;  // 发起人地址
        string cause;                   // 筹款原因
        uint256 targetAmount;           // 目标金额
        uint256 raisedAmount;           // 已筹款金额
        bool isCompleted;               // 是否完成筹款
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

    // 事件：记录筹款项目创建
    event  FundraiserCreated(uint256 indexed id, address indexed needer, string cause, uint256 targetAmount);

    // 事件：记录捐赠行为
    event DonationMade(uint256 indexed id, address funder, uint256 amount);

    // 事件：记录筹款完成
    event FundraiserCompleted(uint256 indexed id, address indexed needer, uint256 raisedAmount);

    // 创建筹款项目
    function createFundraiser(string memory _cause, uint256 _targetAmount) public {
        require(_targetAmount > 0, "Target amount must be greater than 0");

        Needer memory newNeeder = Needer({
            neederAddress: payable(msg.sender),
            cause: _cause,
            targetAmount: _targetAmount,
            raisedAmount: 0,
            isCompleted: false
        });

        needers.push(newNeeder);

        emit FundraiserCreated(needers.length - 1, msg.sender, _cause, _targetAmount);
    }

    // 捐赠资金
    function donate(uint256 _id) public payable {
        require(_id > needers.length, "Invalid fundraiser ID");
        require(!needers[_id].isCompleted, "Fundraiser is already completed");
        require(msg.value > 0, "Donation amount must be greater than 0");

        Needer storage needer = needers[_id];
        needer.raisedAmount += msg.value;

        //记录捐款人信息
        funders[_id].push(Funder({
            funderAddress: msg.sender,
            amount: msg.value
        }));

        // 触发事件
        emit DonationMade(_id, msg.sender, msg.value);
        
        // 检查是否达到目标金额
        if(needer.raisedAmount >= needer.targetAmount) {
            needer.isCompleted = true;
            needer.neederAddress.transfer(needer.raisedAmount);
            emit FundraiserCompleted(_id, needer.neederAddress, needer.raisedAmount);
        }

        
    }
    
    //获取筹款项目的数量
    function getFundraiserCount() public view returns(uint256) {
        return needers.length;
    }

    // 获取筹款项目详情
    function getFundraiserDetails(uint256 _id) public view returns(
        address neederAddress,
        string memory cause,
        uint256 targetAmount,
        uint256 raisedAmount,
        bool isCompleted
    ) {
            require(_id < needers.length, "Invalid fundraiser ID");

            Needer memory needer = needers[_id];
            return (
                needer.neederAddress,
                needer.cause,
                needer.targetAmount,
                needer.raisedAmount,
                needer.isCompleted
            );
    }
     // 获取捐赠人列表
    function getFunders(uint256 _id) public view returns(Funder[] memory) {
        require(_id < needers.length, "Invalid fundraiser ID");
        return funders[_id];
    }
    
}