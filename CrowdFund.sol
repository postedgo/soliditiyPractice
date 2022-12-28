//SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./IERC20.sol";

contract CrowdFund {

    event Launch(
        uintId,
        address indexed creator,
        uint goal,
        uint32 startAt,
        uint32 endAt,
    );

    event Cancel(uint _id);
    //first define a struct

    event Pledge(uint indexed id, address indexed caller, uint amount);

    event Unpledge(uint indexed id, address indexed caller, uint amount);

    event Claim(uint id);

    //multiple refunds for same campaigned so need to make id indexed
    event Refund(uint indexed id, address indexed caller, uint amount);

    struct Campaign {
        address creator;
        uint goal;
        uint pledged;
        uint32 startAt;
        uint32 endAt;
        //tokens for campaign has been claimed by creator
        bool claimed;
    }

    //each contract can handle only one token
    IERC20 public immutable token;
    uint public count;
    mapping(address => Campaign) public campaigns; 
    //how much has each user pledged
    mapping(uint => mapping(address => uint)) public pledgedAmount;

    //take in address of token
    constructor(address _token) {
        token = IERC20(_token);
    }

    function launch(uint _goal, uint32 _startAt, uint32 _endAt) external {
        require(_startAt >= block.timestamp, "start at < now");
        require(_endAt >= _startAt, "end at < start at");
        require(_endAt <= block.timestamp + 90 days, "end at > max duration");

        //new struct, implement id
        count += 1;
        campaigns[count] = Campaign ({
            creator: msg.sender,
            goal: _goal,
            pledged: 0,
            startAt: _startAt,
            endAt: _endAt,
            claimed: false
        });

        emit Launch(count, msg.sender, _goal, _startAt, _endAt);
    }

    function cancel(uint _id) external {
        //campaign must exist
        //only campaign creator can cancel and campaign should not have started yet
        Campaign memory campaign = campaigns[_id];
        require(msg.sender == campaign.creator, "not creator");
        require(block.timestamp < campaign.startAt, "started");
        delete campaigns[_id];
        emit Cancel(_id);
    }

    function pledge(uint _id, uint _amount) external {
        //first get campaign, declare variable as storage bc we need to update Campaign struct
        Campaign storage campaign = campaigns[_id];
        require(block.timestamp >= campagn.startAt, "not started");
        require(block.timestamp <= campaign.endAt, "ended");

        campaign.pledged += amount;
        pledgedAmount[_id][msg.sender] += amount;
        token.trasnferFrom(msg.sender, address(this), _amount);

        emit Pledge(_id, msg.sender, _amount);
    }

    function unpledge(uint _id, uint _amount) external {
        Campaign storage campaign = campaigns[_id];
        require(block.timestamp <= campaign.endAt, "ended");

        campaign.pledged -= _amount;
        pledgedAmount[_id][msg.sender] -= _amount;
        token.transfer(msg.sender, _amount);
        emit Unpledge(_id, msg.sender, _amount);
    }

    function claim(uint _id) external {
        //after success of campaign
        Campaign storage campaign = campaigns[_id];
        require(msg.sender == campaign.creator, "not creator");
        require(block.timestamp > campaign.endAt, "not ended");
        require(campaign.pledged >= campaign.goal, "pledged < goal");
        require(!campaign.claim, "claimed");

        campaign.claim = true;
        //transfer total amount that was pledged to creator
        token.transfer(msg.sender, campaign.pledged);

        emit Claim(_id);
    }

    function refund(uint _id) external {
        //unsuccessful campaign
        Campaign storage campaign = campaigns[_id];
        require(block.timestamp > campaign.endAt, "not ended");
        require(campaign.pledged < campaign.goal, "pledged < goal");

        uint bal = pledgedAmount[_id][msg.sender];
        pledgedAmount[_id][msg.sender] = 0;
        token.transfer(msg.sender, bal);

        emit Refund(_id, msg.sender, bal);
    }
}
