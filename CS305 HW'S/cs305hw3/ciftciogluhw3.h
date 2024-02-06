#ifndef __CIFTCIOGLUHW3_H
#define __CIFTCIOGLUHW3_H

typedef enum { SEND, SCH, VAR, RECIP } NodeType;

typedef struct IdentifierStruct {
        char * str;
        int lineNum;
} IdentifierStruct;

typedef struct SendNode {
        char *sender;
        char *receiver;
        char *msg;
        struct TreeNode *next;
} SendNode;

typedef struct SchNode {
        char *sender;
        char *receiver;
        char *date;
        char *time;
        char *schMsg;
        struct TreeNode *next;
} SchNode;

typedef struct VarNode {
        char *ident;
        char *identVal;
        struct TreeNode *next;
} VarNode;

typedef struct RecipNode{
        int hasName;
        char *name;
        char *address;
        struct TreeNode *next;
} RecipNode;

typedef union {
        SendNode send;
        SchNode sch;
        VarNode var;
        RecipNode recip;
} Node;

typedef struct TreeNode{
	NodeType thisNodeType;
        Node * NodePtr;
} TreeNode;

void mkVarNode (char *, char *);

TreeNode * mkSendNode (TreeNode *, char *, int, int);
TreeNode * mkSendNodeList (char *, TreeNode *, int, int);

TreeNode * mkSchNode (char *, char *, char *, char *);
TreeNode * mkSchNodeList(TreeNode *, char *, char *);

TreeNode * mkRecipNode1 (char *);
TreeNode * mkRecipNode2 (char *, char *, int, int);
TreeNode * mkRecipientList (TreeNode *, TreeNode *);

char * checkVar (char *);
int isLeftDateEarlier(TreeNode *, TreeNode *);
void substr(char *, char *, int, int);
void insertSch(TreeNode *);

void printSendTree();
void printSchTree();
char * createMonth(char *);
char * cleanRecip(char *);
#endif