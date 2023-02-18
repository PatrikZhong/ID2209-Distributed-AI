model CommunicationBetweenAgents

// https://gama-platform.org/wiki/InteractionBetweenAgents

// 'avsluta' auktionen, ska vi typ göra någon close-meddelande?
// en till auktion?

global {
	int numberOfAuctioneers <- 1;
	int numberOfParticipants <- 5;
	init {
		create Auctioneer number: numberOfAuctioneers;
		create Participant number: numberOfParticipants;
				
		loop counter from: 1 to: numberOfParticipants {
        	Participant my_agent <- Participant[counter - 1];
        	my_agent <- my_agent.setName(counter);
        }
	}
}

species Auctioneer skills: [fipa] {
	int itemPrice <- rnd(2000, 10000);
	int itemPriceFloor <- 1999;
	int decreaseItemPriceVariable <- 500;
	message messageFromReceiver;
	bool foundBuyer <- false;
	bool firstRun <- true;
	
	reflex inform_auction_start when: (time = 1) {
		list<Participant> pList;
		loop counter from: 1 to: numberOfParticipants {
        	add Participant[counter - 1] to: pList;
        } 
        write "Informing all participants of auction start";
		do start_conversation (to :: pList, protocol :: 'fipa-contract-net', performative :: 'inform', contents :: ['Starting a new auction'] );
	}
	
	reflex start_bid_cycle when: (time mod 5 = 0) and !foundBuyer and time != 0{
		list<Participant> pList;
		
		if(!firstRun and (itemPrice-decreaseItemPriceVariable) > itemPriceFloor){
			write "new round of auction";
			itemPrice <- itemPrice - decreaseItemPriceVariable;
		} else if ((itemPrice-500) <= itemPriceFloor){
			write "price is lower than floor, " + itemPriceFloor + ", cancelling new auctions";
			foundBuyer <- true; // no new auctions
		}
		
		loop counter from: 1 to: numberOfParticipants {
        	add Participant[counter - 1] to: pList;
        } 
        
        if(!foundBuyer){ // price is too low, so we dont send out any more offers
        	write  "(Time " + string(time) + " ): " + "Auctioneer sends a cfp message to all participants selling for " + itemPrice;
        	do start_conversation (to :: pList, protocol :: 'fipa-contract-net', performative :: 'cfp', contents :: ['Selling for price', itemPrice] );
        }
        
        firstRun <- false;
	}
	
	reflex handle_proposals when: !empty(proposes) and !foundBuyer {
		loop p over: proposes {
			message fromParticipant <- p;
			list contentFromParticipant <- p.contents;
			
			int proposedPrice <- contentFromParticipant[1];
			
			if((proposedPrice >= itemPrice) and !foundBuyer ){ // we have a buyer
				foundBuyer <- true;
				do accept_proposal with: (message: p, contents: ['Accepted price ', itemPrice]);
				
			} else if ((proposedPrice < itemPrice) or foundBuyer ) { // refuse the buyer
				do reject_proposal with: (message: p, contents: ['Rejected price ', proposedPrice]);
			}
		}
	}	
}

species Participant skills: [fipa] {
	int willingPrice <- rnd(1, 8000);
	// int willingPrice <- 5;
	string participantName <- "undefined";
	message messageFromInitiator;
	
	action setName(int num) {
		participantName <- "Participant " + num;
	}
		
	reflex respond_to_cfps when: (!empty(cfps)){
		loop c over: cfps {
			
			message fromAuctioneer <- c;
			list contentFromAuctioneer <- c.contents;
			write  "(Time " + string(time) + " ): " + participantName + " receives a message from auctioneer with content " + string(c.contents);
			write "Willing to buy for " + willingPrice;

			int auctioneerPrice <- contentFromAuctioneer[1];
			
			if(auctioneerPrice > willingPrice){
				write participantName + " rejects " + auctioneerPrice;
			} else {
				write participantName + " accepts " + auctioneerPrice;
			}
			
			do propose with: (message: c, contents: ['Willing to buy for: ', willingPrice]);
		}
	}	
	
	reflex print_rejected when: !empty(reject_proposals) {
		loop r over: reject_proposals {
			write participantName + " has received a reject proposal for: " + string(r.contents);
		}
	}
	
	reflex print_accepted when: !empty(accept_proposals) {
		loop a over: accept_proposals {
			write participantName + " has received an accept proposal for: " + string(a.contents);
			// do inform result message
		}
	}
}

experiment myExperiment type:gui {
	output {
		display myDisplay {
			//species Person aspect:base;
		}
	}
}