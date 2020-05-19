@global_string_literal_1 = constant [27 x i8] c"Did not continue! a is %d\0A\00"
@global_string_literal_2 = constant [32 x i8] c"Broke out of the loop, a is %d\0A\00"
@global_string_literal_3 = constant [18 x i8] c"Value of a is %d\0A\00"
declare i32 @printf (i8*, i32, ...)

define i32 @main () {
	%global_func_main_variable_a = alloca i32
	store i32 0, i32* %global_func_main_variable_a
	
	br label %1 ; terminating previous block
	
	; %1 loop.1.condition
	br i1 true, label %loop.1.body, label %loop.1.continue
	
	loop.1.body: ; user label outerLoop
			
		br label %2 ; terminating previous block
		
		; %2 loop.2.condition
		br i1 true, label %loop.2.body, label %loop.2.continue
		
		loop.2.body: ; user label [not set]
					
			; binary operator: add
			%3 = load i32, i32* %global_func_main_variable_a
			%4 = add i32 %3, 1
			store i32 %4, i32* %global_func_main_variable_a
			
			; argument String
			%5 = getelementptr [18 x i8], [18 x i8]* @global_string_literal_3, i32 0, i32 0
			; argument Int32
			%6 = load i32, i32* %global_func_main_variable_a
			; procedure printf
			%7 = call i32 (i8*, i32, ...) @printf (i8* %5, i32 %6)
			
			; if condition
			
			; binary operator: equal
			%8 = load i32, i32* %global_func_main_variable_a
			%9 = icmp eq i32 %8, 100
			br i1 %9, label %10, label %if.10.continue
			
			; %10 if.10.body:
							
				br label %loop.2.continue ; loop break, user label [not set]
			br label %if.10.continue
			
			if.10.continue:
			
			; if condition
			
			; binary operator: signedGreaterThan
			%12 = load i32, i32* %global_func_main_variable_a
			%13 = icmp sgt i32 %12, 1
			br i1 %13, label %14, label %if.14.else
			
			; %14 if.14.body:
							
				br label %2 ; loop continue, user label [not set]
			br label %if.14.continue
			
			if.14.else:
							
				; argument String
				%16 = getelementptr [27 x i8], [27 x i8]* @global_string_literal_1, i32 0, i32 0
				; argument Int32
				%17 = load i32, i32* %global_func_main_variable_a
				; procedure printf
				%18 = call i32 (i8*, i32, ...) @printf (i8* %16, i32 %17)
			br label %if.14.continue ; exiting else.14
			
			if.14.continue:
			
			; if condition
			
			; binary operator: signedGreaterThan
			%19 = load i32, i32* %global_func_main_variable_a
			%20 = icmp sgt i32 %19, 500
			br i1 %20, label %21, label %if.21.continue
			
			; %21 if.21.body:
							
				br label %loop.1.continue ; loop break, user label outerLoop
			br label %if.21.continue
			
			if.21.continue:
		br label %2
		
		loop.2.continue: ; exiting loop.2, user label [not set]
	br label %1
	
	loop.1.continue: ; exiting loop.1, user label outerLoop
	
	; argument String
	%23 = getelementptr [32 x i8], [32 x i8]* @global_string_literal_2, i32 0, i32 0
	; argument Int32
	%24 = load i32, i32* %global_func_main_variable_a
	; procedure printf
	%25 = call i32 (i8*, i32, ...) @printf (i8* %23, i32 %24)
	ret i32 0
}


Program ended with exit code: 0