/* Universidad de Costa Rica
   Escuela de Ingenieria Eléctrica | Circuitos Digitales II - IE0523
   Proyecto Final | Diseno de un bloque de PCS tipo 1000BASE-X
   Profesor: Enrique Coen 
   Estudiantes: Elizabeth Matamoros Bojorge-C04652
                Elián Jiménez Quesada-C13983
                Jose Andres Guerrero Alvarez-B63162
*/

module tester (
    // Salidas del probador
    output reg clk, reset, 

    output reg power_on, tx_en,                             
    output reg [7:0] data_o_set,

    // Entradas del probador
    input wire rx_even, sync_status,                        
    input wire [9:0] sudi,  

    input wire [9:0] tx_code_group,  
    input wire tx_oset_indicate,
    input wire [7:0] tx_o_set,

    input wire [7:0] rxd,    
    input wire rx_dv,        
    input wire rx_er,       
    input wire receiving    
);            

  initial begin

    // Se inician las entradas de la maquina de estados en 0
    clk = 0;                              
    reset = 0;                            
    #0 reset = 0;
    #0 data_o_set = 8'b00000000;        
    #20 reset = 1; 
    #0 power_on = 1;

    #0 tx_en = 0;
    #130 tx_en = 1; 
    #0 data_o_set = 8'b00000111;
    #10 tx_en = 0;
    #10 tx_en = 1;
    #40 tx_en = 0;
    #60 reset = 0;

    #100 $finish;                         // Finaliza la simulacion
  end

  always begin                            // Se genera un reloj con periodo de 10 unidades de tiempo
    #5 clk = !clk;
  end

endmodule