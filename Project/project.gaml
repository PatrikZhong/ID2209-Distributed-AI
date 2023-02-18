/**
* Name: project
* Based on the internal empty template. 
* Author: Patrik Zhong
* Tags: 
*/


model project

global {

	bool pauseflag <- false;
	int numberOfStudents <- 15;
	int numberOfTeachers <- 1;
	int distanceThreshold <- 2;
	list<Guest> gryffindorList;
	list<DuelingStage> duelingStageList;
	list<string> studentHouses <- ["Gryffindor", "Hufflepuff", "Ravenclaw", "Slytherin"];
	list<int> studentHousePoints <- [0,0,0,0];
	list<Guest> studentList;
	list<Workshop> classroomList;
	int Gryffindor;
	int	Hufflepuff;
	int Ravenclaw;
	int Slytherin;
	
	int slytherinCaughtCounter;

	
	init {

		create Teacher number: numberOfTeachers;		
                     
          loop counter from: 1 to: numberOfTeachers {
            Teacher my_agent <- Teacher[counter - 1];
            my_agent <- my_agent.setName(counter);
        } 
        
        //Gryff
        create Guest number:15{
        	myHome <- "Gryffindor"; 
        	add self to: gryffindorList;
        	       	
        }
          loop counter from: 1 to: 15 {
            Guest my_agent <- Guest[counter - 1];
            my_agent <- my_agent.setName(counter);
        }    
        //Huffle
        create Guest number:15{
        	myHome <- "Hufflepuff";        	
        }
          loop counter from: 16 to: 30 {
            Guest my_agent <- Guest[counter - 1];
            my_agent <- my_agent.setName(counter);
        }
        
        //Ravenclaw
         create Guest number:15{
        	myHome <- "Ravenclaw";        	
        }
          loop counter from: 31 to: 45 {
            Guest my_agent <- Guest[counter - 1];
            my_agent <- my_agent.setName(counter);
        }
        
        //Slytherin
         create Guest number:15{
        	myHome <- "Slytherin";        	
        }
          loop counter from: 46 to: 60 {
            Guest my_agent <- Guest[counter - 1];
            my_agent <- my_agent.setName(counter);
        }       
         
        
        create Workshop number:1{
			location <- {80,25};
			agentColor <- rgb("silver");
		
		}
//		create Classroom number:1{
//			location <- {25,50};
//			agentColor <- rgb("silver");
//		
//		}
		create DuelingStage number:1{
			location <- {52,70};
			agentColor <- rgb("purple");		

		}
		
		create DuelingStage number:1{
			location <- {25,25};
			agentColor <- rgb("purple");			

		}
		
			
	
	}
reflex pausing when: pauseflag{
			
			pauseflag <- false;
			do pause;
	}
	
	reflex updateValues{ //used for updating our graphs
		Gryffindor <- studentHousePoints[0];
		Hufflepuff <- studentHousePoints[1];
		Ravenclaw <- studentHousePoints[2];
		Slytherin <- studentHousePoints[3];
	}
	
}

