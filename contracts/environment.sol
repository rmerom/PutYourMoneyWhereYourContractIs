pragma solidity ^0.4.2;

// Base contract for TargetContracts' interface with the environment (blockchain).
// For production use, one may use ProdEnvironment below, or remove references
// to this interface from the original TargetContract*.
//
// For automated bounties, authors may either use the EnvironmentTestContract
// below, or create one of their own with more, or less, constraints.
// * In future, we'll have a tool to automatically do that.
contract EnvironmentContractInterface {
  function blockDotBlockHash(uint blockNumber) returns (bytes32);
  function blockDotCoinbase() returns (address);
  function blockDotDifficulty() returns (uint);
  function blockDotGasLimit() returns (uint);
  function blockDotNumber() returns (uint);
  function blockDotTimestamp() returns (uint);
  function now() returns (uint);
}

// Target-contract authors may use this contract to simulate the environment
// for their target-contract, or may choose to replace it with a similar one.
// Note the environment contract must be published for the bounty.
contract EnvironmentTestContract is EnvironmentContractInterface {
  mapping(uint =>bytes32) blockHash;
  address coinbase;
  uint difficulty;
  uint gasLimit;
  uint currentBlockNumber;
  uint timestamp;
  bool blockGasLimitChanged;
  
  function blockDotBlockHash(uint forBlockNumber) returns (bytes32) {
      if (currentBlockNumber != 0 && 
          ((forBlockNumber < currentBlockNumber - 256) || (forBlockNumber >= currentBlockNumber))) {
          // This is not allowed per the spec. Behave the same as if this
          // was asked for in production.
          uint projectedBlockNumber = 
              forBlockNumber + currentBlockNumber - block.number;
          return block.blockhash(projectedBlockNumber);
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
      return timestamp;
  }
  
  function now() returns (uint) {
      return timestamp;
  }

  function setBlockDotBlockHash(uint forBlockNumber, bytes32 _blockHash) {
      // May never change once set.
      if (blockHash[forBlockNumber] != 0) throw;
      // Do not accept special value.
      if (_blockHash == 0) throw;
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
