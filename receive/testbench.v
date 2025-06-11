/* Universidad de Costa Rica
   Escuela de Ingenieria Electrica | Circuitos Digitales II - IE0523
   Proyecto Final | Diseno de un bloque de PCS tipo 1000BASE-X
   Profesor: Enrique Coen 
   Estudiantes:  Elizabeth Matamoros Bojorge-C04652
                Elian Jimenez Quesada-C13983
                Jose Andres Guerrero Alvarez-B63162
*/
`include "receptor.v"

// Testbench + Tester 

module receptor_tb;
    // Entradas
    reg reset;             // Senal de reset
    reg gtx_clk;           // Reloj del sistema
    reg sync_status;       // Senal de sincronizacion desde el sincronizador
    reg [9:0] sudi;        // Datos recibidos del transceptor
    reg even;              // Senal que indica si el ciclo de reloj es par o impar

    // Salidas
    wire [7:0] rxd;        // Datos decodificados (8 bits)
    wire rx_dv, rx_er;     // Senales de datos validos y error de recepcion
    wire receiving;        // Senal de estado de recepcion

    // Inicializa la simulacion
    initial begin
        $dumpfile("receptor_tb.vcd"); // Archivo para guardar los resultados de la simulacion
        $dumpvars(-1, ut1);           // Variables a ser monitoreadas durante la simulacion
    end
    
    // Se definen los Code-Groups Especiales en RD (-)
    parameter [9:0] K28_5_RD_Minus_9C = 10'b001111_1010;
    parameter [9:0] K23_7_RD_Minus_F7 = 10'b111010_1000;
    parameter [9:0] K27_7_RD_Minus_FB = 10'b110110_1000;
    parameter [9:0] K29_7_RD_Minus_FD = 10'b101110_1000;

    // Se definen los Code-Groups Especiales en RD (+)
    parameter [9:0] K28_5_RD_Plus_9C = ~K28_5_RD_Minus_9C;
    parameter [9:0] K23_7_RD_Plus_F7 = ~K23_7_RD_Minus_F7;
    parameter [9:0] K27_7_RD_Plus_FB = ~K27_7_RD_Minus_FB;
    parameter [9:0] K29_7_RD_Plus_FD = ~K29_7_RD_Minus_FD;

    // Se define la tabla para Code-Groups de Datos Validos
    // RD (-)
    parameter [9:0] D0_0_RD_Minus_00    = 10'b100111_0100;
    parameter [9:0] D1_0_RD_Minus_01    = 10'b011101_0100;
    parameter [9:0] D2_0_RD_Minus_02    = 10'b101101_0100;
    parameter [9:0] D3_0_RD_Minus_03    = 10'b110001_1011;
    parameter [9:0] D4_0_RD_Minus_04    = 10'b110101_0100;
    parameter [9:0] D5_0_RD_Minus_05    = 10'b101001_1011;
    parameter [9:0] D6_0_RD_Minus_06    = 10'b011001_1011;
    parameter [9:0] D7_0_RD_Minus_07    = 10'b111000_1011;
    parameter [9:0] D8_0_RD_Minus_08    = 10'b111001_0100;
    parameter [9:0] D9_0_RD_Minus_09    = 10'b111001_1010;
    parameter [9:0] D5_6_RD_Minus_C5    = 10'b101001_0110;
    parameter [9:0] D16_2_RD_Minus_50   = 10'b011011_0101;
    
    // RD (+)
    parameter [9:0] D0_0_RD_Plus_00     = ~D0_0_RD_Minus_00;
    parameter [9:0] D1_0_RD_Plus_01     = ~D1_0_RD_Minus_01;
    parameter [9:0] D2_0_RD_Plus_02     = ~D2_0_RD_Minus_02;
    parameter [9:0] D3_0_RD_Plus_03     = ~D3_0_RD_Minus_03;
    parameter [9:0] D4_0_RD_Plus_04     = ~D4_0_RD_Minus_04;
    parameter [9:0] D5_0_RD_Plus_05     = ~D5_0_RD_Minus_05;
    parameter [9:0] D6_0_RD_Plus_06     = ~D6_0_RD_Minus_06;
    parameter [9:0] D7_0_RD_Plus_07     = ~D7_0_RD_Minus_07;
    parameter [9:0] D8_0_RD_Plus_08     = ~D8_0_RD_Minus_08;
    parameter [9:0] D9_0_RD_Plus_09     = ~D9_0_RD_Minus_09;
    parameter [9:0] D5_6_RD_Plus_C5     =  D5_6_RD_Minus_C5;
    parameter [9:0] D16_2_RD_Plus_50    = ~D16_2_RD_Minus_50;

    // Parametros para octetos de bits
    parameter [7:0] D0_0_RD_00_8b   = 8'b00000000;
    parameter [7:0] D1_0_RD_01_8b   = 8'b00000001;
    parameter [7:0] D2_0_RD_02_8b   = 8'b00000010;
    parameter [7:0] D3_0_RD_03_8b   = 8'b00000011;
    parameter [7:0] D4_0_RD_04_8b   = 8'b00000100;
    parameter [7:0] D5_0_RD_05_8b   = 8'b00000101;
    parameter [7:0] D6_0_RD_06_8b   = 8'b00000110;
    parameter [7:0] D7_0_RD_07_8b   = 8'b00000111;
    parameter [7:0] D8_0_RD_08_8b   = 8'b00001000;
    parameter [7:0] D9_0_RD_09_8b   = 8'b00001001;
    parameter [7:0] D5_6_RD_C5_8b   = 8'b11000101;
    parameter [7:0] D16_2_RD_50_8b  = 8'b01010000;

    // Secuencia simulacion 
    initial begin
        gtx_clk = 0;          // Inicializar el reloj en 0
        reset = 1;            // Inicializar la senal de reset en 0
        sync_status = 0;      // Inicializar la senal de sincronizacion en 0
        sudi = 0;             // Inicializar los datos recibidos en 0
        even = 0;             // Inicializar la senal de paridad en 0

        #10 reset = 0;        // Activar la senal de reset
        #25 reset = 1;        // Desactivar la senal de reset

        sync_status = 1'b1;   // Activar la senal de sincronizacion

        #15
        sudi = {1'b0, K28_5_RD_Minus_9C}; even = 1; // Enviar K28.5 en RD (-) para recepcion 
        #10
        even = 0;
        #10
        sudi = {1'b0, D16_2_RD_Plus_50};  // Enviar IDLE en RD (-) para recepcion
        #20
        sudi = {1'b0, K27_7_RD_Minus_FB}; // Enviar /S/ start_of_packed RD (-) para recepcion
        #30
        sudi = {1'b0, D2_0_RD_Minus_02}; // Enviar datos /D/ en RD (-) para recepcion
        #20
        sudi = {1'b0, D5_0_RD_Minus_05};  // Enviar datos /D/ en RD (-) para recepcion
        #20
        sudi = {1'b0, D6_0_RD_Minus_06};  // Enviar datos /D/ en RD (-) para recepcion
        #20
        sudi = {1'b0, D3_0_RD_Minus_03};  // Enviar datos /D/ en RD (-) para recepcion
        #20
        sudi = {1'b0, K29_7_RD_Minus_FD}; even = 1; // Enviar fin de paquete /T/ en RD (-) para recepcion
        #10
        even = 0; 
        #20
        sudi = {1'b0, K23_7_RD_Minus_F7}; // Enviar fin de paquete /R/ en RD (-) para recepcion
        #20
        sudi = {1'b0, K28_5_RD_Minus_9C}; // Enviar K28.5 en RD (-) para recepcion

        #200 $finish;  // Terminar la simulacion
    end

    // Generacion de los ciclos de reloj
    always begin
        #5 gtx_clk = !gtx_clk;  // Invertir el reloj cada 5 unidades de tiempo, creando un reloj con un periodo de 10 unidades de tiempo
    end

    // Instanciacion del modulo receptor_g6
    receptor_g6 ut1 (
        // Entradas del modulo receptor_g6
        .gtx_clk(gtx_clk),
        .reset(reset),
        .sudi(sudi),
        .sync_status(sync_status),
        .even(even),

        // Salidas del modulo receptor_g6
        .rxd(rxd),
        .rx_dv(rx_dv),
        .rx_er(rx_er),
        .receiving(receiving)
    );
endmodule
