pragma solidity ^0.4.2;

// Base contract for TargetContracts' interface with the environment (blockchain).
//
// During automated bounties, use either the EnvironmentTestContract
// below, or create one of your own with more, or less, constraints.

// For production, use ProdEnvironment below, or replace references
// to this interface in the original TargetContract with their direct global vars*.
//
// * In future, an automatic tool will be able to do that.
contract EnvironmentContractInterface {
  function blockDotBlockHash(uint blockNumber) returns (bytes32);
  function blockDotCoinbase() returns (address);
  function blockDotDifficulty() returns (uint);
  function blockDotGasLimit() returns (uint);
  function blockDotNumber() returns (uint);
  function blockDotTimestamp() returns (uint);
  function now() returns (uint);
}


// Environment contract to use for bounty contracts. 
// Of course, you do not have to use this contract, you can create a similar
// one.
contract EnvironmentTestContract is EnvironmentContractInterface {
  mapping(uint =>bytes32) blockHash;
  address coinbase;
  uint difficulty;
  uint gasLimit;
  uint currentBlockNumber;
  uint timestamp;
  bool blockGasLimitChanged;
  
  // Returns the block hash set for this block by setBlockDotBlockHash(),
  // or, if none has been set, the prod block hash.
  function blockDotBlockHash(uint forBlockNumber) returns (bytes32) {
      if (int(forBlockNumber) < (int(currentBlockNumber - 256)) 
          || (forBlockNumber >= currentBlockNumber)) {
          // Spec allows acceessing [currentblock-256, currentblock) only. 
          return 0;
      }
      bytes32 hash = blockHash[forBlockNumber];
      if (uint(hash) == 0) {
          // Not explicitly set, return prod version.
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
    if (blockGasLimitChanged) throw;
    gasLimit = _gasLimit;
    blockGasLimitChanged = true;
  }
  
  function setBlockDotNumber(uint blockNumber) {
      // Time can only move forward.
      if (blockNumber <= currentBlockNumber) throw;
      currentBlockNumber = blockNumber;
      blockGasLimitChanged = false;
  }
  function setBlockDotTimestamp(uint _timestamp) {
      // Time can only move forward.
      if (_timestamp < timestamp) throw;
      timestamp = _timestamp;
  }
}

// This is the environment that is to be run in production.
// In order to save gas, one may carefully get rid of the EnvironmentInterface 
// before deploying contract to production, and replace calls with references
// to the actual variables.
contract ProdEnvironment {
  function blockDotBlockHash(uint blockNumber) returns (bytes32) {
      return block.blockhash(blockNumber);
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
