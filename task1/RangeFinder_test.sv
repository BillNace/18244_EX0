`default_nettype none
module RangeFinder_test();

  logic [15:0] data_in, range;
  logic        clock, reset, go, finish, error;

  RangeFinder #(16) rf(.*);
  
  initial begin
    reset = 1'b1;
    reset <= 1'b0;
    clock = 1'b0;
    forever #5 clock = ~clock;
  end
  
//  initial
//    $monitor($stime," data_in(%h) go(%b) finish(%b) range(%h): hi(%h) lo(%h) error(%b)",
//             data_in, go, finish, range, rf.high_q, rf.low_q, error);
    
  initial begin
    data_in <= 16'h7FFF; {go, finish} <= '0;
    
    // Simple sequence of 7FFF, 8000, 8001, 7FFE --> expect range of 3
    @(posedge clock);
    @(posedge clock);
    go <= 1'b1;
    @(posedge clock);

    data_in <= 16'h8000;
    go <= 1'b0;
    @(posedge clock);

    data_in <= 16'h8001;
    @(posedge clock);
    
    data_in <= 16'h7FFE;
    @(posedge clock);
    
    data_in <= 16'h7FFF;  // doesn't change outer bounds
    @(posedge clock);
    
    finish <= 1'b1;
    @(posedge clock);
    #1 assert (range == 16'h0003) else $display($stime, "range=%h, expected = 16'h0003", range);
    {go, finish} <= '0;
    
    @(posedge clock);
    
    // Error sequence, go and finish at the same time
    {go, finish} <= '1;
    @(posedge clock);
    #1 assert (error == 1'b1) else $display($stime, "Error was not caught");
    {go, finish} <= '0;
    
    @(posedge clock);

    // Error sequence, finish before go
    @(posedge clock);
    @(posedge clock);
    finish <= 1'b1;
    @(posedge clock);
    #1 assert (error == 1'b1) else $display($stime, "Error was not caught");
      
    // And, should stay in the error state until a go happens
    @(posedge clock);
    #1 assert (error == 1'b1) else $display($stime, "Should still be in error state");
    finish <= 1'b0;
    @(posedge clock);
    #1 assert (error == 1'b1) else $display($stime, "Should still be in error state");

    data_in <= 16'h0100;
    go <= 1'b1;
    @(posedge clock);
    #1 assert (error == 1'b0) else $display($stime, "Should NOT still be in error state");

    // Check widest possible range (note, already started a sequence with go on last clock)
    data_in <= 16'h0000;
    @(posedge clock);
    data_in <= 16'hFFFF;
    @(posedge clock);
    data_in <= 16'h0200;
    finish <= 1'b1;
    @(posedge clock);
    #1 assert (range == 16'hFFFF) else $display($stime, "Expected range to be 16'hFFFF");
    finish <= 1'b0;
    
    @(posedge clock);
    @(posedge clock);
    
    $finish();
  end           

endmodule : RangeFinder_test