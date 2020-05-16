declare i32 @printf(i8*, i32, ...)

                            ; "%d\n"
@format_d = private constant [4 x i8] c"%d\0A\00" 

                            ; a: Int : 3
@a = private constant i32 3
    
                            ; func main() -> Int {
define i32 @main() {

                            ; b: Int = 1
    %b = alloca i32
    store i32 1, i32* %b

                            ; b = a + b
    %1 = load i32, i32* @a
    %2 = load i32, i32* %b
    %c = add i32 %1, %2

                            ; print("%d\n", b)
    %call = call i32 (i8*, i32, ...) @printf (i8* getelementptr inbounds ([4 x i8], [4 x i8]* @format_d, i32 0, i32 0),
                                        i32 %c)

                            ; implicit return void
    ret i32 0
}


