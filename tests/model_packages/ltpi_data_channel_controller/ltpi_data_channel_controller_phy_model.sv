module ltpi_data_channel_controller_phy_model
import ltpi_pkg::*;
(
    input                           clk,
    input                           reset,
    input                           req_valid,
    output  logic                   req_ack,
    input   Data_channel_payload_t  req,
    output  logic                   resp_valid,
    output  Data_channel_payload_t  resp
);

    Data_channel_payload_t requests  [$];
    Data_channel_payload_t responses [$];
    
    // Receive Requests
    initial forever begin
        int delay = $urandom_range(200, 1);
        
        req_ack <= 0;

        wait (reset == 0);
        @ (posedge clk);

        wait (req_valid == 1);
        requests.push_back(req);
        $display("[LTPI DATA CHANNEL CONTROLLER PHY MODEL]: Received REQ: %p", req);

        repeat (delay) @ (posedge clk);
        
        req_ack <= 1;

        wait(req_valid == 0);
        @ (posedge clk);
    end

    // Process
    byte mem [4096];

    initial forever begin
        Data_channel_payload_t  trn;
        bit [31:0]              address;

        while (requests.size() == 0) @ (posedge clk);
        trn = requests.pop_front();

        for (int b = 0; b < 4; b++) begin
            address [b*8 +: 8] = trn.address[b];
        end

        if (address < 4096) begin
            if (trn.command == WRITE_REQ) begin
                for (int b = 0; b < 4; b++) begin
                    if (trn.byte_en[b]) mem[address+b] = trn.data[b]; 
                end
                trn.command = WRITE_COMP;
            end
            else if (trn.command == READ_REQ) begin
                for (int b = 0; b < 4; b++) begin
                    if (trn.byte_en[b]) trn.data[b] = mem[address+b];
                    else                trn.data[b] = 0; 
                end
                trn.command = READ_COMP;
            end
            trn.operation_status = 0;
        end
        else begin
            if (trn.command == WRITE_REQ) trn.command = WRITE_COMP;
            else if (trn.command == READ_REQ) trn.command = READ_COMP;
            trn.operation_status = 1;
        end

        responses.push_back(trn);
    end

    // Send Responses
    initial forever begin
        int delay = $urandom_range(200, 1);

        resp_valid  <= 0;
        resp        <= 0;

        wait (reset == 0);
        @ (posedge clk);

        while (responses.size() == 0) @ (posedge clk);

        repeat (delay) @ (posedge clk);

        resp_valid  <= 1;
        resp        <= responses.pop_front();
        @ (posedge clk);
        $display("[LTPI DATA CHANNEL CONTROLLER PHY MODEL]: Sent RESP: %p", resp);
        resp_valid  <= 0;
        resp        <= 0;
    end
endmodule