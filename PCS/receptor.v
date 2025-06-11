/* Universidad de Costa Rica
   Escuela de Ingenieria Electrica | Circuitos Digitales II - IE0523
   Proyecto Final | Diseno de un bloque de PCS tipo 1000BASE-X
   Profesor: Enrique Coen 
   Estudiantes:  Elizabeth Matamoros Bojorge-C04652
                Elian Jimenez Quesada-C13983
                Jose Andres Guerrero Alvarez-B63162
*/
module receptor_g6(
    sync_status,
    reset,
    receiving,
    clk,
    rx_even,
    sudi,
    rx_er,
    rx_dv,
    rxd,
);

    // Entradas
    input reset;         // Senal de reset del sistema
    input clk;       // Reloj del sistema
    input sync_status;   // Señal de sincronizacion desde el sincronizador
    input rx_even;       // Senal que indica si el ciclo de reloj es par o impar
    input [9:0] sudi;    // Datos recibidos del transceptor

    // Salidas
    output reg [7:0] rxd;    // Datos decodificados (8 bits)
    output reg rx_dv;        // Senal de datos recibidos validos
    output reg rx_er;        // Senal de error de recepcion
    output reg receiving;    // Senal de estado de recepcion

    // Registros internos
    reg [3:0] state;         // Estado actual 
    reg [3:0] nxt_state;     // Siguiente estado 
    reg nxt_rx_dv;           // Siguiente valor de rx_dv
    reg nxt_rx_er;           // Siguiente valor de rx_er
    reg nxt_receiving;       // Siguiente valor de receiving
    reg even;                // ciclo par de la maquina receive
    reg sync_status_interno;
    

    // Definicion de parametros internos
    localparam DATA = 1'b1;

    // Definicion de estados del receptor 
    parameter LINK_FAILED       = 4'h1; // Estado de fallo de enlace
    parameter WAIT_FOR_K        = 4'h2; // Espera de un K-code
    parameter RX_K              = 4'h3; // Recepcion de un K-code
    parameter IDLE_D            = 4'h4; // Estado de inactividad
    parameter START_OF_PACKET   = 4'h5; // Inicio de paquete
    parameter RECEIVE           = 4'h6; // Recepcion de datos
    parameter RX_DATA           = 4'h7; // Decodificacion de datos recibidos
    parameter TRI_RRI           = 4'h8; // Transicion y recepcion de RRI

    // Definicion de Code-Groups especiales en RD (-)
    parameter [9:0] K28_5_RD_Minus_9C = 10'b001111_1010;
    parameter [9:0] K23_7_RD_Minus_F7 = 10'b111010_1000;
    parameter [9:0] K27_7_RD_Minus_FB = 10'b110110_1000;
    parameter [9:0] K29_7_RD_Minus_FD = 10'b101110_1000;


    // Definicion de Code-Groups especiales en RD (+)
    parameter [9:0] K28_5_RD_Plus_9C = ~K28_5_RD_Minus_9C;
    parameter [9:0] K23_7_RD_Plus_F7 = ~K23_7_RD_Minus_F7;
    parameter [9:0] K27_7_RD_Plus_FB = ~K27_7_RD_Minus_FB;
    parameter [9:0] K29_7_RD_Plus_FD = ~K29_7_RD_Minus_FD;

    // Definicion de Code-Groups de datos validos en RD (-)
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
    
    // Definicion de Code-Groups de datos validos en RD (+)
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
    parameter [9:0] D16_2_RD_Plus_50    = 10'b100100_0101;

    // Definicion de parametros para octetos de bits
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

    // Funcion para verificar si sudi es un K-code
    function reg SUDI_V_K(input [11:0] sudi);
    begin
        if (sudi[9:0] == K28_5_RD_Minus_9C || sudi[9:0] == K28_5_RD_Plus_9C)
            SUDI_V_K = 1'b1;
        else
            SUDI_V_K = 1'b0;
    end
    endfunction

    // Logica de estado
    always @(posedge clk) begin
        if (reset == 0) begin
            state <= LINK_FAILED; // Estado inicial despues de reset
            rx_dv <= nxt_rx_dv; // Actualiza la senal rx_dv
            rx_er <= nxt_rx_er; // Actualiza la senal rx_er
            receiving <= nxt_receiving; // Actualiza la senal receiving
        end else begin
            state <= nxt_state; // Transicion al siguiente estado
            rx_dv <= 1'b0; // Reinicia rx_dv
            rx_er <= 1'b0; // Reinicia rx_er
            rxd <= 8'b0; // Reinicia rxd
        end
    end

    // Asignar tx_code_group a rx_code_group en cada negedge clk
    always @(negedge clk) begin
        sync_status_interno <= sync_status;
    end

    // Logica combinacional para determinar el siguiente estado
    always @(*) begin
        nxt_state = state;          // Inicialmente, el siguiente estado es el actual
        nxt_receiving = receiving;  // Mantener el estado actual de receiving
        nxt_rx_er = rx_er;          // Mantener el estado actual de rx_er
        nxt_rx_dv = rx_dv;          // Mantener el estado actual de rx_dv

        rxd = 0;                 // Reiniciar datos recibidos
        rx_dv = 0;               // Reiniciar senal de datos validos
        rx_er = 0;               // Reiniciar senal de error
        receiving = 0;           // Reiniciar senal de recepción
        even = rx_even;

        case (state)
            // Estado inicial
            LINK_FAILED: begin
                if (sync_status_interno) begin
                    nxt_state = WAIT_FOR_K; // Esperar un K-code si sync_status esta activo
                end else begin
                    nxt_state = LINK_FAILED; // Mantener el estado si sync_status no esta activo
                end
            end

            // Espera por un K-code
            WAIT_FOR_K: begin
                if (sudi == K28_5_RD_Minus_9C || sudi == K28_5_RD_Plus_9C) begin
                    nxt_state = RX_K; // Transicion al estado RX_K si se recibe un K-code y es un ciclo par
                end else begin
                    nxt_state = WAIT_FOR_K; // Mantener el estado si no se recibe un K-code
                end
            end

            // Recepcion de K-code
            RX_K: begin
                if (sudi == D5_6_RD_Minus_C5 | sudi == D16_2_RD_Minus_50 | sudi == D16_2_RD_Plus_50) begin
                    nxt_state = IDLE_D; // Transicion al estado IDLE_D si se recibe un codigo valido
                end else begin
                    nxt_state = RX_K; // Mantener el estado si no se recibe un codigo valido
                end
            end

            // Estado de inactividad
            IDLE_D: begin
                receiving = 1; // Indicar que esta recibiendo datos
                if (sudi == K27_7_RD_Plus_FB || sudi == K27_7_RD_Minus_FB) begin
                    nxt_state = START_OF_PACKET; // Transicion al estado START_OF_PACKET si se recibe un codigo de inicio de paquete
                end else begin
                    nxt_state = IDLE_D; // Mantener el estado si no se recibe un codigo de inicio de paquete
                end
            end

            // Inicio del paquete
            START_OF_PACKET: begin
                rx_dv = 1'b1; 	    // Indicar que los datos recibidos son validos
                rxd = 8'b01010101; // Codigo de inicio de paquete
                nxt_state = RECEIVE; // Transicion al estado RECEIVE
            end

            // Recepcion de datos
            RECEIVE: begin
                if (sudi == K29_7_RD_Minus_FD || sudi == K29_7_RD_Plus_FD) begin
                    if (even) begin
                        nxt_state = TRI_RRI; // Transicion al estado TRI_RRI si se recibe un codigo de final de paquete
                    end
                end else if (
                (sudi == D0_0_RD_Minus_00) | (sudi == D1_0_RD_Minus_01) | (sudi == D2_0_RD_Minus_02) | (sudi == D3_0_RD_Minus_03) | (sudi == D4_0_RD_Minus_04) | 
                (sudi == D5_0_RD_Minus_05) | (sudi == D6_0_RD_Minus_06) | (sudi == D7_0_RD_Minus_07) | (sudi == D8_0_RD_Minus_08) | (sudi == D9_0_RD_Minus_09) |
                (sudi == D0_0_RD_Plus_00) | (sudi == D1_0_RD_Plus_01) | (sudi == D2_0_RD_Plus_02) | (sudi == D3_0_RD_Plus_03) | (sudi == D4_0_RD_Plus_04) | 
                (sudi == D5_0_RD_Plus_05) | (sudi == D6_0_RD_Plus_06) | (sudi == D7_0_RD_Plus_07) | (sudi == D8_0_RD_Plus_08) | (sudi == D9_0_RD_Plus_09)) begin
                    nxt_state = RX_DATA; // Transicion al estado RX_DATA si se recibe un codigo de datos validos
                end else begin
                    nxt_state = RECEIVE; // Mantener el estado si no se recibe un codigo valido
                end
            end

            // Decodificacion de datos recibidos
            RX_DATA: begin
                nxt_state = RECEIVE; // Volver al estado RECEIVE despues de decodificar los datos
                case (sudi[9:0])
                    D0_0_RD_Minus_00: rxd   = D0_0_RD_00_8b;
                    D1_0_RD_Minus_01: rxd   = D1_0_RD_01_8b;
                    D2_0_RD_Minus_02: rxd   = D2_0_RD_02_8b;
                    D3_0_RD_Minus_03: rxd   = D3_0_RD_03_8b;
                    D4_0_RD_Minus_04: rxd   = D4_0_RD_04_8b;
                    D5_0_RD_Minus_05: rxd   = D5_0_RD_05_8b;
                    D6_0_RD_Minus_06: rxd   = D6_0_RD_06_8b;
                    D7_0_RD_Minus_07: rxd   = D7_0_RD_07_8b;
                    D8_0_RD_Minus_08: rxd   = D8_0_RD_08_8b;
                    D9_0_RD_Minus_09: rxd   = D9_0_RD_09_8b;
                    D5_6_RD_Minus_C5: rxd   = D5_6_RD_C5_8b;
                    D16_2_RD_Minus_50: rxd  = D16_2_RD_50_8b;
                    ////////////////////////////////////////
                    D0_0_RD_Plus_00: rxd    = D0_0_RD_00_8b;
                    D1_0_RD_Plus_01: rxd    = D1_0_RD_01_8b;
                    D2_0_RD_Plus_02: rxd    = D2_0_RD_02_8b;
                    D3_0_RD_Plus_03: rxd    = D3_0_RD_03_8b;
                    D4_0_RD_Plus_04: rxd    = D4_0_RD_04_8b;
                    D5_0_RD_Plus_05: rxd    = D5_0_RD_05_8b;
                    D6_0_RD_Plus_06: rxd    = D6_0_RD_06_8b;
                    D7_0_RD_Plus_07: rxd    = D7_0_RD_07_8b;
                    D8_0_RD_Plus_08: rxd    = D8_0_RD_08_8b;
                    D9_0_RD_Plus_09: rxd    = D9_0_RD_09_8b;
                    D5_6_RD_Plus_C5: rxd    = D5_6_RD_C5_8b;
                    D16_2_RD_Plus_50: rxd   = D16_2_RD_50_8b;
                    default: rxd = 8'b00000000; // Valor por defecto para casos no definidos
                endcase
            end

            // Transicion y recepcion de RRI
            TRI_RRI: begin
                if (sudi == K23_7_RD_Minus_F7 || sudi == K23_7_RD_Plus_F7) begin
                    nxt_state = TRI_RRI; // Mantener el estado si se recibe un codigo de RRI
                end else if (sudi == K28_5_RD_Minus_9C || sudi == K28_5_RD_Plus_9C) begin
                    nxt_state = RX_K; // Transicion al estado RX_K si se recibe un K-code
                end else begin 
                    nxt_state = TRI_RRI; // Mantener el estado si no se recibe un codigo valido
                end
            end
            default: begin
                nxt_state = LINK_FAILED; // Estado por defecto en caso de error
            end
        endcase
    end
endmodule
