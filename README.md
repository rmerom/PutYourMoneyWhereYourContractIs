# "Put Your Money Where Your Contract Is"
## Automated Bug Bounty Program for High Stake Contracts
### Status: first draft, WIP
<div align="right">
<sub><a href='https://github.com/rmerom'>Ron Merom</a>, Oct 2016</sub>
</div>

### Motivation
[TheDAO hack](http://www.coindesk.com/understanding-dao-hack-journalists/) raised concerns in the Ethereum community about existing security measures to audit contracts, especially those that are expected to hold substantial amounts of money, as in the case of crowdfunding/ICO sales.

Different tools have been suggested to raise security level of high stake contracts, among them Formal Verification and Manual Bug Bounties.

We present a mechanism that allows high-stake contract authors to create a trustless, ethereum-based Bug Bounty to be used in the period after the high-stake contract is published and **before** it is put in production.

### Related work

Following a [tweet](https://twitter.com/random_walker/status/692807445408845824) by @random_walker, de la Rouviere [mentioned](https://media.consensys.net/2016/05/05/assert-guards-towards-automated-code-bounties-safe-smart-contract-coding-on-ethereum/) automatic bounties back in May 2016.

Peter Borah [gave](https://medium.com/@peterborah/we-need-fault-tolerant-smart-contracts-ec1b56596dbc#.1j7it3cff) an example of how an automated bug bounty for a specific contract could be created.

Manuel Aráoz [showed another example](https://medium.com/zeppelin-blog/onward-with-ethereum-smart-contract-security-97a827e47702#.o4ckev1rf) of a contract-specific automated bug bounty as a tool in contract security.

Our contribution is to propose a general-purpose, reusable Bounty program that allows contract creators to set up Bounty programs with minimal overhead.



### Protocol Summary
Alice the Author wants to write a contract for general use by Ethereum users, which we'll name `TargetContract`. She is willing to put her money behind its security, and give out an amount of `b` Ether as bounty for anyone who finds a fault in the contract.

After publishing a semi-final draft of `TargetContract`, she involves the community in a collabarative effort to create a test contract, which we'll name `TargetContractTest`. The test contract knows how to to perform multiple checks to see if a given `TargetContract` is in any invalid state. It can also generate &amp; deploy a new copy of `TargetContract` for challenging.


She then registers `TargetContractTest` with the `PutYourMoneyWhereYourContactIs` (`PYMWYCI`) contract, along with a deposit, for a specified period. Any challenger can try and break `TargetContractTest` and win that deposit during that period.

### Detailed Description
#### Contracts Involved
* `TargetContract` is the high stake contract under challenge to find any vulnerabilities in. Written by Alice the Author. It has to adhere to some guidelines (see <a href='#constraints'>Constraints</a>), and should preferably expose as much of its internal state as possible (i.e. providing accessor methods) to be able to efficiently challenge it.
* `PYMWYCI` (Put Your Money Where Your Contract Is, pronounced "*pi-mu-kee*")  is the general contract for bounties, presented in this essay. It registers and manages bounties.
* `ContractEnvironmentInterface` is an abstract contract providing access to environment variables (e.g. `block.number`) for `TargetContract`, and `ContractTestEnvironment` is a concrete descendant that allows a challenger to play with the environment with some restrictions. While a `ContractTestEnvironment` is presented in this work, Alice can choose to add or remove restrictions from it.
* `TargetContractTest` is written by Alice in a collobarative manner together with the community to try and identify any invalid states the contract is in. Examples might include the contract not having the amount of money it "thinks" it has, or a changing number of total tokens in case of a token contract. `TargetContractTest` also has a method for generating &amp; deploying a brand new `TargetContract` for challenging.
* Any number of so-called "attack contracts" by Charlie that help him expose the vulnerability in `TargetContract`.


#### Order of actions
1. Alice publishes `TargetContract` and a draft of `TargetContractTest`. Both, and especially the latter, are up for community inspection for some period of time. Potential challengers, as well as security experts, may suggest additional tests to add to `TargetContractTest`, either formally (see "Future Directions") or informally (through forums etc.).
2. Once that period is over, Alice deploys the final draft of `TargetContractTest` and registers it with the `PutYourMoneyWhereYourContactIs` (`PYMWYCI`) contract, along with the bounty deposit. She also defines a period *p* during which the bounty is open for grabs for anyone who manages to "cheat" the contract.
3. Charlie the Challenger believes he can break `TargetContract` in a way that `TargetContractTest.assertInvalidState()` will return true. He quietly builds up and verifies his strategy offline. When he's ready, he creates in advance the transactions needed to prove `TargetContract`'s vulnerability. He pre-deploys any required attack contracts discretely on the Ethereum production blockchain. He may also play (in any legal way) with `TargetContract`'s environment by pre-creating his own instance of `EnvironmentContractInterface`.
4.  Once done, he formally challenges `TargetContract` by calling `PYMWYCI.challengeContract(TargetContactAddress)` with a deposit of 5% of the bounty sum, and gets back a fresh new copy of `TargetContract`. `PYMWYCI` reserves the `TargetContractTest` bounty only for Charlie for the next 40 blocks (~10 minutes).
5. Charlie fires the transactions he prepared in advance to get `TargetContract` into an invalid state, then calls `PYMWYCI.assertState()`.
6. If successful, the bounty fund in `PYMWYCI` becomes withdrawable by Charlie's. Otherwise, [TBD what happens with Charlie's deposit].

<span id="constraints"></span>
### Constraints for `TargetContract`
* Its contrsuctor should not use `msg.sender`, it should instead be dependency-injected as a parameter (it will be populated with the challenger's address upon creation of a challenge).
* It should not use any of the global variable, but instead use the `EnvironmentContractInterface` (as a library) passed in its constructor to retrieve those. In production, these will simply return the actual variable values. In future, an open source tool would be able to replace any such calls with the direct variables to reduce gas costs.

### Security Aspects
There a few assumptions in this model are that Alice represents a group of people that are `b`-sure that `TargetContract` is flawless (where `b`-sure, formally, is that they're willing to bet `b` Ether on that fact).
TODO(rmerom): complete this section.

### Future Directions
1. Allow testing a system composed of multiple contracts.
2. Allow Challengers to formally suggest new tests for `TargetContract`. The requirement for formal, open suggestion is that even the suggestion might expose vulnerability information to the Author. By formally and openly suggesting new tests, the Author reputation is at stake if she rejects them based on the fact that she realizes they expose a vulnerability.
3. Allow different tests to be associated with different bounty values s.t. more major vulnerabilites will produce higher bounty prizes.
4. Allow a temporal increase of bounty prize (for example, bounty starts at `b/10` and climbs up to `b` Ether). This will allow obvious bugs that were overlooked to be fixed without Alice having to pay the entire bounty amount.

### NOTE: more perliminary code will be uploaded soon
[Environment Contract](https://github.com/rmerom/PutYourMoneyWhereYourContractIs/blob/master/contracts/environment.sol)


