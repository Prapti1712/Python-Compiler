%{
#include <stdio.h>
#include <iostream>
#include <stdlib.h>
#include <string.h>
#include <stdbool.h>
#include<string>
#include<chrono>
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
class LocalSymbolTable {
  public:
    unordered_map<string, Variable*> variables;
     string return_type;
    vector<string> parameter_types;
    string source_file;
    int line_number;
    string scope;
   LocalSymbolTable* parent;
    unordered_map<string, LocalSymbolTable*> children;
    int is_function;
    LocalSymbolTable(unordered_map<string, Variable*> variables, string return_type, vector<string> parameter_types, string source_file, int line_number, string scope, LocalSymbolTable* parent, unordered_map<string, LocalSymbolTable*> children){
        this->variables = variables;
        this->return_type = return_type;
        this->parameter_types = parameter_types;
        this->source_file = source_file;
        this->line_number = line_number;
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
unordered_map<string, LocalSymbolTable*> children; 
LocalSymbolTable* global_table = new LocalSymbolTable(variables, "", parameter_types, "", 0, "global", NULL, children);
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
stack<vector<string>> func;
stack<int> func_running;
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

funcdef: func_start parameters a COLON suite {
    if(func_name!="__init__"){
        // cout<<"not here"<<endl;
  all_tables.push_back({func_name,current_local_symbol_table});}
  if(current_local_symbol_table->parent->scope=="class"&&current_local_symbol_table->parent->children["__init__"]==current_local_symbol_table){
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
   siz+=(counter-temporaries)*4;
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
emit("return","","","",-1);
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

}
|func_start parameters COLON suite {
    if(func_name!="__init__"){
        // cout<<"not_here1"<<func_name<<endl;
    all_tables.push_back({func_name,current_local_symbol_table});}
if(current_local_symbol_table->parent->scope=="class"&&current_local_symbol_table->parent->children["__init__"]==current_local_symbol_table){
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
   siz+=(counter-temporaries)*4;
  func_size.push_back(siz);
  //////////////3AC////////////////////
  while(is_return && !return_labels.empty()){
    string a = return_labels.top();
    emit(a,":","","",-1);
    // emit("end_func","","","",-1);
    // return_label = "";
    return_labels.pop();
  }
  is_return = 0;
  emit("return","","","",-1);
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
}
  ;
func_start: DEF NAME {
 LocalSymbolTable* temp = new LocalSymbolTable(variable, "", parameter_types, "", yylineno, "function", current_local_symbol_table, children);
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
}
  // | STAR f optional_comma_tfpdef_c g 
  // | DOUBLESTAR tfpdef i 
  ;
optional_comma_tfpdef_c: /*empty*/ {}
                      | optional_comma_tfpdef_c COMMA tfpdef c {
                      current_local_symbol_table->parameter_types.insert(current_local_symbol_table->parameter_types.begin(),($3).type);
                      // cout<<"optional_comma_tfpdef_c "<<yylineno<<endl;
                      if(($4).type!=""&&!type_correct(($3).type,($4).type)){
                        type_errors[type_error_line]="Type mismatch in function parameter "+charPtrToString(($3).lexeme)+" on line "+to_string(type_error_line);
                      }
                      }
    
                      ;

c: eq test {
  is_equal=0;
  $$.lexeme = ($2).lexeme;
  $$.type = ($2).type;
  // if($$.lexeme == NULL)
  //cout<<"CCCCCCCCCCCCCCC"<<endl;
  $$.tempvar = ($2).tempvar;
  $$.op = ($1).lexeme;
}
    | /* empty */{
      $$.type="";
      $$.lexeme = NULL;
      // $$.type = NULL;
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
  //cout<<"expr_stmt1 "<<yylineno<<endl;
  if(($2).type!=""){
    if(($2).type=="str") {
    type_errors[type_error_line]="Mutable operation on string on line "+to_string(type_error_line)+" not allowed";}
    else if(!type_correct(($1).type,($2).type) && ($2).type != NULL ){
      type_errors[type_error_line]="Type mismatch in assignment on line "+to_string(type_error_line);
    }
  }
  else{
    //cout<<"expr_stmt2 "<<yylineno<<endl;
    current_local_symbol_table->variables[($1).lexeme]->size=arr_size;
    arr_size=0;
  }
  //cout<<"expr_stmt5 "<<yylineno<<endl;

////////////////////////3AC//////////////////////////
  //cout<<"expr_stmt6 "<<yylineno<<endl;

    if(($2).lexeme == NULL){
      // DO NOTHING
      //cout<<"expr_stmt3 "<<yylineno<<endl;

    }
    else{
      //cout<<"expr_stmt4 "<<yylineno<<endl;
      $$.op = ($2).op;
      string lex1 = ($1).lexeme;
    int sz;
    if(lex1=="self")
    {
      //cout<<"sellllllllffff1"<<($1).lexeme<<current_type<<endl;
    
    sz = size(current_type,($2).lexeme);
   class_offset += sz;}
      string op = charPtrToString(($2).op);
if(op=="=")
    {
      if(lex1=="self"){
 string s1= "*";
    char* st = stringToCharArray(s1);
    strcat(st,"(");
    strcat(st,"self");
    strcat(st,"+");
    strcat(st,stringToCharArray(to_string(class_offset)));
    strcat(st,")");
    emit(op,charPtrToString(($2).lexeme),"",st,-1);


      }
     else {
      if(($1).tempvar == NULL && ($2).tempvar == NULL){
      //cout<<"here1"<<endl;
      emit(op,charPtrToString(($2).lexeme),"",charPtrToString(($1).lexeme),-1);
    }else if(($2).tempvar == NULL){
      //cout<<"here2"<<endl;
      emit(op,charPtrToString(($2).lexeme),"",charPtrToString(($1).tempvar),-1);
    }else if(($1).tempvar == NULL){
      //cout<<"here3"<<endl;
      emit(op,charPtrToString(($2).tempvar),"",charPtrToString(($1).lexeme),-1);
    }else{
      //cout<<"here4"<<endl;
      emit(op,charPtrToString(($2).tempvar),"",charPtrToString(($1).tempvar),-1);
    }
    }}else{
      if(lex1=="self"){
 string s1= "*";
    char* st = stringToCharArray(s1);
    strcat(st,"(");
    strcat(st,"self");
    strcat(st,"+");
    strcat(st,stringToCharArray(to_string(class_offset)));
    strcat(st,")");
    emit(op,charPtrToString(($2).lexeme),"",st,-1);


      }
      else{if(($1).tempvar == NULL && ($2).tempvar == NULL){
        //cout<<"here1"<<endl;
        emit(op,charPtrToString(($1).lexeme),charPtrToString(($2).lexeme),charPtrToString(($1).lexeme),-1);
      }else if(($1).tempvar == NULL){
        //cout<<"here2"<<endl;
        emit(op,charPtrToString(($1).lexeme),charPtrToString(($2).tempvar),charPtrToString(($1).lexeme),-1);
      }else if(($2).tempvar == NULL){
        //cout<<"here3"<<endl;
        emit(op,charPtrToString(($1).tempvar),charPtrToString(($2).lexeme),charPtrToString(($1).tempvar),-1);
      }else{
        //cout<<"here4"<<endl;
        emit(op,charPtrToString(($1).tempvar),charPtrToString(($2).tempvar),charPtrToString(($1).tempvar),-1);
      }}
    }
    }
    //cout<<"expr1"<<endl;
  }
  | NEW_NT B{
    //cout<<"expr_stmt2 "<<yylineno<<" "<<endl;
    if(!type_correct(($1).type,($2).type)){
    type_errors[type_error_line]="Type mismatch in assignment on line "+to_string(type_error_line);}
    /////////////////3AC/////////////////
    
    if(($1).tempvar == NULL && ($2).tempvar == NULL){
      emit("=",charPtrToString(($2).lexeme),"",charPtrToString(($1).lexeme),-1);
    }else if(($2).tempvar == NULL){
      emit("=",charPtrToString(($2).lexeme),"",charPtrToString(($1).tempvar),-1);
    }else if(($1).tempvar == NULL){
      emit("=",charPtrToString(($2).tempvar),"",charPtrToString(($1).lexeme),-1);
    }else{
      emit("=",charPtrToString(($2).tempvar),"",charPtrToString(($1).tempvar),-1);
    }

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
  //cout<<"annassign current_variable: "<<current_variable<<" current_type: "<<current_type<<endl;
  //cout<<"annassign "<<($2).type<<" "<<($3).type<<endl;
  if(strcmp(($2).type,"list")!=0 && !type_correct(($2).type,($3).type) && ($3).type!=""){
  //cout<<"annassign "<<($2).type<<endl;
  type_errors[type_error_line]="Type mismatch in assignment on line "+to_string(type_error_line);}
//Entry(current_type, current_variable, current_scope, current_line);
    if(($3).lexeme!=NULL)
     $$.lexeme = ($3).lexeme;
    else{
      $$.lexeme = NULL;
    }

    $$.type = ($3).type;
    $$.op = ($3).op;
//cout<<"annassign current_variable: "<<current_variable<<" current_type: "<<current_type<<endl;
  $$.tempvar = ($3).tempvar;

};
col: COLON {
  scope_stack.push(":");
};
NEW_NT: test optional_comma_test d{
  $$.lexeme = ($1).lexeme;
  // cout<<"NEW_NTTTTTTTTTTTTTT"<<$$.lexeme<<endl;
  //cout<<$$.lexeme<<endl;
  $$.type=($1).type;

}
        | test d {
          $$.lexeme = ($1).lexeme;
          $$.type=($1).type;
          $$.tempvar = ($1).tempvar;
  // cout<<"NEW_NTTTTTTTTTTTTTT"<<$$.lexeme<<endl;

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
    // string L = newLabel();
    string L = break_labels.top();
    emit("goto",L,"","",-1);
    // break_label = L;

};
continue_stmt: CONTINUE {
    emit("Continue","","","",-1);
    emit("goto",continue_label.top(),"","",-1);
    // continue_label.pop();
};
return_stmt: RETURN testlist {
  if(($2).tempvar!=NULL)
  emit("Return", charPtrToString(($2).tempvar) , "", "", -1);
  else {
    emit("Return", charPtrToString(($2).lexeme) , "", "", -1);}
  string L = newLabel();
  emit("goto",L,"","",-1);
      //cout<<"RETURN testlist"<<endl;

  $$.gotoname = stringToCharArray(L);
  // return_label = L;
  return_labels.push(L);
  is_return = 1;
   }
|RETURN {
  emit("Return","", "", "", -1);
  string L = newLabel();
  emit("goto",L,"","",-1);
  $$.gotoname = stringToCharArray(L);
  // return_label = L;
  return_labels.push(L);
  is_return = 1;

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
// compound_stmt: if_stmt1  {
//   string a = charPtrToString(($1).gotoname);

//   emit(a,":","","",-1);
//   }
//             | while_stmt {
//               }
//             | for_stmt2  {
//               }
//             | funcdef  {
//             }
//             | classdef {
//               }
//             | if_else_stmt1{

//             }
//             ;
compound_stmt: if_stmt1  {
    string a = charPtrToString(($1).gotoname);

    emit(a,":","","",-1);
}
            | while_stmt1 {
  // if(is_break){
  //   emit(break_label,":","","",-1);
  //   break_label = "";
  //   is_break = 0;
  // }
    break_labels.pop();

              }
            | while_stmt2{

            }
            | for_stmt1  {
  // if(is_break){
    // emit(break,":","","",-1);
    // break_label = "";
    // is_break = 0;
    break_labels.pop();
  // }
              }
            |for_stmt2{

            }
            | funcdef  {
            }
            | classdef {
              }
            | if_else_stmt1{

            }
            | if_else_stmt2{

            }
            ;
// iff: IF {type_error_line=yylineno;};
// elif: ELIF {type_error_line=yylineno;};
// if_stmt1: iftestcol suite optional_elif_test_colon_suite p {
//   string a = charPtrToString(($1).gotoname);
//   string L = newLabel();
//     emit("goto",L,"","",-1);
//     emit(a,":","","",-1); 
//    $$.gotoname = stringToCharArray(L);
//   cout<<"here at if_stmt"<<endl;
//   };
// // if_start: iff test COLON{
// //   if(!type_correct(($2).type,"bool")){
// //     type_errors[type_error_line]="Type of condition isn't of bool type in if statement on line "+to_string(type_error_line);}
// // };
// iftestcol: iff test COLON{
//   /////////////3AC/////////////////
//   cout<<"here at iftestcol start"<<endl;
//   string L = newLabel();
//   string a;
//   if(($2).tempvar == NULL )
//   {a = charPtrToString(($2).lexeme);}
//   else
//   {a = charPtrToString(($2).tempvar);}
//   emit("goto",a,L,"Ifz",-1);
//   $$.gotoname = stringToCharArray(L);
//   cout<<"here at iftestcol end"<<endl;
//   ///////////TYPE CHECKING//////////////////
//   if(!type_correct(($2).type,"bool")){
//     type_errors[type_error_line]="Type of condition isn't of bool type in if statement on line "+to_string(type_error_line);
//   }
// };

// optional_elif_test_colon_suite: /*empty*/ {}
//                               |optional_elif_test_colon_suite elif_start suite {
//     //                           if(!type_correct(($3).type,"bool")){
//     // type_errors[type_error_line]="Type of condition isn't of bool type in elif statement on line "+to_string(type_error_line);}
//                              };
// elif_start: elif test COLON{
// if(!type_correct(($2).type,"bool")){
//     type_errors[type_error_line]="Type of condition isn't of bool type in elif statement on line "+to_string(type_error_line);}
// };
// p: elsecol suite {
//   $$.label = NULL;
//   $$.gotoname = ($1).gotoname;
//   // else_present = 1;
//   cout<<"here at p1"<<endl;
// }
//   | /* empty */ {
//     // else_present = 0;
//     $$.label = NULL;
//     cout<<"here at p2"<<endl;
//   };
// elsecol: ELSE COLON{
//   // else_present = 1;
// };
// if_else_stmt1: if_stmt1 elsecol suite{
//   cout<<"if_else_stmt1"<<endl;
//   string a = charPtrToString(($1).gotoname);
//   emit(a,":","","",-1);
// };
iff: IF {type_error_line=yylineno;};
elif: ELIF {type_error_line=yylineno;};
if_stmt1: iftestcol suite{
  string a = charPtrToString(($1).gotoname);
  string L = newLabel();
    emit("goto",L,"","",-1);
    emit(a,":","","",-1); 
   $$.gotoname = stringToCharArray(L);
  //cout<<"here at if_stmt"<<endl;
  };
// if_start: iff test COLON{
//   if(!type_correct(($2).type,"bool")){
//     type_errors[type_error_line]="Type of condition isn't of bool type in if statement on line "+to_string(type_error_line);}
// };
iftestcol: iff test COLON{
  /////////////3AC/////////////////
  //cout<<"here at iftestcol start"<<endl;
  string L = newLabel();
  string a;
  if(($2).tempvar == NULL )
  {a = charPtrToString(($2).lexeme);}
  else
  {a = charPtrToString(($2).tempvar);}
  emit("goto",a,L,"Ifz",-1);
  $$.gotoname = stringToCharArray(L);
  //cout<<"here at iftestcol end"<<endl;
  ///////////TYPE CHECKING//////////////////
  if(!type_correct(($2).type,"bool")){
    type_errors[type_error_line]="Type of condition isn't of bool type in if statement on line "+to_string(type_error_line);
  }
};

// optional_elif_test_colon_suite: /*empty*/ {}
//                               |optional_elif_test_colon_suite elif_start suite {
//     //                           if(!type_correct(($3).type,"bool")){
//     // type_errors[type_error_line]="Type of condition isn't of bool type in elif statement on line "+to_string(type_error_line);}
                        //      };
// elif_start: elif test COLON{
// if(!type_correct(($2).type,"bool")){
//     type_errors[type_error_line]="Type of condition isn't of bool type in elif statement on line "+to_string(type_error_line);}
// };
p: elsecol suite {
  $$.label = NULL;
  $$.gotoname = ($1).gotoname;
  // else_present = 1;
  //cout<<"here at p1"<<endl;
}
  | /* empty */ {
    // else_present = 0;
    $$.label = NULL;
    //cout<<"here at p2"<<endl;
  };
elsecol: ELSE COLON{
  // else_present = 1;
};
if_else_stmt1: if_stmt1 elsecol suite{
  //cout<<"if_else_stmt1"<<endl;
  string a = charPtrToString(($1).gotoname);
  emit(a,":","","",-1);
};
if_else_stmt2: if_stmt1 elif_suite {
  string t = charPtrToString(($2).gotoname);
  emit(t,":","","",-1);
  string a = charPtrToString(($1).gotoname);
  emit(a,":","","",-1);


}|if_stmt1 elif_suite elsecol suite{
  string t = charPtrToString(($2).gotoname);
  emit(t,":","","",-1);
  string a = charPtrToString(($1).gotoname);
  emit(a,":","","",-1);

};
eliftestcol: elif test COLON{
  if(!type_correct(($2).type,"bool")){
    type_errors[type_error_line]="Type of condition isn't of bool type in elif statement on line "+to_string(type_error_line);}
  string a = newtemp();
  string L = newLabel();
  emit("goto",a,L,"Ifz",-1);
  $$.gotoname = stringToCharArray(L);
};
elif_suite: eliftestcol suite{
  string L = newLabel();
  emit("goto",stringToCharArray(L),"","",-1);
  string a = charPtrToString(($1).gotoname);
  emit(a,":","","",-1);
  $$.gotoname = stringToCharArray(L);
  
}| elif_suite eliftestcol suite{
  string a = charPtrToString(($2).gotoname);
  emit(a,":","","",-1);

};
// whilee: WHILE {type_error_line=yylineno;
//   string L = newLabel();
//   emit(L,":","","",-1); 
//   $$.gotoname = stringToCharArray(L);
// };
// while_stmt: while_start suite p {
//   emit("goto",charPtrToString(($1).label),"","",-1);
//   emit(charPtrToString(($1).gotoname),":","","",-1);

// };
// while_start: whilee test COLON{
// if(!type_correct(($2).type,"bool")){
//     type_errors[type_error_line]="Type of condition isn't of bool type in while loop on line "+to_string(type_error_line);} 
//   // emit("goto",charPtrToString(($1).gotoname),"","",-1);
//   // emit(charPtrToString(($2).gotoname),":","","",-1);
//   string L = newLabel();
//   string a = charPtrToString(($2).tempvar);
//   emit("goto",a,L,"Ifz",-1);
//   $$.gotoname = stringToCharArray(L);
//   $$.label = ($1).gotoname;
// };
whilee: WHILE {type_error_line=yylineno;
  string L = newLabel();
  emit(L,":","","",-1); 
  $$.gotoname = stringToCharArray(L);
};
while_stmt1: while_start suite {
  emit("goto",charPtrToString(($1).label),"","",-1);
  emit(charPtrToString(($1).gotoname),":" ,"","",-1);
    continue_label.pop();

};
while_stmt2: while_stmt1 elsecol suite{
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
  // emit("goto",charPtrToString(($1).gotoname),"","",-1);
  // emit(charPtrToString(($2).gotoname),":","","",-1);
  string L = newLabel();
  string a = charPtrToString(($2).tempvar);
  emit("goto",a,L,"Ifz",-1);
  $$.gotoname = stringToCharArray(L);
  $$.label = ($1).gotoname;
  continue_label.push(charPtrToString(($1).gotoname));
  break_labels.push(L);
};
// forr: FOR {
//   type_error_line=yylineno;
//   string L = newLabel();
//   emit(L,":","","",-1); 
//   $$.gotoname = stringToCharArray(L);
// };
// for_stmt: for_start suite p {
// // if(!type_correct(($2).type,"int")){
// //     type_errors[type_error_line]="Type of iterator isn't of int type in for loop on line "+to_string(type_error_line);}
//   emit("goto",charPtrToString(($1).label),"","",-1);
//   emit(charPtrToString(($1).gotoname),":","","",-1);
// }
// ; 
// for_start: forr exprlist IN testlist COLON{
//   cout<<"for_start "<<type_error_line<<" "<<yylineno<<endl;
//   if(!type_correct(($2).type,"int")){
//     type_errors[type_error_line]="Type of iterator isn't of int type in for loop on line "+to_string(type_error_line);}
//   string a = newtemp();
//   string L = newLabel();
//       if(($2).tempvar == NULL && ($4).tempvar == NULL){
//         emit("in",charPtrToString(($2).lexeme),charPtrToString(($4).lexeme),a,-1);
//       }else if(($2).tempvar == NULL){
//         emit("in",charPtrToString(($2).lexeme),charPtrToString(($4).tempvar),a,-1);
//       }else if(($4).tempvar == NULL){
//         emit("in",charPtrToString(($2).tempvar),charPtrToString(($4).lexeme),a,-1);
//       }else{
//         emit("in",charPtrToString(($2).tempvar),charPtrToString(($4).tempvar),a,-1);
//       }
//   emit("goto",a,L,"Ifz",-1);
//   $$.gotoname = stringToCharArray(L);
//   $$.label = ($1).gotoname;
// };
forr: FOR {
  type_error_line=yylineno;
  string L = newLabel();
  emit(L,":","","",-1); 
  $$.gotoname = stringToCharArray(L);
};
for_stmt1: for_start suite {
  emit("goto",charPtrToString(($1).label),"","",-1);
  emit(charPtrToString(($1).gotoname),":","","",-1);
};
for_stmt2: for_stmt1 elsecol suite{
  // if(is_break){
  //   emit(break_label,":","","",-1);
  //   break_label = "";
  //   is_break = 0;
  // }
    break_labels.pop();

}
; 
for_start: forr exprlist IN testlist COLON{
  //cout<<"for_start "<<type_error_line<<" "<<yylineno<<endl;
  if(!type_correct(($2).type,"int")){
    type_errors[type_error_line]="Type of iterator isn't of int type in for loop on line "+to_string(type_error_line);}
  string a = newtemp();
  string L = newLabel();
      if(($2).tempvar == NULL && ($4).tempvar == NULL){
        emit("in",charPtrToString(($2).lexeme),charPtrToString(($4).lexeme),a,-1);
      }else if(($2).tempvar == NULL){
        emit("in",charPtrToString(($2).lexeme),charPtrToString(($4).tempvar),a,-1);
      }else if(($4).tempvar == NULL){
        emit("in",charPtrToString(($2).tempvar),charPtrToString(($4).lexeme),a,-1);
      }else{
        emit("in",charPtrToString(($2).tempvar),charPtrToString(($4).tempvar),a,-1);
      }
  emit("goto",a,L,"Ifz",-1);
  $$.gotoname = stringToCharArray(L);
  $$.label = ($1).gotoname;
  continue_label.push(charPtrToString(($1).gotoname));
  break_labels.push(L);

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
  if(($2).lexeme == NULL)
  $$.tempvar = ($1).tempvar;
 //cout<<"test "<<$$.type<<endl;
  };  
u: IF or_test ELSE test {
  
}
  | /* empty */{
    
  };
// test_nocond: and_test
// |or_test OR and_test;
// test_nocond: or_test ;
// or_test: or_test OR and_test
// ;
or: OR {type_error_line=yylineno;
  $$.lexeme = $1;
};
or_test: and_test{
 $$.lexeme = ($1).lexeme;
 $$.type=($1).type;
 $$.tempvar = ($1).tempvar;
} 
|or_test or and_test{
$$.type="bool"; 
if(($1).type=="str"||($3).type=="str") {
  type_errors[type_error_line]="Logical operation on string on line "+to_string(type_error_line)+" not allowed";}
  // else if(!type_correct(($1).type,($3).type)){
  //   type_errors[yylineno]="Type mismatch in or operation on line "+to_string(yylineno);}
      string a = newtemp();
      string op = charPtrToString(($2).lexeme);
      if(($1).tempvar == NULL && ($3).tempvar == NULL){
        emit(op,charPtrToString(($1).lexeme),charPtrToString(($3).lexeme),a,-1);
      }else if(($1).tempvar == NULL){
        emit(op,charPtrToString(($1).lexeme),charPtrToString(($3).tempvar),a,-1);
      }else if(($3).tempvar == NULL){
        emit(op,charPtrToString(($1).tempvar),charPtrToString(($3).lexeme),a,-1);
      }else{
        emit(op,charPtrToString(($1).tempvar),charPtrToString(($3).tempvar),a,-1);
      }
      $$.tempvar = stringToCharArray(a);
      $$.lexeme = ($3).lexeme; // not actually important

} 
;
and: AND {type_error_line=yylineno;
$$.lexeme = $1;};
and_test: not_test {
  $$.lexeme = ($1).lexeme;
  $$.type=($1).type;
  $$.tempvar = ($1).tempvar;
}
|and_test and not_test {
$$.type="bool"; 
if(($1).type=="str"||($3).type=="str") {
  type_errors[type_error_line]="Logical operation on string on line "+to_string(type_error_line)+" not allowed";}
  // else if(!type_correct(($1).type,($3).type)){
  //   type_errors[yylineno]="Type mismatch in and operation on line "+to_string(yylineno);}
        string a = newtemp();
        string op = charPtrToString(($2).lexeme);
      if(($1).tempvar == NULL && ($3).tempvar == NULL){
        emit(op,charPtrToString(($1).lexeme),charPtrToString(($3).lexeme),a,-1);
      }else if(($1).tempvar == NULL){
        emit(op,charPtrToString(($1).lexeme),charPtrToString(($3).tempvar),a,-1);
      }else if(($3).tempvar == NULL){
        emit(op,charPtrToString(($1).tempvar),charPtrToString(($3).lexeme),a,-1);
      }else{
        emit(op,charPtrToString(($1).tempvar),charPtrToString(($3).tempvar),a,-1);
      }
      $$.tempvar = stringToCharArray(a);
      $$.lexeme = ($3).lexeme; // not actually important

}
;
not_test: NOT not_test {
$$.type="bool"; 
  string a = newtemp();
  if(($2).tempvar!=NULL) emit("not","",charPtrToString(($2).tempvar),a,-1);
  else emit("not","",charPtrToString(($2).lexeme),a,-1);
  $$.tempvar = stringToCharArray(a);
  $$.lexeme = ($2).lexeme;

}
    | comparison {
      $$.lexeme = ($1).lexeme;
      $$.type=($1).type;
      $$.tempvar = ($1).tempvar;
    }
;
comparison: expr {
 $$.lexeme = ($1).lexeme; 
 $$.type=($1).type;
 $$.tempvar = ($1).tempvar;

}
|comparison comp_op expr {
 $$.type="bool";
 //cout<<"comparison "<<($1).lexeme<<yylineno<<endl;
 //cout<<"comparison "<<($3).type<<" "<<($1).type<<endl;
  if(strcmp(($1).lexeme,"__name__")!=0&&!type_correct(($1).type,($3).type)){
    //cout<<"comparison "<<($1).lexeme<<yylineno<<endl;
    type_errors[type_error_line]="Type mismatch in comparison on line "+to_string(type_error_line);
    } 
  // if(($3).type!=NULL)
  // $$.type = ($3).type;
  string a = newtemp();
  string op = charPtrToString(($2).op);
    if(($1).tempvar == NULL && ($3).tempvar == NULL){
      emit(op,charPtrToString(($1).lexeme),charPtrToString(($3).lexeme),a,-1);
    }else if(($1).tempvar == NULL){
      emit(op,charPtrToString(($1).lexeme),charPtrToString(($3).tempvar),a,-1);
    }else if(($3).tempvar == NULL){
      emit(op,charPtrToString(($1).tempvar),charPtrToString(($3).lexeme),a,-1);
    }else{
      emit(op,charPtrToString(($1).tempvar),charPtrToString(($3).tempvar),a,-1);
    }
    $$.tempvar = stringToCharArray(a);

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
    string a = newtemp();

    if(($1).tempvar == NULL && ($2).tempvar == NULL){
      emit("|",charPtrToString(($1).lexeme),charPtrToString(($2).lexeme),a,-1);
    }else if(($1).tempvar == NULL){
      emit("|",charPtrToString(($1).lexeme),charPtrToString(($2).tempvar),a,-1);
    }else if(($2).tempvar == NULL){
      emit("|",charPtrToString(($1).tempvar),charPtrToString(($2).lexeme),a,-1);
    }else{
      emit("|",charPtrToString(($1).tempvar),charPtrToString(($2).tempvar),a,-1);
    }
    $$.tempvar = stringToCharArray(a);

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
                        string a = newtemp();
                        if(($1).tempvar == NULL && ($3).tempvar == NULL){
                          emit("|",charPtrToString(($1).lexeme),charPtrToString(($3).lexeme),a,-1);
                        }else if(($1).tempvar == NULL){
                          emit("|",charPtrToString(($1).lexeme),charPtrToString(($3).tempvar),a,-1);
                        }else if(($3).tempvar == NULL){
                          emit("|",charPtrToString(($1).tempvar),charPtrToString(($3).lexeme),a,-1);
                        }else{
                          emit("|",charPtrToString(($1).tempvar),charPtrToString(($3).tempvar),a,-1);
                        }
                        $$.tempvar = stringToCharArray(a);
                        $$.lexeme = ($3).lexeme; // not actually important
                  
                      }
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
      //cout<<"xor_expr1"<<endl;

    $$.tempvar = ($1).tempvar;
  }else{
      //cout<<"xor_expr2222222222222"<<endl;

    string a = newtemp();
    if(($1).tempvar == NULL && ($2).tempvar == NULL){
      emit("^",charPtrToString(($2).lexeme),charPtrToString(($1).lexeme),a,-1);
    }else if(($2).tempvar == NULL){
      emit("^",charPtrToString(($2).lexeme),charPtrToString(($1).tempvar),a,-1);
    }else if(($1).tempvar == NULL){
      emit("^",charPtrToString(($2).tempvar),charPtrToString(($1).lexeme),a,-1);
    }else{
      emit("^",charPtrToString(($2).tempvar),charPtrToString(($1).tempvar),a,-1);
    }
    $$.tempvar = stringToCharArray(a);
    // $$.lexeme = ($3).lexeme; // not actually important
  }

}                       ;
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
      string a = newtemp();
      if(($1).tempvar == NULL && ($3).tempvar == NULL){
        emit("^",charPtrToString(($3).lexeme),charPtrToString(($1).lexeme),a,-1);
      }else if(($3).tempvar == NULL){
        emit("^",charPtrToString(($3).lexeme),charPtrToString(($1).tempvar),a,-1);
      }else if(($1).tempvar == NULL){
        emit("^",charPtrToString(($3).tempvar),charPtrToString(($1).lexeme),a,-1);
      }else{
        emit("^",charPtrToString(($3).tempvar),charPtrToString(($1).tempvar),a,-1);
      }
      $$.tempvar = stringToCharArray(a);
      $$.lexeme = ($3).lexeme; // not actually important
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
    string a = newtemp();

    if(($1).tempvar == NULL && ($2).tempvar == NULL){
      emit("and",charPtrToString(($1).lexeme),charPtrToString(($2).lexeme),a,-1);
    }else if(($1).tempvar == NULL){
      emit("and",charPtrToString(($1).lexeme),charPtrToString(($2).tempvar),a,-1);
    }else if(($2).tempvar == NULL){
      emit("and",charPtrToString(($1).tempvar),charPtrToString(($2).lexeme),a,-1);
    }else{
      emit("and",charPtrToString(($1).tempvar),charPtrToString(($2).tempvar),a,-1);
    }
    $$.tempvar = stringToCharArray(a);
    // $$.lexeme = ($3).lexeme; // not actually important

  }
}
 ;

optional_and_shift_expr: /*empty*/ {$$.type="";
$$.lexeme = NULL;
}
| optional_and_shift_expr and shift_expr {
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
      string a = newtemp();
      if(($1).tempvar == NULL && ($3).tempvar == NULL){
        emit("and",charPtrToString(($1).lexeme),charPtrToString(($3).lexeme),a,-1);
      }else if(($1).tempvar == NULL){
        emit("and",charPtrToString(($1).lexeme),charPtrToString(($3).tempvar),a,-1);
      }else if(($3).tempvar == NULL){
        emit("and",charPtrToString(($1).tempvar),charPtrToString(($3).lexeme),a,-1);
      }else{
        emit("and",charPtrToString(($1).tempvar),charPtrToString(($3).tempvar),a,-1);
      }
      $$.tempvar = stringToCharArray(a);
      $$.lexeme = ($3).lexeme; // not actually important
 
    }
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
    string a = newtemp();
    string op = charPtrToString(($2).op);
    if(($1).tempvar == NULL && ($2).tempvar == NULL){
      emit(op,charPtrToString(($1).lexeme),charPtrToString(($2).lexeme),a,-1);
    }else if(($1).tempvar == NULL){
      emit(op,charPtrToString(($1).lexeme),charPtrToString(($2).tempvar),a,-1);
    }else if(($2).tempvar == NULL){
      emit(op,charPtrToString(($1).tempvar),charPtrToString(($2).lexeme),a,-1);
    }else{
      emit(op,charPtrToString(($1).tempvar),charPtrToString(($2).tempvar),a,-1);
    }
    $$.tempvar = stringToCharArray(a);
// $$.lexeme = ($1).lexeme; // not actually important

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
      string op = charPtrToString(($2).op);
      string a = newtemp();
      if(($1).tempvar == NULL && ($3).tempvar == NULL){
        emit(op,charPtrToString(($3).lexeme),charPtrToString(($1).lexeme),a,-1);
      }else if(($3).tempvar == NULL){
        emit(op,charPtrToString(($3).lexeme),charPtrToString(($1).tempvar),a,-1);
      }else if(($1).tempvar == NULL){
        emit(op,charPtrToString(($3).tempvar),charPtrToString(($1).lexeme),a,-1);
      }else{
        emit(op,charPtrToString(($3).tempvar),charPtrToString(($1).tempvar),a,-1);
      }
      $$.tempvar = stringToCharArray(a);
      $$.lexeme = ($3).lexeme; // not actually important
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
  //cout<<"arith_expr"<<" "<<$$.lexeme<<endl;

  if(($2).type!="" && (($2).type=="str"||($1).type=="str")) {
    type_errors[type_error_line]="Mutable operation on string on line "+to_string(type_error_line)+" not allowed";}
  else if(($2).type!="" && $$.type!="" && !type_correct($$.type,($2).type)){
    //cout<<"///////////+++++++++++/////////"<<$$.type<<" "<<($2).type<<endl;
    type_errors[type_error_line]="Type mismatch in addition/subtraction on line "+to_string(type_error_line);}
  ////////////////3AC///////////////////
  if(($2).lexeme != NULL){
  //cout<<"arith_expr"<<" "<<($2).lexeme<<endl;
    string a = newtemp();
    // string op = "";
    string op = charPtrToString(($2).op);
    //cout<<"arith_exprrrrr"<<endl;
    
    if(($1).tempvar == NULL && ($2).tempvar == NULL){
      emit(op,charPtrToString(($1).lexeme),charPtrToString(($2).lexeme),a,-1);
    }else if(($1).tempvar == NULL){
      emit(op,charPtrToString(($1).lexeme),charPtrToString(($2).tempvar),a,-1);
    }else if(($2).tempvar == NULL){
      emit(op,charPtrToString(($1).tempvar),charPtrToString(($2).lexeme),a,-1);
    }else{
      emit(op,charPtrToString(($1).tempvar),charPtrToString(($2).tempvar),a,-1);
    }
    $$.tempvar = stringToCharArray(a);
    $$.lexeme = ($1).lexeme; // not actually important
  }else{
  // cout<<"arith_expr"<<" "<<$$.lexeme<<endl;
       $$.tempvar = ($1).tempvar;  
  //cout<<"arith_expr"<<endl;
        
  }
  // if(($2).type != NULL)
  // {if(!type_correct($$.type,($2).type)){
  //   type_errors[yylineno]="Type mismatch in addition/subtraction on line "+to_string(yylineno);
  // }
  // }
//cout<<"here"<<endl;

}
;
optional_plus_minus_term: /*empty*/ {$$.type="";
// cout<<"hHEEEEEEEEEEEEEEELLLLLLLLLLLLLLLLOOOOOOOOOOO1"<<endl;
$$.lexeme = NULL;}
| optional_plus_minus_term plus_minus term {
  $$.type=($3).type;
  //cout<<"optional_plus_minus_term "<<$$.type<<" "<<($3).type<<endl;
  if(($3).type=="str"||($1).type=="str") {
    type_errors[type_error_line]="Mutable operation on string on line "+to_string(type_error_line)+" not allowed";}
  else if(($1).type!=""&&!type_correct($$.type,($1).type)){
    //cout<<"optional_plus_minus_term "<<$$.type<<" "<<($1).type<<endl;
    type_errors[type_error_line]="Type mismatch in addition/subtraction on line "+to_string(type_error_line);}
    //////////////////3AC////////////////////
  if(($1).lexeme == NULL){
    $$.lexeme = ($3).lexeme;
    $$.tempvar = ($3).tempvar;
    $$.op = ($2).lexeme;
    // cout<<"hHEEEEEEEEEEEEEEELLLLLLLLLLLLLLLLOOOOOOOOOOO2"<<endl;

  }   
  else{
    string a = newtemp();
    string op = charPtrToString(($2).lexeme);
                            
    if(($1).tempvar == NULL && ($3).tempvar == NULL){
      emit(op,charPtrToString(($1).lexeme),charPtrToString(($3).lexeme),a,-1);
    }else if(($1).tempvar == NULL){
      emit(op,charPtrToString(($1).lexeme),charPtrToString(($3).tempvar),a,-1);
    }else if(($3).tempvar == NULL){
      emit(op,charPtrToString(($1).tempvar),charPtrToString(($3).lexeme),a,-1);
    }else{
      emit(op,charPtrToString(($1).tempvar),charPtrToString(($3).tempvar),a,-1);
    }
    $$.tempvar = stringToCharArray(a);
    $$.lexeme = ($3).lexeme; // not actually important
  // cout<<"hHEEEEEEEEEEEEEEELLLLLLLLLLLLLLLLOOOOOOOOOOO3"<<endl;

  }   

}
;
plus_minus: PLUS {type_error_line=yylineno;
  $$.lexeme = $1;}
     |MINUS  {
      //cout<<"plus_minus "<<yylineno<<endl; 
      type_error_line=yylineno;
     $$.lexeme = $1;};


term: factor optional_operators_factor { 
  $$.lexeme = ($1).lexeme;
  $$.type=($1).type;
  //cout<<"term1 "<<$$.type<<endl;
  if(($2).lexeme==NULL) {
    //cout<<"NULL"<<endl;
    $$.tempvar = ($1).tempvar;
  }
  if(($2).lexeme!=NULL&&strcmp(($2).lexeme,"len")==0) {
    //cout<<"strcmp "<<($2).lexeme<<endl;
    ($2).type="int";\
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
    string a = newtemp();
    string op = charPtrToString(($2).op);
    if(($1).tempvar == NULL && ($2).tempvar == NULL){
      emit(op,charPtrToString(($1).lexeme),charPtrToString(($2).lexeme),a,-1);
    }else if(($1).tempvar == NULL){
      emit(op,charPtrToString(($1).lexeme),charPtrToString(($2).tempvar),a,-1);
    }else if(($2).tempvar == NULL){
      emit(op,charPtrToString(($1).tempvar),charPtrToString(($2).lexeme),a,-1);
    }else{
      emit(op,charPtrToString(($1).tempvar),charPtrToString(($2).tempvar),a,-1);
    }
    $$.tempvar = stringToCharArray(a);
  }
 }
|factor {
 $$.lexeme = ($1).lexeme; 
 $$.type=($1).type;
//  cout<<"term2 "<<endl;
   $$.tempvar = ($1).tempvar; 
// if($$.tempvar != NULL){
//   //cout<<"term2 "<<$$.tempvar<<endl;
//   // exit(0);
//   }
  //cout<<"term2"<<endl;
}
;
optional_operators_factor: operators factor {
  $$.lexeme = ($2).lexeme;
  $$.type=($2).type;  
  // if($$.lexeme!=NULL)
  //cout<<"optional_operators_factor1 "<<$$.type<<" "<<$$.lexeme<<endl;
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
  //cout<<"optional_operators_factor2 "<<$$.type<<endl;
  if(($1).lexeme == NULL){
    $$.tempvar = ($3).tempvar;
    $$.op = ($1).op;
  }else{
    string a = newtemp();
    string op = charPtrToString(($2).op);
    if(($1).tempvar == NULL && ($3).tempvar == NULL){
      emit(op,charPtrToString(($1).lexeme),charPtrToString(($3).lexeme),a,-1);
    }else if(($1).tempvar == NULL){
      emit(op,charPtrToString(($1).lexeme),charPtrToString(($3).tempvar),a,-1);
    }else if(($3).tempvar == NULL){
      emit(op,charPtrToString(($1).tempvar),charPtrToString(($3).lexeme),a,-1);
    }else{
      emit(op,charPtrToString(($1).tempvar),charPtrToString(($3).tempvar),a,-1);
    }
    $$.tempvar = stringToCharArray(a);
    $$.op = ($1).op;
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
  //cout<<"factor1 "<<$$.type<<endl;
  if(($2).is_number){
  // cout<<"factor1 "<<$$.type<<endl;
    string var = newtemp();
    // strcpy($$.tempvar, var);
    $$.tempvar = stringToCharArray(var);
    emit("=",charPtrToString(($1).op),charPtrToString(($2).lexeme), var, -1);
    un_op = 0;
  }
}
| power {
  $$.lexeme = ($1).lexeme;
  $$.type=($1).type;
          // cout<<"factor2 "<<endl;
  $$.tempvar = ($1).tempvar;
  // if($$.tempvar != NULL){
  //   cout<<"factor2 "<<$$.tempvar<<endl;
  // }
  // cout<<"factor2"<<endl;

  if(($1).is_number && !un_op){
    string var = newtemp();
    // strcpy($$.tempvar, var);
    $$.tempvar = stringToCharArray(var);
    emit("=",charPtrToString(($1).lexeme),"", var, -1);
  }
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
  $$.op = stringToCharArray("~");
};
power: 
atom_expr v {
  //cout<<"power2"<<endl;
  $$.lexeme = ($1).lexeme;
  $$.type=($1).type;
  if(!type_correct($$.type,($2).type)){
  type_errors[type_error_line]="Type mismatch in power operation on line "+to_string(type_error_line);}
  string a = newtemp();
  string op = charPtrToString(($2).op);
                            
  if(($1).tempvar == NULL && ($2).tempvar == NULL){
    emit(op,charPtrToString(($1).lexeme),charPtrToString(($2).lexeme),a,-1);
  }else if(($1).tempvar == NULL){
    emit(op,charPtrToString(($1).lexeme),charPtrToString(($2).tempvar),a,-1);
  }else if(($2).tempvar == NULL){
    emit(op,charPtrToString(($1).tempvar),charPtrToString(($2).lexeme),a,-1);
  }else{
    emit(op,charPtrToString(($1).tempvar),charPtrToString(($2).tempvar),a,-1);
  }
  $$.tempvar = stringToCharArray(a);
  // $$.lexeme = ($2).lexeme; // not actually important

  }
|atom_expr {
  $$.lexeme = ($1).lexeme;
  $$.type=($1).type;
  $$.tempvar = ($1).tempvar;
  //cout<<"power "<<$$.type<<endl;
}
;
doublestar: DOUBLESTAR {type_error_line=yylineno;
  $$.lexeme = $1;
};
v: doublestar factor{
  $$.type=($2).type;
  $$.op = ($1).lexeme;
  // cout<<"v "<<$$.type<<endl;
}
;
atom_expr: atom optional_trailer {
  //cout<<"at atom_expr1"<<endl;
  $$.lexeme = ($1).lexeme;
   string first = charPtrToString(($1).lexeme);
  // if(first == "self"){
  //   cout<<"you are dumb"<<endl;
  // }
  string fun="";
  string fun1="";
  if(!tables.empty()){
    if(tables.top()->scope == "class" && dot_present && first!="self"){
    //cout<<"class present"<<($1).lexeme<<endl;
      //cout<<"dot_present"<<endl;
     fun = first + ".";
     fun1 = fun + dot_name;
    //cout<<fun1<<endl;
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
      if(current_local_symbol_table->parent->scope=="class"&&is_ancestor(temp1,current_local_symbol_table->parent)) {
      // cout<<"is_ancestor "<<$$.type<<endl;
      temp=temp1;}
      else if(current_local_symbol_table->parent->scope!="class") 
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
    //function_arguments.clear();
    // cout<<"before func pop "<<yylineno<<endl;
    //func.pop();
    // cout<<"after func pop "<<yylineno<<endl;
    }
    else{
      // cout<<"temp=NULL in else "<<$$.lexeme<<endl;
      func_errors[func_error_line]="Function called on line "+to_string(func_error_line)+" is not declared";
    }
    //function_arguments.clear();
    // cout<<"before func "<<yylineno<<endl;
    func.pop();
    // cout<<"after func "<<yylineno<<endl;
    is_func_dot="";
    is_dot = "";}

    is_lsq=0;
    //function_arguments.clear();
    if(charPtrToString($$.type).size()>=4&&charPtrToString($$.type).substr(0,4)=="list"&&strcmp($$.lexeme,"list")!=0&&strcmp(($2).type,"int")!=0){
    type_errors[type_error_line]="Array at "+to_string(type_error_line)+" expected int but got "+charPtrToString(($2).type);}
    ///////////////////3AC//////////////////////
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
      
      // emit("stack_pointer", "-" + to_string(push_size), "", "", -1);
      }
      else is_noparam=0;}
      push_size = 0;
      // emit()
    }
    if(($2).is_array == 1&&is_func_param==0) {
      string a = newtemp();
      $$.tempvar = stringToCharArray(newtemp());
      emit("+",charPtrToString(($1).lexeme),charPtrToString(($2).tempvar),a,-1);
      string b="*("+a+")";
      emit("=",b,"",$$.tempvar,-1);
    }
    dot_present=0;
}
| atom{
  $$.lexeme = ($1).lexeme; 
  $$.type=($1).type;
  // cout<<"atom_expr "<<$$.type<<endl;
  $$.tempvar = ($1).tempvar;
//function_arguments.clear();
};
optional_trailer:trailer {
  $$.lexeme = ($1).lexeme;
  $$.type=($1).type;
  $$.tempvar = ($1).tempvar;
  is_func_dot=is_dot;
  }