//4 types of guests, Gryffindor, Hufflepuff, Ravenclaw, Slytherin
species Guest skills: [moving, fipa]{
	float speed <- 2;
	string studentName <- "undefined";	
	point target <- nil;
	bool busy <- false; //a flag that determines if someone is currently doing something or not
	bool illegalDuels <- false;
	Guest currentOpponent;
	bool isStudying <- false;
	
	
	string myHome;
	
	//the main personal attributes used for a guest.
	int finesse <- rnd(0, 100);
	int motivation <- 50;
	int hostility <- 40;
	//attribute specific for slytherin
	int sneak <- rnd(3, 8);
	
	action setName(int num) {
       studentName <- "Student " + num;
    }
    
    init{
    	add self to: studentList; 
    	//ravenclaws are very motivated
    	if(myHome = "Ravenclaw"){
			motivation <- motivation + 50;
		}  
		
//		if(myHome = "Gryffindor"){
//			add self to: gryffindorList;
//		}
		
	
    }
    
    aspect base {
        rgb agentColor <- rgb("firebrick");
       	
       	if(illegalDuels){ //if the slytherin is caught
       		agentColor <- rgb("salmon");
       	}
       	else if(isStudying){ //if theyre going to study
       		agentColor <- rgb("deeppink");
       	}
       	else if(busy){
       		agentColor <- rgb("cyan");
       	}
       	
        else if(myHome = "Gryffindor"){
        	 agentColor <- rgb("firebrick");        	
        }
        else if(myHome = "Hufflepuff"){
        	agentColor <- rgb("goldenrod");
        	
        }
        else if(myHome = "Ravenclaw"){
        	agentColor <- rgb("darkblue");
        	
        }
        else if(myHome = "Slytherin"){
        	agentColor <- rgb("darkgreen");
        	
        }
        draw circle(1) color: agentColor;
    }
    //we increase hostility to make sure duels happen. They initialy start with a rather low hostility to make sure they dont duel each other immedietly.
    reflex increaseHostility{
    	if(flip(0.005)){
    		hostility <- hostility + rnd(0, 10);
    	}
    }    
    //decrease hostility with nearby students if your own hostility is low. (otherwise increase own hostility)    
    reflex Hufflepuffing when: myHome = "Hufflepuff" and !busy{
    	ask Guest at_distance distanceThreshold{
    		if(flip(0.0005) and hostility < 10 ){
    			self.hostility <- 0;    			
    			write "I am Hufflepuff " + myself + " and I am calming down this person:" + self + "| HOSTILITY IS NOW " + self.hostility;
   			
    		}
    	}
    }    
    //increases the hostility of other gryffindor guests if the guests loses in a duel and belongs to gryffindor.
    action Gryffindoring{   	
    		
    		//The gryffindors propose that they become more hostile.
    	  do start_conversation with:(gryffindorList, protocol:: 'fipa-request', performative:: 'propose', contents:: ["lost"]);
    			write "I am Gryffindor " + self + " and i am increasing the hostility of my fellows to avenge my loss."; 
    			 		

    }
    //proposes that they increase hostility
    reflex aCallToArms when: !empty(proposes){
    	loop msg over: proposes{
			//ta ut info här
			list contents <- msg.contents;
			string messages <- contents[0];			
			
				if(messages = "lost"){
					hostility <- hostility + 5;	
				}			
		}
	
	}
	
	//steals from other guests, if they are caught based on their "sneak" value a teacher is alerted to reprimand and dock points from the guest. 
    reflex Slythering when: myHome = "Slytherin" and !busy and target = nil{    	
    	Guest temp;  	
    	
			//deciding to steal
    		if(flip(0.005) and hostility > 10){  			 	
    			ask Guest at_distance distanceThreshold{
    				//found a target that isnt my own home /slytherin)
    				if(self.myHome != myself.myHome){
    					temp <- self;    					   			
    				}		
    			}
    			 		 	  			
    		}
    	
    	//if there's a teacher nearby and I have decided to steal
    	if(!empty(Teacher at_distance sneak) and temp != nil){
    		illegalDuels <- true;
    		
    		write "TEACHER ALERTED"; 
    		
    		ask Teacher at_distance sneak{
    			do alert(myself);
    			
    		}
    		slytherinCaughtCounter <- slytherinCaughtCounter + 1;	
    	}
    	//no teacher nearby, I have a target to steal from
    	else if(temp != nil){ 
    		studentHousePoints[3] <- studentHousePoints[3] + 3; 
    		write "****************************************************************";
    		write "I am Slytherin " + self + "and I am stealing points";
			loop i from: 0 to: 3{
  				if(studentHouses[i] = temp.myHome){
  					studentHousePoints[i] <- studentHousePoints[i]-1;
  				}				
  			}
  			busy <- true;    		
    	}
    }
    
    //If they find other motivated students nearby, they walk together to study at a workshop. 
    reflex Ravenclawing when: myHome = "Ravenclaw" and !busy and target = nil{
    	ask Guest at_distance 2{
    		if(flip(0.0025) and myself.motivation > 40 and self.motivation > 40 and !self.busy and self.target = nil){
    			self.isStudying <- true;
    			myself.isStudying <- true;
    			myself.target <- (Workshop closest_to(self)).location;
    			self.target <- (Workshop closest_to(self)).location;
    			write "I am Ravenclaw  " + myself + " and I am increasing the motivation of  " + self; 
    			
    			
    		}
    	}
    }
    
    //guests will search out an opponent if their hostility is high enough. They will only search for other houses and not duel themselves.
    reflex searchOpponent when: target = nil{
    	ask Guest at_distance distanceThreshold{    		
    		if(!myself.busy and !self.busy and (self.hostility > 50 and myself.hostility > 50) and myself.myHome != self.myHome and !myself.isStudying and !self.isStudying){  
    			self.target <- (duelingStageList closest_to(self)).location;
    			myself.target <- (duelingStageList closest_to(self)).location;
    			myself.currentOpponent <- self;
    			self.currentOpponent <- myself;    			
    			myself.busy <- true;
    			self.busy <- true;  
    			write "A duel is starting between " + self + " and " + myself; 	
		
    		}
    		    		
    	}
    }
    
    //The duel that takes place on the dueling stage. Based on their finesse, different things happen. If they lose due to low finesse, they will lose some points and the others will gain.    
    reflex duel when: currentOpponent != nil and !empty(DuelingStage at_distance(distanceThreshold)) and busy{    	
    	if(finesse + 30 < currentOpponent.finesse ){
    			write " " + self + " is surrendering, difference is too big. I will go to the workshop to learn more and become stronger.";
    			isStudying <- true;    			
    	}    	
    	else if(finesse > currentOpponent.finesse){ //if I am winning 		
    		write "I am " + self + ", and I belong to:" + self.myHome + " .I have won over" + currentOpponent + ", who belongs to " + currentOpponent.myHome;
			hostility <- 0;
			currentOpponent.hostility <- currentOpponent.hostility + 10;
			
    		   		
  			loop i from: 0 to: 3{
  				if(studentHouses[i] = myHome){
  					studentHousePoints[i] <- studentHousePoints[i] + 5;
  				}
  				else if(studentHouses[i] = currentOpponent.myHome){
  					studentHousePoints[i] <- studentHousePoints[i] -5;
  					
  				}  				
  			} 
  			   		
    	}
    	else{
    		write "I am " + self + ", and I belong to:" + self.myHome + " .I have lost to " + currentOpponent + ", who belongs to " + currentOpponent.myHome;

    		hostility <- hostility +10;
    		currentOpponent.hostility <- 0;
    		loop i from: 0 to: 3{
    			
  				if(studentHouses[i] = currentOpponent.myHome){
  					studentHousePoints[i] <- studentHousePoints[i] + 5;
  				}
  				else if(studentHouses[i] = myHome){
  					studentHousePoints[i] <- studentHousePoints[i] -5;
  					
  				}   				
  			} 
  			//if we lose and we belong to gryffindor, make a call to arms. 
  			if(myHome = "Gryffindor"){
  				do Gryffindoring;
  			}
    		
    	}
    	currentOpponent.target <- nil;
    	currentOpponent.currentOpponent <- nil;
    	currentOpponent <- nil;
    	if(isStudying){
    		target <- (Workshop closest_to(self)).location;
    	}
    	else{
    		target <- nil;
    	}
    	  
    		   	
    	
    }
    //after they've done something, such as duel, they are set as busy. This is the global cooldown manager that sets them as not busy after a while.
    reflex setBusy when: busy and target = nil{
    	if(flip(0.01)){ //modifiera 
    		busy <- false;    		
    	}
    }
    
    //Moves to classroom when informed of the start of a workshop. Only moves if their motivation is high enough.
    reflex classHandler when: !empty(informs) and !busy {
    	loop msg over: informs{
			//ta ut info här
			list contents <- msg.contents;
			string messages <- contents[0];
			
			
				if(messages = "Class is starting" and motivation > 30){
					self.target <- (classroomList closest_to(self)).location;	
				}
				else{
					target <- nil;
				}		
			}
		}
//  destroy target
    
    reflex move when: target = nil{
    	do wander;
    }
    reflex moveToTarget when: target != nil{
		do goto target:target;
		if(isStudying and !empty(Workshop at_distance(distanceThreshold))){
			target <- nil;
			isStudying <- false;
			motivation <- motivation +5;
			finesse <- finesse + 2;
			write "I have arrived at the classroom and I have gained some motivation and finesse";
			
		}
	}
	
	
}


