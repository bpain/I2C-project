`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 01/12/2025 05:32:07 PM
// Design Name: 
// Module Name: I2C_FSM
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


module I2C_FSM(
    input [6:0] addr,
    input GO, clk, wr,
    input  [7:0] din,
    output reg [7:0]  dout,
    output reg WE,READY,
    inout wire SDA, SCL
    );
    
    parameter data_length = 7; 
    
    typedef enum{hold,start,address0, address, wait1,waitACK,READ, WRITE} STATES; 
                
    STATES PS, NS = hold; 
   
    reg [2:0] addr_count = 0; 
    reg [3:0] data_count = 0;  
    reg [7:0] data = 0; 
   
//    always_ff @(posedge SCL)
//    begin 
//        PS <= NS;     
//    end     
    // Internal signals for driving SDA and SCL
    reg SDA_out, SCL_out;
    reg SDA_en, SCL_en = 1;
    reg addr_up; 
    // Tri-state buffers for SDA and SCL
    assign SDA = SDA_en ? SDA_out : 1'bz; // Drive SDA_out if enabled, otherwise high-impedance
    assign SCL = SCL_en ? clk : 1'bz; // Drive SCL_out if enabled, otherwise high-impedance
    assign d_out =  wr ? data : 0; 
    //assign addr_count <= addr_up ? addr_count:addr_count + 1; 
   
   always_ff@(posedge clk) 
    begin
        PS <= NS;    WE<=0; 
        SDA_en <= 0; SCL_en <= 1; 
        SCL_out <= 0; SDA_out <= 0; 
        READY <= 0;
        case(PS)
            hold: 
                if (GO) begin 
                    addr_count <= 0;end
                else begin 
                    addr_count <= 0; 
                    READY <= 1; 
                    end 
            start: begin 
                SDA_en <= 1; 
                SDA_out <= 0;      
                end
            address0: 
                    begin 
                        SDA_out <= addr[addr_count];
                        SDA_en <= 1; 
                        addr_count <= addr_count + 1; 
                    end 
            address: begin 
                if (addr_count < 7)begin 
                    SDA_out <= addr[addr_count];  
                    addr_count <= addr_count + 1; 
                    SDA_en <= 1;                  
                    end 
               else begin                     
                    SDA_out <= wr;
                    SDA_en <= 0; 
                    addr_count <= 0; 
                    end              
                end          
//            wait1: begin 
//                addr_count <=0; 
//            end 
            waitACK: begin
               SDA_en <= 0; // Release SDA to allow slave to respond
               addr_count <= addr_count + 1; 
               end
            READ: begin
                SDA_en <= 0; 
                SCL_en <= 1; 
                if (data_count <=7 )begin 
                    data[data_count] <= SDA; 
                    data_count <= data_count + 1; 
                    end 
               else begin     
                    dout <= data; 
                    WE<=1;                 
                    SDA_out <= 0;
                    data_count <= 0; 
                    addr_count <=0; 
                    end              
                end          
               
            WRITE: begin
               
                SCL_en <= 1; 
                if (data_count <= 7)begin 
                    SDA_en <= 1; 
                    SDA_out <= din[data_count]; 
                    data_count <= data_count + 1; 
                    end 
               else begin     
                    //WE <= 1;                 
                    SDA_en <= 0;
                    data_count <= 0; 
                    addr_count <= 0; 
                    end              
                end           
            
        
        endcase
       
    end
    
    
    always_comb begin 
        NS = PS; 
        case(PS)
            hold: 
                if (GO) begin 
                    NS = start; 
                    end
                else begin  
                    NS = hold; end 
                                        
            start: begin             
                NS = address0; 
                end
            address0: 
                    begin 
                    NS = address; 
                    end     
            address: begin 
                if (addr_count < 7)begin 
                    NS = address; 
                    end 
               else begin                     
                    NS = waitACK;end              
                    end          
//            wait1: begin 
//                NS <= waitACK;  
//                end 
            waitACK: begin
               // Release SDA to allow slave to respond
                   if (~SDA)begin // ACK received
                         NS = (wr) ? READ : WRITE; end 
                   else begin 
                   if (addr_count > 2)begin 
                        NS = hold; end 
                   end  // come back to this to have it return to hold 
               end
            READ: begin
                if (data_count <= 7)begin 
                    NS = READ; end 
               else begin     
                                   
                    NS = hold;end              
                end          
               
            WRITE: begin
                if (data_count <= 7)begin 
                    NS = WRITE; end 
               else begin                     
                    NS = hold;end              
                end           
        endcase
    end 
    
endmodule