| optional_trailer trailer {
  is_func_dot=is_dot;
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
}
| STRING {
  $$.type="str";
  $$.lexeme=$1;
  // cout<<"multi_string "<<$$.lexeme<<endl;
  string a = newtemp();
  emit("=",charPtrToString($1),"",a,-1);
  $$.tempvar = stringToCharArray(a);
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
  list_members.insert(list_members.begin(),($1).type);
  //string a=current_local_symbol_table->variables[($1).lexeme]->type;
 //a=a.substr(4,a.size());
 arr_size+=size(($1).type,($1).lexeme);
  if(($2).lexeme == NULL) $$.tempvar = ($1).tempvar;
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
 list_members.insert(list_members.begin(),($2).type);
 //string a=current_local_symbol_table->variables[($2).lexeme]->type;
 //a=a.substr(4,a.size());
 arr_size+=size(($2).type,($2).lexeme);
//  cout<<"NT end "<<yylineno<<endl;
}
| NT COMMA test {
  $$.type=($3).type;
 list_members.insert(list_members.begin(),($3).type);
 //string a=current_local_symbol_table->variables[($3).lexeme]->type;
 //a=a.substr(4,a.size());
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
    if(($2).tempvar!=NULL)
    emit("*",($2).tempvar,a,$$.tempvar,-1);
    else emit("*",($2).lexeme,a,$$.tempvar,-1);}
    //else $$.tempvar=($2).tempvar;
    // cout<<"lsq trailer4 "<<yylineno<<endl;
}
   | DOT NAME{
        dot_name = charPtrToString($2);
    // cout<<"dot name"<<($2)<<endl;
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
//  cout<<"subscriptlist1 "<<yylineno<<endl;
 $$.type=($1).type; 
//  cout<<"subscriptlist2 "<<yylineno<<endl;
 $$.lexeme=($1).lexeme;
//  cout<<"subscriptlist3 "<<yylineno<<endl;
 $$.tempvar=($1).tempvar;
//  cout<<"subscriptlist4 "<<yylineno<<endl;
 type_error_line=yylineno;
};

