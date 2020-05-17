@global_string_literal_1 = constant [4 x i8] c"\25\64\0A\00"
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
	
	; argument String
	%4 = getelementptr [4 x i8], [4 x i8]* @global_string_literal_1, i32 0, i32 0
	; argument Int32
	%5 = load i32, i32* %global_func_main_variable_b

	; procedure global_func_prinf
	%6 = call i32 (i8*, i32, ...) @printf (i8* %4, i32 %5)
	ret i32 0
}


