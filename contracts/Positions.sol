// SPDX-License-Identifier: MIT

//Not using 0.8 since the verifiers are generated with 0.6
//TO DO: Check if they can be upgraded to 0.8
pragma solidity ^0.6.11;

import './Verifiers.sol';

contract Positions is SpawnVerifier, MoveVerifier {

    struct Position{
        //How many resources have been exploited in that position 
        //(If it's not a planet, it has no resources, so it will always be 0)
        uint8 exploited_resources;
        //Players in position is used to know if the space is occupied
        uint16 players_in_position;

        //There should be a timestamp for progressive exploitation of the resources
        //Right now we will make instant explotation
    }

    mapping (uint256 => Position) public positions;
    
    //TO DO: This is fine for tracking your own resources
    //But alone doesn't work to show all scores
    //May need to keep a list of players in a later version
    mapping(address => uint32) public player_resources;

    function insert_initial_position(            
            uint[2] memory a,
            uint[2][2] memory b,
            uint[2] memory c,
            uint[1] memory input)
    public{
        require(
            spawnVerifyProof(a,b,c,input),
            "Failed proof check"
        );
        /*
            There should be another require in the future, 
            as to take in account the 5 mins windows.

            It may be needed to store a timestamp along with the position
        */

        require(positions[input[0]].players_in_position == 0, 
            "Position is already occupied");

        require(planet_i(input[0]) == 0, "You can't spawn in a position with a planet");

        //Safe math should be used on the release (or solidity 0.8)
        positions[input[0]].players_in_position++;
    }
    //let specificInstance = await Positions.at("0x3b58A6bFD71e19F6b23978145048962C51a3E3FB");

    // Moves to a new point and returns the amount of resources it has
    // if it's a planet with resources
    // (Or 0 if it's not a planet, which means it has no resources)

    function move_to_new_position(            
        uint[2] memory a,
        uint[2][2] memory b,
        uint[2] memory c,
        uint[2] memory input) 
    public returns(uint8 resources){
        require(
            moveVerifyProof(a,b,c,input),
            "Failed proof check"
        );

        uint8 planet_i = planet_i(input[0]);
        //Resources are collected when leaving the position
        //Right now it collects everything at once
        if(planet_i > 0){
            player_resources[msg.sender] = 
                player_resources[msg.sender] + planet_i - positions[input[0]].exploited_resources;
            positions[input[0]].exploited_resources = planet_i;
        }

        //Safe math should be used on the release (or solidity 0.8)
        positions[input[0]].players_in_position--;
        positions[input[1]].players_in_position++;

        return(planet_i);
    }

    //Returns the max amount of resources on the position
    function planet_i(uint position) internal returns (uint8){
        //This gives 3 / 12 = 1 / 4 chance of a planet
        // 29 30 has a planet, for testing purposes
        uint8 remainder = uint8(position % 12);
        if (remainder < 4){
            return remainder;
        }else{
            return 0;
        }
    }

    function get_my_resources() public view returns (uint32){
        return player_resources[msg.sender];
    }
}