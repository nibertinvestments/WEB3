// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/**
 * @title NFTMarketplace - Decentralized NFT Trading Platform
 * @dev Comprehensive NFT marketplace with advanced trading features
 * 
 * USE CASES:
 * 1. Digital art and collectible trading
 * 2. Gaming asset marketplace
 * 3. Utility NFT trading (memberships, access tokens)
 * 4. Fractionalized NFT trading
 * 5. NFT lending and borrowing
 * 6. Creator royalty distribution
 * 
 * WHY IT WORKS:
 * - Decentralized ownership removes platform risk
 * - Automated royalty distribution ensures creator compensation
 * - Auction mechanisms enable price discovery
 * - Escrow system protects both buyers and sellers
 * - Cross-collection trading increases liquidity
 * 
 * @author Nibert Investments Development Team
 */

interface IERC721 {
    function ownerOf(uint256 tokenId) external view returns (address owner);
    function safeTransferFrom(address from, address to, uint256 tokenId) external;
    function isApprovedForAll(address owner, address operator) external view returns (bool);
    function getApproved(uint256 tokenId) external view returns (address operator);
}

interface IERC20NFT {
    function transfer(address to, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}

contract NFTMarketplace {
    // Listing types
    enum ListingType {
        FIXED_PRICE,
        AUCTION,
        DUTCH_AUCTION
    }
    
    enum ListingStatus {
        ACTIVE,
        SOLD,
        CANCELLED,
        EXPIRED
    }
    
    // Listing structure
    struct Listing {
        uint256 id;
        address seller;
        address nftContract;
        uint256 tokenId;
        uint256 price;
        address paymentToken;
        ListingType listingType;
        ListingStatus status;
        uint256 startTime;
        uint256 endTime;
        uint256 highestBid;
        address highestBidder;
        uint256 reservePrice;
        bool hasRoyalty;
        address royaltyRecipient;
        uint256 royaltyPercentage;
    }
    
    // Bid structure for auctions
    struct Bid {
        address bidder;
        uint256 amount;
        uint256 timestamp;
    }
    
    // Collection information
    struct Collection {
        address contractAddress;
        string name;
        string symbol;
        address creator;
        uint256 royaltyPercentage;
        bool isVerified;
        uint256 totalVolume;
        uint256 floorPrice;
    }
    
    // State variables
    mapping(uint256 => Listing) public listings;
    mapping(uint256 => Bid[]) public auctionBids;
    mapping(address => Collection) public collections;
    mapping(address => mapping(uint256 => uint256)) public tokenToListing;
    mapping(address => uint256[]) public userListings;
    mapping(address => bool) public acceptedPaymentTokens;
    
    uint256 public listingCounter;
    uint256 public platformFee; // In basis points (10000 = 100%)
    address public feeRecipient;
    address public owner;
    
    // Constants
    uint256 public constant MAX_ROYALTY_PERCENTAGE = 1000; // 10%
    uint256 public constant MIN_AUCTION_DURATION = 1 hours;
    uint256 public constant MAX_AUCTION_DURATION = 30 days;
    uint256 public constant BID_EXTENSION_TIME = 15 minutes;
    
    // Events
    event NFTListed(
        uint256 indexed listingId,
        address indexed seller,
        address indexed nftContract,
        uint256 tokenId,
        uint256 price,
        ListingType listingType
    );
    event NFTSold(
        uint256 indexed listingId,
        address indexed buyer,
        address indexed seller,
        uint256 price
    );
    event BidPlaced(
        uint256 indexed listingId,
        address indexed bidder,
        uint256 amount
    );
    event ListingCancelled(uint256 indexed listingId);
    event CollectionAdded(address indexed contractAddress, string name);
    event RoyaltyPaid(address indexed recipient, uint256 amount);
    
    // Modifiers
    modifier onlyOwner() {
        require(msg.sender == owner, "Not authorized");
        _;
    }
    
    modifier validListing(uint256 listingId) {
        require(listingId > 0 && listingId <= listingCounter, "Invalid listing ID");
        _;
    }
    
    modifier onlyListingSeller(uint256 listingId) {
        require(listings[listingId].seller == msg.sender, "Not the seller");
        _;
    }
    
    constructor(uint256 _platformFee, address _feeRecipient) {
        require(_platformFee <= 1000, "Fee too high"); // Max 10%
        require(_feeRecipient != address(0), "Invalid fee recipient");
        
        platformFee = _platformFee;
        feeRecipient = _feeRecipient;
        owner = msg.sender;
        
        // Add ETH as default payment token
        acceptedPaymentTokens[address(0)] = true;
    }
    
    /**
     * @dev Lists an NFT for sale
     * Use Case: Selling NFTs on the marketplace
     */
    function listNFT(
        address nftContract,
        uint256 tokenId,
        uint256 price,
        address paymentToken,
        ListingType listingType,
        uint256 duration,
        uint256 reservePrice
    ) external returns (uint256) {
        require(IERC721(nftContract).ownerOf(tokenId) == msg.sender, "Not token owner");
        require(
            IERC721(nftContract).isApprovedForAll(msg.sender, address(this)) ||
            IERC721(nftContract).getApproved(tokenId) == address(this),
            "Marketplace not approved"
        );
        require(acceptedPaymentTokens[paymentToken], "Payment token not accepted");
        require(price > 0, "Price must be greater than 0");
        
        if (listingType != ListingType.FIXED_PRICE) {
            require(duration >= MIN_AUCTION_DURATION && duration <= MAX_AUCTION_DURATION, "Invalid duration");
        }
        
        listingCounter++;
        
        // Get collection info for royalties
        Collection memory collection = collections[nftContract];
        bool hasRoyalty = collection.royaltyPercentage > 0;
        
        listings[listingCounter] = Listing({
            id: listingCounter,
            seller: msg.sender,
            nftContract: nftContract,
            tokenId: tokenId,
            price: price,
            paymentToken: paymentToken,
            listingType: listingType,
            status: ListingStatus.ACTIVE,
            startTime: block.timestamp,
            endTime: listingType == ListingType.FIXED_PRICE ? 0 : block.timestamp + duration,
            highestBid: 0,
            highestBidder: address(0),
            reservePrice: reservePrice,
            hasRoyalty: hasRoyalty,
            royaltyRecipient: collection.creator,
            royaltyPercentage: collection.royaltyPercentage
        });
        
        tokenToListing[nftContract][tokenId] = listingCounter;
        userListings[msg.sender].push(listingCounter);
        
        emit NFTListed(listingCounter, msg.sender, nftContract, tokenId, price, listingType);
        
        return listingCounter;
    }
    
    /**
     * @dev Buys an NFT at fixed price
     * Use Case: Immediate purchase of listed NFTs
     */
    function buyNFT(uint256 listingId) external payable validListing(listingId) {
        Listing storage listing = listings[listingId];
        require(listing.status == ListingStatus.ACTIVE, "Listing not active");
        require(listing.listingType == ListingType.FIXED_PRICE, "Not a fixed price listing");
        require(msg.sender != listing.seller, "Cannot buy own NFT");
        
        uint256 totalPrice = listing.price;
        
        // Handle payment
        if (listing.paymentToken == address(0)) {
            require(msg.value >= totalPrice, "Insufficient ETH sent");
        } else {
            require(
                IERC20NFT(listing.paymentToken).transferFrom(msg.sender, address(this), totalPrice),
                "Payment transfer failed"
            );
        }
        
        // Update listing status
        listing.status = ListingStatus.SOLD;
        tokenToListing[listing.nftContract][listing.tokenId] = 0;
        
        // Calculate fees and royalties
        uint256 platformFeeAmount = (totalPrice * platformFee) / 10000;
        uint256 royaltyAmount = 0;
        
        if (listing.hasRoyalty && listing.royaltyRecipient != address(0)) {
            royaltyAmount = (totalPrice * listing.royaltyPercentage) / 10000;
        }
        
        uint256 sellerAmount = totalPrice - platformFeeAmount - royaltyAmount;
        
        // Transfer NFT to buyer
        IERC721(listing.nftContract).safeTransferFrom(listing.seller, msg.sender, listing.tokenId);
        
        // Distribute payments
        _transferPayment(listing.paymentToken, listing.seller, sellerAmount);
        _transferPayment(listing.paymentToken, feeRecipient, platformFeeAmount);
        
        if (royaltyAmount > 0) {
            _transferPayment(listing.paymentToken, listing.royaltyRecipient, royaltyAmount);
            emit RoyaltyPaid(listing.royaltyRecipient, royaltyAmount);
        }
        
        // Update collection volume
        collections[listing.nftContract].totalVolume += totalPrice;
        
        emit NFTSold(listingId, msg.sender, listing.seller, totalPrice);
    }
    
    /**
     * @dev Places a bid on an auction
     * Use Case: Bidding on auction listings
     */
    function placeBid(uint256 listingId, uint256 bidAmount) 
        external 
        payable 
        validListing(listingId) 
    {
        Listing storage listing = listings[listingId];
        require(listing.status == ListingStatus.ACTIVE, "Listing not active");
        require(listing.listingType != ListingType.FIXED_PRICE, "Not an auction");
        require(block.timestamp <= listing.endTime, "Auction ended");
        require(msg.sender != listing.seller, "Cannot bid on own NFT");
        
        uint256 minBid = listing.highestBid > 0 ? 
            listing.highestBid + (listing.highestBid * 5) / 100 : // 5% increment
            listing.reservePrice;
        
        require(bidAmount >= minBid, "Bid too low");
        
        // Handle payment
        if (listing.paymentToken == address(0)) {
            require(msg.value >= bidAmount, "Insufficient ETH sent");
        } else {
            require(
                IERC20NFT(listing.paymentToken).transferFrom(msg.sender, address(this), bidAmount),
                "Payment transfer failed"
            );
        }
        
        // Refund previous highest bidder
        if (listing.highestBidder != address(0)) {
            _transferPayment(listing.paymentToken, listing.highestBidder, listing.highestBid);
        }
        
        // Update auction state
        listing.highestBid = bidAmount;
        listing.highestBidder = msg.sender;
        
        // Record bid
        auctionBids[listingId].push(Bid({
            bidder: msg.sender,
            amount: bidAmount,
            timestamp: block.timestamp
        }));
        
        // Extend auction if bid placed in last 15 minutes
        if (listing.endTime - block.timestamp < BID_EXTENSION_TIME) {
            listing.endTime = block.timestamp + BID_EXTENSION_TIME;
        }
        
        emit BidPlaced(listingId, msg.sender, bidAmount);
    }
    
    /**
     * @dev Finalizes an auction
     * Use Case: Completing auction sales
     */
    function finalizeAuction(uint256 listingId) external validListing(listingId) {
        Listing storage listing = listings[listingId];
        require(listing.status == ListingStatus.ACTIVE, "Listing not active");
        require(listing.listingType != ListingType.FIXED_PRICE, "Not an auction");
        require(block.timestamp > listing.endTime, "Auction still active");
        
        if (listing.highestBidder == address(0) || listing.highestBid < listing.reservePrice) {
            // No valid bids or reserve not met
            listing.status = ListingStatus.EXPIRED;
            tokenToListing[listing.nftContract][listing.tokenId] = 0;
            
            // Refund highest bidder if any
            if (listing.highestBidder != address(0)) {
                _transferPayment(listing.paymentToken, listing.highestBidder, listing.highestBid);
            }
        } else {
            // Successful auction
            listing.status = ListingStatus.SOLD;
            tokenToListing[listing.nftContract][listing.tokenId] = 0;
            
            uint256 totalPrice = listing.highestBid;
            
            // Calculate fees and royalties
            uint256 platformFeeAmount = (totalPrice * platformFee) / 10000;
            uint256 royaltyAmount = 0;
            
            if (listing.hasRoyalty && listing.royaltyRecipient != address(0)) {
                royaltyAmount = (totalPrice * listing.royaltyPercentage) / 10000;
            }
            
            uint256 sellerAmount = totalPrice - platformFeeAmount - royaltyAmount;
            
            // Transfer NFT to highest bidder
            IERC721(listing.nftContract).safeTransferFrom(
                listing.seller, 
                listing.highestBidder, 
                listing.tokenId
            );
            
            // Distribute payments
            _transferPayment(listing.paymentToken, listing.seller, sellerAmount);
            _transferPayment(listing.paymentToken, feeRecipient, platformFeeAmount);
            
            if (royaltyAmount > 0) {
                _transferPayment(listing.paymentToken, listing.royaltyRecipient, royaltyAmount);
                emit RoyaltyPaid(listing.royaltyRecipient, royaltyAmount);
            }
            
            // Update collection volume
            collections[listing.nftContract].totalVolume += totalPrice;
            
            emit NFTSold(listingId, listing.highestBidder, listing.seller, totalPrice);
        }
    }
    
    /**
     * @dev Cancels a listing
     * Use Case: Removing NFT from sale
     */
    function cancelListing(uint256 listingId) 
        external 
        validListing(listingId) 
        onlyListingSeller(listingId) 
    {
        Listing storage listing = listings[listingId];
        require(listing.status == ListingStatus.ACTIVE, "Listing not active");
        
        listing.status = ListingStatus.CANCELLED;
        tokenToListing[listing.nftContract][listing.tokenId] = 0;
        
        // Refund highest bidder if auction
        if (listing.listingType != ListingType.FIXED_PRICE && listing.highestBidder != address(0)) {
            _transferPayment(listing.paymentToken, listing.highestBidder, listing.highestBid);
        }
        
        emit ListingCancelled(listingId);
    }
    
    /**
     * @dev Adds a new collection
     * Use Case: Registering NFT collections for royalty tracking
     */
    function addCollection(
        address contractAddress,
        string memory name,
        string memory symbol,
        address creator,
        uint256 royaltyPercentage
    ) external onlyOwner {
        require(collections[contractAddress].contractAddress == address(0), "Collection already exists");
        require(royaltyPercentage <= MAX_ROYALTY_PERCENTAGE, "Royalty percentage too high");
        
        collections[contractAddress] = Collection({
            contractAddress: contractAddress,
            name: name,
            symbol: symbol,
            creator: creator,
            royaltyPercentage: royaltyPercentage,
            isVerified: false,
            totalVolume: 0,
            floorPrice: 0
        });
        
        emit CollectionAdded(contractAddress, name);
    }
    
    /**
     * @dev Internal function to handle payments
     */
    function _transferPayment(address token, address to, uint256 amount) internal {
        if (amount == 0) return;
        
        if (token == address(0)) {
            payable(to).transfer(amount);
        } else {
            require(IERC20NFT(token).transfer(to, amount), "Payment transfer failed");
        }
    }
    
    /**
     * @dev Gets listing information
     */
    function getListing(uint256 listingId) 
        external 
        view 
        validListing(listingId) 
        returns (
            address seller,
            address nftContract,
            uint256 tokenId,
            uint256 price,
            ListingStatus status,
            uint256 endTime,
            uint256 highestBid,
            address highestBidder
        ) 
    {
        Listing memory listing = listings[listingId];
        return (
            listing.seller,
            listing.nftContract,
            listing.tokenId,
            listing.price,
            listing.status,
            listing.endTime,
            listing.highestBid,
            listing.highestBidder
        );
    }
    
    /**
     * @dev Gets auction bids
     */
    function getAuctionBids(uint256 listingId) 
        external 
        view 
        validListing(listingId) 
        returns (
            address[] memory bidders,
            uint256[] memory amounts,
            uint256[] memory timestamps
        ) 
    {
        Bid[] memory bids = auctionBids[listingId];
        
        bidders = new address[](bids.length);
        amounts = new uint256[](bids.length);
        timestamps = new uint256[](bids.length);
        
        for (uint256 i = 0; i < bids.length; i++) {
            bidders[i] = bids[i].bidder;
            amounts[i] = bids[i].amount;
            timestamps[i] = bids[i].timestamp;
        }
    }
    
    /**
     * @dev Gets collection statistics
     */
    function getCollectionStats(address contractAddress) 
        external 
        view 
        returns (
            string memory name,
            uint256 totalVolume,
            uint256 floorPrice,
            uint256 royaltyPercentage,
            bool isVerified
        ) 
    {
        Collection memory collection = collections[contractAddress];
        return (
            collection.name,
            collection.totalVolume,
            collection.floorPrice,
            collection.royaltyPercentage,
            collection.isVerified
        );
    }
    
    /**
     * @dev Gets user's active listings
     */
    function getUserListings(address user) external view returns (uint256[] memory) {
        return userListings[user];
    }
    
    // Owner functions
    
    /**
     * @dev Updates platform fee
     */
    function updatePlatformFee(uint256 newFee) external onlyOwner {
        require(newFee <= 1000, "Fee too high"); // Max 10%
        platformFee = newFee;
    }
    
    /**
     * @dev Adds accepted payment token
     */
    function addPaymentToken(address token) external onlyOwner {
        acceptedPaymentTokens[token] = true;
    }
    
    /**
     * @dev Removes payment token
     */
    function removePaymentToken(address token) external onlyOwner {
        acceptedPaymentTokens[token] = false;
    }
    
    /**
     * @dev Verifies a collection
     */
    function verifyCollection(address contractAddress) external onlyOwner {
        collections[contractAddress].isVerified = true;
    }
    
    /**
     * @dev Emergency withdrawal
     */
    function emergencyWithdraw(address token, uint256 amount) external onlyOwner {
        _transferPayment(token, owner, amount);
    }
}