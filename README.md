# "Put Your Money Where Your Contract Is"
## Automated Bug Bounty Program for High Stake Contracts
### Status: first draft, WIP
<div align="right">
<sub><a href='https://github.com/rmerom'>Ron Merom</a>, Nov 2016</sub>
</div>

### Motivation
[TheDAO hack](http://www.coindesk.com/understanding-dao-hack-journalists/) raised concerns in the Ethereum community about existing security measures to audit contracts, especially those that are expected to hold substantial amounts of money, as in the case of crowdfunding/ICO sales.

Different tools have been proposed to increase users' confidence in the security of high stake contracts, such as Formal Verification and Manual Bug Bounties.

We present a mechanism that allows high-stake contract authors to create a trustless, ethereum-based Bug Bounty to be used in the period after the high-stake contract is published and **before** it is put in production.

Such a mechanism is expected to draw attention from challengers with the necessary technical skills to find vulnerabilities, as they can deterministically predict the reward. So-called black hat hackers may also be drawn, in order to receive a bounty prize before someone else detects a vulnerability.

### Related work

Following a [tweet](https://twitter.com/random_walker/status/692807445408845824) by @random_walker, de la Rouviere [mentioned](https://media.consensys.net/2016/05/05/assert-guards-towards-automated-code-bounties-safe-smart-contract-coding-on-ethereum/) automatic bounties back in May 2016.

Peter Borah [gave](https://medium.com/@peterborah/we-need-fault-tolerant-smart-contracts-ec1b56596dbc#.1j7it3cff) an example of how an automated bug bounty for a specific contract could be created.

Manuel Aráoz [showed another example](https://medium.com/zeppelin-blog/onward-with-ethereum-smart-contract-security-97a827e47702#.o4ckev1rf) of a contract-specific automated bug bounty as one tool in contract security.

Our contribution is to propose a general-purpose, reusable "Put Your Money Where Your Contract Is" Bounty manager contract that allows high stake contract creators to set up bounty programs with minimal overhead, and provides higher confidence for challengers that they will receive the award if they are successful.



### Protocol Summary
![figure 1](http://www.pixhoster.info/f/2016-11/27333f074fd472da2c0a52ff61fe4a84.png)
Alice the Author wants to write a contract for general use by Ethereum users, which we'll name `TargetContract`. She is willing to put her money behind its security, and give out some amount of Ether as bounty for anyone who finds a fault in the contract.

After publishing a semi-final draft of `TargetContract`, she involves the community in a collabarative effort to create a `TargetContract`-specific accompanying bounty contract, which we'll name `BountyContract`. The bounty contract describes tests to see if a given `TargetContract` is in any invalid state. It can also generate &amp; deploy a new copy of `TargetContract` for challenging.


She then registers `BountyContract` with the `BountyManager` contract, along with a deposit, for a specified period. Any challenger can try and break `BountyContract` and win that deposit during that period. A 5% deposit is required from the challenger to avoid DoSing.
![figure2](http://www.pixhoster.info/f/2016-11/c4b4a110d501d2a9f83383ad6c0178d2.png)

### Detailed Description
#### Contracts Involved
* `BountyManager`  is the contract registry for bounties, presented in this essay. It registers and manages bounties. It is presented in this work.
* `TargetContract` is the high stake contract that the Author challenges other to find vulnerabilities in. It has to adhere to some guidelines (see <a href='#constraints-for-targetcontract'>Constraints</a>).
* `BountyContract` is written by the Author in a collobarative manner with the community to try and identify any potential invalid states of the contract. Examples might include the contract not having the amount of money it "thinks" it has, or a changing number of total tokens in case of a token contract. `BountyContract` also has a method for generating &amp; deploying a brand new `TargetContract` for challenging.
* `ContractEnvironmentInterface` is an abstract contract providing access to environment variables (e.g. `block.number`) for `TargetContract` to help the challenger set up a scenario where the contract fails. `ContractTestEnvironment` is a concrete descendant that allows a challenger to play with the environment under some reasonable restrictions. While a `ContractTestEnvironment` is presented in this work, the Author may choose to copy and modify it in a way she sees as reasonable for her contract.
* Any number of so-called "attack contracts" by the Bounty Challenger that help him expose the vulnerability in `TargetContract`.


#### Order of interactions
1. Alice publishes `TargetContract` and a draft of `BountyContract`. Both, and especially the latter, are up for community inspection for some period of time. Potential challengers, as well as security experts, may suggest additional tests to add to `BountyContract`, either formally (see <a href="#future-directions">Future Directions</a>) or informally (through forums etc.).
2. Once that period is over, Alice deploys the final version of `BountyContract` and registers it with the `BountyManager` contract, along with the bounty deposit. She also defines a period *p* during which the bounty is open for grabs for anyone who manages to coerce the contract into an invalid state.
3. Charlie the Challenger believes he can break `TargetContract` in a way that `BountyContract.assertInvalidState()` will return true. He quietly builds up and verifies his strategy offline. When he's ready, he creates in advance the transactions needed to prove `TargetContract`'s vulnerability. He pre-deploys any required attack contracts discretely on the Ethereum production blockchain. He may also play (in any legitimate way) with `TargetContract`'s environment by pre-creating his own instance of `EnvironmentContractInterface`.
4.  Charlie calls `PYMWYCI.initiateChallenge()` with a deposit of 5% of the bounty sum. This makes sure `BountyManager` locks the `BountyContract` bounty solely for Charlie for the next 40 blocks (~10 minutes). 
5.  Charlie calls `PYMWCI.challengeContract()` with the address of his attack contract (and probably with a lot of gas).
5. Charlie may fire any additional transactions he prepared in advance to get `TargetContract` into an invalid state, then calls `PYMWYCI.assertState()`.
6. If successful, the bounty fund in `BountyManager` becomes withdrawable by Charlie. Otherwise, [TBD what happens with Charlie's deposit. Should not be given to Alice to prevent her from DoSing the bounty].

### Constraints applicable to `TargetContract`
Constraints below apply both to `TargetContract` and to any external methods it calls (in libraries and/or external contracts).
* In order to allow assertions about what the contract owner should do, its contrsuctor should not use `msg.sender`. If needed, the owner should instead be dependency-injected as a parameter (and be populated with the challenger's address upon creation of a challenge).
* It should not use any of the global variables, but instead use the `EnvironmentContractInterface` (as a library) passed in its constructor to retrieve those. In production, these will simply return the actual variable values. In future, an open source tool would be able to replace any such calls with the direct variables to reduce gas costs.


### Security Aspects
#### Protecting the Author
#####  The `ContractTarget` author may

Assumptions in this model are that Alice represents a group of people that are `b`-sure that `TargetContract` is flawless (where `b`-sure, formally, is that they're willing to bet `b` Ether on that fact).
TODO(rmerom): complete this section.

### Future Directions
1. Allow testing a system composed of multiple contracts.
2. Allow Challengers to formally suggest new tests for `TargetContract`. The requirement for formal, open suggestion is that even the suggestion might expose vulnerability information to the Author. By formally and openly suggesting new tests, the Author reputation is at stake if she rejects them based on the fact that she realizes they expose a vulnerability.
3. Allow different tests to be associated with different bounty values s.t. more major vulnerabilites will produce higher bounty prizes.
4. Allow a temporal increase of bounty prize (for example, bounty starts at `b/10` and climbs up to `b` Ether). This will allow obvious bugs that were overlooked to be fixed without Alice having to pay the entire bounty amount.

### NOTE: more perliminary code will be uploaded soon
[Contracts Code](https://github.com/rmerom/PutYourMoneyWhereYourContractIs/blob/master/contracts)


