`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 01/21/2025 11:54:33 PM
// Design Name: 
// Module Name: I2C_peripheral
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


module I2C_peripheral( 
    input  [7:0] din,
    input  [6:0] addr,
    input clk,
    output reg [7:0] dout,
    output reg WE,READY,
    inout wire SDA, SCL
    );
    
    parameter data_length = 7;
     
    
    typedef enum{hold,address,ACK,READ, WRITE, waitACK} STATES; 
    STATES PS, NS = hold; 
    
    reg wr = 0; 
    reg [2:0] addr_count = 0; 
    reg [2:0] data_count = 0;  
    reg [6:0] address_received; 
    reg [6:0] this_address;
    reg [7:0] data = 0; 
    
//    always_ff @(posedge clk)
//    begin 
//        if(SCL_en)begin 
//            SCL <= 0; 
//        end
//    end
    
    always_ff @(posedge SCL)
    begin 
        PS <= NS;     
    end     
    // Internal signals for driving SDA and SCL
    reg SDA_out, SCL_out;
    reg SDA_en, SCL_en;

    // Tri-state buffers for SDA and SCL
    assign SDA = SDA_en ? SDA_out : 1'bz; // Drive SDA_out if enabled, otherwise high-impedance
    //assign SCL = SCL_en ? clk : 1'bz; // Drive SCL_out if enabled, otherwise high-impedance
    //assign data_out =  wr ? data : 0; 
    
    always_ff@(posedge clk) 
    begin
        SDA_en <= 0; SCL_en <= 0; 
        SCL_out <= 0; SDA_out <= 0; 
        WE <= 0;  READY <=0; 
        case(PS)
            hold: begin
                this_address <= addr; 
                address_received <= 0; 
                addr_count<=0; 
                dout <= data; 
                READY<= 1; 
                end 
            address: begin 
                if (addr_count < 7)begin 
                    address_received[addr_count] <= SDA; 
                    addr_count <= addr_count + 1; 
                    end 
               else begin                     
                    if (address_received == this_address) begin 
                       wr <= SDA;
                       end
                end  
                end        
            ACK: begin
                    SDA_en <= 1; 
                    SDA_out <= 0;                      
                end 
            READ: begin
                if (data_count <= 7)begin 
                    data[data_count] <= SDA; 
                    data_count <= data_count + 1; 
                    end 
               else begin        
                    WE <= 1;              
                    SDA_en <= 1; 
                    SDA_out <= 0;
                    data_count <= 0; 
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
                    SDA_out <= 0;
                    data_count <= 0; 
                    addr_count<= 0; 
                    address_received <= 0; 
                    end              
                end   
            waitACK: begin 
                     end            
        endcase
    end
    
    always_comb begin 
       NS = PS; 
        case(PS)
            hold: begin
                if (~SDA)begin 
                    NS = address; 
                    end
                else begin 
                    NS = hold; 
                    end
                end 
            address: begin 
                if (addr_count < 7)begin 
                    NS = address; end 
               else begin                     
                    if (address_received == this_address) begin 
                       NS = ACK; 
                       end
                    else begin 
                        NS = hold; 
                        end 
                    end 
                end          
            ACK: begin
                    if (wr) begin
                        NS = WRITE; 
                        end     
                    else begin 
                        NS = READ; 
                        end                      
                end 
            READ: begin
                    if (data_count < 8)begin 
                        NS = READ; end 
                    else begin                     
                        NS = hold;end              
                    end          
               
            WRITE: begin
                        if (data_count < 7)begin 
                            NS = WRITE; end 
                       else begin                     
                            NS = waitACK;end              
                    end  
            waitACK: begin 
                        if(~SDA) begin 
                            NS = hold; 
                        end 
                        else begin 
                            NS = hold; 
                        end
                    end              
        endcase
    end 
    
endmodule

