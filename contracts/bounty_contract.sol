pragma solidity ^0.4.4;

import "./environment.sol";

/**
 * Base contract for managing a specific bounty. Inherit from this contract
 * to create your own bounty.
 */
contract BaseBountyContract {
  address bountyManagerAddress;
  
  address activeTargetContract;

  modifier onlyFromBountyManager { 
    if (msg.sender != bountyManagerAddress) throw; 
    _;
  }
  
  function BaseBountyContract(address _bountyManagerAddress) { 
    _bountyManagerAddress = bountyManagerAddress;
  }
  
  /**
   * Creates a contract for the bug bounty challenger to try and break.
   * 
   */
  function challengeContract(address ownerToSet) onlyFromBountyManager returns (address, EnvironmentContractInterface) {
      EnvironmentContractInterface env = createTestingEnvironment();
      activeTargetContract = createTargetContract(ownerToSet);
      return (activeTargetContract, env);
  }
  
  /**
   * Override this method to create and return the address of the new target contract.
   * 
   * @param ownerToSet you may, at your own discretion, allow setting the owner of the targetContract
   *        to this address, if you'd like to make assertions about what owner can or cannot do.
   *        If you're not planning to have such assertions, ignore this parameter.
   */
  function createTargetContract(address ownerToSet) internal returns (address);
  

  /**
   * Override this method to create and return the address an environment contract
   * (e.g. EnvironmentTestContract).
   */
  function createTestingEnvironment() internal returns (EnvironmentContractInterface);

  
  /**
   * Returns true if the given contract, which must have been deployed by challengeContract(), is in 
   * an invalid state. 
   */
  function assertInvalidState() onlyFromBountyManager returns (bool);
}

