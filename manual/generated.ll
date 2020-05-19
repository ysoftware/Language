@global_string_literal_1 = constant [24 x i8] c"Left the loop, a == %d\0A\00"
declare i32 @printf (i8*, i32, ...)

define i32 @main () {
	%global_func_main_variable_a = alloca i32
	store i32 0, i32* %global_func_main_variable_a
	br label %1 ; terminating previous block
	
	; %1 loop condition
	br i1 true, label %loop.1.body, label %loop.1.continue
	
	loop.1.body:
			
		; binary operator: add
		%2 = load i32, i32* %global_func_main_variable_a
		%3 = add i32 %2, 1
		store i32 %3, i32* %global_func_main_variable_a
		
		; if condition
		
		; binary operator: equal
		%4 = load i32, i32* %global_func_main_variable_a
		%5 = icmp eq i32 %4, 100
		br i1 %5, label %6, label %if.6.continue
		
		; if.6 body:
					
			; loop break
			br label %loop.1.continue
		br label %if.6.continue
		
		if.6.continue:
		
		; if condition
		
		; binary operator: signedGreaterThan
		%8 = load i32, i32* %global_func_main_variable_a
		%9 = icmp sgt i32 %8, 1
		br i1 %9, label %10, label %if.10.else
		
		; if.10 body:
					
			; loop continue
			br label %1
		br label %if.10.continue
		
		if.10.else:
					
			; argument String
			%12 = getelementptr [24 x i8], [24 x i8]* @global_string_literal_1, i32 0, i32 0
			; argument Int32
			%13 = load i32, i32* %global_func_main_variable_a
			; procedure printf
			%14 = call i32 (i8*, i32, ...) @printf (i8* %12, i32 %13)
		br label %if.10.continue
		
		if.10.continue:
	br label %1
	
	loop.1.continue:
	
	; argument String
	%15 = getelementptr [24 x i8], [24 x i8]* @global_string_literal_1, i32 0, i32 0
	; argument Int32
	%16 = load i32, i32* %global_func_main_variable_a
	; procedure printf
	%17 = call i32 (i8*, i32, ...) @printf (i8* %15, i32 %16)
	ret i32 0
}


Program ended with exit code: 0