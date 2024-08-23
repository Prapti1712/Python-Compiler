%{
#include <stdio.h>
#include <iostream>
#include <stdlib.h>
#include <string.h>
#include <stdbool.h>
#include <string>
#include <chrono>
#include "parser.tab.h"
#include <string>
#include <cstdio>
#include <vector>
#include <stack>
#include <cstring>
#include <fstream>
#include <sstream>
#include <iomanip>
#include <regex>
#include <unordered_map>
#include <map>
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
int class_offset=0;
int class_arg =0;
string dot_name;
int stack_pointer =0;
struct Variable{
string type;
int size;
int offset; // For local variables
string source_file;
int line_number;
string scope;
};
int dot_present = 0;
vector<string> func_names;
string class_nam;
string expr_value="";
class LocalSymbolTable {
  public:
    unordered_map<string, Variable*> variables;
    unordered_map<string,vector<string>>address_descriptor;
    unordered_map<string,vector<string>>register_descriptor;
    unordered_map<string, int> offsets;
    int regs_index;
     int curr_offset;
     string return_type;
     string return_val;
    vector<string> parameter_types;
    string source_file;
    int line_number;
    int size;
    string scope;
   LocalSymbolTable* parent;
    unordered_map<string, LocalSymbolTable*> children;
    int is_function;
    LocalSymbolTable(unordered_map<string, Variable*> variables,unordered_map<string,vector<string>>address_descriptor,unordered_map<string,vector<string>>register_descriptor,unordered_map<string, int> offsets,int regs_index, int curr_offset, string return_type, string return_val, vector<string> parameter_types, string source_file, int line_number, int size, string scope, LocalSymbolTable* parent, unordered_map<string, LocalSymbolTable*> children){
        this->variables = variables;
        this->address_descriptor = address_descriptor;
        this->register_descriptor = register_descriptor;
        this->offsets = offsets;
        this->regs_index = regs_index;
        this->curr_offset = curr_offset;
        this->return_type = return_type;
        this->return_val=return_val;
        this->parameter_types = parameter_types;
        this->source_file = source_file;
        this->line_number = line_number;
        this->size = size;
        this->scope = scope;
        this->parent = parent;
        this->children = children;
    }
};
stack<LocalSymbolTable*> tables;
vector<pair<string,LocalSymbolTable*>> all_tables;
int is_equal=0, is_colon=0, is_lookup=0, is_paren=0, func_error_line=0, is_lsq=0, type_error_line=0, for_error=0, arr_size=0, par_size=0, push_size=0, is_func_param=0;
string is_dot="", is_func_dot="", list_type="", func_name="";
unordered_map<string, Variable*> variables={{"__init__",new Variable()},{"self",new Variable()},{"__name__",new Variable()}, {"list", new Variable()}, {"int", new Variable()}, {"float", new Variable()}, {"str", new Variable()}, {"bool", new Variable()}, {"range", new Variable()}, {"print", new Variable()}, {"len",new Variable()}};
unordered_map<string, Variable*> variable;
vector<string> parameter_types;
unordered_map<string,vector<string>>address_descriptor;
unordered_map<string,vector<string>>register_descriptor;
unordered_map<string,int> offsets;
unordered_map<string, LocalSymbolTable*> children; 
LocalSymbolTable* global_table = new LocalSymbolTable(variables,address_descriptor,register_descriptor,offsets,0,0,"", "", parameter_types, "", 0, 0,"global", NULL, children);
// global_table->parent = NULL;
int offset = 0;
string current_scope = "global";
string current_type;
string current_variable;
int current_line, redeclared_line;
LocalSymbolTable* current_local_symbol_table = global_table;
int is_list=0;
map<int, string> scope_variable;
map<int, string> func_errors;
map<int, string> type_errors;
vector<string> function_arguments;
vector<string> function_arguments_name;
stack<vector<string>> func;
stack<int> func_running;
stack<string>uncond_jump;
vector<string> list_members;
map<int, string> declared_error;
int size(string type, string s){
  if(type=="int") {return sizeof(int);}
  if(type=="float") {return sizeof(float);}
  if(type=="str") {return s.size()*sizeof(char);}
  if(type=="bool") {return sizeof(bool);}
  return 0;}

int variable_declared=0;
stack<string> scope_stack;
void Entry(string type, string name, string scope, int line_number){
  //cout<<"Entry "<<name<<" "<<line_number<<" "<<current_local_symbol_table->scope<<endl;
  if(current_local_symbol_table->variables.find(name) != current_local_symbol_table->variables.end()){
    //cout << "Error: Variable " << name <<" at "<<line_number<< "already declared" << endl;
    // exit(EXIT_FAILURE);
    declared_error[line_number] = "Variable " + name + " at line " + to_string(line_number) + " already declared";
    }
  else{
  Variable* variable = new Variable();
  variable->type = type;
  variable->size = size(type, name);
  variable->line_number = line_number;
  variable->scope = scope;
  // if(name=="a") cout<<"Entry a->type: "<<variable->type<<endl;
  current_local_symbol_table->variables[name] = variable;}
  return;}

//   void create_csv(LocalSymbolTable* table){
//     for(auto it: table->children){
//     stringstream filenamestream;
//     filenamestream<<it.first<<".csv";
//     string filename = filenamestream.str();
//     ofstream outputfile(filename);
//     // cout<<it.first<<endl;
//     //Header
//     outputfile<<"Name,type,line_number"<<endl;
//     LocalSymbolTable* t = it.second;
//     for(auto a:t->children){
//         cout<<"is_function= "<<a.second->is_function<<endl;
//   if(a.second!=NULL)
//      create_csv(a.second);
//      else 
//      return ;}
//     cout<<"is_function= "<<t->is_function<<endl;
//     // cout<<"n2 ="<<t->variables.size()<<endl;
//     int ofset = 0;
//     for(auto it1: t->variables){
//     // cout<<it1.first<<endl;
//     // cout<<it1.second->type<<" "<<it1.second->size<<" "<<endl;
//     outputfile<<it1.first<<","<<it1.second->type<<","<<it1.second->size<<","<<it1.second->offset<<","<<it1.second->line_number<<","<<it.first<<endl;
// }
// outputfile.close();
// }
//   }
int Find_children(string name, LocalSymbolTable* temp){
  if(temp->children.find(name) != temp->children.end()){
    return 0;
  }
  for(auto it = temp->children.begin(); it!=temp->children.end(); ++it){
    return Find_children(name,it->second);}
    return 1;
  }
int Lookup(string name, string scope, int line_number, LocalSymbolTable* temp){
  //struct LocalSymbolTable* temp = current_local_symbol_table;
  LocalSymbolTable* a=temp;
  while(a != NULL){
    if(a->variables.find(name) != a->variables.end() && a->variables[name]->type != ""){
      return 1;
    }
    a = a->parent;
  }
  //cout<<"Lookup "<<name<<" "<<line_number<<endl;
  //cout << "Undeclared Variable " << name << " on line " << line_number << endl;
  if(Find_children(name, temp))
  scope_variable[line_number]=name;
  return 0;}
LocalSymbolTable* Lookup_table(string name, LocalSymbolTable* temp){
LocalSymbolTable* a=temp;
  while(a != NULL){
    if(a->variables.find(name) != a->variables.end() && a->variables[name]->type != ""){
      return a;
    }
    a = a->parent;}
return NULL;}
LocalSymbolTable* find_table(string name, LocalSymbolTable* temp){
    if(temp==NULL) return NULL;
    // if(temp->parent!=NULL&&temp->parent->children.find(name)!=temp->parent->children.end()){
    //   return temp->parent->children[name];
    // }
    if(temp->children.empty()) return NULL;
    if(temp->children.find(name)!=temp->children.end()){
      return temp->children[name];
    }
    for(auto it = temp->children.begin(); it!=temp->children.end(); ++it){
      if(!it->second->children.empty())
      return find_table(name,it->second);}
      return NULL;
    }
LocalSymbolTable* find_parent_table(string name, LocalSymbolTable* temp){
    if(temp==NULL) return NULL;
    temp = temp->parent;
    while(temp!=NULL){
    if(temp->children.find(name)!=temp->children.end()){
      return temp->children[name];}
      temp = temp->parent;
    }
    return NULL;}
int is_ancestor(LocalSymbolTable* a, LocalSymbolTable* b){
  if(a==NULL&&b!=NULL) return 0;
  while(b!=NULL){
    if(a==b) return 1;
    b=b->parent;}
  return 0;}
bool isInteger( string& str) {
    regex integerRegex("^[-+]?[0-9]+$");
    return regex_match(str, integerRegex);
}
bool isString(const string& input) {
    // Define a regular expression pattern to match strings enclosed within double quotes
    regex pattern("^\"[^\"]*\"$");

    // Check if the input matches the pattern
    return regex_match(input, pattern);
}
bool isFloatingPoint( string& str) {
    regex floatingPointRegex("^[-+]?[0-9]*\\.?[0-9]+([eE][-+]?[0-9]+)?$");
    return regex_match(str, floatingPointRegex);
}
bool isBool(string &str){
  if(str == "True" || str == "False"){
    return 1;
  }
  else 
  return 0;
}

string determineNumberType( string& str) {
  string s = "";
    if (isInteger(str)) {
        return "int";
    } else if (isFloatingPoint(str)) {
        return "float";
    } else if(isBool(str)){
return "bool";
    } else if(isString(str)){
        return "string";
    }
return s;
}
int type_correct(string str1, string str2){
  string a="",b="";
  if(str1.size()>=4) a=str1.substr(0,4);
  if(str2.size()>=4) b=str2.substr(0,4);
  if(a=="list") str1=str1.substr(4,str1.size());
  if(b=="list") str2=str2.substr(4,str2.size());
   if(str1==str2){
    return 1;}
   else if(str1=="int" && str2=="float"){
    return 1;
   }
   else if(str1=="float" && str2=="int"){
    return 1;
   }
   else if(str1=="int" && str2=="bool"){
    return 1;
   }
   else if(str1=="bool" && str2=="int"){
    return 1;
   }
   else 
   return 0;
}
char* stringToCharArray(string str) {
    // Allocate memory for char array (+1 for null terminator)
    char* charArray = new char[str.length() + 1];

    // Copy contents of string to char array
    strcpy(charArray, str.c_str());

    return charArray;
}
string charPtrToString(char* charArray) {
    // Use string constructor to convert char* to string
    string str(charArray);

    return str;
}
string concatenateWithCommas( vector<string> strings) {
    string result;
    for (size_t i = 0; i < strings.size(); ++i) {
        result += strings[i];
        if (i < strings.size() - 1) {
            result += ", ";
        }
    }
    return result;
}
    vector<string> types = {"int", "float", "string", "none","bool"};
typedef struct quadruple{
        string op;
        string arg1;
        string arg2;
        string res;
        int idx;
    } quad;
vector<quad> code;
vector<int> func_size;
long long counter = 0;
    long long counter1 = 0;
    long long temporaries=0;
    long long str_counter=0;
    vector<string> func_var;
    int self_offset=0;  

    void emit(string op, string arg1, string arg2, string res, int idx){
        quad temp;
        temp.op = op;
        temp.arg1 = arg1;
        temp.arg2 = arg2;
        temp.res = res;
        temp.idx = idx;
        if(idx == -1) temp.idx = code.size();
        code.push_back(temp);
    }

    string newtemp(){
      string temp_var = "t"+to_string(counter++);
      return temp_var;
    }
    string newLabel(){
      string temp_var = "L"+to_string(counter1++);
      return temp_var;
    }
    string newstr(){
      string str_var = "str"+to_string(str_counter++);
      return str_var;
    }
    unordered_map<string, string> str_map;
    vector<string> str_list;
    int func_offset = 0;
    unordered_map<string,int> func_offset_map;
    vector<string>x86_64_code;
    vector<int>array_elements;
    string only_if_label;
    // string x86;
    // x86=".text";
    // x86_64_code.push_back(x86);
    // x86=".globl main";
    // x86_64_code.push_back(x86);
    int get_offset(string a){
    // auto it=current_local_symbol_table->variables.find(a);
    // int pos, i, off=0;
    // if(it!=current_local_symbol_table->variables.end()){
    // pos=distance(current_local_symbol_table->variables.begin(),it);
    // if(pos<current_local_symbol_table->parameter_types.size()){
    // off=size(current_local_symbol_table->return_type,current_local_symbol_table->return_val);
    // for(i=0; i<=pos; i++){
    // auto b=current_local_symbol_table->variables.begin();
    // advance(b,i);
    // if(b->second->type.size()>=4&&b->second->type.substr(0,4)=="list") off+=b->second->size;
    // else off+=size(b->second->type,b->first);}
    // return off;}
    // // else{
    // // for(i=current_local_symbol_table->parameter_types.size(); i<=pos; i++){
    // // auto b=current_local_symbol_table->variables.begin();
    // // advance(b,i);
    // // if(b->second->type.size()>=4&&b->second->type.substr(0,4)=="list") off+=b->second->size;
    // // else off+=size(b->second->type,b->first);}
    // // return (-off);}
    // }
    return current_local_symbol_table->offsets[a];}
    // vector<string> regs={"%rax","%rbx","%rcx","%rdx","%rsi","%rdi","%r8","%r9","%r10","%r11","%r12","%r13","%r14","%r15"};
    vector<string> regs={"%r8","%r9","%r10","%r11","%r12","%r13","%r14","%r15"};

    vector<string>reg_par={"%rax","%rbx","%r10","%r11","%r12","%r13","%r14","%r15"};
    string init_reg;
    string getreg(string a){
    // int off;
    // vector<string> regs={"%rax","%rbx","%rcx","%rdx","%rsi","%rdi","%r8","%r9","%r10","%r11","%r12","%r13","%r14","%r15"};
    // for(auto i=current_local_symbol_table->register_descriptor.begin();i!=current_local_symbol_table->register_descriptor.end();++i){
    //   auto it=find(i->second.begin(),i->second.end(),a);
    //   if(it!=i->second.end()){
    //     return i->first;}}
    //   for(int i=0; i<regs.size(); i++){
    //   if(current_local_symbol_table->register_descriptor.find(regs[i])==current_local_symbol_table->register_descriptor.end()){
    //     current_local_symbol_table->register_descriptor[regs[i]].push_back(a);
    //     off=get_offset(a);
    //     string b="\tmovq "+to_string(off)+"(%rbp), "+regs[i];
    //     x86_64_code.push_back(b);
    //     return regs[i];}}
    //   int regs_index=current_local_symbol_table->regs_index;
    //   off=get_offset(current_local_symbol_table->register_descriptor[regs[(regs_index)%8]][0]);
    //   string b="\tmovq "+regs[(regs_index)%8]+", "+to_string(off)+"(%rbp)";
    //   current_local_symbol_table->register_descriptor[regs[(regs_index)%8]].push_back(a);
    //   x86_64_code.push_back(b);
    //   b="\tmovq "+to_string(get_offset(a))+"(%rbp), "+regs[(regs_index)%8];
    //   regs_index++;
    //   current_local_symbol_table->regs_index=regs_index;
    //   x86_64_code.push_back(b);
    //   return regs[(regs_index-1)%8];
    int regs_index=current_local_symbol_table->regs_index;
    string x86;
    if(a.size()>=4&&a.substr(0,4)=="self"){
    x86="\tmovq "+to_string(get_offset("self"))+"(%rbp), "+regs[(regs_index)%8];
    x86_64_code.push_back(x86);
    regs_index++;
    x86="\tmovq "+to_string(get_offset(a))+"(%"+regs[(regs_index-1)%8]+"), "+regs[(regs_index)%8];
    x86_64_code.push_back(x86);
    regs_index++;
    current_local_symbol_table->regs_index=regs_index;
    return regs[(regs_index-1)%8];}
    x86="\tmovq "+to_string(get_offset(a))+"(%rbp), "+regs[(regs_index)%8];
    x86_64_code.push_back(x86);
    regs_index++;
    current_local_symbol_table->regs_index=regs_index;
    return regs[(regs_index-1)%8];
    }
    string return_label = "";
    stack<string>return_labels;
    stack<string>break_labels;
    int is_break = 0;
    int is_return = 0;
    string break_label = "";
    stack<string> continue_label;
    int un_op = 0;
    void print_help_page(){
        // cout << "Usage: ./prob.o [options]     \n\n";
        cout << "Commands:\n-h, --help \t\t\t\t\t Show help page\n";
        cout << "-i, --input <input_file_name> \t\t\t Give input file\n";
        cout << "-o, --output <output_file_name>\t\t\t Redirect dot file to output file\n";
        cout << "-v, --verbose \t\t\t\t\t Outputs the entire derivation in command line\n";
        return;
    }
    string range1, range2;
    unordered_map<string,string> lex_string;
    stack<string> expr_lexeme; 
    stack<string> expr_second;
    
    vector<string>lex_list_members;
%}

