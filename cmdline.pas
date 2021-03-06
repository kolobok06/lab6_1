{$mode objfpc}
{$H+}
{$codepage UTF8}
(*
 * Project: lab6_1
 * User: alexa
 * Date: 07.04.2017
 *)
unit cmdline;

interface
    procedure init();

implementation

uses crt,regexpr,btree,list;

const number = '^(0|(-(1|2|3|4|5|6|7|8|9)\d*)|((1|2|3|4|5|6|7|8|9)\d*))$';

var
    cmdstr:string;
    symbols: set Of char;
    cmd_list: array[0..5] of string; //Список доступных команд
    prev_cmd_list,curr_cmd:PCList;
    my_tree:PTree;

procedure help();
var
    f: Text;
    s: string;
begin
    //Выводит файл со справкой на экран
    Assign(f,'help.txt');
    Reset(f);
    while not Eof(f) do
    begin
        ReadLn(f,s);
        WriteLn(s);
    end;
    Close(f);
end;

procedure delete_f(arg: string);
var
    i:integer;
    s:string;
begin
    if not ExecRegExpr('(tree$)|' + number, arg) then
        WriteLn('Недопустимый аргумент команды delete')
    else if arg = 'tree' then
        delete_tree(my_tree)
    else
    begin
        Val(arg,i);
        str(i,s);
        if s = arg then
            delete_item(i,my_tree)
        else
            WriteLn('Число не соответствует типу Integer');
    end;
end;

procedure insert_f(arg: string);
var
    i:integer;
    s:string;
begin
    if not ExecRegExpr(number, arg) then
        WriteLn('Недопустимый аргумент команды insert')
    else
    begin
        Val(arg,i);
        str(i,s);
        if s = arg then
            insert_item(i,my_tree)
        else
            WriteLn('Число не соответствует типу Integer');
    end;
end;

procedure find_f(arg: string);
var
    i:integer;
    s:string;
begin
    if not ExecRegExpr(number, arg) then
        WriteLn('Недопустимый аргумент команды find')
    else
    begin
        Val(arg,i);
        str(i,s);
        if s = arg then
            WriteLn(find_item(i,my_tree))
        else
            WriteLn('Число не соответствует типу Integer');
    end;
end;

procedure print_f(arg: string);
begin
    if not ExecRegExpr('(pre|inf|pos)$', arg) then
        WriteLn('Недопустимый аргумент команды print')
    else
    begin
        if arg = 'inf' then
        print_tree_inf(my_tree);
        if arg = 'pre' then
            print_tree_pre(my_tree);
        if arg = 'pos' then
            print_tree_pos(my_tree);
    end;
end;

procedure help_f(arg: string);
begin
    if arg <> '' then
        WriteLn('У команды help нет аргументов')
    else
      help();
end;

procedure clear_f(arg: string);
begin
    if arg <> '' then
        WriteLn('У команды clear нет аргументов')
    else
        begin
            clrscr;
            cmdstr:='';
        end;
end;

procedure split();
var
    space_pos: Integer;
    cmd: string; //Команда после разбиения строки
    cmd_arg: string; //Аргумент команды

procedure cmd_exec();
begin
    if cmd = 'delete' then
        delete_f(cmd_arg);
    if cmd = 'insert' then
        insert_f(cmd_arg);
    if cmd = 'find' then
        find_f(cmd_arg);
    if cmd = 'print' then
        print_f(cmd_arg);
    if cmd = 'help' then
        help_f(cmd_arg);
    if cmd = 'clearscr' then
        clear_f(cmd_arg);
end;

begin
    WriteLn();
    space_pos := pos(' ',cmdstr);
    cmd_arg:='';
    if space_pos <> 0 then //Если нашли пробел разбиваем команду на 2 части
    begin
        cmd := Copy(cmdstr,1,space_pos - 1);
        cmd_arg:=Copy(cmdstr,space_pos + 1,Length(cmdstr));
        cmd_exec();
    end
    else
    begin
        cmd:=cmdstr;
        cmd_exec();
    end;
end;

procedure del_spaces(var cmd:string);
begin
    cmd:=ReplaceRegExpr('(^\s*)|(\s*$)/(\s\s)',cmd,'',false);
    cmd:=ReplaceRegExpr('\s+',cmd,' ',false);
    cmd:=ReplaceRegExpr('\s$',cmd,'',false);
end;

procedure enter();
begin
    add_list(cmdstr,prev_cmd_list);
    curr_cmd:=prev_cmd_list;
    del_spaces(cmdstr);
    if not ExecRegExpr('(clearscr|help|print|delete|insert|find).*',cmdstr) Then
    begin //Если команда не соответствует регулярному выражению expr
        writeln(#10#13,'Команда   *',cmdstr,'*  не найдена');
        cmdstr := '';
    end
    else
    begin
        split();
        cmdstr := '';
        WriteLn();
    end;
end;

procedure tab();
var
    i: Integer;
begin
    del_spaces(cmdstr);
    for i:=0 to 5 do
    begin
        if pos(cmdstr,cmd_list[i]) = 1 then //Если нашли команду в списке команд
        begin
            cmdstr := cmd_list[i] + ' ';
            delline;
            gotoxy(1,wherey);
            Write(cmdstr);
            break;
        end;
    end;
end;

procedure exit_f();
begin
    del_list(prev_cmd_list);
    delete_tree(my_tree);
    WriteLn(#10#13,'Программа завершена');
    readkey;
    halt();
end;


procedure arrow_up(); //Выводит предыдущую команду
begin
    cmdstr:=get_cmd(curr_cmd);
    gotoxy(1,wherey);
    clreol;
    write(cmdstr);
    curr_cmd:=prev_cmd(curr_cmd);
end;

procedure arrow_down(); //Выводит предыдущую команду
begin
    cmdstr:=get_cmd(curr_cmd);
    gotoxy(1,wherey);
    clreol;
    write(cmdstr);
    curr_cmd:=next_cmd(curr_cmd);
end;

Procedure backspace();
Begin
    delete(cmdstr,length(cmdstr),1);
    gotoxy(wherex - 1,wherey);
    clreol;
End;

procedure key_press();
var
    key: char;
begin
    if Length(cmdstr) > 80 then //Если слишком много вбили в консоль
    begin
        WriteLn(#10#13,'Максимальная длина строки 80 символов');
        cmdstr := '';
    end
    else
    begin
        key := readkey();
        If (key in symbols) Then
        Begin
            write(key);
            cmdstr := cmdstr + key;
        End;
        If (key = #27) Then //Esc
            exit_f();
        If (key = #13) Then
            enter();
        If (key = #9) Then
            tab();
        If (key = #8) Then
            backspace();
        If (key = #0) Then
            Case readkey() Of
            #72: arrow_up();
            #80: arrow_down();
            End;
    end;
end;


procedure init();
begin
    help();
    while(true) do
    begin
        key_press();
    end;
end;

begin
    my_tree:=nil;
    prev_cmd_list:=nil;
    curr_cmd:=nil;
    cmd_list[0] := 'help';
    cmd_list[1] := 'insert';
    cmd_list[2] := 'print';
    cmd_list[3] := 'find';
    cmd_list[4] := 'delete';
    cmd_list[5] :='clearscr';
    symbols := ['a'..'z','0' .. '9',' ','-'];
end.