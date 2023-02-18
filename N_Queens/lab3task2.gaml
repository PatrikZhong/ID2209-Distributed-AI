
model lab3task2

global {
	
	//TODO
	//chooseStage är buggad, väljer alltid stage(0) D: 
	//bygg in så att stages ändrar på sina preferenser så att de rör på sig igen
	
	int numberOfPeople <- 30;
//	int numberOfStages <- 1;
	int distanceThreshold <- 2;
	list<Stage> stageIndex;
	
	init {
		create Guest number:numberOfPeople;

		
		create Stage number:1{
			location <- {50,25};
			agentColor <- rgb("red");
			add self to: stageIndex;
		
		}
		
		create Stage number:1{
			location <- {25,50};
			agentColor <- rgb("yellow");
			add self to: stageIndex;
		
		}
		
		create Stage number:1{
			location <- {50,50};
			agentColor <- rgb("black");
			add self to: stageIndex;
			
		
		}
		
		create Stage number:1{
			location <- {25,25};
			agentColor <- rgb("blue");
			add self to: stageIndex;
			
		
		}
	
		
	}
	
	
}

species Guest skills: [moving, fipa] {
	
	int lightPref;
	int musicPref;
	int crowdPref;
	int bandPref;
	int moshpitPref;
	int dancePref;
	point targetPoint <- nil;
	list<int> prefList;
	list<list<int>> stageUtilities;
	bool updateFlag <- false;
	
	string guestName <- "Undefined";
	  init {
		
			
		lightPref <- rnd(0, 100);
		musicPref <- rnd(0, 100);
		crowdPref <- rnd(0, 100);
		bandPref <- rnd(0, 100);
		moshpitPref <- rnd(0, 100);
		dancePref <- rnd(0, 100);
		prefList <- [lightPref, musicPref, crowdPref, bandPref, moshpitPref, dancePref];
		write name + "preferences are: " + prefList;
		
	
    }
	
	
	action setName(int num) {
		guestName <- "Guest " + num;
	}
	
	aspect base {
		rgb agentColor <- rgb("green");
		

		draw circle(1) color: agentColor;
	}
	

	
	reflex checkStages when:  time = 1 or (time mod 101 = 0) {
		
		do start_conversation with:(list(Stage), protocol:: 'fipa-request', performative:: 'inform', contents:: ['utility?']);
		write name + " is asking the stages the values they have";
		
	}
	
	reflex receiveUtilityVal when: !empty(informs){
		loop msg over: informs{
			//ta ut info här
			list contents <- msg.contents;
			list utilityList <- contents[0];
//			write name + "has received the following utilities: " + utilityList;
//			write "=============================================";
			add utilityList to: stageUtilities;
			updateFlag <- true;
		
		}
	}
	
	reflex chooseStage when: updateFlag{
//		write "the stages are: " + stageIndex;
		int max <- 0;
		int maxIndex <- 0;
			
		loop i from: 0 to: length(stageUtilities) -1{
			int utilityTot <- 0;
			list getStageUtility <- stageUtilities[i];
						
				loop j from: 0 to: length(getStageUtility) -1{
					utilityTot <- utilityTot + (getStageUtility[j]*prefList[j]);
					
				
					if(utilityTot > max){
						maxIndex <- i;
						max <- utilityTot;
					}	
			}
			write name + " thinks the utility for stage " + i + " is " + utilityTot;
			
			
		}		
		updateFlag <- false;			
		write "I am walking to " + stageIndex[maxIndex] + " with the value of " + max;
		write "=================================================";
		targetPoint <- stageIndex[maxIndex].location;
		stageUtilities <- nil;
		
	}
	
	reflex moveToTarget when: targetPoint != nil{
		do goto target:targetPoint;
	}
	
}

species Stage skills: [fipa] {
	string storeName <- "Undefined";
	rgb agentColor;
	int light;
	int music;
	int crowd;
	int band;
	int mosh;
	int dance;
	list stagePrefList;
	

	
	reflex assignStageValues when: time mod 100 = 0  {
		light <- rnd(0, 100);
		music <- rnd(0, 100);
		crowd <- rnd(0, 100);
		band <- rnd(0, 100);
		mosh <- rnd(0, 100);
		dance <- rnd(0, 100);
		stagePrefList <- [light, music, crowd, band, mosh, dance];
		write name + ": my values are: " + stagePrefList;
		
	}
	
	reflex sendUtilityVal when: !empty(informs){
		write name + ": sending values";
		loop msg over: informs{
			do inform with:(message: msg, contents: [stagePrefList]);
		}
		write stagePrefList;
		
	}

	
	action setName(int num) {
		storeName <- "Store " + num;
	}
	
	aspect base {
		
		draw square(2) color: agentColor;
	}
}



experiment my_experiment type:gui {
	output {
		display myDisplay {
			species Guest aspect:base;
			species Stage aspect:base;
		}
	}
}