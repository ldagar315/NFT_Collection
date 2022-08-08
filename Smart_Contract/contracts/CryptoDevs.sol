// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./Iwhitelist.sol";

interface IWhitelist {
        function whitelistedAddresses(address) external view returns (bool);
    }

contract CryptoDevs is ERC721Enumerable, Ownable {
     
    //@dev _baseTokenURI for computing {tokenURI}. If set, the resulting URI for each
    //token will be the concatenation of the `baseURI` and the `tokenId`.
    
    string _baseTokenURI ;
    uint256 public maxTokens = 20;       // Maximum no. of tokens that can be minted
    uint256 public tokenID;              // Takes a count of how many tokens have been minted and provides a Unique ID to the NFTs 
    uint256 public _price = 0.01 ether;
    bool public startTimer;                     // Just a counter to keep check whether the sale has started or not
    uint256 public endPresale;
    IWhitelist whitelist ;               // Instance of previous whitelist app

    modifier onlyWhenNotPaused {
        require (!startTimer,"Contract Currently paused" );
        _;
    }

    constructor (string memory baseURI, address whitelistContract) ERC721("Crypto Devs", "CD") {
          _baseTokenURI = baseURI;
          whitelist = IWhitelist(whitelistContract);
      }

    function startPresale() public onlyOwner {
        startTimer = true;
        endPresale = block.timestamp + 5 minutes;
    }
    
    // function to start minting for the white listed user
    function mint() public payable onlyWhenNotPaused {
        // requirements that need to be satisfied before this functions is called

        // The minted tokens are less than 20
        require (tokenID < maxTokens,"Max Token Supply reached");
        // The timer has started and the 5 minutes are not passed since the timer started 
        require (startTimer && block.timestamp < endPresale, "The presale has ended");
        // The address is present in the whitelistedaddress list 
        require (whitelist.whitelistedAddresses(msg.sender),"User was not whitelisted");
        // The amount send by the minter is greater than 0.01 ethers 
        require (msg.value >= _price,"Amount sent not sufficient") ;

        tokenID += 1 ;

        //_safeMint is a safer version of the _mint function as it ensures that
        // if the address being minted to is a contract, then it knows how to deal with ERC721 tokens
        // If the address being minted to is not a contract, it works the same way as _mint
        _safeMint(msg.sender,tokenID) ;
    }

    function public_mint() public payable onlyWhenNotPaused {
        // Same requirements as mentioned in the above function 

        // The minted tokens are less than 20
        require (tokenID < maxTokens);
        // The timer has started and presale timer has ended
        require (startTimer && block.timestamp > endPresale, "The Air Drop has not still not started");
        // The amount of ethers sent is greater than 0.01 
        require (msg.value >= _price,"Amount sent not sufficient") ;

        tokenID += 1 ;

        _safeMint (msg.sender, tokenID);
    }

     function _baseURI() internal view virtual override returns (string memory) {
          return _baseTokenURI;
      }

      function setPaused(bool val) public onlyOwner {
          startTimer = val;
      }

      // This function transfer all the ethers recieved by the contract to the owner of the contract   
      function withdraw() public onlyOwner  {
          address _owner = owner();
          uint256 amount = address(this).balance;
          (bool sent, ) =  _owner.call{value: amount}("");
          require(sent, "Failed to send Ether");
      }

       // Function to receive Ether. msg.data must be empty
      receive() external payable {}

      // Fallback function is called when msg.data is not empty
      fallback() external payable {}
}