species Teacher skills: [moving, fipa]{
	string teacherName <- "undefined";
	bool feelingLikeIt <- false;
	bool classInSession;
	float speed <- 2;
	point target;
	int workshopTime;
	Guest targetGuest;
	
	//The attributes of teacher
	int determination <-0; //determines when they start up a workshop.
	int spite <- 0; //determines when they want to dock points.
	string favouriteHouse <- one_of(studentHouses); //determines if theyre not going to dock points, because theyre playing favourites.
	
	
	
	action setName(int num) {
        teacherName <- "Teacher " + num;
    }
    
    action alert(Guest guest){
    	targetGuest <- guest;
    	
    }
    reflex chaseTarget when: targetGuest != nil{
    	target <- targetGuest.location;
    }
    
    reflex punishGuest{
    	ask Guest at_distance distanceThreshold{
    		if(myself.targetGuest = self){
    			write "You have been caught stealing points. Points will be deducted";
    			studentHousePoints[3] <- studentHousePoints[3] - 5;
    			self.illegalDuels <- false;
    			myself.targetGuest <- nil;
    			myself.target <- nil;
    			
    		}
    	}
    }
    
    aspect base {
        rgb agentColor <- rgb("black");
        draw triangle(3) color: agentColor;
    }
    
    reflex move when: target = nil {
        do wander;
    }
    
    //increase determination, workshopTime and spite.
    reflex increaseVariables{
    	if(!classInSession){
    		determination <- determination + rnd(-5,15);
    	}
    	else{
    		workshopTime <- workshopTime + 1;
    	} 
    	
   
    	spite <- spite + rnd(1, 10); 
    	

    }
	//sometimes when the spite value is high enough, they will pick a student cclose to them and dock their points. This makes students less motivated.
    reflex dockingPoints when: !classInSession{
    	int dockPoints <- rnd(1,10);
    	ask Guest at_distance distanceThreshold{ 
    		if(myself.favouriteHouse = self.myHome){
    			write "my favourite house is " + myself.favouriteHouse + " and your house is " + myHome;    			
    		}else if(myself.spite > 10000){
    			loop i from: 0 to: 3{
    				if(self.myHome = studentHouses[i]){
    					write "=================";
    					write "before " + studentHousePoints;
    					studentHousePoints[i] <- studentHousePoints[i] - dockPoints;
    					
    					write "Docking " + dockPoints + " amount of points from " + self.myHome;
    					write "after " + studentHousePoints; 
    					write "=================";
    					myself.spite <- 0; 
    					self.motivation <- self.motivation - 10;
    				}    			
    			}
    		}
    	} 		

    }
    
    //when determination is high enough, they will simply start a workshop.
    reflex informWorkshopStart when: !classInSession and target = nil {
    	if(determination > 500){
    		do start_conversation with:(studentList, protocol:: 'fipa-request', performative:: 'inform', contents:: ["Class is starting"]);
    		classInSession <- true; 
    		target <- (Workshop closest_to(self)).location;
    		write "%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%";
    		write "WORKSHOP IN SESSION ";
    		write "%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%";
    	}

    }
    
    //when the workshop has ended, 
    reflex informWorkshopEnd when: classInSession{    	
    	
    	if(workshopTime > 200){
    		do start_conversation with:(studentList, protocol:: 'fipa-request', performative:: 'inform', contents:: ["Class is ending"]);
    		classInSession <- false;  
    		determination <- 0; 
    		target <- nil;
    		write "###################################"; 	    	
    		write "WORKSHOP ENDING";
    		write "###################################";
    		workshopTime <- 0;    		
    	}
    }
  	reflex moveToTarget when: target != nil{
		do goto target:target;
	}

}

species DuelingStage{
	rgb agentColor;
	
	init{
		add self to: duelingStageList;
	}
	
	string duelingStageName <- "undefined";
	
	action setName(int num) {
        duelingStageName <- "DuelingStage " + num;
    }
    aspect base {
        draw square(4) color: agentColor;
    }
	
}

species Workshop{
	rgb agentColor;	
	string classroomName <- "undefined";
	init{
		add self to: classroomList;
	}
	
	action setName(int num) {
        classroomName <- "Classroom " + num;
    }
    aspect base {
    
        draw square(4) color: agentColor;
    }
	
}

experiment my_experiment type:gui {
	output {
		display myDisplay {
			species Guest aspect:base;
			species Teacher aspect:base;
			species Workshop aspect:base;
			species DuelingStage aspect:base;
		}
		
		display infoDisplay refresh: every(10#cycles) {
            chart "NAME" type: series style: spline {
                data "Gryffindor" value: Gryffindor color: #red;
                data "Ravenclaw" value: Ravenclaw color: #blue;
                data "Slytherin" value: Slytherin color: #green;
                data "Hufflepuff" value: Hufflepuff color: #yellow;
            }
          
        }
	}
}

/* Insert your model definition here */

