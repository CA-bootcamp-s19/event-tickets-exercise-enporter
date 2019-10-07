pragma solidity ^0.5.0;

    /*
        The EventTicketsV2 contract keeps track of the details and ticket sales of multiple events.
     */
contract EventTicketsV2 {

    /*
        Define an public owner variable. Set it to the creator of the contract when it is initialized.
    */
    address payable public owner;
    uint PRICE_TICKET = 100 wei;

    /*
        Create a variable to keep track of the event ID numbers.
    */
    uint public eventID = 0;
    uint public idGenerator;

    /*
        Define an Event struct, similar to the V1 of this contract.
        The struct has 6 fields: description, website (URL), totalTickets, sales, buyers, and isOpen.
        Choose the appropriate variable type for each field.
        The "buyers" field should keep track of addresses and how many tickets each buyer purchases.
    */
    struct Event {
        string description;
        string website;
        uint totalTickets;
        uint sales;
        mapping (address => uint) buyers;
        bool isOpen;
    }

    /*
        Create a mapping to keep track of the events.
        The mapping key is an integer, the value is an Event struct.
        Call the mapping "events".
    */
    mapping (uint => Event) public events;

    event LogEventAdded(string desc, string url, uint ticketsAvailable, uint eventId);
    event LogBuyTickets(address buyer, uint eventId, uint numTickets);
    event LogGetRefund(address accountRefunded, uint eventId, uint numTickets);
    event LogEndSale(address owner, uint balance, uint eventId);

    /*
        Create a modifier that throws an error if the msg.sender is not the owner.
    */
    modifier verifyOwner() { require (msg.sender == owner); _; }

    constructor() public {
       owner = msg.sender;
    }

    /*
        Define a function called addEvent().
        This function takes 3 parameters, an event description, a URL, and a number of tickets.
        Only the contract owner should be able to call this function.
        In the function:
            - Set the description, URL and ticket number in a new event.
            - set the event to open
            - set an event ID
            - increment the ID
            - emit the appropriate event
            - return the event's ID
    */
    function addEvent(string memory description, string memory website, uint totalTickets)
        public
        verifyOwner
        returns(uint)
    {
        Event memory newEvent;
        newEvent.description = description;
        newEvent.website = website;
        newEvent.totalTickets = totalTickets;
        newEvent.sales = 0;
        newEvent.isOpen = true;

        uint eid = eventID;
        eventID += 1;
        events[eid] = newEvent;

        emit LogEventAdded(description, website, totalTickets, eid);
        return eid;
    }

    /*
        Define a function called readEvent().
        This function takes one parameter, the event ID.
        The function returns information about the event this order:
            1. description
            2. URL
            3. ticket available
            4. sales
            5. isOpen
    */
    function readEvent(uint eid)
        public
        view
        returns(string memory description, string memory website, uint totalTickets, uint sales, bool isOpen)
    {
        Event memory te = events[eid];
        if (te.totalTickets > 0) {
            return (te.description, te.website, te.totalTickets, te.sales, te.isOpen);
        } else {
            revert("Event doesn't exist");
        }
    }

    /*
        Define a function called buyTickets().
        This function allows users to buy tickets for a specific event.
        This function takes 2 parameters, an event ID and a number of tickets.
        The function checks:
            - that the event sales are open
            - that the transaction value is sufficient to purchase the number of tickets
            - that there are enough tickets available to complete the purchase
        The function:
            - increments the purchasers ticket count
            - increments the ticket sale count
            - refunds any surplus value sent
            - emits the appropriate event
    */
    function buyTickets(uint eid, uint numTickets)
        public
        payable
    {
        Event storage te = events[eid];
        require (te.isOpen == true);
        require (te.totalTickets - te.sales >= numTickets);
        require (msg.value >= PRICE_TICKET * numTickets);

        te.buyers[msg.sender] += numTickets;
        te.sales += numTickets;

        uint amountToRefund = msg.value - (PRICE_TICKET * numTickets);
        msg.sender.transfer(amountToRefund);

        emit LogBuyTickets(msg.sender, eid, numTickets);
    }

    /*
        Define a function called getRefund().
        This function allows users to request a refund for a specific event.
        This function takes one parameter, the event ID.
        TODO:
            - check that a user has purchased tickets for the event
            - remove refunded tickets from the sold count
            - send appropriate value to the refund requester
            - emit the appropriate event
    */
    function getRefund(uint eid)
        public
        payable
    {
        Event storage te = events[eid];
        uint ticketsBought = te.buyers[msg.sender];
        require (ticketsBought > 0);

        te.sales -= ticketsBought;
        msg.sender.transfer(PRICE_TICKET * ticketsBought);

        emit LogGetRefund(msg.sender, eid, ticketsBought);
    }

    /*
        Define a function called getBuyerNumberTickets()
        This function takes one parameter, an event ID
        This function returns a uint, the number of tickets that the msg.sender has purchased.
    */
    function getBuyerNumberTickets(uint eid)
        public
        view
        returns(uint)
    {
        return events[eid].buyers[msg.sender];
    }

    function endSale(uint eid)
        public
        verifyOwner
    {
        Event storage te = events[eid];
        te.isOpen = false;
        uint eventBalance = te.sales * PRICE_TICKET;
        msg.sender.transfer(eventBalance);

        emit LogEndSale(msg.sender, eventBalance, eid);
    }
}
