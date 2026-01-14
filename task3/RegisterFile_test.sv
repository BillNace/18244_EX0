`default_nettype none


module RF_TB;

    logic clock, reset_L, write, read, error;
    logic [7:0] din, dout, test;
    logic [3:0] addr, entry;

    RegisterFile r (.clock, .reset_L, .din, .dout, 
                    .addr, .read, .write, .error);

    logic [15:0] was_written;
    int score = 0;
    int all_correct = 1;


    // Clock
    initial begin
        clock = 1'b0;
        forever #5 clock = ~clock;
    end

    // Force Timeout
    initial begin
        #100000000 ;
        $display("%m @%0t: Testbench issued timeout", $time);
        $finish;
    end


    // Reset task
    task doReset;
        $srandom(18224);

        reset_L = 1'b1;
        reset_L <= 1'b0;

        #1 reset_L <= 1'b1;

        // No entry has been written to yet
        was_written = '0;
    endtask : doReset


    // READ & WRITE FUNCTIONALITY
    task doWrite(input logic [3:0] entry, input logic [7:0] data);
        addr <= entry;
        din  <= data;
        write <= 1'b1;
        @(posedge clock);
        write <= 1'b0;

        // Entry was written to
        was_written[entry] = 1'b1;
    endtask: doWrite

    task doRead(input logic [3:0] entry);
        addr = entry;
        read = 1'b1;
    endtask: doRead


    // MAIN INITIAL
    initial begin

        read = 1'b0;
        write = 1'b0;

        doReset;
        #1;

        // Test reads and writes work normally
        repeat(100) begin

            // Random data to random register
            test = $urandom;
            entry = $urandom;

            doWrite(entry, test);
            @(posedge clock);
            // No error should occur here
            assert (!error) else begin
                $error("Unexpected error for valid write!\n");
                all_correct = 0;
            end

            doRead(entry);
            // No error should occur here
            assert (!error) else begin
                $error("Unexpected error for valid read!\n");
                all_correct = 0;
            end
            #0; assert(test == dout) else begin
                $error("Read value mismatch! Expected %x, got %x\n", test, dout);
                all_correct = 0;
            end

            read = 1'b0;
            @(posedge clock);
        end

        // Test that error is not asserted when value has been written to
        for (int i = 0; i < 16; i++) begin
            if (was_written) begin
                doRead(i);
                assert (!error) else begin
                    $error("Unexpected error for valid read!\n");
                    all_correct = 0;
                end
                read = 1'b0;
                @(posedge clock);
            end
        end

        // Test first error condition
        repeat (5) begin
            read = 1'b0;
            write = 1'b0;
            @(posedge clock);
            assert (!error) else begin
                $error("Unexpected error while RF was idle.\n");
                all_correct = 0;
            end

            read = 1'b1;
            write = 1'b1;
            #0; assert (error) else begin 
                $error("Expected error when both read and write asserted.\n");
                all_correct = 0;
            end
            assert (dout == '0) else begin
                $error("RF output not zero during error. Instead was %x.\n", dout);
                all_correct = 0;
            end
            @(posedge clock);
        end

        read = 1'b0;
        write = 1'b0;

        doReset;
        #1;

        // Test second error condition
        repeat (100) begin
            entry = $urandom;
            doRead(entry);
            #0; assert (error) else begin
                $error("Expected error during invalid read at address %x!\n", entry);
                all_correct = 0;
            end
            assert (dout == '0) else begin
                $error("RF output not zero during error. Instead was %x.\n", dout);
                all_correct = 0;
            end
            read = 1'b0;
            @(posedge clock);
        end


        if (all_correct) $display("\nPassed all tests!\n");
        #1; $finish;
    end


endmodule: RF_TB
