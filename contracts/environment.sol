pragma solidity ^0.4.4;

// Part of the PutYourMoneyWhereYourContractIs (bit.do/pymwyci) project.
//
//
/**
 * @title Base contract for TargetContracts' interaction with the environment (blockchain).
 * During automated bounties, use either EnvironmentTestContract
 * or create one of your own with more, or less, constraints.
 * 
 * For production, use ProdEnvironment below, or replace references to this 
 * interface in the original TargetContract with their direct global vars*.
 * 
 * * In future, an automatic tool will do that.
 */
contract EnvironmentContractInterface {
  function blockDotBlockHash(uint forBlockNumber) returns (bytes32);
  function blockDotCoinbase() returns (address);
  function blockDotDifficulty() returns (uint);
  function blockDotGasLimit() returns (uint);
  function blockDotNumber() returns (uint);
  function blockDotTimestamp() returns (uint);
  function now() returns (uint);
}


/**
 * Can be used as the Environment during testing and bounty challenges.
 * Of course, you do not have to use this contract, you can create a similar one.
 */
contract EnvironmentTestContract is EnvironmentContractInterface {
  mapping(uint =>bytes32) blockHash;
  address coinbase;
  uint currentBlockNumber;
  uint difficulty;
  uint gasLimit;
  uint timestamp;
  
  /**
   * Returns the block hash set for this block by setBlockDotBlockHash(),
   * or, if none has been set, the prod block hash.
   */
  function blockDotBlockHash(uint forBlockNumber) returns (bytes32) {
      if (int(forBlockNumber) < (int(currentBlockNumber - 256)) 
          || (forBlockNumber >= currentBlockNumber)) {
          // Spec allows acceessing [currentblock-256, currentblock) only,
          // otherwise returns 0.
          return 0;
      }
      bytes32 hash = blockHash[forBlockNumber];
      if (hash == 0) {
          // Not explicitly set, return prod value.
          return block.blockhash(forBlockNumber);
      }
      return hash;
  }
  
  function blockDotCoinbase() returns (address) {
      return (coinbase != 0) ? coinbase : block.coinbase;
  }
  
  function blockDotDifficulty() returns (uint) {
      return (difficulty != 0) ? difficulty : block.difficulty;
  }
  
  function blockDotGasLimit() returns (uint) {
      return (gasLimit != 0) ? gasLimit : block.gaslimit;
  }
  
  function blockDotNumber() returns (uint) {
      return (currentBlockNumber != 0) ? currentBlockNumber : block.number;
  }
  
  function blockDotTimestamp() returns (uint) {
      return (timestamp != 0) ? timestamp : block.timestamp;
  }
  
  function now() returns (uint) {
      return (timestamp != 0) ? timestamp : block.timestamp;
  }

  function setBlockDotBlockHash(uint forBlockNumber, bytes32 _blockHash) {
      // May never change once set.
      if (blockHash[forBlockNumber] != 0) throw;
      blockHash[forBlockNumber] = _blockHash;
  }
  
  function setBlockDotCoinbase(address addr) {
      if (addr == 0) throw;
      coinbase = addr;
  }
  
  function setBlockDotDifficulty(uint _difficulty) {
      if (_difficulty == 0) throw;
      difficulty = _difficulty;
  }
  
  function setBlockDotGasLimit(uint _gasLimit) {
    // Gas can only set once per block.
    if (gasLimit > 0) throw;
    gasLimit = _gasLimit;
  }
  
  function setBlockDotNumber(uint blockNumber) {
      // Time can only move forward.
      if (blockNumber <= currentBlockNumber) throw;
      currentBlockNumber = blockNumber;
      // Let user re-set gas limit.
      gasLimit = 0;
  }
  function setBlockDotTimestamp(uint _timestamp) {
      // Time can only move forward.
      if (_timestamp < timestamp) throw;
      timestamp = _timestamp;
  }
}

/**
 * Environment contract to be used in production.
 * Alternatively, in order to save gas, you may carefully replace calls
 * to the EnvironmentInterface with the actual variable names (e.g. block.number
 * instead of env.blockDotNumber() ).
 */
contract ProdEnvironment is EnvironmentContractInterface {
  function blockDotBlockHash(uint forBlockNumber) returns (bytes32) {
      return block.blockhash(forBlockNumber);
  }
  function blockDotCoinbase() returns (address) {
      return block.coinbase;
  }
  function blockDotDifficulty() returns (uint) {
      return block.difficulty;
  }
  function blockDotGasLimit() returns (uint) {
      return block.gaslimit;
  }
  function blockDotNumber() returns (uint) {
      return block.number;
  }
  function blockDotTimestamp() returns (uint) {
      return block.timestamp;
  }
  function now() returns (uint) {
      return block.timestamp;
  }
}
