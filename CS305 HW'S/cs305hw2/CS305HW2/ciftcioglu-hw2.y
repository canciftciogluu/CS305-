// can ciftcioglu cs305 hw2

%{
#include <stdio.h>
void yyerror (const char *msg) {
    return;
}
%}

%token 
tMAIL 
tENDMAIL 
tSCHEDULE 
tENDSCHEDULE 
tSEND 
tSET 
tTO 
tFROM tAT 
tCOMMA 
tCOLON 
tLPR 
tRPR 
tLBR 
tRBR 
tIDENT 
tSTRING 
tDATE 
tTIME 
tADDRESS
%start sst

%%
sst:  stmnt
    | 
;
stmnt:
    |  mail_block  stmnt
    |  set_statement stmnt

;
mail_block: tMAIL tFROM tADDRESS tCOLON statement_list tENDMAIL 
; 
statement_list: 
            |   set_statement statement_list
            |   send_statement statement_list
            |   schedule_statement statement_list
;
set_statement: tSET tIDENT tLPR tSTRING tRPR 
; 
recipient: tLPR tADDRESS tRPR
        |  tLPR tIDENT tCOMMA tADDRESS tRPR
        |  tLPR tSTRING tCOMMA tADDRESS tRPR 
;
recipient_list: tLBR recipients tRBR
;
recipients: recipient
          | recipients tCOMMA recipient
;
send_statement: tSEND tLBR tSTRING tRBR tTO recipient_list 
            |   tSEND tLBR tIDENT tRBR tTO recipient_list 

;
send: send_statement 
    | send_statement send
;
schedule_statement: tSCHEDULE tAT tLBR tDATE tCOMMA tTIME tRBR tCOLON send tENDSCHEDULE 
;

%%
int main() {
    if (yyparse()) {
        // parse error
        printf("ERROR\n");
        return 1;
    }
    else {
        // success
        printf("OK\n");
        return 0;
    }
}