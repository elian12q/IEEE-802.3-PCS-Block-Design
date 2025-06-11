/* Universidad de Costa Rica
   Escuela de Ingenieria Eléctrica | Circuitos Digitales II - IE0523
   Proyecto Final | Diseno de un bloque de PCS tipo 1000BASE-X
   Profesor: Enrique Coen 
   Estudiantes: Elizabeth Matamoros Bojorge-C04652
                Elián Jiménez Quesada-C13983
                Jose Andres Guerrero Alvarez-B63162
*/

module tester (
    //outputs
    output reg clk, reset,                // Se definen las salidas como reg
    output reg [9:0] rx_code_group,

    //inputs
    input wire rx_even, sync_status,      // Se definen las entradas como wire
    input wire [9:0] sudi             
);            

// Asignacion de code-groups. Los _1 son para RD- y los _2 para RD+ 
    parameter D0_1     = 10'b100111_0100;
    parameter D0_2     = 10'b011000_1011;

    parameter D1_1     = 10'b011101_0100;
    parameter D1_2     = 10'b100010_1011;

    parameter D2_1     = 10'b101101_0100;
    parameter D2_2     = 10'b010010_1011;

    parameter D3_1     = 10'b110001_1011;
    parameter D3_2     = 10'b001110_0100;

    parameter D4_1     = 10'b110101_0100;
    parameter D4_2     = 10'b001010_1011;

    parameter D5_1     = 10'b101001_1011;
    parameter D5_2     = 10'b010110_0100;

    parameter D6_1     = 10'b011001_1011;
    parameter D6_2     = 10'b100110_0100;

    parameter D7_1     = 10'b111000_1011;
    parameter D7_2     = 10'b000111_0100;

    parameter D8_1     = 10'b111001_0100;
    parameter D8_2     = 10'b000110_1011;

    parameter D9_1     = 10'b100101_1011;
    parameter D9_2     = 10'b011010_0100;

    parameter D5_6_1   = 10'b101001_0110;
    parameter D5_6_2   = 10'b101001_0110;

    parameter D16_2_1  = 10'b011011_0101;
    parameter D16_2_2  = 10'b100100_0101;

    // Asignacion de code-groups especiales. Los _1 son para RD- y los _2 para RD+ 
    parameter I_1  = 10'b001111_1010;
    parameter I_2  = 10'b110000_0101;

    parameter R_1  = 10'b111010_1000;
    parameter R_2  = 10'b000101_0111;

    parameter S_1  = 10'b110110_1000;
    parameter S_2  = 10'b001001_0111;

    parameter T_1  = 10'b101110_1000;
    parameter T_2  = 10'b010001_0111;

  initial begin

    // Se inician las entradas de la maquina de estados en 0
    clk = 0;                              
    reset = 1;                            
    rx_code_group = 0;
    
    // Prueba #1
    #10 reset = 0;
    #25 reset = 1;

    // Primera comma
    #25 rx_code_group = I_1;
    #20 rx_code_group = D16_2_1;


    // Segunda comma
    #20 rx_code_group = I_2;
    #20 rx_code_group = D5_6_2;

    // Tercera comma
    #20 rx_code_group = I_1;
    #20 rx_code_group = D16_2_1;

    // Caracter de Start correcto
    #20 rx_code_group = S_2;

    // Caracter de Datos correcto
    #20 rx_code_group = D4_2;
    ////////////////////////////////////////////////////////////////////////

    // Prueba #2
    #20 reset = 0; 
    #25 reset = 1; rx_code_group = 0;

    // Primera comma
    #25 rx_code_group = I_1;
    #20 rx_code_group = D5_6_1;


    // Segunda comma
    #20 rx_code_group = I_2;
    #20 rx_code_group = D16_2_2;

    // Comma invalida
    #20 rx_code_group = 10'b110000_1111;
    ////////////////////////////////////////////////////////////////////////

    // Prueba #3
    #20 reset = 0;
    #25 reset = 1; rx_code_group = 0;

    // Primera comma
    #25 rx_code_group = I_1;

    // Dato invalido
    #20 rx_code_group = 10'b011011_0000;
    ////////////////////////////////////////////////////////////////////////

    // Prueba #4
    #20 reset = 0;
    #25 reset = 1; rx_code_group = 0;

    // Primera comma
    #25 rx_code_group = I_1;
    #20 rx_code_group = D16_2_1;


    // Segunda comma
    #20 rx_code_group = I_2;
    #20 rx_code_group = D16_2_1;

    // Tercera comma
    #20 rx_code_group = I_1;
    #20 rx_code_group = D16_2_1;

    // Caracter de Start correcto
    #20 rx_code_group = S_1;

    // Caracter de Datos correcto
    #20 rx_code_group = D1_2;

    // Caracter de Datos incorrecto 1
    #20 rx_code_group = 10'b111111_1110;

    // Caracter de Datos incorrecto 2
    #20 rx_code_group = 10'b111111_0111;

    // Caracter de Datos incorrecto 3
    #20 rx_code_group = 10'b011111_1111;

    // Caracter de Datos incorrecto 4
    #20 rx_code_group = 10'b101111_1111;
    ////////////////////////////////////////////////////////////////////////

    // Prueba #5
    #20 reset = 0;
    #25 reset = 1; rx_code_group = 0;
    

    // Primera comma
    #25 rx_code_group = I_1;
    #20 rx_code_group = D16_2_1;


    // Segunda comma
    #20 rx_code_group = I_1;
    #20 rx_code_group = D16_2_1;

    // Tercera comma
    #20 rx_code_group = I_1;
    #20 rx_code_group = D16_2_1;

    // Caracter de Start correcto
    #20 rx_code_group = S_2;

    // Caracter de Datos correcto
    #20 rx_code_group = D2_2;

    // Caracter de Datos incorrecto 1
    #20 rx_code_group = 10'b111111_1111;

    // Caracter de Datos correcto 1
    #20 rx_code_group = D8_2;

    // Caracter de Datos incorrecto 2
    #20 rx_code_group = 10'b111110_1111;

    // Caracter de Datos incorrecto 3
    #20 rx_code_group = 10'b011111_1111;

    // Caracter de Datos incorrecto 4
    #20 rx_code_group = 10'b011111_0111;
    ////////////////////////////////////////////////////////////////////////

    // Prueba #6
    #20 reset = 0;
    #25 reset = 1; rx_code_group = 0;
    

    // Primera comma
    #25 rx_code_group = I_1;
    #20 rx_code_group = D16_2_1;


    // Segunda comma
    #20 rx_code_group = I_1;
    #20 rx_code_group = D16_2_1;

    // Tercera comma
    #20 rx_code_group = I_1;
    #20 rx_code_group = D16_2_1;

    // Caracter de Start correcto
    #20 rx_code_group = D3_2;

    // Caracter de Datos correcto
    #20 rx_code_group = D2_2;

    // Caracter de Datos incorrecto 1
    #20 rx_code_group = 10'b111111_1111;

    // Caracter de Datos correcto 1
    #20 rx_code_group = D2_1;

    // Caracter de Datos correcto 2
    #20 rx_code_group = D0_1;

    // Caracter de Datos correcto 3
    #20 rx_code_group = D0_2;
    ////////////////////////////////////////////////////////////////////////

    #200 $finish;                         // Finaliza la simulacion
  end

  always begin                            // Se genera un reloj con periodo de 10 unidades de tiempo
    #5 clk = !clk;
  end

endmodule