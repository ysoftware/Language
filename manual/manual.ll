declare i32 @printf (i8*, i32, ...)

                            ; "%d\n"
@format_1 = private constant [4 x i8] c"%d\0A\00" 
@format_2 = private constant [10 x i8] c"we hit 4\0A\00" 

                            ; func main() -> Int {
define i32 @main() {

                            ; a: Int : 3
    %a = alloca i32
    store i32 3, i32* %a
    
                            ; b: Int = 1
    %b = alloca i32
    store i32 1, i32* %b

                            ; b = a + b
    %1 = load i32, i32* %a
    %2 = load i32, i32* %b
    %3 = add i32 %1, %2
    store i32 %3, i32* %b


                            ; if a == 4
    %4 = load i32, i32* %b
    %5 = icmp eq i32 %4, 4
    br i1 %5, label %if_1, label %else_1

        if_1:
                            ; printf("")
        %6 = load i32, i32* %b
        %7 = getelementptr inbounds [10 x i8], [10 x i8]* @format_2, i32 0, i32 0
        call i32 (i8*, i32, ...) @printf (i8* %7, i32 %6)
        br label %else_1

    else_1:
                            ; printf("%d\n", b)
    %9 = load i32, i32* %b
    %10 = getelementptr inbounds [4 x i8], [4 x i8]* @format_1, i32 0, i32 0
    call i32 (i8*, i32, ...) @printf (i8* %10, i32 %9)

                            ; implicit return void
    ret i32 0
}