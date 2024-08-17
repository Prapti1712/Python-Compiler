%{
#include <stdio.h>
#include <iostream>
#include <stdlib.h>
#include <string.h>
#include <stdbool.h>
#include<string>
#include "parser.tab.h"
#include <string>
#include <cstdio>
#include <vector>
#include <cstring>
#include <fstream>
extern int yylex();
extern int yylineno;
extern char* yytext;
#define YYDEBUG 1
void yyerror(const char* s);
//extern int yylval;
extern int yyparse();
extern YYSTYPE yylval;
extern FILE* yyin;
extern int yystate;
extern YYSTYPE yyval;
extern YYSTYPE yystack[];
using namespace std;
struct ASTNode {
    string label;
    vector<struct ASTNode*> children;
};
struct ASTNode* root;
struct ASTNode* create_ast_node(string label) {
    struct ASTNode* node = (struct ASTNode*)malloc(sizeof(struct ASTNode));
    node->label = label;

    return node;
}

void add_child(struct ASTNode* parent, struct ASTNode* child) {
    if(parent == NULL) return;
    if(child == NULL) return;
    parent->children.push_back(child);
}

void print_ast_dot(std::ofstream& file, struct ASTNode* node) {

    if (node == NULL) return;
    
    std::string s = node->label;
    const char* v = s.c_str();
    file << "  node_" << node << " [label=\"" << v << "\"];\n";
    if((node->children.empty())) return;
    for (size_t i = 0; i < node->children.size(); i++) {
        if (node->children[i] != NULL) {
          file << "  node_" << node << " -> node_" << node->children[i]<<endl;
            print_ast_dot(file,node->children[i]);
          }
        
    }
}
void print_to_the_file(const std::string& filename, ASTNode* root){
    std::ofstream file(filename);
    if (!file.is_open()) {
        std::cerr << "Error opening file: " << filename << std::endl;
        exit(EXIT_FAILURE);
    }
    file << "digraph AST {\n";
    print_ast_dot(file, root);
    file << "}\n";

}

void print_help_page(){
    // cout << "Usage: ./prob.o [options]     \n\n";
    cout << "Commands:\n-h, --help \t\t\t\t\t Show help page\n";
    cout << "-i, --input <input_file_name> \t\t\t Give input file\n";
    cout << "-o, --output <output_file_name>\t\t\t Redirect dot file to output file\n";
    cout << "-v, --verbose \t\t\t\t\t Outputs the entire derivation in command line\n";
    return;
}

%}
%union {
    int token_value;    // Example member to store token value
    int non_terminal_value;  // Example member to store non-terminal value
}

%union {
    int intValue;
    char* strValue;
    struct ASTNode* node;
}

%token <strValue> NEWLINE
%token <strValue> ENDMARKER
%token <strValue> DEF 
%token <strValue> COLON 
%token <strValue> ARROW
%token <strValue> LPAREN
%token <strValue> RPAREN
%token <strValue> STAR 
%token <strValue> DOUBLESTAR
%token <strValue> COMMA
%token <strValue> EQUAL
%token <strValue> SEMI 
%token <strValue> PLUSEQUAL
%token <strValue> MINEQUAL
%token <strValue> STAREQUAL
%token <strValue> SLASHEQUAL
%token <strValue> DOUBLESLASHEQUAL
%token <strValue> PERCENTEQUAL
%token <strValue> ATEQUAL
%token <strValue> AMPEQUAL
%token <strValue> VBAREQUAL
%token <strValue> CIRCUMFLEXEQUAL
%token <strValue> VBAR
%token <strValue> RIGHTSHIFTEQUAL
%token <strValue> LEFTSHIFTEQUAL
%token <strValue> DOUBLESTAREQUAL
%token <strValue> BREAK 
%token <strValue> CONTINUE
%token <strValue> RETURN
%token <strValue> RAISE
%token <strValue> FROM 
%token <strValue> GLOBAL
%token <strValue> NONLOCAL
%token <strValue> ASSERT
%token <strValue> IF
%token <strValue> ELIF
%token <strValue> ELSE
%token <strValue> WHILE
%token <strValue> FOR
%token <strValue> IN
%token <strValue> TRY
%token <strValue> FINALLY 
%token <strValue> EXCEPT
%token <strValue> AS
%token <strValue> OR 
%token <strValue> AND
%token <strValue> NOT
%token <strValue> IS
%token <strValue> LESS 
%token <strValue> GREATER
%token <strValue> EQEQUAL
%token <strValue> GREATEREQUAL
%token <strValue> LESSEQUAL
%token <strValue> NOTEQUAL
%token <strValue> NOEQUAL 
%token <strValue> POWER 
%token <strValue> AMPER 
%token <strValue> LEFTSHIFT 
%token <strValue> RIGHTSHIFT
%token <strValue> PLUS
%token <strValue> MINUS
%token <strValue> AT 
%token <strValue> BACKSLASH
%token <strValue> PERCENT 
%token <strValue> DOUBLEBACKSLASH
%token <strValue> TILDE
%token <strValue> LSQBRACKET
%token <strValue> RSQBRACKET
%token <strValue> LCBRACE
%token <strValue> RCBRACE
%token <strValue> TRIPLEDOT
%token <strValue> NONE 
%token <strValue> RIGHT 
%token <strValue> WRONG
%token <strValue> DOT 
%token <strValue> CLASS 
%token <strValue> NUMBER
%token <strValue> NAME
%token <strValue> STRING
%token <strValue> INDENT
%token <strValue> DEDENT
%start start
%left PLUS MINUS
%left STAR SLASH PERCENT DOUBLEBACKSLASH
%type <node> start srt single_input file_input u eval_input operators simple_stmt B small_stmt o  compound_stmt optional_newline_or_stmt n_s stmt testlist optional_newline funcdef parameters a test b typedargslist tfpdef c optional_comma_tfpdef_c d j optional_semicolon_small_stmt expr_stmt flow_stmt global_stmt nonlocal_stmt assert_stmt NEW_NT A annassign augassign break_stmt continue_stmt return_stmt raise_stmt m n optional_comma_name if_stmt while_stmt for_stmt classdef suite optional_elif_test_colon_suite p stmts or_test and_test not_test comparison expr comp_op xor_expr optional_slash_xor_expr and_expr optional_power_and_expr optional_and_shift_expr shift_expr arith_expr optional_shift_operators_arith_expr shift_operators term optional_plus_minus_term plus_minus factor optional_operators_factor unary_operator power atom_expr atom optional_trailer trailer w x multi_string testlist_comp dictorsetmaker comp_for_sub NT y subscriptlist arglist subscript optional_comma_subscript sliceop exprlist optional_comma_expr optional_comma_test ran_out_of_names comp_for_optional_comma_r non_terminal optional_comma_r arg_list optional_comma_arguement argument
%%
start: srt {$$ = $1; 
// print_ast_dot($$);
root = $$;
};
srt: single_input  {
  // cout<<"single_inputcout<<"<<endl;
   $$=create_ast_node("srt");
  add_child($$, $1);
  //  $$ = $1;
}
| file_input {
  //cout<<"file_input"<<endl;
  $$=create_ast_node("srt");
 add_child($$, $1);
// $$ = $1;
}
 | eval_input  {
  //cout<<"eval_input"<<endl;
 $$=create_ast_node("srt");
add_child($$, $1);
// $$ = $1;
};
single_input: NEWLINE {
   $$ = create_ast_node("single_input");
  struct ASTNode* a = create_ast_node("NEWLINE \n"); add_child($$,a);
  // $$= NULL;
  }
            | simple_stmt {
               $$ = create_ast_node("single_input"); 
               add_child($$,$1);
              // $$ = $1;
               }
            | compound_stmt NEWLINE {
              struct ASTNode* a;
              a = create_ast_node("NEWLINE \n");
              $$ = create_ast_node("single_input");
              add_child($$,$1);
              add_child($$,a);
              // $$ = $1;
            }
            ;
