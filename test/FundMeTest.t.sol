//SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import{Test, console} from "forge-std/Test.sol";
import {FundMe} from "../src/FundMe.sol";
import {DeployFundMe} from "../script/DeployFundMe.s.sol";


contract FundMeTest is Test {
     FundMe fundMe;
     address USER = makeAddr("user");
     uint256 constant SEND_VALUE = 0.1 ether;
     uint256 constant STARTING_BALANCE = 10 ether;
    function setUp() external {
       DeployFundMe deployFundMe = new DeployFundMe();
       fundMe = deployFundMe.run();
       vm.deal(USER, STARTING_BALANCE);
    }
    function testMinimumDollarIsFive () public view {
        assertEq(fundMe.MINIMUM_USD(), 5e18);
    }
    function testOwnerIsMsgSender() public view{
        assertEq(fundMe.getOwner(), msg.sender);
    }
    function testPriceFeedVersionIsAccurate() public view  {
        uint256 version = fundMe.getVersion();
        assertEq(version, 4);
    }
    function testFundFailWithoutEnoughEth () public {
        vm.expectRevert();
        fundMe.fund();
    }
    function testFundUpdatesFundedDataStructure () public {
        vm.prank(USER);
        fundMe.fund{value:SEND_VALUE}();
        uint256 amountFunded = fundMe.getAddressToAmountFunded(USER);
        assertEq(amountFunded, SEND_VALUE);

    }
    function testAddsFunderToArrayOfFunders ()  public {
        vm.prank(USER);
        fundMe.fund{value: SEND_VALUE}();

        address funder = fundMe.getFunder(0);
        assertEq(funder, USER);
    }
    function testOnlyOwnerCanWithdraw ()  public {
        vm.prank(USER);
        fundMe.fund{value:SEND_VALUE}();
        vm.expectRevert();
        vm.prank(USER);
        fundMe.cheaperWithdraw();
    }
    function testWithdrawWithASingleFunder () public {
        vm.prank(USER);
        fundMe.fund{value:SEND_VALUE}();
        uint256 startingOwnerBalance = fundMe.getOwner().balance;
        uint256 startingFundMeBalance = address(fundMe).balance;

        vm.prank(fundMe.getOwner());
        fundMe.cheaperWithdraw();

        uint256 endingOwnerBalance = fundMe.getOwner().balance;
        uint256 endingFundMeBalance = address(fundMe).balance;
        assertEq(endingFundMeBalance, 0);
        assertEq(startingFundMeBalance + startingOwnerBalance, endingOwnerBalance);

    }
    function testWithdrawFromMultipleFundersCheaper () public {
        vm.prank(USER);
        fundMe.fund{value:SEND_VALUE}();
        uint160 numberOfFunders = 10;
        uint160 startingFunderIndex = 1;
        for  (uint160 i= startingFunderIndex; i < numberOfFunders; i++) {
            hoax(address(i), SEND_VALUE);
            fundMe.fund{value: SEND_VALUE}();
        }
    uint256 startingOwnerBalance =fundMe.getOwner().balance;
    uint256 startingFundMeBalance = address(fundMe).balance;
    vm.prank(fundMe.getOwner());
    fundMe.cheaperWithdraw(); 
    assert(address(fundMe).balance ==0);
    assert(startingFundMeBalance+startingOwnerBalance == fundMe.getOwner().balance);

    }
}