pragma solidity ^0.5.10;

import "./ERC20.sol";
import "./ERC20Burnable.sol";
import "./Ownable.sol";
import "./ERC20Detailed.sol";

contract GRUSD is ERC20, ERC20Burnable, Ownable, ERC20Detailed {

    using SafeMath for uint256;

    struct Stakeholder {
        uint256 amount;
        uint256 profit;
        uint256 withdrawDate;
        uint256 totalAmount;
        uint256 totalProfit;
        uint256 totalWithdraw;
        bool isStakeholder;
    }

    mapping(address => Stakeholder) public stakeholders;

    address[] public stakeholdersList;

    uint256 public totalStakeAmount = 0;
    uint256 public totalStakeProfit = 0;
    uint256 public totalStakeWithdraw = 0;

    uint256 public profitPercent = 278;

    constructor () public ERC20Detailed("GRUSD", "GRUSD", 6) {
        _mint(msg.sender, 100000000 * (10 ** uint256(decimals())));
    }

    function addToStake(uint256 amount) public
    {
        require(amount > 0, "Bad amount");

        _burn(msg.sender, amount);

        if (stakeholders[msg.sender].amount == 0 && stakeholders[msg.sender].profit == 0) {
            stakeholders[msg.sender].withdrawDate = block.timestamp + 365 days;
        }

        stakeholders[msg.sender].amount += amount;
        stakeholders[msg.sender].totalAmount += amount;

        if (!stakeholders[msg.sender].isStakeholder) {
            stakeholdersList.push(msg.sender);
            stakeholders[msg.sender].isStakeholder = true;
        }
        
        totalStakeAmount += amount;
    }

    function removeFromStake() public
    {
        require(stakeholders[msg.sender].amount > 0, "Not in stake");
        require(block.timestamp > stakeholders[msg.sender].withdrawDate, "You can withdraw deposit only after a year");

        _mint(msg.sender, stakeholders[msg.sender].amount);
        stakeholders[msg.sender].amount = 0;
    }

    function calculateProfit(uint256 amount) private returns(uint256)
    {
        return amount * profitPercent / 100000;
    }

    function accrueStakeProfit() public onlyOwner
    {
        for (uint256 i = 0; i < stakeholdersList.length; i++) {
            uint256 amount = stakeholders[stakeholdersList[i]].amount;

            if (amount > 0) {
                uint256 profit = calculateProfit(amount);
                stakeholders[stakeholdersList[i]].profit += profit;
                stakeholders[stakeholdersList[i]].totalProfit += profit;

                totalStakeProfit += profit;
            }
        }
    }

    function withdrawStakeProfit() public
    {
        uint256 amount = stakeholders[msg.sender].profit;
        require(amount > 0, "You have no profit yet");
        
        stakeholders[msg.sender].profit = 0;
        stakeholders[msg.sender].totalWithdraw += amount;

        totalStakeWithdraw += amount;

        _mint(msg.sender, amount);
    }

    /*
        Only external call
    */

    function totalInStake() public view returns(uint256)
    {
        uint256 totalInStakeAmount = 0;
        for (uint256 i = 0; i < stakeholdersList.length; i++) {
            totalInStakeAmount += stakeholders[stakeholdersList[i]].amount;
        }
        return totalInStakeAmount;
    }

    function profitOf(address _addr) public view returns(uint256)
    {
        return stakeholders[_addr].profit;
    }

    function totalProfitOf(address _addr) public view returns(uint256)
    {
        return stakeholders[_addr].totalProfit;
    }

}