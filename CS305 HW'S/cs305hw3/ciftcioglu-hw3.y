%{
#include <stdio.h>
#include "ciftciogluhw3.h"
#include <string.h>

void yyerror (const char *s)  /* Called by yyparse on error */
{
}

int error = 0;

TreeNode * SendRootNode = NULL;
TreeNode * SendTailNode = NULL;

TreeNode * SchRootNode = NULL;
TreeNode * SchTailNode = NULL;

TreeNode * VarRootNode = NULL;
TreeNode * VarTailNode = NULL;

TreeNode * globalStatList = NULL;
TreeNode * globalStatListTail = NULL;

TreeNode * globalSchStatList = NULL;
TreeNode * globalSchStatListTail = NULL;

%}
 
%union {     
    IdentifierStruct identifierStruct;
    char *str;
    TreeNode * treePtr;
}

%token <identifierStruct> tIDENT
%token <str> tSTRING
%token <str> tADDRESS
%token <str> tDATE
%token <str> tTIME

%type <treePtr> setStatement
%type <treePtr> sendStatement
%type <treePtr> scheduleStatement
%type <treePtr> sendStatements
%type <treePtr> recipient
%type <treePtr> recipientList

%token tMAIL tENDMAIL tSCHEDULE tENDSCH tSEND tTO tFROM tSET tCOMMA tCOLON tLPR tRPR tLBR tRBR tAT  
%start program

%%

program : statements {}
;

statements : 
            | setStatement statements
            | mailBlock statements
;

mailBlock : tMAIL tFROM tADDRESS tCOLON statementList tENDMAIL  {
                                                                    TreeNode * ptr = globalStatList;
                                                                    while (ptr != NULL)
                                                                    {
                                                                        ptr -> NodePtr -> send.sender = $3;
                                                                        ptr = ptr -> NodePtr -> send.next;
                                                                    }

                                                                    if (SendRootNode == NULL)
                                                                    {
                                                                        SendRootNode = globalStatList;
                                                                        SendTailNode = globalStatListTail;
                                                                    }
                                                                    else
                                                                    {
                                                                        SendTailNode -> NodePtr -> send.next = globalStatList;
                                                                        SendTailNode = globalStatListTail;
                                                                    }


                                                                    TreeNode * ptr2 = globalSchStatList;
                                                                    while (ptr2 != NULL)
                                                                    {
                                                                        ptr2 -> NodePtr -> sch.sender = $3;
                                                                        ptr2 = ptr2 -> NodePtr -> sch.next;
                                                                    }

                                                                    insertSch(globalSchStatList);
                                                                    
                                                                    globalStatList = NULL;
                                                                    globalStatListTail = NULL;
                                                                    globalSchStatList = NULL;
                                                                    globalSchStatListTail = NULL;
                                                                }
;

statementList : 
                | statementList setStatement
                | statementList sendStatement       {
                                                        if (globalStatList == NULL) 
                                                        {
                                                            globalStatList = $2;
                                                            TreeNode * ptr = globalStatList;
                                                            while (ptr -> NodePtr -> send.next != NULL)
                                                            {
                                                                ptr = ptr -> NodePtr -> send.next;
                                                            }   
                                                            globalStatListTail = ptr;
                                                            }
                                                        else 
                                                        {
                                                            globalStatListTail -> NodePtr -> send.next = $2;    
                                                            globalStatListTail = $2;
                                                        }
                                                    }
                | statementList scheduleStatement   {   
                                                        if (globalSchStatList == NULL) 
                                                        {
                                                            globalSchStatList = $2;
                                                            TreeNode * ptr = globalSchStatList;
                                                            while (ptr -> NodePtr -> sch.next != NULL)
                                                            {
                                                                ptr = ptr -> NodePtr -> sch.next;
                                                            }   
                                                            globalSchStatListTail = ptr;
                                                            }
                                                        else 
                                                        {
                                                            globalSchStatListTail -> NodePtr -> sch.next = $2;    
                                                            globalSchStatListTail = $2;
                                                        }
                                                    }
