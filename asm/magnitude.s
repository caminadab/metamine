.intel_syntax noprefix
    .globl  main
main:
    mov rdi, 1000000000000              #;your value here
    bsr rax, rdi
    movzx   eax, BYTE PTR maxdigits[1+rax]
    cmp rdi, QWORD PTR powers[0+eax*8]
    sbb al, 0
    ret
maxdigits:
    .byte   0
    .byte   0
    .byte   0
    .byte   0
    .byte   1
    .byte   1
    .byte   1
    .byte   2
    .byte   2
    .byte   2
    .byte   3
    .byte   3
    .byte   3
    .byte   3
    .byte   4
    .byte   4
    .byte   4
    .byte   5
    .byte   5
    .byte   5
    .byte   6
    .byte   6
    .byte   6
    .byte   6
    .byte   7
    .byte   7
    .byte   7
    .byte   8
    .byte   8
    .byte   8
    .byte   9
    .byte   9
    .byte   9
    .byte   9
    .byte   10
    .byte   10
    .byte   10
    .byte   11
    .byte   11
    .byte   11
    .byte   12
powers:
    .quad   0
    .quad   10
    .quad   100
    .quad   1000
    .quad   10000
    .quad   100000
    .quad   1000000
    .quad   10000000
    .quad   100000000
    .quad   1000000000
    .quad   10000000000
    .quad   100000000000
    .quad   1000000000000