%union {
    int intValue;
    char* strValue;
    struct {
    char* type;
    char* lexeme;
    char* tempvar;
    char* label;
    char* gotoname;
    char* op;
    char* second;
    int is_array;
    int is_class_dot;
    int is_number;
   } typ;
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
%type <typ> class_name class_start arg start eq whilee while_start iftestcol eliftestcol elif_suite elsecol forr for_start if_stmt1 or and v if_else_stmt1 if_else_stmt2 nam doublestar srt single_input file_input u eval_input operators simple_stmt B small_stmt o  compound_stmt optional_newline_or_stmt n_s stmt testlist optional_newline funcdef parameters a test b typedargslist tfpdef c optional_comma_tfpdef_c d j optional_semicolon_small_stmt expr_stmt flow_stmt global_stmt nonlocal_stmt assert_stmt NEW_NT A annassign augassign break_stmt continue_stmt return_stmt raise_stmt m n optional_comma_name while_stmt1 while_stmt2 for_stmt1 for_stmt2 classdef suite p stmts or_test and_test not_test comparison expr comp_op xor_expr optional_slash_xor_expr and_expr optional_power_and_expr optional_and_shift_expr shift_expr arith_expr optional_shift_operators_arith_expr shift_operators term optional_plus_minus_term plus_minus factor optional_operators_factor unary_operator power atom_expr atom optional_trailer trailer w x multi_string testlist_comp dictorsetmaker comp_for_sub NT y subscriptlist arglist subscript optional_comma_subscript sliceop exprlist optional_comma_expr optional_comma_test ran_out_of_names comp_for_optional_comma_r non_terminal optional_comma_r arg_list optional_comma_arguement argument
%%
start: srt {

};
srt: single_input  {
  
}
| file_input {
  
}
 | eval_input  {
  
};
single_input: NEWLINE {
   
  }
            | simple_stmt {
               
               }
            | compound_stmt NEWLINE {
              
            }
            ;
file_input: optional_newline_or_stmt ENDMARKER {
  
  }
    | ENDMARKER {
      
    }
          ;
// end_marker: end_marker ENDMARKER 
//           | ENDMARKER 
//           ;
optional_newline_or_stmt: optional_newline_or_stmt n_s {
  
}
| n_s{
  
   }
                        ;
n_s: NEWLINE {
    
}
  | stmt{
  } ;
eval_input: testlist optional_newline ENDMARKER {
  
}
|testlist ENDMARKER {
  
}
;          
optional_newline: NEWLINE {
  
  } 
                | optional_newline NEWLINE {
                  
                }
                ;
func: /*empty*/{

  string a;
  a="\tpushq %rbp";
  x86_64_code.push_back(a);
  a="\tmovq %rsp, %rbp";
  x86_64_code.push_back(a);
  int reg_index=current_local_symbol_table->regs_index;
  // a="\tsubq $16, %rsp";
  // x86_64_code.push_back(a);
  int it=0;
  int siz=0;
  if(current_local_symbol_table->parent!=NULL && current_local_symbol_table->parent->scope=="class"){
    cout<<"my parent is class"<<endl;
  siz=current_local_symbol_table->parent->size;

  a="\tmovq %rdi,"+regs[(reg_index)%8];
  x86_64_code.push_back(a);
  init_reg=regs[(reg_index)%8];
  reg_index++;
   if(it<current_local_symbol_table->parameter_types.size()){
  auto i=current_local_symbol_table->variables.begin();
  advance(i,it);
  siz=size(current_local_symbol_table->parameter_types[it],func_var[it]);
  if(siz<=8) siz=16;
  a="\tsubq $"+to_string(siz)+", %rsp";
  x86_64_code.push_back(a);
  current_local_symbol_table->curr_offset-=siz;
  a="\tmovq %rsi, "+to_string(current_local_symbol_table->curr_offset)+"(%rbp)";
  x86_64_code.push_back(a);
  it++;}
    if(it<current_local_symbol_table->parameter_types.size()){
  auto i=current_local_symbol_table->variables.begin();
  advance(i,it);
  siz=size(current_local_symbol_table->parameter_types[it],func_var[it]);
  if(siz<=8) siz=16;
  a="\tsubq $"+to_string(siz)+", %rsp";
  x86_64_code.push_back(a);
  current_local_symbol_table->curr_offset-=siz;
  //     a = "\tsubq $16, %rsp";
  // x86_64_code.push_back(a);
  a="\tmovq %rdx, "+to_string(current_local_symbol_table->curr_offset)+"(%rbp)";
  x86_64_code.push_back(a);
  it++;}
   if(it<current_local_symbol_table->parameter_types.size()){
  auto i=current_local_symbol_table->variables.begin();
  advance(i,it);
  siz=size(current_local_symbol_table->parameter_types[it],func_var[it]);
  if(siz<=8) siz=16;
  a="\tsubq $"+to_string(siz)+", %rsp";
  x86_64_code.push_back(a);
  current_local_symbol_table->curr_offset-=siz;
  a="\tmovq %rcx, "+to_string(current_local_symbol_table->curr_offset)+"(%rbp)";
  x86_64_code.push_back(a);
  it++;}
  if(it<current_local_symbol_table->parameter_types.size()){
  auto i=current_local_symbol_table->variables.begin();
  advance(i,it);
  siz=size(current_local_symbol_table->parameter_types[it],func_var[it]);
  if(siz<=8) siz=16;
  a="\tsubq $"+to_string(siz)+", %rsp";
  x86_64_code.push_back(a);
  current_local_symbol_table->curr_offset-=siz;
  //     a = "\tsubq $16, %rsp";
  // x86_64_code.push_back(a);
  a="\tmovq %r8, "+to_string(current_local_symbol_table->curr_offset)+"(%rbp)";
  x86_64_code.push_back(a);
  it++;}

  if(it<current_local_symbol_table->parameter_types.size()){
  auto i=current_local_symbol_table->variables.begin();
  advance(i,it);
  siz=size(current_local_symbol_table->parameter_types[it],func_var[it]);
  if(siz<=8) siz=16;
  a="\tsubq $"+to_string(siz)+", %rsp";
  x86_64_code.push_back(a);
  current_local_symbol_table->curr_offset-=siz;
  //     a = "\tsubq $16, %rsp";
  // x86_64_code.push_back(a);
  a="\tmovq %r9, "+to_string(current_local_symbol_table->curr_offset)+"(%rbp)";
  x86_64_code.push_back(a);
  it++;}
  int x;
  siz=0;
  int sz=0;
  reg_index=current_local_symbol_table->regs_index;
  string reg;
  for(x=it; x<current_local_symbol_table->parameter_types.size(); x++){
  reg=regs[(reg_index)%8];
  auto i=current_local_symbol_table->variables.begin();
  advance(i,x);
  sz=size(current_local_symbol_table->parameter_types[x],func_var[x]);
  if(sz%16!=0) sz=(sz/16+1)*16;
  siz+=sz;
  a="\tmovq "+to_string(siz)+"(%rbp), "+reg;
  x86_64_code.push_back(a);
  a="\tsubq $"+to_string(sz)+", %rsp";
  x86_64_code.push_back(a);
  current_local_symbol_table->curr_offset-=sz;
  a="\tmovq "+reg+", "+to_string(current_local_symbol_table->curr_offset)+"(%rbp)";
  x86_64_code.push_back(a);
  reg_index++;}
  current_local_symbol_table->regs_index=reg_index;
  }
  else{
   if(it<current_local_symbol_table->parameter_types.size()){
  auto i=current_local_symbol_table->variables.begin();
  advance(i,it);
  siz=size(current_local_symbol_table->parameter_types[it],func_var[it]);
  if(siz<=8) siz=16;
  a="\tsubq $"+to_string(siz)+", %rsp";
  x86_64_code.push_back(a);
  current_local_symbol_table->curr_offset-=siz;
  a="\tmovq %rdi, "+to_string(current_local_symbol_table->curr_offset)+"(%rbp)";
  x86_64_code.push_back(a);
  it++;}
  if(it<current_local_symbol_table->parameter_types.size()){
  auto i=current_local_symbol_table->variables.begin();
  advance(i,it);
  siz=size(current_local_symbol_table->parameter_types[it],func_var[it]);
  if(siz<=8) siz=16;
  a="\tsubq $"+to_string(siz)+", %rsp";
  x86_64_code.push_back(a);
  current_local_symbol_table->curr_offset-=siz;
  a="\tmovq %rsi, "+to_string(current_local_symbol_table->curr_offset)+"(%rbp)";
  x86_64_code.push_back(a);
  it++;}
  if(it<current_local_symbol_table->parameter_types.size()){
  auto i=current_local_symbol_table->variables.begin();
  advance(i,it);
  siz=size(current_local_symbol_table->parameter_types[it],func_var[it]);
  if(siz<=8) siz=16;
  a="\tsubq $"+to_string(siz)+", %rsp";
  x86_64_code.push_back(a);
  current_local_symbol_table->curr_offset-=siz;
  //     a = "\tsubq $16, %rsp";
  // x86_64_code.push_back(a);
  a="\tmovq %rdx, "+to_string(current_local_symbol_table->curr_offset)+"(%rbp)";
  x86_64_code.push_back(a);
  it++;}
  if(it<current_local_symbol_table->parameter_types.size()){
  auto i=current_local_symbol_table->variables.begin();
  advance(i,it);
  siz=size(current_local_symbol_table->parameter_types[it],func_var[it]);
  if(siz<=8) siz=16;
  a="\tsubq $"+to_string(siz)+", %rsp";
  x86_64_code.push_back(a);
  current_local_symbol_table->curr_offset-=siz;
  a="\tmovq %rcx, "+to_string(current_local_symbol_table->curr_offset)+"(%rbp)";
  x86_64_code.push_back(a);
  it++;}
  if(it<current_local_symbol_table->parameter_types.size()){
  auto i=current_local_symbol_table->variables.begin();
  advance(i,it);
  siz=size(current_local_symbol_table->parameter_types[it],func_var[it]);
  if(siz<=8) siz=16;
  a="\tsubq $"+to_string(siz)+", %rsp";
  x86_64_code.push_back(a);
  current_local_symbol_table->curr_offset-=siz;
  //     a = "\tsubq $16, %rsp";
  // x86_64_code.push_back(a);
  a="\tmovq %r8, "+to_string(current_local_symbol_table->curr_offset)+"(%rbp)";
  x86_64_code.push_back(a);
  it++;}
  if(it<current_local_symbol_table->parameter_types.size()){
  auto i=current_local_symbol_table->variables.begin();
  advance(i,it);
  siz=size(current_local_symbol_table->parameter_types[it],func_var[it]);
  if(siz<=8) siz=16;
  a="\tsubq $"+to_string(siz)+", %rsp";
  x86_64_code.push_back(a);
  current_local_symbol_table->curr_offset-=siz;
  //     a = "\tsubq $16, %rsp";
  // x86_64_code.push_back(a);
  a="\tmovq %r9, "+to_string(current_local_symbol_table->curr_offset)+"(%rbp)";
  x86_64_code.push_back(a);
  it++;}
  int x;
  siz=0;
  int sz=0;
  reg_index=current_local_symbol_table->regs_index;
  string reg;
  for(x=it; x<current_local_symbol_table->parameter_types.size(); x++){
  reg=regs[(reg_index)%8];
  auto i=current_local_symbol_table->variables.begin();
  advance(i,x);
  sz=size(current_local_symbol_table->parameter_types[x],func_var[x]);
  if(sz%16!=0) sz=(sz/16+1)*16;
  siz+=sz;
  a="\tmovq "+to_string(siz)+"(%rbp), "+reg;
  x86_64_code.push_back(a);
  a="\tsubq $"+to_string(sz)+", %rsp";
  x86_64_code.push_back(a);
  current_local_symbol_table->curr_offset-=sz;
  a="\tmovq "+reg+", "+to_string(current_local_symbol_table->curr_offset)+"(%rbp)";
  x86_64_code.push_back(a);
  reg_index++;}
  current_local_symbol_table->regs_index=reg_index;
}
};

funcdef: func_start parameters a COLON func suite {
  if(func_name=="__init__"){
    current_local_symbol_table->parent->size = class_offset;
    cout<<"class_offset "<<class_offset<<" "<<yylineno<<endl;
  }
    if(func_name!="__init__"){
        // cout<<"not here"<<endl;
  all_tables.push_back({func_name,current_local_symbol_table});}
  if(current_local_symbol_table->parent!=NULL && current_local_symbol_table->parent->scope=="class"&&current_local_symbol_table->parent->children["__init__"]==current_local_symbol_table){
    for(auto a=current_local_symbol_table->variables.begin();a!=current_local_symbol_table->variables.end();++a){
      current_local_symbol_table->parent->variables[a->first]=a->second;
    }
  }
  LocalSymbolTable* temp=current_local_symbol_table;
  current_local_symbol_table=current_local_symbol_table->parent;
  current_scope=current_local_symbol_table->scope;
  stack<string>().swap(scope_stack);
  // cout<<"funcdef start"<<endl;
  
  
  int siz=0;
  int a=temp->variables.size()-temp->parameter_types.size();
  int j;
  auto i=temp->variables.begin();
  for(j=0; j<a; j++){
  if(variables.find(i->first)==variables.end()){
  // cout<<"i->first "<<i->first<<" "<<i->second->type<<" "<<size(i->second->type,i->first)<<endl;
   if(i->second->type.size()>=4&&i->second->type.substr(0,4)=="list") siz+=i->second->size;
   else siz+=size(i->second->type,i->first); }
   advance(i,1);}
  //  cout<<"counter "<<counter<<" temporaries "<<temporaries<<endl;
   siz+=(counter-temporaries)*8;
  func_size.push_back(siz);
  ////////////////3AC//////////////////
  while(is_return && !return_labels.empty()){
    string a = return_labels.top();
    emit(a,":","","",-1);
    // emit("end_func","","","",-1);
    // return_label = "";
    return_labels.pop();
  }
  is_return = 0;
emit("\treturn","","","",-1);
  emit("end_func","","","",-1);
  //  if(current_local_symbol_table->scope =="class"){
  //   // int n=func_names.size();
      
  //   string vtable = "vtable";
  //   string space = " ";
  //   string res = vtable + space;
  //   string res1 = res + class_nam;
  //   string functions = concatenateWithCommas(func_names);
  //   int n = func_names.size();
  //   // cout<<"vtable1"<<n<<endl;
  //       emit("=",functions,"",res1,-1);
  // }
  func_name="";
  // func_names.clear();
  string x86;
  x86="\tleave";
  x86_64_code.push_back(x86);
  x86="\tret";
  x86_64_code.push_back(x86);
  self_offset=0;
}
|func_start parameters COLON func suite {
  if(func_name=="__init__"){
    current_local_symbol_table->parent->size = class_offset;
    cout<<"class_offset "<<class_offset<<" "<<yylineno<<endl; 
  }
    if(func_name!="__init__"){
        // cout<<"not_here1"<<func_name<<endl;
    all_tables.push_back({func_name,current_local_symbol_table});}
if(current_local_symbol_table->parent!=NULL && current_local_symbol_table->parent->scope=="class"&&current_local_symbol_table->parent->children["__init__"]==current_local_symbol_table){
for(auto a=current_local_symbol_table->variables.begin();a!=current_local_symbol_table->variables.end();++a){
current_local_symbol_table->parent->variables[a->first]=a->second;}}
LocalSymbolTable* temp=current_local_symbol_table;
current_local_symbol_table=current_local_symbol_table->parent;
current_scope=current_local_symbol_table->scope;
stack<string>().swap(scope_stack);
func_name="";
current_local_symbol_table->return_type="None";
// for(const auto& a: scope_variable){
// if(current_local_symbol_table->variables[a.second]->type==""&&variables.find(a.second)==variables.end()){
// //cout << "Undeclared Variable " << a.second << " on line " << a.first << endl;
// //exit(EXIT_FAILURE);
// }}
// scope_variable.clear();
  
int siz=0;
  int a=temp->variables.size()-temp->parameter_types.size();
  int j;
  auto i=temp->variables.begin();
  for(j=0; j<a; j++){
  if(variables.find(i->first)==variables.end()){
  // cout<<"i->first "<<i->first<<" "<<i->second->type<<" "<<size(i->second->type,i->first)<<endl;
  if(i->second->type.size()>=4&&i->second->type.substr(0,4)=="list") siz+=i->second->size;
   else siz+=size(i->second->type,i->first); }
   advance(i,1);}
  //  cout<<"counter "<<counter<<" temporaries "<<temporaries<<endl;
   siz+=(counter-temporaries)*8;
  func_size.push_back(siz);
  //////////////3AC////////////////////
  while(is_return && !return_labels.empty()){
    string a = return_labels.top();
    emit(a,":","","",-1);
    return_labels.pop();
  }
  is_return = 0;
  emit("\treturn","","","",-1);
  emit("end_func","","","",-1);
  // if(current_local_symbol_table->scope =="class"){
  //   // int n=func_names.size();
      
  //   string vtable = "vtable";
  //   string space = " ";
  //   string res = vtable + space;
  //   string res1 = res + class_nam;
  //   string functions = concatenateWithCommas(func_names);
  //   int n = func_names.size();
  //   // cout<<"vtable1"<<n<<endl;
  //       emit("=",functions,"",res1,-1);
  // }
  func_name="";
  // func_names.clear();
  string x86;
  x86="\tleave";
  x86_64_code.push_back(x86);
  x86="\tret";
  x86_64_code.push_back(x86);
  self_offset=0;
}
  ;
func_start: DEF NAME {
 LocalSymbolTable* temp = new LocalSymbolTable(variable,address_descriptor,register_descriptor,offsets,0,0, "", "", parameter_types, "", yylineno, 0,"function", current_local_symbol_table, children);
  temp->line_number = yylineno;
  temp->scope="function";
  func_name=charPtrToString($2);
  if(current_local_symbol_table->scope=="class"){
      string func1;
      string func = class_nam + ".";
      func1 = func + charPtrToString($2);
      func_names.push_back(func1);
  }
  else
  func_names.push_back(func_name);
  temp->parent = current_local_symbol_table;
  temp->is_function = 1;
  current_local_symbol_table->children[$2] = temp;
  tables.push(current_local_symbol_table);
  current_local_symbol_table = temp;
  emit($2,":","","",-1);
  emit("begin_func","","","",-1);
  temporaries=counter;
  string x86;
  if(current_local_symbol_table->parent!=NULL && current_local_symbol_table->parent->scope=="class"){
    x86=class_nam+"."+charPtrToString($2)+":";
    x86_64_code.push_back(x86);}
  else{
    x86=charPtrToString($2)+":";
    x86_64_code.push_back(x86);
  }
};
a: ARROW test   {
  current_local_symbol_table->return_type=($2).type;
}
;
lparen: LPAREN{
  is_func_param=1;
};
parameters: lparen b RPAREN  {
  // cout<<"parameters "<<yylineno<<endl;
  is_dot="";
  is_func_param=0;
};
// add_child($$,b);}; 
b: typedargslist { 
  }
    | /* empty */ { 
      };
typedargslist: tfpdef c optional_comma_tfpdef_c d { 
  // if(($1).type!=NULL)
  // cout<<"typedargslist start "<<yylineno<<" "<<($1).type<<endl;
  if(func_name=="__init__"){
    if(variables.find(($1).lexeme)==variables.end())
    current_local_symbol_table->parameter_types.insert(current_local_symbol_table->parameter_types.begin(),($1).type);
  }
  else if(variables.find(($1).lexeme)==variables.end()){
    current_local_symbol_table->parameter_types.insert(current_local_symbol_table->parameter_types.begin(),($1).type);}
    func_offset=0;
    if(current_local_symbol_table->parent!=NULL && current_local_symbol_table->parent->scope=="class"){
    func_offset+=current_local_symbol_table->parent->size;}
    else{
    if(size(($1).type,($1).lexeme)<=8) func_offset+=16;
    else func_offset+=size(($1).type,($1).lexeme); 
    }
    //current_local_symbol_table->curr_offset-=func_offset;
  current_local_symbol_table->offsets[(($1).lexeme)]=-func_offset;
  //cout<<"current_local_symbol_table->curr_offset "<<current_local_symbol_table->curr_offset<<endl;
  func_var.insert(func_var.begin(),charPtrToString(($1).lexeme));
  for(auto i=func_offset_map.begin();i!=func_offset_map.end();++i){
    func_offset_map[i->first]+=func_offset;
    current_local_symbol_table->offsets[i->first]=-func_offset_map[i->first];}
    func_offset_map.clear();
  func_offset=0;
}
  // | STAR f optional_comma_tfpdef_c g 
  // | DOUBLESTAR tfpdef i 
  ;
optional_comma_tfpdef_c: /*empty*/ {}
                      | optional_comma_tfpdef_c COMMA tfpdef c {
                      current_local_symbol_table->parameter_types.push_back(($3).type);
                      // cout<<"optional_comma_tfpdef_c "<<yylineno<<endl;
                      if(($4).type!=""&&!type_correct(($3).type,($4).type)){
                        type_errors[type_error_line]="Type mismatch in function parameter "+charPtrToString(($3).lexeme)+" on line "+to_string(type_error_line);
                      }
                      if(size(($3).type,($3).lexeme)<=8) {func_offset+=16;
                      //current_local_symbol_table->curr_offset-=16;
                      }
                      else {func_offset+=size(($3).type,($3).lexeme);}
                      //current_local_symbol_table->curr_offset-=size(($3).type,($3).lexeme);}
                      func_offset_map[charPtrToString(($3).lexeme)]=func_offset;
                      func_var.push_back(charPtrToString(($3).lexeme));
                      }
    
                      ;

c: eq test {
  is_equal=0;
  $$.lexeme = ($2).lexeme;
  $$.type = ($2).type;
  $$.tempvar = ($2).tempvar;
  $$.op = ($1).lexeme;
}
    | /* empty */{
      $$.type="";
      $$.lexeme = NULL;
      $$.tempvar = NULL;
      $$.op = NULL;
      //cout<<"c "<<yylineno<<endl;
      };
d: COMMA {
//cout<<"d "<<yylineno<<endl;
}
  | /* empty */{
    //cout<<"d "<<yylineno<<endl;
    };
tfpdef: nam j {
  $$.type=($2).type;
  $$.lexeme=($1).lexeme;
  //cout<<"tfpdef "<<yylineno<<endl;
  type_error_line=yylineno;
};
j: col test{
  $$.type=($2).type;
  //cout<<"j1 "<<($2).type<<" "<<yylineno<<endl;
}
    | /* empty */{ 
      };
nam: NAME{
$$.lexeme = $1;
if(current_local_symbol_table->variables.find($1) == current_local_symbol_table->variables.end()){
        //cout<<"current_local_symbol_table->scope: 1 "<<current_local_symbol_table->scope<<endl;
        current_variable=$1;
        current_line=yylineno;
        Entry("", current_variable, current_scope, current_line);
        if(!Lookup($1,current_scope,yylineno, current_local_symbol_table)) scope_variable[current_line]=current_variable;
        //cout<<"atom else if current_variable: "<<$1<<" "<<yylineno<<endl;
        scope_stack.push($1);
        }
        else{
          //cout<<"atom else current_variable: "<<$1<<" "<<yylineno<<endl;
          // current_variable=$1;
          // current_line=yylineno;
          redeclared_line=yylineno;
          if(variables.find($1) == variables.end()){
          is_lookup=Lookup($1, current_scope, yylineno, current_local_symbol_table);}
          if(is_lookup==0&&current_local_symbol_table->variables.find($1)!=current_local_symbol_table->variables.end()&&current_local_symbol_table->variables[$1]->type == ""){
          if(variables.find($1) == variables.end()&&current_local_symbol_table->children.find($1)==current_local_symbol_table->children.end()){
          //cout<<"else ";
          scope_variable[yylineno]=$1;}}
          scope_stack.push($1);
        }
//else Lookup($1, current_scope, yylineno, current_local_symbol_table);
};
stmt: simple_stmt {
  
  }
| compound_stmt {
  
   };

simple_stmt: small_stmt optional_semicolon_small_stmt SEMI NEWLINE {
  
}
          | small_stmt optional_semicolon_small_stmt NEWLINE {
            
          }
          | small_stmt SEMI NEWLINE {
            
          }
          | small_stmt NEWLINE {
            
          }
          ;
optional_semicolon_small_stmt: optional_semicolon_small_stmt SEMI small_stmt{

}

| SEMI small_stmt{
  
}
;
// k: SEMI 
//   | /* empty */;
small_stmt: expr_stmt {

}
            | flow_stmt {
              
            }
            | global_stmt {
              
 }
            | nonlocal_stmt {
              
             }
            | assert_stmt {
              
}
            ;

expr_stmt: NEW_NT A {
  cout<<"expr_stmt1 "<<yylineno<<init_reg<<($2).lexeme<<endl;
  if(($2).type!=""){
    cout<<"expr_stmt0"<<endl;
    if(($2).type=="str") {
    type_errors[type_error_line]="Mutable operation on string on line "+to_string(type_error_line)+" not allowed";}
    else if(!type_correct(($1).type,($2).type) && ($2).type != NULL ){
      type_errors[type_error_line]="Type mismatch in assignment on line "+to_string(type_error_line);
    }
  }
  else{
    cout<<"expr_stmt2 "<<yylineno<<endl;
    if(current_local_symbol_table->variables.find(charPtrToString(($1).lexeme))!=current_local_symbol_table->variables.end())
    current_local_symbol_table->variables[charPtrToString(($1).lexeme)]->size=arr_size;
    cout<<"after"<<endl;
    arr_size=0;
  }
  if(($2).type == ""){
    /// storing strings and variable for len function
    lex_string[charPtrToString(($1).lexeme)] = charPtrToString(($2).lexeme);

  }


////////////////////////3AC//////////////////////////
  //cout<<"expr_stmt6 "<<yylineno<<endl;

    if(($2).lexeme == NULL){
      // DO NOTHING
      cout<<"expr_stmt3 "<<yylineno<<endl;

    }
    else{
      cout<<"expr_stmt4 "<<yylineno<<endl;
      $$.op = ($2).op;
      string lex1 = ($1).lexeme;
    int sz;
    if(lex1.size()>=4 && lex1.substr(0,4)=="self")
    {
      cout<<"sellllllllffff1"<<($1).lexeme<<current_type<<endl;
    
      sz = size(current_type,($2).lexeme);
      class_offset += 16;
    }
      string op = charPtrToString(($2).op);
      cout<<"OPERATTTTTTOOOOOORRRRR "<<op<<endl;
    if(op=="=")
    {
      if(lex1.size()>=4&&lex1.substr(0,4)=="self"){
        string s1= "*";
        cout<<"sellllllllffff2"<<($1).lexeme<<current_type<<endl;
    char* st = stringToCharArray(s1);
    strcat(st,"(");
    strcat(st,"self");
    strcat(st,"+");
    strcat(st,stringToCharArray(to_string(class_offset)));
    strcat(st,")");
    emit(op,charPtrToString(($2).lexeme),"",st,-1);
    if(func_name=="__init__"){
      cout<<"sellllllllffff3"<<($1).lexeme<<current_type<<endl;
      cout<<"init_register"<<init_reg<<endl;
    if(($1).tempvar == NULL && ($2).tempvar == NULL){
    int regs_index=current_local_symbol_table->regs_index;
      // reg1=regs[regs_index%8];
      // x86="\tmovq "+to_string(get_offset("self"))+"(%rbp), "+reg1;
      // x86_64_code.push_back(x86);
      // regs_index++;
      cout<<"if init"<<endl;
      string x86;
      string registerr=regs[regs_index%8];
      cout<<"init_register1"<<registerr<<endl;
      regs_index++;
      if(strcmp(stringToCharArray(registerr),stringToCharArray(init_reg))==0){
        registerr = regs[regs_index%8]; 
        regs_index++;
      }
      x86="\tmovq "+to_string(get_offset(charPtrToString(($2).lexeme)))+"(%rbp), "+registerr;
      x86_64_code.push_back(x86);
      x86="\tmovq "+registerr+", "+to_string(self_offset)+"("+init_reg+")";
      x86_64_code.push_back(x86);
      current_local_symbol_table->offsets[($1).lexeme]= self_offset;
      current_local_symbol_table->parent->offsets[($1).lexeme] = self_offset;
      cout<<($1).lexeme<<current_local_symbol_table->scope<<func_name<<endl;
      int sze;
      int len = charPtrToString(($1).lexeme).size();
      string var = charPtrToString(($1).lexeme).substr(5,len);
      cout<<"var1==="<<var<<endl;
      if(current_local_symbol_table->variables.find(var)!=current_local_symbol_table->variables.end()){
      sze = size(current_local_symbol_table->variables[var]->type,var);
      if(sze%16!=0) sze=(sze/16+1)*16;
      self_offset+=sze;}}
      else if(($2).tempvar == NULL){
      cout<<"else if 2 init"<<endl;
      int regs_index=current_local_symbol_table->regs_index;
    // reg1=regs[regs_index%8];
    //   x86="\tmovq "+to_string(get_offset("self"))+"(%rbp), "+reg1;
    //   x86_64_code.push_back(x86);
    //   regs_index++;
      string registerr=regs[regs_index%8];
         cout<<"init_register1"<<registerr<<endl;
      regs_index++;
    if(strcmp(stringToCharArray(registerr),stringToCharArray(init_reg))==0){
      registerr = regs[regs_index%8];
      regs_index++;}
      string x86;
      x86="\tmovq "+to_string(get_offset(charPtrToString(($2).lexeme)))+"(%rbp), "+registerr;
      x86_64_code.push_back(x86);
      x86="\tmovq "+registerr+", "+to_string(self_offset)+"("+init_reg+")";
      x86_64_code.push_back(x86);
      current_local_symbol_table->offsets[($1).lexeme]= self_offset;
      current_local_symbol_table->parent->offsets[($1).lexeme] = self_offset;
     int sze;
      int len = charPtrToString(($1).lexeme).size();
      string var = charPtrToString(($1).lexeme).substr(5,len);
      cout<<"var1==="<<var<<endl;
      if(current_local_symbol_table->variables.find(var)!=current_local_symbol_table->variables.end()){
      sze = size(current_local_symbol_table->variables[var]->type,var);
      if(sze%16!=0) sze=(sze/16+1)*16;
      self_offset+=sze;}}
    else if(($1).tempvar == NULL){
      cout<<"else if init"<<endl;
     string reg1=getreg(($2).tempvar);
    // string regi=regs[regs_index%8];
    //   x86="\tmovq "+to_string(get_offset("self"))+"(%rbp), "+regi;
    //   x86_64_code.push_back(x86);
    //   regs_index++;
    int regs_index=current_local_symbol_table->regs_index;
    string x86;
      string registerr=regs[regs_index%8];
         cout<<"init_register1"<<registerr<<endl;
      regs_index++;
     if(strcmp(stringToCharArray(registerr),stringToCharArray(init_reg))==0){
      registerr = regs[regs_index%8];
      
      regs_index++;}
      x86="\tmovq "+reg1+", "+registerr;
      x86_64_code.push_back(x86);
      x86="\tmovq "+registerr+", "+to_string(self_offset)+"("+init_reg+")";
      x86_64_code.push_back(x86);
      current_local_symbol_table->offsets[($1).lexeme]= self_offset;
      current_local_symbol_table->parent->offsets[($1).lexeme] = self_offset;
      int sze;
      int len = charPtrToString(($1).lexeme).size();
      string var = charPtrToString(($1).lexeme).substr(5,len);
      cout<<"var1==="<<var<<endl;
      if(current_local_symbol_table->variables.find(var)!=current_local_symbol_table->variables.end()){
      sze = size(current_local_symbol_table->variables[var]->type,($1).lexeme);
      if(sze%16!=0) sze=(sze/16+1)*16;
      self_offset+=sze;}}
    else{
      cout<<"else init"<<endl;
      string reg1=getreg(($2).tempvar);
    //string regi=regs[regs_index%8];
      // x86="\tmovq "+to_string(get_offset("self"))+"(%rbp), "+regi;
      // x86_64_code.push_back(x86);
      // regs_index++;
      int regs_index=current_local_symbol_table->regs_index;
      string x86;
      string registerr=regs[regs_index%8];
           cout<<"init_register1"<<registerr<<endl;
      regs_index++;
      if(strcmp(stringToCharArray(registerr),stringToCharArray(init_reg))==0){
      registerr = regs[regs_index%8];
      
      regs_index++;}
      x86="\tmovq "+reg1+", "+registerr;
      x86_64_code.push_back(x86);
      x86="\tmovq "+registerr+", "+to_string(self_offset)+"("+init_reg+")";
      x86_64_code.push_back(x86);
      current_local_symbol_table->offsets[($1).lexeme]= self_offset;
      current_local_symbol_table->parent->offsets[($1).lexeme] = self_offset;
     int sze;
      int len = charPtrToString(($1).lexeme).size();
      string var = charPtrToString(($1).lexeme).substr(5,len);
      cout<<"var1==="<<var<<endl;
      if(current_local_symbol_table->variables.find(var)!=current_local_symbol_table->variables.end()){
      sze = size(current_local_symbol_table->variables[var]->type,($1).lexeme);
      if(sze%16!=0) sze=(sze/16+1)*16;
      self_offset+=sze;}}
    cout<<"init "<<yylineno<<endl;
    }
    else{
    if(($1).tempvar == NULL && ($2).tempvar == NULL){
    int regs_index=current_local_symbol_table->regs_index;
    string reg1;
      reg1=regs[regs_index%8];
      string x86;
      x86="\tmovq "+to_string(get_offset("self"))+"(%rbp), "+reg1;
      x86_64_code.push_back(x86);
      regs_index++;
    
      string registerr = regs[regs_index%8];
      
      regs_index++;
      x86="\tmovq "+to_string(get_offset(charPtrToString(($2).lexeme)))+"(%rbp), "+registerr;
      x86_64_code.push_back(x86);
      x86="\tmovq "+registerr+", "+to_string(self_offset)+"("+reg1+")";
      x86_64_code.push_back(x86);
      current_local_symbol_table->offsets[($1).lexeme]= self_offset;
     int sze;
      int len = charPtrToString(($1).lexeme).size();
      string var = charPtrToString(($1).lexeme).substr(5,len);
      cout<<"var1==="<<var<<endl;
      if(current_local_symbol_table->variables.find(var)!=current_local_symbol_table->variables.end()){
      sze = size(current_local_symbol_table->variables[var]->type,($1).lexeme);
      if(sze%16!=0) sze=(sze/16+1)*16;
      self_offset+=sze;}}
    else if(($2).tempvar == NULL){
      int regs_index=current_local_symbol_table->regs_index;
      string reg1, x86;
      reg1=regs[regs_index%8];
      x86="\tmovq "+to_string(get_offset("self"))+"(%rbp), "+reg1;
      x86_64_code.push_back(x86);
      regs_index++;
      string registerr=regs[regs_index%8];
    
      regs_index++;
      x86="\tmovq "+to_string(get_offset(charPtrToString(($2).lexeme)))+"(%rbp), "+registerr;
      x86_64_code.push_back(x86);
      x86="\tmovq "+registerr+", "+to_string(self_offset)+"("+reg1+")";
      x86_64_code.push_back(x86);
      current_local_symbol_table->offsets[($1).lexeme]= self_offset;
   int sze;
      int len = charPtrToString(($1).lexeme).size();
      string var = charPtrToString(($1).lexeme).substr(5,len);
      cout<<"var1==="<<var<<endl;
      if(current_local_symbol_table->variables.find(var)!=current_local_symbol_table->variables.end()){
      sze = size(current_local_symbol_table->variables[var]->type,($1).lexeme);
      if(sze%16!=0) sze=(sze/16+1)*16;
      self_offset+=sze;}}
    else if(($1).tempvar == NULL){
      int regs_index=current_local_symbol_table->regs_index;
      string x86;
      string reg1=getreg(($2).tempvar);
    string regi=regs[regs_index%8];
      x86="\tmovq "+to_string(get_offset("self"))+"(%rbp), "+regi;
      x86_64_code.push_back(x86);
      regs_index++;
      string registerr=regs[regs_index%8];
     
      
      regs_index++;
      x86="\tmovq "+reg1+", "+registerr;
      x86_64_code.push_back(x86);
      x86="\tmovq "+registerr+", "+to_string(self_offset)+"("+regi+")";
      x86_64_code.push_back(x86);
      current_local_symbol_table->offsets[($1).lexeme]= self_offset;
      int sze;
      int len = charPtrToString(($1).lexeme).size();
      string var = charPtrToString(($1).lexeme).substr(5,len);
      cout<<"var1==="<<var<<endl;
      if(current_local_symbol_table->variables.find(var)!=current_local_symbol_table->variables.end()){
      sze = size(current_local_symbol_table->variables[var]->type,($1).lexeme);
      if(sze%16!=0) sze=(sze/16+1)*16;
      self_offset+=sze;}}
    else{
      int regs_index=current_local_symbol_table->regs_index;
    string regi=regs[regs_index%8];
    string reg1=getreg(($2).tempvar);
    string x86;
      x86="\tmovq "+to_string(get_offset("self"))+"(%rbp), "+regi;
      x86_64_code.push_back(x86);
      regs_index++;
      string registerr=regs[regs_index%8];
      
    
      
      regs_index++;
      x86="\tmovq "+reg1+", "+registerr;
      x86_64_code.push_back(x86);
      x86="\tmovq "+registerr+", "+to_string(self_offset)+"("+regi+")";
      x86_64_code.push_back(x86);
      current_local_symbol_table->offsets[($1).lexeme]= self_offset;
     int sze;
      int len = charPtrToString(($1).lexeme).size();
      string var = charPtrToString(($1).lexeme).substr(5,len);
      cout<<"var1==="<<var<<endl;
      if(current_local_symbol_table->variables.find(var)!=current_local_symbol_table->variables.end()){
      sze = size(current_local_symbol_table->variables[var]->type,($1).lexeme);
      if(sze%16!=0) sze=(sze/16+1)*16;
      self_offset+=sze;}}
    }

      }
     else {
      string x86;
      //cout<<"NEW_NT"<<endl;
      string reg1, reg2, str_1, str_2, var;
      int siz=0;
      string typ=current_local_symbol_table->variables[($1).lexeme]->type;
      if(($1).tempvar == NULL && ($2).tempvar == NULL){
      cout<<"here1 new nt"<<yylineno<<endl;
      emit(op,charPtrToString(($2).lexeme),"",charPtrToString(($1).lexeme),-1);
      //reg1=getreg(($2).lexeme);
      if(typ.size()>=4&&typ.substr(0,4)=="list"){
      }
      else{
      str_1 = charPtrToString(($1).lexeme);
      LocalSymbolTable* table=find_table(charPtrToString(($2).type),global_table);
      siz=16;
      if(siz%16!=0) siz=(siz/16+1)*16;

      if(siz<=8) {x86="\tsubq $16, %rsp";
      siz=16;}
      else
      x86="\tsubq $"+to_string(siz)+", %rsp";
      x86_64_code.push_back(x86);

      current_local_symbol_table->curr_offset-=siz;
      current_local_symbol_table->offsets[str_1]=current_local_symbol_table->curr_offset;
      int regs_index=current_local_symbol_table->regs_index;
      reg1=regs[regs_index%8];
      
      x86="\tmovq "+to_string(get_offset(charPtrToString(($2).lexeme)))+"(%rbp), "+reg1;
      x86_64_code.push_back(x86);
      //reg2=getreg(str_1);
      x86="\tmovq "+reg1+", "+to_string(current_local_symbol_table->curr_offset)+"(%rbp)";
      x86_64_code.push_back(x86);
      regs_index++;
      }
      //cout<<"NEW_NT1"<<endl;
    }else if(($2).tempvar == NULL){
      cout<<"here2 new nt"<<yylineno<<endl;
      //cout<<"here2"<<endl;
      emit(op,charPtrToString(($2).lexeme),"",charPtrToString(($1).tempvar),-1);
      //reg1=getreg(($2).lexeme);
      // str_1 = charPtrToString(($1).tempvar);
      // siz=size(($2).type,($2).lexeme);
      // x86="\tsubq $"+to_string(siz)+", %rsp";
      // x86_64_code.push_back(x86);
      // current_local_symbol_table->curr_offset-=siz;
      // current_local_symbol_table->offsets[str_1]=current_local_symbol_table->curr_offset;
      if(typ.size()>=4&&typ.substr(0,4)=="list"){
      }
      else{
      // if(charPtrToString(($1).lexeme).substr(0,5)=="self."){
      // reg1=regs[regs_index%8];
      // x86="\tmovq "+to_string(get_offset("self"))+"(%rbp), "+reg1;
      // x86_64_code.push_back(x86);
      // regs_index++;
      // string registerr=regs[regs_index%8];
      // regs_index++;
      // x86="\tmovq "+to_string(get_offset(charPtrToString(($2).lexeme)))+"(%rbp), "+registerr;
      // x86_64_code.push_back(x86);
      // x86="\tmovq "+registerr+", "+to_string(self_offset)+"("+reg1+")";
      // x86_64_code.push_back(x86);
      // current_local_symbol_table->offsets[($1).lexeme]= self_offset;
      // self_offset+=size(current_local_symbol_table->variables[($1).lexeme]->type,($1).lexeme);}
      // else{
      siz=get_offset(($1).tempvar);
      //reg2=getreg(str_1);
      x86="\tmovq $"+charPtrToString(($2).lexeme)+", "+to_string(siz)+"(%rbp)";
      x86_64_code.push_back(x86);}
      //cout<<"NEW_NT2"<<endl;
    }else if(($1).tempvar == NULL){
      //cout<<"here3"<<endl;
      cout<<"here3 new nt"<<yylineno<<endl;
      emit(op,charPtrToString(($2).tempvar),"",charPtrToString(($1).lexeme),-1);
      if(typ.size()>=4&&typ.substr(0,4)=="list"){
      }
      else{
      reg1=getreg(($2).tempvar);
      str_1 = charPtrToString(($1).lexeme);
      // LocalSymbolTable* table=find_table(charPtrToString(($2).type),global_table);
      // if(table!=NULL&&table->scope=="class"){
      // siz=table->size;}
      // else 
      siz=16;
      cout<<"siz "<<siz<<" "<<yylineno<<endl;
      if(siz%16!=0) siz=(siz/16+1)*16;
      // if(charPtrToString(($1).lexeme).substr(0,5)=="self."){
      // string regi=regs[regs_index%8];
      // x86="\tmovq "+to_string(get_offset("self"))+"(%rbp), "+regi;
      // x86_64_code.push_back(x86);
      // regs_index++;
      // string registerr=regs[regs_index%8];
      // regs_index++;
      // x86="\tmovq "+reg1+", "+registerr;
      // x86_64_code.push_back(x86);
      // x86="\tmovq "+registerr+", "+to_string(self_offset)+"("+regi+")";
      // x86_64_code.push_back(x86);
      // current_local_symbol_table->offsets[($1).lexeme]= self_offset;
      // self_offset+=size(current_local_symbol_table->variables[($1).lexeme]->type,($1).lexeme);}
      // else{
      x86="\tsubq $"+to_string(siz)+", %rsp";
      x86_64_code.push_back(x86);
      current_local_symbol_table->curr_offset-=siz;
      current_local_symbol_table->offsets[str_1]=current_local_symbol_table->curr_offset;
      //reg2=getreg(str_1);
      x86="\tmovq "+reg1+", "+to_string(current_local_symbol_table->curr_offset)+"(%rbp)";
      x86_64_code.push_back(x86);
      }
      //cout<<"NEW_NT3"<<endl;
    }else{
      //cout<<"here4"<<endl;
      cout<<"here4 new nt"<<yylineno<<endl;
      emit(op,charPtrToString(($2).tempvar),"",charPtrToString(($1).tempvar),-1);
      if(typ.size()>=4&&typ.substr(0,4)=="list"){
      }
      else{
      reg1=getreg(($2).tempvar);
      siz=get_offset(($1).tempvar);
      x86="\tmovq "+reg1+", "+to_string(siz)+"(%rbp)";
      x86_64_code.push_back(x86);}
      //cout<<"NEW_NT4"<<endl;
      }

      // current_local_symbol_table->curr_offset-=siz;
      // current_local_symbol_table->offsets[str_1]=current_local_symbol_table->curr_offset;
      // //reg2=getreg(str_1);
      // x86="\tmovq "+reg1+", "+to_string(current_local_symbol_table->curr_offset)+"(%rbp)";
      // x86_64_code.push_back(x86);
      string type=current_local_symbol_table->variables[($1).lexeme]->type;
   if(type.size()>=4&&type.substr(0,4)=="list"){
      int i, siz, regs_index, off;
      string x86, reg;
      regs_index=current_local_symbol_table->regs_index;
      siz=lex_list_members.size()*16;
      x86="\tmovq $"+to_string(siz)+",%rdi";
      x86_64_code.push_back(x86);
      x86="\tcall malloc@PLT";
      x86_64_code.push_back(x86);
      x86="\tmovq %rax, "+regs[regs_index%8];
      x86_64_code.push_back(x86);
      x86="\tsubq $"+to_string(siz)+",%rsp";
      x86_64_code.push_back(x86);
      current_local_symbol_table->curr_offset-=siz;
      x86="\tmovq "+regs[regs_index%8]+", "+to_string(current_local_symbol_table->curr_offset)+"(%rbp)";
      x86_64_code.push_back(x86);
      current_local_symbol_table->offsets[($1).lexeme]=current_local_symbol_table->curr_offset;
      off=0;
      for(i=0; i<lex_list_members.size(); i++){
      x86="\tmovq $"+lex_list_members[i]+", "+to_string(off)+"("+regs[regs_index%8]+")";
      x86_64_code.push_back(x86);
      off+=16;}
      // for(i=0; i<list_members.size(); i++){
      //  reg=regs[regs_index%8];
      //  off=get_offset(list_members[i]);
      //  x86="\tmovq $"+to_string(off)+"(%rbp), "+reg;
      //   x86_64_code.push_back(x86);
      //   siz=size(($1).type,($1).lexeme);
      //   if(siz<=8) siz=16;
      //   current_local_symbol_table->curr_offset-=siz;
      //   current_local_symbol_table->offsets[charPtrToString(($1).lexeme)+to_string(i)]=current_local_symbol_table->curr_offset;
      //   x86="\tmovq "+reg+", "+to_string(current_local_symbol_table->curr_offset)+"(%rbp)";
      //   x86_64_code.push_back(x86);
      //   regs_index++;}
      regs_index++;
      lex_list_members.clear();
        current_local_symbol_table->regs_index=regs_index;
        list_members.clear();}
        }
    }else{
      string reg1, reg2;
      int siz;
      if(lex1.size()>=4&&lex1.substr(0,4)=="self"){
 string s1= "*";
    char* st = stringToCharArray(s1);
    strcat(st,"(");
    strcat(st,"self");
    strcat(st,"+");
    strcat(st,stringToCharArray(to_string(class_offset)));
    strcat(st,")");
    emit(op,charPtrToString(($2).lexeme),"",st,-1);
    string reg1, reg2;
      int siz;
      if(($1).tempvar == NULL && ($2).tempvar == NULL){
        //cout<<"here1"<<endl;
        reg1=getreg(($2).lexeme);
        reg2=getreg(($1).lexeme);
        siz=get_offset(($1).lexeme);
      }else if(($1).tempvar == NULL){
        //cout<<"here2"<<endl;
        reg1=getreg(($2).tempvar);
        reg2=getreg(($1).lexeme);
        siz=get_offset(($1).lexeme);
      }else if(($2).tempvar == NULL){
        //cout<<"here3"<<endl;
        reg1=getreg(($2).lexeme);
        reg2=getreg(($1).tempvar);
        siz=get_offset(($1).tempvar);
      }else{
        //cout<<"here4"<<endl;
        reg1=getreg(($2).tempvar);
        reg2=getreg(($1).tempvar);
        siz=get_offset(($1).tempvar);
      }

      }
      else{
        if(($1).tempvar == NULL && ($2).tempvar == NULL){
          //cout<<"here1"<<endl;
          emit(op,charPtrToString(($1).lexeme),charPtrToString(($2).lexeme),charPtrToString(($1).lexeme),-1);
          reg1=getreg(($2).lexeme);
          reg2=getreg(($1).lexeme);
          siz=get_offset(($1).lexeme);
        }else if(($1).tempvar == NULL){
          //cout<<"here2"<<endl;
          emit(op,charPtrToString(($1).lexeme),charPtrToString(($2).tempvar),charPtrToString(($1).lexeme),-1);
          reg1=getreg(($2).tempvar);
          reg2=getreg(($1).lexeme);
          siz=get_offset(($1).lexeme);
        }else if(($2).tempvar == NULL){
          //cout<<"here3"<<endl;
          emit(op,charPtrToString(($1).tempvar),charPtrToString(($2).lexeme),charPtrToString(($1).tempvar),-1);
          reg1=getreg(($2).lexeme);
          reg2=getreg(($1).tempvar);
          siz=get_offset(($1).tempvar);
        }else{
          //cout<<"here4"<<endl;
          emit(op,charPtrToString(($1).tempvar),charPtrToString(($2).tempvar),charPtrToString(($1).tempvar),-1);
          reg1=getreg(($2).tempvar);
          reg2=getreg(($1).tempvar);
          siz=get_offset(($1).tempvar);
        }
      }
      string x86;
      string lex = charPtrToString(($2).lexeme);
      if(op=="+"){
        x86="\taddq "+reg1+", "+reg2;
      x86_64_code.push_back(x86);

      }
      else if(op=="-"){
       x86="\tsubq "+reg1+", "+reg2;
      x86_64_code.push_back(x86);

      }
      else if(op=="*"){
        x86="\timulq "+reg1+", "+reg2;
      x86_64_code.push_back(x86);

      }
      else if(op=="/"){
        x86="\tmovq "+reg2+", %rax";
        x86_64_code.push_back(x86);
        x86="\tmovq $0, %rdx";
        x86_64_code.push_back(x86);
        x86="\tidivq "+reg1;
        x86_64_code.push_back(x86);
        x86="\tmovq %rax, "+reg2;
      x86_64_code.push_back(x86);

    }
    else if(op=="%"){
      x86="\tmovq "+reg2+", %rax";
      x86_64_code.push_back(x86);
      x86="\tmovq $0, %rdx";
      x86_64_code.push_back(x86);
      x86="\tidivq "+reg1;
      x86_64_code.push_back(x86);
      x86="\tmovq %rdx, "+reg2;
      x86_64_code.push_back(x86);
      
    }
    else if(op=="&"){
      x86="\tandq "+reg1+", "+reg2;
      x86_64_code.push_back(x86);}
    else if(op=="|"){
      x86="\torq "+reg1+", "+reg2;
      x86_64_code.push_back(x86);}
    else if(op=="^"){
      x86="\txorq "+reg1+", "+reg2;
      x86_64_code.push_back(x86);}
    else if(op=="<<"){
      // cout<<"jhalakkkk "<<yylineno<<endl;
     x86="\tshlq $"+lex+", "+reg2;
     x86_64_code.push_back(x86);}
    else if(op==">>"){
      // cout<<"jhalakkkk "<<yylineno<<endl;
      x86="\tshrq $"+lex+", "+reg2;
      x86_64_code.push_back(x86);}
    else if(op=="**"){
      int regs_index=current_local_symbol_table->regs_index;
      string reg3=regs[(regs_index)%8];
      string reg4=regs[(regs_index+1)%8];
      string L = newLabel();
      string L1 = newLabel();
      x86="\tmovq $1, "+reg4;
      x86_64_code.push_back(x86);
      x86="\tmovq "+reg2+", "+reg3;
      x86_64_code.push_back(x86);
      x86=L+":";
      x86_64_code.push_back(x86);
      x86="\tcmpq "+reg4+", "+reg1;
      x86_64_code.push_back(x86);
      x86="\tjle "+L1;
      x86_64_code.push_back(x86);
      x86="\timulq "+reg2+", "+reg3;
      x86_64_code.push_back(x86);
      x86="\taddq $1, "+reg4;
      x86_64_code.push_back(x86);
      x86="\tjmp "+L;
      x86_64_code.push_back(x86);
      x86=L1+":";
      x86_64_code.push_back(x86);
      x86="\tmovq "+reg3+", "+reg2;
      x86_64_code.push_back(x86);
      
      regs_index++;
      current_local_symbol_table->regs_index=regs_index;
}
  else if(op=="//"){

      x86="\tmovq "+reg2+", %rax";
      x86_64_code.push_back(x86);
      x86="\tmovq $0, %rdx";
      x86_64_code.push_back(x86);
      x86="\tidivq "+reg1;
      x86_64_code.push_back(x86);
      x86="\tmovq %rax, "+reg2;
      x86_64_code.push_back(x86);

    }
      x86="\tmovq "+reg2+", "+to_string(siz)+"(%rbp)";
      x86_64_code.push_back(x86);

  if(siz%16!=0) siz=(siz/16+1)*16;
  if(charPtrToString(($1).lexeme).size()>=4&&charPtrToString(($1).lexeme).substr(0,5)=="self."){
  int r=current_local_symbol_table->regs_index;
  string regi=regs[r%8];
  r++;
  x86="\tmovq "+to_string(get_offset("self"))+"(%rbp), "+regi;
  x86_64_code.push_back(x86);
  x86="\tmovq "+reg2+", "+to_string(siz)+"("+regi+")";
  x86_64_code.push_back(x86);
  current_local_symbol_table->regs_index=r;
  }else{
    x86="\tmovq "+reg2+", "+to_string(siz)+"(%rbp)";
    x86_64_code.push_back(x86);}

    }
    }
    //cout<<"expr1"<<endl;
  }
  | NEW_NT B{
    //cout<<"expr_stmt2 "<<yylineno<<" "<<endl;
    cout<<"here also"<<init_reg<<endl;
    if(!type_correct(($1).type,($2).type)){
    type_errors[type_error_line]="Type mismatch in assignment on line "+to_string(type_error_line);}
    /////////////////3AC/////////////////
    string reg1, reg2;
    int off;
    if(($1).tempvar == NULL && ($2).tempvar == NULL){
      emit("=",charPtrToString(($2).lexeme),"",charPtrToString(($1).lexeme),-1);
      reg1=getreg(($2).lexeme);
      reg2=getreg(($1).lexeme);
      off=get_offset(($1).lexeme);
    }else if(($2).tempvar == NULL){
      emit("=",charPtrToString(($2).lexeme),"",charPtrToString(($1).tempvar),-1);
      reg1=getreg(($2).lexeme);
      reg2=getreg(($1).tempvar);
      off=get_offset(($1).tempvar);
    }else if(($1).tempvar == NULL){
      emit("=",charPtrToString(($2).tempvar),"",charPtrToString(($1).lexeme),-1);
      reg1=getreg(($2).tempvar);
      reg2=getreg(($1).lexeme);
      off=get_offset(($1).lexeme);
    }else{
      emit("=",charPtrToString(($2).tempvar),"",charPtrToString(($1).tempvar),-1);
      reg1=getreg(($2).tempvar);
      reg2=getreg(($1).tempvar);
      off=get_offset(($1).tempvar);
    }
   string x86;
    x86="\tmovq "+reg1+", "+reg2;
    x86_64_code.push_back(x86);
  //       x86 = "\tsubq $16, %rsp";
  // x86_64_code.push_back(x86);
  if(off%16!=0) off=(off/16+1)*16;
  if(charPtrToString(($1).lexeme).size()>=4&&charPtrToString(($1).lexeme).substr(0,5)=="self."){
    int r=current_local_symbol_table->regs_index;
    string regi=regs[r%8];
    r++;
    x86="\tmovq "+to_string(get_offset("self"))+"(%rbp), "+regi;
    x86_64_code.push_back(x86);
    x86="\tmovq "+reg2+", "+to_string(off)+"("+regi+")";
    x86_64_code.push_back(x86);
    current_local_symbol_table->regs_index=r;
  }else{
    x86="\tmovq "+reg2+", "+to_string(off)+"(%rbp)";
    x86_64_code.push_back(x86);}

  
  }
| NEW_NT {
  
};
// empty: /*empty*/{
//   variable_declared=1;
// };
A: annassign {
  $$.lexeme = ($1).lexeme;
  $$.tempvar = ($1).tempvar;
  // $$.type = ($1).type;
  $$.op = ($1).op;

  $$.type="";
 }
  |augassign testlist {
    $$.type=($2).type;
    $$.lexeme = ($2).lexeme;
    $$.tempvar = ($2).tempvar;
    $$.op = ($1).op;
    }
// | B {$$=$1;}
  ;
eq: EQUAL{type_error_line=yylineno;
  $$.lexeme =$1;
};
B: eq NEW_NT  {
  $$.lexeme = ($2).lexeme;
  $$.type=($2).type;
  $$.tempvar = ($2).tempvar;
  }
| B eq NEW_NT{
  $$.type=($3).type;
  $$.lexeme = ($3).lexeme;
}
;
annassign: col test c{
  if(strcmp(($2).type,"list")!=0 && !type_correct(($2).type,($3).type) && ($3).type!=""){
  type_errors[type_error_line]="Type mismatch in assignment on line "+to_string(type_error_line);}
    if(($3).lexeme!=NULL)
      $$.lexeme = ($3).lexeme;
    else{
      $$.lexeme = NULL;
    }

    $$.type = ($3).type;
    $$.op = ($3).op;
    $$.tempvar = ($3).tempvar;

};
col: COLON {
  scope_stack.push(":");
};
NEW_NT: test optional_comma_test d{
  $$.lexeme = ($1).lexeme;
  $$.type=($1).type;

}
        | test d {
          $$.lexeme = ($1).lexeme;
          $$.type=($1).type;
          $$.tempvar = ($1).tempvar;

          }
;
augassign: PLUSEQUAL {type_error_line=yylineno;
  $$.op = stringToCharArray("+");
}
          | MINEQUAL {type_error_line=yylineno;
          $$.op = stringToCharArray("-");}
          | STAREQUAL {type_error_line=yylineno;
          $$.op = stringToCharArray("*");}
          | ATEQUAL {type_error_line=yylineno;
          $$.op = stringToCharArray("@");}
          | SLASHEQUAL {type_error_line=yylineno;
          $$.op = stringToCharArray("/");}
          | PERCENTEQUAL {type_error_line=yylineno;
          $$.op = stringToCharArray("%");}
          | AMPEQUAL {type_error_line=yylineno;
          $$.op = stringToCharArray("&");}
          | VBAREQUAL {type_error_line=yylineno;
          $$.op = stringToCharArray("|");}
          | CIRCUMFLEXEQUAL {type_error_line=yylineno;
          $$.op = stringToCharArray("^");}
          
          | LEFTSHIFTEQUAL {type_error_line=yylineno;
          $$.op = stringToCharArray("<<");}

          | RIGHTSHIFTEQUAL {type_error_line=yylineno;
          $$.op = stringToCharArray(">>");}

          | DOUBLESTAREQUAL {type_error_line=yylineno;
          $$.op = stringToCharArray("**");}

          | DOUBLESLASHEQUAL {type_error_line=yylineno;
          $$.op = stringToCharArray("//");}

          ;
flow_stmt: break_stmt {
  
}
    | continue_stmt {
      
    }
    | return_stmt {
     $$.gotoname = ($1).gotoname; 
    }
    | raise_stmt {
      
    };
break_stmt: BREAK {
    is_break = 1;
    
    emit("Break","","","",-1);
    string L = break_labels.top();
    
    x86_64_code.push_back("\tjmp "+L);
    emit("goto",L,"","",-1);

};
continue_stmt: CONTINUE {
    emit("Continue","","","",-1);
    string L = continue_label.top();
    emit("goto",L,"","",-1);
    // x86_64_code.push_back("\tjmp "+L);
    string lexeme = expr_lexeme.top();
    string second = expr_second.top();
    int offset = get_offset(lexeme);
    int offset2 = get_offset(second);
    string b = break_labels.top();
    string reg1 = getreg(lexeme);
    string reg2 = getreg(second);
    x86_64_code.push_back("\taddq $1,"+reg1);
    x86_64_code.push_back("\tmovq "+reg1+", "+to_string(offset)+"(%rbp)");
    x86_64_code.push_back("\tmovq "+to_string(offset2)+"(%rbp), "+reg2);
    x86_64_code.push_back("\tcmpq "+reg2+", "+reg1); // compare condition
    x86_64_code.push_back("\tjge "+b); //jump out of the loop
    
    x86_64_code.push_back("\tjmp "+L); // jump to the 
};
return_stmt: RETURN testlist {
  current_local_symbol_table->return_val=charPtrToString(($2).lexeme);
  string reg1;
  if(($2).tempvar!=NULL){
    emit("\treturn", charPtrToString(($2).tempvar) , "", "", -1);
    reg1=getreg(($2).tempvar);
  }
  else {
    emit("\treturn", charPtrToString(($2).lexeme) , "", "", -1);
    reg1=getreg(($2).lexeme);
  }
  string L = newLabel();
  emit("goto",L,"","",-1);
  $$.gotoname = stringToCharArray(L);
  return_labels.push(L);
  is_return = 1;
  string x86;
  x86="\tmovq "+reg1+", %rax";
  x86_64_code.push_back(x86);
   }
|RETURN {
  emit("\treturn","", "", "", -1);
  string L = newLabel();
  emit("goto",L,"","",-1);
  $$.gotoname = stringToCharArray(L);
  return_labels.push(L);
  is_return = 1;
  string x86;
};

// l: testlist
//   | /* empty */;
raise_stmt: RAISE m {
  
   };
m: test n {}
  | /* empty */{};
n: FROM test { }
  | /* empty */{};
// global_stmt: 'global' NAME (',' NAME)*;
global_stmt: GLOBAL NAME optional_comma_name {
  Lookup($2, "global", yylineno, global_table);
};
// nonlocal_stmt: 'nonlocal' NAME (',' NAME)*;
nonlocal_stmt: NONLOCAL NAME optional_comma_name {

};  
optional_comma_name : /*empty*/ {}
                    | optional_comma_name COMMA NAME {
                      Lookup($3, "global", yylineno, global_table);
                    }
                    ;

assert_stmt: ASSERT test o  {
 
};
o: COMMA test {} 
  | /* empty */ {}; 
compound_stmt: if_stmt1  {
       string a = charPtrToString(($1).gotoname);
    string b = a+": ";
    x86_64_code.push_back(b);
    uncond_jump.pop();
}
            | while_stmt1 {
    break_labels.pop();
              }
            | while_stmt2{
            }
            | for_stmt1  {
  string L = charPtrToString(($1).gotoname);
  x86_64_code.push_back(L+":");
  break_labels.pop();
  continue_label.pop();
  expr_lexeme.pop();
  expr_second.pop();
              }
            |for_stmt2{

            }
            | funcdef  {
            }
            | classdef {
              }
            | if_else_stmt1{
               uncond_jump.pop();
            }
            | if_else_stmt2{
 uncond_jump.pop();
            }
            ;
iff: IF {type_error_line=yylineno;};
elif: ELIF {type_error_line=yylineno;};
if_stmt1: iftestcol suite{
  string a = charPtrToString(($1).gotoname);
  string L = newLabel();
  ///// 3AC /////
    emit("goto",L,"","",-1); // unconditionl jump
    emit(a,":","","",-1);    // conditional jump for next elif or else.
  ////// X86 //////
  x86_64_code.push_back("\tjmp "+L); // un jump
  string b = a+":"; 
  x86_64_code.push_back(b); // conditional jump 
  $$.gotoname = stringToCharArray(L);
  uncond_jump.push(L);
  $$.label = ($1).gotoname;
  //cout<<"here at if_stmt"<<endl;
  };

iftestcol: iff test COLON{
  /////////////3AC/////////////////
  //cout<<"here at iftestcol start"<<endl;
    string label = newLabel();
    string a;
    if(($2).tempvar == NULL){
      a = charPtrToString(($2).lexeme);
      cout<<"yahan hu main "<<yylineno<<endl;
      x86_64_code.push_back("\tcmpq $0, "+getreg(($2).lexeme));
    }else{
      a = charPtrToString(($2).tempvar);
      x86_64_code.push_back("\tcmpq $0, "+getreg(($2).tempvar));
    }
    emit("goto",a,label,"Ifz",-1);
    x86_64_code.push_back("\tje "+label);
    $$.gotoname = stringToCharArray(label);  //cout<<"here at iftestcol end"<<endl;
    if(!type_correct(($2).type,"bool")){
      type_errors[type_error_line]="Type of condition isn't of bool type in if statement on line "+to_string(type_error_line);
    }
};

elsecol: ELSE COLON{
  // else_present = 1;
};
if_else_stmt1: if_stmt1 elsecol suite{
  string a = charPtrToString(($1).gotoname);
  emit(a,":","","",-1);  // unconditional jump of if stmt 
  string b = a+":";
  x86_64_code.push_back(b);
};
if_else_stmt2: if_stmt1 elif_suite {
  // the unconditional jump of if and elif is same.
  string a = charPtrToString(($1).gotoname); // code for unconditional jump of if_stmt1
  emit(a,":","","",-1); 
  string b = a+":";
  x86_64_code.push_back(b);

}|if_stmt1 elif_suite elsecol suite{
  // the unconditional jump of if and elif is same.
  string a = charPtrToString(($1).gotoname); // code for unconditional jump of if_stmt1
  emit(a,":","","",-1); 
  string b = a+":";
  x86_64_code.push_back(b);

};
eliftestcol: elif test COLON{
  if(!type_correct(($2).type,"bool")){
    type_errors[type_error_line]="Type of condition isn't of bool type in elif statement on line "+to_string(type_error_line);}
    string label = newLabel();
    string a;
    string reg1;
    if(($2).tempvar == NULL){
      a = ($2).lexeme;
      reg1 = getreg(($2).lexeme);
    }else{
      a = ($2).tempvar;
      reg1 = getreg(($2).tempvar);
    }
    emit("goto",a,label,"Ifz",-1);

    x86_64_code.push_back("\tcmpq $0, "+reg1);
    x86_64_code.push_back("\tje "+label);
    $$.gotoname = stringToCharArray(label);  //cout<<"here at iftestcol end"<<endl;

};
elif_suite: eliftestcol suite{
  string a = charPtrToString(($1).gotoname);
  // string L = ($1).gotoname;
  string L = uncond_jump.top();
  emit("goto",L,"","",-1);
  x86_64_code.push_back("\tjmp "+L);
  string b = a+":";
  emit(a,":","","",-1);
  x86_64_code.push_back(b);
  
}| elif_suite eliftestcol suite{
  string a = charPtrToString(($2).gotoname);
  emit(a,":","","",-1);
  string L = uncond_jump.top();
  emit("goto",L,"","",-1);
  x86_64_code.push_back("\tjmp "+L);
  string b = a+":";
  x86_64_code.push_back(b);
};

whilee: WHILE {type_error_line=yylineno;
 string L = newLabel();
 /// 3AC /////
  emit(L,":","","",-1); 
  ///// X86 //////
  x86_64_code.push_back(L+":");
  $$.gotoname = stringToCharArray(L);
};
while_stmt1: while_start suite {
  string L = charPtrToString(($1).label);
  string a = charPtrToString(($1).gotoname);
  //// 3AC /////
  emit("goto",L,"","",-1);
  emit(a,":" ,"","",-1);
  ////// X86 //////
  x86_64_code.push_back("\tjmp "+L);
  x86_64_code.push_back(a+":");
  continue_label.pop();

};
while_stmt2: while_stmt1 elsecol suite{
  /// won't be used hopefully////
  if(is_break){
    emit(break_label,":","","",-1);
    break_label = "";
    is_break = 0;
  }
    continue_label.pop();
};
while_start: whilee test COLON{
if(!type_correct(($2).type,"bool")){
    type_errors[type_error_line]="Type of condition isn't of bool type in while loop on line "+to_string(type_error_line);} 
    string a;
    string label = newLabel();
    //// 3AC /////
    //// X86 /////
    if(($2).tempvar == NULL){
      a = charPtrToString(($2).lexeme);
      x86_64_code.push_back("\tcmpq $0, "+getreg(($2).lexeme));
    }else{
      a = charPtrToString(($2).tempvar);
      x86_64_code.push_back("\tcmpq $0, "+getreg(($2).tempvar));
    }
    emit("goto",a,label,"Ifz",-1);

    x86_64_code.push_back("\tje "+label);
    $$.gotoname = stringToCharArray(label);
    break_labels.push(label);
  $$.label = ($1).gotoname;
  continue_label.push(charPtrToString(($1).gotoname)); // beginning of the loop

  // cout<<"while_start"<<($$).gotoname<<endl;
};
forr: FOR {
  type_error_line=yylineno;
};
for_stmt1: for_start suite {
  /// 3AC ///// 
  emit("goto",charPtrToString(($1).label),"","",-1);
  emit(charPtrToString(($1).gotoname),":","","",-1);
  //// X86 /////
 string reg1=getreg(($1).lexeme);
 string reg2 = getreg(($1).second);
   int offset = get_offset(($1).lexeme);
  int offset2 = get_offset(($1).second);

  x86_64_code.push_back("\taddq $1,"+reg1);
  x86_64_code.push_back("\tmovq "+reg1+", "+to_string(offset)+"(%rbp)");
  x86_64_code.push_back("\tmovq "+to_string(offset2)+"(%rbp), "+reg2);
  x86_64_code.push_back("\tcmpq "+reg2+", "+reg1); // compare condition
  x86_64_code.push_back("\tjge "+charPtrToString(($1).gotoname)); // jump out of the loop
  x86_64_code.push_back("\tjmp "+charPtrToString(($1).label));

  $$.gotoname = ($1).gotoname;
};
for_stmt2: for_stmt1 elsecol suite{
////// not implemented /////////
}
; 
for_start: forr exprlist IN testlist COLON{
  expr_value = charPtrToString(($2).lexeme);
   if(!type_correct(($2).type,"int")){
    type_errors[type_error_line]="Type of iterator isn't of int type in for loop on line "+to_string(type_error_line);}
  string a = newtemp();
  string L = newLabel(); // for unconditional jump
  emit(L,":","","",-1);  // marks loop beginning

      if(($2).tempvar == NULL && ($4).tempvar == NULL){
        emit("in",charPtrToString(($2).lexeme),charPtrToString(($4).lexeme),a,-1);
      }else if(($2).tempvar == NULL){
        emit("in",charPtrToString(($2).lexeme),charPtrToString(($4).tempvar),a,-1);
      }else if(($4).tempvar == NULL){
        emit("in",charPtrToString(($2).tempvar),charPtrToString(($4).lexeme),a,-1);
      }else{
        emit("in",charPtrToString(($2).tempvar),charPtrToString(($4).tempvar),a,-1);
      }
  string L1 = newLabel(); // for conditional jump
  emit("goto",a,L1,"Ifz",-1);
// implementing the range function
  int offset = get_offset(($2).lexeme);
  string reg1 = getreg(range1);
  x86_64_code.push_back("\tmovq "+reg1+", "+to_string(offset)+"(%rbp)");
  x86_64_code.push_back(L+":"); // for unconditional jump

  continue_label.push(L); /// beg of loop
  expr_lexeme.push(charPtrToString(($2).lexeme));
  expr_second.push(range2);
  break_labels.push(L1); // end of the loop
  $$.lexeme = ($2).lexeme;
  $$.label = stringToCharArray(L);
  $$.gotoname = stringToCharArray(L1);
  $$.second = stringToCharArray(range2); // second parameter for range

};
suite: simple_stmt   {
  
  }
    | NEWLINE INDENT stmts DEDENT {
      
    };
// dedent_plus: DEDENT 
//             | dedent_plus DEDENT 
//             ;
stmts: stmts stmt {
  
}
      | stmt{
         
        };

test: or_test u {
  $$.lexeme = ($1).lexeme;
  $$.type=($1).type;
  // ($1).type="bool";
  $$.tempvar = ($1).tempvar;
  $$.gotoname = ($1).gotoname;
 //cout<<"test "<<$$.type<<endl;
  };  
u: IF or_test ELSE test {
  
}
  | /* empty */{
    
  };

or: OR {type_error_line=yylineno;
  $$.lexeme = $1;
};
or_test: and_test{
 $$.lexeme = ($1).lexeme;
 $$.type=($1).type;
 $$.tempvar = ($1).tempvar;
 $$.gotoname = ($1).gotoname;
} 
|or_test or and_test{
$$.type="bool"; 
if(($1).type=="str"||($3).type=="str") {
  type_errors[type_error_line]="Logical operation on string on line "+to_string(type_error_line)+" not allowed";}
  // else if(!type_correct(($1).type,($3).type)){
  //   type_errors[yylineno]="Type mismatch in or operation on line "+to_string(yylineno);}
      string a = newtemp();
          // string a = newtemp();
      string reg1, reg2;

      string op = charPtrToString(($2).lexeme);
      if(($1).tempvar == NULL && ($3).tempvar == NULL){
        emit(op,charPtrToString(($1).lexeme),charPtrToString(($3).lexeme),a,-1);
        reg1 = getreg(($1).lexeme);
        reg2 = getreg(($3).lexeme);

      }else if(($1).tempvar == NULL){
        emit(op,charPtrToString(($1).lexeme),charPtrToString(($3).tempvar),a,-1);
        reg1 = getreg(($1).lexeme);
        reg2 = getreg(($3).tempvar);

      }else if(($3).tempvar == NULL){
        emit(op,charPtrToString(($1).tempvar),charPtrToString(($3).lexeme),a,-1);
        reg1 = getreg(($1).tempvar);
        reg2 = getreg(($3).lexeme);
      }else{
        emit(op,charPtrToString(($1).tempvar),charPtrToString(($3).tempvar),a,-1);
        reg1 = getreg(($1).tempvar);
        reg2 = getreg(($3).tempvar);
      }
      $$.tempvar = stringToCharArray(a);

      $$.lexeme = ($1).lexeme; // not actually important
      $$.tempvar = stringToCharArray(a);
      // string x86="\tsubq $16, %rsp";
      // x86_64_code.push_back(x86);
      current_local_symbol_table->curr_offset-=16;
      current_local_symbol_table->offsets[a]=current_local_symbol_table->curr_offset;
      string reg3 = getreg(a);
      string x86;
      x86 = "\tmovq "+reg1+", "+reg3;  // move reg1 to reg3
      x86_64_code.push_back(x86);
      x86 = "\torq "+reg2+", "+reg3; // or of reg2 with reg3, stored in reg3
      x86_64_code.push_back(x86);
      x86 = "\tsubq $16, %rsp";
  x86_64_code.push_back(x86);
      x86="\tmovq "+reg3+", "+to_string(current_local_symbol_table->curr_offset)+"(%rbp)";
      x86_64_code.push_back(x86);

} 
;
and: AND {type_error_line=yylineno;
$$.lexeme = $1;};
and_test: not_test {
  $$.lexeme = ($1).lexeme;
  $$.type=($1).type;
  $$.tempvar = ($1).tempvar;
      $$.gotoname = ($1).gotoname;
}
|and_test and not_test {
$$.type="bool"; 
if(($1).type=="str"||($3).type=="str") {
  type_errors[type_error_line]="Logical operation on string on line "+to_string(type_error_line)+" not allowed";}
  // else if(!type_correct(($1).type,($3).type)){
  //   type_errors[yylineno]="Type mismatch in and operation on line "+to_string(yylineno);}
    string op = "&";
    string a = newtemp();
    string reg1, reg2;
    if(($1).tempvar == NULL && ($3).tempvar == NULL){
      emit(op,charPtrToString(($1).lexeme),charPtrToString(($3).lexeme),a,-1);
      reg1 = getreg(($1).lexeme);
      reg2 = getreg(($3).lexeme);
    }else if(($1).tempvar == NULL){
      emit(op,charPtrToString(($1).lexeme),charPtrToString(($3).tempvar),a,-1);
      reg1 = getreg(($1).lexeme);
      reg2 = getreg(($3).tempvar);
    }else if(($3).tempvar == NULL){
      emit(op,charPtrToString(($1).tempvar),charPtrToString(($3).lexeme),a,-1);
      reg1 = getreg(($1).tempvar);
      reg2 = getreg(($3).lexeme);
    }else{
      emit(op,charPtrToString(($1).tempvar),charPtrToString(($3).tempvar),a,-1);
      reg1 = getreg(($1).tempvar);
      reg2 = getreg(($3).tempvar);
    }

      $$.lexeme = ($1).lexeme; // not actually important
      $$.tempvar = stringToCharArray(a);
      // string x86="\tsubq $16, %rsp";
      // x86_64_code.push_back(x86);
      current_local_symbol_table->curr_offset-=16;
      current_local_symbol_table->offsets[a]=current_local_symbol_table->curr_offset;
      string reg3 = getreg(a);
      string x86;
      x86 = "\tmovq "+reg1+", "+reg3;
      x86_64_code.push_back(x86);
      x86 = "\tandq "+reg2+", "+reg3;
      x86_64_code.push_back(x86);
      x86 = "\tsubq $16, %rsp";
      x86_64_code.push_back(x86);
      x86="\tmovq "+reg3+", "+to_string(current_local_symbol_table->curr_offset)+"(%rbp)";
      x86_64_code.push_back(x86);

}
;
not_test: NOT not_test {
$$.type="bool"; 
  string a = newtemp();
  if(($2).tempvar!=NULL) emit("not","",charPtrToString(($2).tempvar),a,-1);
  else emit("not","",charPtrToString(($2).lexeme),a,-1);
  $$.tempvar = stringToCharArray(a);
  $$.lexeme = ($2).lexeme;
  string reg1;
  if(($2).tempvar==NULL){
    reg1 = getreg(($2).lexeme);
  }else{
    // cout<<"//hererrerere"<<endl;
    reg1 = getreg(($2).tempvar);
  }
      current_local_symbol_table->curr_offset-=16;
      current_local_symbol_table->offsets[a]=current_local_symbol_table->curr_offset;
  
  string reg2 = getreg(a);
  string label = newLabel();
  string label2 = newLabel();
  x86_64_code.push_back("\tcmpq $0, " + reg1);
  x86_64_code.push_back("\tjne "+label);
  x86_64_code.push_back("\tmovq $1, "+reg2);
  x86_64_code.push_back("\tjmp "+label2);
  x86_64_code.push_back(label+":");
  x86_64_code.push_back("\tmovq $0, "+reg2);
  x86_64_code.push_back(label2+":");
  int offset = get_offset(a);
  string x86="\tmovq "+reg2+", "+to_string(offset)+"(%rbp)";
  x86_64_code.push_back(x86);

}
    | comparison {
      $$.lexeme = ($1).lexeme;
      $$.type=($1).type;
      $$.tempvar = ($1).tempvar;
      $$.gotoname = ($1).gotoname;
    }
;
comparison: expr {
 $$.lexeme = ($1).lexeme; 
 $$.type=($1).type;
 $$.tempvar = ($1).tempvar;

}
|comparison comp_op expr {
 $$.type="bool";
  if(strcmp(($1).lexeme,"__name__")!=0&&!type_correct(($1).type,($3).type)){
    //cout<<"comparison "<<($1).lexeme<<yylineno<<endl;
    type_errors[type_error_line]="Type mismatch in comparison on line "+to_string(type_error_line);
    } 

  string a = newtemp();
  string reg1,reg2;
  string op = charPtrToString(($2).op);
  int offset = get_offset(($3).lexeme);
    if(($1).tempvar == NULL && ($3).tempvar == NULL){
      emit(op,charPtrToString(($1).lexeme),charPtrToString(($3).lexeme),a,-1);
      reg1=getreg(($1).lexeme);
      reg2=getreg(($3).lexeme);
      int offset = get_offset(($3).lexeme);
    }else if(($1).tempvar == NULL){
      // cout<<"HERRRRRRRR"<<endl;
      emit(op,charPtrToString(($1).lexeme),charPtrToString(($3).tempvar),a,-1);
      reg1=getreg(($1).lexeme);
      reg2=getreg(($3).tempvar);
      int offset = get_offset(($3).tempvar);

    }else if(($3).tempvar == NULL){
      emit(op,charPtrToString(($1).tempvar),charPtrToString(($3).lexeme),a,-1);
      reg1=getreg(($1).tempvar);
      reg2=getreg(($3).lexeme);
      int offset = get_offset(($3).lexeme);

    }else{
      emit(op,charPtrToString(($1).tempvar),charPtrToString(($3).tempvar),a,-1);
      reg1=getreg(($1).tempvar);
      reg2=getreg(($3).tempvar);
      int offset = get_offset(($3).tempvar);
      
    }
    $$.tempvar = stringToCharArray(a);
    string x86;
    string reg3 = getreg(a);

    x86 = "\tsubq "+reg1+", "+reg2;
    x86_64_code.push_back(x86);
// store thw value of reg2 in reg3 
    x86 = "\tmovq "+reg2+", "+reg3;
    x86_64_code.push_back(x86);
    x86 = "\tsubq $16, %rsp";
    x86_64_code.push_back(x86);
    current_local_symbol_table->curr_offset -=16;
    x86 ="\tmovq "+reg3+", "+to_string(current_local_symbol_table->curr_offset)+"(%rbp)";
    current_local_symbol_table->offsets[a] = current_local_symbol_table->curr_offset;

    x86_64_code.push_back(x86);
    // restore the value of reg2 
    x86 = "\tmovq "+to_string(offset)+"(%rbp), "+reg2;
    x86_64_code.push_back(x86);
    $$.op = ($2).op;

//  ///// now the jump statement
  if(op == "<"){
    x86_64_code.push_back("\tcmpq $0,"+reg3);
    string label = newLabel();
    string label2 = newLabel();
    x86_64_code.push_back("\tjle "+label);
    x86_64_code.push_back("\tmovq $1, "+reg3);
    x86_64_code.push_back("\tjmp "+label2);
    x86_64_code.push_back(label+":");
    x86_64_code.push_back("\tmovq $0, "+reg3);
    x86_64_code.push_back(label2+":");

    int offset = get_offset(a);
    x86 ="\tmovq "+reg3+", "+to_string(offset)+"(%rbp)";
    x86_64_code.push_back(x86);
  }else if(op == ">"){
    x86_64_code.push_back("\tcmpq $0,"+reg3);
    string label = newLabel();
    string label2 = newLabel();
    x86_64_code.push_back("\tjge "+label);
    x86_64_code.push_back("\tmovq $1, "+reg3);
    x86_64_code.push_back("\tjmp "+label2);
    x86_64_code.push_back(label+":");
    x86_64_code.push_back("\tmovq $0, "+reg3);
    x86_64_code.push_back(label2+":");

    int offset = get_offset(a);
    x86 ="\tmovq "+reg3+", "+to_string(offset)+"(%rbp)";
    x86_64_code.push_back(x86);  
  }else if(op == "=="){
    x86_64_code.push_back("\tcmpq $0,"+reg3);
    string label = newLabel();
    string label2 = newLabel();
    x86_64_code.push_back("\tjne "+label);
    x86_64_code.push_back("\tmovq $1, "+reg3);
    x86_64_code.push_back("\tjmp "+label2);
    x86_64_code.push_back(label+":");
    x86_64_code.push_back("\tmovq $0, "+reg3);
    x86_64_code.push_back(label2+":");

    int offset = get_offset(a);
    x86 ="\tmovq "+reg3+", "+to_string(offset)+"(%rbp)";
    x86_64_code.push_back(x86);
  }else if(op == ">="){
    x86_64_code.push_back("\tcmpq $0,"+reg3);
    string label = newLabel();
    string label2 = newLabel();
    x86_64_code.push_back("\tjg "+label);
    x86_64_code.push_back("\tmovq $1, "+reg3);
    x86_64_code.push_back("\tjmp "+label2);
    x86_64_code.push_back(label+":");
    x86_64_code.push_back("\tmovq $0, "+reg3);
    x86_64_code.push_back(label2+":");

    int offset = get_offset(a);
    x86 ="\tmovq "+reg3+", "+to_string(offset)+"(%rbp)";
    x86_64_code.push_back(x86);
  }else if(op == "<="){
    x86_64_code.push_back("\tcmpq $0,"+reg3);
    string label = newLabel();
    string label2 = newLabel();
    x86_64_code.push_back("\tjl "+label);
    x86_64_code.push_back("\tmovq $1, "+reg3);
    x86_64_code.push_back("\tjmp "+label2);
    x86_64_code.push_back(label+":");
    x86_64_code.push_back("\tmovq $0, "+reg3);
    x86_64_code.push_back(label2+":");

    int offset = get_offset(a);
    x86 ="\tmovq "+reg3+", "+to_string(offset)+"(%rbp)";
    x86_64_code.push_back(x86);
  }else if(op == "!=" || op == "<>"){
    x86_64_code.push_back("\tcmpq $0,"+reg3);
    string label = newLabel();
    string label2 = newLabel();
    x86_64_code.push_back("\tje "+label);
    x86_64_code.push_back("\tmovq $1, "+reg3);
    x86_64_code.push_back("\tjmp "+label2);
    x86_64_code.push_back(label+":");
    x86_64_code.push_back("\tmovq $0, "+reg3);
    x86_64_code.push_back(label2+":");

    int offset = get_offset(a);
    x86 ="\tmovq "+reg3+", "+to_string(offset)+"(%rbp)";
    x86_64_code.push_back(x86);
  }  // cout<<"comparison2"<<endl;


}
;

comp_op: LESS {type_error_line=yylineno;
  $$.op = $1;
}
        |GREATER {type_error_line=yylineno;
  $$.op = $1;
        }
        |EQEQUAL  {
          //cout<<"comp_op == "<<yylineno<<endl; 
          type_error_line=yylineno;
  $$.op = $1;
        }
        |GREATEREQUAL  {type_error_line=yylineno;
  $$.op = $1;
        }
        |LESSEQUAL  {type_error_line=yylineno;
  $$.op = $1;
        }
        |NOTEQUAL  {type_error_line=yylineno;
  $$.op = $1;
        }
        |NOEQUAL  {type_error_line=yylineno;
  $$.op = $1;
        }
        |IN  {type_error_line=yylineno;
  $$.op = $1;
        }
        |NOT IN {
          type_error_line=yylineno;
  $$.op = $1;
        }
        |IS {type_error_line=yylineno;
  $$.op = $1;
        }
        |IS NOT {
        type_error_line=yylineno;
  $$.op = $1;
      
        }
        ; 

expr: xor_expr optional_slash_xor_expr {
  $$.lexeme = ($1).lexeme;
  $$.type=($1).type;
  //cout<<"expr"<<endl;

  if(($2).type!=""&&(($1).type=="str"||($2).type=="str")) {
    type_errors[type_error_line]="Mutable operation on string on line "+to_string(type_error_line)+" not allowed";
    }
  else if(($2).type!=""&&($1).type!=""&&!type_correct(($1).type,($2).type)){
    type_errors[type_error_line]="Type mismatch in | operation on line "+to_string(type_error_line);
    }
  if(($2).lexeme == NULL){
    $$.tempvar = ($1).tempvar;
  }else{
    if(current_local_symbol_table->parent!=NULL && current_local_symbol_table->parent->scope=="class"){
       string a = newtemp();
   int off1, off2;

    if(($1).tempvar == NULL && ($2).tempvar == NULL){
      emit("|",charPtrToString(($1).lexeme),charPtrToString(($2).lexeme),a,-1);
      off1 = current_local_symbol_table->parent->offsets[($1).lexeme];
      off2 = current_local_symbol_table->parent->offsets[($2).lexeme];
    }else if(($1).tempvar == NULL){
      emit("|",charPtrToString(($1).lexeme),charPtrToString(($2).tempvar),a,-1);
       off1 = current_local_symbol_table->parent->offsets[($1).lexeme];
      off2 = current_local_symbol_table->parent->offsets[($2).tempvar];
    }else if(($2).tempvar == NULL){
      emit("|",charPtrToString(($1).tempvar),charPtrToString(($2).lexeme),a,-1);
       off1 = current_local_symbol_table->parent->offsets[($1).tempvar];
      off2 = current_local_symbol_table->parent->offsets[($2).lexeme];
    }else{
      emit("|",charPtrToString(($1).tempvar),charPtrToString(($2).tempvar),a,-1);
       off1 = current_local_symbol_table->parent->offsets[($1).tempvar];
      off2 = current_local_symbol_table->parent->offsets[($2).tempvar];
    }
    current_local_symbol_table->curr_offset-=16;
      current_local_symbol_table->offsets[a]=current_local_symbol_table->curr_offset;
      current_local_symbol_table->parent->offsets[a]=current_local_symbol_table->curr_offset;
   int regs_index = current_local_symbol_table->regs_index;
      string reg3 = regs[regs_index%8];
      regs_index++;
      string x86;

 if(strcmp(stringToCharArray(reg3),stringToCharArray(init_reg))==0){
      reg3 = regs[regs_index%8]; 
      regs_index++;}
if(off1>=0){
        x86 = "\tmovq " + to_string(off1) + "(" + init_reg + "), " + reg3;
        x86_64_code.push_back(x86);

      }
      else {
        x86 = "\tmovq " + to_string(off1) + "(%rbp), " + reg3;
        x86_64_code.push_back(x86);
      }
      if(off2>=0){
         x86 = "\txorq " + to_string(off2) + "(" + init_reg + "), " + reg3;
        x86_64_code.push_back(x86);
      }
      else {
         x86 = "\txorq " + to_string(off2) + "(%rbp), " + reg3;
        x86_64_code.push_back(x86);
      }
          x86 = "\tsubq $16, %rsp";
      x86_64_code.push_back(x86);
      x86="\tmovq "+reg3+", "+to_string(current_local_symbol_table->curr_offset)+"(%rbp)";
      x86_64_code.push_back(x86);
      regs_index++;
      current_local_symbol_table->regs_index=regs_index;
  
    }
    else{
    string a = newtemp();
   string reg1, reg2;
    if(($1).tempvar == NULL && ($2).tempvar == NULL){
      emit("|",charPtrToString(($1).lexeme),charPtrToString(($2).lexeme),a,-1);
      reg1=getreg(($1).lexeme);
      reg2=getreg(($2).lexeme);
    }else if(($1).tempvar == NULL){
      emit("|",charPtrToString(($1).lexeme),charPtrToString(($2).tempvar),a,-1);
      reg1=getreg(($1).lexeme);
      reg2=getreg(($2).tempvar);
    }else if(($2).tempvar == NULL){
      emit("|",charPtrToString(($1).tempvar),charPtrToString(($2).lexeme),a,-1);
      reg1=getreg(($1).tempvar);
      reg2=getreg(($2).lexeme);
    }else{
      emit("|",charPtrToString(($1).tempvar),charPtrToString(($2).tempvar),a,-1);
      reg1=getreg(($1).tempvar);
      reg2=getreg(($2).tempvar);
    }
    $$.tempvar = stringToCharArray(a);
//  string x86="\tsubq $16, %rsp";
//       x86_64_code.push_back(x86);
      current_local_symbol_table->curr_offset-=16;
      current_local_symbol_table->offsets[a]=current_local_symbol_table->curr_offset;
      int regs_index=current_local_symbol_table->regs_index;
      string reg3 = regs[regs_index%8];
      string x86;
      x86= "\tmovq "+reg1+", "+reg3;
      x86_64_code.push_back(x86);
      x86="\torq "+reg2+", "+reg3;
      x86_64_code.push_back(x86);
      x86 = "\tsubq $16, %rsp";
  x86_64_code.push_back(x86);
      x86="\tmovq "+reg3+", "+to_string(current_local_symbol_table->curr_offset)+"(%rbp)";
      x86_64_code.push_back(x86);
      regs_index++;
      current_local_symbol_table->regs_index=regs_index;
  }
  }
}
;
vbar: VBAR {type_error_line=yylineno;};
optional_slash_xor_expr: /*empty*/ {$$.type="";
$$.lexeme = NULL;
}
                      | optional_slash_xor_expr vbar xor_expr  {
                      $$.type=($3).type;
                      //cout<<"optional_slash_xor_expr "<<yylineno<<endl;
                      if(($1).type=="str"||($3).type=="str") {
                      type_errors[type_error_line]="Mutable operation on string on line "+to_string(type_error_line)+" not allowed";}
                      else if(($1).type!=""&&!type_correct(($1).type,($3).type)){
                        type_errors[type_error_line]="Type mismatch in | operation on line "+to_string(type_error_line);}
                      if(($1).lexeme == NULL){
                        $$.tempvar = ($3).tempvar;
                        $$.lexeme = ($3).lexeme;
                      }else{
                        // $$.lexeme = 
                        if(current_local_symbol_table->parent!=NULL && current_local_symbol_table->parent->scope == "class"){
                            string a = newtemp();
      string reg1, reg2;
      int off1, off2;
      if(($1).tempvar == NULL && ($3).tempvar == NULL){
        emit("^",charPtrToString(($1).lexeme),charPtrToString(($3).lexeme),a,-1);
        off1 = current_local_symbol_table->parent->offsets[($1).lexeme] ;
        off2 = current_local_symbol_table->parent->offsets[($3).lexeme];
      
      }else if(($3).tempvar == NULL){
        emit("^",charPtrToString(($1).lexeme),charPtrToString(($3).tempvar),a,-1);
              off1 = current_local_symbol_table->parent->offsets[($1).lexeme] ;
        off2 = current_local_symbol_table->parent->offsets[($3).tempvar];
      }else if(($1).tempvar == NULL){
        emit("^",charPtrToString(($1).tempvar),charPtrToString(($3).lexeme),a,-1);
              off1 = current_local_symbol_table->parent->offsets[($1).tempvar] ;
        off2 = current_local_symbol_table->parent->offsets[($3).lexeme];
      }else{
        emit("^",charPtrToString(($1).tempvar),charPtrToString(($3).tempvar),a,-1);
              off1 = current_local_symbol_table->parent->offsets[($1).tempvar] ;
        off2 = current_local_symbol_table->parent->offsets[($3).tempvar];
      }
      $$.tempvar = stringToCharArray(a);
      $$.lexeme = ($3).lexeme;
      current_local_symbol_table->curr_offset-=16;
      current_local_symbol_table->offsets[a]=current_local_symbol_table->curr_offset;
      current_local_symbol_table->parent->offsets[a] = current_local_symbol_table->curr_offset;
      int regs_index=current_local_symbol_table->regs_index;
      string reg3 = regs[regs_index%8];
      if(strcmp(stringToCharArray(reg3),stringToCharArray(init_reg))==0){
      reg3 = regs[regs_index%8]; 
      regs_index++;}
      string x86;
      if(off1>=0){
      x86 = "\tmovq " + to_string(off1) + "(" + init_reg + "), " + reg3;
      x86_64_code.push_back(x86);
      }
      else {
          x86 = "\tmovq " + to_string(off1) + "(%rbp), " + reg3;
      x86_64_code.push_back(x86);
      }
      if(off2>=0){
        x86 = "\torq " + to_string(off2) + "(" + init_reg + "), " + reg3;
        x86_64_code.push_back(x86);
      }
      else {
         x86 = "\torq " + to_string(off2) + "(%rbp), " + reg3;
        x86_64_code.push_back(x86);
      }
        x86 = "\tsubq $16, %rsp";
  x86_64_code.push_back(x86);
      x86="\tmovq "+reg3+", "+to_string(current_local_symbol_table->curr_offset)+"(%rbp)";
      x86_64_code.push_back(x86);
       current_local_symbol_table->regs_index=regs_index;
                        }
                        else {
                        string a = newtemp();
                        string reg1, reg2;
                        if(($1).tempvar == NULL && ($3).tempvar == NULL){
                          emit("|",charPtrToString(($1).lexeme),charPtrToString(($3).lexeme),a,-1);
                          reg1=getreg(($1).lexeme);
                          reg2=getreg(($3).lexeme);
                        }else if(($1).tempvar == NULL){
                          emit("|",charPtrToString(($1).lexeme),charPtrToString(($3).tempvar),a,-1);
                          reg1=getreg(($1).lexeme);
                          reg2=getreg(($3).tempvar);
                        }else if(($3).tempvar == NULL){
                          emit("|",charPtrToString(($1).tempvar),charPtrToString(($3).lexeme),a,-1);
                          reg1=getreg(($1).tempvar);
                          reg2=getreg(($3).lexeme);
                        }else{
                          emit("|",charPtrToString(($1).tempvar),charPtrToString(($3).tempvar),a,-1);
                          reg1=getreg(($1).tempvar);
                          reg2=getreg(($3).tempvar);
                        }
                        $$.tempvar = stringToCharArray(a);
                        $$.lexeme = ($3).lexeme; // not actually important

                        ////////X86////////
                      current_local_symbol_table->curr_offset-=16;
                      current_local_symbol_table->offsets[a]=current_local_symbol_table->curr_offset;
                      int regs_index=current_local_symbol_table->regs_index;
                      string reg3 = regs[regs_index%8];
                      string x86;
                      x86= "\tmovq "+reg1+", "+reg3;
                      x86_64_code.push_back(x86);
                      x86="\torq "+reg2+", "+reg3;
                      x86_64_code.push_back(x86);
                      x86 = "\tsubq $16, %rsp";
                      x86_64_code.push_back(x86);
                      x86="\tmovq "+reg3+", "+to_string(current_local_symbol_table->curr_offset)+"(%rbp)";
                      x86_64_code.push_back(x86);
                      regs_index++;
                      current_local_symbol_table->regs_index=regs_index;
                      }}
}
                      ;
xor_expr: and_expr optional_power_and_expr {
  $$.lexeme = ($1).lexeme; 
  $$.type=($1).type;
  //cout<<"xor_expr"<<endl;

  if(($2).type!=""&&(($1).type=="str"||($2).type=="str")) {
    type_errors[type_error_line]="Mutable operation on string on line "+to_string(type_error_line)+" not allowed";}
  else if(($2).type!=""&&($1).type!=""&&!type_correct(($1).type,($2).type)){
    type_errors[type_error_line]="Type mismatch in ^ operation on line "+to_string(type_error_line);}
  if(($2).lexeme == NULL){

    $$.tempvar = ($1).tempvar;
  }else{
    if(current_local_symbol_table->parent!=NULL && current_local_symbol_table->parent->scope=="class"){
       string a = newtemp();
    string reg1, reg2;
    int off1,off2;
    if(($1).tempvar == NULL && ($2).tempvar == NULL){
      emit("^",charPtrToString(($1).lexeme),charPtrToString(($2).lexeme),a,-1);
     off1 = current_local_symbol_table->parent->offsets[($1).lexeme];
     off2 = current_local_symbol_table->parent->offsets[($2).lexeme];
    }else if(($2).tempvar == NULL){
      emit("^",charPtrToString(($1).lexeme),charPtrToString(($2).tempvar),a,-1);
      off1 = current_local_symbol_table->parent->offsets[($1).lexeme];
     off2 = current_local_symbol_table->parent->offsets[($2).tempvar];
    }else if(($1).tempvar == NULL){
      emit("^",charPtrToString(($1).tempvar),charPtrToString(($2).lexeme),a,-1);
       off1 = current_local_symbol_table->parent->offsets[($1).tempvar];
     off2 = current_local_symbol_table->parent->offsets[($2).lexeme];
    }else{
      emit("^",charPtrToString(($1).tempvar),charPtrToString(($2).tempvar),a,-1);
      off1 = current_local_symbol_table->parent->offsets[($1).tempvar];
     off2 = current_local_symbol_table->parent->offsets[($2).tempvar];
    }
     $$.tempvar = stringToCharArray(a);
      current_local_symbol_table->curr_offset-=16;
      current_local_symbol_table->offsets[a]=current_local_symbol_table->curr_offset;
      int regs_index=current_local_symbol_table->regs_index;
      string reg3 = regs[regs_index%8];
      string x86;
      if(strcmp(stringToCharArray(reg3),stringToCharArray(init_reg))==0){
          reg3 = regs[regs_index%8]; 
          regs_index++;}
      if(off1>=0){
        x86 = "\tmovq " + to_string(off1) + "(" + init_reg + "), " + reg3;
        x86_64_code.push_back(x86);

      }
      else {
        x86 = "\tmovq " + to_string(off1) + "(%rbp), " + reg3;
        x86_64_code.push_back(x86);
      }
      if(off2>=0){
         x86 = "\txorq " + to_string(off2) + "(" + init_reg + "), " + reg3;
        x86_64_code.push_back(x86);
      }
      else {
         x86 = "\txorq " + to_string(off2) + "(%rbp), " + reg3;
        x86_64_code.push_back(x86);
      }
            x86 = "\tsubq $16, %rsp";
      x86_64_code.push_back(x86);
      x86="\tmovq "+reg3+", "+to_string(current_local_symbol_table->curr_offset)+"(%rbp)";
      x86_64_code.push_back(x86);
      regs_index++;
      current_local_symbol_table->regs_index=regs_index;
    }
else {
    string a = newtemp();
    string reg1, reg2;
    if(($1).tempvar == NULL && ($2).tempvar == NULL){
      emit("^",charPtrToString(($1).lexeme),charPtrToString(($2).lexeme),a,-1);
      reg1=getreg(($1).lexeme);
      reg2=getreg(($2).lexeme);
    }else if(($2).tempvar == NULL){
      emit("^",charPtrToString(($1).lexeme),charPtrToString(($2).tempvar),a,-1);
      reg1=getreg(($1).lexeme);
      reg2=getreg(($2).tempvar);
    }else if(($1).tempvar == NULL){
      emit("^",charPtrToString(($1).tempvar),charPtrToString(($2).lexeme),a,-1);
      reg1=getreg(($1).tempvar);
      reg2=getreg(($2).lexeme);
    }else{
      emit("^",charPtrToString(($1).tempvar),charPtrToString(($2).tempvar),a,-1);
      reg1=getreg(($1).tempvar);
      reg2=getreg(($2).tempvar);
    }
    $$.tempvar = stringToCharArray(a);
      current_local_symbol_table->curr_offset-=16;
      current_local_symbol_table->offsets[a]=current_local_symbol_table->curr_offset;
      int regs_index=current_local_symbol_table->regs_index;
      string reg3 = regs[regs_index%8];
      string x86;
      x86= "\tmovq "+reg1+", "+reg3;
      x86_64_code.push_back(x86);
      x86="\txorq "+reg2+", "+reg3;
      x86_64_code.push_back(x86);
      x86 = "\tsubq $16, %rsp";
      x86_64_code.push_back(x86);
      x86="\tmovq "+reg3+", "+to_string(current_local_symbol_table->curr_offset)+"(%rbp)";
      x86_64_code.push_back(x86);
      regs_index++;
      current_local_symbol_table->regs_index=regs_index;
  }
  }
};
powerr: POWER {type_error_line=yylineno;};
optional_power_and_expr : /*empty*/  { $$.type="";
$$.lexeme = NULL;

 }
| optional_power_and_expr powerr and_expr {
  $$.type=($3).type;
  if(($1).type=="str"||($3).type=="str") {
    type_errors[type_error_line]="Mutable operation on string on line "+to_string(type_error_line)+" not allowed";}
  else if(($1).type!=""&&!type_correct(($1).type,($3).type)){
    type_errors[type_error_line]="Type mismatch in ^ operation on line "+to_string(type_error_line);}

  /////////////////3AC/////////////////
  if(($1).lexeme == NULL){
    $$.lexeme= ($3).lexeme;
    //cout<<"optional_power_and_expr111111111111"<<endl;
      $$.tempvar = ($3).tempvar;
  }else{
    //cout<<"optional_power_and_expr22222222222222222"<<endl;
     if(current_local_symbol_table->parent!=NULL && current_local_symbol_table->parent->scope=="class"){
            string a = newtemp();
      string reg1, reg2;
      int off1, off2;
      if(($1).tempvar == NULL && ($3).tempvar == NULL){
        emit("^",charPtrToString(($1).lexeme),charPtrToString(($3).lexeme),a,-1);
        off1 = current_local_symbol_table->parent->offsets[($1).lexeme] ;
        off2 = current_local_symbol_table->parent->offsets[($3).lexeme];
      
      }else if(($3).tempvar == NULL){
        emit("^",charPtrToString(($1).lexeme),charPtrToString(($3).tempvar),a,-1);
              off1 = current_local_symbol_table->parent->offsets[($1).lexeme] ;
        off2 = current_local_symbol_table->parent->offsets[($3).tempvar];
      }else if(($1).tempvar == NULL){
        emit("^",charPtrToString(($1).tempvar),charPtrToString(($3).lexeme),a,-1);
              off1 = current_local_symbol_table->parent->offsets[($1).tempvar] ;
        off2 = current_local_symbol_table->parent->offsets[($3).lexeme];
      }else{
        emit("^",charPtrToString(($1).tempvar),charPtrToString(($3).tempvar),a,-1);
              off1 = current_local_symbol_table->parent->offsets[($1).tempvar] ;
        off2 = current_local_symbol_table->parent->offsets[($3).tempvar];
      }
      $$.tempvar = stringToCharArray(a);
      $$.lexeme = ($3).lexeme;
      current_local_symbol_table->curr_offset-=16;
      current_local_symbol_table->offsets[a]=current_local_symbol_table->curr_offset;
      current_local_symbol_table->parent->offsets[a] = current_local_symbol_table->curr_offset;
      int regs_index=current_local_symbol_table->regs_index;
      string reg3 = regs[regs_index%8];
      if(strcmp(stringToCharArray(reg3),stringToCharArray(init_reg))==0){
      reg3 = regs[regs_index%8]; 
      regs_index++;}
      string x86;
      if(off1>=0){
      x86 = "\tmovq " + to_string(off1) + "(" + init_reg + "), " + reg3;
      x86_64_code.push_back(x86);
      }
      else {
          x86 = "\tmovq " + to_string(off1) + "(%rbp), " + reg3;
      x86_64_code.push_back(x86);
      }
      if(off2>=0){
        x86 = "\txorq " + to_string(off2) + "(" + init_reg + "), " + reg3;
        x86_64_code.push_back(x86);
      }
      else {
         x86 = "\txorq " + to_string(off2) + "(%rbp), " + reg3;
        x86_64_code.push_back(x86);
      }
        x86 = "\tsubq $16, %rsp";
  x86_64_code.push_back(x86);
      x86="\tmovq "+reg3+", "+to_string(current_local_symbol_table->curr_offset)+"(%rbp)";
      x86_64_code.push_back(x86);
       current_local_symbol_table->regs_index=regs_index;
    }
    else {
      string a = newtemp();
      string reg1, reg2;
      if(($1).tempvar == NULL && ($3).tempvar == NULL){
        emit("^",charPtrToString(($1).lexeme),charPtrToString(($3).lexeme),a,-1);
        reg1=getreg(($1).lexeme);
        reg2=getreg(($3).lexeme);
      }else if(($3).tempvar == NULL){
        emit("^",charPtrToString(($1).lexeme),charPtrToString(($3).tempvar),a,-1);
        reg1=getreg(($1).lexeme);
        reg2=getreg(($3).tempvar);
      }else if(($1).tempvar == NULL){
        emit("^",charPtrToString(($1).tempvar),charPtrToString(($3).lexeme),a,-1);
        reg1=getreg(($1).tempvar);
        reg2=getreg(($3).lexeme);
      }else{
        emit("^",charPtrToString(($1).tempvar),charPtrToString(($3).tempvar),a,-1);
        reg1=getreg(($1).tempvar);
        reg2=getreg(($3).tempvar);
      }
      $$.tempvar = stringToCharArray(a);
      $$.lexeme = ($3).lexeme; // not actually important
      // string x86="\tsubq $16, %rsp";
      // x86_64_code.push_back(x86);
      current_local_symbol_table->curr_offset-=16;
      current_local_symbol_table->offsets[a]=current_local_symbol_table->curr_offset;
      int regs_index=current_local_symbol_table->regs_index;
      string reg3 = regs[regs_index%8];
      string x86;
      x86= "\tmovq "+reg1+", "+reg3;
      x86_64_code.push_back(x86);
      x86="\txorq "+reg2+", "+reg3;
      x86_64_code.push_back(x86);
      x86 = "\tsubq $16, %rsp";
  x86_64_code.push_back(x86);
      x86="\tmovq "+reg3+", "+to_string(current_local_symbol_table->curr_offset)+"(%rbp)";
      x86_64_code.push_back(x86);
      regs_index++;
      current_local_symbol_table->regs_index=regs_index;
    }
  }
};
and_expr: shift_expr optional_and_shift_expr {
 $$.lexeme = ($1).lexeme;
 $$.type=($1).type;
  //cout<<"and_expr"<<endl;

  if(($2).type!=""&&(($1).type=="str"||($2).type=="str")) {
    type_errors[type_error_line]="Mutable operation on string on line "+to_string(type_error_line)+" not allowed";}
  else if(($2).type!=""&&($1).type!=""&&!type_correct(($1).type,($2).type)){
    type_errors[type_error_line]="Type mismatch in and operation on line "+to_string(type_error_line);}
  //////////////////3AC/////////////////////
  if(($2).lexeme == NULL){
    $$.tempvar = ($1).tempvar;
  }else{
     if(current_local_symbol_table->parent!=NULL && current_local_symbol_table->parent->scope == "class"){
            string a = newtemp();
        string reg1,reg2;
        int off1,off2;
        if(($1).tempvar == NULL && ($2).tempvar == NULL){
        emit("&",charPtrToString(($1).lexeme),charPtrToString(($2).lexeme),a,-1);
       off1 = current_local_symbol_table->parent->offsets[($1).lexeme];
       off2 = current_local_symbol_table->parent->offsets[($2).lexeme];

      }else if(($1).tempvar == NULL){
        emit("&",charPtrToString(($1).lexeme),charPtrToString(($2).tempvar),a,-1);
        off1 = current_local_symbol_table->parent->offsets[($1).lexeme];
       off2 = current_local_symbol_table->parent->offsets[($2).tempvar];
      }else if(($2).tempvar == NULL){
        emit("&",charPtrToString(($1).tempvar),charPtrToString(($2).lexeme),a,-1);
 off1 = current_local_symbol_table->parent->offsets[($1).tempvar];
       off2 = current_local_symbol_table->parent->offsets[($2).lexeme];
      }else{
        emit("&",charPtrToString(($1).tempvar),charPtrToString(($2).tempvar),a,-1);
 off1 = current_local_symbol_table->parent->offsets[($1).tempvar];
       off2 = current_local_symbol_table->parent->offsets[($2).tempvar];
      }
      $$.tempvar = stringToCharArray(a);
      $$.lexeme = ($1).lexeme;
      current_local_symbol_table->curr_offset-=16;
      current_local_symbol_table->offsets[a]=current_local_symbol_table->curr_offset;
      current_local_symbol_table->parent->offsets[a] = current_local_symbol_table->curr_offset;
      int regs_index=current_local_symbol_table->regs_index;
      string reg3 = regs[regs_index%8];
      regs_index++;
      if(strcmp(stringToCharArray(reg3),stringToCharArray(init_reg))==0){
      reg3 = regs[regs_index%8]; 
      regs_index++;}
      string x86;
 if(off1>=0){
  x86 = "\tmovq " + to_string(off1) + "(" + init_reg + "), " + reg3;
  x86_64_code.push_back(x86); 
 }
 else {
  x86 = "\tmovq " + to_string(off1) + "(%rbp), " + reg3;
  x86_64_code.push_back(x86);
 }
 if(off2>=0){
  x86 = "\tandq " + to_string(off2) + "(" + init_reg + "), " + reg3;
  x86_64_code.push_back(x86);
 }
 else{
 x86 = "\tandq " + to_string(off2) + "(%rbp), " + reg3;
  x86_64_code.push_back(x86);
 }
  x86 = "\tsubq $16, %rsp";
  x86_64_code.push_back(x86);
      x86="\tmovq "+reg3+", "+to_string(current_local_symbol_table->curr_offset)+"(%rbp)";
      x86_64_code.push_back(x86);
      current_local_symbol_table->regs_index=regs_index;
    }
    else{
    string a = newtemp();
    string reg1, reg2;
    if(($1).tempvar == NULL && ($2).tempvar == NULL){
      emit("&",charPtrToString(($1).lexeme),charPtrToString(($2).lexeme),a,-1);
      reg1=getreg(($1).lexeme);
      reg2=getreg(($2).lexeme);
    }else if(($1).tempvar == NULL){
      emit("&",charPtrToString(($1).lexeme),charPtrToString(($2).tempvar),a,-1);
      reg1=getreg(($1).lexeme);
      reg2=getreg(($2).tempvar);
    }else if(($2).tempvar == NULL){
      emit("&",charPtrToString(($1).tempvar),charPtrToString(($2).lexeme),a,-1);
      reg1=getreg(($1).tempvar);
      reg2=getreg(($2).lexeme);
    }else{
      emit("&",charPtrToString(($1).tempvar),charPtrToString(($2).tempvar),a,-1);
      reg1=getreg(($1).tempvar);
      reg2=getreg(($2).tempvar);
    }
    $$.tempvar = stringToCharArray(a);
    // $$.lexeme = ($3).lexeme; // not actually important
  //  string x86="\tsubq $16, %rsp";
  //     x86_64_code.push_back(x86);
      current_local_symbol_table->curr_offset-=16;
      current_local_symbol_table->offsets[a]=current_local_symbol_table->curr_offset;
      int regs_index=current_local_symbol_table->regs_index;
      string reg3 = regs[regs_index%8];
      string x86;
      x86= "\tmovq "+reg1+", "+reg3;
      x86_64_code.push_back(x86);
      x86="\tandq "+reg2+", "+reg3;
      x86_64_code.push_back(x86);
      x86 = "\tsubq $16, %rsp";
  x86_64_code.push_back(x86);
      x86="\tmovq "+reg3+", "+to_string(current_local_symbol_table->curr_offset)+"(%rbp)";
      x86_64_code.push_back(x86);
      regs_index++;
      current_local_symbol_table->regs_index=regs_index;
  }
  }
}
 ;
amper: AMPER {type_error_line=yylineno;};
optional_and_shift_expr: /*empty*/ {$$.type="";
$$.lexeme = NULL;
}
| optional_and_shift_expr amper shift_expr {
$$.type=($3).type;
  if(($1).type=="str"||($3).type=="str") {
    type_errors[type_error_line]="Mutable operation on string on line "+to_string(type_error_line)+" not allowed";}
  else if(($1).type!=""&&!type_correct(($1).type,($3).type)){
    type_errors[type_error_line]="Type mismatch in and operation on line "+to_string(type_error_line);}
  if(($1).lexeme == NULL){
    $$.tempvar = ($3).tempvar;
    $$.lexeme = ($3).lexeme;
  }else{
      // $$.lexeme = 
       if(current_local_symbol_table->parent!=NULL && current_local_symbol_table->parent->scope == "class"){
        string a = newtemp();
        string reg1,reg2;
        int off1,off2;
        if(($1).tempvar == NULL && ($3).tempvar == NULL){
        emit("&",charPtrToString(($1).lexeme),charPtrToString(($3).lexeme),a,-1);
       off1 = current_local_symbol_table->parent->offsets[($1).lexeme];
       off2 = current_local_symbol_table->parent->offsets[($3).lexeme];

      }else if(($1).tempvar == NULL){
        emit("&",charPtrToString(($1).lexeme),charPtrToString(($3).tempvar),a,-1);
        off1 = current_local_symbol_table->parent->offsets[($1).lexeme];
       off2 = current_local_symbol_table->parent->offsets[($3).tempvar];
      }else if(($3).tempvar == NULL){
        emit("&",charPtrToString(($1).tempvar),charPtrToString(($3).lexeme),a,-1);
 off1 = current_local_symbol_table->parent->offsets[($1).tempvar];
       off2 = current_local_symbol_table->parent->offsets[($3).lexeme];
      }else{
        emit("&",charPtrToString(($1).tempvar),charPtrToString(($3).tempvar),a,-1);
 off1 = current_local_symbol_table->parent->offsets[($1).tempvar];
       off2 = current_local_symbol_table->parent->offsets[($3).tempvar];
      }
      $$.tempvar = stringToCharArray(a);
      $$.lexeme = ($3).lexeme;
      current_local_symbol_table->curr_offset-=16;
      current_local_symbol_table->offsets[a]=current_local_symbol_table->curr_offset;
      current_local_symbol_table->parent->offsets[a] = current_local_symbol_table->curr_offset;
      int regs_index=current_local_symbol_table->regs_index;
      string reg3 = regs[regs_index%8];
      regs_index++;
      if(strcmp(stringToCharArray(reg3),stringToCharArray(init_reg))==0){
      reg3 = regs[regs_index%8]; 
      regs_index++;}
      string x86;
 if(off1>=0){
  x86 = "\tmovq " + to_string(off1) + "(" + init_reg + "), " + reg3;
  x86_64_code.push_back(x86); 
 }
 else {
  x86 = "\tmovq " + to_string(off1) + "(%rbp), " + reg3;
  x86_64_code.push_back(x86);
 }
 if(off2>=0){
  x86 = "\tandq " + to_string(off2) + "(" + init_reg + "), " + reg3;
  x86_64_code.push_back(x86);
 }
 else{
 x86 = "\tandq " + to_string(off2) + "(%rbp), " + reg3;
  x86_64_code.push_back(x86);
 }
  x86 = "\tsubq $16, %rsp";
  x86_64_code.push_back(x86);
      x86="\tmovq "+reg3+", "+to_string(current_local_symbol_table->curr_offset)+"(%rbp)";
      x86_64_code.push_back(x86);
      current_local_symbol_table->regs_index=regs_index;
      }
      else{
      string a = newtemp();
      string reg1, reg2;
      if(($1).tempvar == NULL && ($3).tempvar == NULL){
        emit("&",charPtrToString(($1).lexeme),charPtrToString(($3).lexeme),a,-1);
        reg1=getreg(($1).lexeme);
        reg2=getreg(($3).lexeme);
      }else if(($1).tempvar == NULL){
        emit("&",charPtrToString(($1).lexeme),charPtrToString(($3).tempvar),a,-1);
        reg1=getreg(($1).lexeme);
        reg2=getreg(($3).tempvar);
      }else if(($3).tempvar == NULL){
        emit("&",charPtrToString(($1).tempvar),charPtrToString(($3).lexeme),a,-1);
        reg1=getreg(($1).tempvar);
        reg2=getreg(($3).lexeme);
      }else{
        emit("&",charPtrToString(($1).tempvar),charPtrToString(($3).tempvar),a,-1);
        reg1=getreg(($1).tempvar);
        reg2=getreg(($3).tempvar);
      }
      $$.tempvar = stringToCharArray(a);
      $$.lexeme = ($3).lexeme; // not actually important
    // string x86="\tsubq $16, %rsp";
    //   x86_64_code.push_back(x86);
      current_local_symbol_table->curr_offset-=16;
      current_local_symbol_table->offsets[a]=current_local_symbol_table->curr_offset;
      int regs_index=current_local_symbol_table->regs_index;
      string reg3 = regs[regs_index%8];
      string x86;
      x86= "\tmovq "+reg1+", "+reg3;
      x86_64_code.push_back(x86);
      x86="\tandq "+reg2+", "+reg3;
      x86_64_code.push_back(x86);
      x86 = "\tsubq $16, %rsp";
  x86_64_code.push_back(x86);
      x86="\tmovq "+reg3+", "+to_string(current_local_symbol_table->curr_offset)+"(%rbp)";
      x86_64_code.push_back(x86);
      regs_index++;
      current_local_symbol_table->regs_index=regs_index;
    }}
}
;
shift_expr: arith_expr optional_shift_operators_arith_expr {
 $$.lexeme = ($1).lexeme; 
 $$.type=($1).type;
  //cout<<"shift_expr"<<endl;

  if(($2).type!=""&&(($1).type=="str"||($2).type=="str")) {
    type_errors[type_error_line]="Mutable operation on string on line "+to_string(type_error_line)+" not allowed";}
  else if(($2).type!=""&&($1).type!=""&&!type_correct(($1).type,($2).type)){
    type_errors[type_error_line]="Type mismatch in shift operation on line "+to_string(type_error_line);}
  ////////////////3AC///////////////
  if(($2).lexeme == NULL){
    $$.tempvar = ($1).tempvar;
  }else{
    if(current_local_symbol_table->parent!=NULL && current_local_symbol_table->parent->scope=="class"){
        string op = charPtrToString(($2).op);
      string a = newtemp();
      int off1, off2;
      if(($1).tempvar == NULL && ($2).tempvar == NULL){
        emit(op,charPtrToString(($1).lexeme),charPtrToString(($2).lexeme),a,-1);
        off1 = current_local_symbol_table->parent->offsets[($1).lexeme];
        off2 = current_local_symbol_table->parent->offsets[($2).lexeme];

      }else if(($2).tempvar == NULL){
        emit(op,charPtrToString(($1).lexeme),charPtrToString(($2).tempvar),a,-1);
        off1 = current_local_symbol_table->parent->offsets[($1).lexeme];
        off2 = current_local_symbol_table->parent->offsets[($2).tempvar];

      }else if(($1).tempvar == NULL){
        emit(op,charPtrToString(($1).tempvar),charPtrToString(($2).lexeme),a,-1);
        off1 = current_local_symbol_table->parent->offsets[($1).tempvar];
        off2 = current_local_symbol_table->parent->offsets[($2).lexeme];

      }else{
        emit(op,charPtrToString(($1).tempvar),charPtrToString(($2).tempvar),a,-1);
     off1 = current_local_symbol_table->parent->offsets[($1).tempvar];
        off2 = current_local_symbol_table->parent->offsets[($2).tempvar];

        }
        current_local_symbol_table->curr_offset-=16;
      current_local_symbol_table->offsets[a]=current_local_symbol_table->curr_offset;
      current_local_symbol_table->parent->offsets[a]=current_local_symbol_table->curr_offset;
   int regs_index = current_local_symbol_table->regs_index;
      string reg3 = regs[regs_index%8];
      regs_index++;
      string x86;
$$.tempvar = stringToCharArray(a);
$$.lexeme = ($1).lexeme;
string lex = charPtrToString(($2).lexeme);
 if(strcmp(stringToCharArray(reg3),stringToCharArray(init_reg))==0){
      reg3 = regs[regs_index%8]; 
      regs_index++;}
       x86;
      if(charPtrToString(($2).op)=="<<"){
          if(off1>=0){
      x86 = "\tmovq " +to_string(off1) + "(" + init_reg + "), "+reg3;
      x86_64_code.push_back(x86);}
      else{
      x86 = "\tmovq " +to_string(off1) + "(%rbp), "+reg3;
      x86_64_code.push_back(x86);}
      if(off2>=0){
      x86 = "\tshlq $" + lex + ", " + reg3;
      x86_64_code.push_back(x86);}
      else{
      x86 = "\tshlq $" + lex + ", " + reg3;
      x86_64_code.push_back(x86);
      }
      }
      else {
           if(off1>=0){
      x86 = "\tmovq " +to_string(off1) + "(" + init_reg + "), "+reg3;
      x86_64_code.push_back(x86);}
      else{
      x86 = "\tmovq " +to_string(off1) + "(%rbp), "+reg3;
      x86_64_code.push_back(x86);}
      if(off2>=0){
      x86 = "\tshrq " + lex + "), " + reg3;
      x86_64_code.push_back(x86);}
      else{
      x86 = "\tshrq " + lex + ", " + reg3;
      x86_64_code.push_back(x86);
      }
      }
       x86 = "\tsubq $16, %rsp";
  x86_64_code.push_back(x86);
        x86="\tmovq "+reg3+", "+to_string(current_local_symbol_table->curr_offset)+"(%rbp)";
      x86_64_code.push_back(x86);
      current_local_symbol_table->regs_index=regs_index;
    }
    else {
    string a = newtemp();
    string op = charPtrToString(($2).op);
    string reg1, reg2;
    if(($1).tempvar == NULL && ($2).tempvar == NULL){
      emit(op,charPtrToString(($1).lexeme),charPtrToString(($2).lexeme),a,-1);
      reg1=getreg(($1).lexeme);
      reg2=getreg(($2).lexeme);
    }else if(($1).tempvar == NULL){
      emit(op,charPtrToString(($1).lexeme),charPtrToString(($2).tempvar),a,-1);
      reg1=getreg(($1).lexeme);
      reg2=getreg(($2).tempvar);
    }else if(($2).tempvar == NULL){
      emit(op,charPtrToString(($1).tempvar),charPtrToString(($2).lexeme),a,-1);
      reg1=getreg(($1).tempvar);
      reg2=getreg(($2).lexeme);
    }else{
      emit(op,charPtrToString(($1).tempvar),charPtrToString(($2).tempvar),a,-1);
      reg1=getreg(($1).tempvar);
      reg2=getreg(($2).tempvar);
    }
    $$.tempvar = stringToCharArray(a);
// $$.lexeme = ($1).lexeme; // not actually important
  //  string x86="\tsubq $16, %rsp";
  //     x86_64_code.push_back(x86);
      current_local_symbol_table->curr_offset-=16;
      current_local_symbol_table->offsets[a]=current_local_symbol_table->curr_offset;
    int regs_index=current_local_symbol_table->regs_index;
    string reg3=regs[regs_index%8];
    // int off=get_offset(current_local_symbol_table->register_descriptor[reg3][0]);
    // x86="\tmovq "+reg3+", "+to_string(off)+"(%rbp)";
    // x86_64_code.push_back(x86);
    // regs_index++;
    // current_local_symbol_table->regs_index=regs_index;
    string x86;
    string lex = charPtrToString(($2).lexeme);
      if(charPtrToString(($2).op)=="<<"){
        x86="\tmovq "+reg1+", "+reg3;
        x86_64_code.push_back(x86);
        x86="\tshlq $"+lex+", "+reg3;
        x86_64_code.push_back(x86);
        x86 = "\tsubq $16, %rsp";
  x86_64_code.push_back(x86);
        x86="\tmovq "+reg3+", "+to_string(current_local_symbol_table->curr_offset)+"(%rbp)";
      x86_64_code.push_back(x86);
      }
      else{
        x86="\tmovq "+reg1+", "+reg3;
        x86_64_code.push_back(x86);
        x86="\tshrq $"+lex+", "+reg3;
        x86_64_code.push_back(x86);
        x86 = "\tsubq $16, %rsp";
  x86_64_code.push_back(x86);
        x86="\tmovq "+reg3+", "+to_string(current_local_symbol_table->curr_offset)+"(%rbp)";
      x86_64_code.push_back(x86);
      }
      regs_index++;
      current_local_symbol_table->regs_index=regs_index;
  }
  }
}  ; 
optional_shift_operators_arith_expr: /*empty*/ {$$.type="";
$$.lexeme = NULL;
}
| optional_shift_operators_arith_expr shift_operators arith_expr {
  $$.type=($3).type;
  if(($1).type=="str"||($3).type=="str") {
    type_errors[type_error_line]="Mutable operation on string on line "+to_string(type_error_line)+" not allowed";}
  else if(($1).type!=""&&!type_correct(($1).type,($3).type)){
    type_errors[type_error_line]="Type mismatch in shift operation on line "+to_string(type_error_line);}
  if(($1).lexeme == NULL){
      $$.tempvar = ($3).tempvar;
      $$.lexeme = ($3).lexeme;
      $$.op = ($2).op;
    }else{
      // $$.lexeme = 
      if(current_local_symbol_table->parent!=NULL && current_local_symbol_table->parent->scope == "class"){
       string op = charPtrToString(($2).op);
      string a = newtemp();
      int off1, off2;
      if(($1).tempvar == NULL && ($3).tempvar == NULL){
        emit(op,charPtrToString(($1).lexeme),charPtrToString(($3).lexeme),a,-1);
        off1 = current_local_symbol_table->parent->offsets[($1).lexeme];
        off2 = current_local_symbol_table->parent->offsets[($3).lexeme];

      }else if(($3).tempvar == NULL){
        emit(op,charPtrToString(($1).lexeme),charPtrToString(($3).tempvar),a,-1);
        off1 = current_local_symbol_table->parent->offsets[($1).lexeme];
        off2 = current_local_symbol_table->parent->offsets[($3).tempvar];

      }else if(($1).tempvar == NULL){
        emit(op,charPtrToString(($1).tempvar),charPtrToString(($3).lexeme),a,-1);
        off1 = current_local_symbol_table->parent->offsets[($1).tempvar];
        off2 = current_local_symbol_table->parent->offsets[($3).lexeme];

      }else{
        emit(op,charPtrToString(($1).tempvar),charPtrToString(($3).tempvar),a,-1);
     off1 = current_local_symbol_table->parent->offsets[($1).tempvar];
        off2 = current_local_symbol_table->parent->offsets[($2).tempvar];

        }
        current_local_symbol_table->curr_offset-=16;
      current_local_symbol_table->offsets[a]=current_local_symbol_table->curr_offset;
      current_local_symbol_table->parent->offsets[a]=current_local_symbol_table->curr_offset;
   int regs_index = current_local_symbol_table->regs_index;
      string reg3 = regs[regs_index%8];
      regs_index++;
      string x86;
      string lex = charPtrToString(($3).lexeme);
 if(strcmp(stringToCharArray(reg3),stringToCharArray(init_reg))==0){
      reg3 = regs[regs_index%8]; 
      regs_index++;}
       
      if(charPtrToString(($2).op)=="<<"){
          if(off1>=0){
      x86 = "\tmovq " +to_string(off1) + "(" + init_reg + "), "+reg3;
      x86_64_code.push_back(x86);}
      else{
      x86 = "\tmovq " +to_string(off1) + "(%rbp), "+reg3;
      x86_64_code.push_back(x86);}
      if(off2>=0){
      x86 = "\tshlq $"+ lex+", " + reg3;
      x86_64_code.push_back(x86);}
      else{
      x86 = "\tshlq $"+lex+", " + reg3;
      x86_64_code.push_back(x86);
      }
      }
      else {
        if(strcmp(stringToCharArray(reg3),stringToCharArray(init_reg))==0){
          reg3 = regs[regs_index%8]; 
          regs_index++;}
           if(off1>=0){
      x86 = "\tmovq " +to_string(off1) + "(" + init_reg + "), "+reg3;
      x86_64_code.push_back(x86);}
      else{
      x86 = "\tmovq " +to_string(off1) + "(%rbp), "+reg3;
      x86_64_code.push_back(x86);}
      if(off2>=0){
      x86 = "\tshrq " + lex+ ", " + reg3;
      x86_64_code.push_back(x86);}
      else{
      x86 = "\tshrq " +lex+", " + reg3;
      x86_64_code.push_back(x86);
      }
      }
       x86 = "\tsubq $16, %rsp";
  x86_64_code.push_back(x86);
        x86="\tmovq "+reg3+", "+to_string(current_local_symbol_table->curr_offset)+"(%rbp)";
      x86_64_code.push_back(x86);
      current_local_symbol_table->regs_index=regs_index;
      }
      else {
      string op = charPtrToString(($2).op);
      string a = newtemp();
      string reg1, reg2;
      if(($1).tempvar == NULL && ($3).tempvar == NULL){
        emit(op,charPtrToString(($1).lexeme),charPtrToString(($3).lexeme),a,-1);
        reg1=getreg(($1).lexeme);
        reg2=getreg(($3).lexeme);
      }else if(($3).tempvar == NULL){
        emit(op,charPtrToString(($1).lexeme),charPtrToString(($3).tempvar),a,-1);
        reg1=getreg(($1).lexeme);
        reg2=getreg(($3).tempvar);
      }else if(($1).tempvar == NULL){
        emit(op,charPtrToString(($1).tempvar),charPtrToString(($3).lexeme),a,-1);
        reg1=getreg(($1).tempvar);
        reg2=getreg(($3).lexeme);
      }else{
        emit(op,charPtrToString(($1).tempvar),charPtrToString(($3).tempvar),a,-1);
        reg1=getreg(($1).tempvar);
        reg2=getreg(($3).tempvar);}
      $$.tempvar = stringToCharArray(a);
      $$.lexeme = ($3).lexeme; // not actually important
      // string x86="\tsubq $16, %rsp";
      // x86_64_code.push_back(x86);
      current_local_symbol_table->curr_offset-=16;
      current_local_symbol_table->offsets[a]=current_local_symbol_table->curr_offset;
      int regs_index=current_local_symbol_table->regs_index;
    string reg3=regs[regs_index%8];
    string x86;
    string lex = charPtrToString(($3).lexeme);
      if(charPtrToString(($2).op)=="<<"){
        x86="\tmovq "+reg1+", "+reg3;
        x86_64_code.push_back(x86);
        x86="\tshlq $"+lex+", "+reg3;
        x86_64_code.push_back(x86);
        x86 = "\tsubq $16, %rsp";
  x86_64_code.push_back(x86);
        x86="\tmovq "+reg3+", "+to_string(current_local_symbol_table->curr_offset)+"(%rbp)";
      x86_64_code.push_back(x86);
      }
      else{
        x86="\tmovq "+reg1+", "+reg3;
        x86_64_code.push_back(x86);
        x86="\tshrq $"+lex+", "+reg3;
        x86_64_code.push_back(x86);
        x86 = "\tsubq $16, %rsp";
  x86_64_code.push_back(x86);
        x86="\tmovq "+reg3+", "+to_string(current_local_symbol_table->curr_offset)+"(%rbp)";
      x86_64_code.push_back(x86);
      }
      regs_index++;
      current_local_symbol_table->regs_index=regs_index;
    }
  }
}
;
shift_operators: LEFTSHIFT  {type_error_line=yylineno;
$$.op=$1;}
       |RIGHTSHIFT  {type_error_line=yylineno;
$$.op = $1;
};
arith_expr: term optional_plus_minus_term{
  $$.lexeme = ($1).lexeme;
  $$.type=($1).type;
  cout<<"arith_expr_self1"<<" "<<$$.lexeme<<" "<<endl;

  if(($2).type!="" && (($2).type=="str"||($1).type=="str")) {
    type_errors[type_error_line]="Mutable operation on string on line "+to_string(type_error_line)+" not allowed";}
  else if(($2).type!="" && $$.type!="" && !type_correct($$.type,($2).type)){
    //cout<<"///////////+++++++++++/////////"<<$$.type<<" "<<($2).type<<endl;
    type_errors[type_error_line]="Type mismatch in addition/subtraction on line "+to_string(type_error_line);}
  ////////////////3AC///////////////////
    if(current_local_symbol_table->parent!=NULL && current_local_symbol_table->parent->scope == "class"){
    cout<<"in class"<<yylineno<<endl;
    if(($2).lexeme!=NULL){
      string a = newtemp();
      $$.tempvar = stringToCharArray(a);
      $$.lexeme = ($1).lexeme;
    string op = charPtrToString(($2).op);
      int off1,off2;
      cout<<"yes here"<<endl;
      cout<<current_local_symbol_table->parent->offsets[($2).lexeme]<<" "<<($1).lexeme<<" "<<init_reg<<endl;;
      if(($1).tempvar==NULL && ($2).tempvar==NULL)
      {
        // cout<<"here??"<<endl;
        emit(op,charPtrToString(($1).lexeme),charPtrToString(($2).lexeme),a,-1);
        off1 = current_local_symbol_table->parent->offsets[($1).lexeme];
        off2 = current_local_symbol_table->parent->offsets[($2).lexeme];

      }    
      else if(($1).tempvar==NULL){
          emit(op,charPtrToString(($1).lexeme),charPtrToString(($2).tempvar),a,-1);
            off1 = current_local_symbol_table->parent->offsets[($1).lexeme];
            off2 = current_local_symbol_table->parent->offsets[($2).tempvar];
      }  
      else if(($2).tempvar == NULL){
          emit(op,charPtrToString(($1).tempvar),charPtrToString(($2).lexeme),a,-1);
            off1 = current_local_symbol_table->parent->offsets[($1).tempvar];
            off2 = current_local_symbol_table->parent->offsets[($2).lexeme];
      }
      else {
          emit(op,charPtrToString(($1).tempvar),charPtrToString(($2).tempvar),a,-1);
            off1 = current_local_symbol_table->parent->offsets[($1).tempvar];
            off2 = current_local_symbol_table->parent->offsets[($2).tempvar];
      }
      cout<<"offsets=="<<off1<<" "<<off2<<endl;
      cout<<"offsets=="<<off1<<" "<<off2<<endl;
      current_local_symbol_table->curr_offset-=16;
      current_local_symbol_table->offsets[a]=current_local_symbol_table->curr_offset;
      current_local_symbol_table->parent->offsets[a]=current_local_symbol_table->curr_offset;
   

      int regs_index = current_local_symbol_table->regs_index;
      string reg3 = regs[regs_index%8];
      regs_index++;
      string x86;

 if(strcmp(stringToCharArray(reg3),stringToCharArray(init_reg))==0){
      reg3 = regs[regs_index%8]; 
      regs_index++;}
    if(charPtrToString(($2).op)=="+"){
      if(off1>=0){
      x86 = "\tmovq " +to_string(off1) + "(" + init_reg + "), "+reg3;
      x86_64_code.push_back(x86);}
      else{
      x86 = "\tmovq " +to_string(off1) + "(%rbp), "+reg3;
      x86_64_code.push_back(x86);}
      if(off2>=0){
      x86 = "\taddq " + to_string(off2) + "(" + init_reg + "), " + reg3;
      x86_64_code.push_back(x86);}
      else{
      x86 = "\taddq " + to_string(off2) + "(%rbp), " + reg3;
      x86_64_code.push_back(x86);
      }
 
      x86 = "\tsubq $16, %rsp";
      x86_64_code.push_back(x86);
      x86="\tmovq "+reg3+", "+to_string(current_local_symbol_table->curr_offset)+"(%rbp)";
      x86_64_code.push_back(x86);
    }
    else{
      if(strcmp(stringToCharArray(reg3),stringToCharArray(init_reg))==0){
          reg3 = regs[regs_index%8]; 
          regs_index++;}
        if(off1>=0){
      x86 = "\tmovq " +to_string(off1) + "(" + init_reg + "), "+reg3;
      x86_64_code.push_back(x86);}
      else{
      x86 = "\tmovq " +to_string(off1) + "(%rbp), "+reg3;
      x86_64_code.push_back(x86);}
      if(off2>=0){
      x86 = "\taddq " + to_string(off2) + "(" + init_reg + "), " + reg3;
      x86_64_code.push_back(x86);}
      else{
      x86 = "\taddq " + to_string(off2) + "(%rbp), " + reg3;
      x86_64_code.push_back(x86);
      }
 
 
        x86 = "\tsubq $16, %rsp";
        x86_64_code.push_back(x86);
        x86="\tmovq "+reg3+", "+to_string(current_local_symbol_table->curr_offset)+"(%rbp)";
        x86_64_code.push_back(x86);
    }
    current_local_symbol_table->regs_index = regs_index;
    }
    else{
      $$.tempvar = ($1).tempvar;
    }

  }
  else{ 
  if(($2).lexeme != NULL){
    string a = newtemp();
    // string op = "";
    string op = charPtrToString(($2).op);
    //cout<<"arith_exprrrrr"<<endl;
    string reg1, reg2;
    if(($1).tempvar == NULL && ($2).tempvar == NULL){
      emit(op,charPtrToString(($1).lexeme),charPtrToString(($2).lexeme),a,-1);
      reg1=getreg(($1).lexeme);
      reg2=getreg(($2).lexeme);
    }else if(($1).tempvar == NULL){
      emit(op,charPtrToString(($1).lexeme),charPtrToString(($2).tempvar),a,-1);
      reg1=getreg(($1).lexeme);
      reg2=getreg(($2).tempvar);
    }else if(($2).tempvar == NULL){
      emit(op,charPtrToString(($1).tempvar),charPtrToString(($2).lexeme),a,-1);
      reg1=getreg(($1).tempvar);
      reg2=getreg(($2).lexeme);
    }else{
      emit(op,charPtrToString(($1).tempvar),charPtrToString(($2).tempvar),a,-1);
      reg1=getreg(($1).tempvar);
      reg2=getreg(($2).tempvar);
    }
    $$.tempvar = stringToCharArray(a);
    $$.lexeme = ($1).lexeme; // not actually important
    string x86;
    current_local_symbol_table->curr_offset-=16;
    current_local_symbol_table->offsets[a]=current_local_symbol_table->curr_offset;
    int regs_index=current_local_symbol_table->regs_index;
    string reg3=regs[regs_index%8];
  if(charPtrToString(($2).op)=="+"){
    x86="\tmovq "+reg1+", "+reg3;
    x86_64_code.push_back(x86);
    x86="\taddq "+reg2+", "+reg3;
    x86_64_code.push_back(x86);
    x86 = "\tsubq $16, %rsp";
    x86_64_code.push_back(x86);
    x86="\tmovq "+reg3+", "+to_string(current_local_symbol_table->curr_offset)+"(%rbp)";
    x86_64_code.push_back(x86);
  }
  else{
    x86="\tmovq "+reg1+", "+reg3;
    x86_64_code.push_back(x86);
    x86="\tsubq "+reg2+", "+reg3;
    x86_64_code.push_back(x86);
    x86 = "\tsubq $16, %rsp";
    x86_64_code.push_back(x86);
    x86="\tmovq "+reg3+", "+to_string(current_local_symbol_table->curr_offset)+"(%rbp)";
    x86_64_code.push_back(x86);}
    regs_index++;
    current_local_symbol_table->regs_index=regs_index;
  }else{
       $$.tempvar = ($1).tempvar;  
  }    
  }

}
;
optional_plus_minus_term: /*empty*/ {
  $$.type="";
  $$.lexeme = NULL;
}
| optional_plus_minus_term plus_minus term {
  $$.type=($3).type;
  cout<<"optional_plus_minus_term "<<endl;
  if(($3).type=="str"||($1).type=="str") {
    type_errors[type_error_line]="Mutable operation on string on line "+to_string(type_error_line)+" not allowed";}
  else if(($1).type!=""&&!type_correct($$.type,($1).type)){
    //cout<<"optional_plus_minus_term "<<$$.type<<" "<<($1).type<<endl;
    type_errors[type_error_line]="Type mismatch in addition/subtraction on line "+to_string(type_error_line);}
    //////////////////3AC////////////////////
    if(current_local_symbol_table->parent!=NULL && current_local_symbol_table->parent->scope=="class"){
      cout<<"not null"<<endl;
      if(($1).lexeme == NULL){
    $$.lexeme = ($3).lexeme;
    $$.tempvar = ($3).tempvar;
    $$.op = ($2).lexeme;
    cout<<"lexeme null"<<endl;
  }  
  else{
    cout<<"here??"<<endl;
    string a = newtemp();
      $$.tempvar = stringToCharArray(a);
      $$.lexeme = ($3).lexeme;
    string op = charPtrToString(($2).op);
      int off1,off2;
      cout<<"yes here"<<endl;

      // cout<<current_local_symbol_table->parent->offsets[($2).lexeme]<<" "<<($1).lexeme<<" "<<init_reg<<endl;;
      if(($1).tempvar==NULL && ($3).tempvar==NULL)
      {
        // cout<<"here??"<<endl;
        emit(op,charPtrToString(($1).lexeme),charPtrToString(($3).lexeme),a,-1);
        off1 = current_local_symbol_table->parent->offsets[($1).lexeme];
        off2 = current_local_symbol_table->parent->offsets[($3).lexeme];

      }    
      else if(($1).tempvar==NULL){
          emit(op,charPtrToString(($1).lexeme),charPtrToString(($3).tempvar),a,-1);
            off1 = current_local_symbol_table->parent->offsets[($1).lexeme];
            off2 = current_local_symbol_table->parent->offsets[($3).tempvar];
      }  
      else if(($3).tempvar == NULL){
          emit(op,charPtrToString(($1).tempvar),charPtrToString(($3).lexeme),a,-1);
            off1 = current_local_symbol_table->parent->offsets[($1).tempvar];
            off2 = current_local_symbol_table->parent->offsets[($3).lexeme];
      }
      else {
          emit(op,charPtrToString(($1).tempvar),charPtrToString(($3).tempvar),a,-1);
            off1 = current_local_symbol_table->parent->offsets[($1).tempvar];
            off2 = current_local_symbol_table->parent->offsets[($3).tempvar];
      }
      string x86;
      current_local_symbol_table->curr_offset-=16;
      current_local_symbol_table->offsets[a]=current_local_symbol_table->curr_offset;
      current_local_symbol_table->parent->offsets[a] = current_local_symbol_table->curr_offset;
      int regs_index = current_local_symbol_table->regs_index;
      string reg3 = regs[regs_index%8];
      regs_index++;
       if(strcmp(stringToCharArray(reg3),stringToCharArray(init_reg))==0){
      reg3 = regs[regs_index%8]; 
      regs_index++;}
       if(charPtrToString(($2).op)=="+"){
      if(off1>=0){
      x86 = "\tmovq " +to_string(off1) + "(" + init_reg + "), "+reg3;
      x86_64_code.push_back(x86);
      }
      else {
             x86 = "\tmovq " +to_string(off1) + "(%rbp), "+reg3;
      x86_64_code.push_back(x86);
      }
      if(off2>=0){
      x86 = "\taddq " + to_string(off2) + "(" + init_reg + "), " + reg3;
      x86_64_code.push_back(x86);}
      else{
          x86 = "\taddq " + to_string(off2) + "(%rbp), " + reg3;
      x86_64_code.push_back(x86);
      }
 
      x86 = "\tsubq $16, %rsp";
      x86_64_code.push_back(x86);
      x86="\tmovq "+reg3+", "+to_string(current_local_symbol_table->curr_offset)+"(%rbp)";
      x86_64_code.push_back(x86);
    }
    else{
      if(off1>=0){
        x86 = "\tmovq " +to_string(off1) + "(" + init_reg + "), "+reg3;
        x86_64_code.push_back(x86);
      }
      else {
           x86 = "\tmovq " +to_string(off1) + "(%rbp), "+reg3;
        x86_64_code.push_back(x86);
      }
      if(off1>=0){
        x86 = "\tsubq " + to_string(off2) + "(" + init_reg + "), " + reg3;
        x86_64_code.push_back(x86);
      }
      else {
         x86 = "\tsubq " + to_string(off2) + "(%rbp), " + reg3;
        x86_64_code.push_back(x86);
      }
 
        x86 = "\tsubq $16, %rsp";
        x86_64_code.push_back(x86);
        x86="\tmovq "+reg3+", "+to_string(current_local_symbol_table->curr_offset)+"(%rbp)";
        x86_64_code.push_back(x86);
    }
     current_local_symbol_table->regs_index = regs_index; 
  }
    }
    else{
  if(($1).lexeme == NULL){
    $$.lexeme = ($3).lexeme;
    $$.tempvar = ($3).tempvar;
    $$.op = ($2).lexeme;
  }   
  else{
    string a = newtemp();
    string op = charPtrToString(($2).lexeme);
    string reg1, reg2;                    
    if(($1).tempvar == NULL && ($3).tempvar == NULL){
      emit(op,charPtrToString(($1).lexeme),charPtrToString(($3).lexeme),a,-1);
      reg1=getreg(($1).lexeme);
      reg2=getreg(($3).lexeme);
    }else if(($1).tempvar == NULL){
      emit(op,charPtrToString(($1).lexeme),charPtrToString(($3).tempvar),a,-1);
      reg1=getreg(($1).lexeme);
      reg2=getreg(($3).tempvar);
    }else if(($3).tempvar == NULL){
      emit(op,charPtrToString(($1).tempvar),charPtrToString(($3).lexeme),a,-1);
      reg1=getreg(($1).tempvar);
      reg2=getreg(($3).lexeme);
    }else{
      emit(op,charPtrToString(($1).tempvar),charPtrToString(($3).tempvar),a,-1);
      reg1=getreg(($1).tempvar);
      reg2=getreg(($3).tempvar);
    }
    $$.tempvar = stringToCharArray(a);
    $$.lexeme = ($3).lexeme; // not actually important
  // cout<<"hHEEEEEEEEEEEEEEELLLLLLLLLLLLLLLLOOOOOOOOOOO3"<<endl;
  string x86;
  // x86="\tsubq $16, %rsp";
  // x86_64_code.push_back(x86);
  current_local_symbol_table->curr_offset-=16;
  current_local_symbol_table->offsets[a]=current_local_symbol_table->curr_offset;
  int regs_index=current_local_symbol_table->regs_index;
    string reg3=regs[regs_index%8];
  if(charPtrToString(($2).lexeme)=="+"){
    x86="\tmovq "+reg1+", "+reg3;
    x86_64_code.push_back(x86);
    x86="\taddq "+reg2+", "+reg3;
    x86_64_code.push_back(x86);
    x86 = "\tsubq $16, %rsp";
    x86_64_code.push_back(x86);
    x86="\tmovq "+reg3+", "+to_string(current_local_symbol_table->curr_offset)+"(%rbp)";
    x86_64_code.push_back(x86);
  }
  else{
    x86="\tmovq "+reg1+", "+reg3;
    x86_64_code.push_back(x86);
    x86="\tsubq "+reg2+", "+reg3;
    x86_64_code.push_back(x86);
    x86 = "\tsubq $16, %rsp";
    x86_64_code.push_back(x86);
    x86="\tmovq "+reg3+", "+to_string(current_local_symbol_table->curr_offset)+"(%rbp)";
    x86_64_code.push_back(x86);}
    regs_index++;
    current_local_symbol_table->regs_index=regs_index;
  }   
    }
cout<<"optional pus minus term end"<<endl;
}
;
plus_minus: PLUS {type_error_line=yylineno;
  $$.lexeme = $1;
  $$.op = $1;}
     |MINUS  {
      //cout<<"plus_minus "<<yylineno<<endl; 
      type_error_line=yylineno;
     $$.lexeme = $1;
     $$.op = $1;};


term: factor optional_operators_factor { 
  $$.lexeme = ($1).lexeme;
  $$.type=($1).type;
  //cout<<"term1 "<<$$.type<<endl;
  if(($2).lexeme==NULL ) {
    $$.tempvar = ($1).tempvar;
  }
  if(($2).lexeme!=NULL&&strcmp(($2).lexeme,"len")==0) {
    //cout<<"strcmp "<<($2).lexeme<<endl;
    ($2).type="int";
  }
  //cout<<"term1 "<<$$.type<<endl;
  if(($2).type=="str"||($1).type=="str") {
  type_errors[type_error_line]="Mutable operation on string on line "+to_string(type_error_line)+" not allowed";}
  else if(!type_correct($$.type,($2).type)){
    //cout<<"term "<<$$.type<<" "<<($2).type<<endl;
    type_errors[type_error_line]="Type mismatch in multiplication/division on line "+to_string(type_error_line);}
  //cout<<"term1 "<<$$.type<<endl;
  ///////////////////3AC///////////////////
  if(($2).lexeme != NULL){
        if(current_local_symbol_table->parent!=NULL && current_local_symbol_table->parent->scope == "class"){
        cout<<"inclass"<<endl;
        string a = newtemp();
        string op = charPtrToString(($2).op);
        int off1, off2;
        if(($1).tempvar == NULL && ($2).tempvar == NULL){
            off1 = current_local_symbol_table->parent->offsets[($1).lexeme];
            off2 = current_local_symbol_table->parent->offsets[($2).lexeme];
        }
        else  if(($1).tempvar == NULL){
            off1 = current_local_symbol_table->parent->offsets[($1).lexeme];
            off2 = current_local_symbol_table->parent->offsets[($2).tempvar];
        }
        else if(($2).tempvar == NULL){
            off1 = current_local_symbol_table->parent->offsets[($1).tempvar];
            off2 = current_local_symbol_table->parent->offsets[($2).lexeme];

        }
        else {
            off1 = current_local_symbol_table->parent->offsets[($1).tempvar];
            off2 = current_local_symbol_table->parent->offsets[($2).tempvar];
        }
        $$.tempvar = stringToCharArray(a);
        $$.op = ($2).op;
        string x86;
        current_local_symbol_table->curr_offset-=16;
        current_local_symbol_table->offsets[a]=current_local_symbol_table->curr_offset;
        int regs_index=current_local_symbol_table->regs_index;
        string reg3=regs[regs_index%8];
        regs_index++;
        if(strcmp(stringToCharArray(reg3),stringToCharArray(init_reg))==0){
          reg3 = regs[regs_index%8]; 
          regs_index++;
        }
      if(charPtrToString(($2).op)=="*"){
        if(off1>=0){
        x86 = "\tmovq" + to_string(off1) + "(" + init_reg + "), " + reg3;
x86_64_code.push_back(x86);}
else{
  x86 = "\tmovq " +to_string(off1) + "(%rbp), "+reg3;
      x86_64_code.push_back(x86);
}
if(off2>=0){
x86 = "\timulq " + to_string(off2) + "(" + init_reg + "), " + reg3;
x86_64_code.push_back(x86);}
else{
      x86 = "\timulq " + to_string(off2) + "(%rbp), " + reg3;
      x86_64_code.push_back(x86);
      }
      }
           else if(charPtrToString(($2).op) == "/"){
            if(off1>=0){
        x86 = "\tmovq " + to_string(off1) + "(" + init_reg + ")" + ", %rax";
        x86_64_code.push_back(x86);
            }
            else {
               x86 = "\tmovq " +to_string(off1) + "(%rbp), "+reg3;
      x86_64_code.push_back(x86);
            }
    x86="\tmovq $0, %rdx";
    x86_64_code.push_back(x86);
    if(off2>=0){
    x86 = "\tidivq " + to_string(off2) +"(" + init_reg + ")" ;
    x86_64_code.push_back(x86);}
    else {
       x86 = "\tidivq " + to_string(off2) +"(%rbp)" ;
    x86_64_code.push_back(x86);
    }
x86="\tmovq %rax, "+reg3;
    x86_64_code.push_back(x86);
      }
      else if(charPtrToString(($2).op)=="%"){
        if(off1>=0){
          x86 = "\tmovq " + to_string(off1) + "(" + init_reg + ")" + ", %rax";
        x86_64_code.push_back(x86);}
        else{
      x86 = "\tmovq " +to_string(off1) + "(%rbp), "+reg3;
      x86_64_code.push_back(x86);}
    x86="\tmovq $0, %rdx";
    x86_64_code.push_back(x86);
    if(off2>=0){
    x86 = "\tidivq " + to_string(off2) +"(" + init_reg + ")" ;
    x86_64_code.push_back(x86);}
    else{
          x86 = "\tidivq " + to_string(off2) +"(%rbp)" ;
    x86_64_code.push_back(x86);
    }
x86="\tmovq %rdx, "+reg3;
    x86_64_code.push_back(x86);
}
else if(charPtrToString(($2).op)=="//"){
  if(off1>=0){
    x86 = "\tmovq " + to_string(off1) + "(" + init_reg + ")" + ", %rax";
        x86_64_code.push_back(x86);}
          else{
      x86 = "\tmovq " +to_string(off1) + "(%rbp), "+reg3;
      x86_64_code.push_back(x86);}   
        
    x86="\tmovq $0, %rdx";
    x86_64_code.push_back(x86);
    if(off2>=0){
    x86 = "\tidivq " + to_string(off2) +"(" + init_reg + ")" ;
    x86_64_code.push_back(x86);}
    else{
        x86 = "\tidivq " + to_string(off2) +"(%rbp)" ;
    x86_64_code.push_back(x86);
    }
    }
      
    
  x86 = "\tsubq $16, %rsp";
  x86_64_code.push_back(x86);
    x86="\tmovq "+reg3+", "+to_string(current_local_symbol_table->curr_offset)+"(%rbp)";
      x86_64_code.push_back(x86);
    }
    else{
    string a = newtemp();
    string op = charPtrToString(($2).op);
    string reg1, reg2;
    if(($1).tempvar == NULL && ($2).tempvar == NULL){
      emit(op,charPtrToString(($1).lexeme),charPtrToString(($2).lexeme),a,-1);
      reg1=getreg(($1).lexeme);
      reg2=getreg(($2).lexeme);
    }else if(($1).tempvar == NULL){
      emit(op,charPtrToString(($1).lexeme),charPtrToString(($2).tempvar),a,-1);
      reg1=getreg(($1).lexeme);
      reg2=getreg(($2).tempvar);
    }else if(($2).tempvar == NULL){
      emit(op,charPtrToString(($1).tempvar),charPtrToString(($2).lexeme),a,-1);
      reg1=getreg(($1).tempvar);
      reg2=getreg(($2).lexeme);
    }else{
      emit(op,charPtrToString(($1).tempvar),charPtrToString(($2).tempvar),a,-1);
      reg1=getreg(($1).tempvar);
      reg2=getreg(($2).tempvar);
    }
    $$.tempvar = stringToCharArray(a);
    string x86;
    current_local_symbol_table->curr_offset-=16;
    current_local_symbol_table->offsets[a]=current_local_symbol_table->curr_offset;
    int regs_index=current_local_symbol_table->regs_index;
    string reg3=regs[regs_index%8];
  if(charPtrToString(($2).op)=="*"){
    x86="\tmovq "+reg1+", "+reg3;
    x86_64_code.push_back(x86);
    x86="\timulq "+reg2+", "+reg3;
    x86_64_code.push_back(x86);
  }
  else if(charPtrToString(($2).op)=="/"){
    // if(current_local_symbol_table->register_descriptor.find("%rax")!=current_local_symbol_table->register_descriptor.end()){
    // int off=get_offset(current_local_symbol_table->register_descriptor["%rax"][0]);
    // x86="\tmovq %rax, "+to_string(off)+"(%rbp)";
    // x86_64_code.push_back(x86);}
    // if(current_local_symbol_table->register_descriptor.find("%rdx")!=current_local_symbol_table->register_descriptor.end()){
    // int off=get_offset(current_local_symbol_table->register_descriptor["%rdx"][0]);
    // x86="\tmovq %rdx, "+to_string(off)+"(%rbp)";
    // x86_64_code.push_back(x86);}
    x86="\tmovq "+reg1+", %rax";
    x86_64_code.push_back(x86);
    x86="\tmovq $0, %rdx";
    x86_64_code.push_back(x86);
    x86="\tidivq "+reg2;
    x86_64_code.push_back(x86);
    x86="\tmovq %rax, "+reg3;
    x86_64_code.push_back(x86);}
    else if(charPtrToString(($2).op)=="%"){
    //   if(current_local_symbol_table->register_descriptor.find("%rax")!=current_local_symbol_table->register_descriptor.end()){
    // int off=get_offset(current_local_symbol_table->register_descriptor["%rax"][0]);
    // x86="\tmovq %rax, "+to_string(off)+"(%rbp)";
    // x86_64_code.push_back(x86);}
    // if(current_local_symbol_table->register_descriptor.find("%rdx")!=current_local_symbol_table->register_descriptor.end()){
    // int off=get_offset(current_local_symbol_table->register_descriptor["%rdx"][0]);
    // x86="\tmovq %rdx, "+to_string(off)+"(%rbp)";
    // x86_64_code.push_back(x86);}
    x86="\tmovq "+reg1+", %rax";
    x86_64_code.push_back(x86);
    x86="\tmovq $0, %rdx";
    x86_64_code.push_back(x86);
    x86="\tidivq "+reg2;
    x86_64_code.push_back(x86);
    x86="\tmovq %rdx, "+reg3;
    x86_64_code.push_back(x86);}
    else if(charPtrToString(($2).op)=="//"){
    // if(current_local_symbol_table->register_descriptor.find("%rax")!=current_local_symbol_table->register_descriptor.end()){
    // int off=get_offset(current_local_symbol_table->register_descriptor["%rax"][0]);
    // x86="\tmovq %rax, "+to_string(off)+"(%rbp)";
    // x86_64_code.push_back(x86);}
    // if(current_local_symbol_table->register_descriptor.find("%rdx")!=current_local_symbol_table->register_descriptor.end()){
    // int off=get_offset(current_local_symbol_table->register_descriptor["%rdx"][0]);
    // x86="\tmovq %rdx, "+to_string(off)+"(%rbp)";
    // x86_64_code.push_back(x86);}
    x86="\tmovq "+reg1+", %rax";
    x86_64_code.push_back(x86);
    x86="\tmovq $0, %rdx";
    x86_64_code.push_back(x86);
    x86="\tidivq "+reg2;
    x86_64_code.push_back(x86);
    x86="\tmovq %rax, "+reg3;
    x86_64_code.push_back(x86);
    }
    x86 = "\tsubq $16, %rsp";
    x86_64_code.push_back(x86);
    x86="\tmovq "+reg3+", "+to_string(current_local_symbol_table->curr_offset)+"(%rbp)";
    x86_64_code.push_back(x86);
    regs_index++;
    current_local_symbol_table->regs_index=regs_index;
 } 
 }
 }
|factor {
 $$.lexeme = ($1).lexeme; 
 $$.type=($1).type;
 cout<<"term2 "<<endl;
   $$.tempvar = ($1).tempvar; 
}
;
optional_operators_factor: operators factor {
  $$.lexeme = ($2).lexeme;
  $$.type=($2).type;  
  // if($$.lexeme!=NULL)

  cout<<"optional_operators_factor1"<<" "<<endl;
  $$.op = ($1).op;
  $$.tempvar = ($2).tempvar;

} 
|optional_operators_factor operators factor {
  $$.lexeme = ($3).lexeme;
  $$.type=($3).type;
  if(($3).type=="str"||($1).type=="str") {
    type_errors[type_error_line]="Mutable operation on string on line "+to_string(type_error_line)+" not allowed";}
  else if(!type_correct(($1).type,($3).type)){
    type_errors[type_error_line]="Type mismatch in operators on line "+to_string(type_error_line);}
  cout<<"optional_operators_factor2 "<<endl;
  if(($1).lexeme == NULL){
    $$.tempvar = ($3).tempvar;
    $$.op = ($1).op;
  }else{
    cout<<"optional_operators_factor2 "<<endl;
    if(current_local_symbol_table->parent!=NULL && current_local_symbol_table->parent->scope == "class"){
        cout<<"inclass"<<endl;
        string a = newtemp();
        string op = charPtrToString(($2).op);
        int off1, off2;
        if(($1).tempvar == NULL && ($3).tempvar == NULL){
            off1 = current_local_symbol_table->parent->offsets[($1).lexeme];
            off2 = current_local_symbol_table->parent->offsets[($3).lexeme];

        }
        else  if(($1).tempvar == NULL){
            off1 = current_local_symbol_table->parent->offsets[($1).lexeme];
            off2 = current_local_symbol_table->parent->offsets[($3).tempvar];

        }
        else if(($3).tempvar == NULL){
            off1 = current_local_symbol_table->parent->offsets[($1).tempvar];
            off2 = current_local_symbol_table->parent->offsets[($3).lexeme];

        }
        else {
            off1 = current_local_symbol_table->parent->offsets[($1).tempvar];
            off2 = current_local_symbol_table->parent->offsets[($3).tempvar];
        }
        $$.tempvar = stringToCharArray(a);
        $$.op = ($2).op;
        string x86;
         current_local_symbol_table->curr_offset-=16;
  current_local_symbol_table->offsets[a]=current_local_symbol_table->curr_offset;
  int regs_index=current_local_symbol_table->regs_index;
    string reg3=regs[regs_index%8];
    regs_index++;
     if(strcmp(stringToCharArray(reg3),stringToCharArray(init_reg))==0){
      reg3 = regs[regs_index%8]; 
      regs_index++;}
      if(charPtrToString(($2).op)=="*"){
        if(off1>=0){
        x86 = "\tmovq" + to_string(off1) + "(" + init_reg + "), " + reg3;
x86_64_code.push_back(x86);}
else{
  x86 = "\tmovq " +to_string(off1) + "(%rbp), "+reg3;
      x86_64_code.push_back(x86);
}
if(off2>=0){
x86 = "\timulq " + to_string(off2) + "(" + init_reg + "), " + reg3;
x86_64_code.push_back(x86);}
else{
      x86 = "\timulq " + to_string(off2) + "(%rbp), " + reg3;
      x86_64_code.push_back(x86);
      }
      }
           else if(charPtrToString(($2).op) == "/"){
            if(off1>=0){
        x86 = "\tmovq " + to_string(off1) + "(" + init_reg + ")" + ", %rax";
        x86_64_code.push_back(x86);
            }
            else {
               x86 = "\tmovq " +to_string(off1) + "(%rbp), "+reg3;
      x86_64_code.push_back(x86);
            }
    x86="\tmovq $0, %rdx";
    x86_64_code.push_back(x86);
    if(off2>=0){
    x86 = "\tidivq " + to_string(off2) +"(" + init_reg + ")" ;
    x86_64_code.push_back(x86);}
    else {
       x86 = "\tidivq " + to_string(off2) +"(%rbp)" ;
    x86_64_code.push_back(x86);
    }
x86="\tmovq %rax, "+reg3;
    x86_64_code.push_back(x86);
      }
      else if(charPtrToString(($2).op)=="%"){
        if(off1>=0){
          x86 = "\tmovq " + to_string(off1) + "(" + init_reg + ")" + ", %rax";
        x86_64_code.push_back(x86);}
        else{
      x86 = "\tmovq " +to_string(off1) + "(%rbp), "+reg3;
      x86_64_code.push_back(x86);}
    x86="\tmovq $0, %rdx";
    x86_64_code.push_back(x86);
    if(off2>=0){
    x86 = "\tidivq " + to_string(off2) +"(" + init_reg + ")" ;
    x86_64_code.push_back(x86);}
    else{
          x86 = "\tidivq " + to_string(off2) +"(%rbp)" ;
    x86_64_code.push_back(x86);
    }
x86="\tmovq %rdx, "+reg3;
    x86_64_code.push_back(x86);
}
else if(charPtrToString(($2).op)=="//"){
  if(off1>=0){
    x86 = "\tmovq " + to_string(off1) + "(" + init_reg + ")" + ", %rax";
        x86_64_code.push_back(x86);}
          else{
      x86 = "\tmovq " +to_string(off1) + "(%rbp), "+reg3;
      x86_64_code.push_back(x86);}   
        
    x86="\tmovq $0, %rdx";
    x86_64_code.push_back(x86);
    if(off2>=0){
    x86 = "\tidivq " + to_string(off2) +"(" + init_reg + ")" ;
    x86_64_code.push_back(x86);}
    else{
        x86 = "\tidivq " + to_string(off2) +"(%rbp)" ;
    x86_64_code.push_back(x86);
    }
    x86="\tmovq %rax, "+reg3;
    x86_64_code.push_back(x86);
    }


  x86 = "\tsubq $16, %rsp";
  x86_64_code.push_back(x86);
    x86="\tmovq "+reg3+", "+to_string(current_local_symbol_table->curr_offset)+"(%rbp)";
      x86_64_code.push_back(x86);

    }else {
    string a = newtemp();
    string op = charPtrToString(($2).op);
    string reg1, reg2;
    if(($1).tempvar == NULL && ($3).tempvar == NULL){
      emit(op,charPtrToString(($1).lexeme),charPtrToString(($3).lexeme),a,-1);
      reg1=getreg(($1).lexeme);
      reg2=getreg(($3).lexeme);
    }else if(($1).tempvar == NULL){
      emit(op,charPtrToString(($1).lexeme),charPtrToString(($3).tempvar),a,-1);
      reg1=getreg(($1).lexeme);
      reg2=getreg(($3).tempvar);
    }else if(($3).tempvar == NULL){
      emit(op,charPtrToString(($1).tempvar),charPtrToString(($3).lexeme),a,-1);
      reg1=getreg(($1).tempvar);
      reg2=getreg(($3).lexeme);
    }else{
      emit(op,charPtrToString(($1).tempvar),charPtrToString(($3).tempvar),a,-1);
      reg1=getreg(($1).tempvar);
      reg2=getreg(($3).tempvar);
    }
    $$.tempvar = stringToCharArray(a);
    $$.op = ($1).op;
    string x86;
  // x86="\tsubq $16, %rsp";
  // x86_64_code.push_back(x86);
  current_local_symbol_table->curr_offset-=16;
  current_local_symbol_table->offsets[a]=current_local_symbol_table->curr_offset;
  int regs_index=current_local_symbol_table->regs_index;
    string reg3=regs[regs_index%8];
    // int off=get_offset(current_local_symbol_table->register_descriptor[reg3][0]);
    // x86="\tmovq "+reg3+", "+to_string(off)+"(%rbp)";
    // x86_64_code.push_back(x86);
    // regs_index++;
    // current_local_symbol_table->regs_index=regs_index;
    //cout<<"optional_operators_factor2after "<<endl;
  if(charPtrToString(($2).op)=="*"){
    x86="\tmovq "+reg1+", "+reg3;
    x86_64_code.push_back(x86);
    x86="\timulq "+reg2+", "+reg3;
    x86_64_code.push_back(x86);
    //cout<<"star"<<endl;
  }
  else if(charPtrToString(($2).op)=="/"){
    x86="\tmovq "+reg1+", %rax";
    x86_64_code.push_back(x86);
    x86="\tmovq $0, %rdx";
    x86_64_code.push_back(x86);
    x86="\tidivq "+reg2;
    x86_64_code.push_back(x86);
    x86="\tmovq %rax, "+reg3;
    x86_64_code.push_back(x86);
  }
    else if(charPtrToString(($2).op)=="%"){
      x86="\tmovq "+reg1+", %rax";
      x86_64_code.push_back(x86);
      x86="\tmovq $0, %rdx";
      x86_64_code.push_back(x86);
      x86="\tidivq "+reg2;
      x86_64_code.push_back(x86);
      x86="\tmovq %rdx, "+reg3;
      x86_64_code.push_back(x86);
    }
    else if(charPtrToString(($2).op)=="//"){
    // if(current_local_symbol_table->register_descriptor.find("%rax")!=current_local_symbol_table->register_descriptor.end()){
    // int off=get_offset(current_local_symbol_table->register_descriptor["%rax"][0]);
    // x86="\tmovq %rax, "+to_string(off)+"(%rbp)";
    // x86_64_code.push_back(x86);}
    // if(current_local_symbol_table->register_descriptor.find("%rdx")!=current_local_symbol_table->register_descriptor.end()){
    // int off=get_offset(current_local_symbol_table->register_descriptor["%rdx"][0]);
    // x86="\tmovq %rdx, "+to_string(off)+"(%rbp)";
    // x86_64_code.push_back(x86);}
      x86="\tmovq "+reg1+", %rax";
      x86_64_code.push_back(x86);
      x86="\tmovq $0, %rdx";
      x86_64_code.push_back(x86);
      x86="\tidivq "+reg2;
      x86_64_code.push_back(x86);
      x86="\tmovq %rax, "+reg3;
      x86_64_code.push_back(x86);
    }
    x86 = "\tsubq $16, %rsp";
    x86_64_code.push_back(x86);
    x86="\tmovq "+reg3+", "+to_string(current_local_symbol_table->curr_offset)+"(%rbp)";
      x86_64_code.push_back(x86);
      regs_index++;
      current_local_symbol_table->regs_index=regs_index;
      //cout<<"optional_operators_factor2end"<<endl;
  }
  }
}
;
operators: STAR {
  type_error_line=yylineno;
  $$.op = $1;
  }
          |AT {
  type_error_line=yylineno;
  $$.op = $1;
            }
          |BACKSLASH {
  type_error_line=yylineno;
  $$.op = $1;
            }
          |PERCENT {type_error_line=yylineno;
  $$.op = $1;
  
  }
          |DOUBLEBACKSLASH { type_error_line=yylineno;
      //cout<<"operators //"<<endl;
      $$.op = $1;

  };
factor: unary_operator factor  {
  $$.type=($2).type;
  $$.lexeme=($2).lexeme;
  $$.tempvar=($2).tempvar;
  cout<<"factor1 "<<endl;
  //cout<<"tempvar=="<<($2).tempvar<<endl;
  cout<<"unaray operator"<<endl;
  if(($2).is_number){
  // cout<<"factor1 "<<$$.type<<endl;
  cout<<"number"<<endl;
      string var = newtemp();
      $$.tempvar = stringToCharArray(var);
      emit("=",charPtrToString(($1).op),charPtrToString(($2).lexeme), var, -1);
      un_op = 0;
      string reg1;
      string x86;
      current_local_symbol_table->curr_offset-=16;
      x86 = "\tsubq $16, %rsp";
      x86_64_code.push_back(x86);
      x86="\tmovq $"+charPtrToString(($2).lexeme)+", "+to_string(current_local_symbol_table->curr_offset)+"(%rbp)";
      x86_64_code.push_back(x86);
      int regs_index=current_local_symbol_table->regs_index;
      reg1=regs[regs_index%8];
      x86="\tmovq "+to_string(current_local_symbol_table->curr_offset)+"(%rbp), "+reg1;
      x86_64_code.push_back(x86);
      current_local_symbol_table->curr_offset-=16;
      current_local_symbol_table->offsets[var]=current_local_symbol_table->curr_offset;
    regs_index++;
    string reg2=regs[regs_index%8];
    if(charPtrToString(($1).op)=="-"){
      x86="\tnegq "+reg1;
      x86_64_code.push_back(x86);
      x86="\tmovq "+reg1+", "+reg2;
      x86_64_code.push_back(x86);
    }
    else if(charPtrToString(($1).op)=="+"){
      x86="\tmovq "+reg1+", "+reg2;
    }
    else if(charPtrToString(($1).op)=="~"){
      x86="\tnotq "+reg1;
      x86_64_code.push_back(x86);
      x86="\tmovq "+reg1+", "+reg2;
      x86_64_code.push_back(x86);
    }
        x86 = "\tsubq $16, %rsp";
  x86_64_code.push_back(x86);
    x86="\tmovq "+reg2+", "+to_string(current_local_symbol_table->curr_offset)+"(%rbp)";
      x86_64_code.push_back(x86);
      regs_index++;
      current_local_symbol_table->regs_index=regs_index;
  }
  else {
    cout<<"not_numer"<<($1).op<<endl;
    string t = newtemp();
    int off1;

      string reg1,x86;
      int regs_index=current_local_symbol_table->regs_index;
      string reg2 = regs[regs_index%8];
     x86_64_code.push_back(x86);
     if(charPtrToString(($1).op)=="~"){
        if(($2).tempvar == NULL){
        emit("=","~",charPtrToString(($2).lexeme), t, -1);
        off1 = get_offset(($2).lexeme);
        reg1 = getreg(($2).lexeme);
        x86 = "\tmovq "+ to_string(off1) + "(%rbp), "+  reg2;
        }else{
          emit("=","~",charPtrToString(($2).tempvar), t, -1);
        off1 = get_offset(($2).tempvar);
        reg1 = getreg(($2).lexeme);
        x86 = "\tmovq "+ to_string(off1) + "(%rbp), "+  reg2;
        }
        x86 = "\tnotq " + reg2;
      x86_64_code.push_back(x86);

      }else if(charPtrToString(($1).op)=="-"){
        if(($2).tempvar == NULL){
        emit("=","-",charPtrToString(($2).lexeme), t, -1);
        off1 = get_offset(($2).lexeme);
        reg1 = getreg(($2).lexeme);
        x86 = "\tmovq "+ to_string(off1) + "(%rbp), "+  reg2;
        }else{
          emit("=","-",charPtrToString(($2).tempvar), t, -1);
        off1 = get_offset(($2).tempvar);
        reg1 = getreg(($2).lexeme);
        x86 = "\tmovq "+ to_string(off1) + "(%rbp), "+  reg2;
        }
        x86 = "\tnegq " + reg2;
      x86_64_code.push_back(x86);

      }else{
        if(($2).tempvar == NULL){
        emit("=","+",charPtrToString(($2).lexeme), t, -1);
        // off1 = get_offset(($2).lexeme);
        // reg1 = getreg(($2).lexeme);
        // x86 = "\tmovq "+ to_string(off1) + "(%rbp), "+  reg2;
        }else{
          emit("=","-",charPtrToString(($2).tempvar), t, -1);
        // off1 = get_offset(($2).tempvar);
        // reg1 = getreg(($2).lexeme);
        // x86 = "\tmovq "+ to_string(off1) + "(%rbp), "+  reg2;
        }
        // x86 = "\tnegq " + reg2;

      }
      x86 = "\tsubq $16, %rsp";
      x86_64_code.push_back(x86);
      current_local_symbol_table->curr_offset-=16;
      current_local_symbol_table->offsets[t] = current_local_symbol_table->curr_offset;
      x86="\tmovq "+reg2+", "+to_string(current_local_symbol_table->curr_offset)+"(%rbp)";
      x86_64_code.push_back(x86);
      regs_index++;
      current_local_symbol_table->regs_index=regs_index;
 $$.tempvar = stringToCharArray(t);

  }
}
| power {
  $$.lexeme = ($1).lexeme;
  $$.type=($1).type;
          cout<<"factor2 "<<endl;
  $$.tempvar = ($1).tempvar;
string x86;
  if(($1).is_number && !un_op){
  //   string var = newtemp();
  //   // strcpy($$.tempvar, var);
  //   $$.tempvar = stringToCharArray(var);
  //   emit("=",charPtrToString(($1).lexeme),"", var, -1);
  //   // string x86="\tsubq $16, %rsp";
  //   // x86_64_code.push_back(x86);
  // current_local_symbol_table->curr_offset-=16;
  // current_local_symbol_table->offsets[var]=current_local_symbol_table->curr_offset;
  // x86 = "\tsubq $16, %rsp";
  // x86_64_code.push_back(x86);
  // x86="\tmovq $"+charPtrToString(($1).lexeme)+", "+to_string(current_local_symbol_table->curr_offset)+"(%rbp)";
  // x86_64_code.push_back(x86);
  }
  cout<<"factor 2 end"<<endl;
};
unary_operator: PLUS {
  un_op = 1;
  $$.op = stringToCharArray("+");
}
                |MINUS {
  un_op = 1;
  $$.op = stringToCharArray("-");           
}
                // $$=create_ast_node("MINUS");}
                |TILDE {
  un_op = 1;
  cout<<"tilde"<<endl;
  $$.op = stringToCharArray("~");
};
power: 
atom_expr doublestar factor {
  // cout<<"power2"<<endl;
  cout<<"//////////"<<($1).lexeme<<" "<<($3).lexeme<<"$$$$$$$$$$$$$"<<endl;
  $$.lexeme = ($1).lexeme;
  $$.type=($1).type;
  if(!type_correct($$.type,($3).type)){
 
  type_errors[type_error_line]="Type mismatch in power operation on line "+to_string(type_error_line);}
 if(current_local_symbol_table->parent!=NULL && current_local_symbol_table->parent->scope == "class"){
  string a = newtemp();
  string op = charPtrToString(($2).op);
  int off1,off2;
    if(($1).tempvar == NULL && ($3).tempvar == NULL){
    emit(op,charPtrToString(($1).lexeme),charPtrToString(($3).lexeme),a,-1);
    off1 = current_local_symbol_table->parent->offsets[($1).lexeme];
    off2 = current_local_symbol_table->parent->offsets[($3).lexeme];

  }else if(($1).tempvar == NULL){
    emit(op,charPtrToString(($1).lexeme),charPtrToString(($3).tempvar),a,-1);
    off1 = current_local_symbol_table->parent->offsets[($1).lexeme];
    off2 = current_local_symbol_table->parent->offsets[($3).tempvar];
  }else if(($3).tempvar == NULL){
    emit(op,charPtrToString(($1).tempvar),charPtrToString(($3).lexeme),a,-1);
     off1 = current_local_symbol_table->parent->offsets[($1).tempvar];
    off2 = current_local_symbol_table->parent->offsets[($3).lexeme];
  }else{
    emit(op,charPtrToString(($1).tempvar),charPtrToString(($3).tempvar),a,-1);
     off1 = current_local_symbol_table->parent->offsets[($1).tempvar];
    off2 = current_local_symbol_table->parent->offsets[($3).tempvar];
  }
    $$.tempvar = stringToCharArray(a);
  current_local_symbol_table->curr_offset-=16;
  current_local_symbol_table->offsets[a]=current_local_symbol_table->curr_offset;
  current_local_symbol_table->parent->offsets[a] = current_local_symbol_table->curr_offset;

  int regs_index=current_local_symbol_table->regs_index;
  string reg3=regs[regs_index%8];
  regs_index++;
  if(strcmp(stringToCharArray(reg3),stringToCharArray(init_reg))==0){
      reg3 = regs[regs_index%8]; 
      regs_index++;}
  string reg4 = regs[(regs_index)%8];
  regs_index++;
  if(strcmp(stringToCharArray(reg4),stringToCharArray(init_reg))==0){
      reg3 = regs[regs_index%8]; 
      regs_index++;}

  string x86;
  string L = newLabel();
  string L1 = newLabel();
 x86="\tmovq $1, "+reg4;
      x86_64_code.push_back(x86);
      if(off1>=0){
      x86 = "\tmovq " + to_string(off1) + "(" + init_reg + "), " + reg3;
      x86_64_code.push_back(x86); 
      }
      else {
           x86 = "\tmovq " + to_string(off1) + "(%rbp), " + reg3;
      x86_64_code.push_back(x86); 
      }
      x86= L+":";
      x86_64_code.push_back(x86);
      if(off2>=0){
      x86="\tcmpq "+reg4+", "+to_string(off2) + "(" + init_reg + ")";
      x86_64_code.push_back(x86);
      }
      else {
      
      x86="\tcmpq "+reg4+", "+to_string(off2) + "(%rbp)";
      x86_64_code.push_back(x86);
      }
      x86="\tjle "+L1;
      x86_64_code.push_back(x86);
      if(off1>=0){
         x86 = "\timulq " + to_string(off1) + "(" + init_reg + "), " + reg3;
      x86_64_code.push_back(x86);
      }
      else {
          x86 = "\tmovq " + to_string(off1) + "(%rbp), " + reg3;
      x86_64_code.push_back(x86); 
      }
      x86="\taddq $1, "+reg4;
      x86_64_code.push_back(x86);
      x86="\tjmp "+L ;
      x86_64_code.push_back(x86);
      x86= L1+":";
      x86_64_code.push_back(x86);
      current_local_symbol_table->regs_index=regs_index;
  x86 = "\tsubq $16, %rsp";
  x86_64_code.push_back(x86);
  x86="\tmovq "+reg3+", "+to_string(current_local_symbol_table->curr_offset)+"(%rbp)";
      x86_64_code.push_back(x86);
      current_local_symbol_table->regs_index=regs_index;
cout<<"exit_power"<<endl;
 }
 else{ string a = newtemp();
  string op = "**";
  string reg1, reg2;            
  if(($1).tempvar == NULL && ($3).tempvar == NULL){
    emit(op,charPtrToString(($1).lexeme),charPtrToString(($3).lexeme),a,-1);
    reg1=getreg(($1).lexeme);
    reg2=getreg(($3).lexeme);
  }else if(($1).tempvar == NULL){
    emit(op,charPtrToString(($1).lexeme),charPtrToString(($3).tempvar),a,-1);
    cout<<"II AMMMMMM HERRREEEEEE"<<($1).lexeme<<" "<<($3).tempvar<<endl;
    reg1=getreg(($1).lexeme);
    reg2=getreg(($3).tempvar);
  }else if(($3).tempvar == NULL){
    emit(op,charPtrToString(($1).tempvar),charPtrToString(($3).lexeme),a,-1);
    reg1=getreg(($1).tempvar);
    reg2=getreg(($3).lexeme);
  }else{
    emit(op,charPtrToString(($1).tempvar),charPtrToString(($3).tempvar),a,-1);
    cout<<"II AMMMMMM HERRREEEEEE"<<($1).tempvar<<" "<<($3).tempvar<<endl;

    reg1=getreg(($1).tempvar);
    reg2=getreg(($3).tempvar);
  }
  $$.tempvar = stringToCharArray(a);
  current_local_symbol_table->curr_offset -= 16;
  current_local_symbol_table->offsets[a]=current_local_symbol_table->curr_offset;
  int regs_index=current_local_symbol_table->regs_index;
  string reg3=regs[regs_index%8];
  regs_index++;
  string reg4 = regs[(regs_index)%8];
  string x86;
  string L = newLabel();
  string L1 = newLabel();

      x86="\tmovq $1, "+reg4;
      x86_64_code.push_back(x86);
      x86="\tmovq "+reg1+", "+reg3;
      x86_64_code.push_back(x86);
      x86= L+":";
      x86_64_code.push_back(x86);
      x86="\tcmpq "+reg4+", "+reg2;
      x86_64_code.push_back(x86);
      x86="\tjle "+L1;
      x86_64_code.push_back(x86);
      x86="\timulq "+reg1+", "+reg3;
      x86_64_code.push_back(x86);
      x86="\taddq $1, "+reg4;
      x86_64_code.push_back(x86);
      x86="\tjmp "+L ;
      x86_64_code.push_back(x86);
      x86= L1+":";
      x86_64_code.push_back(x86);
  regs_index++;
  current_local_symbol_table->regs_index=regs_index;
  x86 = "\tsubq $16, %rsp";
  x86_64_code.push_back(x86);
  x86="\tmovq "+reg3+", "+to_string(current_local_symbol_table->offsets[a])+"(%rbp)";
      x86_64_code.push_back(x86);
      current_local_symbol_table->regs_index=regs_index;
cout<<"exit_power"<<endl;
 }
  }
|atom_expr {
  $$.is_number = ($1).is_number;

  $$.lexeme = ($1).lexeme;
  $$.type=($1).type;
  $$.tempvar = ($1).tempvar;
  cout<<"power "<<($1).lexeme<<endl;
}
;
doublestar: DOUBLESTAR {type_error_line=yylineno;
  $$.lexeme = $1;
};
// v: doublestar factor{
//   $$.type=($2).type;
//   $$.op = ($1).lexeme;
//     $$.tempvar= ($2).tempvar;

// }
;
atom_expr: atom optional_trailer {
  //cout<<"at atom_expr1"<<endl;
  $$.lexeme = ($1).lexeme;
   string first = charPtrToString(($1).lexeme);

  vector<string>func_argument;
  string fun="";
  string fun1="";
  if(!tables.empty()){
    if(tables.top()->scope == "class" && dot_present && first!="self"){
     fun = first + ".";
     fun1 = fun + dot_name;
    func_names.push_back(fun1);}
  }
 
  $$.type=($1).type;
  string p,q="";
  int is_noparam=0;
  if(charPtrToString(($2).type).size()>=4)q=charPtrToString(($2).type).substr(0,4);
  if(strcmp($$.type,"list")==0&&q!="list"){
    p=charPtrToString(($1).type)+charPtrToString(($2).type);
    $$.type=stringToCharArray(p);
  }
  else if(strcmp($$.type,"list")==0) $$.type=($2).type;
  string x;
  //cout<<"atom_expr "<<$$.type<<" "<<$$.lexeme<<" "<<($2).type<<endl;
  if(variables.find($$.lexeme)!=variables.end()) {
    if(strcmp($$.lexeme,"len")==0) $$.type="int";
    if(is_paren==1) {func.pop(); }
    //cout<<"is_paren=1 to 0"<<endl;
    if(func_running.empty()){
      //cout<<"is_paren=1 to 0 if"<<endl;
      is_paren=0;
    }
  }
  // if(is_lsq==1) cout<<"is_lsq=1"<<endl;
  // if(is_paren==0) cout<<"is_paren=0"<<endl;
  string class_func="";
  if(is_paren==1&&is_lsq!=1&&variables.find($$.lexeme)==variables.end()){
    //cout<<"is_paren=1"<<endl;
    vector<string>function_argument;
    if(!func.empty())
    function_argument=func.top();
    // cout<<"is_paren=1 to 0"<<endl;
    if(func_running.empty())
    is_paren=0;
    LocalSymbolTable* temp, *temp1;
    if(current_local_symbol_table!=global_table){
      temp1 = find_table($$.type, global_table);
      if(current_local_symbol_table->parent!=NULL && current_local_symbol_table->parent->scope=="class"&&is_ancestor(temp1,current_local_symbol_table->parent)) {
      // cout<<"is_ancestor "<<$$.type<<endl;
      temp=temp1;}
      else if(current_local_symbol_table->parent!=NULL && current_local_symbol_table->parent->scope!="class") 
      {
        // cout<<"current_local_symbol_table->parent->scope!=class "<<$$.lexeme<<endl;
      temp=find_table($$.type, global_table);}
    }
    else {
      // cout<<"current_local_symbol_table==global_table "<<$$.lexeme<<endl;
      temp = find_table($$.type, global_table);
    }
    // cout<<"func_error_line "<<func_error_line<<"yylineno "<<yylineno<<endl;
    if(is_func_dot!=""){
      // cout<<"is_func_dot=1 "<<is_func_dot<<" "<<$$.lexeme<<endl;
      temp=find_table(is_func_dot, temp);
      //is_dot="";
      // cout<<"is_func_dot=1 "<<is_func_dot<<" "<<$$.lexeme<<endl;
    }
    int i=0;
  // if(temp==NULL) cout<<"temp=NULL "<<$$.lexeme<<endl;
  string scop="";
  if(temp!=NULL&&is_func_dot==""&&temp->scope=="class") {
    // cout<<"is_func_dot temp!=NULL "<<$$.lexeme<<endl;
    temp = find_table("__init__", temp);
    scop="class";
    $$.type=($1).lexeme;
  //temp->parameter_types.erase(temp->parameter_types.begin());
  }
  func_argument=function_argument;
  if(temp!=NULL){
    // cout<<"temp!=NULL "<<$$.lexeme<<" "<<temp->parameter_types.size()<<" "<<function_argument.size()<<endl;
    if(function_argument.empty()) is_noparam=1;
    if(scop!="class") $$.type=stringToCharArray(temp->return_type);
    // cout<<"temp!=NULL "<<$$.type<<" "<<$$.lexeme<<endl;
    for(i=0; i<function_argument.size(); i++){
      // cout<<"function_arguments: "<<function_argument[i]<<endl;
      if(i<temp->parameter_types.size()&&temp->parameter_types[i]==":") temp->parameter_types[i]="";
      if(i<temp->parameter_types.size()&&function_argument[i]!=temp->parameter_types[i]){
      // cout<<"function_arguments if: "<<function_argument[i]<<"1"<<endl<<temp->parameter_types[i]<<endl;
      func_errors[func_error_line]="Function called with type mismatch in parameter "+to_string(i+1)+" on line "+to_string(func_error_line);
      // cout<<func_errors[func_error_line]<<endl;
      }
      else if(i>=temp->parameter_types.size())
      func_errors[func_error_line]="Function called with extra parameters on line "+to_string(func_error_line);
    }
    // cout<<"i: "<<i<<" "<<temp->parameter_types.size()<<endl;
    if(i<temp->parameter_types.size()){
      // cout<<"i if: "<<i<<" "<<temp->parameter_types.size()<<" "<<func_error_line<<endl;
      func_errors[func_error_line]="Function called with less parameters on line "+to_string(func_error_line);
    }
    }
    else{
      // cout<<"temp=NULL in else "<<$$.lexeme<<endl;
      func_errors[func_error_line]="Function called on line "+to_string(func_error_line)+" is not declared";
    }
    func.pop();
    // cout<<"after func "<<yylineno<<endl;
    class_func=is_func_dot;
    is_func_dot="";
    is_dot = "";}

    is_lsq=0;
    //function_arguments.clear();
    if(charPtrToString($$.type).size()>=4&&charPtrToString($$.type).substr(0,4)=="list"&&strcmp($$.lexeme,"list")!=0&&strcmp(($2).type,"int")!=0){
    type_errors[type_error_line]="Array at "+to_string(type_error_line)+" expected int but got "+charPtrToString(($2).type);}
    ///////////////////3AC//////////////////////
    if(charPtrToString(($1).lexeme).size()>=4&&charPtrToString(($1).lexeme)=="self"){
    string self=charPtrToString(($1).lexeme)+"."+charPtrToString(($2).lexeme);
    $$.lexeme=stringToCharArray(self);}
    if(($2).is_array == 0&&charPtrToString(($1).lexeme)!="self") {
      string a = newtemp();
      $$.tempvar = stringToCharArray(a);
      if(charPtrToString(($1).lexeme)!="self"){
        if(($2).is_class_dot && fun1!=""){
          emit("stackpointer","+xxx","","",-1);
          emit("=","Lcall",fun1,a,-1);
          emit("stackpointer","-yyy","","",-1);
        }
        else{
          emit("stackpointer","+xxx","","",-1);
          emit("=","Lcall",charPtrToString(($1).lexeme),a,-1);
          emit("stackpointer","-yyy","","",-1);
        } if(is_noparam==0){
          emit("pop_params",to_string(push_size),"","",-1);
         }
          else is_noparam=0;
      }
      int it, pop_size = 0;
      string x86;
      current_local_symbol_table->curr_offset-=16;
      current_local_symbol_table->offsets[a]=current_local_symbol_table->curr_offset;
      LocalSymbolTable* table = find_table(($1).lexeme, global_table);
      LocalSymbolTable* tab=NULL;
      if(current_local_symbol_table->variables.find(($1).lexeme)!=current_local_symbol_table->variables.end()){
        tab=find_table(current_local_symbol_table->variables[($1).lexeme]->type, global_table);
      }
      if(func_name=="__init__"&&charPtrToString(($1).lexeme)!="print"){
        int off;
        cout<<"here??";
        int paren_off = 0;
    for(it = 0; it<function_arguments_name.size(); it++){
      off = get_offset(function_arguments_name[it]);
      int regs_index=current_local_symbol_table->regs_index;
      if(regs[regs_index%8]==init_reg){
     regs_index++;
     } 
     x86 = "\tmovq " +to_string(off) + "(%rbp),"+regs[regs_index%8];
     x86_64_code.push_back(x86);
     x86="\tmovq "+regs[regs_index%8]+", " + to_string(paren_off) +"("+init_reg+")";
     x86_64_code.push_back(x86);
     paren_off+=16;
  regs_index++;}}
     else if(tab!=NULL&&tab->scope=="class"&&charPtrToString(($1).lexeme)!="print"){
        x86="\tmovq "+to_string(get_offset(charPtrToString(($1).lexeme)))+"(%rbp), %rdi";
        x86_64_code.push_back(x86);

        it=0;
        if(it<function_arguments_name.size()){
          x86="\tmovq "+to_string(get_offset(function_arguments_name[it]))+"(%rbp), %rdi";
          x86_64_code.push_back(x86);
          it++;}
        if(it<function_arguments_name.size()){
          x86="\tmovq "+to_string(get_offset(function_arguments_name[it]))+"(%rbp), %rsi";
          x86_64_code.push_back(x86);
          it++;}
        if(it<function_arguments_name.size()){
          x86="\tmovq "+to_string(get_offset(function_arguments_name[it]))+"(%rbp), %rdx";
          x86_64_code.push_back(x86);
          it++;}
        if(it<function_arguments_name.size()){
          x86="\tmovq "+to_string(get_offset(function_arguments_name[it]))+"(%rbp), %rcx";
          x86_64_code.push_back(x86);
          it++;}
        if(it<function_arguments_name.size()){
          x86="\tmovq "+to_string(get_offset(function_arguments_name[it]))+"(%rbp), %r8";
          x86_64_code.push_back(x86);
          it++;}
        if(it<function_arguments_name.size()){
          x86="\tmovq "+to_string(get_offset(function_arguments_name[it]))+"(%rbp), %r9";
          x86_64_code.push_back(x86);
          it++;
        }
        int x=it;
        int regs_index=current_local_symbol_table->regs_index;
        string reg;
        int sz;
        cout<<"for_loop start3"<<endl;
        for(x=function_arguments_name.size()-1; x>=it; x--){
          cout<<"start loop"<<endl;
          reg=reg_par[regs_index%8];
          cout<<"x: "<<x<<endl;
          cout<<"begin x: "<<x<<" "<<function_arguments_name[x]<<endl;
          x86="\tmovq "+to_string(get_offset(function_arguments_name[x]))+"(%rbp), "+reg;
          cout<<"end x: "<<x<<" "<<function_arguments_name[x]<<endl;
          x86_64_code.push_back(x86);
          x86="\tmovq "+reg+", 0(%rsp)";
          x86_64_code.push_back(x86);
          if(x!=it){
          x86="\tsubq $16, %rsp";
          x86_64_code.push_back(x86);
          current_local_symbol_table->curr_offset-=16;}
          regs_index++;
          cout<<"regs_index: "<<regs_index<<endl;
        }
        cout<<"for_loop end1"<<endl;
        current_local_symbol_table->regs_index=regs_index;
        x86="\tcall "+current_local_symbol_table->variables[charPtrToString(($1).lexeme)]->type+"."+class_func;
      x86_64_code.push_back(x86);
      }
      else if(table!=NULL&&table->scope=="class"&&charPtrToString(($1).lexeme)!="print"){
        int s=table->size;
        cout<<"size: "<<s<<endl;
        if(s%16!=0) s=(s/16+1)*16;
        x86="\tmovq $"+to_string(s)+", %rdi";
        x86_64_code.push_back(x86);
        x86="\tcall malloc@PLT";
        x86_64_code.push_back(x86);
        int regs_index=current_local_symbol_table->regs_index;
        string reg3=regs[regs_index%8];
        x86="\tmovq %rax, "+reg3;
        x86_64_code.push_back(x86);
        regs_index++;
        current_local_symbol_table->regs_index=regs_index;
        x86="\tsubq $"+to_string(s)+", %rsp";
        x86_64_code.push_back(x86);
        current_local_symbol_table->curr_offset-=16;
        current_local_symbol_table->offsets[charPtrToString($$.tempvar)]=current_local_symbol_table->curr_offset;
        x86="\tmovq "+reg3+", "+to_string(current_local_symbol_table->curr_offset)+"(%rbp)";
        x86_64_code.push_back(x86);
        x86="\tmovq "+to_string(current_local_symbol_table->curr_offset)+"(%rbp), %rdi";
        x86_64_code.push_back(x86);
        it=0;
        if(it<function_arguments_name.size()){
          x86="\tmovq "+to_string(get_offset(function_arguments_name[it]))+"(%rbp), %rsi";
          x86_64_code.push_back(x86);
          cout<<"rsi: "<<function_arguments_name[it]<<endl;
          it++;}
        if(it<function_arguments_name.size()){
          x86="\tmovq "+to_string(get_offset(function_arguments_name[it]))+"(%rbp), %rdx";
          x86_64_code.push_back(x86);
          cout<<"rdx: "<<function_arguments_name[it]<<endl;
          it++;}
        if(it<function_arguments_name.size()){
          x86="\tmovq "+to_string(get_offset(function_arguments_name[it]))+"(%rbp), %rcx";
          x86_64_code.push_back(x86);
          it++;}
        if(it<function_arguments_name.size()){
          x86="\tmovq "+to_string(get_offset(function_arguments_name[it]))+"(%rbp), %r8";
          x86_64_code.push_back(x86);
          it++;}
        if(it<function_arguments_name.size()){
          x86="\tmovq "+to_string(get_offset(function_arguments_name[it]))+"(%rbp), %r9";
          x86_64_code.push_back(x86);
          it++;}
        int x=it;
        regs_index=current_local_symbol_table->regs_index;
        string reg;
        int sz;
        cout<<"for_loop start1 "<<($1).lexeme<<endl;
        for(x=function_arguments_name.size()-1; x>=it; x--){
        cout<<"start loop"<<endl;
        reg=reg_par[regs_index%8];
        cout<<"x: "<<x<<endl;
        cout<<"begin x: "<<x<<" "<<function_arguments_name[x]<<endl;
        x86="\tmovq "+to_string(get_offset(function_arguments_name[x]))+"(%rbp), "+reg;
        cout<<"end x: "<<x<<" "<<function_arguments_name[x]<<endl;
        x86_64_code.push_back(x86);
        x86="\tmovq "+reg+", 0(%rsp)";
        x86_64_code.push_back(x86);
        if(x!=it){
        x86="\tsubq $16, %rsp";
        x86_64_code.push_back(x86);
        current_local_symbol_table->curr_offset-=16;}
        regs_index++;
        cout<<"regs_index: "<<regs_index<<endl;}
        cout<<"for_loop end1"<<endl;
        current_local_symbol_table->regs_index=regs_index;
        x86="\tcall "+charPtrToString(($1).lexeme)+".__init__";
        x86_64_code.push_back(x86);
        cout<<"after call"<<endl;
      }
      else if(charPtrToString(($1).lexeme)!="print" && charPtrToString(($1).lexeme)!="range" && charPtrToString(($1).lexeme)!="len"){
        cout<<"not_print"<<endl;
        it=0;
        if(it<function_arguments_name.size()){
        x86="\tmovq "+to_string(get_offset(function_arguments_name[it]))+"(%rbp), %rdi";
        x86_64_code.push_back(x86);
        it++;}
      //cout<<"function_arguments_name.size() "<<function_arguments_name.size()<<endl;
        if(it<function_arguments_name.size()){
        x86="\tmovq "+to_string(get_offset(function_arguments_name[it]))+"(%rbp), %rsi";
        x86_64_code.push_back(x86);
        it++;}
        if(it<function_arguments_name.size()){
        x86="\tmovq "+to_string(get_offset(function_arguments_name[it]))+"(%rbp), %rdx";
        x86_64_code.push_back(x86);
        it++;}
        if(it<function_arguments_name.size()){
        x86="\tmovq "+to_string(get_offset(function_arguments_name[it]))+"(%rbp), %rcx";
        x86_64_code.push_back(x86);
        it++;}
        if(it<function_arguments_name.size()){
        x86="\tmovq "+to_string(get_offset(function_arguments_name[it]))+"(%rbp), %r8";
        x86_64_code.push_back(x86);
        it++;}
        if(it<function_arguments_name.size()){
        x86="\tmovq "+to_string(get_offset(function_arguments_name[it]))+"(%rbp), %r9";
        x86_64_code.push_back(x86);
        it++;}
        int x=it;
        int regs_index=current_local_symbol_table->regs_index;
        string reg;
        int sz;
        cout<<"for_loop start2"<<endl;
        for(x=function_arguments_name.size()-1; x>=it; x--){
          cout<<"start loop"<<endl;
          reg=reg_par[regs_index%8];
          cout<<"x: "<<x<<endl;
          cout<<"begin x: "<<x<<" "<<function_arguments_name[x]<<endl;
          x86="\tmovq "+to_string(get_offset(function_arguments_name[x]))+"(%rbp), "+reg;
          cout<<"end x: "<<x<<" "<<function_arguments_name[x]<<endl;
          x86_64_code.push_back(x86);
          x86="\tmovq "+reg+", 0(%rsp)";
          x86_64_code.push_back(x86);
          if(x!=it){
          x86="\tsubq $16, %rsp";
          x86_64_code.push_back(x86);
          current_local_symbol_table->curr_offset-=16;}
          regs_index++;
          cout<<"regs_index: "<<regs_index<<endl;
        }
        cout<<"for_loop end1"<<endl;
        // string reg3=regs[regs_index%8];
        current_local_symbol_table->regs_index=regs_index;
        x86="\tcall "+charPtrToString(($1).lexeme);
        x86_64_code.push_back(x86);
        regs_index=current_local_symbol_table->regs_index;
        string reg3=regs[regs_index%8];
        x86="\tmovq %rax, "+reg3;
        x86_64_code.push_back(x86);
        regs_index++;
        current_local_symbol_table->regs_index=regs_index;
        x86="\tsubq $16, %rsp";
        x86_64_code.push_back(x86);
        current_local_symbol_table->curr_offset-=16;
        current_local_symbol_table->offsets[charPtrToString($$.tempvar)]=current_local_symbol_table->curr_offset;
        x86="\tmovq "+reg3+", "+to_string(current_local_symbol_table->curr_offset)+"(%rbp)";
        x86_64_code.push_back(x86);
      }
    else if(charPtrToString(($1).lexeme)=="print"){
        it = 0;
        if(it<function_arguments_name.size()){
          cout<<"print_arguments=="<<function_arguments_name[it]<<" "<<get_offset(expr_value)<<endl;

          x86="\tmovq "+to_string(get_offset(function_arguments_name[it]))+"(%rbp), %rdi";
          x86_64_code.push_back(x86);
          it++;}
        x86="\tmovq %rdi, %rsi";
        x86_64_code.push_back(x86);
          if(charPtrToString(($2).type) != "str"){x86="\tleaq .LC0(%rip), %rdi";
          x86_64_code.push_back(x86);}
          else if(charPtrToString(($2).type) == "str"){
            x86="\tleaq .LC1(%rip), %rdi";
            x86_64_code.push_back(x86);
          }
        // x86_64_code.push_back(x86);
        x86="\tcall printf@PLT";
        x86_64_code.push_back(x86);
    }
    else if(charPtrToString(($1).lexeme) == "len" && charPtrToString(($2).type) == "str"){
      int offset = current_local_symbol_table->offsets[charPtrToString(($2).lexeme)];
      cout<<"hereeeeee "<<charPtrToString(($2).lexeme)<<endl;
      x86 = "\tmovq "+to_string(offset)+"(%rbp), %rdi";
      x86_64_code.push_back(x86);
      x86 = "\tcall strlen";
      x86_64_code.push_back(x86);
        int regs_index=current_local_symbol_table->regs_index;
        string reg3=regs[regs_index%8];
        x86="\tmovq %rax, "+reg3;
        x86_64_code.push_back(x86);
        regs_index++;
        current_local_symbol_table->regs_index=regs_index;
        x86="\tsubq $16, %rsp";
        x86_64_code.push_back(x86);

      string t = newtemp();
      current_local_symbol_table->curr_offset-=16;
      current_local_symbol_table->offsets[t] = current_local_symbol_table->curr_offset;
      x86 = "\tmovq "+reg3+", "+to_string(current_local_symbol_table->curr_offset)+"(%rbp)";
      x86_64_code.push_back(x86);
      $$.tempvar = stringToCharArray(t);
    }else if(charPtrToString(($1).lexeme) == "len"){
      int result = (current_local_symbol_table->variables[($2).lexeme]->size)/4;
      cout<<"sizeeee = "<<result<<endl;
      string t = newtemp();
      current_local_symbol_table->curr_offset-=16;
      current_local_symbol_table->offsets[t] = current_local_symbol_table->curr_offset;
      string x86 = "\tmovq $"+to_string(result)+", "+to_string(current_local_symbol_table->curr_offset)+"(%rbp)";
      x86_64_code.push_back(x86);
      $$.tempvar = stringToCharArray(t);
    }
      else if (charPtrToString(($1).lexeme)=="range"){
        if(function_arguments_name.size() == 2){
            range1 = function_arguments_name[0];
            range2 = function_arguments_name[1];
            // cout<<first<<" "<<second<<endl;
        }else if(function_arguments_name.size() == 1){
          range1 = "0";
          range2 = function_arguments_name[0];
        }

        if(isInteger(range1)){
          current_local_symbol_table->curr_offset -= 16;
          current_local_symbol_table->offsets[range1] = current_local_symbol_table->curr_offset;
          x86_64_code.push_back("\tmovq $"+range1+", "+to_string(current_local_symbol_table->curr_offset)+"(%rbp)");
        }
        if(isInteger(range2)){
          current_local_symbol_table->curr_offset -= 16;
          current_local_symbol_table->offsets[range2] = current_local_symbol_table->curr_offset;
          x86_64_code.push_back("\tmovq $"+range2+", "+to_string(current_local_symbol_table->curr_offset)+"(%rbp)");
        }
    }
    }
  //   else if (charPtrToString(($1).lexeme)=="range"){
  //     if(function_arguments_name.size() == 2){
  //         range1 = function_arguments_name[0];
  //         range2 = function_arguments_name[1];
  //         // cout<<first<<" "<<second<<endl;
  //     }else if(function_arguments_name.size() == 1){
  //       range1 = "0";
  //       range2 = function_arguments_name[0];
  //     }

  //     if(isInteger(range1)){
  //       current_local_symbol_table->curr_offset -= 16;
  //       current_local_symbol_table->offsets[range1] = current_local_symbol_table->curr_offset;
  //       x86_64_code.push_back("\tmovq $"+range1+", "+to_string(current_local_symbol_table->curr_offset)+"(%rbp)");
  //     }
  //     if(isInteger(range2)){
  //       current_local_symbol_table->curr_offset -= 16;
  //       current_local_symbol_table->offsets[range2] = current_local_symbol_table->curr_offset;
  //       x86_64_code.push_back("\tmovq $"+range2+", "+to_string(current_local_symbol_table->curr_offset)+"(%rbp)");
  //     }
  //  }
    function_arguments_name.clear();
   cout<<"is_array=="<<($2).is_array<<" "<<yylineno<<is_func_param<<" "<<yylineno<<endl;
    if(($2).is_array == 1 && is_func_param==0&&charPtrToString(($1).lexeme)!="list") {
      cout<<"arrrraaay"<<yylineno<<endl;
      string a = newtemp();
      $$.tempvar = stringToCharArray(newtemp());
      emit("+",charPtrToString(($1).lexeme),charPtrToString(($2).tempvar),a,-1);
      string b="*("+a+")";
      emit("=",b,"",$$.tempvar,-1);
      string type=charPtrToString(($1).type).substr(4,charPtrToString(($1).type).size());
      int siz=size(type,charPtrToString(($1).lexeme));
      if(siz<=8) siz=16;
      string str1 = charPtrToString(($2).lexeme);
      //cout<<str1<<endl;
      // if(isInteger(str1)){
        // cout<<"VALLLLLL:"<<($2).val<<endl;
      // int off=current_local_symbol_table->offsets[charPtrToString(($1).lexeme)];
      // current_local_symbol_table->offsets[charPtrToString($$.tempvar)]=off+((($2).val)*16);
      // cout<<"offsets: "<<current_local_symbol_table->offsets[charPtrToString($$.tempvar)]<<" "<<yylineno<<endl;
      // }
       int regs_index=current_local_symbol_table->regs_index;
      string x86;
      if(isInteger(str1)&&($2).tempvar==NULL){
      x86="\tmovq $"+charPtrToString(($2).lexeme)+"(%rbp), "+regs[regs_index%8];
      x86_64_code.push_back(x86);
      }
      else if(($2).tempvar==NULL){
      cout<<($2).lexeme<<" "<<current_local_symbol_table->offsets[charPtrToString(($2).lexeme)]<<" "<<yylineno<<"is_array====1"<<endl;
      x86="\tmovq "+to_string(current_local_symbol_table->offsets[charPtrToString(($2).lexeme)])+"(%rbp), "+regs[regs_index%8];
      x86_64_code.push_back(x86);}
      else{
        cout<<"IIIIII AAAAAAAAAAAMMMMMMMMM "<<current_local_symbol_table->offsets[charPtrToString(($2).tempvar)]<<endl;
      if(current_local_symbol_table->offsets[charPtrToString(($2).tempvar)]!=0)
      x86="\tmovq "+to_string(current_local_symbol_table->offsets[charPtrToString(($2).tempvar)])+"(%rbp), "+regs[regs_index%8];
      else{
        cout<<"ppppp"<<yylineno<<endl;
      x86="\tmovq "+to_string(current_local_symbol_table->offsets[charPtrToString(($2).lexeme)])+"(%rbp), "+regs[regs_index%8];}
      x86_64_code.push_back(x86);
      }
      x86="\timulq $16 ,"+regs[regs_index%8];
      x86_64_code.push_back(x86);
      x86="\tsubq $16, %rsp";
      x86_64_code.push_back(x86);
      current_local_symbol_table->curr_offset-=16;
      x86="\tmovq "+regs[regs_index%8]+", "+to_string(current_local_symbol_table->curr_offset)+"(%rbp)";
      x86_64_code.push_back(x86);
      regs_index++;
      x86="\tmovq "+to_string(current_local_symbol_table->offsets[($1).lexeme])+"(%rbp), "+regs[regs_index%8];
      x86_64_code.push_back(x86);
      x86="\taddq "+to_string(current_local_symbol_table->curr_offset)+"(%rbp), "+regs[regs_index%8];
      x86_64_code.push_back(x86);
      regs_index++;
      x86="\tmovq ("+regs[(regs_index-1)%8]+"), "+regs[regs_index%8];
      x86_64_code.push_back(x86);
      x86="\tsubq $16, %rsp";
      x86_64_code.push_back(x86);
      current_local_symbol_table->curr_offset-=16;
      x86="\tmovq "+regs[regs_index%8]+", "+to_string(current_local_symbol_table->curr_offset)+"(%rbp)";
      x86_64_code.push_back(x86);
      regs_index++;
      current_local_symbol_table->regs_index=regs_index;
      current_local_symbol_table->offsets[charPtrToString($$.tempvar)]=current_local_symbol_table->curr_offset;
      //x86=


    }
    $$.is_array=0;
    ($2).is_array = 0;

    dot_present=0;
    cout<<"exit atom_expr"<<endl;
}
| atom{
  $$.lexeme = ($1).lexeme; 
  $$.type=($1).type;
  cout<<"atom_expr "<<$$.lexeme<<endl;
  $$.tempvar = ($1).tempvar;
//function_arguments.clear();
};
optional_trailer:trailer {
  $$.lexeme = ($1).lexeme;
  $$.type=($1).type;
  $$.tempvar = ($1).tempvar;
  is_func_dot=is_dot;
    $$.is_array = ($1).is_array;
  }
| optional_trailer trailer {
  is_func_dot=is_dot;
  $$.is_array = ($2).is_array;
  $$.lexeme = ($2).lexeme;
  if(is_lsq)
  type_errors[type_error_line]="Array at "+to_string(type_error_line)+" accessed with more dimensions than expected" ;
}
               ;
atom: LPAREN w RPAREN {
  $$.lexeme=($2).lexeme;
  $$.type=($2).type;
  $$.tempvar = ($2).tempvar;
  // cout<<"atom1 w "<<$$.type<<endl;
}
      | LSQBRACKET w RSQBRACKET {    
$$.type=($2).type;
$$.lexeme=($2).lexeme;
$$.tempvar = ($2).tempvar;
}
      | LCBRACE x RCBRACE {
       
}
      | NAME {
        if(strcmp($1,"int")==0 || strcmp($1,"float")==0 || strcmp($1,"str")==0 || strcmp($1,"bool")==0 || strcmp($1,"list")==0){
        //cout<<"Type: "<<$1<<" "<<yylineno<<endl;
        current_type = $1;
        $$.type = $1;
        $$.lexeme=$1;
        // if(current_variable=="a") cout<<"a->type: "<<($$).type<<endl;
        if(strcmp($1,"float")==0){
        current_type = "float";
        $$.type = "float";}
        if(is_list==1) {
        // cout<<"is_list: "<<$1<<" "<<current_variable<<endl;
        // cout<<"list_type before: "<<list_type<<endl;
        list_type=$1; 
        // cout<<"list_type: "<<list_type<<endl;
        current_local_symbol_table->variables[current_variable]->type="list"+charPtrToString($1);
        // cout<<"current_local_symbol_table->variables[current_variable]->type: "<<current_local_symbol_table->variables[current_variable]->type<<endl;
        $$.type = stringToCharArray(current_local_symbol_table->variables[current_variable]->type);}
        if(is_list==0&&!scope_stack.empty()&&scope_stack.top()==":"){
        // cout<<"atom if current_variable: "<<current_variable<<" "<<$1<<endl;
        if(current_local_symbol_table->variables[current_variable]->type=="") {

          // cout<<"atom if current_variable if: "<<current_variable<<" "<<current_type<<endl;
          current_local_symbol_table->variables[current_variable]->type = current_type;}
        else {
        // cout<<"atom ";
        //cout << "Error: Variable " << current_variable <<" at "<<redeclared_line<< " already declared" << endl;
        declared_error[yylineno]="Variable " + current_variable + " at line " + to_string(yylineno) + " already declared";
        //exit(EXIT_FAILURE);
        }
        scope_variable.erase(current_line);}
        is_list=0;
        if(strcmp($1,"list")==0){is_list=1; }
        scope_stack.push($1);}
        else if(current_local_symbol_table->variables.find($1) == current_local_symbol_table->variables.end()){
        //$$.type="";
        // cout<<"before scope: "<<current_local_symbol_table->scope<<" "<<$1<<endl;
        LocalSymbolTable* a=find_table($1,global_table);
        // if(a!=NULL)
        // cout<<"scopes: "<<current_local_symbol_table->scope<<" "<<a->scope<<endl;
        LocalSymbolTable *temp = NULL;
        if(a!=NULL) temp=a;
        //if(temp==NULL) cout<<"temp=NULL "<<yylineno<<endl;
        //if(a==NULL) cout<<"a=NULL "<<yylineno<<endl;
        if(!scope_stack.empty()&&scope_stack.top()==":"){
        // cout<<"atom if current_variable if: "<<current_variable<<" "<<$1<<endl;
        if(temp!=NULL&&temp->scope=="class"){
        // cout<<"temp!=NULL "<<$1<<endl;
        current_local_symbol_table->variables[current_variable]->type = $1;
        scope_variable.erase(current_line);}
        scope_stack.push($1);
        $$.lexeme = $1;}
        else if(temp!=NULL){
        scope_stack.push($1);
        $$.lexeme = $1;
        }
        else{
        // cout<<"current_local_symbol_table->scope: 2 "<<current_local_symbol_table->scope<<endl;
        current_variable=$1;
        current_line=yylineno;
        if(variables.find(charPtrToString($1))==variables.end()){
        if((!Lookup($1,current_scope,yylineno, current_local_symbol_table))) Entry("", current_variable, current_scope, current_line);
        else $$.type=stringToCharArray(Lookup_table($1,current_local_symbol_table)->variables[$1]->type);}
        if(!Lookup($1,current_scope,yylineno, current_local_symbol_table)&&Find_children($1, current_local_symbol_table)) {
          //if(current_variable=="ShiftReduceParser") cout<<"ShiftReduceParser in scope variable "<<current_scope<<" "<<yylineno<<endl;
          // cout<<"atom else if else "<<$1<<" "<<yylineno<<endl;
          scope_variable[current_line]=current_variable;}
        // cout<<"atom else if current_variable name: "<<$1<<" "<<yylineno<<endl;
        scope_stack.push($1);
        $$.lexeme = $1;}
        }
        else{
        //$$.type="";
        //if(scope_stack.top==":")
        $$.lexeme = $1;
        string x=$1;
        // cout<<"1$1: "<<$1<<endl;
        //$$.type = current_local_symbol_table->variables[$1]->type;
        if(variables.find($1) == variables.end()){
        // cout<<"2$1: "<<$1<<endl;
        LocalSymbolTable* a=Lookup_table($1,current_local_symbol_table);
        // cout<<"3$1: "<<$1<<endl;
        if(a!=NULL){
        // cout<<"4$1: "<<$1<<" "<<endl;
        // strcpy($$.type, a->variables[x]->type.c_str());
        $$.type=(char*)a->variables[x]->type.c_str();
        // cout<<"$$.type "<<$$.type<<endl;
        // strcpy($1,x.c_str());
        // cout<<"5$1: "<<$1<<" "<<x<<" $$.type: "<<$$.type<<endl;
        }
        }
        else {
          //cout<<"here: "<<$1<<endl; 
        $$.type="";}
        //strcpy($1,x.c_str());
        // cout<<"atom else current_variable: "<<$1<<" "<<$$.type<<" "<<yylineno<<endl;
        // current_variable=$1;
        // current_line=yylineno;
        redeclared_line=yylineno;
        if(variables.find($1) == variables.end()){
        is_lookup=Lookup($1, current_scope, yylineno, current_local_symbol_table);}
        if(is_lookup==0&&Find_children($1, current_local_symbol_table)&&current_local_symbol_table->variables.find($1)!=current_local_symbol_table->variables.end()&&current_local_symbol_table->variables[$1]->type == ""){
        if(variables.find($1) == variables.end()&&current_local_symbol_table->children.find($1)==current_local_symbol_table->children.end()){
        // if($1=="ShiftReduceParser") cout<<"ShiftReduceParser in scope variable else "<<current_scope<<" "<<yylineno<<endl;
  scope_variable[yylineno]=$1;
  }}
        scope_stack.push($1);
        }
        // cout<<"NAMEEEE"<<$$.lexeme<<" "<<$1<<endl;
      }
       | NUMBER {
        // cout<<"atom number1 "<<$1<<endl;
        // string a=charPtrToString($1);
        // cout<<"atom number21 "<<$1<<endl;
        // string b=determineNumberType(a);
        // cout<<"atom number22 "<<$1<<endl;
        // $$.lexeme=$1;
        // cout<<"atom number3 "<<$1<<endl;
        // $$.type=stringToCharArray(b);
        // cout<<"atom number4 "<<$1<<endl;
        $$.type="int";
        $$.lexeme=$1;
      string var = newtemp();
      string x86;
      // strcpy($$.tempvar, var);
      $$.tempvar = stringToCharArray(var);
      current_local_symbol_table->curr_offset-=16;
      current_local_symbol_table->offsets[var]=current_local_symbol_table->curr_offset;
      x86 = "\tsubq $16, %rsp";
      x86_64_code.push_back(x86);
      x86="\tmovq $"+charPtrToString(($1))+", "+to_string(current_local_symbol_table->curr_offset)+"(%rbp)";
      x86_64_code.push_back(x86);
        ///////////3AC///////////
        // string var = newtemp();
        // strcpy($$.tempvar, var);
        // $$.tempvar = stringToCharArray(var);
        // char* op = stringToCharArray("=");
        $$.is_number = 1;
      }
        | multi_string {
          $$.type="str";
          $$.lexeme=($1).lexeme;
          $$.tempvar = ($1).tempvar;

         }
        | TRIPLEDOT {
         $$.lexeme=$1; 
         }
        | NONE {
         $$.lexeme=$1;
         $$.type="None";
         if(is_list==0&&!scope_stack.empty()&&scope_stack.top()==":"){
        // cout<<"atom None current_variable: "<<current_variable<<endl;
        if(current_local_symbol_table->variables[current_variable]->type=="") {
          // cout<<"atom None current_variable if: "<<current_variable<<endl;
          type_errors[yylineno]="Type of variable at line "+to_string(yylineno)+" can not be None";
        }
        scope_variable.erase(current_line);}
        scope_stack.push($1);
          }
        | RIGHT {
          $$.type="bool";
          $$.lexeme=$1;
          // cout<<"right "<<$$.type<<endl;
         }
        | WRONG {
          $$.type="bool";
          $$.lexeme=$1;
         };
multi_string: multi_string STRING {
 $$.type="str";
 string a(($1).lexeme);
  string b($2);
  string c = b+a;
$$.lexeme=new char[c.length()+1];
strcpy($$.lexeme,c.c_str());
string str=newstr();
  str_map[charPtrToString($$.lexeme)]=str;
  string s=str+":\n\t.string "+charPtrToString($$.lexeme);
  str_list.push_back(s);
}
| STRING {
  $$.type="str";
cout<<"stringgg"<<endl;
  cout<<"string =="<<$1<<endl;
    $$.lexeme=$1;
  // cout<<"multi_string "<<$$.lexeme<<endl;
  string a = newtemp();
  emit("=",charPtrToString($1),"",a,-1);
  $$.tempvar = stringToCharArray(a);
  // tempvar_string[a] = $1;
  // string x86="\tsubq $16, %rsp";
  // x86_64_code.push_back(x86);
  current_local_symbol_table->curr_offset-=16;
  current_local_symbol_table->offsets[a]=current_local_symbol_table->curr_offset;

  string x86="\tsubq $16, %rsp";
  x86_64_code.push_back(x86);
  string str=newstr();
  x86="\tmovq $"+str+", "+to_string(current_local_symbol_table->curr_offset)+"(%rbp)";
  x86_64_code.push_back(x86);
  str_map[$1]=str;
  string s=str+":\n\t.string "+charPtrToString($1);
  str_list.push_back(s);
    current_local_symbol_table->curr_offset-=16;
  current_local_symbol_table->offsets[$1]=current_local_symbol_table->curr_offset;

}; 
w: testlist_comp {
  $$.type=($1).type;
  $$.lexeme=($1).lexeme;
  $$.tempvar = ($1).tempvar;
  // cout<<"w "<<$$.type<<endl;
  }
| /* empty */{
  $$.type="";
  $$.lexeme="";
  };
x: dictorsetmaker {
  }
  | /* empty */{};
testlist_comp: test comp_for_sub {
  $$.type=($1).type;
  $$.lexeme=($1).lexeme;
  lex_list_members.insert(lex_list_members.begin(), ($1).lexeme);
  if(($1).tempvar!=NULL) {list_members.insert(list_members.begin(),($1).tempvar); cout<<($1).tempvar<<endl;}
  else list_members.insert(list_members.begin(),($1).lexeme);
  //string a=current_local_symbol_table->variables[($1).lexeme]->type;
 //a=a.substr(4,a.size());
 arr_size+=size(($1).type,($1).lexeme);
  if(($2).lexeme == NULL) {cout<<"testlist1"<<endl;$$.tempvar = ($1).tempvar;}
  }
 ;
comp_for_sub:  NT d {
  $$.type=($1).type;
  }
            |d {
              $$.type="";
              }
 ;
NT: COMMA test {
  // cout<<"NT "<<yylineno<<endl;
  $$.type=($2).type;
  if(($2).tempvar!=NULL) list_members.push_back(($2).tempvar);
  else list_members.push_back(($2).lexeme);
  lex_list_members.push_back(($2).lexeme);
 //string a=current_local_symbol_table->variables[($2).lexeme]->type;
 //a=a.substr(4,a.size());
 arr_size+=size(($2).type,($2).lexeme);
}
| NT COMMA test {
  $$.type=($3).type;
 if(($3).tempvar!=NULL) list_members.push_back(($3).tempvar);
  else list_members.push_back(($3).lexeme);
 //string a=current_local_symbol_table->variables[($3).lexeme]->type;
 //a=a.substr(4,a.size());
 lex_list_members.push_back(($3).lexeme);
 arr_size+=size(($3).type,($3).lexeme);
}
                                  ;
// test_or_star_expr : test {cout<<"test_or_star_expr"<<endl;}
//                   | star_expr 
//                   ;
lpa: LPAREN{
  is_paren=1; 
  // cout<<"lpa1 "<<yylineno<<endl;
  function_arguments.clear();
  func.push(function_arguments);
  // cout<<"lpa2 "<<yylineno<<endl;
  // if(func_running.empty()){cout<<"func_running empty"<<endl;}
  // else {
  //   cout<<"func_running not empty "<<func_running.top()<<endl;
  // }
  func_running.push(1);
  // cout<<"lpa end "<<yylineno<<endl;
};
lsq: LSQBRACKET{
  is_lsq=1; 
  type_error_line=yylineno;
};
trailer: lpa y RPAREN {
  // cout<<"trailer1 "<<yylineno<<endl;
  func_running.pop();
  // if(!func_running.empty()) cout<<"func_running not empty in trailer "<<func_running.top()<<endl;
  // else cout<<"func_running empty in trailer "<<endl;
  // cout<<"trailer2 "<<yylineno<<endl;
  func_error_line=yylineno;
  $$.lexeme=($2).lexeme;
  $$.type = ($2).type;
  // cout<<"func push"<<endl;
  if(charPtrToString(($2).lexeme)=="")
  func.push(function_arguments);
  $$.lexeme=($2).lexeme;
}
   | lsq subscriptlist RSQBRACKET {
    // cout<<"lsq trailer1 "<<yylineno<<endl;
    is_lsq=1;
    $$.type=($2).type;
    $$.lexeme=($2).lexeme;
    $$.is_array = 1;
    // cout<<"is_func_param "<<is_func_param<<" "<<yylineno<<endl;
    if(is_func_param==0){
    string a=newtemp();
    // cout<<"lsq trailer2 "<<yylineno<<endl;
    string b=to_string(size(($2).type,($2).lexeme));
    // cout<<"lsq trailer3 "<<yylineno<<endl;
    emit("=",b,"",a,-1);
    $$.tempvar=stringToCharArray(newtemp());
    // if(($2).tempvar==NULL) cout<<"$2 tempvar NULL"<<endl;
    if(($2).tempvar!=NULL){
    emit("*",($2).tempvar,a,$$.tempvar,-1);
    current_local_symbol_table->offsets[charPtrToString(($$).tempvar)]=current_local_symbol_table->offsets[charPtrToString(($2).tempvar)];}
    else emit("*",($2).lexeme,a,$$.tempvar,-1);

  
  }
  
}
   | DOT NAME{
        dot_name = charPtrToString($2);
    cout<<"dot name"<<($2)<<endl;
    dot_present = 1;
    $$.lexeme = $2;
    $$.is_class_dot=1;
    is_dot=$2;
    if(current_local_symbol_table->variables.find($2) == current_local_symbol_table->variables.end()){
        //$$.type="";
        // cout<<"dot if current_variable: "<<$2<<" "<<scope_stack.top()<<" "<<yylineno<<endl;
        LocalSymbolTable* a;
        LocalSymbolTable* b=find_table(scope_stack.top(),global_table);
        LocalSymbolTable *c = NULL;
        if(b!=NULL&&is_ancestor(b,current_local_symbol_table)) c=b;
        if(global_table!=NULL&&global_table->variables.find(scope_stack.top()) == global_table->variables.end()&&current_local_symbol_table->variables.find(scope_stack.top()) != current_local_symbol_table->variables.end()){
        a=find_table(current_local_symbol_table->variables[scope_stack.top()]->type,global_table);}
        else {
          // cout<<"a=NULL"<<endl; 
          a=NULL;}
        LocalSymbolTable *temp = find_table($2, a);
        // cout<<"temp=NULL"<<endl;
        if(!scope_stack.empty()&&scope_stack.top()==":"){
        // cout<<"atom if current_variable if: "<<current_variable<<" "<<$1<<endl;
        if(temp!=NULL&&temp->scope=="class"){
        // cout<<"temp!=NULL "<<$2<<endl;
        current_local_symbol_table->variables[current_variable]->type = $2;
        scope_variable.erase(current_line);}
        scope_stack.push($2);}
        else if(temp!=NULL){
        scope_stack.push($2);
        }
        else{
        // cout<<"current_local_symbol_table->scope: 2 "<<current_local_symbol_table->scope<<endl;
        current_variable=$2;
        // if(current_variable=="bubbleSort") cout<<"bubbleSort in scope variable "<<current_scope<<" "<<yylineno<<endl;
        current_line=yylineno;
        if(variables.find(charPtrToString($2))==variables.end()){
        if((!Lookup($2,current_scope,yylineno, current_local_symbol_table))) Entry("", current_variable, current_scope, current_line);
        else $$.type=stringToCharArray(Lookup_table($2,current_local_symbol_table)->variables[$2]->type);}
        if(!Lookup($2,current_scope,yylineno, current_local_symbol_table)&&Find_children($2, current_local_symbol_table)) {
          //if(current_variable=="ShiftReduceParser") cout<<"ShiftReduceParser in scope variable "<<current_scope<<" "<<yylineno<<endl;
          scope_variable[current_line]=current_variable;}
        // cout<<"atom else if current_variable: "<<$2<<" "<<yylineno<<endl;
        scope_stack.push($2);}
        }
        else{
        //$$.type="";
        //cout<<"atom else current_variable dot: "<<$2<<" "<<yylineno<<endl;
        // current_variable=$1;
        // current_line=yylineno;
        redeclared_line=yylineno;
        if(variables.find($2) == variables.end()){
        is_lookup=Lookup($2, current_scope, yylineno, current_local_symbol_table);}
        if(is_lookup==0&&Find_children($2, current_local_symbol_table)&&current_local_symbol_table->variables.find($2)!=current_local_symbol_table->variables.end()&&current_local_symbol_table->variables[$2]->type == ""){
        if(variables.find($2) == variables.end()&&current_local_symbol_table->children.find($2)==current_local_symbol_table->children.end()){
        //if($2=="ShiftReduceParser") cout<<"ShiftReduceParser in scope variable else "<<current_scope<<" "<<yylineno<<endl;
  scope_variable[yylineno]=$2;
  }}
        scope_stack.push($2);
  }
};
y: arglist {
 $$.lexeme = ($1).lexeme; 
 int i;
  $$.type = ($1).type;
  $$.tempvar = ($1).tempvar;

 //cout<<"arguments "<<function_arguments[0]<<" "<<current_local_symbol_table->parameter_types[0]<<endl;
//  for(i=0; i<function_arguments.size(); i++){
//   if(i<current_local_symbol_table->parameter_types.size()&&function_arguments[i]!=current_local_symbol_table->parameter_types[i])
//   scope_variable[yylineno]=".Function called with type mismatch in parameter "+to_string(i+1)+" on line "+to_string(yylineno);
//   else if(i>=current_local_symbol_table->parameter_types.size())
//   scope_variable[yylineno]=".Function called with extra parameters on line "+to_string(yylineno);}
//   if(i<current_local_symbol_table->parameter_types.size())
//   scope_variable[yylineno]=".Function called with less parameters on line "+to_string(yylineno);
//   function_arguments.clear();
  }
  | /* empty */{
    $$.lexeme = "";
    // if(current_local_symbol_table->parameter_types.size()!=0)
    // scope_variable[yylineno]=".Function called with less parameters on line "+to_string(yylineno);
    // function_arguments.clear();
  };
// subscriptlist: subscript (',' subscript)* i;
subscriptlist: subscript optional_comma_subscript d{
 $$.type=($1).type; 
 $$.lexeme=($1).lexeme;
 $$.tempvar=($1).tempvar;
 type_error_line=yylineno;
};

optional_comma_subscript: /*empty*/ {
 }
                        | optional_comma_subscript COMMA subscript{
                          //array_elements.push_back(($3).lexeme);
                          }
                        ;

subscript: test {
  // cout<<"subscript1 "<<yylineno<<endl;
  $$.type=($1).type;
  // cout<<"subscript2 "<<yylineno<<endl;
  $$.lexeme=($1).lexeme;
  // cout<<"subscript3 "<<yylineno<<endl;
  $$.tempvar=($1).tempvar;
  // cout<<"subscript4 "<<yylineno<<endl;
  }
|test COLON test sliceop{
}
|test COLON test{
  
}
|COLON test sliceop {
}
|COLON test{
}
|test COLON sliceop{
  
}
|test COLON {
  
}
|COLON sliceop{
}
|COLON{
}
;

// s_o: sliceop 
//   | /* empty */;
sliceop: COLON test {
}
|COLON {
};

exprlist: expr optional_comma_expr COMMA {
}
|expr optional_comma_expr{
} 
|expr COMMA {
}
|expr {
  $$.type=($1).type;
  $$.tempvar = ($1).tempvar;

  }
;

optional_comma_expr: COMMA expr {
}
                  | optional_comma_expr COMMA expr {
                  
                  };

testlist: test optional_comma_test {
  $$.lexeme = ($1).lexeme;

}
          |test optional_comma_test COMMA{
  $$.lexeme = ($1).lexeme;
            
          }
          |test COMMA{
  $$.lexeme = ($1).lexeme;
            
          }
          |test { 
          $$.type=($1).type;
  $$.lexeme = ($1).lexeme;
  $$.tempvar = ($1).tempvar;
  string reg=getreg(($1).lexeme);
  string x86="\tmovq "+reg+", %rax";
  x86_64_code.push_back(x86);
            }
          ;
optional_comma_test: COMMA test {

}
 | optional_comma_test COMMA test {
    
 } ;
// dictorsetmaker: ((test ':' test | '**' expr)(comp_for | (',' (test ':' test | '**' expr))* [','])) |
//                   ((test | star_expr) (comp_for | (',' (test | star_expr))* [',']))
dictorsetmaker: ran_out_of_names comp_for_optional_comma_r {
 
}
              | test non_terminal {
               }
              ;

non_terminal: optional_comma_test d {
  
}
            | d {
              }
            ; /*naam hi nahi bacche :(*/

comp_for_optional_comma_r: optional_comma_r d {

 }
| d {}
;
optional_comma_r: COMMA ran_out_of_names {
  }
                | optional_comma_r COMMA ran_out_of_names{
                  }
                ;
ran_out_of_names: test COLON test {
 
}
                ;
classdef: class_start COLON suite {
//   all_tables.push_back(current_local_symbol_table);
    string vtable = "vtable";
    string space = " ";
    string res = vtable + space;
    string res1 = res + class_nam;
    string functions = concatenateWithCommas(func_names);
    int n = func_names.size();
    // cout<<"vtable1"<<n<<endl;
        emit("=",functions,"",res1,-1);
        func_names.clear();
  current_local_symbol_table=global_table;
  current_scope=current_local_symbol_table->scope;
  stack<string>().swap(scope_stack);
  // cout<<"scope="<<current_local_symbol_table->scope<<endl;
  emit("end_class","","","",-1);
}
        ;
class_start: class_name arg{
  class_offset = 0;
  $$.lexeme = ($1).lexeme;
  LocalSymbolTable* temp = new LocalSymbolTable(variable,address_descriptor,register_descriptor,offsets,0,0, "","", parameter_types, "", yylineno,0, "class", current_local_symbol_table, children);
  temp->line_number = yylineno;
  temp->scope="class";
  if(($2).lexeme!=""){
    LocalSymbolTable* temp1 = find_table(($2).lexeme, global_table);
    temp->parent = temp1; 
    temp1->children[($1).lexeme] = temp;
    current_local_symbol_table = temp;
      cout<<"loop"<<endl;
    int parent_size = temp1->offsets.size();
    for(int i= temp1->offsets.size()-1; i>=0; i--){
      
      auto it = temp1->offsets.begin();
      cout<<"it->first=="<<it->first<<endl;
      advance(it,i);
      temp->offsets[it->first] = self_offset;
      self_offset+=16;
    }
  
    cout<<"self_offset=="<<self_offset<<endl;
    class_offset = self_offset;
current_local_symbol_table = temp;
  } 
  else{
    temp->parent = current_local_symbol_table;
    // cout<<"class_start: "<<($1).lexeme<<endl;
    current_local_symbol_table->children[($1).lexeme] = temp;
    current_local_symbol_table = temp;
  }
  class_arg = 0;
  emit("begin_class","","","",-1);
};
class_name: CLASS NAME{
  $$.lexeme = $2;
  class_nam = charPtrToString($2);
  class_arg = 1;
//   class_offset = 0;


};
arg: arg_list{
  $$.lexeme = ($1).lexeme;}
  | /* empty */{$$.lexeme = "";};
arg_list: LPAREN y RPAREN{
 $$.lexeme = ($2).lexeme; };
// arglist: argument (',' argument)*  [',']
arglist: argument optional_comma_arguement d{
  $$.lexeme = ($1).lexeme;
  // if($$.lexeme!=NULL)
    // cout<<"arglist "<<yylineno<<endl;
  if(is_paren==1){
  //function_arguments=func.top();
  if(!func.empty()){
  // cout<<"function_arguments=func.top()"<<endl;
  function_arguments=func.top();
  // cout<<"end 1"<<endl;
  }
  if(variables.find(($1).lexeme)==variables.end()){
    function_arguments.insert(function_arguments.begin(),($1).type);
    if(($1).tempvar!=NULL) function_arguments_name.insert(function_arguments_name.begin(),($1).tempvar);
    else function_arguments_name.insert(function_arguments_name.begin(),($1).lexeme);
  }
  //else function_arguments.insert(function_arguments.begin(),"");
  // else function_arguments.insert(function_arguments.begin(),"");
  // for(int i=0; i<function_arguments.size(); i++){
  //   cout<<"function_arguments: "<<function_arguments[i]<<endl;
  // }
  if(!func.empty()) func.pop();
  func.push(function_arguments);
  }
  // else cout<<"is_paren==0"<<endl;
  //////////////////3AC///////////////////
  
  int sze=0;
  if(class_arg==0){
  if(($1).tempvar == NULL){
    //string a=current_local_symbol_table->variables[($1).lexeme]->type;
    string a="";
    string third = charPtrToString(($1).lexeme);
    LocalSymbolTable* temp=Lookup_table(($1).lexeme,current_local_symbol_table);
    if(temp!=NULL)a=temp->variables[($1).lexeme]->type;
    if(a.size()>=4&&a.substr(0,4)=="list") sze=temp->variables[($1).lexeme]->size;

    else if(third == "self") {
      // cout<<"selllllllffff"<<endl; 
      sze = class_offset;}
    else sze=size(($1).type,($1).lexeme);
    emit("push_param",charPtrToString(($1).lexeme),"","",-1);
    // emit("stack_pointer", "+" + to_string(sze),"","", -1);
   }
   else{
    sze=4;
    emit("push_param",charPtrToString(($1).tempvar),"","",-1);
    //  emit("stack_pointer", "+" + to_string(sze),"","", -1);
   }}
push_size+=sze;

}
|argument d{
  $$.lexeme = ($1).lexeme;
  $$.type = ($1).type;
  // if($$.lexeme!=NULL)
  // cout<<"arglist "<<" "<<$$.lexeme<<" "<<yylineno<<endl;
  if(is_paren==1){
  if(!func.empty()){
    function_arguments=func.top();
  }
  if(($1).type!=NULL)
  function_arguments.insert(function_arguments.begin(),($1).type);
  else function_arguments.insert(function_arguments.begin(),"");
  if(($1).tempvar!=NULL) function_arguments_name.insert(function_arguments_name.begin(),($1).tempvar);
      else function_arguments_name.insert(function_arguments_name.begin(),($1).lexeme);
  //func.push(function_arguments);
  if(!func.empty()) func.pop();
  func.push(function_arguments);
  }
  //push_size=0;
    int sze = 0;
  if(class_arg==0){if(($1).tempvar == NULL){
    //string a=current_local_symbol_table->variables[($1).lexeme]->type;
    string a="";
    string third = charPtrToString(($1).lexeme);
    // cout<<"argument1 "<<($1).lexeme<<" "<<yylineno<<endl;
    LocalSymbolTable* temp=Lookup_table(($1).lexeme,current_local_symbol_table);
    // cout<<"argument2 "<<($1).lexeme<<" "<<yylineno<<endl;
    if(temp!=NULL)a=temp->variables[($1).lexeme]->type;
    if(a.size()>=4&&a.substr(0,4)=="list") sze=temp->variables[($1).lexeme]->size;
    else if(third == "self") {
      // cout<<"selllllllffff"<<endl;
      sze = class_offset;}
    else sze=size(($1).type,($1).lexeme);
    emit("push_param",charPtrToString(($1).lexeme),"","",-1);
    //  emit("stack_pointer", "+" + to_string(sze),"","", -1);
   }else{
    sze=4;
    emit("push_param",charPtrToString(($1).tempvar),"","",-1);
    //  emit("stack_pointer", "+" + to_string(sze),"","", -1);
   }}
   push_size+=sze;

}
;
optional_comma_arguement: COMMA argument{
  if(is_paren==1){
  // function_arguments.clear();
    if(!func.empty()){
      // cout<<"function_arguments=func.top()"<<endl;
      function_arguments=func.top();
      // cout<<"end 3"<<endl;
    }
    function_arguments.insert(function_arguments.begin(),($2).type);
    if(($2).tempvar!=NULL) function_arguments_name.push_back(($2).tempvar);
      else function_arguments_name.push_back(($2).lexeme);
    // cout<<"optional_comma_arguement "<<($2).type<<" "<<yylineno<<endl;
    // for(int i=0; i<function_arguments.size(); i++){
    //   cout<<"function_arguments: "<<function_arguments[i]<<endl;}
      if(!func.empty()) func.pop();
    func.push(function_arguments);
  }
    $$.type=($2).type;
    //push_size=0;
  int sze = 0;
  if(class_arg==0){if(($2).tempvar == NULL){
    //string a=current_local_symbol_table->variables[($2).lexeme]->type;
    string a="";
    string third = charPtrToString(($2).lexeme);
    LocalSymbolTable* temp=Lookup_table(($2).lexeme,current_local_symbol_table);
    if(temp!=NULL)a=temp->variables[($2).lexeme]->type;
    if(a.size()>=4&&a.substr(0,4)=="list") sze=temp->variables[($2).lexeme]->size;
    else if(third == "self") {
      // cout<<"selllllllffff"<<endl;
      sze = class_offset;}
    else sze=size(($2).type,($2).lexeme);
    emit("push_param",charPtrToString(($2).lexeme),"","",-1);
    //  emit("stack_pointer", "+" + to_string(sze),"","", -1);
   }else{
    sze=4;
    emit("push_param",charPtrToString(($2).tempvar),"","",-1);
    //  emit("stack_pointer", "+" + to_string(sze),"","", -1);
   }}
push_size+=sze;

}
  | optional_comma_arguement COMMA argument{
    if(is_paren==1){
      if(!func.empty()){
      // cout<<"function_arguments=func.top()"<<endl;
      function_arguments=func.top();
      // cout<<"end 4"<<endl;
      }
      function_arguments.push_back(($3).type);
      if(($3).tempvar!=NULL) function_arguments_name.push_back(($3).tempvar);
      else function_arguments_name.push_back(($3).lexeme);
      // cout<<"optional_comma_arguement "<<($3).type<<" "<<yylineno<<endl;
      // for(int i=0; i<function_arguments.size(); i++){
      //   cout<<"function_arguments: "<<function_arguments[i]<<endl;
      // }
      if(!func.empty()) func.pop();
      func.push(function_arguments);
    }
  $$.type=($3).type;
  int sze= 0;
 if(class_arg==0){ if(($3).tempvar == NULL){
    string a="";
    string third = charPtrToString(($3).lexeme);
    LocalSymbolTable* temp=Lookup_table(($3).lexeme,current_local_symbol_table);
    if(temp!=NULL)a=temp->variables[($3).lexeme]->type;
    if(a.size()>=4&&a.substr(0,4)=="list") sze=temp->variables[($3).lexeme]->size;
    else if(third == "self") {
      // cout<<"selllllllffff"<<endl; 
      sze = class_offset;}
    else sze=size(($3).type,($3).lexeme);
    emit("push_param",charPtrToString(($3).lexeme),"","",-1);
    //  emit("stack_pointer", "+" + to_string(sze),"","", -1);
   }else{
    sze=4;
    emit("push_param",charPtrToString(($3).tempvar),"","",-1);
    //  emit("stack_pointer", "+" + to_string(sze),"","", -1);
   }}
push_size+=sze;

};
argument:test {
// cout<<"argument "<<yylineno<<endl;
 $$.lexeme = ($1).lexeme; 
 $$.type=($1).type;
 $$.tempvar = ($1).tempvar;}
        |test EQUAL test {
          $$.type=($1).type;};

%%

int main(int argc, char *argv[]){
  bool verbose = false;
   string input_file_name;
   string output_file_name;
   string tac_output;
   string asm_output;
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
        }else if(std::string(argv[i]) == "--tac" || std::string(argv[i]) == "-t"){
            if((i + 1) < argc) tac_output = argv[i+1];
          i++;
        }else if(std::string(argv[i]) == "--asm" || std::string(argv[i]) == "-s"){
          if((i + 1) < argc) asm_output = argv[i+1];
          i++;
        }
        else {
            cout << "Error: Invalid parameter\n";
            print_help_page();
            return -1;
        }
    }
    if(verbose) yydebug=1;

  // FILE *input_file = fopen(argv[1],"r");
    FILE *input_file = fopen(input_file_name.c_str(),"r");

      yyin = input_file;
  yyparse();
  // cout<<"start"<<endl;
  for (auto a = scope_variable.begin(); a != scope_variable.end(); ++a){
    if(variables.find(a->second)==variables.end()){
      if(func_errors.empty()||(!func_errors.empty()&&a->first<=func_errors.begin()->first)){
        if(type_errors.empty()||(!type_errors.empty()&&a->first<=type_errors.begin()->first)){
        if(!declared_error.empty()&&declared_error.begin()->first<=a->first) cout << declared_error.begin()->second<<"error"<<endl;
        else cout<<"Undeclared Variable "<<a->second<<" on line "<<a->first<<endl;}
        else {
        if(!declared_error.empty()&&declared_error.begin()->first<=type_errors.begin()->first) cout << declared_error.begin()->second<<"error"<<endl;
        else 
        cout<<type_errors.begin()->second<<endl;}
      }
      else {
      // cout<<"start else"<<endl;
      if(type_errors.empty()||(!type_errors.empty()&&func_errors.begin()->first<=type_errors.begin()->first)){
      if(!declared_error.empty()&&declared_error.begin()->first<=func_errors.begin()->first) cout << declared_error.begin()->second<<"error"<<endl;
        else 
      cout<<func_errors.begin()->second<<endl;}
      else 
      {if(!declared_error.empty()&&declared_error.begin()->first<=type_errors.begin()->first) cout << declared_error.begin()->second<<"error"<<endl;
        else 
        cout<<type_errors.begin()->second<<endl;}}
      exit(EXIT_FAILURE);
    }
    else if(!func_errors.empty()&&a->first>=func_errors.begin()->first){
    if(!type_errors.empty()&&type_errors.begin()->first<=func_errors.begin()->first) {
    if(!declared_error.empty()&&declared_error.begin()->first<=type_errors.begin()->first) cout << declared_error.begin()->second<<"error"<<endl;
        else 
    cout<<type_errors.begin()->second<<endl;}
    else {
    if(!declared_error.empty()&&declared_error.begin()->first<=func_errors.begin()->first) cout << declared_error.begin()->second<<"error"<<endl;
        else 
      cout<<func_errors.begin()->second<<endl;}
    exit(EXIT_FAILURE);
    }
  }
  // cout<<"end"<<endl;
  if(!func_errors.empty()&&!type_errors.empty()&&func_errors.begin()->first<=type_errors.begin()->first){
  if(!declared_error.empty()&&declared_error.begin()->first<=func_errors.begin()->first) cout << declared_error.begin()->second<<"error"<<endl;
        else 
  cout<<func_errors.begin()->second<<endl;
  exit(EXIT_FAILURE);}
  else if(!type_errors.empty()){
  if(!declared_error.empty()&&declared_error.begin()->first<=type_errors.begin()->first) cout << declared_error.begin()->second<<"error"<<endl;
        else 
  cout<<type_errors.begin()->second<<endl;
  exit(EXIT_FAILURE);}
  else if(!func_errors.empty()) {
  if(!declared_error.empty()&&declared_error.begin()->first<=func_errors.begin()->first) cout << declared_error.begin()->second<<"error"<<endl;
        else 
  cout<<func_errors.begin()->second<<endl;
  exit(EXIT_FAILURE);}
  else if(!declared_error.empty()) cout<<declared_error.begin()->second<<endl;
  // print_to_the_file(output_file_name.c_str(), root);
  ////////////////OUTPUT///////////////////
  // fout.open(output_file_name);
  ofstream tacfile(tac_output);
  int i=0;
  // vector<string> ops = {"+","-",">","!","<","==","^","|","and",">>","<<","*","@","/","//","or","in","+=","-=","*=","@=","/=","%=","^=",">>=","<<=","**=","//=","&=",">=","<=","<>","!=","**","%"};
  vector<string> ops = {"*","**","+=","-=","*=","/=","//=","%=","@=","&=","|=","^=",">>=","<<=","**=","<",">","==",">=","<=","<>","!=","^","&","<<",">>","+","-","@","/","%","//","~","|","and","or","not","in"};
    for(auto it:code){
    if(it.op=="begin_func"){
      tacfile<<"\t"<<it.op<<" "<<func_size[i]<<"\n";
      i++;
    }
    else if( it.op == "end_func" || it.op == "\treturn"){
      tacfile<<"\t"<<it.op<<"\n";
    }
    else if(it.op == "="){
      tacfile<<"\t"<<it.res<<" "<< it.op <<" "<< it.arg1<<" "<<it.arg2<<"\n";
    }
    else if(it.res == "Ifz"){
      tacfile<<"\t"<<it.res<<" "<<it.arg1<<" "<<it.op<<" "<<it.arg2<<"\n";
    }
    else if(it.op=="goto"){
      tacfile<<"\t"<<it.op<<" : "<<it.arg1<<"\n";
    }
    else if(find(ops.begin(),ops.end(),it.op)!=ops.end()){
      tacfile<<"\t"<<it.res<<" = "<<it.arg1<<" "<<it.op<<" "<<it.arg2<<"\n";
    }
    else if(it.op == "\treturn" || it.op == "push_param" || it.op == "stackpointer" || it.op == "Lcall" || it.op == "Break" || it.op == "pop_params" || it.op=="Continue"){
      tacfile<<"\t"<<it.op<<" "<<it.arg1<<"\n";
    }
    // else if(it.op == "+")
    else{
      tacfile<<it.op<<' '<<it.arg1<<' '<<it.arg2<<' '<<it.res<<'\n';
    }
  }
  tacfile.close();
  int j = 0;
  string x86;
  x86=".globl main";
  x86_64_code.insert(x86_64_code.begin(),x86);
  x86="\tret";
  x86_64_code.insert(x86_64_code.begin(),x86);
  x86="\tpopq %rbp";
  x86_64_code.insert(x86_64_code.begin(),x86);
  x86="\tmovq %rcx, %rax";
  x86_64_code.insert(x86_64_code.begin(),x86);
  x86="end:";
  x86_64_code.insert(x86_64_code.begin(),x86);
  x86="\tjmp begin";
  x86_64_code.insert(x86_64_code.begin(),x86);
  x86="\tincq %rcx";
  x86_64_code.insert(x86_64_code.begin(),x86);
  x86="\tje end";
  x86_64_code.insert(x86_64_code.begin(),x86);
  x86="\tcmpb $0, (%rdi,%rcx)";
  x86_64_code.insert(x86_64_code.begin(),x86);
  x86="begin:";
  x86_64_code.insert(x86_64_code.begin(),x86);
  x86="\txorq %rcx, %rcx";
  x86_64_code.insert(x86_64_code.begin(),x86);
  x86="\tmovq %rsp, %rbp";
  x86_64_code.insert(x86_64_code.begin(),x86);
  x86 = "\tpushq %rbp";
  x86_64_code.insert(x86_64_code.begin(),x86);
  x86="strlen:";
  x86_64_code.insert(x86_64_code.begin(),x86);
  x86=".text";
  x86_64_code.insert(x86_64_code.begin(),x86);
  for(j=0; j<str_list.size(); j++){
    x86_64_code.insert(x86_64_code.begin(),str_list[j]);
  }
    x86="\t.string \"%s\\n\"";
    x86_64_code.insert(x86_64_code.begin(),x86);
    x86=".LC1:";
    x86_64_code.insert(x86_64_code.begin(),x86);
    x86="\t.string \"%d\\n\"";
    x86_64_code.insert(x86_64_code.begin(),x86);
    x86=".LC0:";
    x86_64_code.insert(x86_64_code.begin(),x86);
  x86=".section .data";
  x86_64_code.insert(x86_64_code.begin(),x86);
  ofstream asmfile(asm_output);

  for(j=0; j<x86_64_code.size(); j++){
    asmfile<<x86_64_code[j]<<"\n";
  }
  asmfile.close();
int n=all_tables.size();
// cout<<"number of function= "<<n<<endl;
//  auto now = chrono::system_clock::now();
//     auto now_ms = chrono::time_point_cast<chrono::milliseconds>(now);
//     auto epoch = now_ms.time_since_epoch();
//     auto value = chrono::duration_cast<chrono::milliseconds>(epoch);
// for(auto it: all_tables){
//     stringstream filenamestream;
//     string name_of_function = it.first;
//     filenamestream<<it.first<<"-"<<it.second->parent->scope<<".csv";
//     string filename = filenamestream.str();
//     ofstream outputfile(filename);
//     //header
//     outputfile<<"Token,Lexeme,type,line_numer,scope"<<endl;
//   LocalSymbolTable* t = it.second;
//   string identifier = "Identifier";
//  for(auto it1: t->variables){
//     outputfile<<"Identifier"<<","<<it1.first<<","<<it1.second->type<<","<<it1.second->line_number<<","<<it.first<<endl;
//    }
//    outputfile.close();
// }
fclose(input_file);
}

void yyerror(const char* s) {
    fprintf(stderr, "%s %d %s\n", s, yylineno, yytext);
}