;

sendStatements : sendStatement  {   $$ = $1;    }
                | sendStatement sendStatements {
                                                    TreeNode * temp = $1;
                                                    while (temp -> NodePtr -> send.next != NULL){
                                                        temp = temp -> NodePtr -> send.next;
                                                    }
                                                    temp -> NodePtr -> send.next = $2;
                                                    $$ = $1;

                                                    temp = $1;
                                                    int i = 0;
                                                    while (temp !=  NULL)
                                                    {
                                                        temp = temp -> NodePtr -> send.next;
                                                    }
                                                }


sendStatement : tSEND tLBR tIDENT tRBR tTO tLBR recipientList tRBR  {
                                                                        $$ = mkSendNodeList($3.str, $7, 1, $3.lineNum);    }
                | tSEND tLBR tSTRING tRBR tTO tLBR recipientList tRBR   {   $$ = mkSendNodeList($3, $7, 0, 1);    }
;

recipientList : recipient   {$$ = $1;}
            | recipient tCOMMA recipientList    {   $$ = mkRecipientList($1, $3);    }
;

recipient : tLPR tADDRESS tRPR {    $$ = mkRecipNode1($2);    }
            | tLPR tSTRING tCOMMA tADDRESS tRPR {   $$ = mkRecipNode2($4, $2, 0, 1);    }
            | tLPR tIDENT tCOMMA tADDRESS tRPR  {   
                                                    $$ = mkRecipNode2($4, $2.str, 1, $2.lineNum);    
                                                }
;

scheduleStatement : tSCHEDULE tAT tLBR tDATE tCOMMA tTIME tRBR tCOLON sendStatements tENDSCH {  $$ = mkSchNodeList ($9, $4, $6);    }
;

setStatement : tSET tIDENT tLPR tSTRING tRPR {  mkVarNode($2.str, $4);  }
;

%%

void mkVarNode (char * ident, char * identVal){
    TreeNode * ret    = (TreeNode *)malloc (sizeof(TreeNode));
    ret->thisNodeType = VAR;
    ret->NodePtr = (Node *)malloc(sizeof(Node));
    ret->NodePtr->var.ident = strdup(ident);
    ret->NodePtr->var.identVal = strdup(identVal);
    ret->NodePtr->var.next = NULL;

    if (VarRootNode == NULL)
    {
        VarRootNode = ret;
        VarTailNode = ret;
    }
    else
    {
        TreeNode * ptr;
        ptr = VarRootNode;

        while (ptr != NULL)
        {  
            if (strcmp(ptr -> NodePtr -> var.ident, ident) == 0)
            {
                ptr -> NodePtr -> var.identVal = strdup(identVal);
                return;
            }
            ptr = ptr -> NodePtr -> var.next;
        }
        VarTailNode -> NodePtr -> var.next = ret;
    }
    VarTailNode = ret;
}

TreeNode * mkSendNodeList (char * str, TreeNode * recipList, int type, int numLine){
    TreeNode * ptr = recipList;
    TreeNode * root = mkSendNode(ptr, str, type, numLine);
    TreeNode * ptr2 = root; // -> NodePtr -> send.next;
    ptr = ptr -> NodePtr -> recip.next;
    
    while(ptr != NULL){
        ptr2 -> NodePtr -> send.next = mkSendNode(ptr, str, type, numLine);

        ptr2 = ptr2 -> NodePtr -> send.next;
        ptr = ptr -> NodePtr -> recip.next;
    }

    ptr2 = root;
    int i = 0;
     while(ptr2 != NULL){
        ptr2 = ptr2 -> NodePtr -> send.next;
    }
    return root;
}

