/**
* Name: internode
* Author: Therese Anne Rollan , Science Research Specialist II, IAMBlueCECAM Project 3: GeoSiMaS
* Description: Mortality and Actual field growth parameters applied
* Tags: Tag1, Tag2, TagN
*/

model seagrasssimulationasordors

/* Extent: 1 x 1 m
 * Multiple views for the 4 Factors: 
 * Dissolved nitrogen (µmol L-1)
 * Dissolved phosphate (µmol L-1)
 * Dissolved silicate (µmol L-1)
 * Chlorophyll-A (µg L-1)
 */

global {
	//Plot 
	int grid_length_num <- 1; 
	int area <- int(grid_length_num^2);
	
	//Initial Parameters
	int num_seeds <- rnd(3,5); //range 1-5 is just a setting; max = 58 (growth stops when reached) based on Vermaat et al Meadow Maintenance..
	int num_apices <- 0;
	int num_shoots <- 0;
	int num_horizontal_rhizomes <- 0;
	
	//Environmental Parameters
	float dn <- 0.0 ;//min:2.0 max:20.2; //dissolved nitrogen
	float dp <- 0.0 ;//min:0.5 max:2.5; //dissolved phosphate
	float ds <- 0.0 ;//min:10.0 max:18.5; //dissolved silicate
	float chlA <- 0.0 ;//min:0.03 max:10.5; //chlorophyll-A
	
	//Structure Parameters
	string elongation_option <- 'V';
	float rhizome_elongation_vermaat <- 20.6; //in cm/yr
	float rhizome_elongation_ <- 20.6;
	float rhizome_elongation <- 20.6; //default : rhizome_elongation_vermaat in cm/yr
	float spacer_length <- 6.9;//Shoot Spacing (cm) from Vermaat et al.
	float branching_rate <- 0.0;
	float internode_rate <- (0.37 + rnd(-0.1,0.1)) with_precision 2; //in mm
	float rhizome_lifespan <- 4.0; //horizontal; 4 years
	
	//Time Parameters
	float timestep <- (spacer_length*365/rhizome_elongation_) with_precision 2; //in days
	
	//Visualization Parameters
	float angle;
	image_file shoot_image const: true <- file('../images/Thalassia_hemprichii_vector.png');
	image_file legend const: true <- file('../images/Legend.png');

	init{
		//write rhizome_elongation_;
		loop times:num_seeds{
			if num_apices < 59 {
				write "create horizontal_rhizome init";
				create horizontal_rhizome name: initial_horizontal_rhizomes{
				spacer_length <- rhizome_elongation*timestep/365;
				angle <- rnd(0.0,360.0);
				A <- location;
				B <- location + {spacer_length*cos(angle), spacer_length*sin(angle)};
				apex_location <- B;
				create shoot with: (location:A);
				}
			}
		}
	}
	
	reflex grow {
		write "apex count global reflex 1 = " + ( apex count (each.color=#red));
		loop i_node over: horizontal_rhizome {
			write "apex count global reflex 2 = " + num_apices;
			if num_apices < 59 {
				write "create horizontal_rhizome global reflex";
				create horizontal_rhizome {
				spacer_length <- rhizome_elongation*timestep/365;
				A <- i_node.apex_location;
				angle <- rnd(0.0,360.0);
				B <- A + {spacer_length*cos(angle), spacer_length*sin(angle)};
				}
			}
		}
	}
}

species horizontal_rhizome {
	point apex_location <- B;
	point A;
	point B;
	bool still_active <- true;
	int initial_cycle ;
	float transparency <- 0.0 update: transparency+0.2;
	rgb color <- #saddlebrown;
	int max_age <- int(365*4/timestep); //~133 cycles = 365 days * 4yrs [average lifespan] / timestep[duration per cycle]
	float apex_probability ;
	
	init{
		initial_cycle <- cycle;
		num_horizontal_rhizomes <- num_horizontal_rhizomes+1;
		
		if (elongation_option = 'V'){ 
			rhizome_elongation <- rhizome_elongation_vermaat; //in cm/yr
		}
		if (elongation_option = 'DN'){ 
			rhizome_elongation <- ((-0.0431*dn) + 1.0956)/10.0; //varying based on Dissolved nitrogen (µmol L-1)
		}
		if (elongation_option = 'DP'){
			rhizome_elongation <- ((-0.3865*dp) + 1.1923)/10.0; //varying based on Dissolved phosphate (µmol L-1)
		}
		if (elongation_option = 'DS'){ 
			rhizome_elongation <- ((-0.0872*ds) + 1.9022)/10.0; //varying based on Dissolved silicate (µmol L-1)
		}
		if (elongation_option = 'C'){
			rhizome_elongation <- ((-0.0735*chlA) + 0.9918)/10.0; //varying based on Chlorophyll-A (µg L-1)
		}
		if (elongation_option = 'AD'){ //all dissolved nutrients
			rhizome_elongation <- ((-1.144*dn) + (9.250*dp) + (0.1629*ds) - 2.806)/10.0; 
		
		}
	}
	reflex create_apex when:  num_apices < 59 {
		apex_probability <- rnd(0.0,1.0);
		if (apex_probability >= 0.5) {
			create apex with: (location:B);	
			write "new apex";
			write num_apices;
		}
	}
	reflex mortality when: cycle = initial_cycle + max_age { 
		color <- #gray;
		num_horizontal_rhizomes <- num_horizontal_rhizomes -1;
	}
	reflex mortality_2 when: cycle = (initial_cycle + max_age + 1) { 
		do die;
	}
	aspect base{
		draw line([A,B],0.3) color: color;
		apex_location <- B;
	}
}

species apex{
	int initial_cycle;
	point apex_location;
	rgb color <- #red;
	float branching_probability;
	
	init {
		initial_cycle <- cycle;
		apex_location <- location;
		num_apices <- num_apices +1;
		branching_probability <- rnd(0.0,1.0);
	}
	
	reflex mortality  {
		create shoot with: (location:apex_location);
		do die;
	}
	reflex branch_out when: (branching_probability >= 0.01 and num_apices < 59 ) {
		write "create horizontal_rhizome apex";
		create horizontal_rhizome;
	}
	aspect base{
		draw circle(0.15) color:color;
	}	
}

species shoot {
	int initial_cycle;
	rgb color <- #green;
	float size <- 0.5;
	float transparency <- 0.0 update: transparency+0.2;
	int max_age <- round((229 + rnd(-17,17))/timestep); //229 +/- 17 days [median max age] / timestep[duration per cycle]
	
	init{
		num_shoots <- num_shoots +1;
		initial_cycle <- cycle;
		num_apices <- num_apices -1;	
	}
	
	reflex mortality when: cycle = initial_cycle + 2 { 
		num_shoots <- num_shoots -1;
		do die;
	}
	aspect base{
		draw circle(size) color:color;
	}
}


experiment Varying_Environmental_Factors type: gui {
	point quadrant_size <- { 0.5, 0.5 };
	float minimum_cycle_duration <- 0.25;
	parameter 'Number of \nInitial Apical Meristems:' var: num_seeds category: 'Agents' ;
	parameter 'Time Step (days):' var: timestep category: 'Time' ;
	parameter 'Spacer Length (cm):' var: spacer_length category: 'Growth Parameters' ;
	parameter 'Horizontal Rhizome \nElongation Rate (cm/timestep):' var: rhizome_elongation_ category: 'Growth Parameters' ;
	parameter 'Average Rhizome Lifespan (years):' var: rhizome_lifespan category: 'Growth Parameters' ;
	parameter 'Elongation Rate Option
 [default] V - based on Vermaat et al
 DN - diss. nitrogen 
 DS - diss. silicate
 DP - diss. phosphate
 C - chl-A
 AD - all nutrients except chl-A
	' var: elongation_option category: 'Growth Parameters' ;
	parameter 'Dissolved Nitrogen (µmol L-1)' var: dn category: 'Nutrient Values' ;
	parameter 'Dissolved Phosphate (µmol L-1)' var: dp category: 'Nutrient Values' ;
	parameter 'Dissolved Silicate (µmol L-1)' var: ds category: 'Nutrient Values' ;
	parameter 'Chlorophyll-A (µg L-1)' var: chlA category: 'Nutrient Values' ;
	
	init{
		elongation_option <- 'V';	
	}
	
	output {
		display seagrass_initial_meadow /*type:opengl*/ { 
			image '../images/water.png' position: { 0, 0} size: { 100.0,100.0 }; //size: 1 sqm [100 x 100 cm]
			species horizontal_rhizome transparency: transparency aspect: base;
			species apex aspect: base;
			species shoot transparency: transparency aspect: base;
			overlay "Texts" transparency: 1.0 background: rgb (0, 180, 153,255)  position: {0°px, 450°px} size: {280°px, 85°px}{
				draw legend at: {730°px, 20°px} size: {130°px, 130°px} rotate: 0;
				draw ('Duration:      ' +  (cycle*timestep)with_precision 2 + ' days') at: {30°px, -425°px} font:font("Arial", 14 , #bold) color: #black;
				draw ('  ' +  (cycle*timestep/30)with_precision 2 + ' months') at: {100°px, -410°px} font:font("Arial", 14 , #bold) color: #black;
			}
			
		}
		inspect "Shoot" type: table value: shoot attributes: ['name', 'location','state'];
	}
	
	permanent {
		display Comparison background: #white {
			chart "Count vs Duration" type: series {
					data "Shoots" value: shoot count (each.color=#green) style: spline color: #green ;
					data "Horizontal Rhizomes" value: horizontal_rhizome count (each.color=#brown)style: spline color: #brown ;
					data "Apical Meristems" value: apex count (each.color=#red) style: spline color: #red ;
			}
		}
		display cover {
			image '../images/COVER.png' position: { 0, 0} size: { 100.0,100.0 }; //size: 1 sqm [100 x 100 cm]
		}
	}
}