file_input: optional_newline_or_stmt ENDMARKER {
  //cout<<"endmarker1"<<endl;
   $$ =create_ast_node("file_input");
   add_child($$, $1);
  // struct ASTNode* a;
  // a = create_ast_node("ENDMARKER");
  //  add_child(b,a);
  //  add_child(b, $1);
  // add_child(a,$1);
  //  $$ = b;
  }
    | ENDMARKER {
      $$=create_ast_node("file_input"); 
      struct ASTNode* a =create_ast_node("ENDMARKER");
       add_child($$,a);
      //  $$ = NULL;}
    }
          ;
// end_marker: end_marker ENDMARKER 
//           | ENDMARKER 
//           ;
optional_newline_or_stmt: optional_newline_or_stmt n_s {
  //  $$=create_ast_node("optional_newline_or_stmt");
  // if($1==NULL)
  // $$=$2;
  // else {
  // add_child($$, $1);
  // add_child($$, $2);}
  // struct ASTNode* a = create_ast_node("stmt");
  // cout<<"op_ns1"<<endl;
  // add_child($);
  add_child($2,$1);
  $$ = $2;
  // $$ = a;
}
| n_s{
  // $$=create_ast_node("optional_newline_or_stmt");
  // add_child($$, $1);
  // cout<<"op_ns2"<<endl;
   $$ = $1;
   }
                        ;
n_s: NEWLINE {
    $$ = create_ast_node("n_s");
  // cout<<"n_s1"<<endl;
  struct ASTNode* a;
   a = create_ast_node("(NEWLINE \n)");
  // // add_child($$,a);
  // // $$ = a;
  // // $$ = NULL;
  // add_child($$,a);
  $$ = a;
}
  | stmt{
  //  cout<<"ns2"<<endl;
  //  $$=create_ast_node("n_s");
  //   add_child($$, $1);
   $$ = $1;
  } ;
eval_input: testlist optional_newline ENDMARKER {
  //cout<<"endmarker3"<<endl;
struct ASTNode* a;
$$ = create_ast_node("eval_input");
add_child($$,$1);
add_child($$,$2);
a=create_ast_node("ENDMARKER");
add_child($$,a);

// add_child(a,$1);
// add_child(a,$2);
// $$ = a;
// $$ = $1;
}
|testlist ENDMARKER {
  //cout<<"endmarker4"<<endl;
$$ = create_ast_node("eval_input");
add_child($$,$1);
struct ASTNode* a;
a=create_ast_node("ENDMARKER");
add_child($$,a);
// $$ = a;
// $$ = $1;
}
;          
optional_newline: NEWLINE {
  $$ = create_ast_node("optional_newline");
   struct ASTNode* a =create_ast_node("(NEWLINE \n)");
   add_child($$,a);
  // $$ = NULL;
  } 
                | optional_newline NEWLINE {
                  // struct ASTNode* a;
                  // a = create_ast_node("NEWLINE");
                  // add_child(a,$1);
                  // $$ = a;
                  // $$ = create_ast_node("optional_newline");
   struct ASTNode* a =create_ast_node("NEWLINE \n");
  //  add_child($$,a);
  add_child(a,$1);
  $$ = a;
                  // $$ = NULL;
                }
                ;

funcdef: DEF NAME parameters a COLON suite {
  //cout<<"function"<<endl;
$$ = create_ast_node("funcdef");
struct ASTNode *b;
// a = create_ast_node("DEF");
//cout<<"HIIIIIIIIIII"<<$1<<endl;
string x = " ";
string y = "NAME";
string z = y + x;
string final = z + $2;
b = create_ast_node(final);
// c = create_ast_node("check");
// c = create_ast_node("COLON");
// add_child($$,a);
add_child($$,b);
// add_child($$,c);
add_child($$,$3);
 add_child($$,$4);
// add_child($$,c);
  add_child($$,$6);
  // print_ast_dot($$);
}
|DEF NAME parameters COLON suite {
  //cout<<"function"<<endl;
$$=create_ast_node("funcdef");
struct ASTNode* b;
// a = create_ast_node("DEF");
string x = " ";
string y = "NAME";
string z = y + x;
string final = z + $2;
b = create_ast_node(final);
// c = create_ast_node("COLON");
// add_child($$,a);
add_child($$,b);
add_child($$,$3);
// add_child($$,c);
add_child($$,$5);
// print_ast_dot($$);
}
  ;
a: ARROW test   {
  //cout<<"a"<<endl;
$$ = create_ast_node("type");

//  struct ASTNode* a;
//  a = create_ast_node("ARROW");
//  add_child($$,a);
add_child($$,$2);
//  $$=a;
// print_ast_dot($$);
}
;
parameters: LPAREN b RPAREN  {
  //cout<<"parameters"<<endl;
$$=create_ast_node("parameters");
struct ASTNode* a = create_ast_node("(");
struct ASTNode* b = create_ast_node(")");
// print_ast_dot($$);
add_child($$,a);
add_child($$,$2);
add_child($$,b);
};
// add_child($$,b);}; 
b: typedargslist { 
   $$=create_ast_node("b1"); 
   //cout<<"b1"<<endl; 
   add_child($$,$1);
  // $$ = $1;
  }
    | /* empty */ { 
      //cout<<"b2"<<endl;
       $$=NULL;};
typedargslist: tfpdef c optional_comma_tfpdef_c d { 
  //cout<<"typedarglist1"<<endl;
struct ASTNode* a = create_ast_node("typedarglist");
add_child(a,$1);
  add_child(a,$2);
  add_child(a,$3);
  add_child(a,$4);
  $$ = a;
}
  // | STAR f optional_comma_tfpdef_c g 
  // | DOUBLESTAR tfpdef i 
  ;
optional_comma_tfpdef_c: /*empty*/ {$$=NULL;}
                      | optional_comma_tfpdef_c COMMA tfpdef c {
                      // struct ASTNode* a;
                      // a = create_ast_node("COMMA");
                      // $$ = create_ast_node("optional_comma_tfpdef_c");
                      // add_child($$,$1);
                      add_child($3,$1);
                      add_child($3,$4);
                      $$ = $3;
                      // add_child(a,$4);
                      // $$ = a;
                      }
                      ;

c: EQUAL test {
  //cout<<"c"<<endl;
// $$ = create_ast_node("c");
struct ASTNode* a;
a = create_ast_node("=");
add_child(a,$2);
// add_child($$,$2);
$$=a;
}
    | /* empty */{$$=NULL;};
d: COMMA {
  $$ = create_ast_node(",");
  //cout<<"d"<<endl;
  // struct ASTNode* a;
  // a = create_ast_node("COMMA");
  // //add_child(a,$2);
  // add_child($$,a);
  // $$ = NULL;
}
  | /* empty */{$$=NULL;};
tfpdef: NAME j {
  //cout<<"tfpdef1"<<endl;
  $$ = create_ast_node("TFPDEF");
  // if($2 != NULL) {add_child(a,$2);}
  string space = " ";
  string y = "NAME";
  string x = y + space;
  string z = x + $1;
  // x.push_back() 
//cout<<"z="<<z<<endl;
  // const char* y = x.c_str;
  struct ASTNode* a = create_ast_node(z);

  add_child($$,a);
  add_child($$,$2);
  // $$ = a;
};
j: COLON test{
  //cout<<"j1"<<endl;
  $$ = create_ast_node("j");
    struct ASTNode* a = create_ast_node(":");
  // // if($2 != NULL) {add_child(a,$2);}
   add_child($$,a);
   add_child($$,$2);
  // $$ = $2;
  // $$ = $2;
}
    | /* empty */{ 
      //cout<<"j2"<<endl;
       $$=NULL;};

