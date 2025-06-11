/* Universidad de Costa Rica
   Escuela de Ingenieria Eléctrica | Circuitos Digitales II - IE0523
   Proyecto Final | Diseno de un bloque de PCS tipo 1000BASE-X
   Profesor: Enrique Coen 
   Estudiantes: Elizabeth Matamoros Bojorge-C04652
                Elián Jiménez Quesada-C13983
                Jose Andres Guerrero Alvarez-B63162
*/

// Includes
`include "transmit_ordered_set.v"
`include "transmit_codegroup.v"
`include "synchronization.v"
`include "receptor.v"
`include "tester.v"

module testbench ();

    // Se definen tanto entradas como salidas de la maquina de estados como wire
    wire clk, reset, power_on, tx_en; 
    wire [7:0] data_o_set;
    wire [9:0] tx_code_group;  
    wire tx_oset_indicate;
    wire [7:0] tx_o_set;

    wire rx_even, sync_status;
    wire [9:0] sudi;

    wire [7:0] rxd;
    wire rx_dv;        
    wire rx_er;        
    wire receiving;   


    initial begin
    $dumpfile("ondas.vcd");                 // dumpfile genera el archivo de resultados
    $dumpvars(-1, U0);                      // dumpvars indica lo que contendra el archivo de rsultados. (-1, UO) = todas las señales de U0
    $dumpvars(-1, U1);                      
    $dumpvars(-1, U2);
    $dumpvars(-1, U3);
    $dumpvars(-1, P0);
    end

// Instanciacion de la maquina transmit_ordered_set

PCS_TRASMIT_ORDERED_SET U0
    (
    .clk                (clk),              // Modo de conexion ".ENTRADA(CABLE)"
    .reset              (reset), 
    .power_on           (power_on), 
    .tx_o_set           (tx_o_set), 
    .tx_en              (tx_en), 
    .tx_oset_indicate   (tx_oset_indicate)
    );

// Instanciacion de la maquina transmit_codegroup

PCS_TRASMIT_CODE_GROUP U1
    (
    .clk                (clk), 
    .reset              (reset), 
    .power_on           (power_on), 
    .tx_o_set           (tx_o_set), 
    .tx_oset_indicate   (tx_oset_indicate), 
    .tx_code_group      (tx_code_group), 
    .data_o_set         (data_o_set)
    );

// Instanciacion de la maquina receive

synchronization U2 (
    .clk                (clk),
    .reset              (reset),
    .tx_code_group      (tx_code_group),
    .rx_even            (rx_even),
    .sync_status        (sync_status),
    .sudi               (sudi)
    );

receptor_g6 U3 (
    .clk                (clk),
    .reset              (reset),
    .rx_even            (rx_even),
    .sync_status        (sync_status),
    .sudi               (sudi),
    .rxd                (rxd),
    .rx_dv              (rx_dv),
    .rx_er              (rx_er),
    .receiving          (receiving)
    );

// Instanciacion del probador

tester P0 (
    .clk                (clk),
    .reset              (reset),
    .rx_even            (rx_even),
    .sync_status        (sync_status),
    .sudi               (sudi),

    .power_on           (power_on), 
    .tx_o_set           (tx_o_set), 
    .tx_en              (tx_en), 
    .tx_oset_indicate   (tx_oset_indicate),
    .tx_code_group      (tx_code_group), 
    .data_o_set         (data_o_set)
    );
endmodule  
