/* ***********************************************************
                    Universidad de Costa Rica
                 Escuela de Ingenieria Electrica
                            IE0323
                   Circuitos Digitales II

                    tesbench_transmit.v

Autor: José Andrés Guerrero Álvarez <Jose.guerreroalvarez@ucr.ac.cr>
Fecha: 23/06/2024

Descripcion: 
***********************************************************/
// Includes
`include "transmit_ordered_set.v"
`include "transmit_codegroup.v"

/* Probador, se agrega las conexiones entre el cajero
"transmit_ordered.v" y "transmit_ordered_set". */

module Testbench ();

    output reg clk, rst, power_on, tx_en; //SALIDAS
    output reg [7:0] data_o_set;
    input [9:0] tx_code_group;  //ENTRADA
    input tx_oset_indicate;
    input[7:0] tx_o_set;

PCS_TRASMIT_ORDERED_SET transmit_uno
    (.clk(clk), .rst(rst), .power_on(power_on), .tx_o_set(tx_o_set), .tx_en(tx_en), .tx_oset_indicate(tx_oset_indicate));

PCS_TRASMIT_CODE_GROUP transmit_dos
    (.clk(clk), .rst(rst), .power_on(power_on), .tx_o_set(tx_o_set), .tx_oset_indicate(tx_oset_indicate), .tx_code_group(tx_code_group), .data_o_set(data_o_set));

    // Modo de conexion ".ENTRADA(CABLE)"

    //Se define el reloj
    initial 
        begin
            clk = 0;
        end
    always #5 clk = ~clk;

    initial 
        begin
        $dumpfile ("ondas.vcd");
        $dumpvars;
        //Especificacion de las pruebas para el protocolo
        //PRUEBA 1 
        #0 rst = 0;
        #0 data_o_set = 8'b00000000;        
        #20 rst = 1; 
        #0 power_on = 1;

        #0 tx_en = 0;
        #130 tx_en = 1; 
        #0 data_o_set = 8'b00000111;
        #10 tx_en = 0;
        #10 tx_en = 1;
        #40 tx_en = 0;
        #60 rst = 0;

        #20 $finish;
        end

endmodule  