stmt: simple_stmt {
  //cout<<"stmt1"<<endl;
  //   $$=create_ast_node("stmt");
  //  add_child($$, $1);
  // $$ = NULL;
   $$ = $1;

  }
| compound_stmt {
  //  $$= create_ast_node("stmt");
  //   add_child($$,$1); 
  $$ = $1;
   //cout<<"stmt2"<<endl; 
   };

simple_stmt: small_stmt optional_semicolon_small_stmt SEMI NEWLINE {
  //cout<<"simple_stmt1"<<endl;
$$=create_ast_node("statement");
add_child($$,$1);
add_child($$,$2);
struct ASTNode* a;
a = create_ast_node("NEWLINE \n");
 add_child($$,a);
}
          | small_stmt optional_semicolon_small_stmt NEWLINE {
            //cout<<"simple_stmt2"<<endl;
          $$=create_ast_node("statement");
          add_child($$,$1);
          add_child($$,$2);
          }
          | small_stmt SEMI NEWLINE {
            //cout<<"simple_stmt3"<<endl;
          $$=create_ast_node("Statement");
add_child($$,$1);
struct ASTNode* a;
a = create_ast_node("NEWLINE \n");
add_child($$,a);
          }
          | small_stmt NEWLINE {
            //cout<<"simple_stmt4"<<endl;
           $$ = create_ast_node("statement");
            // struct ASTNode* a;
          // a = create_ast_node("NEWLINE");
          // $$ = $1;
           add_child($$,$1);
          //  $$ = $1;
            //  add_child($$,a);
            // add_child(a,$1);
           // $$ = $1;
          }
          ;
optional_semicolon_small_stmt: optional_semicolon_small_stmt SEMI small_stmt{
// $$=create_ast_node("SEMI");
// add_child($$,$2);
// add_child($$,$3);
// $$ = create_ast_node("optional_semicolon");
// add_child($$,$1);
add_child($3,$1);
$$ = $3;
// $$ = $3;
}

| SEMI small_stmt{
  $$ = create_ast_node("optional_semicolon");

  struct ASTNode* a=create_ast_node(";");
  add_child($$,a);
   add_child($$,$2);
  // $$ = $2;
}
;
// k: SEMI 
//   | /* empty */;
small_stmt: expr_stmt {
  //cout<<"small_stmt1"<<endl;
  //  $$ = create_ast_node("small_stmt");
  // add_child($$,$1);
  $$ = $1;

}
            | flow_stmt {
              //cout<<"small_stmt2"<<endl; 
            // $$ = $1;
            // $$ = create_ast_node("small_stmt");
            $$ = $1;
  // add_child($$,$1);

            }
            | global_stmt {
              //cout<<"small_stmt3"<<endl;
            // $$ = create_ast_node("small_stmt");
  // add_child($$,$1);
 $$ = $1;
 }
            | nonlocal_stmt {
              //cout<<"small_stmt4"<<endl;
            // $$ = create_ast_node("small_stmt");
  // add_child($$,$1);
$$ = $1;
             }
            | assert_stmt {
              //cout<<"small_stmt5"<<endl; 
            // $$ = create_ast_node("small_stmt");
  // add_child($$,$1);
$$ = $1;
}
            ;

expr_stmt: NEW_NT A {
  //cout<<"expr_stmt1"<<endl;
   $$=create_ast_node("expr_stmt");
  add_child($$, $1);
   add_child($$,$2);
  // $$ = $2;
  }
  | NEW_NT B{
    //cout<<"expr_stmt2"<<endl;
   $$=create_ast_node("expr_stmt");
  add_child($$,$1);
   add_child($$,$2);
 // $$ = $2;
  }
| NEW_NT {
  //cout<<"expr_stmt3"<<endl;
  // $$ = create_ast_node("expr_stmt");
//   struct ASTNode* a;
//    a=create_ast_node("=");
  //  add_child($$, $1);
  // add_child($$,$2);
//   add_child(a,$1);
//   add_child(a,$3);
  $$ = $1;
};
A: annassign {
  //cout<<"A1"<<endl;
 $$=$1;
 }
  |augassign testlist {
    $$ = create_ast_node("A");

    add_child($$,$1);
    add_child($$,$2);
    // $$ = $1;
    }
// | B {$$=$1;}
  ;
B: EQUAL NEW_NT  {
  //cout<<"b1"<<endl;
   $$=create_ast_node("B");
  struct ASTNode* a;
  a = create_ast_node("=");
  add_child($$,a);
  //printf("value = %s\n",$2->label);
//  $$ = a;
   add_child($$, $2);
  // $$ = a;
  }
| B EQUAL NEW_NT{
  //cout<<"b2"<<endl;
  // $$ = create_ast_node("B");
  struct ASTNode* c =create_ast_node("=");
   add_child($3,$1);
  add_child($3,c);
  // add_child($$,$3);
  $$ = $3;
}
;
annassign: COLON test c{
$$=create_ast_node("annassign");
struct ASTNode* a = create_ast_node(":");
add_child($$,a);
add_child($$,$2);
add_child($$,$3);
};
NEW_NT: test optional_comma_test d{
  //cout <<"new_nt1"<<endl;
  $$ = create_ast_node("test_expression");
  add_child($$,$1);
add_child($$,$2);
add_child($$,$3);
}
        | test d {
          //cout <<"new_nt2"<<endl;
          //cout<<"testlist"<<endl;
          // $$ = create_ast_node("test_expression");
           if($2==NULL)$$ = $1;
           else{
            $$ = create_ast_node("test_expression");
            add_child($$,$1);
            add_child($$,$2);
           }
          //  }
        //  add_child($$,$3);
         // $$ = $1;
          }
;
augassign: PLUSEQUAL {$$=create_ast_node("+=");}
          | MINEQUAL {$$=create_ast_node("-=");}
          | STAREQUAL {$$=create_ast_node("*=");}
          | ATEQUAL {$$=create_ast_node("@=");}
          | SLASHEQUAL {$$=create_ast_node("/=");}
          | PERCENTEQUAL {$$=create_ast_node("%=");}
          | AMPEQUAL {$$=create_ast_node("&=");}
          | VBAREQUAL {$$=create_ast_node("|=");}
          | CIRCUMFLEXEQUAL {$$=create_ast_node("^=");}
          | LEFTSHIFTEQUAL {$$=create_ast_node("<<=");}
          | RIGHTSHIFTEQUAL {$$=create_ast_node(">>=");}
          | DOUBLESTAREQUAL {$$=create_ast_node("**=");}
          | DOUBLESLASHEQUAL {$$=create_ast_node("//=");}
          ;
flow_stmt: break_stmt {
  $$=create_ast_node("flow_stmt");
add_child($$,$1);
// $$ = $1;
}
    | continue_stmt {
      $$=create_ast_node("flow_stmt");
    add_child($$,$1);
    // $$ = $1;
    }
    | return_stmt {
      $$=create_ast_node("flow_stmt");
    add_child($$,$1);
    // $$ = $1;
    }
    | raise_stmt {
      $$=create_ast_node("flow_stmt");
    add_child($$,$1);
    // $$ = $1;
    };
break_stmt: BREAK {$$=create_ast_node("BREAK");};
continue_stmt: CONTINUE {$$=create_ast_node("CONTINUE");};
return_stmt: RETURN testlist {
  $$=create_ast_node("RETURN");
  struct ASTNode* a = create_ast_node("return");
  add_child($$,a);
   add_child($$,$2);
   }
