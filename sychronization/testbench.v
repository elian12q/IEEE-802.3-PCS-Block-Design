/* Universidad de Costa Rica
   Escuela de Ingenieria Eléctrica | Circuitos Digitales II - IE0523
   Proyecto Final | Diseno de un bloque de PCS tipo 1000BASE-X
   Profesor: Enrique Coen 
   Estudiantes: Elizabeth Matamoros Bojorge-C04652
                Elián Jiménez Quesada-C13983
                Jose Andres Guerrero Alvarez-B63162
*/

`include "tester.v"
`include "synchronization.v"
                                        
module testbench;

    // Se definen tanto entradas como salidas de la maquina de estados como wire.
    wire clk, reset;
    wire [9:0] rx_code_group;
    wire rx_even, sync_status;
    wire [9:0] sudi;

    initial begin
    $dumpfile("resultados.vcd");            // dumpfile genera el archivo de resultados.
    $dumpvars(-1, U0);                      // dumpvars indica lo que contendra el archivo de rsultados. (-1, UO) = todas las señales de U0.
    end

    // Instanciacion del modulo bajo prueba.

    synchronization U0 (
    .clk                (clk),
    .reset              (reset),
    .rx_code_group      (rx_code_group),
    .rx_even            (rx_even),
    .sync_status        (sync_status),
    .sudi               (sudi)
    );

    // Instanciacion del probador.

    tester P0 (
    .clk                (clk),
    .reset              (reset),
    .rx_code_group      (rx_code_group),
    .rx_even            (rx_even),
    .sync_status        (sync_status),
    .sudi               (sudi)
    );
endmodule