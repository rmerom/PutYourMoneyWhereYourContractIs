pragma solidity ^0.4.4;

import "./bounty_contract.sol";
import "./challenger_contract.sol";

/**
 * @title creates and manages bounties
 * 
 * Responsible for running bounties. Authors of contracts can register their 
 * BountyContract and challengers can use it to officially start a bounty challenge.
 */
contract BountyManager {
    event LogBountySubmitted(address bountyContract, uint bountySum, uint untilBlock);
    event LogChallengeInitiated(address contractTest, address caller);
    event LogBountySuccess(address bountyContract, address challenger);
    
    uint8 constant DEPOSIT_PERCENTAGE = 5;
    uint constant MIN_BOUNTY_DEADLINE_IN_BLOCKS = 5083; // ~1 day @ 17s/block
    uint16 constant NUM_BLOCKS_LOCKED = 36;  // ~10 minutes @ 17s/block
    uint MIN_BOUNTY_WEI = 1000000000000 wei;  // 1e12 wei == 1e-6 ether
    
    
    address owner = msg.sender;
    
    // Where to send lost deposits to. These are deposits made by bounty 
    // challengers who did not succeed in getting the bounty.
    address lostDepositsAddress;

    mapping(address => BountyInfo) bounties;
    mapping(address => uint) pendingWithdrawls;
    
    struct BountyInfo {
        // Bounty info
        bool exists;
        uint bountySum;
        uint runsUntilBlock;
        address bountyContract;
        address bountyOwner;
        bool successful;
        
        // Lock info
        uint lockedUntilBlock;
        address currentChallenger;
        uint currentDeposit;
    }
    
    function BountyManager(address _lostDepositsAddress) {
        lostDepositsAddress = _lostDepositsAddress;
    }

    /**
     * Call this method to register your own bounty.
     * The value with the call will constitute the bounty.
     */
    function registerBounty(
        address bountyContractAddress, 
        uint deadlineBlockNumber) payable {
        
        if (bounties[bountyContractAddress].exists) throw;
        if (msg.value < MIN_BOUNTY_WEI) throw;
        if (deadlineBlockNumber <= block.number) throw;
        bounties[bountyContractAddress] = BountyInfo(
            {
                exists: true,
                bountySum: msg.value,
                runsUntilBlock: deadlineBlockNumber,
                bountyContract: bountyContractAddress,
                bountyOwner: msg.sender,
                successful: false,
                
                lockedUntilBlock: 0,
                currentChallenger: 0,
                currentDeposit: 0
            });
        LogBountySubmitted(bountyContractAddress, msg.value, deadlineBlockNumber);
    }
      
    /**
     * Formally initiates a challenge with contractTest.
     * This call must be made with a deposit of at least 
     * DEPOSIT_PERCENTAGE * 0.01 * bounty sum, after which the challenger
     * receives exclusive rights to attack the targetContract for
     * NUM_BLOCKS_LOCKED blocks.
     * NOTE: the deposit is returned only if the challenge succeeds (on top
     * of the bounty sum). This is to prevent DoSing.
     * If contractTest's challenge is already locked by another challenger, 
     * this function throws.
     * If successful, this method issues a LogChallengeInitiated event. Once 
     * triggered, the challenger can call challengeContract() to start the
     * attack.
     */
    function initiateChallenge(address bountyContract) payable {
        BountyInfo bountyInfo = bounties[bountyContract];
        
        // Conditions
        if (!bountyInfo.exists || bountyInfo.successful) throw;
        if (block.number > bountyInfo.runsUntilBlock) throw;
        if (block.number <= bountyInfo.lockedUntilBlock) throw;
        if (msg.value < bountyInfo.bountySum * DEPOSIT_PERCENTAGE / 100) throw;
        
        // State changes
        releasePreviousLockIfNeeded(bountyInfo);
        bountyInfo.lockedUntilBlock = block.number + NUM_BLOCKS_LOCKED;
        bountyInfo.currentChallenger = msg.sender;
        bountyInfo.currentDeposit = msg.value;
        
        LogChallengeInitiated(bountyContract, msg.sender);
    }
    
    /**
     * Call this function only while holding the lock.
     * @param challengerContract the contract to run that will challenge the
     *        targetContract.
     */
    function challengeContract(
        address bountyContract, 
        address challengerContract) {

        // Conditions
        assertValidChallenger(bountyContract);

        BountyInfo bountyInfo = bounties[bountyContract];

        EnvironmentContractInterface env;
        address targetContract;
        (targetContract, env) = BaseBountyContract(bountyInfo.bountyContract).challengeContract();
        BaseChallengerContract(challengerContract).execute(targetContract, env);
    }
    
    /** 
     * Call this function only after calling challengeContract() and making
     * sure that targetContract is an invalid state, and before the lock expires. 
     * If this is the case, you'll be winning the bounty!
     */
    function assertInvalidState(address bountyContract) returns (bool) {
        // Conditions
        assertValidChallenger(bountyContract);

        BountyInfo bountyInfo = bounties[bountyContract];
        
        if (BaseBountyContract(bountyInfo.bountyContract).assertInvalidState()) {
            // Challenger won the bounty!
            bountyInfo.successful = true;
            pendingWithdrawls[msg.sender] += bountyInfo.bountySum;
            pendingWithdrawls[msg.sender] += bountyInfo.currentDeposit;
            
            // Clear storage to save on space.
            delete bounties[bountyContract];

            LogBountySuccess(bountyContract, msg.sender);
            
            return true;
        }
        // Sorry, no win, keep trying.
        return false;
    }
    
    /**
     * Withdraws bounty funds for a bounty creator in case nobody claimed the
     * bounty. Can only be called after the deadline has passed.
     */
    function releaseUnclaimedBounty(address bountyContract) {
        BountyInfo bountyInfo = bounties[bountyContract];
        
        if (!bountyInfo.exists) throw;
        if (block.number < bountyInfo.runsUntilBlock) throw;
        if (bountyInfo.successful) throw;  // Sorry, you lost.
        pendingWithdrawls[bountyInfo.bountyOwner] += bountyInfo.bountySum;
        
        delete bounties[bountyContract];
    }
    
    // Withdraws money from a successful bounty hunt.
    function getPendingWithdrawl() {
        if (pendingWithdrawls[msg.sender] == 0) throw;
        uint amount = pendingWithdrawls[msg.sender];
        
        pendingWithdrawls[msg.sender] = 0;
        if (!msg.sender.send(amount)) throw;
    }
    

    function releasePreviousLockIfNeeded(BountyInfo bountyInfo) internal {
         if (bountyInfo.lockedUntilBlock > 0) {
             // Last challenge failed, move funds to lostDepositsAddress;
             pendingWithdrawls[lostDepositsAddress] += bountyInfo.currentDeposit;
         }
    }
    
    /**
     * Checks conditions for the msg.sender to work on a given bounty.
     */
    function assertValidChallenger(address contractTest) {
        BountyInfo bountyInfo = bounties[contractTest];
        
        // Conditions
        if (!bountyInfo.exists) throw;
        if (block.number > bountyInfo.runsUntilBlock) throw;
        if (bountyInfo.currentChallenger != msg.sender) throw;
        if (block.number > bountyInfo.lockedUntilBlock) throw;
        if (msg.value < bountyInfo.bountySum * DEPOSIT_PERCENTAGE / 100) throw;
    }

    
    // v2
    // Lets outsiders suggest alternative ContractTest for testing a contract.
    // This only generates an event to be picked up by the bounty author,
    // and they can add this ContractTest, or another one.
    // function suggestContractTest(
    //    address originalContractTest, address suggestedContractTest);

    // v2: allows author of a bug bounty to add another ContractTest as a challenge.
    // Notice challengers need only break one of the ContractTests associated with a bounty.
    // function addContractTestToBounty(address originalContractTest, address additionalContractTest);

    // v2
    // event contractTestSuggested(
    //    address originalContractTest, address suggestedContractTest);

}

