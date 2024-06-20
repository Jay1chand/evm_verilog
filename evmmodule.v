module evm #(
parameter off =  2'b00,					// states and their corresponding numbers
parameter run =  2'b01,
parameter check =  2'b10,
parameter finish = 2'b11
)(
    input clk,							
    input rst,							// input High to reset counting  (active high)
    input candidate_1,				// input to run for candidate 1
    input candidate_2,				// input to run for candidate 2
    input candidate_3,				// input to run for candidate 3
    input i_voting_over,				// input high to get total runs after voting is over

    output reg [31:0] total1,			// output for total number of runs of candidate 1
    output reg [31:0] total2,			// output for total number of runs of candidate 2
    output reg [31:0] total3			// output for total number of runs of candidate 3

);	  

reg [31:0] r_cand1_prev;					// store previous value of input for candidate 1
reg [31:0] r_cand2_prev;					// store previous value of input for candidate 2
reg [31:0] r_cand3_prev;					// store previous value of input for candidate 3

reg [31:0] r_counter_1;						// counting register for candidate 1
reg [31:0] r_counter_2;						// counting register for candidate 2
reg [31:0] r_counter_3;						// counting register for candidate 3

reg [1:0] r_present_state, r_next_state;		// present state and next state registers
//reg [1:0] r_state_no;					     // store state number
reg [3:0] r_check_count;                        //counter for check state

//////////// always block that assigns next state & internal reg operations /////////////////////////////////// 
always @(posedge clk or negedge rst)
	begin
		case (r_present_state)														

			off: if (!rst)												// off state operations
						begin
							r_next_state <= run;									// assign next state run when reset low
							//r_state_no <= 2'b01;
						end	

					else
						begin
						//r_present_state = off;									// present state at the beginning
							r_counter_1 <= 32'b0;										// clear counting registers
							r_counter_2 <= 32'b0;
							r_counter_3 <= 32'b0;
							r_check_count <= 4'b0000;

							r_next_state <= off;									// assign next state as off till reset not low
							//r_state_no <= 2'b0;
						end
				

			run: if (i_voting_over == 1'b1)									// check if voting is over
						begin
							r_next_state <= finish;								// if over is high go to finish state
							//r_state_no <= 2'b11;
						end
												// if over is low contiue counting
					else if (candidate_1 == 1'b0 && r_cand1_prev == 1'b1)         // check falling edge of input candidate1 so only single input is regeistered 
						begin
							r_counter_1 <= r_counter_1 + 1'b1;								// increment counter for candidate 1
							//r_counter_2 <= r_counter_2;									// keep previous value of counter 
							//r_counter_3 <= r_counter_3;									// keep previous value of counter

							r_next_state <= check;									// got to check state
							//r_state_no <= 2'b10;
						end

					else if (candidate_2 == 1'b0 && r_cand2_prev == 1'b1) 		// check falling edge of input candidate2 so only single input is regeistered
						begin
							//r_counter_1 <= r_counter_1;									// keep previous value of counter 
							r_counter_2 <= r_counter_2 + 1'b1;								// increment counter for candidate 2
							//r_counter_3 <= r_counter_3;									// keep previous value of counter 

							r_next_state <= check;									// got to check state
							//r_state_no <= 2'b10;
						end

					else if (candidate_3 == 1'b0 && r_cand3_prev == 1'b1) 		// check falling edge of input candidate3 so only single input is regeistered
						begin
							//r_counter_1 <= r_counter_1;									// keep previous value of counter
							//r_counter_2 <= r_counter_2;									// keep previous value of counter
							r_counter_3 <= r_counter_3 + 1'b1;								// increment counter for candidate 3

							r_next_state <= check;									// got to check state
							//r_state_no <= 2'b10;
						end
					else															// none of the input present or more than 1 input present at same time
						begin
							r_counter_1 <= r_counter_1;									// keep previous value of counter
							r_counter_2 <= r_counter_2;									
							r_counter_3 <= r_counter_3;

							r_next_state <= run;
							//r_state_no <= 2'b01;
						end

			check: if (i_voting_over == 1'b1)									// check if over input is high
						begin
							r_next_state <= finish;									// go to finish state
							//r_state_no <= 2'b11;
						end

					else 
						begin
							if (r_check_count != 4'b1111) begin
								r_check_count = r_check_count + 1'b1;
							end
							else begin
							    r_next_state <= run;									// if over is low go to run state
							end
							//r_state_no <= 2'b01;
						end

			finish: if (i_voting_over == 1'b0)										
						begin
							r_next_state <= off;									// if over is low go to off state
							//r_state_no <= 2'b0;
						end

					else
						begin
							r_next_state <= finish;									// remain in finish state if over is high
							//r_state_no <= 2'b11;
						end

			default: 
				begin 
					r_counter_1 <= 32'b0;											// default values for resgisters
					r_counter_2 <= 32'b0;
					r_counter_3 <= 32'b0;
					r_check_count <= 4'b0000;

					r_next_state <= off;										// by default go to off state at the begining
					//r_state_no <= 2'b0;
				end
		endcase
	end	  

////////////// always block that performs assignment of regsiters and output on clock signal //////////////////////////////
always @(posedge clk or negedge rst)													// work on positive edge of clock 
	begin				

      if (rst == 1'b1)
			begin
				 r_present_state <= off;											// remain in off state when reset is high
													
				 total1 <= 32'b0; 												// reset final output count  
				 total2 <= 32'b0;
				 total3 <= 32'b0;
				 r_check_count <= 4'b0000;
			end 
			
		else if (rst == 1'b0 && i_voting_over == 1'b1)											// if voting process is i.e.over is high
			begin
				 total1 <= r_counter_1; 											// provide value of counting registers at output
				 total2 <= r_counter_2;
				 total3 <= r_counter_3;
			end
		
		else
			begin
				r_present_state <= r_next_state;									// if reset is low keep assigning next state to present state
				r_cand1_prev <= candidate_1;									// keep assigning input of candidate 1 to internal register
				r_cand2_prev <= candidate_2;
				r_cand3_prev <= candidate_3;
			end
	
	end	

endmodule