TreeNode * mkSendNode (TreeNode * receiver, char * str, int type, int numLine){
    char * msg;
    char * rec;
    if (type == 1 && checkVar(str) == "D O E S N O T E X I S T")
    {
        error = 1;
        printf("ERROR at line %d:  %s is undefined\n", numLine, str);
    }
    else if (type == 1 && checkVar(str) != "D O E S N O T E X I S T")
    {
        msg = strdup(checkVar(str));
    }
    else if (type == 0)
    {
        msg = strdup(str);
    }

    if (receiver -> NodePtr -> recip.hasName == 1) {rec = receiver -> NodePtr -> recip.name;}
    else {rec = receiver -> NodePtr -> recip.address;}

    TreeNode * ret    = (TreeNode *)malloc (sizeof(TreeNode));
    ret->thisNodeType = SEND;
    ret->NodePtr = (Node *)malloc(sizeof(Node));
    ret->NodePtr->send.msg = msg;
    ret->NodePtr->send.receiver = rec;
    ret->NodePtr->send.next = NULL;

    return ret;
}

TreeNode * mkSchNode (char * date, char * time, char * rec, char * msg){
    TreeNode * ret    = (TreeNode *)malloc (sizeof(TreeNode));
    ret->thisNodeType = SCH;
    ret->NodePtr = (Node *)malloc(sizeof(Node));

    ret->NodePtr->sch.schMsg = msg;
    ret->NodePtr->sch.receiver = rec;
    ret->NodePtr->sch.date = date;
    ret->NodePtr->sch.time = time;

    ret->NodePtr->sch.next = NULL;

    return ret;
}

TreeNode * mkSchNodeList (TreeNode * sendStatements, char * date, char * time){
    TreeNode * root    = (TreeNode *)malloc (sizeof(TreeNode));
    char * rec = sendStatements -> NodePtr -> send.receiver;
    char * msg = sendStatements -> NodePtr -> send.msg;
    root = mkSchNode(date, time, rec, msg);

    TreeNode * ptr2 = root;
    TreeNode * ptr = sendStatements -> NodePtr -> send.next;
    
    while (ptr != NULL)
    {
        rec = ptr -> NodePtr -> send.receiver;
        msg = ptr -> NodePtr -> send.msg;

        TreeNode * temp = mkSchNode(date, time, rec, msg);
        ptr2 -> NodePtr -> sch.next = temp;
        ptr = ptr -> NodePtr -> send.next;
        ptr2 = ptr2 -> NodePtr -> sch.next;
    }
    return root;
}

TreeNode * mkRecipNode1 (char *address){
    TreeNode * ret    = (TreeNode *)malloc (sizeof(TreeNode));
    ret->thisNodeType = RECIP;
    ret->NodePtr = (Node *)malloc(sizeof(Node));
    ret->NodePtr->recip.hasName = 0;
    ret->NodePtr->recip.address = strdup(address);
    ret->NodePtr->recip.next = NULL;

    return ret;
}

TreeNode * mkRecipNode2 (char *address, char *ident, int type, int numLine){
    TreeNode * ret    = (TreeNode *)malloc (sizeof(TreeNode));
    ret->thisNodeType = RECIP;
    ret->NodePtr = (Node *)malloc(sizeof(Node));

    if (type == 1 && checkVar(ident) == "D O E S N O T E X I S T")
    {
        error = 1;
        printf("ERROR at line %d:  %s is undefined\n", numLine, ident);
        
        // ERROR
    }
    else if (type == 1 && checkVar(ident) != "D O E S N O T E X I S T")
    {
        char sub[100];
        substr(strdup(checkVar(ident)), sub, 1, strlen(strdup(checkVar(ident)))-2);
        ret->NodePtr->recip.name = sub;
    }
    else if (type == 0)
    {
        char sub[100];
        substr(strdup(ident), sub, 1, strlen(ident)-2);
        ret->NodePtr->recip.name = strdup(sub);
    }
    ret->NodePtr->recip.hasName = 1;
    ret->NodePtr->recip.address = strdup(address);
    ret->NodePtr->recip.next = NULL;

    return ret;
}