|RETURN {$$=create_ast_node("RETURN");};
// l: testlist
//   | /* empty */;
raise_stmt: RAISE m {
  $$=create_ast_node("RAISE");
   struct ASTNode* a = create_ast_node("raise");
  add_child($$,a);
   add_child($$,$2);
   };
m: test n {$$ = create_ast_node("test"); add_child($$,$1); add_child($$,$2);}
  | /* empty */{$$=NULL;};
n: FROM test {$$=create_ast_node("test"); struct ASTNode* a = create_ast_node("FROM"); add_child($$,a); add_child($$,$2); }
  | /* empty */{$$=NULL;};
// global_stmt: 'global' NAME (',' NAME)*;
global_stmt: GLOBAL NAME optional_comma_name {
$$=create_ast_node("global_stmt");
struct ASTNode* a, *b;
a = create_ast_node("GLOBAL");
add_child($$,a);
string space = " ";
string x = "NAME";
string y = x + space;
string z = y +  $2;
b=create_ast_node(z);
add_child($$,b);
add_child($$,$3);
};
// nonlocal_stmt: 'nonlocal' NAME (',' NAME)*;
nonlocal_stmt: NONLOCAL NAME optional_comma_name {
$$=create_ast_node("nonlocal_stmt");
struct ASTNode* a, *b;
a = create_ast_node("NONLOCAL");
add_child($$,a);
string space = " ";
string x = "NAME";
string y = x + space;
string z = y +  $2;
b=create_ast_node(z);
add_child($$,b);
add_child($$,$3);
};  
optional_comma_name : /*empty*/ {$$=NULL;}
                    | optional_comma_name COMMA NAME {
                      struct ASTNode* b, *c;
                    // $$ = create_ast_node("optional_comma_name");
                      c = create_ast_node("COMMA");
                    string space = " ";
string x = "NAME";
string y = x + space;
string z = y +  $3;
b=create_ast_node(z);
                      add_child(b,c);
                      add_child(b,$1);
                      $$ = b;
                      // add_child($$,c);
                      // $$ = a;
                    }
                    ;

assert_stmt: ASSERT test o  {
  $$=create_ast_node("assert_stmt");
  struct ASTNode* a = create_ast_node("ASSERT");
  add_child($$,a);
  add_child($$,$2);
  add_child($$,$3);
};
o: COMMA test {$$=create_ast_node("o"); struct ASTNode *a = create_ast_node(","); add_child($$,a); add_child($$,$2);} 
  | /* empty */ {$$=NULL;}; 
compound_stmt: if_stmt  {
  //cout<<"if_stmt"<<endl; 
  $$=create_ast_node("compound_stmt1"); add_child($$,$1);}
            | while_stmt {
              //cout<<"compound_stmt1"<<endl;
               $$=create_ast_node("compound_stmt2"); add_child($$,$1);}
            | for_stmt  {
              //cout<<"compound_stmt1"<<endl; 
              $$=create_ast_node("compound_stmt3"); add_child($$,$1);}
            | funcdef  {$$=create_ast_node("compound_stmt"); add_child($$,$1); 
            //cout<<"compound_stmt_func4"<<endl;
            }
            | classdef {
              //cout<<"compound_stmt_class"<<endl;
               $$=create_ast_node("compound_stmt5"); add_child($$,$1);}
            ;
// if_stmt: 'if' test ':' suite ('elif' test ':' suite)* p;
if_stmt: IF test COLON suite optional_elif_test_colon_suite p {
  //cout<<"if_stmt2"<<endl;
 $$=create_ast_node("If_stmt");
// struct ASTNode* a;
// a = create_ast_node("IF");
// add_child($$,a);
add_child($$,$2);
// add_child($$, $2);
add_child($$, $4);
add_child($$, $5);
add_child($$, $6);}
;
optional_elif_test_colon_suite: /*empty*/ {$$=NULL;}
                              |optional_elif_test_colon_suite ELIF test COLON suite {
                              // $$=create_ast_node("ELIF");
                              struct ASTNode* a;
                              a = create_ast_node("ELIF");
                              // add_child($$);
                              add_child($3,$1);
                              add_child($3,a);
                              add_child($3, $5);
                              // add_child($$,$5);
                              $$ = $3;
                              };
p: ELSE COLON suite {
$$=create_ast_node("ELSE");
// struct ASTNode* a;
// a = create_ast_node("ELSE");
// add_child($$,a);
add_child($$, $3);
}
  | /* empty */ {$$=NULL;};
while_stmt: WHILE test COLON suite p {
  $$=create_ast_node("WHILE_STATEMENt");
  struct ASTNode* a;
  a = create_ast_node("WHILE");
  add_child($$,a);
  add_child($$, $2);
  add_child($$, $4);
  add_child($$, $5);
}
; 
for_stmt: FOR exprlist IN testlist COLON suite p {
  $$=create_ast_node("FOR_STATEMENT");
  struct ASTNode* b;
  // a = create_ast_node("FOR");
  b = create_ast_node("IN");
  // add_child($$,a);
  add_child($$, $2);
  add_child($$,b);
  add_child($$, $4);
  add_child($$, $6);
  add_child($$, $7);
}
; 
suite: simple_stmt   {
  //cout<<"suite1"<<endl;
  //$$=create_ast_node("suite"); 
  //add_child($$,$1);
  $$=$1;
  }
    | NEWLINE INDENT stmts DEDENT {
      //cout<<"suite2"<<endl;
     //$$=create_ast_node("suite");
  // //  struct ASTNode* a,
    //add_child($$,$3);
  // $3 = NULL;
  $$=$3;
    // add_child($$,c);
    };
// dedent_plus: DEDENT 
//             | dedent_plus DEDENT 
//             ;
stmts: stmts stmt {
  //cout<<"stmts1"<<endl;
  // $$ = create_ast_node("statement");
  // $2 = NULL;
  // add_child($$,$1);
 add_child($2,$1);
 $$ = $2;
}
      | stmt{
         $$ = $1; 
        // $$ = create_ast_node("statement");
        //  add_child($$,$1);
        //cout<<"stmts2"<<endl; 
        };

test: or_test u {
  //cout<<"test"<<endl;
  if($2 == NULL){
    //cout<<"test1"<<endl;
    $$ = $1;
  }
  else{
    //cout<<"test2"<<endl;
    $$ = create_ast_node("TEST");
    add_child($$,$1);
   add_child($$,$2);}
   
  };  
u: IF or_test ELSE test {
  //cout<<"u1"<<endl;
$$=create_ast_node("IF-ELSE");
struct ASTNode* a, *b;
a = create_ast_node("IF");
b = create_ast_node("ELSE");
add_child($$,a);
add_child($$,$2);
add_child($$,b);
add_child($$,$4);
}
  | /* empty */{
    $$ = NULL;
  };
// test_nocond: and_test
// |or_test OR and_test;
// test_nocond: or_test ;
// or_test: or_test OR and_test
// ;

or_test: and_test{
  //cout<<"OR_TEST1"<<endl;
//  $$ = create_ast_node("OR_TEST");
//  add_child($$,$1);
 $$ = $1;
} 
|or_test OR and_test{
  //cout<<"OR_TEST2"<<endl;
// $$=create_ast_node("OR_Test");
struct ASTNode* a= create_ast_node("or");
add_child(a,$1);
// add_child($$,a);
add_child(a,$3);
$$ = a;
} 
;

