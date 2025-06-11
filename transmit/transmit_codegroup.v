/* ***********************************************************
                    Universidad de Costa Rica
                 Escuela de Ingenieria Electrica
                            IE0323
                   Circuitos Digitales II

                    transmit_codegroup.v

Autor: José Andrés Guerrero Álvarez <Jose.guerreroalvarez@ucr.ac.cr>
Fecha: 23/06/2024

Descripcion: 
***********************************************************/
module PCS_TRASMIT_CODE_GROUP(
    input wire clk, rst, power_on,
    input wire [7:0] tx_o_set,
    input wire [7:0] data_o_set,
    output reg [9:0] tx_code_group,
    output reg tx_oset_indicate
);
    reg [7:0] state, nxt_state; //Ambas variables almacenadas en registros hechos con FF 
    reg tx_even, nxt_tx_even; //VARIABLE INTERNA
    reg nxt_tx_oset_indicate; //VARIABLE INTERNA
    reg tx_disparity, nxt_tx_disparity;

    // Asignación de estados
    // Un FF por bit de cada variable 
    parameter GENERATE_CODE_GROUPS = 8'b00000001;
    parameter IDLE_DISPARITY_TEST  = 8'b00000010;
    parameter IDLE_DISPARITY_OK    = 8'b00000100;
    parameter IDLE_I2B             = 8'b00001000;
    parameter IDLE_DISPARITY_WRONG = 8'b00010000;
    parameter IDLE_I1B             = 8'b00100000;
    parameter DATA_GO              = 8'b01000000;
    parameter SPECIAL_GO           = 8'b10000000;

    //Asignacion de varaiables del paquete
    parameter I       = 8'b10111100;  //par , k28.5
    parameter I_RDN   = 10'b0011111010 ;  
    parameter I_RDP   = 10'b1100000101 ; 

    parameter I1B     = 8'b11000101; //impar , D5.6
    parameter I1B_RDN = 10'b1010010110;
    parameter I1B_RDP = 10'b1010010110;

    parameter I2B     = 8'b01010000; //impar , D16.2
    parameter I2B_RDN = 10'b0110110101;
    parameter I2B_RDP = 10'b1001000101;

    parameter S       = 8'b11111011;
    parameter S_RDN   = 10'b1101101000;
    parameter S_RDP   = 10'b0010010111;

    parameter R       = 8'b11110111;
    parameter R_RDN   = 10'b1110101000;
    parameter R_RDP   = 10'b0001010111;

    parameter T       = 8'b11111101;
    parameter T_RDN   = 10'b1011101000;
    parameter T_RDP   = 10'b0100010111;

    parameter D       = 8'b11111111;

    parameter D0      = 8'b00000000;
    parameter D0_RDN  = 10'b1001110100;
    parameter D0_RDP  = 10'b0110001011; 

    parameter D1      = 8'b00000001;
    parameter D1_RDN  = 10'b0111010100;
    parameter D1_RDP  = 10'b1000101011; 

    parameter D2      = 8'b00000010;
    parameter D2_RDN  = 10'b1011010100; 
    parameter D2_RDP  = 10'b0100101011;

    parameter D3      = 8'b00000011;
    parameter D3_RDN  = 10'b1100011011;
    parameter D3_RDP  = 10'b1100010100;

    parameter D4      = 8'b00000100;
    parameter D4_RDN  = 10'b1101010100; 
    parameter D4_RDP  = 10'b0010101011;

    parameter D5      = 8'b00000101;
    parameter D5_RDN  = 10'b1010011011;
    parameter D5_RDP  = 10'b1010010100; 

    parameter D6      = 8'b00000110;
    parameter D6_RDN  = 10'b0110011011; 
    parameter D6_RDP  = 10'b0110010100;

    parameter D7      = 8'b00000111;
    parameter D7_RDN  = 10'b1110001011;
    parameter D7_RDP  = 10'b0001110100;

    parameter D8      = 8'b00001000;
    parameter D8_RDN  = 10'b1110010100;
    parameter D8_RDP  = 10'b0001101011;

    parameter D9      = 8'b00001001;
    parameter D9_RDN  = 10'b1110011010; 
    parameter D9_RDP  = 10'b1001010100;

    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    // Función para calcular la disparidad
    function rd_calculate;
        input [9:0] cg;
        input rd_start;
        reg [5:0] sub_block_6;
        reg [3:0] sub_block_4;
        reg [2:0] ones_6;
        reg [2:0] zeros_6;
        reg [1:0] ones_4;
        reg [1:0] zeros_4;
        reg rd_mid; // Disparidad al final del sub-bloque de 6 bits

        begin
            // Dividir el code_group en dos sub-bloques
            sub_block_6 = cg[9:4]; // Primeros 6 bits
            sub_block_4 = cg[3:0]; // Últimos 4 bits

            // Contar los unos y ceros en cada sub-bloque
            ones_6 = sub_block_6[0] + sub_block_6[1] + sub_block_6[2] + sub_block_6[3] + sub_block_6[4] + sub_block_6[5];
            zeros_6 = 6 - ones_6;
            ones_4 = sub_block_4[0] + sub_block_4[1] + sub_block_4[2] + sub_block_4[3];
            zeros_4 = 4 - ones_4;

            // Calcular la disparidad para el sub-bloque de 6 bits
            if (ones_6 > zeros_6 || sub_block_6 == 6'b000111) begin
                rd_mid = 1;
            end else if (zeros_6 > ones_6 || sub_block_6 == 6'b111000) begin
                rd_mid = 0;
            end else begin
                rd_mid = rd_start; // Mantener la misma disparidad si los unos == ceros
            end

            // Calcular la disparidad para el sub-bloque de 4 bits
            if (ones_4 > zeros_4 || sub_block_4 == 4'b0011) begin
                rd_calculate = 1;
            end else if (zeros_4 > ones_4 || sub_block_4 == 4'b1100) begin
                rd_calculate = 0;
            end else begin
                rd_calculate = rd_mid; // Mantener la misma disparidad si los unos == ceros
            end
        end
    endfunction

    // Llamar a la función para calcular la disparidad y asignar el resultado
    // always @(*) begin
        //rd_out = rd_calculate(code_group, rd_in);
    //end
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

    // Memoria de estados inicio de los 
    always @(posedge clk) 
    begin
        if (rst == 0)
        // Entrada de reinicio. Si rst=1 el generador funciona normalmente.
        // En caso contrario, el generador vuelve a su estado inicial
        // y todas las salidas toman el valor de cero.
        // Asignacion de los valores por defecto al reiniciar
            begin
            state <= GENERATE_CODE_GROUPS;
            tx_even <= 0;
            tx_oset_indicate <= 0;
            tx_disparity <= 0;
            end
        else 
            begin
            state <= nxt_state;
            tx_even <= nxt_tx_even;
            tx_oset_indicate <= nxt_tx_oset_indicate;
            tx_disparity <= nxt_tx_disparity;
            end                            
    end
    always @*
        begin
            //Valores por defecto
            //Hace que los valores futuros mantengan los valores presentes
            nxt_state = state;
            nxt_tx_even = tx_even;
            nxt_tx_oset_indicate = tx_oset_indicate;
            nxt_tx_disparity = tx_disparity;

            case (state)
                GENERATE_CODE_GROUPS:
                    begin
                        if (power_on && rst)
                            begin
                                if (tx_o_set == I) 
                                    begin
                                     nxt_state  = IDLE_DISPARITY_TEST;
                                    end
                                else if (tx_o_set == D) 
                                    begin
                                        nxt_tx_oset_indicate = 1;
                                        nxt_state  = DATA_GO;    
                                    end
                                else if (tx_o_set == S || tx_o_set == T || tx_o_set == R) 
                                    begin
                                        nxt_tx_oset_indicate = 1;
                                        nxt_state  = SPECIAL_GO;    
                                    end
                            end
                        nxt_tx_even = !nxt_tx_even;
                    end

                IDLE_DISPARITY_TEST:
                    begin
                        if (!tx_disparity ) 
                            begin
                                nxt_state = IDLE_DISPARITY_OK;
                            end
                        else 
                            begin
                                nxt_state = IDLE_DISPARITY_WRONG;
                            end
                        nxt_tx_even = !nxt_tx_even;
                    end

                IDLE_DISPARITY_OK:
                    begin
                        tx_code_group = I_RDN;
                        tx_disparity = rd_calculate(I_RDN, tx_disparity);
                        nxt_tx_even = 1;
                        nxt_state = IDLE_I2B;
                        nxt_tx_oset_indicate = 1;
                    end

                IDLE_I2B:
                    begin                
                        if (tx_disparity) 
                        begin
                            tx_code_group = I2B_RDP;
                            tx_disparity = rd_calculate(I2B_RDP, tx_disparity);
                        end
                        else 
                        begin
                            tx_code_group = I2B_RDN;
                            tx_disparity = rd_calculate(I2B_RDN, tx_disparity);
                        end
                        nxt_tx_even = 0;
                        nxt_tx_oset_indicate =0;
                        nxt_state = GENERATE_CODE_GROUPS;
                    end

                IDLE_DISPARITY_WRONG:
                    begin
                        tx_code_group = I_RDN;
                        tx_disparity = rd_calculate(I_RDN, tx_disparity);
                        nxt_tx_even = 1;
                        nxt_state = IDLE_I1B;
                        nxt_tx_oset_indicate = 1;
                    end

                IDLE_I1B:
                    begin
                        tx_disparity = rd_calculate(I_RDN, tx_disparity);
                        if (tx_disparity) 
                        begin
                            tx_code_group = I1B_RDP;
                            tx_disparity = rd_calculate(I1B_RDP, tx_disparity);
                        end
                        else 
                        begin
                            tx_code_group = I1B_RDN;
                            tx_disparity = rd_calculate(I1B_RDN, tx_disparity);
                        end
                        nxt_tx_even = 0;
                        nxt_tx_oset_indicate =0;
                        nxt_state = GENERATE_CODE_GROUPS;
                    end

                DATA_GO:
                    begin
                        if (tx_disparity)   
                            begin
                                if (data_o_set == D0) 
                                    begin
                                        tx_code_group = D0_RDP;
                                        nxt_tx_disparity = rd_calculate(D0_RDP, tx_disparity);        
                                    end
                                else if (data_o_set == D1) 
                                    begin
                                        tx_code_group = D1_RDP;
                                        nxt_tx_disparity = rd_calculate(D1_RDP, tx_disparity);        
                                    end
                                else if (data_o_set == D2) 
                                    begin
                                        tx_code_group = D2_RDP;
                                        nxt_tx_disparity = rd_calculate(D2_RDP, tx_disparity);        
                                    end
                                else if (data_o_set == D3) 
                                    begin
                                        tx_code_group = D3_RDP;
                                        nxt_tx_disparity = rd_calculate(D3_RDP, tx_disparity);        
                                    end
                                else if (data_o_set == D4) 
                                    begin
                                        tx_code_group = D4_RDP;
                                        nxt_tx_disparity = rd_calculate(D4_RDP, tx_disparity);        
                                    end
                                else if (data_o_set == D5) 
                                    begin
                                        tx_code_group = D5_RDP;
                                        nxt_tx_disparity = rd_calculate(D5_RDP, tx_disparity);        
                                    end
                                else if (data_o_set == D6) 
                                    begin
                                        tx_code_group = D6_RDP;
                                        nxt_tx_disparity = rd_calculate(D6_RDP, tx_disparity);        
                                    end
                                else if (data_o_set == D7) 
                                    begin
                                        tx_code_group = D7_RDP;
                                        nxt_tx_disparity = rd_calculate(D7_RDP, tx_disparity);        
                                    end
                                else if (data_o_set == D8) 
                                    begin
                                        tx_code_group = D8_RDP;
                                        nxt_tx_disparity = rd_calculate(D8_RDP, tx_disparity);        
                                    end
                                else if (data_o_set == D9) 
                                    begin
                                        tx_code_group = D9_RDP;
                                        nxt_tx_disparity = rd_calculate(D9_RDP, tx_disparity);        
                                    end
                            end
                        else 
                            begin
                                if (data_o_set == D0) 
                                    begin
                                        tx_code_group = D0_RDN;
                                        nxt_tx_disparity = rd_calculate(D0_RDN, tx_disparity);        
                                    end
                                else if (data_o_set == D1) 
                                    begin
                                        tx_code_group = D1_RDN;
                                        nxt_tx_disparity = rd_calculate(D1_RDN, tx_disparity);        
                                    end
                                else if (data_o_set == D2) 
                                    begin
                                        tx_code_group = D2_RDN;
                                        nxt_tx_disparity = rd_calculate(D2_RDN, tx_disparity);        
                                    end
                                else if (data_o_set == D3) 
                                    begin
                                        tx_code_group = D3_RDN;
                                        nxt_tx_disparity = rd_calculate(D3_RDN, tx_disparity);        
                                    end
                                else if (data_o_set == D4) 
                                    begin
                                        tx_code_group = D4_RDN;
                                        nxt_tx_disparity = rd_calculate(D4_RDN, tx_disparity);        
                                    end
                                else if (data_o_set == D5) 
                                    begin
                                        tx_code_group = D5_RDN;
                                        nxt_tx_disparity = rd_calculate(D5_RDN, tx_disparity);        
                                    end
                                else if (data_o_set == D6) 
                                    begin
                                        tx_code_group = D6_RDN;
                                        nxt_tx_disparity = rd_calculate(D6_RDN, tx_disparity);        
                                    end
                                else if (data_o_set == D7) 
                                    begin
                                        tx_code_group = D7_RDN;
                                        nxt_tx_disparity = rd_calculate(D7_RDN, tx_disparity);        
                                    end
                                else if (data_o_set == D8) 
                                    begin
                                        tx_code_group = D8_RDN;
                                        nxt_tx_disparity = rd_calculate(D8_RDN, tx_disparity);        
                                    end
                                else if (data_o_set == D9) 
                                    begin
                                        tx_code_group = D9_RDN;
                                        nxt_tx_disparity = rd_calculate(D9_RDN, tx_disparity);        
                                    end
                            end
                        nxt_state =  GENERATE_CODE_GROUPS;
                        nxt_tx_even = !nxt_tx_even;
                        nxt_tx_oset_indicate = 0;
                    end

                SPECIAL_GO:
                    begin
                        if (tx_disparity) 
                            begin
                                if (tx_o_set == S) 
                                        begin
                                            tx_code_group = S_RDP;
                                            nxt_tx_disparity = rd_calculate(S_RDP, tx_disparity);        
                                        end
                                else if (tx_o_set == T) 
                                        begin
                                            tx_code_group = T_RDP;
                                            nxt_tx_disparity = rd_calculate(T_RDP, tx_disparity);        
                                        end
                                else if (tx_o_set == R) 
                                        begin
                                            tx_code_group = R_RDP;
                                            nxt_tx_disparity = rd_calculate(R_RDP, tx_disparity);        
                                        end
                            end
                        else
                            begin
                                if (tx_o_set == S) 
                                        begin
                                            tx_code_group = S_RDN;
                                            nxt_tx_disparity = rd_calculate(S_RDN, tx_disparity);        
                                        end
                                else if (tx_o_set == T) 
                                        begin
                                            tx_code_group = T_RDN;
                                            nxt_tx_disparity = rd_calculate(T_RDN, tx_disparity);        
                                        end
                                else if (tx_o_set == R) 
                                        begin
                                            tx_code_group = R_RDN;
                                            nxt_tx_disparity = rd_calculate(R_RDN, tx_disparity);        
                                        end    
                            end
                            if (tx_o_set == D) 
                                begin
                                    nxt_state =  GENERATE_CODE_GROUPS;
                                    tx_oset_indicate = 0;
                                end
                        nxt_tx_even = !nxt_tx_even;
 
                    end

                default : nxt_state =   GENERATE_CODE_GROUPS;
                //Si la maquina entra en un estado inesperado regresa al incio
            endcase
        end // Este end corresponde al always @(*) de la logica combinacional
endmodule