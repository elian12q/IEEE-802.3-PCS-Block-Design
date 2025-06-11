/* Universidad de Costa Rica
   Escuela de Ingenieria Eléctrica | Circuitos Digitales II - IE0523
   Proyecto Final | Diseno de un bloque de PCS tipo 1000BASE-X
   Profesor: Enrique Coen 
   Estudiantes: Elizabeth Matamoros Bojorge-C04652
                Elián Jiménez Quesada-C13983
                Jose Andres Guerrero Alvarez-B63162
*/

module synchronization(
    //inputs
    input clk, reset, 
    input [9:0] tx_code_group,

    //outputs
    output reg rx_even, sync_status,
    output reg [9:0] sudi
);
    // Asignacion de estados
    parameter LOSS_OF_SYNC      = 5'b00001;             // Codificacion one hot
    parameter COMMA_DETECTED    = 5'b00010;             
    parameter ACQUIRE_SYNC      = 5'b00100;
    parameter SYNC_ACQUIRED_1   = 5'b01000;
    parameter SYNC_ACQUIRED_2   = 5'b10000;

    // Variables intermedias
    reg [4:0] state, nxt_state;

    reg [2:0] count_cgg, nxt_count_cgg;                 // Contador de code_groups correctos
    reg [2:0] count_cgb, nxt_count_cgb;                 // Contador de code_groups incorrectos 
    reg [2:0] count_comma, nxt_count_comma;             // Contador de commas
    reg [9:0] rx_code_group;
    reg [9:0] prev_rx_code_group;                       // Para almacenar el valor anterior de rx_code_group

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

    // Flip-flops
    always @(posedge clk) begin
        if (reset == 0) begin
            state               <= LOSS_OF_SYNC;    // Estado inicial
            count_cgg           <= 0;
            count_cgb           <= 0;
            count_comma         <= 0;
            rx_even             <= 0;
            sync_status         <= 0;
            sudi                <= 0;

        end else begin
            state               <= nxt_state;
            count_cgg           <= nxt_count_cgg;
            count_cgb           <= nxt_count_cgb;
            count_comma         <= nxt_count_comma;
            prev_rx_code_group  <= rx_code_group;
            

            // Si el estado es COMMA_DETECTED, rx_even = 1, sino rx_even = !rx_even. Se genera en la logica secuencial para que que cambie con cada ciclo de reloj
            if (nxt_state == COMMA_DETECTED) begin
                rx_even <= 1;
            end else begin
                rx_even <= !rx_even;
            end
        end
    end

    // Asignar tx_code_group a rx_code_group en cada negedge clk
    always @(negedge clk) begin
        rx_code_group <= tx_code_group;
    end

    // Logica combinacional
    always @(*) begin

        // Valores por defecto. Hace que los valores futuros mantengan los valores presentes.
        nxt_state = state;
        nxt_count_cgg = count_cgg;
        nxt_count_cgb = count_cgb;
        nxt_count_comma = count_comma;

        sync_status = 0;
        sudi = rx_code_group; // Genera los 10 bits de salida de sudi

        case (state)
            LOSS_OF_SYNC: begin

                // Se reinician los contadores
                count_comma = 0;
                count_cgb = 0;
                count_cgg = 0;

                // No hay sincronizacion
                sync_status = 0;

                // Si recibe una comma pasa al estado COMMA_DETECTED y aumenta el contador count_comma
                if (rx_code_group == I_1 | rx_code_group == I_2) begin
                    nxt_count_comma = count_comma + 1;
                    nxt_state = COMMA_DETECTED;  
                    
                // Si no se recibe ninguna comma se mantiene en el estado LOSS_OF_SYNC
                end else begin
                    nxt_state = LOSS_OF_SYNC;
                end  
            end

            COMMA_DETECTED: begin

                // Si se recibe un dato valido 5.6 o 16.2 y count_comma = 3 pasa al estado SYNC_ACQUIRED_1
                if (rx_code_group == D5_6_1 | rx_code_group == D5_6_2 | rx_code_group == D16_2_1 | rx_code_group == D16_2_2) begin
                    if (count_comma == 3) begin
                        nxt_state = SYNC_ACQUIRED_1;

                    // Si se recibe una dato valido 5.6 o 16.2 y count_comma < 3 pasa al estado ACQUIRE_SYNC
                    end else begin
                        nxt_state = ACQUIRE_SYNC;
                    end
                // Este else if hace que se mantenga el estado COMMA_DETECTED si aun no ha llegado un dato valido 5.6 o 16.2
                end else if (rx_code_group == I_1 | rx_code_group == I_2) begin
                    nxt_state = COMMA_DETECTED;
                
                // Si llega cualquier otro dato pasa al estado LOSS_OF_SYNC
                end else begin
                    nxt_state = LOSS_OF_SYNC;
                end
                
            end

            ACQUIRE_SYNC: begin

                // Si recibe una comma y rx_even = 0, pasa al estado COMMA_DETECTED y aumenta el contador count_comma
                if ((rx_code_group == I_1) | (rx_code_group == I_2)) begin
                    if (rx_even == 0) begin
                        nxt_count_comma = count_comma + 1;
                        nxt_state = COMMA_DETECTED;
                    // Si rx_even != 0 se mantiene en el estado ACQUIRE_SYNC
                    end else begin
                        nxt_state = ACQUIRE_SYNC;
                    end
                // Este else if hace que se mantenga el estado ACQUIRE_SYNC si aun no ha llegado una comma
                end else if (rx_code_group == D5_6_1 | rx_code_group == D5_6_2 | rx_code_group == D16_2_1 | rx_code_group == D16_2_2) begin
                    nxt_state = ACQUIRE_SYNC;
                
                // Si llega cualquier otro dato pasa al estado LOSS_OF_SYNC
                end else begin
                    nxt_state = LOSS_OF_SYNC;
                end
            end

            SYNC_ACQUIRED_1: begin
                count_comma = 0;
                count_cgb = 0;
                count_cgg = 0;
                sync_status = 1;
                // Si el code-group es correcto:
                if ( // Si el code-group esta entre D0.0 y D9.0 se considera correcto
                    (rx_code_group == D0_1) | (rx_code_group == D0_2) | (rx_code_group == D1_1) | (rx_code_group == D1_2) | (rx_code_group == D2_1) | 
                    (rx_code_group == D2_2) | (rx_code_group == D3_1) | (rx_code_group == D3_2) | (rx_code_group == D4_1) | (rx_code_group == D4_2) | 
                    (rx_code_group == D5_1) | (rx_code_group == D5_2) | (rx_code_group == D6_1) | (rx_code_group == D6_2) | (rx_code_group == D7_1) |
                    (rx_code_group == D7_2) | (rx_code_group == D8_1) | (rx_code_group == D8_2) | (rx_code_group == D9_1) | (rx_code_group == D9_2) |

                    // Si el code group es 5.6 o 16.2 se considera correcto
                    (rx_code_group == D5_6_2) | (rx_code_group == D5_6_2) | (rx_code_group == D16_2_1) | (rx_code_group == D16_2_2) |
                    
                    // Si el code-group es I, S, R, o T se considera correcto
                    (rx_code_group == I_1) | (rx_code_group == I_2) | (rx_code_group == S_1) | (rx_code_group == S_2) | (rx_code_group == T_1) | (rx_code_group == T_2) | 
                    (rx_code_group == R_1) | (rx_code_group == R_2)) begin
                    
                    // Si es correcto se mantiene en el estado SYNC_ACQUIRED_1
                    nxt_state = SYNC_ACQUIRED_1;

                // Si el code-group es incorrecto:
                end else begin
                    // Si es incorrecto pasa al estado SYNC_ACQUIRED_2 y aumenta el contador count_cgb
                    nxt_count_cgb = count_cgb + 1;
                    nxt_state = SYNC_ACQUIRED_2;
                end
            end

            SYNC_ACQUIRED_2: begin
                sync_status = 1;
                // Si el code-group es correcto:
                if ( // Si el code-group esta entre D0.0 y D9.0 se considera correcto
                    (rx_code_group == D0_1) | (rx_code_group == D0_2) | (rx_code_group == D1_1) | (rx_code_group == D1_2) | (rx_code_group == D2_1) | 
                    (rx_code_group == D2_2) | (rx_code_group == D3_1) | (rx_code_group == D3_2) | (rx_code_group == D4_1) | (rx_code_group == D4_2) | 
                    (rx_code_group == D5_1) | (rx_code_group == D5_2) | (rx_code_group == D6_1) | (rx_code_group == D6_2) | (rx_code_group == D7_1) | 
                    (rx_code_group == D7_2) | (rx_code_group == D8_1) | (rx_code_group == D8_2) | (rx_code_group == D9_1) | (rx_code_group == D9_2) |

                    // Si el code-group es 5.6 o 16.2 se considera correcto
                    (rx_code_group == D5_6_2) | (rx_code_group == D5_6_2) | (rx_code_group == D16_2_1) | (rx_code_group == D16_2_2) |
                    
                    // Si el code-group es I, S, R, o T se considera correcto
                    (rx_code_group == I_1) | (rx_code_group == I_2) | (rx_code_group == S_1) | (rx_code_group == S_2) | (rx_code_group == T_1) | (rx_code_group == T_2) | 
                    (rx_code_group == R_1) | (rx_code_group == R_2)) begin
                    
                // Si el code-group es correcto se analiza count_cgg 

                    // Si count_cgg == 3 regresa al estado SYNC_ACQUIRED_1
                    if (count_cgg == 3) begin
                        nxt_state = SYNC_ACQUIRED_1;

                    // Sino, se mantiene en el estado SYNC_ACQUIRED_2 y aumenta el contador count_cgg
                    end else begin

                        // Este if hace que count_cgg solo incremente cuando hay un nuevo rx_code_group
                        if (rx_code_group != prev_rx_code_group)begin
                            nxt_count_cgg = count_cgg + 1;
                            nxt_state = SYNC_ACQUIRED_2;
                        end
                    end
                    
                // Si el code-group es incorrecto:
                end else begin
                    count_cgg = 0; // Se reinicia el contador count_cgg

                    // Si el code-group es incorrecto se analiza count_cgb

                    // Si count_cgb == 4 pasa al estado LOSS_OF_SYNC
                    if (count_cgb == 4) begin
                        nxt_state = LOSS_OF_SYNC;

                    // Sino, se mantiene en el estado SYNC_ACQUIRED_2 y aumenta el contador count_cgb
                    end else begin

                        // Este if hace que count_cgb solo incremente cuando hay un nuevo rx_code_group
                        if (rx_code_group != prev_rx_code_group)begin
                            nxt_count_cgb = count_cgb + 1;
                            nxt_state = SYNC_ACQUIRED_2;
                        end
                    end
                end
            end
        endcase
    end
endmodule