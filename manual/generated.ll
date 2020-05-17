@global_string_literal_1 = constant [4 x i8] c"\25\64\0A\00"
@global_string_literal_2 = constant [10 x i8] c"\77\65\20\68\69\74\20\34\0A\00"
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
	

	; condition
	br i1 %5, label %6, label %10
	

	; %6  if
			
		; argument String
		%7 = getelementptr [10 x i8], [10 x i8]* @global_string_literal_2, i32 0, i32 0
		; argument Int32
		%8 = load i32, i32* %global_func_main_variable_b

		; procedure printf
		%9 = call i32 (i8*, i32, ...) @printf (i8* %7, i32 %8)
	br label %10
	; %10
	
	; argument String
	%11 = getelementptr [4 x i8], [4 x i8]* @global_string_literal_1, i32 0, i32 0
	; argument Int32
	%12 = load i32, i32* %global_func_main_variable_b

	; procedure printf
	%13 = call i32 (i8*, i32, ...) @printf (i8* %11, i32 %12)
	ret i32 0
}