TreeNode * mkRecipientList (TreeNode * recip, TreeNode * recipList){
    recip -> NodePtr -> recip.next = recipList;
    TreeNode * ptr = recip;

    while (ptr -> NodePtr -> recip.next != NULL)
    {  
        TreeNode * ptr2 = ptr -> NodePtr -> recip.next;
        if (strcmp(ptr2 -> NodePtr -> recip.address, recip -> NodePtr -> recip.address) == 0)
        {
            ptr -> NodePtr -> recip.next = ptr2 -> NodePtr -> recip.next;
            return recip;
        }
        ptr = ptr -> NodePtr -> recip.next;
    }

    return recip;
}

char * checkVar (char * identifier){
    TreeNode * ptr = VarRootNode;

    while (ptr != NULL)
    {  
        if (strcmp(ptr -> NodePtr -> var.ident, identifier) == 0)
        {
            return ptr -> NodePtr -> var.identVal;
        }
        ptr = ptr -> NodePtr -> var.next;
    }
    char * res = "D O E S N O T E X I S T";
    return res;
}

int isLeftDateEarlier(TreeNode * left, TreeNode * right){
    char * leftDate = left -> NodePtr -> sch.date;
    char * leftTime = left -> NodePtr -> sch.time;
    char * rightDate = right -> NodePtr -> sch.date;
    char * rightTime = right -> NodePtr -> sch.time;

    char leftDay[1000], leftMonth[1000], leftYear[1000], rightDay[1000], rightMonth[1000], rightYear[1000]; 
    char leftHour[1000], leftMin[1000], rightHour[1000], rightMin[1000]; 
    substr(leftDate, leftDay, 0, 2);
    substr(leftDate, leftMonth, 3, 2);
    substr(leftDate, leftYear, 6, 4);
    substr(leftTime, leftHour, 0, 2);
    substr(leftTime, leftMin , 3, 2);

    substr(rightDate, rightDay, 0, 2);
    substr(rightDate, rightMonth, 3, 2);
    substr(rightDate, rightYear, 6, 4);
    substr(rightTime, rightHour, 0, 2);
    substr(rightTime, rightMin , 3, 2);

    if (strcmp(leftYear, rightYear) > 0)   {return 0;}
    else if (strcmp(leftYear, rightYear) < 0)  {return 1;}
    else
    {
        if (strcmp(leftMonth, rightMonth) > 0) {return 0;}
        else if (strcmp(leftMonth, rightMonth) < 0) {return 1;}
        else
        {
            if (strcmp(leftDay, rightDay) > 0) {return 0;}
            else if (strcmp(leftDay, rightDay) < 0) {return 1;}
            else
            {
                if (strcmp(leftHour, rightHour) > 0) {return 0;}
                else if (strcmp(leftHour, rightHour) < 0) {return 1;}
                else
                {
                    if (strcmp(leftMin, rightMin) > 0) {return 0;}
                    else if (strcmp(leftMin, rightMin) < 0) {return 1;}
                    else
                    {
                        return 2;
                    }
                }
            }
        }
    }
}

void substr(char * s, char * sub, int p, int l) {
   int c = 0;
   
   while (c < l) {
      sub[c] = s[p+c];
      c++;
   }
   sub[c] = '\0';
}

