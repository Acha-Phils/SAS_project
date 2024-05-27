  /*************************/
 /***  EXERCISES ***/
/*************************/

/***********************/
/******* Part 1 *******/
/*********************/

/*** Exercise 1 ***/

PROC IMPORT DATAFILE = "H:\Doctoraat\Lessen SAS\2015-2016\Les 2\Home Exercises\ex1.xlsx" DBMS = XLSX OUT = Ex1;
RUN;

DATA Ex1_Farenheit (DROP = celcius1-celcius100 i);
 SET Ex1;

 	ARRAY Celcius_array {100} celcius1-celcius100;
	ARRAY Farenheit_array {100} farenheit1-farenheit100;

	DO i = 1 TO 100;
		farenheit_array{i} = (celcius_array{i}*9/5)+32 ;
	END;

RUN;

/*** Exercise 2 ***/

PROC IMPORT DATAFILE = "H:\Doctoraat\Lessen SAS\2015-2016\Les 2\Home Exercises\ex2.xlsx" DBMS = XLSX OUT = Ex2 REPLACE;
RUN;

DATA Ex2_r;
 SET Ex2;

 	ARRAY All_num {*} _NUMERIC_;

	DO i = 1 TO DIM(All_num);
		All_num{i} = ROUND(All_num{i},.001);
	END;
RUN;

/****************/
/**** Part 2 ***/
/**************/

/* 1 */
PROC IMPORT DATAFILE = 'H:\Doctoraat\Lessen SAS\2015-2016\Les 2\Home Exercises\Sales.xls' 
																		OUT= Sales REPLACE DBMS = XLS;
	* SHEET="Sheet2"  Is not necessary, is specified in the RANGE statement;
	RANGE="Sheet2$A2:E33";
RUN;

/* 2 */

/* Using PROC CONTENTS to check the format (type) of the variables*/
PROC CONTENTS DATA = Sales;

RUN;

/* Converting the ID type and creating extra variable */
DATA Sales_missing (RENAME = (custid=cust_id prodid = prod_id) DROP=cust_id prod_id);
 SET Sales;

	custid=PUT(cust_id, 4.);
	prodid=PUT(prod_id, 2.);

	IF prodid=. THEN DO;    /* Creating an extra variable called missing, give it a 1 when there's a missing, a 0
							   when there's no missing. This way you will be able to put the missings last
							   in the sorting */
		prodid="";
		missing = 1;
	END;
	ELSE missing = 0;

RUN;

PROC SORT DATA=Sales_missing OUT=Sales_sorted NODUPKEY;											/* Making the rows unique */
	BY missing prod_id date DESCENDING cust_id; 
			/* First sort by missing, so the misings (= 1) come last */
RUN;

/* 3 */
DATA Sales_price;
 SET Sales_sorted;
	IF prod_id='56' THEN price=1.55;
	 ELSE IF prod_id='42' THEN price=6.99;
	 ELSE IF prod_id='86' THEN price=5.45;
	 ELSE IF prod_id='91' THEN price=6.77;
	* ELSE price=.; /* This additional step is not necessary as long as you specify all possible options */
	tot_price=quantity*price;
	month=MONTH(date);	
RUN;

/* 4 */
PROC SORT DATA = Sales_price OUT = Sales_price_s;
	BY month;

RUN;

PROC MEANS DATA = Sales_price_s NOPRINT;
									/* Do not print anything to the output window */
	FORMAT Monthly_sales DOLLAR10.2;
							/* Assign a format to the newly created variable (see below) */
	CLASS month;
	VAR tot_price;
	OUTPUT OUT = Sales_sum SUM(tot_price) = Monthly_sales;
RUN;

PROC PRINT DATA = Sales_sum;
	VAR month monthly_sales;
	WHERE month ~= .;
		/* Exclude the missing month, this is the total */
RUN;

/*5 */
PROC FREQ DATA = Sales_price;
	TABLES cash*month / NOCOL NOROW NOPERCENT;
RUN;

/* 6 */
PROC SORT DATA = Sales_price OUT = Sales_price_unique NODUPKEY;
	BY cust_id;
RUN;

DATA Sales_random;
 SET Sales_price_unique;

	a=UNIFORM(10);
RUN;

PROC SORT DATA = Sales_random OUT = Sales_random_s;
	BY a;
RUN;

DATA Sample (KEEP = cust_id);
 SET Sales_random_s;
	IF _N_ <= 3;
RUN;

/* LAG function */
PROC SORT DATA = Sales OUT = Cust_sorted;
 BY cust_id DESCENDING cash;
RUN;

DATA Sales_lag;
 SET Cust_sorted;
 	BY cust_id; 
	IF cash = 1 THEN dif_quant = DIF(quantity);
	IF FIRST.cust_id THEN dif_quant = 0;
RUN;

/*****************/
/**** Part 3 ****/
/***************/

PROC IMPORT DATAFILE = "H:\Doctoraat\Lessen SAS\2015-2016\Les 2\Home Exercises\tickets.xlsx" DBMS = XLSX OUT = Tickets REPLACE;
RUN;

