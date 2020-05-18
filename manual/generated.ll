@global_string_literal_1 = constant [4 x i8] c"%d\0A\00"
@global_string_literal_2 = constant [18 x i8] c"we hit if! %d %d\0A\00"
@global_string_literal_3 = constant [19 x i8] c"we hit else %d %d\0A\00"
declare i32 @printf (i8*, i32, ...)

define i32 @main () {
	%global_func_main_variable_a = alloca i32
	store i32 3, i32* %global_func_main_variable_a
	%global_func_main_variable_b = alloca i32
	store i32 1, i32* %global_func_main_variable_b
	
	; binary operator: add
	%1 = load i32, i32* %global_func_main_variable_a
	%2 = load i32, i32* %global_func_main_variable_b
	%3 = add i32 %1, %2
	store i32 %3, i32* %global_func_main_variable_b
	; condition evaluation
	
	; binary operator: icmp eq
	%4 = load i32, i32* %global_func_main_variable_b
	%5 = icmp eq i32 %4, 4
	br i1 %5, label %6, label %else_6
	
	; %6 if block
			
		; argument String
		%7 = getelementptr [18 x i8], [18 x i8]* @global_string_literal_2, i32 0, i32 0
		; argument Int32
		%8 = load i32, i32* %global_func_main_variable_a
		; argument Int32
		%9 = load i32, i32* %global_func_main_variable_b
		; procedure printf
		%10 = call i32 (i8*, i32, ...) @printf (i8* %7, i32 %8, i32 %9)
	br label %continue_6
	
	else_6:
			
		; argument String
		%11 = getelementptr [18 x i8], [18 x i8]* @global_string_literal_2, i32 0, i32 0
		; argument Int32
		%12 = load i32, i32* %global_func_main_variable_a
		; argument Int32
		%13 = load i32, i32* %global_func_main_variable_b
		; procedure printf
		%14 = call i32 (i8*, i32, ...) @printf (i8* %11, i32 %12, i32 %13)
	br label %continue_6
	
	continue_6:
	
	; argument String
	%15 = getelementptr [4 x i8], [4 x i8]* @global_string_literal_1, i32 0, i32 0
	; argument Int32
	%16 = load i32, i32* %global_func_main_variable_b
	; procedure printf
	%17 = call i32 (i8*, i32, ...) @printf (i8* %15, i32 %16)
	ret i32 0
}


Program ended with exit code: 0