optional_comma_subscript: /*empty*/ {
 }
                        | optional_comma_subscript COMMA subscript{
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
  LocalSymbolTable* temp = new LocalSymbolTable(variable, "", parameter_types, "", yylineno, "class", current_local_symbol_table, children);
  temp->line_number = yylineno;
  temp->scope="class";
  if(($2).lexeme!=""){
    LocalSymbolTable* temp1 = find_table(($2).lexeme, global_table);
    temp->parent = temp1; 
    temp1->children[($1).lexeme] = temp;
    current_local_symbol_table = temp;
  } 
  else{
    temp->parent = current_local_symbol_table;
    // cout<<"class_start: "<<($1).lexeme<<endl;
    current_local_symbol_table->children[($1).lexeme] = temp;
    current_local_symbol_table = temp;
  }
  class_offset = 0;
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
  if(variables.find(($1).lexeme)==variables.end())
  function_arguments.insert(function_arguments.begin(),($1).type);
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
  // if($$.lexeme!=NULL)
  // cout<<"arglist "<<" "<<$$.lexeme<<" "<<yylineno<<endl;
  if(is_paren==1){
  //function_arguments.clear();
  //function_arguments=func.top();
  if(!func.empty()){
// cout<<"function_arguments=func.top()"<<endl;
function_arguments=func.top();
// cout<<"end 2"<<endl;
}
  if(($1).type!=NULL)
  function_arguments.insert(function_arguments.begin(),($1).type);
  else function_arguments.insert(function_arguments.begin(),"");
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
      function_arguments.insert(function_arguments.begin(),($3).type);
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
 $$.type=($1).type;}
        |test EQUAL test {
          $$.type=($1).type;};

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

    // FILE *input_file = fopen(argv[1],"r");
    FILE *input_file = fopen(input_file_name.c_str(),"r");
      yyin = input_file;
  yyparse();
  // cout<<"start"<<endl;
  for (auto a = scope_variable.begin(); a != scope_variable.end(); ++a){
    // if(func_errors.empty()) cout<<"func_errors is empty"<<endl;
    // if(a->first==20) cout<<"start "<<a->first<<endl;
    // cout<<a->first<<" "<<a->second<<endl;
    // if(current_local_symbol_table==NULL) cout<<"current_local_symbol_table is NULL"<<endl;
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
    // cout<<"hurrrrrrrrrrrrrrrraaaaaaaaaaaayyyyyyyyyyy"<<endl;
  //print_to_the_file(output_file_name.c_str(), root);
  //////////////////OUTPUT///////////////////
    // fout.open(output_file_name);
    ofstream tacfile(output_file_name);
  int i=0;
  // vector<string> ops = {"+","-",">","!","<","==","^","|","and",">>","<<","*","@","/","//","or","in","+=","-=","*=","@=","/=","%=","^=",">>=","<<=","**=","//=","&=",">=","<=","<>","!=","**","%"};
  vector<string> ops = {"*","**","+=","-=","*=","/=","//=","%=","@=","&=","|=","^=",">>=","<<=","**=","<",">","==",">=","<=","<>","!=","^","&","<<",">>","+","-","@","/","%","//","~","|","and","or","not","in"};
    for(auto it:code){
    if(it.op=="begin_func"){
      tacfile<<"\t"<<it.op<<" "<<func_size[i]<<"\n";
      i++;
    }
    else if( it.op == "end_func" || it.op == "return"){
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
    else if(it.op == "Return" || it.op == "push_param" || it.op == "stackpointer" || it.op == "Lcall" || it.op == "Break" || it.op == "pop_params" || it.op=="Continue"){
      tacfile<<"\t"<<it.op<<" "<<it.arg1<<"\n";
    }
    // else if(it.op == "+")
    else{
      tacfile<<it.op<<' '<<it.arg1<<' '<<it.arg2<<' '<<it.res<<'\n';
    }
  }
  tacfile.close();
int n=all_tables.size();
// cout<<"number of function= "<<n<<endl;
//  auto now = chrono::system_clock::now();
//     auto now_ms = chrono::time_point_cast<chrono::milliseconds>(now);
//     auto epoch = now_ms.time_since_epoch();
//     auto value = chrono::duration_cast<chrono::milliseconds>(epoch);
for(auto it: all_tables){
    stringstream filenamestream;
    string name_of_function = it.first;
    filenamestream<<it.first<<"-"<<it.second->parent->scope<<".csv";
    string filename = filenamestream.str();
    ofstream outputfile(filename);
    //header
    outputfile<<"Token,Lexeme,type,line_numer,scope"<<endl;
  LocalSymbolTable* t = it.second;
  string identifier = "Identifier";
 for(auto it1: t->variables){
    outputfile<<"Identifier"<<","<<it1.first<<","<<it1.second->type<<","<<it1.second->line_number<<","<<it.first<<endl;
   }
   outputfile.close();
}
  fclose(input_file);
}

void yyerror(const char* s) {
    fprintf(stderr, "%s %d %s\n", s, yylineno, yytext);
}