void insertSch(TreeNode * new){
    TreeNode * schListPtr = SchRootNode;
    
    if (SchRootNode == NULL) {
        SchRootNode = new;
        schListPtr = SchRootNode;
    }
    else
    {
        if (1 == isLeftDateEarlier(new, schListPtr))
        {
            TreeNode * newPtr = new;
            while (newPtr -> NodePtr -> sch.next != NULL) 
            {
                newPtr = newPtr -> NodePtr -> sch.next;
            }
            newPtr -> NodePtr -> sch.next = schListPtr;
            SchRootNode = new;
        }
        else
        {
            // either go to the end of the schedule root list or go to the node when a later date in the sch list arrives
            while (schListPtr -> NodePtr -> sch.next != NULL && (1 == isLeftDateEarlier(schListPtr-> NodePtr -> sch.next, new)
            || 2 == isLeftDateEarlier(schListPtr-> NodePtr -> sch.next, new)))
            {
                schListPtr = schListPtr -> NodePtr -> sch.next;
            }
            
            TreeNode * newPtr = new;
            while (newPtr -> NodePtr -> sch.next != NULL) 
            {
                newPtr = newPtr -> NodePtr -> sch.next;
            }
            newPtr -> NodePtr -> sch.next = schListPtr -> NodePtr -> sch.next;
            schListPtr -> NodePtr -> sch.next = new;
        }
    }

    int i = 0;
    TreeNode * newPtr = SchRootNode;
    while (newPtr != NULL) 
    {
        newPtr = newPtr -> NodePtr -> sch.next;
        i = i + 1;
    }
    
}

void printSendTree(){
    TreeNode * ptr = SendRootNode;

    while (ptr != NULL)
    {
        char * sender = ptr -> NodePtr -> send.sender;
        char * receiver = ptr -> NodePtr -> send.receiver;
        char * msg = ptr -> NodePtr -> send.msg;

        printf("E-mail sent from %s to %s: %s\n", sender, receiver, msg);
        ptr = ptr -> NodePtr -> send.next;
    }
}

void printSchTree(){
    TreeNode * ptr = SchRootNode;
    int b = 0;
    while (ptr != NULL)
    {
        b = b + 1;
        char * receiver = ptr -> NodePtr -> sch.receiver;
        char * msg = ptr -> NodePtr -> sch.schMsg;
        char * Date = ptr -> NodePtr -> sch.date;
        char * Time = ptr -> NodePtr -> sch.time;
        char * mySender = ptr -> NodePtr -> sch.sender;

        char Day[1000], Month[1000], Year[1000];
        char rightHour[1000], rightMin[1000]; 
        substr(Date, Day, 0, 2);
        substr(Date, Month, 3, 2);
        substr(Date, Year, 6, 4);
        char * myMonth = createMonth(Month);
        char myDayFirstIndex[1000];
        char * myDay;
        substr(Day, myDayFirstIndex, 0, 1);
        if (strcmp(myDayFirstIndex, "0") == 0)
        {
            substr(Day, myDay, 1, 1);
        }
        else
        {
            myDay = strdup(Day);
        }
        printf("E-mail scheduled to be sent from %s on %s %s, %s, %s to %s: %s\n", mySender, myMonth, myDay, Year, Time, receiver, msg);
        ptr = ptr -> NodePtr -> sch.next;
    }
}

char * createMonth(char * month){
    if (strcmp(month, "01") == 0) {return "January";}
    else if (strcmp(month, "02") == 0) {return "February,";}
    else if (strcmp(month, "03") == 0) {return "March,";}
    else if (strcmp(month, "04") == 0) {return "April";}
    else if (strcmp(month, "05") == 0) {return "May";}
    else if (strcmp(month, "06") == 0) {return "June";}
    else if (strcmp(month, "07") == 0) {return "July";}
    else if (strcmp(month, "08") == 0) {return "August";}
    else if (strcmp(month, "09") == 0) {return "September";}
    else if (strcmp(month, "10") == 0) {return "October";}
    else if (strcmp(month, "11") == 0) {return "November";}
    else {return "December";}
}

int main ()
{
   if (yyparse())
   {
      // parse error
      printf("ERROR\n");
      return 1;
    } 
    else 
    {   
        // successful parsing
        if (error == 0)
        {
            printSendTree();
            printSchTree();
        }
        else if (error == 1)
        {

        }

        return 0;
    } 
}