and_test: not_test {
  //cout<<"AND_TEST1"<<endl;
  // $$ = create_ast_node("AND_TEST");
//  add_child($$,$1);
 $$ = $1;
}
|and_test AND not_test {
  //cout<<"AND_TEST2"<<endl;
// $$ = create_ast_node("AND_Test");
// add_child($$,$1);
struct ASTNode* a = create_ast_node("&&");
add_child(a,$1);
add_child(a,$3);
$$ = a;
}
;
not_test: NOT not_test {
  //cout<<"NOT_TEST1"<<endl;
 $$ = create_ast_node("not_test");
  struct ASTNode* a = create_ast_node("!");
  // if($2 != NULL) {add_child(a,$2);}
   add_child($$,a);
  add_child($$,$2);
  //  $$ = a;
}
    | comparison {
      //cout<<"NOT_TEST2"<<endl;
      //  $$ = create_ast_node("NOT_TEST");
  // add_child($$,$1);
 $$=$1;

    }
;
comparison: expr {
  //cout<<"COMPARISON1"<<endl;
//  $$ = create_ast_node("comparison");
//  add_child($$ ,$1);
 $$ = $1;
}
|comparison comp_op expr {
  //cout<<"comparison"<<endl;
// $$ = create_ast_node("comparison");
 add_child($2,$1);
add_child($2,$3);
// add_child($$,$3);
$$ = $2;

}
;

comp_op: LESS {$$=create_ast_node("<");}
        |GREATER {$$=create_ast_node(">");}
        |EQEQUAL  {$$=create_ast_node("==");}
        |GREATEREQUAL  {$$=create_ast_node(">=");}
        |LESSEQUAL  {$$=create_ast_node("<=");}
        |NOTEQUAL  {$$=create_ast_node("<>");}
        |NOEQUAL  {$$=create_ast_node("!=");}
        |IN  {$$=create_ast_node("in");}
        |NOT IN {
        // $$=create_ast_node("comp_op");
        struct ASTNode* a;
        a = create_ast_node("not in");
        $$ = a;
        // add_child($$,a);
        // add_child($$,b);
        }
        |IS {$$=create_ast_node("is");}
        |IS NOT {
        // $$=create_ast_node("comp_op");
        struct ASTNode* a;
        a = create_ast_node("is not");
        // b = create_ast_node("NOT");
        // add_child($$,a);
        // add_child($$,b);
        $$ = a;
        }
        ; 

expr: xor_expr optional_slash_xor_expr {
  //cout<<"expr"<<endl;
if($2==NULL){
//cout<<"/////////////////////////$2 IS NULL////////////////////////////////"<<endl;
$$ = $1;
}
else{
  $$ = create_ast_node("expr");

add_child($$,$1);
add_child($$,$2);
}

}
;
optional_slash_xor_expr: /*empty*/ {$$=NULL;}
                      | optional_slash_xor_expr VBAR xor_expr  {
                        //cout<<"OPTIONAL_SLASH1"<<endl;

       struct ASTNode* a;
       a = create_ast_node("|");

                      //  $$ = create_ast_node("optional_slash_xor_expr");
// add_child($$,$1);
add_child(a,$1);
add_child(a,$3);
$$ = a;
// add_child(a,$3);
// add_child(a,$3);
// $$=a;
                      }
                      ;
xor_expr: and_expr optional_power_and_expr {
  //cout<<"xor_expr"<<endl;

                        // $$ = create_ast_node("xor_expr");
                       if($2==NULL){
                        //cout<<"/////////////////////////$2 IS NULL////////////////////////////////"<<endl;
                        $$ = $1;
                        }
                        else{
                        $$ = create_ast_node("xor_expr");
add_child($$,$1);
add_child($$,$2);
}
}                       ;
optional_power_and_expr : /*empty*/  {
 // cout<<"optional_power1"<<endl; 
  $$=NULL;}
                        | optional_power_and_expr POWER and_expr {
                        // $$=create_ast_node("POWER_expr");
                        //cout<<"optional_power2"<<endl;
                        struct ASTNode* a= create_ast_node("^");
                        // add_child($$,$1);
                        add_child(a,$1);
                        add_child(a,$3);
                        $$ = a;
                        };
and_expr: shift_expr optional_and_shift_expr {
  //cout<<"and_expr"<<endl;
                      //  $$ = create_ast_node("and_expr");
                       if($2==NULL){
                        //cout<<"/////////////////////////$2 IS NULL////////////////////////////////"<<endl;
                        $$ = $1;
                        }
                        else{
                       $$ = create_ast_node("and_expr");

add_child($$,$1);
add_child($$,$2);}
 }
 ;

optional_and_shift_expr: /*empty*/ {$$=NULL;}
                    | optional_and_shift_expr AND shift_expr {
                      //cout<<"optional_and_shift_exp"<<endl;
                      //  $$ = create_ast_node("optional_and_shift_exp");
                       struct ASTNode * a;
                      a = create_ast_node("and");
//  add_child($$,$1);
add_child(a,$1);
 add_child(a,$3);
 $$ = a;
          // add_child(a,$1);
          // add_child(a,$3);
          // $$ = a;           

                    }
                    ;
// shift_expr: arith_expr (('<<'|'>>') arith_expr)*;
shift_expr: arith_expr optional_shift_operators_arith_expr {
  //cout<<"shift_expr"<<endl;
if($2 == NULL){
  $$ = $1;
  //cout<<"/////////////////////////$2 IS NULL////////////////////////////////"<<endl;
}
else{
  $$ = create_ast_node("SHIFT_expr");
  add_child($$,$1);
 add_child($$,$2);
}
 
}  ; 
optional_shift_operators_arith_expr: /*empty*/ {$$=NULL;}
                                  | optional_shift_operators_arith_expr shift_operators arith_expr {
                                    //cout<<"OPTIONAL_shift_expr"<<endl;
// $$ = create_ast_node("shift_operators");
// add_child($$,$1);
 add_child($2,$1);
 add_child($2,$3);
 $$ = $2;
// add_child($2,$3);
// $$ = $2;
                                  }
                                  ;
shift_operators: LEFTSHIFT  {$$=create_ast_node("<<");}
       |RIGHTSHIFT  {$$=create_ast_node(">>");};
// arith_expr: term (('+'|'-') term)*;
arith_expr: term optional_plus_minus_term{
  //cout<<"arith_expr"<<endl;
// $$ = create_ast_node("arith_expr");
if($2 == NULL){
  $$ = $1;
  //cout<<"/////////////////////////$2 IS NULL////////////////////////////////"<<endl;
}
else{
  $$ = create_ast_node("arith_expr");

  add_child($$,$1);
  add_child($$,$2);
}
}
;
optional_plus_minus_term: /*empty*/ {$$=NULL;}
                        | optional_plus_minus_term plus_minus term {
                          //cout<<"OPTIONAL_PLUS_MINUS"<<endl;
                          //  $$ = create_ast_node("optional_PLUS_MINUS");
//                           if($$!=NULL){
//                           if($1!=NULL)
// add_child($$,$1);
 add_child($2,$1);
// add_child($$,$3);}
// add_child($2,$1);
 add_child($2,$3);
$$ = $2;
}
                        ;
plus_minus: PLUS {$$=create_ast_node("+");}
     |MINUS  {
      //cout<<"plus_minus"<<endl;
     $$=create_ast_node("-");};
