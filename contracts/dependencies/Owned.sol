pragma solidity ^0.4.24;


contract Owned {
    address owner;

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyowner {
        assert(msg.sender == owner);
        _;
    }
}