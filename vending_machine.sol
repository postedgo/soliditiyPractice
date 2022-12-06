// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

contract VendingMachine {
    //set this to address of deployer of contract
    address public owner;
    //map eth addresses to number of donuts each address owns; uint, unsigned integer, uin256-only positive values
    mapping(address => uint) public donutBalances;

    constructor() {
        //constructor called when smart contract deployed
        owner = msg.sender;
        //set initial donut balance of vending machine 100. address(this) - give address of current contract, owner
        donutBalances[address(this)] = 100;
    }

    function getVendingMachineBalance() public view returns(uint) {
        //return from the donutbalances mapping the amount of donuts associated with this smart contract
        return donutBalances[address(this)];
    }

    function restock(uint amount) public {
        require(msg.sender == owner, "Only the owner can restock this machine.");
        donutBalances[address(this)] += amount;
    }

    //purchase function
    function purchase(uint amount) public payable {
        //make sure amount of eth coming is greater than or equal to price of donuts
        //cost 2 ether per donut, add error message in case
        require(msg.value >= amount * 2 ether, "You must pay at least 2 ether per donut");
        //check donut balances of address(this), current contract
        require(donutBalances[address(this)] >= amount, "Not enough donuts");
        donutBalances[address(this)] -= amount;
        donutBalances[msg.sender] += amount;
    }
}