term: factor optional_operators_factor{
  if($2==NULL){
    //cout<<"-----------------------------------------------------<"<<endl;
  $$ = $1;
  }
  else{
  $$ = create_ast_node("term");
  add_child($$,$1);
add_child($$,$2);}
// $$=$1;
  
}
|factor {
  //cout<<"term"<<endl;
//  $$ = create_ast_node("TERM");
 $$ = $1;
// add_child($$,$1);
}
;
optional_operators_factor: operators factor {
  // add_child($1,$2);
  $$ = create_ast_node("OPERATORS_FACTOR");
  // $$=$1;
  add_child($$,$1);
  add_child($$,$2);
} 
                         |optional_operators_factor operators factor {
  // $$ = create_ast_node("OPTIONAL_OPERATORS_FACTOR");

  // add_child($$,$1);
  add_child($2,$1);
// add_child($$,$3);}
// add_child($2,$1);
 add_child($2,$3);
$$ = $2;
                         }
                         ;
operators: STAR {
  // $$=create_ast_node("OPERATOR");
  struct ASTNode* a;
   a = create_ast_node("*");
  // add_child($$,a);
  $$ = a;
  }
          |AT {
  // $$=create_ast_node("OPERATOR");
   struct ASTNode* a;
   a = create_ast_node("AT");
  // add_child($$,a);
  $$ = a;
  // $$=create_ast_node("AT");
            }
          |BACKSLASH {
  // $$=create_ast_node("OPERATOR");
  struct ASTNode* a;
  a = create_ast_node("/");
  // add_child($$,a);
  $$ = a;
            }
          |PERCENT {
  // $$=create_ast_node("OPERATOR");
  struct ASTNode* a;
  a = create_ast_node("%");
  // add_child($$,a);
  $$ = a;
            }
          |DOUBLEBACKSLASH {
  // $$=create_ast_node("OPERATOR");
  struct ASTNode* a;
  a = create_ast_node("//");
  // add_child($$,a);
  $$ = a;
            };
// factor: ('+'|'-'|'~') factor | power
factor: unary_operator factor  {
  //cout<<"factor 2"<<yytext<<endl;
$$ = create_ast_node("FACTOR");
add_child($$,$1);
add_child($$,$2);
// $$=$1;
}
      | power {
        //cout<<"factor1\n"<<yytext<<endl;
      //  $$ = create_ast_node("FACTOR");
 $$ = $1;
// add_child($$,$1);
      };
unary_operator: PLUS {
struct ASTNode* a = create_ast_node("+");
// add_child($$,a);
$$ = a;
}
                |MINUS {
                  //cout<<"unary_operator"<<endl;
$$=create_ast_node("-");
// struct ASTNode* a = create_ast_node("MINUS");
// // add_child($$,a);
// $$ = a;
}
                // $$=create_ast_node("MINUS");}
                |TILDE {
// $$=create_ast_node("UNARY_OPERATOR");
$$ = create_ast_node("~");
// add_child($$,a);
};
power: 
// atom_expr v {cout<<"power2"<<endl;
// add_child($1,$2);
// $$=$1;}| 
atom_expr {
  //cout<<"power1"<<endl;
//  $$ = create_ast_node("POWER");
$$ = $1;
// add_child($$,$1);
}
;
// v: DOUBLESTAR factor
// ;
atom_expr: atom optional_trailer {
  //cout<<"atom_expr1"<<endl;

  $$ = create_ast_node("atom_expr");
add_child($$,$1);
add_child($$,$2);

}
| atom{
  //cout<<"atom_expr2"<<endl;
 //$$ = create_ast_node("ATOM_EXPR");
 $$ = $1;
// add_child($$,$1);
};
optional_trailer:trailer {
  // $$=create_ast_node("OPTIONAL_TRAILER");
  // add_child($$,$1);
  $$ = $1;
  }
               | optional_trailer trailer {
                // $$ = create_ast_node("OPTIONAL_TRAILER");

                add_child($2,$1);
                $$ = $2;
                // add_child($$,$1);
                // $$=$2;
               }
               ;
// atom: ('(' w ')' |
//        '[' w ']' |
//        '{' x '}' |
//        NAME | NUMBER | STRING+ | '...' | 'None' | 'True' | 'False');
atom: LPAREN w RPAREN {
  //cout<<"atom1"<<endl; 
$$=create_ast_node("atom");
struct ASTNode* a, *b;
a = create_ast_node("(");
b = create_ast_node(")");
add_child($$,a);
add_child($$,$2);
add_child($$,b);
// $$ = $2;
}
      | LSQBRACKET w RSQBRACKET {
        //cout<<"atom2"<<endl; 
        $$=create_ast_node("atom");
struct ASTNode* a, *b;
a = create_ast_node("[");
b = create_ast_node("]");
add_child($$,a);
add_child($$,$2);
add_child($$,b);
// $$ = $2;
}
      | LCBRACE x RCBRACE {
        //cout<<"atom3"<<endl; 
$$=create_ast_node("atom");
struct ASTNode* a, *b;
a = create_ast_node("(");
b = create_ast_node(")");
add_child($$,a);
add_child($$,$2);
add_child($$,b);
// $$ = $2;
}
      | NAME {
        //cout<<"atom4 "<<yytext<<endl;
      //  $$ = create_ast_node("ATOM4");
      // $$ = create_ast_node("atom");
       struct ASTNode* a;
       string space = " ";
       string x = "NAME";
       string z = x + space;
       string y = z + $1;
      //  const char* s = yytext;
       a = create_ast_node(y);
        $$ = a;
        // add_child($$,a);
      }
       | NUMBER {
        //cout<<"atom5"<<endl;
        // $$ = create_ast_node("ATOM5");
       struct ASTNode* a;
       string space = " ";
       string x = "NUMBER";
       string z = x + space;
       string y = $1;
       string final = z + y;
       a = create_ast_node(final);
       $$ = a;
      // add_child($$,a);
      }
        | multi_string {
          //cout<<"atom6"<<endl;
        // $$ = create_ast_node("ATOM");
        // add_child($$,$1);
         $$=$1;
         }
        | TRIPLEDOT {
          //cout<<"atom7"<<endl;
        // $$ = create_ast_node("ATOM");
        struct ASTNode* a;
        string space = " ";
       string x = "TRIPLEDOT";
       string z = x + space;
       string y = $1;
       string final = z + y;
       a = create_ast_node(final);

        // add_child($$,a);
$$ = a;
         }
        | NONE {
          //cout<<"atom8"<<endl;
        //  $$=create_ast_node("atom"); 
         struct ASTNode* a=create_ast_node("NONE");
          // add_child($$,a);
          $$ = a;
          }
        | RIGHT {
          //cout<<"atom9"<<endl;
        //  $$=create_ast_node("RIGHT");
        // $$ = create_ast_node("ATOM");
        // struct ASTNode* a;
       struct ASTNode* a;
        string space = " ";
       string x = "RIGHT";
       string z = x + space;
       string y = $1;
       string final = z + y;
       a = create_ast_node(final);
        // add_child($$,a);
        $$ = a;
         }
        | WRONG {
          //cout<<"atom10"<<endl;
        //  $$=create_ast_node("WRONG");
        // $$ = create_ast_node("ATOM");
        // struct ASTNode* a;
       struct ASTNode* a;
        string space = " ";
       string x = "WRONG";
       string z = x + space;
       string y = $1;
       string final = z + y;
       a = create_ast_node(final);
$$ = a;
        // add_child($$,a);

         };
multi_string: multi_string STRING {
 struct ASTNode* a;
// $$ = create_ast_node("STRINGs");
string space = " ";
       string x = "STRING";
       string z = x + space;
       string y = $2;
       string final = z + y;
 a = create_ast_node(final);
add_child(a,$1);
$$ = a;
// add_child($$,$1);
}
             | STRING {
      // struct ASTNode* a;
      // string space = " ";
      // string x = "STRING";
      // string y = x + space;
      // string final = y + $1;
$$ = create_ast_node("STRING");
              }; 
