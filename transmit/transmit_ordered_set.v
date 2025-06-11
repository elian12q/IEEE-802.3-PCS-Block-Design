/* ***********************************************************
                    Universidad de Costa Rica
                 Escuela de Ingenieria Electrica
                            IE0323
                   Circuitos Digitales II

                            transmit_ordered_set.v

Autor: José Andrés Guerrero Álvarez <Jose.guerreroalvarez@ucr.ac.cr>
Fecha: 23/06/2024

Descripcion: 
***********************************************************/
module PCS_TRASMIT_ORDERED_SET(
    input wire clk, rst, power_on,
    input wire tx_en, tx_oset_indicate, tx_even,
    output reg [7:0] tx_o_set
);
    reg [5:0] state, nxt_state; //Ambas variables almacenadas en registros hechos con FF 


    // Asignación de estados
    // Un FF por bit de cada variable
    parameter XMIT_DATA           = 6'b000001;
    parameter START_OF_PACKET     = 6'b000010;
    parameter TX_PACKET           = 6'b000100;
    parameter TX_DATA             = 6'b001000;
    parameter END_OF_PACKET_NOEXT = 6'b010000;
    parameter EPO2_NOEXT          = 6'b100000;

    //Asignacion de varaiables del paquete
    parameter I   = 8'b10111100; 
    parameter S   = 8'b11111011;
    parameter R   = 8'b11110111;
    parameter T   = 8'b11111101;
    parameter D   = 8'b11111111;

    parameter D0  = 8'b00000000; 
    parameter D1  = 8'b00000001; 
    parameter D2  = 8'b00000010; 
    parameter D3  = 8'b00000011; 
    parameter D4  = 8'b00000100; 
    parameter D5  = 8'b00000101; 
    parameter D6  = 8'b00000110; 
    parameter D7  = 8'b00000111; 
    parameter D8  = 8'b00001000; 
    parameter D9  = 8'b00001001; 


    // Memoria de estados
    always @(posedge clk) 
    begin
        if (rst == 0)
        // Entrada de reinicio. Si rst=1 el generador funciona normalmente.
        // En caso contrario, el generador vuelve a su estado inicial
        // y todas las salidas toman el valor de cero.
        // Asignacion de los valores por defecto al reiniciar
            begin
            state <= XMIT_DATA;
            end
        else
            begin
            state <= nxt_state;
            end
    end
    always @*
        begin
            //Valores por defecto
            //Hace que los valores futuros mantengan los valores presentes
            nxt_state = state;

            case (state)

                XMIT_DATA:
                    begin
                        if (power_on && rst)
                        begin
                            tx_o_set = I;
                            if (tx_en && tx_oset_indicate) 
                                begin
                                    nxt_state = START_OF_PACKET;
                                end
                        end
                    end

                START_OF_PACKET:
                    begin
                        tx_o_set = S;
                        if (tx_oset_indicate) 
                        begin
                            nxt_state = TX_PACKET;    
                        end
                    end

                TX_PACKET :
                    begin
                        if (tx_en)
                            begin
                                nxt_state = TX_DATA;    
                            end
                        else
                            begin
                                nxt_state = END_OF_PACKET_NOEXT;
                            end 
                    end

                TX_DATA:
                    begin
                        tx_o_set = D;
                        if (tx_oset_indicate) 
                            begin
                                nxt_state = TX_PACKET;    
                            end
                    end

                END_OF_PACKET_NOEXT:
                    begin
                        tx_o_set = T;
                        if (tx_oset_indicate)
                            begin
                                nxt_state = EPO2_NOEXT;
                            end
                    end

                EPO2_NOEXT:
                    begin
                        tx_o_set = R;
                        if (/*!tx_even &&*/ tx_oset_indicate)
                            begin
                                nxt_state = XMIT_DATA;
                            end
                    end

                default : nxt_state =  XMIT_DATA;
                //Si la maquina entra en un estado inesperado regresa al incio
            endcase
        end // Este end corresponde al always @(*) de la logica combinacional
endmodule