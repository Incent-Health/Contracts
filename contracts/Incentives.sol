pragma solidity ^0.4.15;

import './SafeMath.sol';
import './ERC20.sol';

// contract that holds multiple incentives of the same "type".
//  All incentives are attached to a goal (an address (ID) + a uint (goal#)) (see goals contract)
//  Incentives can be funded with ERC20 or ETH
//  Incentives be withdrawn by the funder after min 48 hrs notice is given.
//  This is a base contract that is not meant to be instantiated,
//   (the incentive can be claimed at any time with no restrictions)
//   see ProviderUnlockedGoalIncentive for an example of a protected incentive
contract Incentives {

	struct FundBalance {
		uint amount;
		uint canWithdrawAfter;
	}

	struct fundBalance {
		uint amount;
		uint canWithdrawAfter;
	}

	struct Funder {
		uint ethTotal;
		uint canWithdrawAfter;
		mapping(address => uint) ERC20Totals;
	}

	struct Incentive {
		uint ethTotal;
		mapping(address => uint) ERC20Totals;
		ERC20[] ERC20s;
		mapping(address => Funder) funders;
	}

	//mapping from goal (address + goal#) to incentive
	mapping(address => mapping(uint => Incentive)) private incentives;

	function ERC20s(address target, uint goalNum) public constant returns (ERC20[] ERC20s) {
		return incentives[target][goalNum].ERC20s;
	}

	function balanceOf(address _target, uint _goal, address _owner) public constant returns (uint balance, uint canWithdrawAfter) {
		Funder b = incentives[_target][_goal].funders[_owner];
		return (b.ethTotal, b.canWithdrawAfter);
	}

	function balanceOf(address _target, uint _goal, ERC20 _token, address _owner) constant returns (uint balance, uint canWithdrawAfter) {
		Funder b = incentives[_target][_goal].funders[_owner];
		return (b.ERC20Totals[_token], b.canWithdrawAfter);
	}

	modifier reasonableTimeLimit(uint _canWithdrawAfter) {
		require(_canWithdrawAfter > SafeMath.add(now, 2 days));
		_;
	}

	function setCanWithdrawAfter(address _target, uint _goal, uint _canWithdrawAfter)
		reasonableTimeLimit(_canWithdrawAfter) {
		incentives[_target][_goal].funders[msg.sender].canWithdrawAfter = _canWithdrawAfter;
	}

	function fundEth(address _target, uint _goal) payable {
		incentives[_target][_goal].funders[msg.sender].ethTotal = SafeMath.add(
			incentives[_target][_goal].funders[msg.sender].ethTotal,
			msg.value);
		Fund(_target, _goal, msg.sender, msg.value);
	}

	function addERC20(address _target, uint _goal, ERC20 _token) {
		bool inArray = false;
		for(uint i = 0; i < incentives[_target][_goal].ERC20s.length; i++) {
			if (incentives[_target][_goal].ERC20s[i] == _token) {
				inArray = true;
				break;
			}
		}
		if (!inArray) {
			incentives[_target][_goal].ERC20s.push(_token);
		}
	}

	function fund(address _target, uint _goal, ERC20 _token, uint _value) {
		addERC20(_target, _goal, _token);
		require(_token.transferFrom(msg.sender, this, _value));
		incentives[_target][_goal].funders[msg.sender].ERC20Totals[_token] = SafeMath.add(
			incentives[_target][_goal].funders[msg.sender].ERC20Totals[_token],
			_value);
		Fund(_target, _goal, msg.sender, _token, _value);
	}

	function fund(address _target, uint _goal, uint _canWithdrawAfter) payable {
		fundEth(_target, _goal);
		setCanWithdrawAfter(_target, _goal, _canWithdrawAfter);
	}

	function fund(address _target, uint _goal, ERC20 _token, uint _value, uint _canWithdrawAfter) {
		fund(_target, _goal, _token, _value);
		setCanWithdrawAfter(_target, _goal, _canWithdrawAfter);
	}

	modifier withinWithdrawWindow(address _target, uint _goal) {
		require(now > incentives[_target][_goal].funders[msg.sender].canWithdrawAfter);
		_;
	}

	function withdrawFunding(address _target, uint _goal, uint _value) 
		withinWithdrawWindow(_target, _goal) {
		incentives[_target][_goal].funders[msg.sender].ethTotal = SafeMath.sub(
			incentives[_target][_goal].funders[msg.sender].ethTotal,
			_value);
		msg.sender.transfer(_value);
		Withdraw(_target, _goal, msg.sender, _value);
	}

	function withdrawFunding(address _target, uint _goal, ERC20 _token, uint _value)
		withinWithdrawWindow(_target, _goal) {
		incentives[_target][_goal].funders[msg.sender].ERC20Totals[_token] = SafeMath.sub(
			incentives[_target][_goal].funders[msg.sender].ERC20Totals[_token],
			_value);
		assert(_token.transfer(msg.sender, _value));
		Withdraw(_target, _goal, msg.sender, _token, _value);
	}

	modifier onlyTarget(address target) {
		require(msg.sender == target);
		_;
	}

	function claim(address _target, uint _goal)
		onlyTarget(_target) {
		uint ethToTransfer = incentives[_target][_goal].ethTotal;
		incentives[_target][_goal].ethTotal = 0;
		msg.sender.transfer(ethToTransfer);
		Claim(_target, _goal, ethToTransfer);
		ERC20[] erc20s = incentives[_target][_goal].ERC20s;
		for(uint i = 0; i < erc20s.length; i++) {
			uint erc20ToTransfer = incentives[_target][_goal].ERC20Totals[erc20s[i]];
			incentives[_target][_goal].ERC20Totals[erc20s[i]] = 0;
			if(!erc20s[i].transfer(msg.sender, erc20ToTransfer)) {
				incentives[_target][_goal].ERC20Totals[erc20s[i]] = erc20ToTransfer;
			} else {
				Claim(_target, _goal, erc20s[i], erc20ToTransfer);
			}
		}
	}

	event Fund(address indexed _target, uint indexed _goal, address indexed _from, uint _value);
	event Fund(address indexed _target, uint indexed _goal, address indexed _from, ERC20 _token, uint _value);
	event Withdraw(address indexed _target, uint indexed _goal, address indexed _from, uint _value);
	event Withdraw(address indexed _target, uint indexed _goal, address indexed _from, ERC20 _token, uint _value);
	event Claim(address indexed _target, uint indexed _goal, uint _value);
	event Claim(address indexed _target, uint indexed _goal, ERC20 _token, uint _value);

}
