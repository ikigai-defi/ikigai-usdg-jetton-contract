import "@stdlib/deploy";
import "@stdlib/ownable";
import "./messages";
import "./jetton_wallet";

struct JettonData {
    totalSupply: Int;
    mintable: Bool;
    owner: Address;
    content: Cell;
    walletCode: Cell;
}

contract JettonMaster with Jetton, Deployable {
    totalSupply: Int as coins;
    owner: Address;
    content: Cell;
    mintable: Bool;

    // max_supply: Int as coins; 

    init(
        owner: Address, 
        content: Cell, 
        // max_supply: Int
    ) {
        self.totalSupply = 0;
        self.owner = owner;
        self.mintable = true;
        self.content = content;

        // self.max_supply = max_supply; // Initial Setting for max_supply
    }

    receive(msg: Mint) {
        let ctx: Context = context();
        require(ctx.sender == self.owner, "Not Owner");
        require(self.mintable, "Can't Mint Anymore");
        self.mint(msg.receiver, msg.amount, self.owner); // (to, amount, response_destination)
    }

    receive(msg: SafeTokenBurn) {
        let ctx: Context = context();
        require(ctx.sender == msg.owner, "Only owner can burn tokens"); // avoid case that the Sender is not the owner
        require(self.totalSupply - msg.amount >= 0, "Invalid total supply after burn");
        self.burn(msg.amount, msg.owner, msg.queryId);
    }

    // receive("Mint: 100") { // Public Minting
    //     let ctx: Context = context();
    //     require(self.mintable, "Can't Mint Anymore");
    //     self.mint(ctx.sender, 100, self.owner);
    // }

    // receive("Owner: MintClose") {
    //     let ctx: Context = context();
    //     require(ctx.sender == self.owner, "Not Owner");
    //     self.mintable = false;
    // }
} 

@interface("org.ton.jetton.master")
trait Jetton with Ownable {

    totalSupply: Int; // Already set initially 
    mintable: Bool;
    owner: Address;
    content: Cell;

    // max_supply: Int; // This is not in the TEP-74 interface

    receive(msg: TokenUpdateContent) {
        self.requireOwner();                // Allow changing content only by owner
        self.content = msg.content;         // Update content
    }

    receive(msg: TokenBurnNotification) {
        self.requireWallet(msg.owner);                     // Check wallet
        self.totalSupply = self.totalSupply - msg.amount; // Update supply

        if (msg.response_destination != null) { // Cashback
            send(SendParameters{
                to: msg.response_destination!!, 
                value: 0,
                bounce: false,
                mode: SendRemainingValue + SendIgnoreErrors,
                body: TokenExcesses{
                    queryId: msg.queryId
                }.toCell()
            });
        }
    }

    // @to The Address receive the Jetton token after minting
    // @amount The amount of Jetton token being minted
    // @response_destination The previous owner address
    fun mint(to: Address, amount: Int, response_destination: Address) {
        // require(self.totalSupply + amount <= self.max_supply, "The total supply will be overlapping.");
        self.totalSupply = self.totalSupply + amount; // Update total supply

        let winit: StateInit = self.getJettonWalletInit(to); // Create message
        send(SendParameters{
            to: contractAddress(winit), 
            value: 0, 
            bounce: false,
            mode: SendRemainingValue,
            body: TokenTransferInternal{ 
                queryId: 0,
                amount: amount,
                from: myAddress(),
                response_destination: response_destination,
                forward_ton_amount: 0,
                forward_payload: emptySlice()
            }.toCell(),
            code: winit.code,
            data: winit.data
        });
    }

    fun burn(burnAmount: Int, to: Address, queryId: Int) {
        // Update total supply
        self.totalSupply = self.totalSupply - burnAmount;
        //Create message
        let winit: StateInit = self.getJettonWalletInit(to);
        let walletAddress: Address = contractAddress(winit);
        // Send a confirmation back to the wallet to finalize the burn
        send(SendParameters{
            to: walletAddress,
            value: 0,
            bounce: false,
            mode: SendRemainingValue,
            body: TokenBurnConfirmation{
                queryId: queryId,
                amount: burnAmount
            }.toCell(),
            code: winit.code,
            data: winit.data
        });
    } 

    fun requireWallet(owner: Address) {
        let ctx: Context = context();
        let winit: StateInit = self.getJettonWalletInit(owner);
        require(contractAddress(winit) == ctx.sender, "Invalid sender");
    }

    virtual fun getJettonWalletInit(address: Address): StateInit {
        return initOf JettonDefaultWallet(myAddress(), address);
    }

    // ====== Get Methods ====== //
    get fun get_jetton_data(): JettonData {
        let code: Cell = self.getJettonWalletInit(myAddress()).code;
        return JettonData{ 
            totalSupply: self.totalSupply, 
            mintable: self.mintable, 
            owner: self.owner, 
            content: self.content, 
            walletCode: code
        };
    }

    get fun get_wallet_address(owner: Address): Address {
        let winit: StateInit = self.getJettonWalletInit(owner);
        return contractAddress(winit);
    }
}
