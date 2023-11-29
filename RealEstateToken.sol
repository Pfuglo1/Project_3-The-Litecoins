pragma solidity ^0.5.0;
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/release-v2.5.0/contracts/token/ERC20/ERC20.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/release-v2.5.0/contracts/token/ERC20/ERC20Detailed.sol";
contract RealEstateToken is ERC20, ERC20Detailed {
    address public admin;
    mapping(uint => address) public propertyOwners;
    mapping(uint => uint256) public propertyValues;
    uint public nextPropertyId;
    modifier onlyAdmin() {
        require(msg.sender == admin, "Only admin can perform this action");
        _;
    }
    constructor(string memory tok) ERC20Detailed("RealEstateToken", tok, 18) public {
        admin = msg.sender;
    }
    function createProperty(uint256 _value) external onlyAdmin {
        propertyOwners[nextPropertyId] = msg.sender;
        propertyValues[nextPropertyId] = _value;
        nextPropertyId++;
    }
    function mint(uint propertyId, address to, uint256 amount) external onlyAdmin {
        require(propertyOwners[propertyId] == msg.sender, "Only property owner can mint tokens");
        _mint(to, amount);
    }
}
contract RentalAgreement {
    struct Agreement {
        address payable landlord;
        address payable tenant;
        uint rent;
        uint securityDeposit;
        uint leaseStart;
        uint leaseEnd;
        bool isActive;
    }
    Agreement[] public agreements;
    function createAgreement(
        address payable _tenant,
        uint _rent,
        uint _securityDeposit,
        uint _leaseStart,
        uint _leaseEnd
    ) public {
        Agreement memory newAgreement = Agreement({
            landlord: msg.sender,
            tenant: _tenant,
            rent: _rent,
            securityDeposit: _securityDeposit,
            leaseStart: _leaseStart,
            leaseEnd: _leaseEnd,
            isActive: true
        });
        agreements.push(newAgreement);
    }
    function payRent(uint agreementId) external payable {
        Agreement storage agreement = agreements[agreementId];
        require(msg.sender == agreement.tenant, "Only tenant can pay rent");
        require(block.timestamp > agreement.leaseStart && block.timestamp < agreement.leaseEnd, "Lease not active");
        require(msg.value == agreement.rent, "Incorrect rent amount");
        agreement.landlord.transfer(msg.value);
    }
}
contract RealEstateCrowdfunding {
    struct Project {
        uint id;
        uint goal;
        uint raisedAmount;
        uint end;
        bool isFunded;
    }
    RealEstateToken public token;
    address public admin;
    Project[] public projects;
    mapping(uint => mapping(address => uint)) public contributions;
    constructor(address _token) public {
        token = RealEstateToken(_token);
        admin = msg.sender;
    }
    function createProject(uint _goal, uint _duration) public {
        uint projectId = projects.length;
        projects.push(Project({
            id: projectId,
            goal: _goal,
            raisedAmount: 0,
            end: block.timestamp + _duration,
            isFunded: false
        }));
    }
    function contribute(uint projectId) external payable {
        Project storage project = projects[projectId];
        require(block.timestamp < project.end, "Crowdfunding ended");
        contributions[projectId][msg.sender] += msg.value;
        project.raisedAmount += msg.value;
    }
    function withdraw(uint projectId) external {
        Project storage project = projects[projectId];
        require(msg.sender == admin, "Only admin can withdraw");
        require(block.timestamp >= project.end, "Crowdfunding not ended");
        require(project.raisedAmount >= project.goal, "Goal not reached");
        address(uint160(admin)).transfer(address(this).balance);
    }
}