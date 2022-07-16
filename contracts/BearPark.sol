
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "./ERC721Minter.sol";

/*
______                  ______          _    
| ___ \                 | ___ \        | |   
| |_/ / ___  __ _ _ __  | |_/ /_ _ _ __| | __
| ___ \/ _ \/ _` | '__| |  __/ _` | '__| |/ /
| |_/ /  __/ (_| | |    | | | (_| | |  |   < 
\____/ \___|\__,_|_|    \_|  \__,_|_|  |_|\_\                                                                                          

*/

contract BearPark is ERC721Minter {
    constructor() ERC721Minter("Bear Park VIP Pass", "PASS") {}
}