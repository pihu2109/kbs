// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;
//importing other contracts from openzeppelin for functions


//this ext. adds support for efficiently enumerating all tokens.
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";

//This extension adds support for storing and retrieving token URIs
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";

//This contract provides a basic implementation of an ownership mechanism
import "@openzeppelin/contracts/access/Ownable.sol";

//This import is a standard contract providing some predefined function that can be called by making ERC721 the child contract of minter contract
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";


contract NFT is ERC721URIStorage, Ownable {
    using Strings for uint256;  //converts uint256 to strings while making token URIs
    uint public constant mx_tok=10000; //maximum supply of NFT collection
    uint private constant rsrv_tok= 5;  //after deployment 5 tokens will be minted to wallet
    uint public cost = 100000000000;  //cost of one token to be minted
    uint256 public constant mx_tok_mint_per_tx = 10;  //maximum tokens that can be minted per transaction
    bool public isSalelive;
    uint256 public ttlsply;
    mapping(address => uint256) private mintedPerWallet; //mapping from address to integer to keep track how many tokens each wallet has minted
    string public baseUri;
    string public baseExt = ".json";



     constructor(address _address)ERC721("NFT", "SYMBOL") Ownable(_address){
    baseUri = "ipfs://xxxxxxxxxxxxxxxxxxxxxxxxxxxxx/";  //base URIs of the NFT
        for(uint256 i = 1; i <= rsrv_tok; ++i) {   //loop for safely minting the reserved tokens right after deplyoment of the contract
            _safeMint(msg.sender, i);   //i is the unique ID of the token
        }
        ttlsply = rsrv_tok;   //initializing total supply of the minted tokens by putting the reserved number of tokens in it, which has been minted in the last loop
    }
    


     // Public or external Functions

     //function to mint the demanded number of tokens
    function mint(uint256 _numTok) external payable {   
        require(isSalelive, "The sale is not live.");    //check if sale is active or not

        require(_numTok <= mx_tok_mint_per_tx, "You cannot mint that many in one transaction.");   //checking if the demanded number off tokens is less than the limit tokens per transaction

        require(ttlsply + _numTok <= mx_tok_mint_per_tx, "You cannot mint that many total.");   //checking if the sum of the number of tokens demanded and already minted reseved tokens is less than or equal to the constraint applied in previous case

        require(ttlsply + _numTok <= mx_tok, "Your demand is exceeding total supply.");    //checking if the sum of the number of tokens demanded and already minted reseved tokens is less than or equal to the maximum tokens available

        require(_numTok * cost <= msg.value, "Insufficient funds.");    //checks whether the total cost of minting tokens is less than or equal to the amount of Ether sent with the transaction

        for(uint256 i = 1; i <= _numTok; ++i) {     //loop for minting tokens and givng them unique IDs
            _safeMint(msg.sender, ttlsply + i);
        }
        mintedPerWallet[msg.sender] += _numTok;  //incrementing the number of previously minted tokens by the newly minted ones
        ttlsply += _numTok;   //same as above but for ttlsply variable
    }

    // Owner-only functions

    //function to toggle the state of the boolean variable isSalelive
    function flipSaleState() external onlyOwner {
        isSalelive = !isSalelive;
    }
     //function to set the URI of the token
    function setBaseUri(string memory _baseUri) external onlyOwner {
        baseUri = _baseUri;
    }
     //function to set the price of the token which is given the modifier to be only owner
    function setPrice(uint256 _cost) external onlyOwner {
        cost = _cost;
    }

    function withdrawAll() external payable onlyOwner {  
        uint256 balance = address(this).balance;   //Retrieves the current balance of the contract  and assigns it to the variable balance

        uint256 balanceOne = balance * 70 / 100;  //calculate 70% and 30% of the balance to be transferred
        uint256 balanceTwo = balance * 30 / 100;
        ( bool transferOne, ) = payable(0x7ceB3cAf7cA83D837F9d04c59f41a92c1dC71C7d).call{value: balanceOne}("");
        ( bool transferTwo, ) = payable(0x7ceB3cAf7cA83D837F9d04c59f41a92c1dC71C7d).call{value: balanceTwo}("");
        require(transferOne && transferTwo, "Transfer failed.");  //checking if both the transaction should be done succesully
    }

    //internal function to get the base URI
    function _baseURI() internal view virtual override returns (string memory) {
        return baseUri;
    }

//function to give unique token id 
       function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {

        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token"); //check if the token id exists or not (i dont know why _exists shows an error even if the ERC721ennumerable extension is used)

        string memory currentBaseURI = _baseURI();  //saves the base URI in temprory memory variable in string form 

        return bytes(currentBaseURI).length>0 ? string(abi.encodePacked(currentBaseURI, tokenId.toString(), baseExt)) : " ";  //checks if the base URI from the last step is valid or not by checking its lenght by converting it into bytes, iff the lenght is greater than 0 then URI is formed by concatenating the base URI, tokenid and base extension ".json", if not then give an empty or void string for URI
    }
 }
