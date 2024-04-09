// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8.18;

import {Token} from "./Token.sol";
import {IERC20} from "./IERC20.sol";

// Inflation attack - attacker deposits tokens into the contract to inflate the value of the shares

// Inflation attack on this contract
// 1. User 0 deposits 1 token, and get 1 share
// 2. User 0 donates 100 * 1e18 (100 tokens) (inflating the value of the share)
// 3. User 1 deposits 100 * 1e18 (100 tokens) -> 0 shares minted
// 4. User 0 withdraws 200 * 1e18 (200 tokens) + 1

//    | balance        | user 0 shares | user 1 shares | total supply |
// 1. |              1 |            1  |             0 |            1 |
// 2. | 100 * 1e18 + 1 |            1  |             0 |            1 |
// 3. | 200 * 1e18 + 1 |            1  |             0 |            1 |
// 3.1. user 1 shares = (100 * 1e18 * 1) / (100 * 1e18 + 1) == 0
// 4. |              0 |             0 |             0 |            0 |

// Protections
// - Min shares -> protection from front running
// - Internal balance -> protection from donation
// - Dead shares -> contract is first depositor
// - Decimal offset (OpenZeppelin ERC4626)
contract Vault {
    IERC20 public immutable token;

    uint256 public totalSupply;
    mapping(address user => uint256 shares) public balanceOf;

    constructor(address _token) {
        token = IERC20(_token);
    }

    function _mint(address _to, uint256 _amount) private {
        totalSupply += _amount;
        balanceOf[_to] += _amount;
    }

    function _burn(address _from, uint256 _amount) private {
        totalSupply -= _amount;
        balanceOf[_from] -= _amount;
    }

    function deposit(uint256 _amount) external {
        /* 
        a = amount
        B = balance of token before deposit
        T = total supply
        s = shares to mint

        (T + s) / T = (a + B) / B

        s = aT / B
        */

        uint256 shares;
        if (totalSupply == 0) {
            shares = _amount;
        } else {
            shares = (_amount * totalSupply) / token.balanceOf(address(this));
        }

        _mint(msg.sender, shares);
        token.transferFrom(msg.sender, address(this), _amount);
    }

    function withdraw(uint256 _shares) external {
        /* 
        a = amount
        B = balance of token before withdraw
        T = total supply
        s = shares to burn

        (T - s) / T = (B - a) / B

        a = sB / T
        */
        uint256 amount = (_shares * token.balanceOf(address(this))) / totalSupply;
        // if(_shares > balanceOf[msg.sender]) revert();
        _burn(msg.sender, _shares);
        token.transfer(msg.sender, amount);
    }
}
