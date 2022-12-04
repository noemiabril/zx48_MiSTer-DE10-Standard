//-------------------------------------------------------------------------------------------------
module video
//-------------------------------------------------------------------------------------------------
(
	input  wire       clock,
	input  wire       ce,

	input  wire       model,

	input  wire[ 2:0] border,

	output wire[ 1:0] blank,
	output wire[ 1:0] sync,
	output wire[23:0] rgb,

	output wire       bi,
	output wire       rd,
	output wire       cn,

	input  wire[ 7:0] d,
	output wire[12:0] a
);
//-------------------------------------------------------------------------------------------------

wire[8:0] hcountEnd = model ? 9'd455 : 9'd447;
wire[8:0] vcountEnd = model ? 9'd310 : 9'd311;

wire[8:0] intBeg = model ? 9'd6  : 9'd2 ;
wire[8:0] intEnd = model ? 9'd78 : 9'd66;

//-------------------------------------------------------------------------------------------------

reg[8:0] hCount;
wire hCountReset = hCount >= hcountEnd;
always @(posedge clock) if(ce) if(hCountReset) hCount <= 1'd0; else hCount <= hCount+1'd1;

reg[8:0] vCount;
wire vCountReset = vCount >= vcountEnd;
always @(posedge clock) if(ce) if(hCountReset) if(vCountReset) vCount <= 1'd0; else vCount <= vCount+1'd1;

reg[4:0] fCount;
always @(posedge clock) if(ce) if(hCountReset) if(vCountReset) fCount <= fCount+5'd1;

//-------------------------------------------------------------------------------------------------

wire dataEnable = hCount <= 255 && vCount <= 191;

reg videoEnable;
wire videoEnableLoad = hCount[3];
always @(posedge clock) if(ce) if(videoEnableLoad) videoEnable <= dataEnable;

//-------------------------------------------------------------------------------------------------

reg[7:0] dataInput;
wire dataInputLoad = (hCount[3:0] ==  9 || hCount[3:0] == 13) && dataEnable;
always @(posedge clock) if(ce) if(dataInputLoad) dataInput <= d;

reg[7:0] attrInput;
wire attrInputLoad = (hCount[3:0] == 11 || hCount[3:0] == 15) && dataEnable;
always @(posedge clock) if(ce) if(attrInputLoad) attrInput <= d;

reg[7:0] dataOutput;
wire dataOutputLoad = hCount[2:0] == 4 && videoEnable;
always @(posedge clock) if(ce) if(dataOutputLoad) dataOutput <= dataInput; else dataOutput <= { dataOutput[6:0], 1'b0 };

reg[7:0] attrOutput;
wire attrOutputLoad = hCount[2:0] == 4;
always @(posedge clock) if(ce) if(attrOutputLoad) attrOutput <= { videoEnable ? attrInput[7:3] : { 2'b00, border }, attrInput[2:0] };

//-------------------------------------------------------------------------------------------------

wire dataSelect = dataOutput[7] ^ (fCount[4] & attrOutput[7]);

wire r = dataSelect ? attrOutput[1] : attrOutput[4];
wire g = dataSelect ? attrOutput[2] : attrOutput[5];
wire b = dataSelect ? attrOutput[0] : attrOutput[3];
wire i = attrOutput[6];

reg[23:0] palette[0:15];
initial $readmemh("palette.hex", palette, 0);

//-------------------------------------------------------------------------------------------------

assign blank = { vCount >= 248 && vCount <= 255, hCount >= 320 && hCount <= 415 };
assign sync = { vCount >= 248 && vCount <= 251, hCount >= 344 && hCount <= 375 };
assign rgb = palette[{ i, r, g, b }];

assign bi = !(vCount == 248 && hCount >= intBeg && hCount < intEnd);
assign cn = (hCount[3] || hCount[2]) && dataEnable;
assign rd = hCount[3] && dataEnable;

assign a = { !hCount[1] ? { vCount[7:6], vCount[2:0] } : { 3'b110, vCount[7:6] }, vCount[5:3], hCount[7:4], hCount[2] };

//-------------------------------------------------------------------------------------------------
endmodule
//-------------------------------------------------------------------------------------------------
