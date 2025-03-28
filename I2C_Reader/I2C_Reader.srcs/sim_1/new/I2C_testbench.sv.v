`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 02/03/2025 11:38:11 PM
// Design Name: 
// Module Name: I2C_testbench
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////
interface Vif(input bit clk); 
       logic [7:0] p_din; 
       logic [6:0] p_addr;
       logic [7:0] p_dout;
    
       logic [7:0] MCU_din;
       logic [7:0] MCU_dout;
    
       logic GO;
       logic MCU_WR; 
     
    endinterface 

class I2C_DATA; 
        
    randc bit [7:0] p_din; 
    randc bit [6:0] p_addr;
    bit [7:0] p_dout;
    
    randc bit [7:0] MCU_din;
    bit [7:0] MCU_dout; 
    bit MCU_WR;
           
endclass

class generator #(nums = 75); 
    
      mailbox#(I2C_DATA) driver_mailbox; 
      bit num = nums; 
      event driver_done; 
      
      task run(); 
        $display("generator runnning"); 
        for (int i =0; i < nums; i++) begin
            I2C_DATA stimuli = new(); 
            stimuli.randomize(); 
            driver_mailbox.put(stimuli); 
            @driver_done; 
        end 
      endtask
endclass

class driver; 
    mailbox#(I2C_DATA) driver_mailbox; 
    virtual Vif vif; 
    event driver_done; 
    
    task run(); 
        initial begin
        $display("driver running"); 
        I2C_DATA stimuli; 
        driver_mailbox.get(stimuli); 
       
       vif.p_din = stimuli.p_din; 
       vif.p_addr = stimuli.p_addr;
       vif.MCU_din = stimuli.MCU_din;
       
       repeat (10) @(posedge vif.clk);  
       
       @(posedge vif.clk) begin 
            @driver_done;  
       end 
      end  
    endtask
endclass


class monitor;
     virtual Vif vif;
     mailbox#(I2C_DATA) scb_mbx;
     event driver_done; 
        
        
    task run(); 
        forever begin
        $display("monitor running"); 
        I2C_DATA results = new(); 
        @driver_done; 
            results.p_din = vif.p_din; 
            results.p_addr = vif.p_addr;
            results.p_dout = vif.p_dout;
    
            results.MCU_din = vif.MCU_din;
            results.MCU_dout = vif.MCU_dout; 
            results.MCU_WR = vif.MCU_WR;
            scb_mbx.put(results); 
           
        end 
    endtask
    
endclass
 

class scoreboard; 
    virtual Vif vif;
    mailbox#(I2C_DATA) scb_mbx;
   
    task run();
         
            $display("scoreboard running"); 
            I2C_DATA results = new(); 
            scb_mbx.get(results); 
            if (results.MCU_WR)begin 
                if (results.MCU_dout != results.p_din)begin 
                    $display ("T=%0t [Scoreboard] READ ERROR! Mismatch MCU_dout=0x%0h p_din=0x%0h p_addr=0x%0h ", $time, results.MCU_dout, results.p_din, results.p_addr);
                end 
            end 
            else begin 
                if (results.p_dout != results.MCU_din)begin 
                    $display ("T=%0t [Scoreboard] WRITE ERROR! Mismatch p_dout=0x%0h MCU_din=0x%0h p_addr=0x%0h ", $time, results.p_dout, results.MCU_din, results.p_addr);
                end 
            end 
        
    endtask
    
endclass

class environment;
  driver 		d0; 		// Driver handle
  monitor 		m0; 		// Monitor handle
  generator		g0; 		// Generator Handle
  scoreboard	s0; 		// Scoreboard handle

  mailbox#(I2C_DATA) 	drv_mbx; 		// Connect GEN -> DRV
  mailbox#(I2C_DATA)  	scb_mbx; 		// Connect MON -> SCB
  event 	drv_done; 		// Indicates when driver is done

  virtual Vif vif; 	// Virtual interface handle

  function new();
    d0 = new;
    m0 = new;
    g0 = new;
    s0 = new;
    drv_mbx = new();
    scb_mbx = new();

    d0.driver_mailbox = drv_mbx;
    g0.driver_mailbox = drv_mbx;
    m0.scb_mbx = scb_mbx;
    s0.scb_mbx = scb_mbx;

    d0.driver_done = drv_done;
    g0.driver_done = drv_done;
  endfunction

  virtual task run();
    $display("environment running"); 
    d0.vif = vif;
    m0.vif = vif;

    fork
      d0.run();
      m0.run();
      g0.run();
      s0.run();
    join_any
  endtask
endclass




module I2C_testbench();
    reg clk;
    
    always #10 clk = ~clk; 
    
    Vif vif(clk);   
    
    environment e0; 
    
    I2C_TOP_LEVEL DUT(
        .p_din(vif.p_din), 
        .p_addr(vif.p_addr),
        .p_dout(vif.p_dout),
    
        .MCU_din(vif.MCU_din),
        .MCU_dout(vif.MCU_dout),
    
        .clk(clk),
        .GO(vif.GO), 
        .MCU_WR(vif.MCU_WR)); 
        
      initial begin 
        $display("lets see if dis is working"); 
        e0 = new(); 
        e0.vif = vif; 
        e0.run(); 
        #1000; 
        $display("it's hopefully all good big dog");
        #20
        $finish; 
      end 
    
    
    
    
endmodule
