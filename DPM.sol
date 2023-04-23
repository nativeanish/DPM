pragma solidity ^0.8.0;

contract PredictionMarket {
    struct Prediction {
        uint outcome; // Outcome index (e.g., 0 for outcome A, 1 for outcome B)
        uint amount; // Amount of prediction token
    }

    mapping (address => Prediction) public predictions; // Mapping to store predictions by address
    uint public totalPredictions; // Total number of predictions
    uint public outcomeCount; // Total number of outcomes
    uint[] public outcomePrices; // Array to store prices of each outcome
    address public owner; // Contract owner
    uint public deadline; // Prediction deadline
    uint public predictionFee; // Prediction fee in wei

    event NewPrediction(address indexed user, uint outcome, uint amount); // Event for new predictions
    event OutcomeResult(uint outcome, uint price); // Event for outcome results
    event PredictionCancelled(address indexed user, uint outcome, uint amount); // Event for cancelled predictions

    constructor(uint _outcomeCount, uint _deadline, uint _predictionFee) {
        owner = msg.sender; // Set contract owner
        outcomeCount = _outcomeCount; // Set outcome count
        outcomePrices = new uint[](outcomeCount); // Initialize outcome prices
        deadline = _deadline; // Set prediction deadline
        predictionFee = _predictionFee; // Set prediction fee
    }

    // Function to make a prediction
    function makePrediction(uint _outcome, uint _amount) public payable {
        require(_outcome < outcomeCount, "Invalid outcome"); // Check for valid outcome
        require(_amount > 0, "Amount must be greater than 0"); // Check for valid amount
        require(msg.value == _amount + predictionFee, "Incorrect amount"); // Check for correct amount sent
        require(block.timestamp < deadline, "Prediction deadline has passed"); // Check if prediction deadline has passed

        Prediction storage prediction = predictions[msg.sender]; // Get prediction by sender
        prediction.outcome = _outcome; // Set outcome
        prediction.amount += _amount; // Add amount to existing prediction

        totalPredictions += 1; // Increase total prediction count

        emit NewPrediction(msg.sender, _outcome, _amount); // Emit event for new prediction
    }

    // Function to cancel a prediction
    function cancelPrediction() public {
        Prediction storage prediction = predictions[msg.sender]; // Get prediction by sender

        require(prediction.outcome < outcomeCount, "No prediction found"); // Check for valid prediction
        require(block.timestamp < deadline, "Prediction deadline has passed"); // Check if prediction deadline has passed

        uint amountToRefund = prediction.amount + predictionFee; // Calculate amount to refund (prediction amount + prediction fee)
        prediction.amount = 0; // Reset prediction amount

        payable(msg.sender).transfer(amountToRefund); // Transfer amount to refund to sender

        emit PredictionCancelled(msg.sender, prediction.outcome, amountToRefund); // Emit event for cancelled prediction
    }

    // Function to resolve outcome
    function resolveOutcome(uint _outcome, uint _price) public {
        require(msg.sender == owner, "Only contract owner can resolve outcome"); // Check for contract owner
        require(_outcome < outcomeCount, "Invalid outcome"); // Check for valid outcome

        outcomePrices[_outcome] = _price; // Set outcome price

        emit OutcomeResult(_outcome, _price); // Emit event for outcome result
    }

    // Function to claim rewards
    function claimRewards() public {
        Prediction storage prediction = predictions[msg.sender]; // Get prediction by sender

        require(prediction.outcome <outcomeCount, "No prediction found"); // Check for valid prediction
        require(outcomePrices[prediction.outcome] > 0, "Outcome not resolved yet"); // Check if outcome is resolved
            uint rewardAmount = prediction.amount * outcomePrices[prediction.outcome]; // Calculate reward amount
        prediction.amount = 0; // Reset prediction amount

        payable(msg.sender).transfer(rewardAmount); // Transfer reward amount to sender

        emit PredictionCancelled(msg.sender, prediction.outcome, rewardAmount); // Emit event for claimed rewards
    }

    // Function to withdraw contract balance
    function withdrawContractBalance() public {
        require(msg.sender == owner, "Only contract owner can withdraw contract balance"); // Check for contract owner

        uint contractBalance = address(this).balance; // Get contract balance

        payable(owner).transfer(contractBalance); // Transfer contract balance to contract owner
    }

    // Function to update prediction fee
    function updatePredictionFee(uint _predictionFee) public {
        require(msg.sender == owner, "Only contract owner can update prediction fee"); // Check for contract owner

        predictionFee = _predictionFee; // Update prediction fee
    }

    // Function to update prediction deadline
    function updatePredictionDeadline(uint _deadline) public {
        require(msg.sender == owner, "Only contract owner can update prediction deadline"); // Check for contract owner

        deadline = _deadline; // Update prediction deadline
    }

    // Function to update outcome prices
    function updateOutcomePrices(uint[] memory _prices) public {
        require(msg.sender == owner, "Only contract owner can update outcome prices"); // Check for contract owner
        require(_prices.length == outcomeCount, "Invalid prices array length"); // Check for valid prices array length

        outcomePrices = _prices; // Update outcome prices
    }
}