@global_string_literal_1 = constant [9 x i8] c"a == %d\0A\00"
@global_string_literal_2 = constant [24 x i8] c"Left the loop, a == %d\0A\00"
declare i32 @printf (i8*, i32, ...)

define i32 @main () {
	%global_func_main_variable_a = alloca i32
	store i32 10, i32* %global_func_main_variable_a
	br label %1 ; terminating previous block
	
	; %1 loop condition
	
	; binary operator: notEqual
	%2 = load i32, i32* %global_func_main_variable_a
	%3 = icmp ne i32 %2, 0
	br i1 %3, label %loop.1.body, label %loop.1.continue
	
	loop.1.body:
			
		; argument String
		%4 = getelementptr [9 x i8], [9 x i8]* @global_string_literal_1, i32 0, i32 0
		; argument Int32
		%5 = load i32, i32* %global_func_main_variable_a
		; procedure printf
		%6 = call i32 (i8*, i32, ...) @printf (i8* %4, i32 %5)
		
		; binary operator: sub
		%7 = load i32, i32* %global_func_main_variable_a
		%8 = sub i32 %7, 1
		store i32 %8, i32* %global_func_main_variable_a
	br label %1
	
	loop.1.continue:
	
	; argument String
	%9 = getelementptr [24 x i8], [24 x i8]* @global_string_literal_2, i32 0, i32 0
	; argument Int32
	%10 = load i32, i32* %global_func_main_variable_a
	; procedure printf
	%11 = call i32 (i8*, i32, ...) @printf (i8* %9, i32 %10)
	ret i32 0
}