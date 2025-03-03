#include <stdlib.h>
#include <iostream>
#include <verilated.h>
#include <verilated_vcd_c.h>
#include <string>

using namespace std;
#include "Vvending_machine.h"
#include "Vvending_machine___024root.h"
#define D_WIDTH 16
#define MAX_SIM_TIME 500
vluint64_t sim_time = 0;
int o_available_item_expected = 0;
int current = 0;
int success = 0;
int fail = 0;
int idk = 0;
const char* to_binary(int input) {
    string result = "";
    while (input > 0) {
        result = to_string(input % 2) + result;
        input = input / 2;
    }

    return ("0b" + result).c_str();
}

int temp1, temp2, temp3, temp4;
int coin[8] = {0, 100, 500, 600, 1000, 1100, 1500, 1600};
int coin_cnt[8] = {};
int coin_total = 0;
void init_temp() {
    temp1 = temp2 = temp3 = temp4 = 0;
    for(int i = 0; i < 8; i ++ ) coin_cnt[i] = 0;
    coin_total = 0;
}
int calc_coin() {
    coin_total = 0;
    for(int i = 1; i < 8; i++) coin_total += coin[i] * coin_cnt[i];
    return coin_total;
}

int main(int argc, char** argv, char** env) {
    Verilated::commandArgs(argc, argv);
    Vvending_machine* dut = new Vvending_machine;

    Verilated::traceEverOn(true);
    VerilatedVcdC *m_trace = new VerilatedVcdC;
    dut->trace(m_trace, 5);
    m_trace->open("waveform.vcd");

    


    while (sim_time < MAX_SIM_TIME) {
        dut->clk ^= 1;
        dut->eval();
        m_trace->dump(sim_time);
        sim_time++;


        if (sim_time >= 1 && sim_time < 2)
        {
            dut -> reset_n = 1;
        }

        if (sim_time >= 2 && sim_time < 3)
        {
            dut -> reset_n = 0;
        }

        if (sim_time >= 4 && sim_time < 8)
        {
            dut -> reset_n = 1;
            dut -> i_input_coin = 0;
            dut -> i_select_item = 0;
            dut -> i_trigger_return = 0;
        }
       
        //##############################################################################
        if (sim_time==8)
        {   
            printf(" initial test sim_time: %d\n", sim_time);
            // if (dut -> o_available_item == o_available_item_expected)
            // {
            //     success++;
            //     printf("PASSED  : o_available_item: %d, expected %d \n", dut -> o_available_item, o_available_item_expected);
            // }
               
        }
       
        switch (sim_time) { 
            //######################## 1. 물건 구매 후 반환 ###############################
            case 10:
                init_temp();
                printf("\n Test: select item then return. sim_time: %d\n", sim_time);
                printf("Behavior: +(1000,500), -400, return.\n");
                dut->i_input_coin = 0b110; 
                break;
            case 11:
                dut->i_input_coin = 0;
                break;
            case 12:    
                dut->i_select_item = 0b0001;
                break;
            case 13:
                dut->i_select_item = 0;
                temp1 = dut->o_output_item;
                break;
            case 14:
                dut->i_trigger_return = 1;
                break;
            case 15:
                dut->i_trigger_return = 0;
                temp2 = dut->o_return_coin;
                printf("Expected: Output_item: 0b0001, Return_coin: 0b101\n");
                printf("Received: Output_item: %d, Return_coin: %d.\n", temp1, temp2);
                if(temp1 == 1 && temp2 == 5) success++, printf("PASSED. \n");
                else fail++, printf("FAILED. \n");
                break;
            //##############################################################################
            case 16:
                dut->reset_n = 0;
                break;
            case 17:
                dut->reset_n = 1;
                break;
            //######################## 5. 같은 동전 여러개를 반환할 수 있는가? ########################
            case 18:
                init_temp();
                printf("\n Test: return multiple same coin. sim_time: %d\n", sim_time);
                printf("Behavior: +100, +100, return.\n");
                dut->i_input_coin = 0b001;
                break;
            case 19:
                dut->i_input_coin = 0;
                break;
            case 20:
                dut->i_input_coin = 0b001;
                break;
            case 21:
                dut->i_input_coin = 0;
                break;
            case 22:
                dut->i_trigger_return = 1;
                break;
            case 23:
                dut->i_trigger_return=0;
                coin_cnt[dut->o_return_coin] ++;
                break;
            case 24:
                coin_cnt[dut->o_return_coin] ++;
                break;
            case 25:
                coin_cnt[dut->o_return_coin] ++;
                break;
            case 26:
                printf("Expected: Return_coin(total): 200won\n");
                printf("Received: Return_coin(total): %dwon\n", calc_coin());
                if(200 == calc_coin()) success++, printf("PASSED. \n");
                else fail++, printf("FAILED. \n");
                break;    

            //##############################################################################
            case 28:
                dut->reset_n = 0;
                break;
            case 29:
                dut->reset_n = 1;
                break;
                
            //##################### 6. 100초 이후에 자동으로 반환하는가? ########################
            case 30:
                init_temp();
                printf("\n Test: Auto return after 100 cycles, sim_time: %d\n", sim_time);
                printf("Behavior: +500, ...\n");
                dut->i_input_coin = 0b010;
                break;
            case 31:
                dut->i_input_coin = 0;
                break;
            case 231:
                temp4 = dut->o_return_coin;
                printf("Expected: Return_coin: 0b010 (500 returned after timeout)\n");
                printf("Received: Return_coin: %d.\n", temp4);
                if(temp4 == 2) success++, printf("PASSED. \n");
                else fail++, printf("FAILED. \n");
                printf("...but, maybe your o_return_coin is not clear. Note detect log. (225 .. 235)\n");
                break;

            //##############################################################################
            case MAX_SIM_TIME:
                printf("\n### SIMULATING DONE ###, max_sim_time: %d\n", MAX_SIM_TIME);
                break;
        }
        if(225<= sim_time && sim_time <= 235) {
            if(dut->o_return_coin) {
                printf("Return detected. \n");
                printf("%d: %d\n", sim_time, dut->o_return_coin);
            }
        }

       
       
///////////////////////////////////////////////////////////////////////////////////////////////////////////
    }
    printf("\nsuccess: %d / %d\n", success, success + fail + idk);
    printf("fail: %d / %d\n", fail, success + fail + idk);
    printf("IDK: %d / %d\n", idk, success + fail + idk);



    m_trace->close();

    delete dut;
    exit(0);
}