w: testlist_comp {
  // $$ = create_ast_node("W");
  // add_child($$,$1);
  // // add_child($$,$2);
  $$=$1;
  }
  | /* empty */{$$=NULL;};
x: dictorsetmaker {
  $$ = create_ast_node("X");
  add_child($$,$1);
  // add_child($$,$2);
  }
  | /* empty */{$$=NULL;};
testlist_comp: test comp_for_sub {
  $$ = create_ast_node("testlist_comp");
  add_child($$,$1);
  add_child($$,$2);;
  }
 ;
comp_for_sub:  NT d {
  //cout<<"comp_for_sub1"<<endl;
  $$ = create_ast_node("comp_for_sub");
              add_child($$,$1);
              add_child($$,$2);
              // $$=$1;
            }
            |d {
                //cout<<"comp_for_sub1"<<endl;
              $$ = create_ast_node("comp_for_sub");
              add_child($$,$1);
              // add_child($$,$2);
              // $$=$1;
              }
 ;
NT: COMMA test {
  //cout<<"optional_comma_test1"<<endl;
$$=create_ast_node("COMMA_test");
// struct ASTNode* a;
// a = create_ast_node("COMMA");
// add_child($$,a);
add_child($$,$2);
// $$ = $2;
}
| NT COMMA test {
 // cout<<"optional_comma_test2"<<endl;
  $$=create_ast_node("COMMA_test");
// $$ = create_ast_node("tests");
add_child($3,$1);
// add_child($$,$3);
$$ = $3;
}
                                  ;
// test_or_star_expr : test {cout<<"test_or_star_expr"<<endl;}
//                   | star_expr 
//                   ;

trailer: LPAREN y RPAREN {
  //cout<<"LPAREN2"<<endl; 
$$=create_ast_node("TRAILER");
struct ASTNode* a, *b;
a = create_ast_node("(");
b = create_ast_node(")");
add_child($$,a);
add_child($$,$2);
add_child($$,b);
//  $$ = $2;
}
   | LSQBRACKET subscriptlist RSQBRACKET {
    $$=create_ast_node("TRAILER");
struct ASTNode* a, *b;
a = create_ast_node("[");
b = create_ast_node("]");
add_child($$,a);
add_child($$,$2);
add_child($$,b);
// $$ = $2;
}
   | DOT NAME{$$=create_ast_node("trailer"); struct ASTNode* b; 
  //  a = create_ast_node("DOT");
  string space = " ";
       string x = "NAME";
       string z = x + space;
       string y = $2;
       string final = z + y;
   b = create_ast_node(final);
  //  add_child($$,a);
   add_child($$,b);
  // $$ = b;
   };
y: arglist {
  // $$ = create_ast_node("Y");
  // add_child($$,$1);
  $$=$1;
  }
  | /* empty */{$$=NULL;};
// subscriptlist: subscript (',' subscript)* i;
subscriptlist: subscript optional_comma_subscript d{
  $$ = create_ast_node("subscriptlist");
  add_child($$,$1);
add_child($$,$2);
if($3==NULL)
//cout<<"NNNNNNNNNNNUUUUUUUUUUUULLLLLLLLLLLLLL"<<endl;
add_child($$,$3);
// $$/=$1;
};

optional_comma_subscript: /*empty*/ {
 // cout<<"------------------here------------------"<<endl; 
  $$=NULL;}
                        | optional_comma_subscript COMMA subscript{
                          // $$=create_ast_node("subscript");
                          // add_child($$,$1);
                          // struct ASTNode* a;
                          // a = create_ast_node("COMMA");
                          // add_child($$,a);
                          if($3==NULL){
                           // cout<<"--------------------------------good-----------------------------";
                          }
                          add_child($3,$1);
                          $$ = $3;
                        }
                        ;

subscript: test {
  //cout<<"subscript1"<<endl;
  // $$ = create_ast_node("SUBSCRIPT");
  // add_child($$,$1);
  $$=$1;
  }
|test COLON test sliceop{
  //cout<<"subscript2"<<endl;
  $$=create_ast_node("subscript");
  add_child($$,$1);
  // struct ASTNode* a;
  // a = create_ast_node("COLON");
  // add_child($$,a);
  add_child($$,$3);
  add_child($$,$4);
}
|test COLON test{
  //cout<<"subscript3"<<endl;
  $$=create_ast_node("subscript");
  add_child($$,$1);
  // struct ASTNode* a;
  // a = create_ast_node("COLON");
  // add_child($$,a);
  add_child($$,$3);
}
|COLON test sliceop {
 // cout<<"subscript4"<<endl;
  $$=create_ast_node("subscript");
  // struct ASTNode* a;
  // a = create_ast_node("COLON");
  // add_child($$,a);
  add_child($$,$2);
  add_child($$,$3);
}
|COLON test{
  //cout<<"subscript5"<<endl;
   $$=create_ast_node("subscript");
  // // struct ASTNode* a;
  // // a = create_ast_node("COLON");
  // // add_child($$,a);
   add_child($$,$2);
  // $$ = $2;
}
|test COLON sliceop{
  //cout<<"subscript6"<<endl;
  $$=create_ast_node("subscript");
  add_child($$,$1);
  // struct ASTNode* a;
  // a = create_ast_node("COLON");
  // add_child($$,a);
  add_child($$,$3);
}
|test COLON {
  //cout<<"subscript7"<<endl;
   $$=create_ast_node("subscript");
add_child($$,$1);
  // struct ASTNode* a;
  // a = create_ast_node("COLON");
  // add_child($$,a);
  // $$ = $1;
}
|COLON sliceop{
  //cout<<"subscript8"<<endl;
   $$=create_ast_node("subscript");
  struct ASTNode* a;
  a = create_ast_node("COLON");
  add_child($$,a);
  // add_child($$,$2);
  // $$ = $2;
}
|COLON{
  //cout<<"subscript9"<<endl;
  // $$=create_ast_node("COLON");
  $$=create_ast_node("SUBSCRIPT");
  struct ASTNode* a;
  a = create_ast_node("COLON");
  add_child($$,a);
}
;

// s_o: sliceop 
//   | /* empty */;
sliceop: COLON test {
  // $$=create_ast_node("sliceop");  
  // struct ASTNode* a;
  // a = create_ast_node("COLON");
  // add_child($$,a);
  // add_child($$,$2);
  $$ = create_ast_node("SLICEOP");
  add_child($$,$2);
  // $$ = $2;
}
|COLON {
  $$=create_ast_node("SLICEOP");
  struct ASTNode* a;
  a = create_ast_node("COLON");
  add_child($$,a);
};

exprlist: expr optional_comma_expr COMMA {
  $$=create_ast_node("exprlist");
  add_child($$,$1);
  add_child($$,$2);
  // struct ASTNode* a;
  // a = create_ast_node("COMMA");
  // add_child($$,a);
}
|expr optional_comma_expr{
  $$=create_ast_node("exprlist");
  add_child($$,$1);
  add_child($$,$2);
} 
|expr COMMA {
  $$=create_ast_node("exprlist");
  add_child($$,$1);
  // struct ASTNode* a;
  // a = create_ast_node("COMMA");
  // add_child($$,a);
  // $$ = $1;
}
|expr {
  $$ = create_ast_node("EXPRLIST");
  add_child($$,$1);
  // $$=$1;
  }
;

optional_comma_expr: COMMA expr {
  $$=create_ast_node("optional_comma_expr");
  // struct ASTNode* a;
  // a = create_ast_node("COMMA");
  // add_child($$,a);
  add_child($$,$2);
  // $$ = $2;
}
                  | optional_comma_expr COMMA expr {
                    // $$=create_ast_node("optional_comma_expr");
                    add_child($3,$1);
                    $$ = $3;
                    // struct ASTNode* a;
                    // a = create_ast_node("COMMA");
                    // add_child($$,a);
                    // add_child($$,$1);
                  };

