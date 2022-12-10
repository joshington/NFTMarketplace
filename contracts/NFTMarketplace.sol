// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

//INTERNAL IMPORT FOR NFT OPENZIPLINE
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage";
import  "@openzeppelin/contracts/token/ERC721/ERC721.sol";

import "hardhat/console.sol";

contract NFTMarketplace is  ERC721URIStorage {
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIds;
    Counters.Counter private _itmesSold; //tracks how many times token is getting sold

    uint256 listingPrice = 0.0015 ether; //specifying the amount of ether

    address payable owner; //reserving some rights to the owner

    mapping(uint256 => MarketItem) private idMarketItem;
    //every nft will have a unique id, and id will be stored in the idMarketItem
    struct MarketItem {
        uint256 tokenId; //since its a unique id
        address payable seller; //the one creating the nft
        address payable owner;
        uint256 price;
        bool sold;
    }

    //event is triggered on every action in the nft marketplace.
    event idMarketItemCreated (
        uint256 indexed tokenId,
        address seller,
        address owner,
        uint256 price,
        bool sold
    );
    modifier onlyOwner {
        require(
            msg.sender == owner,
            "Only owner of the marketplace can change the listing price"
        );
        _;
    }



    constructor() ERC721("NFT Metaverse Token", "MYNFT"){
        owner == payable(msg.sender); //however will deploy the smartcontract
        //becomes the owner
    }
    //since for fellows to use my nft thy have two pay me some money
    //==so this is for updating my price
    function updateListingPrice(uint256 _listingPrice) public payable onlyOwner{
        //this function should only be called by owner of the smart contract
        //we have to add a modifier since we want only the owner to update the contract
        //so every time someone calls the function the modifier will be called
        listingPrice = _listingPrice;
    }

    function getListingPrice() public view returns (uint256){
        return listingPrice; //making function public so that anyone can caall it
    }
    //let create "CREATE NFT TOKEN FUNCTION
    //tokenURI => is the url of the nft
    function createToken(string memory tokenURI, uin256 price) public payable returns(uint256){
        _tokenIds.increment(); //the token id will get incremented
        uint256 newTokenId = _tokenIds.curent();
        //we are incrementing the token id and getting that token id
        _mint(msg.sender, newTokenId); //we are using _mint function from openzeppelin
        _setTokenURI(newTokenId, tokenURI);

        createMarketItem(newTokenId, price); //creating the nft now on the marketpalce
    }
    //create market items
    function createMarketItem(uint256 tokenId, uint256 price) private {
        require(price > 0, "Price must be atleast 1");
        require(msg.value == listingPrice, "Price must be equal to listing price");

        idMarketItem[tokenId] = MarketItem(
            tokenId,
            payable(msg.sender),
            payable(address(this)), //address means the smart contract
            price,
            false //set the status to false because nft is ot yet sold
        );
        //now we want to transfer the msg.sender(one who created) to the address
        _transfer(msg.sender, address(this), tokenId);

        //the event is now triggered, since the transfer action is triggered
        emit idMarketItemCreated(tokenId, msg.sender, address(this), price, false);
        //make sure u fill the data in the same order as initiated
        //data we need wen someone creates the nft
    }
    //function for resale token, =lets user to resale theier nft
    function reSellToken(uint256 tokenId, uint256 price) public payable {
        //anyone can call the contract, and we use payable because money is included
        require(idMarketItem[tokenId].owner == msg.sender, "only item owner can perform operation");
        //since all the data of the token is getting mapped to idMarketItem
        //if the owner matches the sender then we will let the sale happend

        require(msg.value == listingPrice, "Price must be equal to listing price");
        //since the platform has to make money aswell
        idMarketItem[tokenId].sold = false;
        idMarketItem[tokenId].price = price;
        idMarketItem[tokenId].seller = payable(msg.sender);
        idMarketItem[tokenId].owner=payable(address(this));

        //every time item is sold itemSold is incremented but however  decremented  when resale is
        //done
        _itmesSold.decrement();
        _transfer(msg.sender, address(this), tokenId);
    }
    //function createMarketsale
    function createMarketSale(uint256 tokenId) public payable {
        uint256 price = idMarketItem[tokenId].price;
        //with the above we can get the price of the nft
        require(
            msg.value == price,
            "Please submit asking price inorder to complete the process"
        );
        idMarketItem[tokenId].owner = payable(msg.sender);
        //however is calling the function will become owner of the nft after making the 
        //payment.
        idMarketItem[tokenId].sold = true;
        idMarketItem[tokenId].owner = payable(address(0));

        _itmesSold.increment();//incrementing items sold 
        _transfer(address(this),  msg.sender, tokenId);
        payable(owner).transfer(listingPrice);//we want to get comission since we 
        //are owners of the marketplace
        payable(idMarketItem[tokenId].seller).transfer(msg.value);
        //rest of the money is given the owner of the nft
    }

    //getting unsold nft data
    function fetchMarketItem() public view returns (MarketItem[] memory) {
        uint256 itemCount = _tokenIds.current();
        //gives the number of nfts in our nft marketplace
        uint256 unSoldItemCount = _tokenIds.current() - _itmesSold.current();
        uint256 currentIndex = 0;

        MarketItem[] memory items = new MarketItem[](unSoldItemCount)
        //only want to display the unsold nfts
        for(uint256 i = 0; i<itemCount;++i){
            if(idMarketItem[i + 1].owner == address(this)){
                uint256 currentId = i + 1;
                MarketItem storage currentItem = idMarketItem[currentId];
                items[currentIndex] = currentItem;
                currentIndex += 1;
            }
        }
        return items;
    }
    //purchase item
    function fetchMyNFT() public view returns(MarketItem[] memory) {
        uint256 totalCount = _tokenIds.current();
        uint256 itemCount = 0;
        uint256 currentIndex = 0;
        for(uint256 i = 0; i<totalCount; i++){
            if(idMarketItem[i+1].owner == msg.sender){
                //owner here is the msg.sender
                itemCount += 1;
                //if the above condition is true then we have to update the itemCount
            }
        }
        //after we get the condition right we have to store the NFT somewhere
        MarketItem[] memory items = new MarketItem[](itemCount);
        for(uint256 i = 0; i<totalCount; i++){
            if(idMarketItem[i+1].owner == msg.sender) {
                uint256 currentId = i + 1;
                MarketItem storage currentItem = idMarketItem[currentId];
                items[currentIndex] = currentItem;
                currentIndex += 1;
            }
        }
        return items;
    }
    //single user items
    function fetchItemsListed() public view returns(MarketItem[] memory){
        uint256 totalCount = _tokenIds.current();
        uint256 itemCount = 0;
        uint256 currentIndex = 0;
        
        for(uint256 i =0; i<totalCount; i++) {
            if(idMarketItem[i+1].seller == msg.sender){
                itemCount += 1;
            }
        }
        MarketItem[] memory items = new MarketItem[](itemCount);
        for(uint256 i = 0;i<totalCount; i++){
            if(idMarketItem[i+1].seller == msg.sender){
                uint256 currentId = i+1;

                MarketItem storage currentItem = idMarketItem[currentId];
                items[currentIndex] = currentItem;
                currentIndex += 1;
            }
        }
        return items;
    }
}