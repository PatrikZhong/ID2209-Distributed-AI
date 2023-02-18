/**
* Name: task1Queens
* Based on the internal empty template. 
* Author: Edvin Walleborn
* Tags: 
*/
model task1Queens

global {
	int numberOfQueens <- 8;
	int N <- 8;
	list queenList;
	
	init {
		create Queen number:numberOfQueens {
			location <- {-5, -5};
		}     
	}
}

grid ChessBoard skills: [fipa] width: N height: N {
    rgb color <- #white;
}

species Queen skills: [fipa] {
	list allowedIndexes <- list_with(N, true);
	int myIndex;
	int myRowPosition;

	
	
	init {
		add self to: queenList;
		myIndex <- length(queenList)-1;
		
		if(length(queenList) = N){
			write queenList;
			write "ready to start";
			
			do start_conversation (to :: list(queenList[0]), protocol :: 'fipa-contract-net', performative :: 'inform', contents :: ['LocateValidPosition', []] );
		}
	}
	
	action locateValidPosition(list contentFromPredecessor, list illegalIndexes) {
		
		write "I am queen: " + myIndex + " , I am on position: " + myRowPosition + " and I have been asked to " + contentFromPredecessor[0];
		write "illegal indexes are: " + illegalIndexes;
		//write "I have received an inform with the information: " + contentFromPredecessor[0];
		
		if(contentFromPredecessor[0] = "LocateValidPosition" and empty(illegalIndexes)){ // första positioneringen
			location <- ChessBoard[0,0].location;
			myRowPosition <- 0;
			add myRowPosition to: illegalIndexes;
			write "I am queen: " + myIndex + " and I have chosen position: " + myRowPosition;
			do start_conversation (to :: list(queenList[1]), protocol :: 'fipa-contract-net', performative :: 'inform', contents :: ['LocateValidPosition', illegalIndexes]);
			
		} else if(!empty(illegalIndexes)){ // alla efterkommande
			//check columnlegality
			loop i from: 0 to: length(illegalIndexes) - 1{
				
				int illegalIndex <- illegalIndexes[i];
				allowedIndexes[illegalIndex] <- false;
			}
			
			//checkDiagonalLegality
			loop i from: 0 to: length(illegalIndexes)-1{
				int predecessorIndex <- illegalIndexes[i];
				
				//på vår föregångarens rad, dens index föregångaren har, minus radavståndet mellan oss
				//write "my predecessor has index: " + predecessorIndex;
				int leftIllegal <- predecessorIndex - (i-myIndex); 
				int rightIllegal <- predecessorIndex + (i-myIndex);
				
				if(leftIllegal > 0 and leftIllegal <= N-1){
					allowedIndexes[leftIllegal] <- false;
				}
				
				if(rightIllegal > 0 and rightIllegal <= N-1){
					allowedIndexes[rightIllegal] <- false;
				}
			}
			
			if(contentFromPredecessor[0] = "Reposition"){
				write "removed my old position: " + myRowPosition + " from the illegal indexes";
				illegalIndexes <- (illegalIndexes - (myRowPosition));
			}
			
			loop i from: 0 to: length(allowedIndexes) - 1{
				//write "I am queen: " + (myIndex) + " any my allowedIndexes are: " + allowedIndexes;
				if(allowedIndexes[i] = true){
					myRowPosition <- i;
					location <- ChessBoard[myRowPosition,myIndex].location;
					add myRowPosition to: illegalIndexes;
					break;
				}
			}	
			write "the updated illegal indexes are: " + illegalIndexes;
			write "my allowed indexes are: " + allowedIndexes;
			
			if(!(allowedIndexes contains true)){ // if there are no eligible spots left
				write "no eligible spots left for me";
				// start_conversation previous_queen repos
				
				if(!(myIndex = 0)){
					allowedIndexes <- list_with(N, true);
					do start_conversation (to :: list(queenList[myIndex-1]), protocol :: 'fipa-contract-net', performative :: 'inform', contents :: ['Reposition', illegalIndexes]);					
				} else {
					write "ERROR - first queen was requested to reposition, but she has no allowed positions left";
				}
				write "===========================================================================";
				
			} else { // if there are eligible spots (I have chosen one of them)
				
				// tell the next queen to proceed with her positioning depending on the illegalIndexes I send (but if im last we're done)
				// start conversation next_queen positioning
				write "I am queen: " + myIndex + " and I have chosen position: " + myRowPosition;
				if(myIndex = length(queenList)-1){ // I'm the last queen
					write "DONE WITH POSITIONING";
				} else {
					if(contentFromPredecessor[0] = "Reposition"){
					}
					do start_conversation (to :: list(queenList[myIndex+1]), protocol :: 'fipa-contract-net', performative :: 'inform', contents :: ['LocateValidPosition', illegalIndexes]);					
				}
				write "===========================================================================";
			}
		}
	}
		
	reflex when: !empty(informs){ //hitta din position
		list contentFromPredecessor <- informs[0].contents;
		list illegalIndexes <- contentFromPredecessor[1];
		
		do locateValidPosition(contentFromPredecessor, illegalIndexes);
		
	}
	
		
		
	aspect base {
		rgb agentColor <- rgb("gold");
		draw triangle(6) color: agentColor;
	}
}

/* Insert your model definition here */
experiment myExperiment type: gui{
    output {
    	display map {
        	grid ChessBoard lines: #black ;
        	species Queen aspect:base;
    	}
    }
}