testlist: test optional_comma_test {
  //cout<<"testlist1"<<endl;
  $$=create_ast_node("testlist");
  add_child($$,$1);
  add_child($$,$2);
}
          |test optional_comma_test COMMA{
            //cout<<"testlist2"<<endl;
  $$=create_ast_node("testlist");
  add_child($$,$1);
  add_child($$,$2);
          }
          |test COMMA{
            // cout<<"testlist3"<<endl;
            $$=create_ast_node("testlist");
            add_child($$,$1);
            // struct ASTNode* a;
            // a = create_ast_node("COMMA");
            // add_child($$,a);
            // $$ = $1;
          }
          |test { 
            //cout<<"testlist4"<<endl; 
            $$=create_ast_node("testlist");
            add_child($$,$1);}
          ;
optional_comma_test: COMMA test {
$$=create_ast_node("optional_comma_test");
// struct ASTNode* a;
// a = create_ast_node("COMMA");
// add_child($$,a);
add_child($$,$2);
// $$ = $2;
}
 | optional_comma_test COMMA test {
    // $$=create_ast_node("optional_comma_test");
    add_child($3,$1);
    $$ = $3;
    // struct ASTNode* a;
    // a = create_ast_node("COMMA");
    // add_child($$,a);
    // add_child($$,$1);
 } ;
// dictorsetmaker: ((test ':' test | '**' expr)(comp_for | (',' (test ':' test | '**' expr))* [','])) |
//                   ((test | star_expr) (comp_for | (',' (test | star_expr))* [',']))
dictorsetmaker: ran_out_of_names comp_for_optional_comma_r {
  $$ = create_ast_node("dictorsetmarker");
add_child($$,$1);
add_child($$,$2);
// $$=$1;
}
              | test non_terminal {
                //cout<<"dictorsetmaker"<<endl;
              $$ = create_ast_node("dictorsetmarker");
add_child($$,$1);
add_child($$,$2);
// $$=$1;
              }
              ;

non_terminal: optional_comma_test d {
  //cout<<"non_terminal"<<endl;

    $$ = create_ast_node("tests");
              add_child($$,$1);
              add_child($$,$2);
}
            | d {
              // $$=$1;
              $$ = create_ast_node("NON_TERMINAL");
              add_child($$,$1);
              // add_child($$,$2);
            }
            ; /*naam hi nahi bacche :(*/

comp_for_optional_comma_r: optional_comma_r d {

  $$ = create_ast_node("tests");
  add_child($$,$1);
  add_child($$,$2);

 }
| d {$$ = create_ast_node("tests");
  add_child($$,$1);}
;
optional_comma_r: COMMA ran_out_of_names {
  $$=create_ast_node("optional_comma_r");
  // struct ASTNode* a;
  // a = create_ast_node("COMMA");
  // add_child($$,a);
  // $$ = $2;
  add_child($$,$2);
  }
                | optional_comma_r COMMA ran_out_of_names{
                  // $$=create_ast_node("OPTIONAL_COMMA_R");
                  // add_child($$,$1);
                  // struct ASTNode* a;
                  // a = create_ast_node("COMMA");
                  // add_child($$,a);
                  add_child($3,$1);
                  $$ = $3;
                }
                ;
ran_out_of_names: test COLON test {
  $$=create_ast_node("test");
  add_child($$,$1);
  // struct ASTNode* a;
  // a = create_ast_node("COLON");
  // add_child($$,a);
  add_child($$,$3);
}
                ;
classdef: CLASS NAME arg_list COLON suite {
  $$=create_ast_node("classdef");
  struct ASTNode* a, *b;
  a = create_ast_node("CLASS");
  string space = " ";
       string x = "NAME";
       string z = x + space;
       string y = $2;
       string final = z + y;
  b = create_ast_node(final);
  // c = create_ast_node("COLON");
  add_child($$,a);
  add_child($$,b);
  add_child($$,$3);
  // add_child($$,c);
  add_child($$,$5);
  // print_ast_dot($$)
}
        | CLASS NAME COLON suite{
          $$=create_ast_node("classdef");
          struct ASTNode* a, *b;
          a = create_ast_node("CLASS");
         string space = " ";
       string x = "NAME";
       string z = x + space;
       string y = $2;
       string final = z + y;
  b = create_ast_node(final);
          // c=create_ast_node("COLON");
          add_child($$,a);
          add_child($$,b);
          // add_child($$,c);
          add_child($$,$4);
        }
        ;
arg_list: LPAREN y RPAREN{
  //cout<<"LPAREN3"<<endl; 
  $$ = create_ast_node("arg_list");
  struct ASTNode* a, *b;
  a = create_ast_node("(");
  b = create_ast_node(")");
  add_child($$,a);
  add_child($$,$2);
  add_child($$,b);
  };
// arglist: argument (',' argument)*  [',']
arglist: argument optional_comma_arguement d{
$$=create_ast_node("arglist");
add_child($$,$1);
if($2!=NULL) add_child($$,$2);
add_child($$,$3);
}
|argument d{
$$=create_ast_node("arglist");
add_child($$,$1);
add_child($$,$2);}
      ;
optional_comma_arguement: COMMA argument{
  // $$=create_ast_node("optional_comma_arguement");
  // struct ASTNode* a;
  // a = create_ast_node("COMMA");
  // add_child($$,a);
  // add_child($$,$2);
  $$ = $2;

}
                        | optional_comma_arguement COMMA argument{
                          // $$=create_ast_node("arguements");
                          // add_child($$,$1);
                          // struct ASTNode* a;
                          // a = create_ast_node("COMMA");
                          // add_child($$,a);
                          // $$ = create_ast_node("OPTIONAL_COMMA_ARGUEMENT");
                          // add_child($$,$1);
                          add_child($3,$1);
                          $$ = $3;
                        };
argument:test {
  $$=$1;
  // $$ = create_ast_node("argument_test");
  // add_child($$,$1);
  }
        |test EQUAL test {
          //cout<<"arguement"<<endl;

          struct ASTNode* a;
          a = create_ast_node("=");
          add_child(a,$1);
          add_child(a,$3);
          $$ = a;
        };

%%

int main(int argc, char *argv[]){
  bool verbose = false;
   string input_file_name;
   string output_file_name;
       for(int i = 1; i < argc; i++){        
        if(std::string(argv[i]) == "--help" || std::string(argv[i]) == "-h") {
            print_help_page();
            return -1;
        }
        if(std::string(argv[i]) == "--input" || std::string(argv[i]) == "-i") {
            if((i + 1) < argc) input_file_name = argv[i+1];
            else cout << "Error: No input filename given";
            i++;
        }
        else if(std::string(argv[i]) == "--output" || std::string(argv[i]) == "-o") {
            if((i + 1) < argc) output_file_name = argv[i+1];
            else cout << "Error: No output filename given";
            i++;
        }
        else if(std::string(argv[i]) == "--verbose" || std::string(argv[i]) == "-v") {
            verbose = true;
        }
        else {
            cout << "Error: Invalid parameter\n";
            print_help_page();
            return -1;
        }
    }
    if(verbose) yydebug=1;

    FILE *input_file = fopen(input_file_name.c_str(),"r");
      yyin = input_file;
  yyparse();
  print_to_the_file(output_file_name.c_str(), root);
  fclose(input_file);
}

void yyerror(const char* s) {
    fprintf(stderr, "%s %d %s\n", s, yylineno, yytext);
}
