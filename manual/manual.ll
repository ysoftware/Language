declare i32 @printf (i8*, i32, ...)

                            ; "%d\n"
@format_d = private constant [4 x i8] c"%d\0A\00" 

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

                            ; print("%d\n", b)
    %4 = load i32, i32* %b
    %5 = getelementptr inbounds [4 x i8], [4 x i8]* @format_d, i32 0, i32 0
    call i32 (i8*, i32, ...) @printf (i8* %5, i32 %4)

                            ; implicit return void
    ret i32 0
}