PROC IMPORT DATAFILE = "H:\Doctoraat\Lessen SAS\2015-2016\Les 2\Home Exercises\External_card.xlsx" DBMS = XLSX OUT = External_card REPLACE;
RUN;

PROC IMPORT DATAFILE = "H:\Doctoraat\Lessen SAS\2015-2016\Les 2\Home Exercises\Customer_info.xlsx" DBMS = XLSX OUT = Customer_info REPLACE;
RUN;

PROC SORT DATA = Tickets;
	BY Cust_nr;	 
RUN;
 
DATA Tickets (DROP = counter ticket_nr); 
 SET Tickets;
	BY Cust_nr;
	RETAIN avg_amount avg_total;

	IF FIRST.cust_nr THEN DO;
		avg_amount = 0;
		avg_total = 0;
		counter = 0;
	END;
	counter + 1;
	avg_amount = avg_amount + amount;
	avg_total = avg_total + ticket_total;

	IF LAST.cust_nr THEN DO;
		avg_amount = avg_amount/counter;
		avg_total = avg_total/counter;
		OUTPUT;
	END;
RUN;

DATA Customer_info;
 SET Customer_info;
  
 	IF web_shop_client = "" THEN web_shop_client = "no";
	 ELSE web_shop_client = "yes";

RUN;

/* First add customer number to the external file for later merging */
/* Rename the external number variable name because it is different between datasets */
DATA External_card (RENAME = (Ext_card_number = External_card));
 SET External_card;
 LABEL Ext_card_number = ; 
 	/* Remove the label or it looks that the rename statement did nothing */
RUN;

PROC SORT DATA = External_card ;
	BY External_card;	 
RUN;

/* Keep only the unique card numbers for the merge */
PROC SORT DATA = Tickets OUT = Tick_unique NODUPKEY;
	BY External_card;
RUN;

DATA External_card;
 MERGE External_card (IN = a) Tick_unique (KEEP = External_card Cust_nr);
 	BY external_card;
	IF a;
RUN;

PROC SORT DATA = Tickets;
	BY Cust_nr;
RUN;

PROC SORT DATA = External_card;
	BY Cust_nr;
RUN;

PROC SORT DATA = Customer_info;
	BY Cust_nr;
RUN;

DATA No_External_Info External_Info Rest;
 MERGE Tickets (IN = a) Customer_info (IN = b) External_card (IN = c);
 	BY cust_nr;
	IF a AND b AND NOT c THEN OUTPUT No_external_info;
	 ELSE IF a AND b AND c THEN OUTPUT External_info;
	 ELSE OUTPUT Rest;
RUN;

/* Initial conclusions: One customer number in the tickets dataset has no match in the customer 
info dataset, this is most likely a dummy number for customers without a card. Only 6 customers
out of 35 unique customers (disregarding the dummy) have external information. This hints at the
fact that the cooperation might not be a good one. However, some further analyses are required */

PROC MEANS DATA = No_external_info MEDIAN MEAN MIN MAX;
 VAR avg_amount avg_total;

RUN;

PROC MEANS DATA = external_info MEDIAN MEAN MIN MAX;
 VAR avg_amount avg_total;

RUN;

/* We do not see any difference in the averages. If the External info dataset had higher 
averages it would be an argument pro the cooperation. */ 

/***** PART 4 ******/

DATA Mileages1;
 SET SASHELP.mileages;
	city = COMPRESS(city);
	city = COMPRESS(city,".");
RUN;

PROC TRANSPOSE DATA = Mileages1 OUT = Mileages2;
	ID City;
	VAR Atlanta--WashingtonDC;
RUN;

DATA New (KEEP = city atlanta--washingtondc);
 SET Mileages2 (RENAME = (_NAME_ = city)) Mileages1;
 	BY city;
	ARRAY vars {*} atlanta--washingtonDC;
	ARRAY new {10} var1-var10;
	RETAIN var1-var10;
	IF FIRST.City THEN DO;
		DO i = 1 TO 10;
			new(i) = vars(i);
		END;
	END;

	IF LAST.city THEN DO;
		DO i = 1 TO DIM(vars);
			IF vars(i) = . THEN vars(i) = new(i);
		END;
		OUTPUT;
	END;
RUN;

/* Alternative solution */
data Lower;
set sashelp.mileages;
/* Removing spaces and dots from the city names so they are 
   identical to the city names created by the proc transpose statement below */
City = tranwrd(trim(City),'.','');
City = compress(City);
run;

/* Transposing the 'Lower' dataset (which is copy of mileage) to 'Upper' dataset */
/* Name of former variable is _NAME_ by default after running proc transpose (in dataset 'Upper'), 
   so it should be changed to 'City' so 'Lower' and 'Upper' can be merged later (see below)*/
proc transpose data = Lower out = Upper (rename = (_NAME_ = City));
id City;
run;

/* The 'upper' dataset is now updated with values of the 'lower' dataset, creating a triangular matrix */
data Triangular;
update upper lower;
by City;
/* Optional relabeling of variable City from 'NAME OF FORMER VARIABLE' to 'CITY' */
label City = "CITY";
run;

