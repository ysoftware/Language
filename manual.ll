declare i32 @printf(i8*, ...)

                            ; "%d"
@format_d = private constant [4 x i8] c"%d\0A\00" ; "%d\n"

                            ; a: Int : 3
@a = private constant i64 3

    
                            ; func main() -> Int {
define i32 @main() {

                            ; b: Int = 1
    %b = alloca i64
    store i64 1, i64* %b

                            ; b = a + b
    %1 = load i64, i64* @a
    %2 = load i64, i64* %b
    %c = add i64 %1, %2

                            ; print("%d", b)
    %call = call i32 (i8*, ...) @printf 
        (i8* getelementptr inbounds ([4 x i8], [4 x i8] * @format_d , i32 0, i32 0), i64 %c)

                            ; implicit return void
    ret i32 0
}


